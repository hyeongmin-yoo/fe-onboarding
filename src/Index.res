open Belt

module Query = %relay(`
  query IndexQuery($query: String!, $count: Int!) {
    ...IndexRepos_query @arguments(query: $query, count: $count)
  }
`)

module Fragment = %relay(`
  fragment IndexRepos_query on Query
  @refetchable(queryName: "IndexRepoRefetchQuery")
  @argumentDefinitions(
    query: { type: "String!" }
    count: { type: "Int", defaultValue: 5 }
    cursor: { type: "String" }
  ) {
    search(query: $query, first: $count, type: REPOSITORY, after: $cursor)
      @connection(key: "Repos_search") {
      edges {
        node {
          ... on Repository {
            id
            name
            description
            stargazerCount
            viewerHasStarred
          }
        }
      }
    }
  }
`)

module AddStarMutation = %relay(`
  mutation IndexAddRepoStarMutation($input: AddStarInput!) {
    addStar(input: $input) {
      starrable {
        id
        stargazerCount
        viewerHasStarred
      }
    }
  }
`)

module RemoveStarMutation = %relay(`
  mutation IndexRemoveRepoStarMutation($input: RemoveStarInput!) {
    removeStar(input: $input) {
      starrable {
        id
        stargazerCount
        viewerHasStarred
      }
    }
  }
`)

type repo = IndexRepos_query_graphql.Types.fragment_search_edges_node_Repository

module RepoItem = {
  @react.component
  let make = (~repo: repo) => {
    let (addStar, isAddingStar) = AddStarMutation.use()
    let (removeStar, isRemovingStar) = RemoveStarMutation.use()

    <div>
      <div>
        <strong> {repo.name->React.string} </strong>
      </div>
      {switch repo.description {
      | Some(val) => <div> {val->React.string} </div>
      | _ => React.null
      }}
      {repo.viewerHasStarred
        ? <button
            type_="button"
            disabled={isRemovingStar}
            style={ReactDOM.Style.make(~background="#eee", ~border="1px solid #ddd", ())}
            onClick={_ => {
              removeStar(
                ~variables={
                  input: {
                    starrableId: repo.id,
                    clientMutationId: None,
                  },
                },
                (),
              )->ignore
            }}>
            {"🌟 :"->React.string}
            {repo.stargazerCount->React.int}
          </button>
        : <button
            type_="button"
            disabled={isAddingStar}
            style={ReactDOM.Style.make(~background="#fff", ~border="1px solid #ddd", ())}
            onClick={_ => {
              addStar(
                ~variables={
                  input: {
                    starrableId: repo.id,
                    clientMutationId: None,
                  },
                },
                (),
              )->ignore
            }}>
            {"⭐️ :"->React.string}
            {repo.stargazerCount->React.int}
          </button>}
    </div>
  }
}

module RepoList = {
  @react.component
  let make = (~query, ~count) => {
    let {data, hasNext, isLoadingNext, loadNext} = Fragment.usePagination(query)
    let repos =
      data.search
      ->Fragment.getConnectionNodes
      ->Array.keepMap(repo =>
        switch repo {
        | #Repository(val) => Some(val)
        | _ => None
        }
      )

    <div>
      <ul>
        {repos
        ->Array.map(repo =>
          <li key=repo.id>
            <RepoItem repo />
          </li>
        )
        ->React.array}
      </ul>
      {hasNext
        ? <button onClick={_ => loadNext(~count, ())->ignore} disabled=isLoadingNext>
            {"더 보기"->React.string}
          </button>
        : React.null}
    </div>
  }
}

module SearchField = {
  @react.component
  let make = (~initValue: string, ~onSubmit: string => unit) => {
    let (keyword, setKeyword) = React.useState(() => initValue)

    <form
      onSubmit={evt => {
        evt->ReactEvent.Form.preventDefault
        onSubmit(keyword)
      }}>
      <input
        type_="search"
        value=keyword
        onChange={evt => evt->ReactEvent.Form.currentTarget->(it => it["value"])->setKeyword}
      />
      <button type_="submit"> {"Search"->React.string} </button>
    </form>
  }
}

module SearchResult = {
  @react.component
  let make = (~keyword: string) => {
    let queryData = Query.use(~variables={query: keyword, count: 5}, ())
    <RepoList query=queryData.fragmentRefs count=5 />
  }
}

let default = () => {
  let (keyword, setKeyword) = React.useState(() => "")

  <>
    <SearchField initValue=keyword onSubmit={val => setKeyword(_ => val)} />
    {switch keyword {
    | "" => <div> {"검색어를 입력하세요."->React.string} </div>
    | _ =>
      <React.Suspense fallback={"Loading..."->React.string}>
        <SearchResult keyword />
      </React.Suspense>
    }}
  </>
}
