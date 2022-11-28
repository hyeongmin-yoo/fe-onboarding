module Query = %relay(`
  query IndexQuery {
    viewer {
      login
    }
  }
`)

let default = () => {
  let queryData = Query.use(~variables=(), ())

  <div> {`Hello ${queryData.viewer.login}!`->React.string} </div>
}
