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
            url
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
        <a href={repo.url} target="_blank" className="hover:underline hover:underline-offset-2">
          <strong> {repo.name->React.string} </strong>
        </a>
      </div>
      {switch repo.description {
      | Some(val) => <div> {val->React.string} </div>
      | _ => React.null
      }}
      {repo.viewerHasStarred
        ? <button
            type_="button"
            className="mt-2 px-2 py-1 rounded-md border-solid border-2 border-gray-220 bg-gray-200"
            disabled={isRemovingStar}
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
            {"🌟 : "->React.string}
            {repo.stargazerCount->React.int}
          </button>
        : <button
            type_="button"
            className="mt-2 px-2 py-1 rounded-md border-solid border-2 border-gray-220 bg-white"
            disabled={isAddingStar}
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
            {"⭐️ : "->React.string}
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
      <ul className="my-4">
        {repos
        ->Array.map(repo =>
          <li key=repo.id className="first:mt-0 mt-4">
            <RepoItem repo />
          </li>
        )
        ->React.array}
      </ul>
      {hasNext
        ? <button
            className="w-full bg-gray-200 p-2 rounded-md hover:bg-gray-300"
            onClick={_ => loadNext(~count, ())->ignore}
            disabled=isLoadingNext>
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
      className="flex justify-center"
      onSubmit={evt => {
        evt->ReactEvent.Form.preventDefault
        onSubmit(keyword)
      }}>
      <input
        className="border-solid border-2 border-gray-600 py-1 px-2 focus:outline-none"
        type_="search"
        value=keyword
        onChange={evt => evt->ReactEvent.Form.currentTarget->(it => it["value"])->setKeyword}
      />
      <button type_="submit" className="bg-gray-600 text-white py-1 px-4">
        {"검색"->React.string}
      </button>
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

  <div className="p-4 max-w-2xl m-auto">
    <SearchField initValue=keyword onSubmit={val => setKeyword(_ => val)} />
    {switch keyword {
    | "" =>
      <div className="mt-10 text-center"> {"검색어를 입력하세요."->React.string} </div>
    | _ =>
      <React.Suspense
        fallback={<div className="mt-10 text-center"> {"Loading..."->React.string} </div>}>
        <SearchResult keyword />
      </React.Suspense>
    }}
  </div>
}
