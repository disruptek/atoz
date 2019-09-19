
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_BatchGetNamedQuery_600768 = ref object of OpenApiRestCall_600426
proc url_BatchGetNamedQuery_600770(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchGetNamedQuery_600769(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600882 = header.getOrDefault("X-Amz-Date")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Date", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-Security-Token")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Security-Token", valid_600883
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600897 = header.getOrDefault("X-Amz-Target")
  valid_600897 = validateParameter(valid_600897, JString, required = true, default = newJString(
      "AmazonAthena.BatchGetNamedQuery"))
  if valid_600897 != nil:
    section.add "X-Amz-Target", valid_600897
  var valid_600898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-Content-Sha256", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-Algorithm")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Algorithm", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Signature")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Signature", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-SignedHeaders", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Credential")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Credential", valid_600902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600926: Call_BatchGetNamedQuery_600768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the details of a single named query or a list of up to 50 queries, which you provide as an array of query ID strings. Requires you to have access to the workgroup in which the queries were saved. Use <a>ListNamedQueriesInput</a> to get the list of named query IDs in the specified workgroup. If information could not be retrieved for a submitted query ID, information about the query ID submitted is listed under <a>UnprocessedNamedQueryId</a>. Named queries differ from executed queries. Use <a>BatchGetQueryExecutionInput</a> to get details about each unique query execution, and <a>ListQueryExecutionsInput</a> to get a list of query execution IDs.
  ## 
  let valid = call_600926.validator(path, query, header, formData, body)
  let scheme = call_600926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600926.url(scheme.get, call_600926.host, call_600926.base,
                         call_600926.route, valid.getOrDefault("path"))
  result = hook(call_600926, url, valid)

proc call*(call_600997: Call_BatchGetNamedQuery_600768; body: JsonNode): Recallable =
  ## batchGetNamedQuery
  ## Returns the details of a single named query or a list of up to 50 queries, which you provide as an array of query ID strings. Requires you to have access to the workgroup in which the queries were saved. Use <a>ListNamedQueriesInput</a> to get the list of named query IDs in the specified workgroup. If information could not be retrieved for a submitted query ID, information about the query ID submitted is listed under <a>UnprocessedNamedQueryId</a>. Named queries differ from executed queries. Use <a>BatchGetQueryExecutionInput</a> to get details about each unique query execution, and <a>ListQueryExecutionsInput</a> to get a list of query execution IDs.
  ##   body: JObject (required)
  var body_600998 = newJObject()
  if body != nil:
    body_600998 = body
  result = call_600997.call(nil, nil, nil, nil, body_600998)

var batchGetNamedQuery* = Call_BatchGetNamedQuery_600768(
    name: "batchGetNamedQuery", meth: HttpMethod.HttpPost,
    host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.BatchGetNamedQuery",
    validator: validate_BatchGetNamedQuery_600769, base: "/",
    url: url_BatchGetNamedQuery_600770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetQueryExecution_601037 = ref object of OpenApiRestCall_600426
proc url_BatchGetQueryExecution_601039(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchGetQueryExecution_601038(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601040 = header.getOrDefault("X-Amz-Date")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Date", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Security-Token")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Security-Token", valid_601041
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601042 = header.getOrDefault("X-Amz-Target")
  valid_601042 = validateParameter(valid_601042, JString, required = true, default = newJString(
      "AmazonAthena.BatchGetQueryExecution"))
  if valid_601042 != nil:
    section.add "X-Amz-Target", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Content-Sha256", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Algorithm")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Algorithm", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Signature")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Signature", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-SignedHeaders", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Credential")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Credential", valid_601047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601049: Call_BatchGetQueryExecution_601037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the details of a single query execution or a list of up to 50 query executions, which you provide as an array of query execution ID strings. Requires you to have access to the workgroup in which the queries ran. To get a list of query execution IDs, use <a>ListQueryExecutionsInput$WorkGroup</a>. Query executions differ from named (saved) queries. Use <a>BatchGetNamedQueryInput</a> to get details about named queries.
  ## 
  let valid = call_601049.validator(path, query, header, formData, body)
  let scheme = call_601049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601049.url(scheme.get, call_601049.host, call_601049.base,
                         call_601049.route, valid.getOrDefault("path"))
  result = hook(call_601049, url, valid)

proc call*(call_601050: Call_BatchGetQueryExecution_601037; body: JsonNode): Recallable =
  ## batchGetQueryExecution
  ## Returns the details of a single query execution or a list of up to 50 query executions, which you provide as an array of query execution ID strings. Requires you to have access to the workgroup in which the queries ran. To get a list of query execution IDs, use <a>ListQueryExecutionsInput$WorkGroup</a>. Query executions differ from named (saved) queries. Use <a>BatchGetNamedQueryInput</a> to get details about named queries.
  ##   body: JObject (required)
  var body_601051 = newJObject()
  if body != nil:
    body_601051 = body
  result = call_601050.call(nil, nil, nil, nil, body_601051)

var batchGetQueryExecution* = Call_BatchGetQueryExecution_601037(
    name: "batchGetQueryExecution", meth: HttpMethod.HttpPost,
    host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.BatchGetQueryExecution",
    validator: validate_BatchGetQueryExecution_601038, base: "/",
    url: url_BatchGetQueryExecution_601039, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNamedQuery_601052 = ref object of OpenApiRestCall_600426
proc url_CreateNamedQuery_601054(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateNamedQuery_601053(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601055 = header.getOrDefault("X-Amz-Date")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Date", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Security-Token")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Security-Token", valid_601056
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601057 = header.getOrDefault("X-Amz-Target")
  valid_601057 = validateParameter(valid_601057, JString, required = true, default = newJString(
      "AmazonAthena.CreateNamedQuery"))
  if valid_601057 != nil:
    section.add "X-Amz-Target", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Content-Sha256", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Algorithm")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Algorithm", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Signature")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Signature", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-SignedHeaders", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Credential")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Credential", valid_601062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601064: Call_CreateNamedQuery_601052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a named query in the specified workgroup. Requires that you have access to the workgroup.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  let valid = call_601064.validator(path, query, header, formData, body)
  let scheme = call_601064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601064.url(scheme.get, call_601064.host, call_601064.base,
                         call_601064.route, valid.getOrDefault("path"))
  result = hook(call_601064, url, valid)

proc call*(call_601065: Call_CreateNamedQuery_601052; body: JsonNode): Recallable =
  ## createNamedQuery
  ## <p>Creates a named query in the specified workgroup. Requires that you have access to the workgroup.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ##   body: JObject (required)
  var body_601066 = newJObject()
  if body != nil:
    body_601066 = body
  result = call_601065.call(nil, nil, nil, nil, body_601066)

var createNamedQuery* = Call_CreateNamedQuery_601052(name: "createNamedQuery",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.CreateNamedQuery",
    validator: validate_CreateNamedQuery_601053, base: "/",
    url: url_CreateNamedQuery_601054, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkGroup_601067 = ref object of OpenApiRestCall_600426
proc url_CreateWorkGroup_601069(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateWorkGroup_601068(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601070 = header.getOrDefault("X-Amz-Date")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Date", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Security-Token")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Security-Token", valid_601071
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601072 = header.getOrDefault("X-Amz-Target")
  valid_601072 = validateParameter(valid_601072, JString, required = true, default = newJString(
      "AmazonAthena.CreateWorkGroup"))
  if valid_601072 != nil:
    section.add "X-Amz-Target", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Content-Sha256", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Algorithm")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Algorithm", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Signature")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Signature", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-SignedHeaders", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Credential")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Credential", valid_601077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601079: Call_CreateWorkGroup_601067; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a workgroup with the specified name.
  ## 
  let valid = call_601079.validator(path, query, header, formData, body)
  let scheme = call_601079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601079.url(scheme.get, call_601079.host, call_601079.base,
                         call_601079.route, valid.getOrDefault("path"))
  result = hook(call_601079, url, valid)

proc call*(call_601080: Call_CreateWorkGroup_601067; body: JsonNode): Recallable =
  ## createWorkGroup
  ## Creates a workgroup with the specified name.
  ##   body: JObject (required)
  var body_601081 = newJObject()
  if body != nil:
    body_601081 = body
  result = call_601080.call(nil, nil, nil, nil, body_601081)

var createWorkGroup* = Call_CreateWorkGroup_601067(name: "createWorkGroup",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.CreateWorkGroup",
    validator: validate_CreateWorkGroup_601068, base: "/", url: url_CreateWorkGroup_601069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNamedQuery_601082 = ref object of OpenApiRestCall_600426
proc url_DeleteNamedQuery_601084(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteNamedQuery_601083(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601085 = header.getOrDefault("X-Amz-Date")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Date", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Security-Token")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Security-Token", valid_601086
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601087 = header.getOrDefault("X-Amz-Target")
  valid_601087 = validateParameter(valid_601087, JString, required = true, default = newJString(
      "AmazonAthena.DeleteNamedQuery"))
  if valid_601087 != nil:
    section.add "X-Amz-Target", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Content-Sha256", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Algorithm")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Algorithm", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Signature")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Signature", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-SignedHeaders", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Credential")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Credential", valid_601092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601094: Call_DeleteNamedQuery_601082; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the named query if you have access to the workgroup in which the query was saved.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  let valid = call_601094.validator(path, query, header, formData, body)
  let scheme = call_601094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601094.url(scheme.get, call_601094.host, call_601094.base,
                         call_601094.route, valid.getOrDefault("path"))
  result = hook(call_601094, url, valid)

proc call*(call_601095: Call_DeleteNamedQuery_601082; body: JsonNode): Recallable =
  ## deleteNamedQuery
  ## <p>Deletes the named query if you have access to the workgroup in which the query was saved.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ##   body: JObject (required)
  var body_601096 = newJObject()
  if body != nil:
    body_601096 = body
  result = call_601095.call(nil, nil, nil, nil, body_601096)

var deleteNamedQuery* = Call_DeleteNamedQuery_601082(name: "deleteNamedQuery",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.DeleteNamedQuery",
    validator: validate_DeleteNamedQuery_601083, base: "/",
    url: url_DeleteNamedQuery_601084, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkGroup_601097 = ref object of OpenApiRestCall_600426
proc url_DeleteWorkGroup_601099(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteWorkGroup_601098(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601100 = header.getOrDefault("X-Amz-Date")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Date", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Security-Token")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Security-Token", valid_601101
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601102 = header.getOrDefault("X-Amz-Target")
  valid_601102 = validateParameter(valid_601102, JString, required = true, default = newJString(
      "AmazonAthena.DeleteWorkGroup"))
  if valid_601102 != nil:
    section.add "X-Amz-Target", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Content-Sha256", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Algorithm")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Algorithm", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Signature")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Signature", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-SignedHeaders", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Credential")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Credential", valid_601107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601109: Call_DeleteWorkGroup_601097; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the workgroup with the specified name. The primary workgroup cannot be deleted.
  ## 
  let valid = call_601109.validator(path, query, header, formData, body)
  let scheme = call_601109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601109.url(scheme.get, call_601109.host, call_601109.base,
                         call_601109.route, valid.getOrDefault("path"))
  result = hook(call_601109, url, valid)

proc call*(call_601110: Call_DeleteWorkGroup_601097; body: JsonNode): Recallable =
  ## deleteWorkGroup
  ## Deletes the workgroup with the specified name. The primary workgroup cannot be deleted.
  ##   body: JObject (required)
  var body_601111 = newJObject()
  if body != nil:
    body_601111 = body
  result = call_601110.call(nil, nil, nil, nil, body_601111)

var deleteWorkGroup* = Call_DeleteWorkGroup_601097(name: "deleteWorkGroup",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.DeleteWorkGroup",
    validator: validate_DeleteWorkGroup_601098, base: "/", url: url_DeleteWorkGroup_601099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNamedQuery_601112 = ref object of OpenApiRestCall_600426
proc url_GetNamedQuery_601114(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetNamedQuery_601113(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601115 = header.getOrDefault("X-Amz-Date")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Date", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Security-Token")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Security-Token", valid_601116
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601117 = header.getOrDefault("X-Amz-Target")
  valid_601117 = validateParameter(valid_601117, JString, required = true, default = newJString(
      "AmazonAthena.GetNamedQuery"))
  if valid_601117 != nil:
    section.add "X-Amz-Target", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Content-Sha256", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Algorithm")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Algorithm", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Signature")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Signature", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-SignedHeaders", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Credential")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Credential", valid_601122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601124: Call_GetNamedQuery_601112; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a single query. Requires that you have access to the workgroup in which the query was saved.
  ## 
  let valid = call_601124.validator(path, query, header, formData, body)
  let scheme = call_601124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601124.url(scheme.get, call_601124.host, call_601124.base,
                         call_601124.route, valid.getOrDefault("path"))
  result = hook(call_601124, url, valid)

proc call*(call_601125: Call_GetNamedQuery_601112; body: JsonNode): Recallable =
  ## getNamedQuery
  ## Returns information about a single query. Requires that you have access to the workgroup in which the query was saved.
  ##   body: JObject (required)
  var body_601126 = newJObject()
  if body != nil:
    body_601126 = body
  result = call_601125.call(nil, nil, nil, nil, body_601126)

var getNamedQuery* = Call_GetNamedQuery_601112(name: "getNamedQuery",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.GetNamedQuery",
    validator: validate_GetNamedQuery_601113, base: "/", url: url_GetNamedQuery_601114,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQueryExecution_601127 = ref object of OpenApiRestCall_600426
proc url_GetQueryExecution_601129(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetQueryExecution_601128(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601130 = header.getOrDefault("X-Amz-Date")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Date", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Security-Token")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Security-Token", valid_601131
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601132 = header.getOrDefault("X-Amz-Target")
  valid_601132 = validateParameter(valid_601132, JString, required = true, default = newJString(
      "AmazonAthena.GetQueryExecution"))
  if valid_601132 != nil:
    section.add "X-Amz-Target", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Content-Sha256", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Algorithm")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Algorithm", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Signature")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Signature", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-SignedHeaders", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Credential")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Credential", valid_601137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601139: Call_GetQueryExecution_601127; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a single execution of a query if you have access to the workgroup in which the query ran. Each time a query executes, information about the query execution is saved with a unique ID.
  ## 
  let valid = call_601139.validator(path, query, header, formData, body)
  let scheme = call_601139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601139.url(scheme.get, call_601139.host, call_601139.base,
                         call_601139.route, valid.getOrDefault("path"))
  result = hook(call_601139, url, valid)

proc call*(call_601140: Call_GetQueryExecution_601127; body: JsonNode): Recallable =
  ## getQueryExecution
  ## Returns information about a single execution of a query if you have access to the workgroup in which the query ran. Each time a query executes, information about the query execution is saved with a unique ID.
  ##   body: JObject (required)
  var body_601141 = newJObject()
  if body != nil:
    body_601141 = body
  result = call_601140.call(nil, nil, nil, nil, body_601141)

var getQueryExecution* = Call_GetQueryExecution_601127(name: "getQueryExecution",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.GetQueryExecution",
    validator: validate_GetQueryExecution_601128, base: "/",
    url: url_GetQueryExecution_601129, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQueryResults_601142 = ref object of OpenApiRestCall_600426
proc url_GetQueryResults_601144(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetQueryResults_601143(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Streams the results of a single query execution specified by <code>QueryExecutionId</code> from the Athena query results location in Amazon S3. For more information, see <a href="https://docs.aws.amazon.com/athena/latest/ug/querying.html">Query Results</a> in the <i>Amazon Athena User Guide</i>. This request does not execute the query but returns results. Use <a>StartQueryExecution</a> to run a query.</p> <p>To stream query results successfully, the IAM principal with permission to call <code>GetQueryResults</code> also must have permissions to the Amazon S3 <code>GetObject</code> action for the Athena query results location.</p> <important> <p>IAM principals with permission to the Amazon S3 <code>GetObject</code> action for the query results location are able to retrieve query results from Amazon S3 even if permission to the <code>GetQueryResults</code> action is denied. To restrict user or role access, ensure that Amazon S3 permissions to the Athena query location are denied.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_601145 = query.getOrDefault("NextToken")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "NextToken", valid_601145
  var valid_601146 = query.getOrDefault("MaxResults")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "MaxResults", valid_601146
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601147 = header.getOrDefault("X-Amz-Date")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-Date", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Security-Token")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Security-Token", valid_601148
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601149 = header.getOrDefault("X-Amz-Target")
  valid_601149 = validateParameter(valid_601149, JString, required = true, default = newJString(
      "AmazonAthena.GetQueryResults"))
  if valid_601149 != nil:
    section.add "X-Amz-Target", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Content-Sha256", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-Algorithm")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Algorithm", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Signature")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Signature", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-SignedHeaders", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Credential")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Credential", valid_601154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601156: Call_GetQueryResults_601142; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Streams the results of a single query execution specified by <code>QueryExecutionId</code> from the Athena query results location in Amazon S3. For more information, see <a href="https://docs.aws.amazon.com/athena/latest/ug/querying.html">Query Results</a> in the <i>Amazon Athena User Guide</i>. This request does not execute the query but returns results. Use <a>StartQueryExecution</a> to run a query.</p> <p>To stream query results successfully, the IAM principal with permission to call <code>GetQueryResults</code> also must have permissions to the Amazon S3 <code>GetObject</code> action for the Athena query results location.</p> <important> <p>IAM principals with permission to the Amazon S3 <code>GetObject</code> action for the query results location are able to retrieve query results from Amazon S3 even if permission to the <code>GetQueryResults</code> action is denied. To restrict user or role access, ensure that Amazon S3 permissions to the Athena query location are denied.</p> </important>
  ## 
  let valid = call_601156.validator(path, query, header, formData, body)
  let scheme = call_601156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601156.url(scheme.get, call_601156.host, call_601156.base,
                         call_601156.route, valid.getOrDefault("path"))
  result = hook(call_601156, url, valid)

proc call*(call_601157: Call_GetQueryResults_601142; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getQueryResults
  ## <p>Streams the results of a single query execution specified by <code>QueryExecutionId</code> from the Athena query results location in Amazon S3. For more information, see <a href="https://docs.aws.amazon.com/athena/latest/ug/querying.html">Query Results</a> in the <i>Amazon Athena User Guide</i>. This request does not execute the query but returns results. Use <a>StartQueryExecution</a> to run a query.</p> <p>To stream query results successfully, the IAM principal with permission to call <code>GetQueryResults</code> also must have permissions to the Amazon S3 <code>GetObject</code> action for the Athena query results location.</p> <important> <p>IAM principals with permission to the Amazon S3 <code>GetObject</code> action for the query results location are able to retrieve query results from Amazon S3 even if permission to the <code>GetQueryResults</code> action is denied. To restrict user or role access, ensure that Amazon S3 permissions to the Athena query location are denied.</p> </important>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601158 = newJObject()
  var body_601159 = newJObject()
  add(query_601158, "NextToken", newJString(NextToken))
  if body != nil:
    body_601159 = body
  add(query_601158, "MaxResults", newJString(MaxResults))
  result = call_601157.call(nil, query_601158, nil, nil, body_601159)

var getQueryResults* = Call_GetQueryResults_601142(name: "getQueryResults",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.GetQueryResults",
    validator: validate_GetQueryResults_601143, base: "/", url: url_GetQueryResults_601144,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkGroup_601161 = ref object of OpenApiRestCall_600426
proc url_GetWorkGroup_601163(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetWorkGroup_601162(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601164 = header.getOrDefault("X-Amz-Date")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Date", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Security-Token")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Security-Token", valid_601165
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601166 = header.getOrDefault("X-Amz-Target")
  valid_601166 = validateParameter(valid_601166, JString, required = true, default = newJString(
      "AmazonAthena.GetWorkGroup"))
  if valid_601166 != nil:
    section.add "X-Amz-Target", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Content-Sha256", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Algorithm")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Algorithm", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Signature")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Signature", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-SignedHeaders", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-Credential")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Credential", valid_601171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601173: Call_GetWorkGroup_601161; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the workgroup with the specified name.
  ## 
  let valid = call_601173.validator(path, query, header, formData, body)
  let scheme = call_601173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601173.url(scheme.get, call_601173.host, call_601173.base,
                         call_601173.route, valid.getOrDefault("path"))
  result = hook(call_601173, url, valid)

proc call*(call_601174: Call_GetWorkGroup_601161; body: JsonNode): Recallable =
  ## getWorkGroup
  ## Returns information about the workgroup with the specified name.
  ##   body: JObject (required)
  var body_601175 = newJObject()
  if body != nil:
    body_601175 = body
  result = call_601174.call(nil, nil, nil, nil, body_601175)

var getWorkGroup* = Call_GetWorkGroup_601161(name: "getWorkGroup",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.GetWorkGroup",
    validator: validate_GetWorkGroup_601162, base: "/", url: url_GetWorkGroup_601163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNamedQueries_601176 = ref object of OpenApiRestCall_600426
proc url_ListNamedQueries_601178(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListNamedQueries_601177(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Provides a list of available query IDs only for queries saved in the specified workgroup. Requires that you have access to the workgroup.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_601179 = query.getOrDefault("NextToken")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "NextToken", valid_601179
  var valid_601180 = query.getOrDefault("MaxResults")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "MaxResults", valid_601180
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601181 = header.getOrDefault("X-Amz-Date")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-Date", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Security-Token")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Security-Token", valid_601182
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601183 = header.getOrDefault("X-Amz-Target")
  valid_601183 = validateParameter(valid_601183, JString, required = true, default = newJString(
      "AmazonAthena.ListNamedQueries"))
  if valid_601183 != nil:
    section.add "X-Amz-Target", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Content-Sha256", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Algorithm")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Algorithm", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Signature")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Signature", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-SignedHeaders", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-Credential")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Credential", valid_601188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601190: Call_ListNamedQueries_601176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provides a list of available query IDs only for queries saved in the specified workgroup. Requires that you have access to the workgroup.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  let valid = call_601190.validator(path, query, header, formData, body)
  let scheme = call_601190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601190.url(scheme.get, call_601190.host, call_601190.base,
                         call_601190.route, valid.getOrDefault("path"))
  result = hook(call_601190, url, valid)

proc call*(call_601191: Call_ListNamedQueries_601176; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listNamedQueries
  ## <p>Provides a list of available query IDs only for queries saved in the specified workgroup. Requires that you have access to the workgroup.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601192 = newJObject()
  var body_601193 = newJObject()
  add(query_601192, "NextToken", newJString(NextToken))
  if body != nil:
    body_601193 = body
  add(query_601192, "MaxResults", newJString(MaxResults))
  result = call_601191.call(nil, query_601192, nil, nil, body_601193)

var listNamedQueries* = Call_ListNamedQueries_601176(name: "listNamedQueries",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.ListNamedQueries",
    validator: validate_ListNamedQueries_601177, base: "/",
    url: url_ListNamedQueries_601178, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQueryExecutions_601194 = ref object of OpenApiRestCall_600426
proc url_ListQueryExecutions_601196(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListQueryExecutions_601195(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Provides a list of available query execution IDs for the queries in the specified workgroup. Requires you to have access to the workgroup in which the queries ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_601197 = query.getOrDefault("NextToken")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "NextToken", valid_601197
  var valid_601198 = query.getOrDefault("MaxResults")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "MaxResults", valid_601198
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601199 = header.getOrDefault("X-Amz-Date")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Date", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-Security-Token")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Security-Token", valid_601200
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601201 = header.getOrDefault("X-Amz-Target")
  valid_601201 = validateParameter(valid_601201, JString, required = true, default = newJString(
      "AmazonAthena.ListQueryExecutions"))
  if valid_601201 != nil:
    section.add "X-Amz-Target", valid_601201
  var valid_601202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-Content-Sha256", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-Algorithm")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Algorithm", valid_601203
  var valid_601204 = header.getOrDefault("X-Amz-Signature")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "X-Amz-Signature", valid_601204
  var valid_601205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-SignedHeaders", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-Credential")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Credential", valid_601206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601208: Call_ListQueryExecutions_601194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provides a list of available query execution IDs for the queries in the specified workgroup. Requires you to have access to the workgroup in which the queries ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  let valid = call_601208.validator(path, query, header, formData, body)
  let scheme = call_601208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601208.url(scheme.get, call_601208.host, call_601208.base,
                         call_601208.route, valid.getOrDefault("path"))
  result = hook(call_601208, url, valid)

proc call*(call_601209: Call_ListQueryExecutions_601194; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listQueryExecutions
  ## <p>Provides a list of available query execution IDs for the queries in the specified workgroup. Requires you to have access to the workgroup in which the queries ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601210 = newJObject()
  var body_601211 = newJObject()
  add(query_601210, "NextToken", newJString(NextToken))
  if body != nil:
    body_601211 = body
  add(query_601210, "MaxResults", newJString(MaxResults))
  result = call_601209.call(nil, query_601210, nil, nil, body_601211)

var listQueryExecutions* = Call_ListQueryExecutions_601194(
    name: "listQueryExecutions", meth: HttpMethod.HttpPost,
    host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.ListQueryExecutions",
    validator: validate_ListQueryExecutions_601195, base: "/",
    url: url_ListQueryExecutions_601196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_601212 = ref object of OpenApiRestCall_600426
proc url_ListTagsForResource_601214(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_601213(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601215 = header.getOrDefault("X-Amz-Date")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-Date", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-Security-Token")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Security-Token", valid_601216
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601217 = header.getOrDefault("X-Amz-Target")
  valid_601217 = validateParameter(valid_601217, JString, required = true, default = newJString(
      "AmazonAthena.ListTagsForResource"))
  if valid_601217 != nil:
    section.add "X-Amz-Target", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Content-Sha256", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-Algorithm")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-Algorithm", valid_601219
  var valid_601220 = header.getOrDefault("X-Amz-Signature")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Signature", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-SignedHeaders", valid_601221
  var valid_601222 = header.getOrDefault("X-Amz-Credential")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "X-Amz-Credential", valid_601222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601224: Call_ListTagsForResource_601212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags associated with this workgroup.
  ## 
  let valid = call_601224.validator(path, query, header, formData, body)
  let scheme = call_601224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601224.url(scheme.get, call_601224.host, call_601224.base,
                         call_601224.route, valid.getOrDefault("path"))
  result = hook(call_601224, url, valid)

proc call*(call_601225: Call_ListTagsForResource_601212; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists the tags associated with this workgroup.
  ##   body: JObject (required)
  var body_601226 = newJObject()
  if body != nil:
    body_601226 = body
  result = call_601225.call(nil, nil, nil, nil, body_601226)

var listTagsForResource* = Call_ListTagsForResource_601212(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.ListTagsForResource",
    validator: validate_ListTagsForResource_601213, base: "/",
    url: url_ListTagsForResource_601214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkGroups_601227 = ref object of OpenApiRestCall_600426
proc url_ListWorkGroups_601229(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListWorkGroups_601228(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists available workgroups for the account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_601230 = query.getOrDefault("NextToken")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "NextToken", valid_601230
  var valid_601231 = query.getOrDefault("MaxResults")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "MaxResults", valid_601231
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601232 = header.getOrDefault("X-Amz-Date")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Date", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-Security-Token")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-Security-Token", valid_601233
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601234 = header.getOrDefault("X-Amz-Target")
  valid_601234 = validateParameter(valid_601234, JString, required = true, default = newJString(
      "AmazonAthena.ListWorkGroups"))
  if valid_601234 != nil:
    section.add "X-Amz-Target", valid_601234
  var valid_601235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Content-Sha256", valid_601235
  var valid_601236 = header.getOrDefault("X-Amz-Algorithm")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-Algorithm", valid_601236
  var valid_601237 = header.getOrDefault("X-Amz-Signature")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "X-Amz-Signature", valid_601237
  var valid_601238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "X-Amz-SignedHeaders", valid_601238
  var valid_601239 = header.getOrDefault("X-Amz-Credential")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "X-Amz-Credential", valid_601239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601241: Call_ListWorkGroups_601227; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists available workgroups for the account.
  ## 
  let valid = call_601241.validator(path, query, header, formData, body)
  let scheme = call_601241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601241.url(scheme.get, call_601241.host, call_601241.base,
                         call_601241.route, valid.getOrDefault("path"))
  result = hook(call_601241, url, valid)

proc call*(call_601242: Call_ListWorkGroups_601227; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listWorkGroups
  ## Lists available workgroups for the account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601243 = newJObject()
  var body_601244 = newJObject()
  add(query_601243, "NextToken", newJString(NextToken))
  if body != nil:
    body_601244 = body
  add(query_601243, "MaxResults", newJString(MaxResults))
  result = call_601242.call(nil, query_601243, nil, nil, body_601244)

var listWorkGroups* = Call_ListWorkGroups_601227(name: "listWorkGroups",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.ListWorkGroups",
    validator: validate_ListWorkGroups_601228, base: "/", url: url_ListWorkGroups_601229,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartQueryExecution_601245 = ref object of OpenApiRestCall_600426
proc url_StartQueryExecution_601247(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartQueryExecution_601246(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601248 = header.getOrDefault("X-Amz-Date")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Date", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-Security-Token")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-Security-Token", valid_601249
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601250 = header.getOrDefault("X-Amz-Target")
  valid_601250 = validateParameter(valid_601250, JString, required = true, default = newJString(
      "AmazonAthena.StartQueryExecution"))
  if valid_601250 != nil:
    section.add "X-Amz-Target", valid_601250
  var valid_601251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-Content-Sha256", valid_601251
  var valid_601252 = header.getOrDefault("X-Amz-Algorithm")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "X-Amz-Algorithm", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-Signature")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-Signature", valid_601253
  var valid_601254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-SignedHeaders", valid_601254
  var valid_601255 = header.getOrDefault("X-Amz-Credential")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-Credential", valid_601255
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601257: Call_StartQueryExecution_601245; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Runs the SQL query statements contained in the <code>Query</code>. Requires you to have access to the workgroup in which the query ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  let valid = call_601257.validator(path, query, header, formData, body)
  let scheme = call_601257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601257.url(scheme.get, call_601257.host, call_601257.base,
                         call_601257.route, valid.getOrDefault("path"))
  result = hook(call_601257, url, valid)

proc call*(call_601258: Call_StartQueryExecution_601245; body: JsonNode): Recallable =
  ## startQueryExecution
  ## <p>Runs the SQL query statements contained in the <code>Query</code>. Requires you to have access to the workgroup in which the query ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ##   body: JObject (required)
  var body_601259 = newJObject()
  if body != nil:
    body_601259 = body
  result = call_601258.call(nil, nil, nil, nil, body_601259)

var startQueryExecution* = Call_StartQueryExecution_601245(
    name: "startQueryExecution", meth: HttpMethod.HttpPost,
    host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.StartQueryExecution",
    validator: validate_StartQueryExecution_601246, base: "/",
    url: url_StartQueryExecution_601247, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopQueryExecution_601260 = ref object of OpenApiRestCall_600426
proc url_StopQueryExecution_601262(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopQueryExecution_601261(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601263 = header.getOrDefault("X-Amz-Date")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-Date", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-Security-Token")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-Security-Token", valid_601264
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601265 = header.getOrDefault("X-Amz-Target")
  valid_601265 = validateParameter(valid_601265, JString, required = true, default = newJString(
      "AmazonAthena.StopQueryExecution"))
  if valid_601265 != nil:
    section.add "X-Amz-Target", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Content-Sha256", valid_601266
  var valid_601267 = header.getOrDefault("X-Amz-Algorithm")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "X-Amz-Algorithm", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-Signature")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-Signature", valid_601268
  var valid_601269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-SignedHeaders", valid_601269
  var valid_601270 = header.getOrDefault("X-Amz-Credential")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Credential", valid_601270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601272: Call_StopQueryExecution_601260; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a query execution. Requires you to have access to the workgroup in which the query ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  let valid = call_601272.validator(path, query, header, formData, body)
  let scheme = call_601272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601272.url(scheme.get, call_601272.host, call_601272.base,
                         call_601272.route, valid.getOrDefault("path"))
  result = hook(call_601272, url, valid)

proc call*(call_601273: Call_StopQueryExecution_601260; body: JsonNode): Recallable =
  ## stopQueryExecution
  ## <p>Stops a query execution. Requires you to have access to the workgroup in which the query ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ##   body: JObject (required)
  var body_601274 = newJObject()
  if body != nil:
    body_601274 = body
  result = call_601273.call(nil, nil, nil, nil, body_601274)

var stopQueryExecution* = Call_StopQueryExecution_601260(
    name: "stopQueryExecution", meth: HttpMethod.HttpPost,
    host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.StopQueryExecution",
    validator: validate_StopQueryExecution_601261, base: "/",
    url: url_StopQueryExecution_601262, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601275 = ref object of OpenApiRestCall_600426
proc url_TagResource_601277(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_601276(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601278 = header.getOrDefault("X-Amz-Date")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "X-Amz-Date", valid_601278
  var valid_601279 = header.getOrDefault("X-Amz-Security-Token")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "X-Amz-Security-Token", valid_601279
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601280 = header.getOrDefault("X-Amz-Target")
  valid_601280 = validateParameter(valid_601280, JString, required = true, default = newJString(
      "AmazonAthena.TagResource"))
  if valid_601280 != nil:
    section.add "X-Amz-Target", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-Content-Sha256", valid_601281
  var valid_601282 = header.getOrDefault("X-Amz-Algorithm")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "X-Amz-Algorithm", valid_601282
  var valid_601283 = header.getOrDefault("X-Amz-Signature")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "X-Amz-Signature", valid_601283
  var valid_601284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-SignedHeaders", valid_601284
  var valid_601285 = header.getOrDefault("X-Amz-Credential")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "X-Amz-Credential", valid_601285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601287: Call_TagResource_601275; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to the resource, such as a workgroup. A tag is a label that you assign to an AWS Athena resource (a workgroup). Each tag consists of a key and an optional value, both of which you define. Tags enable you to categorize resources (workgroups) in Athena, for example, by purpose, owner, or environment. Use a consistent set of tag keys to make it easier to search and filter workgroups in your account. For best practices, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>. The key length is from 1 (minimum) to 128 (maximum) Unicode characters in UTF-8. The tag value length is from 0 (minimum) to 256 (maximum) Unicode characters in UTF-8. You can use letters and numbers representable in UTF-8, and the following characters: + - = . _ : / @. Tag keys and values are case-sensitive. Tag keys must be unique per resource. If you specify more than one, separate them by commas.
  ## 
  let valid = call_601287.validator(path, query, header, formData, body)
  let scheme = call_601287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601287.url(scheme.get, call_601287.host, call_601287.base,
                         call_601287.route, valid.getOrDefault("path"))
  result = hook(call_601287, url, valid)

proc call*(call_601288: Call_TagResource_601275; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags to the resource, such as a workgroup. A tag is a label that you assign to an AWS Athena resource (a workgroup). Each tag consists of a key and an optional value, both of which you define. Tags enable you to categorize resources (workgroups) in Athena, for example, by purpose, owner, or environment. Use a consistent set of tag keys to make it easier to search and filter workgroups in your account. For best practices, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>. The key length is from 1 (minimum) to 128 (maximum) Unicode characters in UTF-8. The tag value length is from 0 (minimum) to 256 (maximum) Unicode characters in UTF-8. You can use letters and numbers representable in UTF-8, and the following characters: + - = . _ : / @. Tag keys and values are case-sensitive. Tag keys must be unique per resource. If you specify more than one, separate them by commas.
  ##   body: JObject (required)
  var body_601289 = newJObject()
  if body != nil:
    body_601289 = body
  result = call_601288.call(nil, nil, nil, nil, body_601289)

var tagResource* = Call_TagResource_601275(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "athena.amazonaws.com", route: "/#X-Amz-Target=AmazonAthena.TagResource",
                                        validator: validate_TagResource_601276,
                                        base: "/", url: url_TagResource_601277,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601290 = ref object of OpenApiRestCall_600426
proc url_UntagResource_601292(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_601291(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601293 = header.getOrDefault("X-Amz-Date")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-Date", valid_601293
  var valid_601294 = header.getOrDefault("X-Amz-Security-Token")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "X-Amz-Security-Token", valid_601294
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601295 = header.getOrDefault("X-Amz-Target")
  valid_601295 = validateParameter(valid_601295, JString, required = true, default = newJString(
      "AmazonAthena.UntagResource"))
  if valid_601295 != nil:
    section.add "X-Amz-Target", valid_601295
  var valid_601296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-Content-Sha256", valid_601296
  var valid_601297 = header.getOrDefault("X-Amz-Algorithm")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "X-Amz-Algorithm", valid_601297
  var valid_601298 = header.getOrDefault("X-Amz-Signature")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "X-Amz-Signature", valid_601298
  var valid_601299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "X-Amz-SignedHeaders", valid_601299
  var valid_601300 = header.getOrDefault("X-Amz-Credential")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "X-Amz-Credential", valid_601300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601302: Call_UntagResource_601290; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the workgroup resource. Takes as an input a list of TagKey Strings separated by commas, and removes their tags at the same time.
  ## 
  let valid = call_601302.validator(path, query, header, formData, body)
  let scheme = call_601302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601302.url(scheme.get, call_601302.host, call_601302.base,
                         call_601302.route, valid.getOrDefault("path"))
  result = hook(call_601302, url, valid)

proc call*(call_601303: Call_UntagResource_601290; body: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags from the workgroup resource. Takes as an input a list of TagKey Strings separated by commas, and removes their tags at the same time.
  ##   body: JObject (required)
  var body_601304 = newJObject()
  if body != nil:
    body_601304 = body
  result = call_601303.call(nil, nil, nil, nil, body_601304)

var untagResource* = Call_UntagResource_601290(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.UntagResource",
    validator: validate_UntagResource_601291, base: "/", url: url_UntagResource_601292,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkGroup_601305 = ref object of OpenApiRestCall_600426
proc url_UpdateWorkGroup_601307(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateWorkGroup_601306(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601308 = header.getOrDefault("X-Amz-Date")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-Date", valid_601308
  var valid_601309 = header.getOrDefault("X-Amz-Security-Token")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-Security-Token", valid_601309
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601310 = header.getOrDefault("X-Amz-Target")
  valid_601310 = validateParameter(valid_601310, JString, required = true, default = newJString(
      "AmazonAthena.UpdateWorkGroup"))
  if valid_601310 != nil:
    section.add "X-Amz-Target", valid_601310
  var valid_601311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "X-Amz-Content-Sha256", valid_601311
  var valid_601312 = header.getOrDefault("X-Amz-Algorithm")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "X-Amz-Algorithm", valid_601312
  var valid_601313 = header.getOrDefault("X-Amz-Signature")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "X-Amz-Signature", valid_601313
  var valid_601314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "X-Amz-SignedHeaders", valid_601314
  var valid_601315 = header.getOrDefault("X-Amz-Credential")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-Credential", valid_601315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601317: Call_UpdateWorkGroup_601305; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the workgroup with the specified name. The workgroup's name cannot be changed.
  ## 
  let valid = call_601317.validator(path, query, header, formData, body)
  let scheme = call_601317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601317.url(scheme.get, call_601317.host, call_601317.base,
                         call_601317.route, valid.getOrDefault("path"))
  result = hook(call_601317, url, valid)

proc call*(call_601318: Call_UpdateWorkGroup_601305; body: JsonNode): Recallable =
  ## updateWorkGroup
  ## Updates the workgroup with the specified name. The workgroup's name cannot be changed.
  ##   body: JObject (required)
  var body_601319 = newJObject()
  if body != nil:
    body_601319 = body
  result = call_601318.call(nil, nil, nil, nil, body_601319)

var updateWorkGroup* = Call_UpdateWorkGroup_601305(name: "updateWorkGroup",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.UpdateWorkGroup",
    validator: validate_UpdateWorkGroup_601306, base: "/", url: url_UpdateWorkGroup_601307,
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
