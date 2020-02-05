
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchGetNamedQuery_612996 = ref object of OpenApiRestCall_612658
proc url_BatchGetNamedQuery_612998(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetNamedQuery_612997(path: JsonNode; query: JsonNode;
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
  var valid_613123 = header.getOrDefault("X-Amz-Target")
  valid_613123 = validateParameter(valid_613123, JString, required = true, default = newJString(
      "AmazonAthena.BatchGetNamedQuery"))
  if valid_613123 != nil:
    section.add "X-Amz-Target", valid_613123
  var valid_613124 = header.getOrDefault("X-Amz-Signature")
  valid_613124 = validateParameter(valid_613124, JString, required = false,
                                 default = nil)
  if valid_613124 != nil:
    section.add "X-Amz-Signature", valid_613124
  var valid_613125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-Content-Sha256", valid_613125
  var valid_613126 = header.getOrDefault("X-Amz-Date")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Date", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Credential")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Credential", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Security-Token")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Security-Token", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Algorithm")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Algorithm", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-SignedHeaders", valid_613130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613154: Call_BatchGetNamedQuery_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the details of a single named query or a list of up to 50 queries, which you provide as an array of query ID strings. Requires you to have access to the workgroup in which the queries were saved. Use <a>ListNamedQueriesInput</a> to get the list of named query IDs in the specified workgroup. If information could not be retrieved for a submitted query ID, information about the query ID submitted is listed under <a>UnprocessedNamedQueryId</a>. Named queries differ from executed queries. Use <a>BatchGetQueryExecutionInput</a> to get details about each unique query execution, and <a>ListQueryExecutionsInput</a> to get a list of query execution IDs.
  ## 
  let valid = call_613154.validator(path, query, header, formData, body)
  let scheme = call_613154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613154.url(scheme.get, call_613154.host, call_613154.base,
                         call_613154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613154, url, valid)

proc call*(call_613225: Call_BatchGetNamedQuery_612996; body: JsonNode): Recallable =
  ## batchGetNamedQuery
  ## Returns the details of a single named query or a list of up to 50 queries, which you provide as an array of query ID strings. Requires you to have access to the workgroup in which the queries were saved. Use <a>ListNamedQueriesInput</a> to get the list of named query IDs in the specified workgroup. If information could not be retrieved for a submitted query ID, information about the query ID submitted is listed under <a>UnprocessedNamedQueryId</a>. Named queries differ from executed queries. Use <a>BatchGetQueryExecutionInput</a> to get details about each unique query execution, and <a>ListQueryExecutionsInput</a> to get a list of query execution IDs.
  ##   body: JObject (required)
  var body_613226 = newJObject()
  if body != nil:
    body_613226 = body
  result = call_613225.call(nil, nil, nil, nil, body_613226)

var batchGetNamedQuery* = Call_BatchGetNamedQuery_612996(
    name: "batchGetNamedQuery", meth: HttpMethod.HttpPost,
    host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.BatchGetNamedQuery",
    validator: validate_BatchGetNamedQuery_612997, base: "/",
    url: url_BatchGetNamedQuery_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetQueryExecution_613265 = ref object of OpenApiRestCall_612658
proc url_BatchGetQueryExecution_613267(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetQueryExecution_613266(path: JsonNode; query: JsonNode;
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
  var valid_613268 = header.getOrDefault("X-Amz-Target")
  valid_613268 = validateParameter(valid_613268, JString, required = true, default = newJString(
      "AmazonAthena.BatchGetQueryExecution"))
  if valid_613268 != nil:
    section.add "X-Amz-Target", valid_613268
  var valid_613269 = header.getOrDefault("X-Amz-Signature")
  valid_613269 = validateParameter(valid_613269, JString, required = false,
                                 default = nil)
  if valid_613269 != nil:
    section.add "X-Amz-Signature", valid_613269
  var valid_613270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Content-Sha256", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Date")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Date", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Credential")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Credential", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Security-Token")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Security-Token", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Algorithm")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Algorithm", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-SignedHeaders", valid_613275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613277: Call_BatchGetQueryExecution_613265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the details of a single query execution or a list of up to 50 query executions, which you provide as an array of query execution ID strings. Requires you to have access to the workgroup in which the queries ran. To get a list of query execution IDs, use <a>ListQueryExecutionsInput$WorkGroup</a>. Query executions differ from named (saved) queries. Use <a>BatchGetNamedQueryInput</a> to get details about named queries.
  ## 
  let valid = call_613277.validator(path, query, header, formData, body)
  let scheme = call_613277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613277.url(scheme.get, call_613277.host, call_613277.base,
                         call_613277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613277, url, valid)

proc call*(call_613278: Call_BatchGetQueryExecution_613265; body: JsonNode): Recallable =
  ## batchGetQueryExecution
  ## Returns the details of a single query execution or a list of up to 50 query executions, which you provide as an array of query execution ID strings. Requires you to have access to the workgroup in which the queries ran. To get a list of query execution IDs, use <a>ListQueryExecutionsInput$WorkGroup</a>. Query executions differ from named (saved) queries. Use <a>BatchGetNamedQueryInput</a> to get details about named queries.
  ##   body: JObject (required)
  var body_613279 = newJObject()
  if body != nil:
    body_613279 = body
  result = call_613278.call(nil, nil, nil, nil, body_613279)

var batchGetQueryExecution* = Call_BatchGetQueryExecution_613265(
    name: "batchGetQueryExecution", meth: HttpMethod.HttpPost,
    host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.BatchGetQueryExecution",
    validator: validate_BatchGetQueryExecution_613266, base: "/",
    url: url_BatchGetQueryExecution_613267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNamedQuery_613280 = ref object of OpenApiRestCall_612658
proc url_CreateNamedQuery_613282(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateNamedQuery_613281(path: JsonNode; query: JsonNode;
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
  var valid_613283 = header.getOrDefault("X-Amz-Target")
  valid_613283 = validateParameter(valid_613283, JString, required = true, default = newJString(
      "AmazonAthena.CreateNamedQuery"))
  if valid_613283 != nil:
    section.add "X-Amz-Target", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-Signature")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-Signature", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Content-Sha256", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Date")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Date", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Credential")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Credential", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Security-Token")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Security-Token", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Algorithm")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Algorithm", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-SignedHeaders", valid_613290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613292: Call_CreateNamedQuery_613280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a named query in the specified workgroup. Requires that you have access to the workgroup.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  let valid = call_613292.validator(path, query, header, formData, body)
  let scheme = call_613292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613292.url(scheme.get, call_613292.host, call_613292.base,
                         call_613292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613292, url, valid)

proc call*(call_613293: Call_CreateNamedQuery_613280; body: JsonNode): Recallable =
  ## createNamedQuery
  ## <p>Creates a named query in the specified workgroup. Requires that you have access to the workgroup.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ##   body: JObject (required)
  var body_613294 = newJObject()
  if body != nil:
    body_613294 = body
  result = call_613293.call(nil, nil, nil, nil, body_613294)

var createNamedQuery* = Call_CreateNamedQuery_613280(name: "createNamedQuery",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.CreateNamedQuery",
    validator: validate_CreateNamedQuery_613281, base: "/",
    url: url_CreateNamedQuery_613282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkGroup_613295 = ref object of OpenApiRestCall_612658
proc url_CreateWorkGroup_613297(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateWorkGroup_613296(path: JsonNode; query: JsonNode;
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
  var valid_613298 = header.getOrDefault("X-Amz-Target")
  valid_613298 = validateParameter(valid_613298, JString, required = true, default = newJString(
      "AmazonAthena.CreateWorkGroup"))
  if valid_613298 != nil:
    section.add "X-Amz-Target", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Signature")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Signature", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Content-Sha256", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Date")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Date", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Credential")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Credential", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Security-Token")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Security-Token", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Algorithm")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Algorithm", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-SignedHeaders", valid_613305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613307: Call_CreateWorkGroup_613295; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a workgroup with the specified name.
  ## 
  let valid = call_613307.validator(path, query, header, formData, body)
  let scheme = call_613307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613307.url(scheme.get, call_613307.host, call_613307.base,
                         call_613307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613307, url, valid)

proc call*(call_613308: Call_CreateWorkGroup_613295; body: JsonNode): Recallable =
  ## createWorkGroup
  ## Creates a workgroup with the specified name.
  ##   body: JObject (required)
  var body_613309 = newJObject()
  if body != nil:
    body_613309 = body
  result = call_613308.call(nil, nil, nil, nil, body_613309)

var createWorkGroup* = Call_CreateWorkGroup_613295(name: "createWorkGroup",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.CreateWorkGroup",
    validator: validate_CreateWorkGroup_613296, base: "/", url: url_CreateWorkGroup_613297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNamedQuery_613310 = ref object of OpenApiRestCall_612658
proc url_DeleteNamedQuery_613312(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteNamedQuery_613311(path: JsonNode; query: JsonNode;
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
  var valid_613313 = header.getOrDefault("X-Amz-Target")
  valid_613313 = validateParameter(valid_613313, JString, required = true, default = newJString(
      "AmazonAthena.DeleteNamedQuery"))
  if valid_613313 != nil:
    section.add "X-Amz-Target", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Signature")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Signature", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Content-Sha256", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Date")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Date", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Credential")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Credential", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Security-Token")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Security-Token", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Algorithm")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Algorithm", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-SignedHeaders", valid_613320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613322: Call_DeleteNamedQuery_613310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the named query if you have access to the workgroup in which the query was saved.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  let valid = call_613322.validator(path, query, header, formData, body)
  let scheme = call_613322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613322.url(scheme.get, call_613322.host, call_613322.base,
                         call_613322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613322, url, valid)

proc call*(call_613323: Call_DeleteNamedQuery_613310; body: JsonNode): Recallable =
  ## deleteNamedQuery
  ## <p>Deletes the named query if you have access to the workgroup in which the query was saved.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ##   body: JObject (required)
  var body_613324 = newJObject()
  if body != nil:
    body_613324 = body
  result = call_613323.call(nil, nil, nil, nil, body_613324)

var deleteNamedQuery* = Call_DeleteNamedQuery_613310(name: "deleteNamedQuery",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.DeleteNamedQuery",
    validator: validate_DeleteNamedQuery_613311, base: "/",
    url: url_DeleteNamedQuery_613312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkGroup_613325 = ref object of OpenApiRestCall_612658
proc url_DeleteWorkGroup_613327(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteWorkGroup_613326(path: JsonNode; query: JsonNode;
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
  var valid_613328 = header.getOrDefault("X-Amz-Target")
  valid_613328 = validateParameter(valid_613328, JString, required = true, default = newJString(
      "AmazonAthena.DeleteWorkGroup"))
  if valid_613328 != nil:
    section.add "X-Amz-Target", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Signature")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Signature", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Content-Sha256", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Date")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Date", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Credential")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Credential", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Security-Token")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Security-Token", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Algorithm")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Algorithm", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-SignedHeaders", valid_613335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613337: Call_DeleteWorkGroup_613325; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the workgroup with the specified name. The primary workgroup cannot be deleted.
  ## 
  let valid = call_613337.validator(path, query, header, formData, body)
  let scheme = call_613337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613337.url(scheme.get, call_613337.host, call_613337.base,
                         call_613337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613337, url, valid)

proc call*(call_613338: Call_DeleteWorkGroup_613325; body: JsonNode): Recallable =
  ## deleteWorkGroup
  ## Deletes the workgroup with the specified name. The primary workgroup cannot be deleted.
  ##   body: JObject (required)
  var body_613339 = newJObject()
  if body != nil:
    body_613339 = body
  result = call_613338.call(nil, nil, nil, nil, body_613339)

var deleteWorkGroup* = Call_DeleteWorkGroup_613325(name: "deleteWorkGroup",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.DeleteWorkGroup",
    validator: validate_DeleteWorkGroup_613326, base: "/", url: url_DeleteWorkGroup_613327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNamedQuery_613340 = ref object of OpenApiRestCall_612658
proc url_GetNamedQuery_613342(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetNamedQuery_613341(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613343 = header.getOrDefault("X-Amz-Target")
  valid_613343 = validateParameter(valid_613343, JString, required = true, default = newJString(
      "AmazonAthena.GetNamedQuery"))
  if valid_613343 != nil:
    section.add "X-Amz-Target", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Signature")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Signature", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Content-Sha256", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Date")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Date", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Credential")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Credential", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Security-Token")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Security-Token", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Algorithm")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Algorithm", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-SignedHeaders", valid_613350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613352: Call_GetNamedQuery_613340; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a single query. Requires that you have access to the workgroup in which the query was saved.
  ## 
  let valid = call_613352.validator(path, query, header, formData, body)
  let scheme = call_613352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613352.url(scheme.get, call_613352.host, call_613352.base,
                         call_613352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613352, url, valid)

proc call*(call_613353: Call_GetNamedQuery_613340; body: JsonNode): Recallable =
  ## getNamedQuery
  ## Returns information about a single query. Requires that you have access to the workgroup in which the query was saved.
  ##   body: JObject (required)
  var body_613354 = newJObject()
  if body != nil:
    body_613354 = body
  result = call_613353.call(nil, nil, nil, nil, body_613354)

var getNamedQuery* = Call_GetNamedQuery_613340(name: "getNamedQuery",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.GetNamedQuery",
    validator: validate_GetNamedQuery_613341, base: "/", url: url_GetNamedQuery_613342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQueryExecution_613355 = ref object of OpenApiRestCall_612658
proc url_GetQueryExecution_613357(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetQueryExecution_613356(path: JsonNode; query: JsonNode;
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
  var valid_613358 = header.getOrDefault("X-Amz-Target")
  valid_613358 = validateParameter(valid_613358, JString, required = true, default = newJString(
      "AmazonAthena.GetQueryExecution"))
  if valid_613358 != nil:
    section.add "X-Amz-Target", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Signature")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Signature", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Content-Sha256", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Date")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Date", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Credential")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Credential", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Security-Token")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Security-Token", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Algorithm")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Algorithm", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-SignedHeaders", valid_613365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613367: Call_GetQueryExecution_613355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a single execution of a query if you have access to the workgroup in which the query ran. Each time a query executes, information about the query execution is saved with a unique ID.
  ## 
  let valid = call_613367.validator(path, query, header, formData, body)
  let scheme = call_613367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613367.url(scheme.get, call_613367.host, call_613367.base,
                         call_613367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613367, url, valid)

proc call*(call_613368: Call_GetQueryExecution_613355; body: JsonNode): Recallable =
  ## getQueryExecution
  ## Returns information about a single execution of a query if you have access to the workgroup in which the query ran. Each time a query executes, information about the query execution is saved with a unique ID.
  ##   body: JObject (required)
  var body_613369 = newJObject()
  if body != nil:
    body_613369 = body
  result = call_613368.call(nil, nil, nil, nil, body_613369)

var getQueryExecution* = Call_GetQueryExecution_613355(name: "getQueryExecution",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.GetQueryExecution",
    validator: validate_GetQueryExecution_613356, base: "/",
    url: url_GetQueryExecution_613357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQueryResults_613370 = ref object of OpenApiRestCall_612658
proc url_GetQueryResults_613372(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetQueryResults_613371(path: JsonNode; query: JsonNode;
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
  var valid_613373 = query.getOrDefault("MaxResults")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "MaxResults", valid_613373
  var valid_613374 = query.getOrDefault("NextToken")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "NextToken", valid_613374
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
  var valid_613375 = header.getOrDefault("X-Amz-Target")
  valid_613375 = validateParameter(valid_613375, JString, required = true, default = newJString(
      "AmazonAthena.GetQueryResults"))
  if valid_613375 != nil:
    section.add "X-Amz-Target", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Signature")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Signature", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Content-Sha256", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Date")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Date", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Credential")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Credential", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-Security-Token")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-Security-Token", valid_613380
  var valid_613381 = header.getOrDefault("X-Amz-Algorithm")
  valid_613381 = validateParameter(valid_613381, JString, required = false,
                                 default = nil)
  if valid_613381 != nil:
    section.add "X-Amz-Algorithm", valid_613381
  var valid_613382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613382 = validateParameter(valid_613382, JString, required = false,
                                 default = nil)
  if valid_613382 != nil:
    section.add "X-Amz-SignedHeaders", valid_613382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613384: Call_GetQueryResults_613370; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Streams the results of a single query execution specified by <code>QueryExecutionId</code> from the Athena query results location in Amazon S3. For more information, see <a href="https://docs.aws.amazon.com/athena/latest/ug/querying.html">Query Results</a> in the <i>Amazon Athena User Guide</i>. This request does not execute the query but returns results. Use <a>StartQueryExecution</a> to run a query.</p> <p>To stream query results successfully, the IAM principal with permission to call <code>GetQueryResults</code> also must have permissions to the Amazon S3 <code>GetObject</code> action for the Athena query results location.</p> <important> <p>IAM principals with permission to the Amazon S3 <code>GetObject</code> action for the query results location are able to retrieve query results from Amazon S3 even if permission to the <code>GetQueryResults</code> action is denied. To restrict user or role access, ensure that Amazon S3 permissions to the Athena query location are denied.</p> </important>
  ## 
  let valid = call_613384.validator(path, query, header, formData, body)
  let scheme = call_613384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613384.url(scheme.get, call_613384.host, call_613384.base,
                         call_613384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613384, url, valid)

proc call*(call_613385: Call_GetQueryResults_613370; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getQueryResults
  ## <p>Streams the results of a single query execution specified by <code>QueryExecutionId</code> from the Athena query results location in Amazon S3. For more information, see <a href="https://docs.aws.amazon.com/athena/latest/ug/querying.html">Query Results</a> in the <i>Amazon Athena User Guide</i>. This request does not execute the query but returns results. Use <a>StartQueryExecution</a> to run a query.</p> <p>To stream query results successfully, the IAM principal with permission to call <code>GetQueryResults</code> also must have permissions to the Amazon S3 <code>GetObject</code> action for the Athena query results location.</p> <important> <p>IAM principals with permission to the Amazon S3 <code>GetObject</code> action for the query results location are able to retrieve query results from Amazon S3 even if permission to the <code>GetQueryResults</code> action is denied. To restrict user or role access, ensure that Amazon S3 permissions to the Athena query location are denied.</p> </important>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613386 = newJObject()
  var body_613387 = newJObject()
  add(query_613386, "MaxResults", newJString(MaxResults))
  add(query_613386, "NextToken", newJString(NextToken))
  if body != nil:
    body_613387 = body
  result = call_613385.call(nil, query_613386, nil, nil, body_613387)

var getQueryResults* = Call_GetQueryResults_613370(name: "getQueryResults",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.GetQueryResults",
    validator: validate_GetQueryResults_613371, base: "/", url: url_GetQueryResults_613372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkGroup_613389 = ref object of OpenApiRestCall_612658
proc url_GetWorkGroup_613391(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetWorkGroup_613390(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613392 = header.getOrDefault("X-Amz-Target")
  valid_613392 = validateParameter(valid_613392, JString, required = true, default = newJString(
      "AmazonAthena.GetWorkGroup"))
  if valid_613392 != nil:
    section.add "X-Amz-Target", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Signature")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Signature", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Content-Sha256", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-Date")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-Date", valid_613395
  var valid_613396 = header.getOrDefault("X-Amz-Credential")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "X-Amz-Credential", valid_613396
  var valid_613397 = header.getOrDefault("X-Amz-Security-Token")
  valid_613397 = validateParameter(valid_613397, JString, required = false,
                                 default = nil)
  if valid_613397 != nil:
    section.add "X-Amz-Security-Token", valid_613397
  var valid_613398 = header.getOrDefault("X-Amz-Algorithm")
  valid_613398 = validateParameter(valid_613398, JString, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "X-Amz-Algorithm", valid_613398
  var valid_613399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613399 = validateParameter(valid_613399, JString, required = false,
                                 default = nil)
  if valid_613399 != nil:
    section.add "X-Amz-SignedHeaders", valid_613399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613401: Call_GetWorkGroup_613389; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the workgroup with the specified name.
  ## 
  let valid = call_613401.validator(path, query, header, formData, body)
  let scheme = call_613401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613401.url(scheme.get, call_613401.host, call_613401.base,
                         call_613401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613401, url, valid)

proc call*(call_613402: Call_GetWorkGroup_613389; body: JsonNode): Recallable =
  ## getWorkGroup
  ## Returns information about the workgroup with the specified name.
  ##   body: JObject (required)
  var body_613403 = newJObject()
  if body != nil:
    body_613403 = body
  result = call_613402.call(nil, nil, nil, nil, body_613403)

var getWorkGroup* = Call_GetWorkGroup_613389(name: "getWorkGroup",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.GetWorkGroup",
    validator: validate_GetWorkGroup_613390, base: "/", url: url_GetWorkGroup_613391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNamedQueries_613404 = ref object of OpenApiRestCall_612658
proc url_ListNamedQueries_613406(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListNamedQueries_613405(path: JsonNode; query: JsonNode;
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
  var valid_613407 = query.getOrDefault("MaxResults")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "MaxResults", valid_613407
  var valid_613408 = query.getOrDefault("NextToken")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "NextToken", valid_613408
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
  var valid_613409 = header.getOrDefault("X-Amz-Target")
  valid_613409 = validateParameter(valid_613409, JString, required = true, default = newJString(
      "AmazonAthena.ListNamedQueries"))
  if valid_613409 != nil:
    section.add "X-Amz-Target", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-Signature")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-Signature", valid_613410
  var valid_613411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613411 = validateParameter(valid_613411, JString, required = false,
                                 default = nil)
  if valid_613411 != nil:
    section.add "X-Amz-Content-Sha256", valid_613411
  var valid_613412 = header.getOrDefault("X-Amz-Date")
  valid_613412 = validateParameter(valid_613412, JString, required = false,
                                 default = nil)
  if valid_613412 != nil:
    section.add "X-Amz-Date", valid_613412
  var valid_613413 = header.getOrDefault("X-Amz-Credential")
  valid_613413 = validateParameter(valid_613413, JString, required = false,
                                 default = nil)
  if valid_613413 != nil:
    section.add "X-Amz-Credential", valid_613413
  var valid_613414 = header.getOrDefault("X-Amz-Security-Token")
  valid_613414 = validateParameter(valid_613414, JString, required = false,
                                 default = nil)
  if valid_613414 != nil:
    section.add "X-Amz-Security-Token", valid_613414
  var valid_613415 = header.getOrDefault("X-Amz-Algorithm")
  valid_613415 = validateParameter(valid_613415, JString, required = false,
                                 default = nil)
  if valid_613415 != nil:
    section.add "X-Amz-Algorithm", valid_613415
  var valid_613416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "X-Amz-SignedHeaders", valid_613416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613418: Call_ListNamedQueries_613404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provides a list of available query IDs only for queries saved in the specified workgroup. Requires that you have access to the workgroup.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  let valid = call_613418.validator(path, query, header, formData, body)
  let scheme = call_613418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613418.url(scheme.get, call_613418.host, call_613418.base,
                         call_613418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613418, url, valid)

proc call*(call_613419: Call_ListNamedQueries_613404; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listNamedQueries
  ## <p>Provides a list of available query IDs only for queries saved in the specified workgroup. Requires that you have access to the workgroup.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613420 = newJObject()
  var body_613421 = newJObject()
  add(query_613420, "MaxResults", newJString(MaxResults))
  add(query_613420, "NextToken", newJString(NextToken))
  if body != nil:
    body_613421 = body
  result = call_613419.call(nil, query_613420, nil, nil, body_613421)

var listNamedQueries* = Call_ListNamedQueries_613404(name: "listNamedQueries",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.ListNamedQueries",
    validator: validate_ListNamedQueries_613405, base: "/",
    url: url_ListNamedQueries_613406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQueryExecutions_613422 = ref object of OpenApiRestCall_612658
proc url_ListQueryExecutions_613424(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListQueryExecutions_613423(path: JsonNode; query: JsonNode;
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
  var valid_613425 = query.getOrDefault("MaxResults")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "MaxResults", valid_613425
  var valid_613426 = query.getOrDefault("NextToken")
  valid_613426 = validateParameter(valid_613426, JString, required = false,
                                 default = nil)
  if valid_613426 != nil:
    section.add "NextToken", valid_613426
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
  var valid_613427 = header.getOrDefault("X-Amz-Target")
  valid_613427 = validateParameter(valid_613427, JString, required = true, default = newJString(
      "AmazonAthena.ListQueryExecutions"))
  if valid_613427 != nil:
    section.add "X-Amz-Target", valid_613427
  var valid_613428 = header.getOrDefault("X-Amz-Signature")
  valid_613428 = validateParameter(valid_613428, JString, required = false,
                                 default = nil)
  if valid_613428 != nil:
    section.add "X-Amz-Signature", valid_613428
  var valid_613429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613429 = validateParameter(valid_613429, JString, required = false,
                                 default = nil)
  if valid_613429 != nil:
    section.add "X-Amz-Content-Sha256", valid_613429
  var valid_613430 = header.getOrDefault("X-Amz-Date")
  valid_613430 = validateParameter(valid_613430, JString, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "X-Amz-Date", valid_613430
  var valid_613431 = header.getOrDefault("X-Amz-Credential")
  valid_613431 = validateParameter(valid_613431, JString, required = false,
                                 default = nil)
  if valid_613431 != nil:
    section.add "X-Amz-Credential", valid_613431
  var valid_613432 = header.getOrDefault("X-Amz-Security-Token")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "X-Amz-Security-Token", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-Algorithm")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-Algorithm", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-SignedHeaders", valid_613434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613436: Call_ListQueryExecutions_613422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provides a list of available query execution IDs for the queries in the specified workgroup. Requires you to have access to the workgroup in which the queries ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  let valid = call_613436.validator(path, query, header, formData, body)
  let scheme = call_613436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613436.url(scheme.get, call_613436.host, call_613436.base,
                         call_613436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613436, url, valid)

proc call*(call_613437: Call_ListQueryExecutions_613422; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listQueryExecutions
  ## <p>Provides a list of available query execution IDs for the queries in the specified workgroup. Requires you to have access to the workgroup in which the queries ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613438 = newJObject()
  var body_613439 = newJObject()
  add(query_613438, "MaxResults", newJString(MaxResults))
  add(query_613438, "NextToken", newJString(NextToken))
  if body != nil:
    body_613439 = body
  result = call_613437.call(nil, query_613438, nil, nil, body_613439)

var listQueryExecutions* = Call_ListQueryExecutions_613422(
    name: "listQueryExecutions", meth: HttpMethod.HttpPost,
    host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.ListQueryExecutions",
    validator: validate_ListQueryExecutions_613423, base: "/",
    url: url_ListQueryExecutions_613424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613440 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613442(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_613441(path: JsonNode; query: JsonNode;
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
  var valid_613443 = header.getOrDefault("X-Amz-Target")
  valid_613443 = validateParameter(valid_613443, JString, required = true, default = newJString(
      "AmazonAthena.ListTagsForResource"))
  if valid_613443 != nil:
    section.add "X-Amz-Target", valid_613443
  var valid_613444 = header.getOrDefault("X-Amz-Signature")
  valid_613444 = validateParameter(valid_613444, JString, required = false,
                                 default = nil)
  if valid_613444 != nil:
    section.add "X-Amz-Signature", valid_613444
  var valid_613445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "X-Amz-Content-Sha256", valid_613445
  var valid_613446 = header.getOrDefault("X-Amz-Date")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "X-Amz-Date", valid_613446
  var valid_613447 = header.getOrDefault("X-Amz-Credential")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Credential", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-Security-Token")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Security-Token", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Algorithm")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Algorithm", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-SignedHeaders", valid_613450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613452: Call_ListTagsForResource_613440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags associated with this workgroup.
  ## 
  let valid = call_613452.validator(path, query, header, formData, body)
  let scheme = call_613452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613452.url(scheme.get, call_613452.host, call_613452.base,
                         call_613452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613452, url, valid)

proc call*(call_613453: Call_ListTagsForResource_613440; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists the tags associated with this workgroup.
  ##   body: JObject (required)
  var body_613454 = newJObject()
  if body != nil:
    body_613454 = body
  result = call_613453.call(nil, nil, nil, nil, body_613454)

var listTagsForResource* = Call_ListTagsForResource_613440(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.ListTagsForResource",
    validator: validate_ListTagsForResource_613441, base: "/",
    url: url_ListTagsForResource_613442, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkGroups_613455 = ref object of OpenApiRestCall_612658
proc url_ListWorkGroups_613457(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListWorkGroups_613456(path: JsonNode; query: JsonNode;
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
  var valid_613458 = query.getOrDefault("MaxResults")
  valid_613458 = validateParameter(valid_613458, JString, required = false,
                                 default = nil)
  if valid_613458 != nil:
    section.add "MaxResults", valid_613458
  var valid_613459 = query.getOrDefault("NextToken")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "NextToken", valid_613459
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
  var valid_613460 = header.getOrDefault("X-Amz-Target")
  valid_613460 = validateParameter(valid_613460, JString, required = true, default = newJString(
      "AmazonAthena.ListWorkGroups"))
  if valid_613460 != nil:
    section.add "X-Amz-Target", valid_613460
  var valid_613461 = header.getOrDefault("X-Amz-Signature")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "X-Amz-Signature", valid_613461
  var valid_613462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "X-Amz-Content-Sha256", valid_613462
  var valid_613463 = header.getOrDefault("X-Amz-Date")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-Date", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Credential")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Credential", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Security-Token")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Security-Token", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Algorithm")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Algorithm", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-SignedHeaders", valid_613467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613469: Call_ListWorkGroups_613455; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists available workgroups for the account.
  ## 
  let valid = call_613469.validator(path, query, header, formData, body)
  let scheme = call_613469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613469.url(scheme.get, call_613469.host, call_613469.base,
                         call_613469.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613469, url, valid)

proc call*(call_613470: Call_ListWorkGroups_613455; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listWorkGroups
  ## Lists available workgroups for the account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613471 = newJObject()
  var body_613472 = newJObject()
  add(query_613471, "MaxResults", newJString(MaxResults))
  add(query_613471, "NextToken", newJString(NextToken))
  if body != nil:
    body_613472 = body
  result = call_613470.call(nil, query_613471, nil, nil, body_613472)

var listWorkGroups* = Call_ListWorkGroups_613455(name: "listWorkGroups",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.ListWorkGroups",
    validator: validate_ListWorkGroups_613456, base: "/", url: url_ListWorkGroups_613457,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartQueryExecution_613473 = ref object of OpenApiRestCall_612658
proc url_StartQueryExecution_613475(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartQueryExecution_613474(path: JsonNode; query: JsonNode;
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
  var valid_613476 = header.getOrDefault("X-Amz-Target")
  valid_613476 = validateParameter(valid_613476, JString, required = true, default = newJString(
      "AmazonAthena.StartQueryExecution"))
  if valid_613476 != nil:
    section.add "X-Amz-Target", valid_613476
  var valid_613477 = header.getOrDefault("X-Amz-Signature")
  valid_613477 = validateParameter(valid_613477, JString, required = false,
                                 default = nil)
  if valid_613477 != nil:
    section.add "X-Amz-Signature", valid_613477
  var valid_613478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "X-Amz-Content-Sha256", valid_613478
  var valid_613479 = header.getOrDefault("X-Amz-Date")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Date", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-Credential")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Credential", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Security-Token")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Security-Token", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Algorithm")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Algorithm", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-SignedHeaders", valid_613483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613485: Call_StartQueryExecution_613473; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Runs the SQL query statements contained in the <code>Query</code>. Requires you to have access to the workgroup in which the query ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  let valid = call_613485.validator(path, query, header, formData, body)
  let scheme = call_613485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613485.url(scheme.get, call_613485.host, call_613485.base,
                         call_613485.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613485, url, valid)

proc call*(call_613486: Call_StartQueryExecution_613473; body: JsonNode): Recallable =
  ## startQueryExecution
  ## <p>Runs the SQL query statements contained in the <code>Query</code>. Requires you to have access to the workgroup in which the query ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ##   body: JObject (required)
  var body_613487 = newJObject()
  if body != nil:
    body_613487 = body
  result = call_613486.call(nil, nil, nil, nil, body_613487)

var startQueryExecution* = Call_StartQueryExecution_613473(
    name: "startQueryExecution", meth: HttpMethod.HttpPost,
    host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.StartQueryExecution",
    validator: validate_StartQueryExecution_613474, base: "/",
    url: url_StartQueryExecution_613475, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopQueryExecution_613488 = ref object of OpenApiRestCall_612658
proc url_StopQueryExecution_613490(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopQueryExecution_613489(path: JsonNode; query: JsonNode;
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
  var valid_613491 = header.getOrDefault("X-Amz-Target")
  valid_613491 = validateParameter(valid_613491, JString, required = true, default = newJString(
      "AmazonAthena.StopQueryExecution"))
  if valid_613491 != nil:
    section.add "X-Amz-Target", valid_613491
  var valid_613492 = header.getOrDefault("X-Amz-Signature")
  valid_613492 = validateParameter(valid_613492, JString, required = false,
                                 default = nil)
  if valid_613492 != nil:
    section.add "X-Amz-Signature", valid_613492
  var valid_613493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613493 = validateParameter(valid_613493, JString, required = false,
                                 default = nil)
  if valid_613493 != nil:
    section.add "X-Amz-Content-Sha256", valid_613493
  var valid_613494 = header.getOrDefault("X-Amz-Date")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "X-Amz-Date", valid_613494
  var valid_613495 = header.getOrDefault("X-Amz-Credential")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-Credential", valid_613495
  var valid_613496 = header.getOrDefault("X-Amz-Security-Token")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-Security-Token", valid_613496
  var valid_613497 = header.getOrDefault("X-Amz-Algorithm")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-Algorithm", valid_613497
  var valid_613498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-SignedHeaders", valid_613498
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613500: Call_StopQueryExecution_613488; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a query execution. Requires you to have access to the workgroup in which the query ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  let valid = call_613500.validator(path, query, header, formData, body)
  let scheme = call_613500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613500.url(scheme.get, call_613500.host, call_613500.base,
                         call_613500.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613500, url, valid)

proc call*(call_613501: Call_StopQueryExecution_613488; body: JsonNode): Recallable =
  ## stopQueryExecution
  ## <p>Stops a query execution. Requires you to have access to the workgroup in which the query ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ##   body: JObject (required)
  var body_613502 = newJObject()
  if body != nil:
    body_613502 = body
  result = call_613501.call(nil, nil, nil, nil, body_613502)

var stopQueryExecution* = Call_StopQueryExecution_613488(
    name: "stopQueryExecution", meth: HttpMethod.HttpPost,
    host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.StopQueryExecution",
    validator: validate_StopQueryExecution_613489, base: "/",
    url: url_StopQueryExecution_613490, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613503 = ref object of OpenApiRestCall_612658
proc url_TagResource_613505(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_613504(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613506 = header.getOrDefault("X-Amz-Target")
  valid_613506 = validateParameter(valid_613506, JString, required = true, default = newJString(
      "AmazonAthena.TagResource"))
  if valid_613506 != nil:
    section.add "X-Amz-Target", valid_613506
  var valid_613507 = header.getOrDefault("X-Amz-Signature")
  valid_613507 = validateParameter(valid_613507, JString, required = false,
                                 default = nil)
  if valid_613507 != nil:
    section.add "X-Amz-Signature", valid_613507
  var valid_613508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613508 = validateParameter(valid_613508, JString, required = false,
                                 default = nil)
  if valid_613508 != nil:
    section.add "X-Amz-Content-Sha256", valid_613508
  var valid_613509 = header.getOrDefault("X-Amz-Date")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "X-Amz-Date", valid_613509
  var valid_613510 = header.getOrDefault("X-Amz-Credential")
  valid_613510 = validateParameter(valid_613510, JString, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "X-Amz-Credential", valid_613510
  var valid_613511 = header.getOrDefault("X-Amz-Security-Token")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-Security-Token", valid_613511
  var valid_613512 = header.getOrDefault("X-Amz-Algorithm")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-Algorithm", valid_613512
  var valid_613513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-SignedHeaders", valid_613513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613515: Call_TagResource_613503; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to the resource, such as a workgroup. A tag is a label that you assign to an AWS Athena resource (a workgroup). Each tag consists of a key and an optional value, both of which you define. Tags enable you to categorize resources (workgroups) in Athena, for example, by purpose, owner, or environment. Use a consistent set of tag keys to make it easier to search and filter workgroups in your account. For best practices, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>. The key length is from 1 (minimum) to 128 (maximum) Unicode characters in UTF-8. The tag value length is from 0 (minimum) to 256 (maximum) Unicode characters in UTF-8. You can use letters and numbers representable in UTF-8, and the following characters: + - = . _ : / @. Tag keys and values are case-sensitive. Tag keys must be unique per resource. If you specify more than one, separate them by commas.
  ## 
  let valid = call_613515.validator(path, query, header, formData, body)
  let scheme = call_613515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613515.url(scheme.get, call_613515.host, call_613515.base,
                         call_613515.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613515, url, valid)

proc call*(call_613516: Call_TagResource_613503; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags to the resource, such as a workgroup. A tag is a label that you assign to an AWS Athena resource (a workgroup). Each tag consists of a key and an optional value, both of which you define. Tags enable you to categorize resources (workgroups) in Athena, for example, by purpose, owner, or environment. Use a consistent set of tag keys to make it easier to search and filter workgroups in your account. For best practices, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>. The key length is from 1 (minimum) to 128 (maximum) Unicode characters in UTF-8. The tag value length is from 0 (minimum) to 256 (maximum) Unicode characters in UTF-8. You can use letters and numbers representable in UTF-8, and the following characters: + - = . _ : / @. Tag keys and values are case-sensitive. Tag keys must be unique per resource. If you specify more than one, separate them by commas.
  ##   body: JObject (required)
  var body_613517 = newJObject()
  if body != nil:
    body_613517 = body
  result = call_613516.call(nil, nil, nil, nil, body_613517)

var tagResource* = Call_TagResource_613503(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "athena.amazonaws.com", route: "/#X-Amz-Target=AmazonAthena.TagResource",
                                        validator: validate_TagResource_613504,
                                        base: "/", url: url_TagResource_613505,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613518 = ref object of OpenApiRestCall_612658
proc url_UntagResource_613520(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_613519(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613521 = header.getOrDefault("X-Amz-Target")
  valid_613521 = validateParameter(valid_613521, JString, required = true, default = newJString(
      "AmazonAthena.UntagResource"))
  if valid_613521 != nil:
    section.add "X-Amz-Target", valid_613521
  var valid_613522 = header.getOrDefault("X-Amz-Signature")
  valid_613522 = validateParameter(valid_613522, JString, required = false,
                                 default = nil)
  if valid_613522 != nil:
    section.add "X-Amz-Signature", valid_613522
  var valid_613523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613523 = validateParameter(valid_613523, JString, required = false,
                                 default = nil)
  if valid_613523 != nil:
    section.add "X-Amz-Content-Sha256", valid_613523
  var valid_613524 = header.getOrDefault("X-Amz-Date")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "X-Amz-Date", valid_613524
  var valid_613525 = header.getOrDefault("X-Amz-Credential")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "X-Amz-Credential", valid_613525
  var valid_613526 = header.getOrDefault("X-Amz-Security-Token")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Security-Token", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-Algorithm")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Algorithm", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-SignedHeaders", valid_613528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613530: Call_UntagResource_613518; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the workgroup resource. Takes as an input a list of TagKey Strings separated by commas, and removes their tags at the same time.
  ## 
  let valid = call_613530.validator(path, query, header, formData, body)
  let scheme = call_613530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613530.url(scheme.get, call_613530.host, call_613530.base,
                         call_613530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613530, url, valid)

proc call*(call_613531: Call_UntagResource_613518; body: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags from the workgroup resource. Takes as an input a list of TagKey Strings separated by commas, and removes their tags at the same time.
  ##   body: JObject (required)
  var body_613532 = newJObject()
  if body != nil:
    body_613532 = body
  result = call_613531.call(nil, nil, nil, nil, body_613532)

var untagResource* = Call_UntagResource_613518(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.UntagResource",
    validator: validate_UntagResource_613519, base: "/", url: url_UntagResource_613520,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkGroup_613533 = ref object of OpenApiRestCall_612658
proc url_UpdateWorkGroup_613535(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateWorkGroup_613534(path: JsonNode; query: JsonNode;
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
  var valid_613536 = header.getOrDefault("X-Amz-Target")
  valid_613536 = validateParameter(valid_613536, JString, required = true, default = newJString(
      "AmazonAthena.UpdateWorkGroup"))
  if valid_613536 != nil:
    section.add "X-Amz-Target", valid_613536
  var valid_613537 = header.getOrDefault("X-Amz-Signature")
  valid_613537 = validateParameter(valid_613537, JString, required = false,
                                 default = nil)
  if valid_613537 != nil:
    section.add "X-Amz-Signature", valid_613537
  var valid_613538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613538 = validateParameter(valid_613538, JString, required = false,
                                 default = nil)
  if valid_613538 != nil:
    section.add "X-Amz-Content-Sha256", valid_613538
  var valid_613539 = header.getOrDefault("X-Amz-Date")
  valid_613539 = validateParameter(valid_613539, JString, required = false,
                                 default = nil)
  if valid_613539 != nil:
    section.add "X-Amz-Date", valid_613539
  var valid_613540 = header.getOrDefault("X-Amz-Credential")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "X-Amz-Credential", valid_613540
  var valid_613541 = header.getOrDefault("X-Amz-Security-Token")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Security-Token", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-Algorithm")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Algorithm", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-SignedHeaders", valid_613543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613545: Call_UpdateWorkGroup_613533; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the workgroup with the specified name. The workgroup's name cannot be changed.
  ## 
  let valid = call_613545.validator(path, query, header, formData, body)
  let scheme = call_613545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613545.url(scheme.get, call_613545.host, call_613545.base,
                         call_613545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613545, url, valid)

proc call*(call_613546: Call_UpdateWorkGroup_613533; body: JsonNode): Recallable =
  ## updateWorkGroup
  ## Updates the workgroup with the specified name. The workgroup's name cannot be changed.
  ##   body: JObject (required)
  var body_613547 = newJObject()
  if body != nil:
    body_613547 = body
  result = call_613546.call(nil, nil, nil, nil, body_613547)

var updateWorkGroup* = Call_UpdateWorkGroup_613533(name: "updateWorkGroup",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.UpdateWorkGroup",
    validator: validate_UpdateWorkGroup_613534, base: "/", url: url_UpdateWorkGroup_613535,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
