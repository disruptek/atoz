
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Athena
## version: 2017-05-18
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Amazon Athena is an interactive query service that lets you use standard SQL to analyze data directly in Amazon S3. You can point Athena at your data in Amazon S3 and run ad-hoc queries and get results in seconds. Athena is serverless, so there is no infrastructure to set up or manage. You pay only for the queries you run. Athena scales automatically—executing queries in parallel—so results are fast, even with large datasets and complex queries. For more information, see <a href="http://docs.aws.amazon.com/athena/latest/ug/what-is.html">What is Amazon Athena</a> in the <i>Amazon Athena User Guide</i>.</p> <p>If you connect to Athena using the JDBC driver, use version 1.1.0 of the driver or later with the Amazon Athena API. Earlier version drivers do not support the API. For more information and to download the driver, see <a href="https://docs.aws.amazon.com/athena/latest/ug/connect-with-jdbc.html">Accessing Amazon Athena with JDBC</a>.</p> <p>For code samples using the AWS SDK for Java, see <a href="https://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/athena/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "athena.ap-northeast-1.amazonaws.com", "ap-southeast-1": "athena.ap-southeast-1.amazonaws.com",
                           "us-west-2": "athena.us-west-2.amazonaws.com",
                           "eu-west-2": "athena.eu-west-2.amazonaws.com", "ap-northeast-3": "athena.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "athena.eu-central-1.amazonaws.com",
                           "us-east-2": "athena.us-east-2.amazonaws.com",
                           "us-east-1": "athena.us-east-1.amazonaws.com", "cn-northwest-1": "athena.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "athena.ap-south-1.amazonaws.com",
                           "eu-north-1": "athena.eu-north-1.amazonaws.com", "ap-northeast-2": "athena.ap-northeast-2.amazonaws.com",
                           "us-west-1": "athena.us-west-1.amazonaws.com", "us-gov-east-1": "athena.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "athena.eu-west-3.amazonaws.com",
                           "cn-north-1": "athena.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "athena.sa-east-1.amazonaws.com",
                           "eu-west-1": "athena.eu-west-1.amazonaws.com", "us-gov-west-1": "athena.us-gov-west-1.amazonaws.com", "ap-southeast-2": "athena.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "athena.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "athena.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "athena.ap-southeast-1.amazonaws.com",
      "us-west-2": "athena.us-west-2.amazonaws.com",
      "eu-west-2": "athena.eu-west-2.amazonaws.com",
      "ap-northeast-3": "athena.ap-northeast-3.amazonaws.com",
      "eu-central-1": "athena.eu-central-1.amazonaws.com",
      "us-east-2": "athena.us-east-2.amazonaws.com",
      "us-east-1": "athena.us-east-1.amazonaws.com",
      "cn-northwest-1": "athena.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "athena.ap-south-1.amazonaws.com",
      "eu-north-1": "athena.eu-north-1.amazonaws.com",
      "ap-northeast-2": "athena.ap-northeast-2.amazonaws.com",
      "us-west-1": "athena.us-west-1.amazonaws.com",
      "us-gov-east-1": "athena.us-gov-east-1.amazonaws.com",
      "eu-west-3": "athena.eu-west-3.amazonaws.com",
      "cn-north-1": "athena.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "athena.sa-east-1.amazonaws.com",
      "eu-west-1": "athena.eu-west-1.amazonaws.com",
      "us-gov-west-1": "athena.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "athena.ap-southeast-2.amazonaws.com",
      "ca-central-1": "athena.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "athena"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchGetNamedQuery_592703 = ref object of OpenApiRestCall_592364
proc url_BatchGetNamedQuery_592705(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetNamedQuery_592704(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns the details of a single named query or a list of up to 50 queries, which you provide as an array of query ID strings. Requires you to have access to the workgroup in which the queries were saved. Use <a>ListNamedQueriesInput</a> to get the list of named query IDs in the specified workgroup. If information could not be retrieved for a submitted query ID, information about the query ID submitted is listed under <a>UnprocessedNamedQueryId</a>. Named queries differ from executed queries. Use <a>BatchGetQueryExecutionInput</a> to get details about each unique query execution, and <a>ListQueryExecutionsInput</a> to get a list of query execution IDs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592830 = header.getOrDefault("X-Amz-Target")
  valid_592830 = validateParameter(valid_592830, JString, required = true, default = newJString(
      "AmazonAthena.BatchGetNamedQuery"))
  if valid_592830 != nil:
    section.add "X-Amz-Target", valid_592830
  var valid_592831 = header.getOrDefault("X-Amz-Signature")
  valid_592831 = validateParameter(valid_592831, JString, required = false,
                                 default = nil)
  if valid_592831 != nil:
    section.add "X-Amz-Signature", valid_592831
  var valid_592832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592832 = validateParameter(valid_592832, JString, required = false,
                                 default = nil)
  if valid_592832 != nil:
    section.add "X-Amz-Content-Sha256", valid_592832
  var valid_592833 = header.getOrDefault("X-Amz-Date")
  valid_592833 = validateParameter(valid_592833, JString, required = false,
                                 default = nil)
  if valid_592833 != nil:
    section.add "X-Amz-Date", valid_592833
  var valid_592834 = header.getOrDefault("X-Amz-Credential")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "X-Amz-Credential", valid_592834
  var valid_592835 = header.getOrDefault("X-Amz-Security-Token")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Security-Token", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Algorithm")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Algorithm", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-SignedHeaders", valid_592837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592861: Call_BatchGetNamedQuery_592703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the details of a single named query or a list of up to 50 queries, which you provide as an array of query ID strings. Requires you to have access to the workgroup in which the queries were saved. Use <a>ListNamedQueriesInput</a> to get the list of named query IDs in the specified workgroup. If information could not be retrieved for a submitted query ID, information about the query ID submitted is listed under <a>UnprocessedNamedQueryId</a>. Named queries differ from executed queries. Use <a>BatchGetQueryExecutionInput</a> to get details about each unique query execution, and <a>ListQueryExecutionsInput</a> to get a list of query execution IDs.
  ## 
  let valid = call_592861.validator(path, query, header, formData, body)
  let scheme = call_592861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592861.url(scheme.get, call_592861.host, call_592861.base,
                         call_592861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592861, url, valid)

proc call*(call_592932: Call_BatchGetNamedQuery_592703; body: JsonNode): Recallable =
  ## batchGetNamedQuery
  ## Returns the details of a single named query or a list of up to 50 queries, which you provide as an array of query ID strings. Requires you to have access to the workgroup in which the queries were saved. Use <a>ListNamedQueriesInput</a> to get the list of named query IDs in the specified workgroup. If information could not be retrieved for a submitted query ID, information about the query ID submitted is listed under <a>UnprocessedNamedQueryId</a>. Named queries differ from executed queries. Use <a>BatchGetQueryExecutionInput</a> to get details about each unique query execution, and <a>ListQueryExecutionsInput</a> to get a list of query execution IDs.
  ##   body: JObject (required)
  var body_592933 = newJObject()
  if body != nil:
    body_592933 = body
  result = call_592932.call(nil, nil, nil, nil, body_592933)

var batchGetNamedQuery* = Call_BatchGetNamedQuery_592703(
    name: "batchGetNamedQuery", meth: HttpMethod.HttpPost,
    host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.BatchGetNamedQuery",
    validator: validate_BatchGetNamedQuery_592704, base: "/",
    url: url_BatchGetNamedQuery_592705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetQueryExecution_592972 = ref object of OpenApiRestCall_592364
proc url_BatchGetQueryExecution_592974(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetQueryExecution_592973(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the details of a single query execution or a list of up to 50 query executions, which you provide as an array of query execution ID strings. Requires you to have access to the workgroup in which the queries ran. To get a list of query execution IDs, use <a>ListQueryExecutionsInput$WorkGroup</a>. Query executions differ from named (saved) queries. Use <a>BatchGetNamedQueryInput</a> to get details about named queries.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592975 = header.getOrDefault("X-Amz-Target")
  valid_592975 = validateParameter(valid_592975, JString, required = true, default = newJString(
      "AmazonAthena.BatchGetQueryExecution"))
  if valid_592975 != nil:
    section.add "X-Amz-Target", valid_592975
  var valid_592976 = header.getOrDefault("X-Amz-Signature")
  valid_592976 = validateParameter(valid_592976, JString, required = false,
                                 default = nil)
  if valid_592976 != nil:
    section.add "X-Amz-Signature", valid_592976
  var valid_592977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592977 = validateParameter(valid_592977, JString, required = false,
                                 default = nil)
  if valid_592977 != nil:
    section.add "X-Amz-Content-Sha256", valid_592977
  var valid_592978 = header.getOrDefault("X-Amz-Date")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "X-Amz-Date", valid_592978
  var valid_592979 = header.getOrDefault("X-Amz-Credential")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Credential", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Security-Token")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Security-Token", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Algorithm")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Algorithm", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-SignedHeaders", valid_592982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592984: Call_BatchGetQueryExecution_592972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the details of a single query execution or a list of up to 50 query executions, which you provide as an array of query execution ID strings. Requires you to have access to the workgroup in which the queries ran. To get a list of query execution IDs, use <a>ListQueryExecutionsInput$WorkGroup</a>. Query executions differ from named (saved) queries. Use <a>BatchGetNamedQueryInput</a> to get details about named queries.
  ## 
  let valid = call_592984.validator(path, query, header, formData, body)
  let scheme = call_592984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592984.url(scheme.get, call_592984.host, call_592984.base,
                         call_592984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592984, url, valid)

proc call*(call_592985: Call_BatchGetQueryExecution_592972; body: JsonNode): Recallable =
  ## batchGetQueryExecution
  ## Returns the details of a single query execution or a list of up to 50 query executions, which you provide as an array of query execution ID strings. Requires you to have access to the workgroup in which the queries ran. To get a list of query execution IDs, use <a>ListQueryExecutionsInput$WorkGroup</a>. Query executions differ from named (saved) queries. Use <a>BatchGetNamedQueryInput</a> to get details about named queries.
  ##   body: JObject (required)
  var body_592986 = newJObject()
  if body != nil:
    body_592986 = body
  result = call_592985.call(nil, nil, nil, nil, body_592986)

var batchGetQueryExecution* = Call_BatchGetQueryExecution_592972(
    name: "batchGetQueryExecution", meth: HttpMethod.HttpPost,
    host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.BatchGetQueryExecution",
    validator: validate_BatchGetQueryExecution_592973, base: "/",
    url: url_BatchGetQueryExecution_592974, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNamedQuery_592987 = ref object of OpenApiRestCall_592364
proc url_CreateNamedQuery_592989(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateNamedQuery_592988(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Creates a named query in the specified workgroup. Requires that you have access to the workgroup.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592990 = header.getOrDefault("X-Amz-Target")
  valid_592990 = validateParameter(valid_592990, JString, required = true, default = newJString(
      "AmazonAthena.CreateNamedQuery"))
  if valid_592990 != nil:
    section.add "X-Amz-Target", valid_592990
  var valid_592991 = header.getOrDefault("X-Amz-Signature")
  valid_592991 = validateParameter(valid_592991, JString, required = false,
                                 default = nil)
  if valid_592991 != nil:
    section.add "X-Amz-Signature", valid_592991
  var valid_592992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "X-Amz-Content-Sha256", valid_592992
  var valid_592993 = header.getOrDefault("X-Amz-Date")
  valid_592993 = validateParameter(valid_592993, JString, required = false,
                                 default = nil)
  if valid_592993 != nil:
    section.add "X-Amz-Date", valid_592993
  var valid_592994 = header.getOrDefault("X-Amz-Credential")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Credential", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-Security-Token")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Security-Token", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-Algorithm")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Algorithm", valid_592996
  var valid_592997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-SignedHeaders", valid_592997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592999: Call_CreateNamedQuery_592987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a named query in the specified workgroup. Requires that you have access to the workgroup.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  let valid = call_592999.validator(path, query, header, formData, body)
  let scheme = call_592999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592999.url(scheme.get, call_592999.host, call_592999.base,
                         call_592999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592999, url, valid)

proc call*(call_593000: Call_CreateNamedQuery_592987; body: JsonNode): Recallable =
  ## createNamedQuery
  ## <p>Creates a named query in the specified workgroup. Requires that you have access to the workgroup.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ##   body: JObject (required)
  var body_593001 = newJObject()
  if body != nil:
    body_593001 = body
  result = call_593000.call(nil, nil, nil, nil, body_593001)

var createNamedQuery* = Call_CreateNamedQuery_592987(name: "createNamedQuery",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.CreateNamedQuery",
    validator: validate_CreateNamedQuery_592988, base: "/",
    url: url_CreateNamedQuery_592989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkGroup_593002 = ref object of OpenApiRestCall_592364
proc url_CreateWorkGroup_593004(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateWorkGroup_593003(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a workgroup with the specified name.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593005 = header.getOrDefault("X-Amz-Target")
  valid_593005 = validateParameter(valid_593005, JString, required = true, default = newJString(
      "AmazonAthena.CreateWorkGroup"))
  if valid_593005 != nil:
    section.add "X-Amz-Target", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-Signature")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-Signature", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Content-Sha256", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-Date")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-Date", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-Credential")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-Credential", valid_593009
  var valid_593010 = header.getOrDefault("X-Amz-Security-Token")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Security-Token", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-Algorithm")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Algorithm", valid_593011
  var valid_593012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-SignedHeaders", valid_593012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593014: Call_CreateWorkGroup_593002; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a workgroup with the specified name.
  ## 
  let valid = call_593014.validator(path, query, header, formData, body)
  let scheme = call_593014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593014.url(scheme.get, call_593014.host, call_593014.base,
                         call_593014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593014, url, valid)

proc call*(call_593015: Call_CreateWorkGroup_593002; body: JsonNode): Recallable =
  ## createWorkGroup
  ## Creates a workgroup with the specified name.
  ##   body: JObject (required)
  var body_593016 = newJObject()
  if body != nil:
    body_593016 = body
  result = call_593015.call(nil, nil, nil, nil, body_593016)

var createWorkGroup* = Call_CreateWorkGroup_593002(name: "createWorkGroup",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.CreateWorkGroup",
    validator: validate_CreateWorkGroup_593003, base: "/", url: url_CreateWorkGroup_593004,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNamedQuery_593017 = ref object of OpenApiRestCall_592364
proc url_DeleteNamedQuery_593019(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteNamedQuery_593018(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes the named query if you have access to the workgroup in which the query was saved.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593020 = header.getOrDefault("X-Amz-Target")
  valid_593020 = validateParameter(valid_593020, JString, required = true, default = newJString(
      "AmazonAthena.DeleteNamedQuery"))
  if valid_593020 != nil:
    section.add "X-Amz-Target", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-Signature")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-Signature", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Content-Sha256", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-Date")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-Date", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-Credential")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Credential", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Security-Token")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Security-Token", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-Algorithm")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Algorithm", valid_593026
  var valid_593027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-SignedHeaders", valid_593027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593029: Call_DeleteNamedQuery_593017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the named query if you have access to the workgroup in which the query was saved.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  let valid = call_593029.validator(path, query, header, formData, body)
  let scheme = call_593029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593029.url(scheme.get, call_593029.host, call_593029.base,
                         call_593029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593029, url, valid)

proc call*(call_593030: Call_DeleteNamedQuery_593017; body: JsonNode): Recallable =
  ## deleteNamedQuery
  ## <p>Deletes the named query if you have access to the workgroup in which the query was saved.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ##   body: JObject (required)
  var body_593031 = newJObject()
  if body != nil:
    body_593031 = body
  result = call_593030.call(nil, nil, nil, nil, body_593031)

var deleteNamedQuery* = Call_DeleteNamedQuery_593017(name: "deleteNamedQuery",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.DeleteNamedQuery",
    validator: validate_DeleteNamedQuery_593018, base: "/",
    url: url_DeleteNamedQuery_593019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkGroup_593032 = ref object of OpenApiRestCall_592364
proc url_DeleteWorkGroup_593034(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteWorkGroup_593033(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Deletes the workgroup with the specified name. The primary workgroup cannot be deleted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593035 = header.getOrDefault("X-Amz-Target")
  valid_593035 = validateParameter(valid_593035, JString, required = true, default = newJString(
      "AmazonAthena.DeleteWorkGroup"))
  if valid_593035 != nil:
    section.add "X-Amz-Target", valid_593035
  var valid_593036 = header.getOrDefault("X-Amz-Signature")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-Signature", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Content-Sha256", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-Date")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Date", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Credential")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Credential", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Security-Token")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Security-Token", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Algorithm")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Algorithm", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-SignedHeaders", valid_593042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593044: Call_DeleteWorkGroup_593032; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the workgroup with the specified name. The primary workgroup cannot be deleted.
  ## 
  let valid = call_593044.validator(path, query, header, formData, body)
  let scheme = call_593044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593044.url(scheme.get, call_593044.host, call_593044.base,
                         call_593044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593044, url, valid)

proc call*(call_593045: Call_DeleteWorkGroup_593032; body: JsonNode): Recallable =
  ## deleteWorkGroup
  ## Deletes the workgroup with the specified name. The primary workgroup cannot be deleted.
  ##   body: JObject (required)
  var body_593046 = newJObject()
  if body != nil:
    body_593046 = body
  result = call_593045.call(nil, nil, nil, nil, body_593046)

var deleteWorkGroup* = Call_DeleteWorkGroup_593032(name: "deleteWorkGroup",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.DeleteWorkGroup",
    validator: validate_DeleteWorkGroup_593033, base: "/", url: url_DeleteWorkGroup_593034,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNamedQuery_593047 = ref object of OpenApiRestCall_592364
proc url_GetNamedQuery_593049(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetNamedQuery_593048(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a single query. Requires that you have access to the workgroup in which the query was saved.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593050 = header.getOrDefault("X-Amz-Target")
  valid_593050 = validateParameter(valid_593050, JString, required = true, default = newJString(
      "AmazonAthena.GetNamedQuery"))
  if valid_593050 != nil:
    section.add "X-Amz-Target", valid_593050
  var valid_593051 = header.getOrDefault("X-Amz-Signature")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "X-Amz-Signature", valid_593051
  var valid_593052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-Content-Sha256", valid_593052
  var valid_593053 = header.getOrDefault("X-Amz-Date")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Date", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-Credential")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Credential", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Security-Token")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Security-Token", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-Algorithm")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-Algorithm", valid_593056
  var valid_593057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "X-Amz-SignedHeaders", valid_593057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593059: Call_GetNamedQuery_593047; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a single query. Requires that you have access to the workgroup in which the query was saved.
  ## 
  let valid = call_593059.validator(path, query, header, formData, body)
  let scheme = call_593059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593059.url(scheme.get, call_593059.host, call_593059.base,
                         call_593059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593059, url, valid)

proc call*(call_593060: Call_GetNamedQuery_593047; body: JsonNode): Recallable =
  ## getNamedQuery
  ## Returns information about a single query. Requires that you have access to the workgroup in which the query was saved.
  ##   body: JObject (required)
  var body_593061 = newJObject()
  if body != nil:
    body_593061 = body
  result = call_593060.call(nil, nil, nil, nil, body_593061)

var getNamedQuery* = Call_GetNamedQuery_593047(name: "getNamedQuery",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.GetNamedQuery",
    validator: validate_GetNamedQuery_593048, base: "/", url: url_GetNamedQuery_593049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQueryExecution_593062 = ref object of OpenApiRestCall_592364
proc url_GetQueryExecution_593064(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetQueryExecution_593063(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns information about a single execution of a query if you have access to the workgroup in which the query ran. Each time a query executes, information about the query execution is saved with a unique ID.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593065 = header.getOrDefault("X-Amz-Target")
  valid_593065 = validateParameter(valid_593065, JString, required = true, default = newJString(
      "AmazonAthena.GetQueryExecution"))
  if valid_593065 != nil:
    section.add "X-Amz-Target", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-Signature")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-Signature", valid_593066
  var valid_593067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-Content-Sha256", valid_593067
  var valid_593068 = header.getOrDefault("X-Amz-Date")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-Date", valid_593068
  var valid_593069 = header.getOrDefault("X-Amz-Credential")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "X-Amz-Credential", valid_593069
  var valid_593070 = header.getOrDefault("X-Amz-Security-Token")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "X-Amz-Security-Token", valid_593070
  var valid_593071 = header.getOrDefault("X-Amz-Algorithm")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-Algorithm", valid_593071
  var valid_593072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-SignedHeaders", valid_593072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593074: Call_GetQueryExecution_593062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a single execution of a query if you have access to the workgroup in which the query ran. Each time a query executes, information about the query execution is saved with a unique ID.
  ## 
  let valid = call_593074.validator(path, query, header, formData, body)
  let scheme = call_593074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593074.url(scheme.get, call_593074.host, call_593074.base,
                         call_593074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593074, url, valid)

proc call*(call_593075: Call_GetQueryExecution_593062; body: JsonNode): Recallable =
  ## getQueryExecution
  ## Returns information about a single execution of a query if you have access to the workgroup in which the query ran. Each time a query executes, information about the query execution is saved with a unique ID.
  ##   body: JObject (required)
  var body_593076 = newJObject()
  if body != nil:
    body_593076 = body
  result = call_593075.call(nil, nil, nil, nil, body_593076)

var getQueryExecution* = Call_GetQueryExecution_593062(name: "getQueryExecution",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.GetQueryExecution",
    validator: validate_GetQueryExecution_593063, base: "/",
    url: url_GetQueryExecution_593064, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQueryResults_593077 = ref object of OpenApiRestCall_592364
proc url_GetQueryResults_593079(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetQueryResults_593078(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Streams the results of a single query execution specified by <code>QueryExecutionId</code> from the Athena query results location in Amazon S3. For more information, see <a href="https://docs.aws.amazon.com/athena/latest/ug/querying.html">Query Results</a> in the <i>Amazon Athena User Guide</i>. This request does not execute the query but returns results. Use <a>StartQueryExecution</a> to run a query.</p> <p>To stream query results successfully, the IAM principal with permission to call <code>GetQueryResults</code> also must have permissions to the Amazon S3 <code>GetObject</code> action for the Athena query results location.</p> <important> <p>IAM principals with permission to the Amazon S3 <code>GetObject</code> action for the query results location are able to retrieve query results from Amazon S3 even if permission to the <code>GetQueryResults</code> action is denied. To restrict user or role access, ensure that Amazon S3 permissions to the Athena query location are denied.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593080 = query.getOrDefault("MaxResults")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "MaxResults", valid_593080
  var valid_593081 = query.getOrDefault("NextToken")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "NextToken", valid_593081
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593082 = header.getOrDefault("X-Amz-Target")
  valid_593082 = validateParameter(valid_593082, JString, required = true, default = newJString(
      "AmazonAthena.GetQueryResults"))
  if valid_593082 != nil:
    section.add "X-Amz-Target", valid_593082
  var valid_593083 = header.getOrDefault("X-Amz-Signature")
  valid_593083 = validateParameter(valid_593083, JString, required = false,
                                 default = nil)
  if valid_593083 != nil:
    section.add "X-Amz-Signature", valid_593083
  var valid_593084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593084 = validateParameter(valid_593084, JString, required = false,
                                 default = nil)
  if valid_593084 != nil:
    section.add "X-Amz-Content-Sha256", valid_593084
  var valid_593085 = header.getOrDefault("X-Amz-Date")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "X-Amz-Date", valid_593085
  var valid_593086 = header.getOrDefault("X-Amz-Credential")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "X-Amz-Credential", valid_593086
  var valid_593087 = header.getOrDefault("X-Amz-Security-Token")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "X-Amz-Security-Token", valid_593087
  var valid_593088 = header.getOrDefault("X-Amz-Algorithm")
  valid_593088 = validateParameter(valid_593088, JString, required = false,
                                 default = nil)
  if valid_593088 != nil:
    section.add "X-Amz-Algorithm", valid_593088
  var valid_593089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593089 = validateParameter(valid_593089, JString, required = false,
                                 default = nil)
  if valid_593089 != nil:
    section.add "X-Amz-SignedHeaders", valid_593089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593091: Call_GetQueryResults_593077; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Streams the results of a single query execution specified by <code>QueryExecutionId</code> from the Athena query results location in Amazon S3. For more information, see <a href="https://docs.aws.amazon.com/athena/latest/ug/querying.html">Query Results</a> in the <i>Amazon Athena User Guide</i>. This request does not execute the query but returns results. Use <a>StartQueryExecution</a> to run a query.</p> <p>To stream query results successfully, the IAM principal with permission to call <code>GetQueryResults</code> also must have permissions to the Amazon S3 <code>GetObject</code> action for the Athena query results location.</p> <important> <p>IAM principals with permission to the Amazon S3 <code>GetObject</code> action for the query results location are able to retrieve query results from Amazon S3 even if permission to the <code>GetQueryResults</code> action is denied. To restrict user or role access, ensure that Amazon S3 permissions to the Athena query location are denied.</p> </important>
  ## 
  let valid = call_593091.validator(path, query, header, formData, body)
  let scheme = call_593091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593091.url(scheme.get, call_593091.host, call_593091.base,
                         call_593091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593091, url, valid)

proc call*(call_593092: Call_GetQueryResults_593077; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getQueryResults
  ## <p>Streams the results of a single query execution specified by <code>QueryExecutionId</code> from the Athena query results location in Amazon S3. For more information, see <a href="https://docs.aws.amazon.com/athena/latest/ug/querying.html">Query Results</a> in the <i>Amazon Athena User Guide</i>. This request does not execute the query but returns results. Use <a>StartQueryExecution</a> to run a query.</p> <p>To stream query results successfully, the IAM principal with permission to call <code>GetQueryResults</code> also must have permissions to the Amazon S3 <code>GetObject</code> action for the Athena query results location.</p> <important> <p>IAM principals with permission to the Amazon S3 <code>GetObject</code> action for the query results location are able to retrieve query results from Amazon S3 even if permission to the <code>GetQueryResults</code> action is denied. To restrict user or role access, ensure that Amazon S3 permissions to the Athena query location are denied.</p> </important>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593093 = newJObject()
  var body_593094 = newJObject()
  add(query_593093, "MaxResults", newJString(MaxResults))
  add(query_593093, "NextToken", newJString(NextToken))
  if body != nil:
    body_593094 = body
  result = call_593092.call(nil, query_593093, nil, nil, body_593094)

var getQueryResults* = Call_GetQueryResults_593077(name: "getQueryResults",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.GetQueryResults",
    validator: validate_GetQueryResults_593078, base: "/", url: url_GetQueryResults_593079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkGroup_593096 = ref object of OpenApiRestCall_592364
proc url_GetWorkGroup_593098(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetWorkGroup_593097(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about the workgroup with the specified name.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593099 = header.getOrDefault("X-Amz-Target")
  valid_593099 = validateParameter(valid_593099, JString, required = true, default = newJString(
      "AmazonAthena.GetWorkGroup"))
  if valid_593099 != nil:
    section.add "X-Amz-Target", valid_593099
  var valid_593100 = header.getOrDefault("X-Amz-Signature")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-Signature", valid_593100
  var valid_593101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-Content-Sha256", valid_593101
  var valid_593102 = header.getOrDefault("X-Amz-Date")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "X-Amz-Date", valid_593102
  var valid_593103 = header.getOrDefault("X-Amz-Credential")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "X-Amz-Credential", valid_593103
  var valid_593104 = header.getOrDefault("X-Amz-Security-Token")
  valid_593104 = validateParameter(valid_593104, JString, required = false,
                                 default = nil)
  if valid_593104 != nil:
    section.add "X-Amz-Security-Token", valid_593104
  var valid_593105 = header.getOrDefault("X-Amz-Algorithm")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "X-Amz-Algorithm", valid_593105
  var valid_593106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593106 = validateParameter(valid_593106, JString, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "X-Amz-SignedHeaders", valid_593106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593108: Call_GetWorkGroup_593096; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the workgroup with the specified name.
  ## 
  let valid = call_593108.validator(path, query, header, formData, body)
  let scheme = call_593108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593108.url(scheme.get, call_593108.host, call_593108.base,
                         call_593108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593108, url, valid)

proc call*(call_593109: Call_GetWorkGroup_593096; body: JsonNode): Recallable =
  ## getWorkGroup
  ## Returns information about the workgroup with the specified name.
  ##   body: JObject (required)
  var body_593110 = newJObject()
  if body != nil:
    body_593110 = body
  result = call_593109.call(nil, nil, nil, nil, body_593110)

var getWorkGroup* = Call_GetWorkGroup_593096(name: "getWorkGroup",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.GetWorkGroup",
    validator: validate_GetWorkGroup_593097, base: "/", url: url_GetWorkGroup_593098,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNamedQueries_593111 = ref object of OpenApiRestCall_592364
proc url_ListNamedQueries_593113(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListNamedQueries_593112(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Provides a list of available query IDs only for queries saved in the specified workgroup. Requires that you have access to the workgroup.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593114 = query.getOrDefault("MaxResults")
  valid_593114 = validateParameter(valid_593114, JString, required = false,
                                 default = nil)
  if valid_593114 != nil:
    section.add "MaxResults", valid_593114
  var valid_593115 = query.getOrDefault("NextToken")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "NextToken", valid_593115
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593116 = header.getOrDefault("X-Amz-Target")
  valid_593116 = validateParameter(valid_593116, JString, required = true, default = newJString(
      "AmazonAthena.ListNamedQueries"))
  if valid_593116 != nil:
    section.add "X-Amz-Target", valid_593116
  var valid_593117 = header.getOrDefault("X-Amz-Signature")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "X-Amz-Signature", valid_593117
  var valid_593118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "X-Amz-Content-Sha256", valid_593118
  var valid_593119 = header.getOrDefault("X-Amz-Date")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "X-Amz-Date", valid_593119
  var valid_593120 = header.getOrDefault("X-Amz-Credential")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "X-Amz-Credential", valid_593120
  var valid_593121 = header.getOrDefault("X-Amz-Security-Token")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "X-Amz-Security-Token", valid_593121
  var valid_593122 = header.getOrDefault("X-Amz-Algorithm")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "X-Amz-Algorithm", valid_593122
  var valid_593123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-SignedHeaders", valid_593123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593125: Call_ListNamedQueries_593111; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provides a list of available query IDs only for queries saved in the specified workgroup. Requires that you have access to the workgroup.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  let valid = call_593125.validator(path, query, header, formData, body)
  let scheme = call_593125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593125.url(scheme.get, call_593125.host, call_593125.base,
                         call_593125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593125, url, valid)

proc call*(call_593126: Call_ListNamedQueries_593111; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listNamedQueries
  ## <p>Provides a list of available query IDs only for queries saved in the specified workgroup. Requires that you have access to the workgroup.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593127 = newJObject()
  var body_593128 = newJObject()
  add(query_593127, "MaxResults", newJString(MaxResults))
  add(query_593127, "NextToken", newJString(NextToken))
  if body != nil:
    body_593128 = body
  result = call_593126.call(nil, query_593127, nil, nil, body_593128)

var listNamedQueries* = Call_ListNamedQueries_593111(name: "listNamedQueries",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.ListNamedQueries",
    validator: validate_ListNamedQueries_593112, base: "/",
    url: url_ListNamedQueries_593113, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQueryExecutions_593129 = ref object of OpenApiRestCall_592364
proc url_ListQueryExecutions_593131(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListQueryExecutions_593130(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Provides a list of available query execution IDs for the queries in the specified workgroup. Requires you to have access to the workgroup in which the queries ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593132 = query.getOrDefault("MaxResults")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "MaxResults", valid_593132
  var valid_593133 = query.getOrDefault("NextToken")
  valid_593133 = validateParameter(valid_593133, JString, required = false,
                                 default = nil)
  if valid_593133 != nil:
    section.add "NextToken", valid_593133
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593134 = header.getOrDefault("X-Amz-Target")
  valid_593134 = validateParameter(valid_593134, JString, required = true, default = newJString(
      "AmazonAthena.ListQueryExecutions"))
  if valid_593134 != nil:
    section.add "X-Amz-Target", valid_593134
  var valid_593135 = header.getOrDefault("X-Amz-Signature")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "X-Amz-Signature", valid_593135
  var valid_593136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593136 = validateParameter(valid_593136, JString, required = false,
                                 default = nil)
  if valid_593136 != nil:
    section.add "X-Amz-Content-Sha256", valid_593136
  var valid_593137 = header.getOrDefault("X-Amz-Date")
  valid_593137 = validateParameter(valid_593137, JString, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "X-Amz-Date", valid_593137
  var valid_593138 = header.getOrDefault("X-Amz-Credential")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-Credential", valid_593138
  var valid_593139 = header.getOrDefault("X-Amz-Security-Token")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "X-Amz-Security-Token", valid_593139
  var valid_593140 = header.getOrDefault("X-Amz-Algorithm")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-Algorithm", valid_593140
  var valid_593141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-SignedHeaders", valid_593141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593143: Call_ListQueryExecutions_593129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provides a list of available query execution IDs for the queries in the specified workgroup. Requires you to have access to the workgroup in which the queries ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  let valid = call_593143.validator(path, query, header, formData, body)
  let scheme = call_593143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593143.url(scheme.get, call_593143.host, call_593143.base,
                         call_593143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593143, url, valid)

proc call*(call_593144: Call_ListQueryExecutions_593129; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listQueryExecutions
  ## <p>Provides a list of available query execution IDs for the queries in the specified workgroup. Requires you to have access to the workgroup in which the queries ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593145 = newJObject()
  var body_593146 = newJObject()
  add(query_593145, "MaxResults", newJString(MaxResults))
  add(query_593145, "NextToken", newJString(NextToken))
  if body != nil:
    body_593146 = body
  result = call_593144.call(nil, query_593145, nil, nil, body_593146)

var listQueryExecutions* = Call_ListQueryExecutions_593129(
    name: "listQueryExecutions", meth: HttpMethod.HttpPost,
    host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.ListQueryExecutions",
    validator: validate_ListQueryExecutions_593130, base: "/",
    url: url_ListQueryExecutions_593131, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_593147 = ref object of OpenApiRestCall_592364
proc url_ListTagsForResource_593149(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_593148(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the tags associated with this workgroup.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593150 = header.getOrDefault("X-Amz-Target")
  valid_593150 = validateParameter(valid_593150, JString, required = true, default = newJString(
      "AmazonAthena.ListTagsForResource"))
  if valid_593150 != nil:
    section.add "X-Amz-Target", valid_593150
  var valid_593151 = header.getOrDefault("X-Amz-Signature")
  valid_593151 = validateParameter(valid_593151, JString, required = false,
                                 default = nil)
  if valid_593151 != nil:
    section.add "X-Amz-Signature", valid_593151
  var valid_593152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593152 = validateParameter(valid_593152, JString, required = false,
                                 default = nil)
  if valid_593152 != nil:
    section.add "X-Amz-Content-Sha256", valid_593152
  var valid_593153 = header.getOrDefault("X-Amz-Date")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "X-Amz-Date", valid_593153
  var valid_593154 = header.getOrDefault("X-Amz-Credential")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "X-Amz-Credential", valid_593154
  var valid_593155 = header.getOrDefault("X-Amz-Security-Token")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "X-Amz-Security-Token", valid_593155
  var valid_593156 = header.getOrDefault("X-Amz-Algorithm")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "X-Amz-Algorithm", valid_593156
  var valid_593157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-SignedHeaders", valid_593157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593159: Call_ListTagsForResource_593147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags associated with this workgroup.
  ## 
  let valid = call_593159.validator(path, query, header, formData, body)
  let scheme = call_593159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593159.url(scheme.get, call_593159.host, call_593159.base,
                         call_593159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593159, url, valid)

proc call*(call_593160: Call_ListTagsForResource_593147; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists the tags associated with this workgroup.
  ##   body: JObject (required)
  var body_593161 = newJObject()
  if body != nil:
    body_593161 = body
  result = call_593160.call(nil, nil, nil, nil, body_593161)

var listTagsForResource* = Call_ListTagsForResource_593147(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.ListTagsForResource",
    validator: validate_ListTagsForResource_593148, base: "/",
    url: url_ListTagsForResource_593149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkGroups_593162 = ref object of OpenApiRestCall_592364
proc url_ListWorkGroups_593164(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListWorkGroups_593163(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists available workgroups for the account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593165 = query.getOrDefault("MaxResults")
  valid_593165 = validateParameter(valid_593165, JString, required = false,
                                 default = nil)
  if valid_593165 != nil:
    section.add "MaxResults", valid_593165
  var valid_593166 = query.getOrDefault("NextToken")
  valid_593166 = validateParameter(valid_593166, JString, required = false,
                                 default = nil)
  if valid_593166 != nil:
    section.add "NextToken", valid_593166
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593167 = header.getOrDefault("X-Amz-Target")
  valid_593167 = validateParameter(valid_593167, JString, required = true, default = newJString(
      "AmazonAthena.ListWorkGroups"))
  if valid_593167 != nil:
    section.add "X-Amz-Target", valid_593167
  var valid_593168 = header.getOrDefault("X-Amz-Signature")
  valid_593168 = validateParameter(valid_593168, JString, required = false,
                                 default = nil)
  if valid_593168 != nil:
    section.add "X-Amz-Signature", valid_593168
  var valid_593169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593169 = validateParameter(valid_593169, JString, required = false,
                                 default = nil)
  if valid_593169 != nil:
    section.add "X-Amz-Content-Sha256", valid_593169
  var valid_593170 = header.getOrDefault("X-Amz-Date")
  valid_593170 = validateParameter(valid_593170, JString, required = false,
                                 default = nil)
  if valid_593170 != nil:
    section.add "X-Amz-Date", valid_593170
  var valid_593171 = header.getOrDefault("X-Amz-Credential")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "X-Amz-Credential", valid_593171
  var valid_593172 = header.getOrDefault("X-Amz-Security-Token")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "X-Amz-Security-Token", valid_593172
  var valid_593173 = header.getOrDefault("X-Amz-Algorithm")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-Algorithm", valid_593173
  var valid_593174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "X-Amz-SignedHeaders", valid_593174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593176: Call_ListWorkGroups_593162; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists available workgroups for the account.
  ## 
  let valid = call_593176.validator(path, query, header, formData, body)
  let scheme = call_593176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593176.url(scheme.get, call_593176.host, call_593176.base,
                         call_593176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593176, url, valid)

proc call*(call_593177: Call_ListWorkGroups_593162; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listWorkGroups
  ## Lists available workgroups for the account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593178 = newJObject()
  var body_593179 = newJObject()
  add(query_593178, "MaxResults", newJString(MaxResults))
  add(query_593178, "NextToken", newJString(NextToken))
  if body != nil:
    body_593179 = body
  result = call_593177.call(nil, query_593178, nil, nil, body_593179)

var listWorkGroups* = Call_ListWorkGroups_593162(name: "listWorkGroups",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.ListWorkGroups",
    validator: validate_ListWorkGroups_593163, base: "/", url: url_ListWorkGroups_593164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartQueryExecution_593180 = ref object of OpenApiRestCall_592364
proc url_StartQueryExecution_593182(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartQueryExecution_593181(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Runs the SQL query statements contained in the <code>Query</code>. Requires you to have access to the workgroup in which the query ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593183 = header.getOrDefault("X-Amz-Target")
  valid_593183 = validateParameter(valid_593183, JString, required = true, default = newJString(
      "AmazonAthena.StartQueryExecution"))
  if valid_593183 != nil:
    section.add "X-Amz-Target", valid_593183
  var valid_593184 = header.getOrDefault("X-Amz-Signature")
  valid_593184 = validateParameter(valid_593184, JString, required = false,
                                 default = nil)
  if valid_593184 != nil:
    section.add "X-Amz-Signature", valid_593184
  var valid_593185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593185 = validateParameter(valid_593185, JString, required = false,
                                 default = nil)
  if valid_593185 != nil:
    section.add "X-Amz-Content-Sha256", valid_593185
  var valid_593186 = header.getOrDefault("X-Amz-Date")
  valid_593186 = validateParameter(valid_593186, JString, required = false,
                                 default = nil)
  if valid_593186 != nil:
    section.add "X-Amz-Date", valid_593186
  var valid_593187 = header.getOrDefault("X-Amz-Credential")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-Credential", valid_593187
  var valid_593188 = header.getOrDefault("X-Amz-Security-Token")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-Security-Token", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-Algorithm")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-Algorithm", valid_593189
  var valid_593190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "X-Amz-SignedHeaders", valid_593190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593192: Call_StartQueryExecution_593180; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Runs the SQL query statements contained in the <code>Query</code>. Requires you to have access to the workgroup in which the query ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  let valid = call_593192.validator(path, query, header, formData, body)
  let scheme = call_593192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593192.url(scheme.get, call_593192.host, call_593192.base,
                         call_593192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593192, url, valid)

proc call*(call_593193: Call_StartQueryExecution_593180; body: JsonNode): Recallable =
  ## startQueryExecution
  ## <p>Runs the SQL query statements contained in the <code>Query</code>. Requires you to have access to the workgroup in which the query ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ##   body: JObject (required)
  var body_593194 = newJObject()
  if body != nil:
    body_593194 = body
  result = call_593193.call(nil, nil, nil, nil, body_593194)

var startQueryExecution* = Call_StartQueryExecution_593180(
    name: "startQueryExecution", meth: HttpMethod.HttpPost,
    host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.StartQueryExecution",
    validator: validate_StartQueryExecution_593181, base: "/",
    url: url_StartQueryExecution_593182, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopQueryExecution_593195 = ref object of OpenApiRestCall_592364
proc url_StopQueryExecution_593197(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopQueryExecution_593196(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Stops a query execution. Requires you to have access to the workgroup in which the query ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593198 = header.getOrDefault("X-Amz-Target")
  valid_593198 = validateParameter(valid_593198, JString, required = true, default = newJString(
      "AmazonAthena.StopQueryExecution"))
  if valid_593198 != nil:
    section.add "X-Amz-Target", valid_593198
  var valid_593199 = header.getOrDefault("X-Amz-Signature")
  valid_593199 = validateParameter(valid_593199, JString, required = false,
                                 default = nil)
  if valid_593199 != nil:
    section.add "X-Amz-Signature", valid_593199
  var valid_593200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593200 = validateParameter(valid_593200, JString, required = false,
                                 default = nil)
  if valid_593200 != nil:
    section.add "X-Amz-Content-Sha256", valid_593200
  var valid_593201 = header.getOrDefault("X-Amz-Date")
  valid_593201 = validateParameter(valid_593201, JString, required = false,
                                 default = nil)
  if valid_593201 != nil:
    section.add "X-Amz-Date", valid_593201
  var valid_593202 = header.getOrDefault("X-Amz-Credential")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-Credential", valid_593202
  var valid_593203 = header.getOrDefault("X-Amz-Security-Token")
  valid_593203 = validateParameter(valid_593203, JString, required = false,
                                 default = nil)
  if valid_593203 != nil:
    section.add "X-Amz-Security-Token", valid_593203
  var valid_593204 = header.getOrDefault("X-Amz-Algorithm")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "X-Amz-Algorithm", valid_593204
  var valid_593205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-SignedHeaders", valid_593205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593207: Call_StopQueryExecution_593195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a query execution. Requires you to have access to the workgroup in which the query ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  let valid = call_593207.validator(path, query, header, formData, body)
  let scheme = call_593207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593207.url(scheme.get, call_593207.host, call_593207.base,
                         call_593207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593207, url, valid)

proc call*(call_593208: Call_StopQueryExecution_593195; body: JsonNode): Recallable =
  ## stopQueryExecution
  ## <p>Stops a query execution. Requires you to have access to the workgroup in which the query ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ##   body: JObject (required)
  var body_593209 = newJObject()
  if body != nil:
    body_593209 = body
  result = call_593208.call(nil, nil, nil, nil, body_593209)

var stopQueryExecution* = Call_StopQueryExecution_593195(
    name: "stopQueryExecution", meth: HttpMethod.HttpPost,
    host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.StopQueryExecution",
    validator: validate_StopQueryExecution_593196, base: "/",
    url: url_StopQueryExecution_593197, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_593210 = ref object of OpenApiRestCall_592364
proc url_TagResource_593212(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_593211(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds one or more tags to the resource, such as a workgroup. A tag is a label that you assign to an AWS Athena resource (a workgroup). Each tag consists of a key and an optional value, both of which you define. Tags enable you to categorize resources (workgroups) in Athena, for example, by purpose, owner, or environment. Use a consistent set of tag keys to make it easier to search and filter workgroups in your account. For best practices, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>. The key length is from 1 (minimum) to 128 (maximum) Unicode characters in UTF-8. The tag value length is from 0 (minimum) to 256 (maximum) Unicode characters in UTF-8. You can use letters and numbers representable in UTF-8, and the following characters: + - = . _ : / @. Tag keys and values are case-sensitive. Tag keys must be unique per resource. If you specify more than one, separate them by commas.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593213 = header.getOrDefault("X-Amz-Target")
  valid_593213 = validateParameter(valid_593213, JString, required = true, default = newJString(
      "AmazonAthena.TagResource"))
  if valid_593213 != nil:
    section.add "X-Amz-Target", valid_593213
  var valid_593214 = header.getOrDefault("X-Amz-Signature")
  valid_593214 = validateParameter(valid_593214, JString, required = false,
                                 default = nil)
  if valid_593214 != nil:
    section.add "X-Amz-Signature", valid_593214
  var valid_593215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593215 = validateParameter(valid_593215, JString, required = false,
                                 default = nil)
  if valid_593215 != nil:
    section.add "X-Amz-Content-Sha256", valid_593215
  var valid_593216 = header.getOrDefault("X-Amz-Date")
  valid_593216 = validateParameter(valid_593216, JString, required = false,
                                 default = nil)
  if valid_593216 != nil:
    section.add "X-Amz-Date", valid_593216
  var valid_593217 = header.getOrDefault("X-Amz-Credential")
  valid_593217 = validateParameter(valid_593217, JString, required = false,
                                 default = nil)
  if valid_593217 != nil:
    section.add "X-Amz-Credential", valid_593217
  var valid_593218 = header.getOrDefault("X-Amz-Security-Token")
  valid_593218 = validateParameter(valid_593218, JString, required = false,
                                 default = nil)
  if valid_593218 != nil:
    section.add "X-Amz-Security-Token", valid_593218
  var valid_593219 = header.getOrDefault("X-Amz-Algorithm")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "X-Amz-Algorithm", valid_593219
  var valid_593220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593220 = validateParameter(valid_593220, JString, required = false,
                                 default = nil)
  if valid_593220 != nil:
    section.add "X-Amz-SignedHeaders", valid_593220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593222: Call_TagResource_593210; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to the resource, such as a workgroup. A tag is a label that you assign to an AWS Athena resource (a workgroup). Each tag consists of a key and an optional value, both of which you define. Tags enable you to categorize resources (workgroups) in Athena, for example, by purpose, owner, or environment. Use a consistent set of tag keys to make it easier to search and filter workgroups in your account. For best practices, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>. The key length is from 1 (minimum) to 128 (maximum) Unicode characters in UTF-8. The tag value length is from 0 (minimum) to 256 (maximum) Unicode characters in UTF-8. You can use letters and numbers representable in UTF-8, and the following characters: + - = . _ : / @. Tag keys and values are case-sensitive. Tag keys must be unique per resource. If you specify more than one, separate them by commas.
  ## 
  let valid = call_593222.validator(path, query, header, formData, body)
  let scheme = call_593222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593222.url(scheme.get, call_593222.host, call_593222.base,
                         call_593222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593222, url, valid)

proc call*(call_593223: Call_TagResource_593210; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags to the resource, such as a workgroup. A tag is a label that you assign to an AWS Athena resource (a workgroup). Each tag consists of a key and an optional value, both of which you define. Tags enable you to categorize resources (workgroups) in Athena, for example, by purpose, owner, or environment. Use a consistent set of tag keys to make it easier to search and filter workgroups in your account. For best practices, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>. The key length is from 1 (minimum) to 128 (maximum) Unicode characters in UTF-8. The tag value length is from 0 (minimum) to 256 (maximum) Unicode characters in UTF-8. You can use letters and numbers representable in UTF-8, and the following characters: + - = . _ : / @. Tag keys and values are case-sensitive. Tag keys must be unique per resource. If you specify more than one, separate them by commas.
  ##   body: JObject (required)
  var body_593224 = newJObject()
  if body != nil:
    body_593224 = body
  result = call_593223.call(nil, nil, nil, nil, body_593224)

var tagResource* = Call_TagResource_593210(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "athena.amazonaws.com", route: "/#X-Amz-Target=AmazonAthena.TagResource",
                                        validator: validate_TagResource_593211,
                                        base: "/", url: url_TagResource_593212,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_593225 = ref object of OpenApiRestCall_592364
proc url_UntagResource_593227(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_593226(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes one or more tags from the workgroup resource. Takes as an input a list of TagKey Strings separated by commas, and removes their tags at the same time.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593228 = header.getOrDefault("X-Amz-Target")
  valid_593228 = validateParameter(valid_593228, JString, required = true, default = newJString(
      "AmazonAthena.UntagResource"))
  if valid_593228 != nil:
    section.add "X-Amz-Target", valid_593228
  var valid_593229 = header.getOrDefault("X-Amz-Signature")
  valid_593229 = validateParameter(valid_593229, JString, required = false,
                                 default = nil)
  if valid_593229 != nil:
    section.add "X-Amz-Signature", valid_593229
  var valid_593230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593230 = validateParameter(valid_593230, JString, required = false,
                                 default = nil)
  if valid_593230 != nil:
    section.add "X-Amz-Content-Sha256", valid_593230
  var valid_593231 = header.getOrDefault("X-Amz-Date")
  valid_593231 = validateParameter(valid_593231, JString, required = false,
                                 default = nil)
  if valid_593231 != nil:
    section.add "X-Amz-Date", valid_593231
  var valid_593232 = header.getOrDefault("X-Amz-Credential")
  valid_593232 = validateParameter(valid_593232, JString, required = false,
                                 default = nil)
  if valid_593232 != nil:
    section.add "X-Amz-Credential", valid_593232
  var valid_593233 = header.getOrDefault("X-Amz-Security-Token")
  valid_593233 = validateParameter(valid_593233, JString, required = false,
                                 default = nil)
  if valid_593233 != nil:
    section.add "X-Amz-Security-Token", valid_593233
  var valid_593234 = header.getOrDefault("X-Amz-Algorithm")
  valid_593234 = validateParameter(valid_593234, JString, required = false,
                                 default = nil)
  if valid_593234 != nil:
    section.add "X-Amz-Algorithm", valid_593234
  var valid_593235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593235 = validateParameter(valid_593235, JString, required = false,
                                 default = nil)
  if valid_593235 != nil:
    section.add "X-Amz-SignedHeaders", valid_593235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593237: Call_UntagResource_593225; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the workgroup resource. Takes as an input a list of TagKey Strings separated by commas, and removes their tags at the same time.
  ## 
  let valid = call_593237.validator(path, query, header, formData, body)
  let scheme = call_593237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593237.url(scheme.get, call_593237.host, call_593237.base,
                         call_593237.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593237, url, valid)

proc call*(call_593238: Call_UntagResource_593225; body: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags from the workgroup resource. Takes as an input a list of TagKey Strings separated by commas, and removes their tags at the same time.
  ##   body: JObject (required)
  var body_593239 = newJObject()
  if body != nil:
    body_593239 = body
  result = call_593238.call(nil, nil, nil, nil, body_593239)

var untagResource* = Call_UntagResource_593225(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.UntagResource",
    validator: validate_UntagResource_593226, base: "/", url: url_UntagResource_593227,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkGroup_593240 = ref object of OpenApiRestCall_592364
proc url_UpdateWorkGroup_593242(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateWorkGroup_593241(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Updates the workgroup with the specified name. The workgroup's name cannot be changed.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593243 = header.getOrDefault("X-Amz-Target")
  valid_593243 = validateParameter(valid_593243, JString, required = true, default = newJString(
      "AmazonAthena.UpdateWorkGroup"))
  if valid_593243 != nil:
    section.add "X-Amz-Target", valid_593243
  var valid_593244 = header.getOrDefault("X-Amz-Signature")
  valid_593244 = validateParameter(valid_593244, JString, required = false,
                                 default = nil)
  if valid_593244 != nil:
    section.add "X-Amz-Signature", valid_593244
  var valid_593245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593245 = validateParameter(valid_593245, JString, required = false,
                                 default = nil)
  if valid_593245 != nil:
    section.add "X-Amz-Content-Sha256", valid_593245
  var valid_593246 = header.getOrDefault("X-Amz-Date")
  valid_593246 = validateParameter(valid_593246, JString, required = false,
                                 default = nil)
  if valid_593246 != nil:
    section.add "X-Amz-Date", valid_593246
  var valid_593247 = header.getOrDefault("X-Amz-Credential")
  valid_593247 = validateParameter(valid_593247, JString, required = false,
                                 default = nil)
  if valid_593247 != nil:
    section.add "X-Amz-Credential", valid_593247
  var valid_593248 = header.getOrDefault("X-Amz-Security-Token")
  valid_593248 = validateParameter(valid_593248, JString, required = false,
                                 default = nil)
  if valid_593248 != nil:
    section.add "X-Amz-Security-Token", valid_593248
  var valid_593249 = header.getOrDefault("X-Amz-Algorithm")
  valid_593249 = validateParameter(valid_593249, JString, required = false,
                                 default = nil)
  if valid_593249 != nil:
    section.add "X-Amz-Algorithm", valid_593249
  var valid_593250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593250 = validateParameter(valid_593250, JString, required = false,
                                 default = nil)
  if valid_593250 != nil:
    section.add "X-Amz-SignedHeaders", valid_593250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593252: Call_UpdateWorkGroup_593240; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the workgroup with the specified name. The workgroup's name cannot be changed.
  ## 
  let valid = call_593252.validator(path, query, header, formData, body)
  let scheme = call_593252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593252.url(scheme.get, call_593252.host, call_593252.base,
                         call_593252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593252, url, valid)

proc call*(call_593253: Call_UpdateWorkGroup_593240; body: JsonNode): Recallable =
  ## updateWorkGroup
  ## Updates the workgroup with the specified name. The workgroup's name cannot be changed.
  ##   body: JObject (required)
  var body_593254 = newJObject()
  if body != nil:
    body_593254 = body
  result = call_593253.call(nil, nil, nil, nil, body_593254)

var updateWorkGroup* = Call_UpdateWorkGroup_593240(name: "updateWorkGroup",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.UpdateWorkGroup",
    validator: validate_UpdateWorkGroup_593241, base: "/", url: url_UpdateWorkGroup_593242,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
