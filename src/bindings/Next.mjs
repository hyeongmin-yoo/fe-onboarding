// Generated by ReScript, PLEASE EDIT WITH CARE


var Req = {};

var Res = {};

var GetServerSideProps = {};

var GetStaticProps = {};

var GetStaticPaths = {};

var App = {};

var Link = {};

var Events = {};

function replaceShallow(router, pathObj) {
  router.replace(pathObj, undefined, {
        shallow: true
      });
}

function pushShallow(router, pathObj) {
  router.push(pathObj, undefined, {
        shallow: true
      });
}

var Router = {
  Events: Events,
  replaceShallow: replaceShallow,
  pushShallow: pushShallow
};

var Head = {};

var $$Error = {};

var Dynamic = {};

var $$Image = {};

var Script = {};

export {
  Req ,
  Res ,
  GetServerSideProps ,
  GetStaticProps ,
  GetStaticPaths ,
  App ,
  Link ,
  Router ,
  Head ,
  $$Error ,
  Dynamic ,
  $$Image ,
  Script ,
}
/* No side effect */
