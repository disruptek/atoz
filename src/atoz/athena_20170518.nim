
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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
  Call_BatchGetNamedQuery_599705 = ref object of OpenApiRestCall_599368
proc url_BatchGetNamedQuery_599707(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetNamedQuery_599706(path: JsonNode; query: JsonNode;
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
  var valid_599819 = header.getOrDefault("X-Amz-Date")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "X-Amz-Date", valid_599819
  var valid_599820 = header.getOrDefault("X-Amz-Security-Token")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Security-Token", valid_599820
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599834 = header.getOrDefault("X-Amz-Target")
  valid_599834 = validateParameter(valid_599834, JString, required = true, default = newJString(
      "AmazonAthena.BatchGetNamedQuery"))
  if valid_599834 != nil:
    section.add "X-Amz-Target", valid_599834
  var valid_599835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599835 = validateParameter(valid_599835, JString, required = false,
                                 default = nil)
  if valid_599835 != nil:
    section.add "X-Amz-Content-Sha256", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Algorithm")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Algorithm", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Signature")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Signature", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-SignedHeaders", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Credential")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Credential", valid_599839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599863: Call_BatchGetNamedQuery_599705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the details of a single named query or a list of up to 50 queries, which you provide as an array of query ID strings. Requires you to have access to the workgroup in which the queries were saved. Use <a>ListNamedQueriesInput</a> to get the list of named query IDs in the specified workgroup. If information could not be retrieved for a submitted query ID, information about the query ID submitted is listed under <a>UnprocessedNamedQueryId</a>. Named queries differ from executed queries. Use <a>BatchGetQueryExecutionInput</a> to get details about each unique query execution, and <a>ListQueryExecutionsInput</a> to get a list of query execution IDs.
  ## 
  let valid = call_599863.validator(path, query, header, formData, body)
  let scheme = call_599863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599863.url(scheme.get, call_599863.host, call_599863.base,
                         call_599863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599863, url, valid)

proc call*(call_599934: Call_BatchGetNamedQuery_599705; body: JsonNode): Recallable =
  ## batchGetNamedQuery
  ## Returns the details of a single named query or a list of up to 50 queries, which you provide as an array of query ID strings. Requires you to have access to the workgroup in which the queries were saved. Use <a>ListNamedQueriesInput</a> to get the list of named query IDs in the specified workgroup. If information could not be retrieved for a submitted query ID, information about the query ID submitted is listed under <a>UnprocessedNamedQueryId</a>. Named queries differ from executed queries. Use <a>BatchGetQueryExecutionInput</a> to get details about each unique query execution, and <a>ListQueryExecutionsInput</a> to get a list of query execution IDs.
  ##   body: JObject (required)
  var body_599935 = newJObject()
  if body != nil:
    body_599935 = body
  result = call_599934.call(nil, nil, nil, nil, body_599935)

var batchGetNamedQuery* = Call_BatchGetNamedQuery_599705(
    name: "batchGetNamedQuery", meth: HttpMethod.HttpPost,
    host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.BatchGetNamedQuery",
    validator: validate_BatchGetNamedQuery_599706, base: "/",
    url: url_BatchGetNamedQuery_599707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetQueryExecution_599974 = ref object of OpenApiRestCall_599368
proc url_BatchGetQueryExecution_599976(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetQueryExecution_599975(path: JsonNode; query: JsonNode;
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
  var valid_599977 = header.getOrDefault("X-Amz-Date")
  valid_599977 = validateParameter(valid_599977, JString, required = false,
                                 default = nil)
  if valid_599977 != nil:
    section.add "X-Amz-Date", valid_599977
  var valid_599978 = header.getOrDefault("X-Amz-Security-Token")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "X-Amz-Security-Token", valid_599978
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599979 = header.getOrDefault("X-Amz-Target")
  valid_599979 = validateParameter(valid_599979, JString, required = true, default = newJString(
      "AmazonAthena.BatchGetQueryExecution"))
  if valid_599979 != nil:
    section.add "X-Amz-Target", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Content-Sha256", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Algorithm")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Algorithm", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Signature")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Signature", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-SignedHeaders", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Credential")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Credential", valid_599984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599986: Call_BatchGetQueryExecution_599974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the details of a single query execution or a list of up to 50 query executions, which you provide as an array of query execution ID strings. Requires you to have access to the workgroup in which the queries ran. To get a list of query execution IDs, use <a>ListQueryExecutionsInput$WorkGroup</a>. Query executions differ from named (saved) queries. Use <a>BatchGetNamedQueryInput</a> to get details about named queries.
  ## 
  let valid = call_599986.validator(path, query, header, formData, body)
  let scheme = call_599986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599986.url(scheme.get, call_599986.host, call_599986.base,
                         call_599986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599986, url, valid)

proc call*(call_599987: Call_BatchGetQueryExecution_599974; body: JsonNode): Recallable =
  ## batchGetQueryExecution
  ## Returns the details of a single query execution or a list of up to 50 query executions, which you provide as an array of query execution ID strings. Requires you to have access to the workgroup in which the queries ran. To get a list of query execution IDs, use <a>ListQueryExecutionsInput$WorkGroup</a>. Query executions differ from named (saved) queries. Use <a>BatchGetNamedQueryInput</a> to get details about named queries.
  ##   body: JObject (required)
  var body_599988 = newJObject()
  if body != nil:
    body_599988 = body
  result = call_599987.call(nil, nil, nil, nil, body_599988)

var batchGetQueryExecution* = Call_BatchGetQueryExecution_599974(
    name: "batchGetQueryExecution", meth: HttpMethod.HttpPost,
    host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.BatchGetQueryExecution",
    validator: validate_BatchGetQueryExecution_599975, base: "/",
    url: url_BatchGetQueryExecution_599976, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNamedQuery_599989 = ref object of OpenApiRestCall_599368
proc url_CreateNamedQuery_599991(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateNamedQuery_599990(path: JsonNode; query: JsonNode;
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
  var valid_599992 = header.getOrDefault("X-Amz-Date")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Date", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-Security-Token")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Security-Token", valid_599993
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599994 = header.getOrDefault("X-Amz-Target")
  valid_599994 = validateParameter(valid_599994, JString, required = true, default = newJString(
      "AmazonAthena.CreateNamedQuery"))
  if valid_599994 != nil:
    section.add "X-Amz-Target", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Content-Sha256", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Algorithm")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Algorithm", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Signature")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Signature", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-SignedHeaders", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Credential")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Credential", valid_599999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600001: Call_CreateNamedQuery_599989; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a named query in the specified workgroup. Requires that you have access to the workgroup.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  let valid = call_600001.validator(path, query, header, formData, body)
  let scheme = call_600001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600001.url(scheme.get, call_600001.host, call_600001.base,
                         call_600001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600001, url, valid)

proc call*(call_600002: Call_CreateNamedQuery_599989; body: JsonNode): Recallable =
  ## createNamedQuery
  ## <p>Creates a named query in the specified workgroup. Requires that you have access to the workgroup.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ##   body: JObject (required)
  var body_600003 = newJObject()
  if body != nil:
    body_600003 = body
  result = call_600002.call(nil, nil, nil, nil, body_600003)

var createNamedQuery* = Call_CreateNamedQuery_599989(name: "createNamedQuery",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.CreateNamedQuery",
    validator: validate_CreateNamedQuery_599990, base: "/",
    url: url_CreateNamedQuery_599991, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkGroup_600004 = ref object of OpenApiRestCall_599368
proc url_CreateWorkGroup_600006(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateWorkGroup_600005(path: JsonNode; query: JsonNode;
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
  var valid_600007 = header.getOrDefault("X-Amz-Date")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Date", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Security-Token")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Security-Token", valid_600008
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600009 = header.getOrDefault("X-Amz-Target")
  valid_600009 = validateParameter(valid_600009, JString, required = true, default = newJString(
      "AmazonAthena.CreateWorkGroup"))
  if valid_600009 != nil:
    section.add "X-Amz-Target", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Content-Sha256", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Algorithm")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Algorithm", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-Signature")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Signature", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-SignedHeaders", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-Credential")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Credential", valid_600014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600016: Call_CreateWorkGroup_600004; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a workgroup with the specified name.
  ## 
  let valid = call_600016.validator(path, query, header, formData, body)
  let scheme = call_600016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600016.url(scheme.get, call_600016.host, call_600016.base,
                         call_600016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600016, url, valid)

proc call*(call_600017: Call_CreateWorkGroup_600004; body: JsonNode): Recallable =
  ## createWorkGroup
  ## Creates a workgroup with the specified name.
  ##   body: JObject (required)
  var body_600018 = newJObject()
  if body != nil:
    body_600018 = body
  result = call_600017.call(nil, nil, nil, nil, body_600018)

var createWorkGroup* = Call_CreateWorkGroup_600004(name: "createWorkGroup",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.CreateWorkGroup",
    validator: validate_CreateWorkGroup_600005, base: "/", url: url_CreateWorkGroup_600006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNamedQuery_600019 = ref object of OpenApiRestCall_599368
proc url_DeleteNamedQuery_600021(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteNamedQuery_600020(path: JsonNode; query: JsonNode;
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
  var valid_600022 = header.getOrDefault("X-Amz-Date")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Date", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-Security-Token")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Security-Token", valid_600023
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600024 = header.getOrDefault("X-Amz-Target")
  valid_600024 = validateParameter(valid_600024, JString, required = true, default = newJString(
      "AmazonAthena.DeleteNamedQuery"))
  if valid_600024 != nil:
    section.add "X-Amz-Target", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Content-Sha256", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Algorithm")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Algorithm", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Signature")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Signature", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-SignedHeaders", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Credential")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Credential", valid_600029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600031: Call_DeleteNamedQuery_600019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the named query if you have access to the workgroup in which the query was saved.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  let valid = call_600031.validator(path, query, header, formData, body)
  let scheme = call_600031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600031.url(scheme.get, call_600031.host, call_600031.base,
                         call_600031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600031, url, valid)

proc call*(call_600032: Call_DeleteNamedQuery_600019; body: JsonNode): Recallable =
  ## deleteNamedQuery
  ## <p>Deletes the named query if you have access to the workgroup in which the query was saved.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ##   body: JObject (required)
  var body_600033 = newJObject()
  if body != nil:
    body_600033 = body
  result = call_600032.call(nil, nil, nil, nil, body_600033)

var deleteNamedQuery* = Call_DeleteNamedQuery_600019(name: "deleteNamedQuery",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.DeleteNamedQuery",
    validator: validate_DeleteNamedQuery_600020, base: "/",
    url: url_DeleteNamedQuery_600021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkGroup_600034 = ref object of OpenApiRestCall_599368
proc url_DeleteWorkGroup_600036(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteWorkGroup_600035(path: JsonNode; query: JsonNode;
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
  var valid_600037 = header.getOrDefault("X-Amz-Date")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Date", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Security-Token")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Security-Token", valid_600038
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600039 = header.getOrDefault("X-Amz-Target")
  valid_600039 = validateParameter(valid_600039, JString, required = true, default = newJString(
      "AmazonAthena.DeleteWorkGroup"))
  if valid_600039 != nil:
    section.add "X-Amz-Target", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Content-Sha256", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Algorithm")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Algorithm", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Signature")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Signature", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-SignedHeaders", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-Credential")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Credential", valid_600044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600046: Call_DeleteWorkGroup_600034; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the workgroup with the specified name. The primary workgroup cannot be deleted.
  ## 
  let valid = call_600046.validator(path, query, header, formData, body)
  let scheme = call_600046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600046.url(scheme.get, call_600046.host, call_600046.base,
                         call_600046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600046, url, valid)

proc call*(call_600047: Call_DeleteWorkGroup_600034; body: JsonNode): Recallable =
  ## deleteWorkGroup
  ## Deletes the workgroup with the specified name. The primary workgroup cannot be deleted.
  ##   body: JObject (required)
  var body_600048 = newJObject()
  if body != nil:
    body_600048 = body
  result = call_600047.call(nil, nil, nil, nil, body_600048)

var deleteWorkGroup* = Call_DeleteWorkGroup_600034(name: "deleteWorkGroup",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.DeleteWorkGroup",
    validator: validate_DeleteWorkGroup_600035, base: "/", url: url_DeleteWorkGroup_600036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNamedQuery_600049 = ref object of OpenApiRestCall_599368
proc url_GetNamedQuery_600051(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetNamedQuery_600050(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600052 = header.getOrDefault("X-Amz-Date")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Date", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-Security-Token")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Security-Token", valid_600053
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600054 = header.getOrDefault("X-Amz-Target")
  valid_600054 = validateParameter(valid_600054, JString, required = true, default = newJString(
      "AmazonAthena.GetNamedQuery"))
  if valid_600054 != nil:
    section.add "X-Amz-Target", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Content-Sha256", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Algorithm")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Algorithm", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Signature")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Signature", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-SignedHeaders", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Credential")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Credential", valid_600059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600061: Call_GetNamedQuery_600049; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a single query. Requires that you have access to the workgroup in which the query was saved.
  ## 
  let valid = call_600061.validator(path, query, header, formData, body)
  let scheme = call_600061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600061.url(scheme.get, call_600061.host, call_600061.base,
                         call_600061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600061, url, valid)

proc call*(call_600062: Call_GetNamedQuery_600049; body: JsonNode): Recallable =
  ## getNamedQuery
  ## Returns information about a single query. Requires that you have access to the workgroup in which the query was saved.
  ##   body: JObject (required)
  var body_600063 = newJObject()
  if body != nil:
    body_600063 = body
  result = call_600062.call(nil, nil, nil, nil, body_600063)

var getNamedQuery* = Call_GetNamedQuery_600049(name: "getNamedQuery",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.GetNamedQuery",
    validator: validate_GetNamedQuery_600050, base: "/", url: url_GetNamedQuery_600051,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQueryExecution_600064 = ref object of OpenApiRestCall_599368
proc url_GetQueryExecution_600066(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetQueryExecution_600065(path: JsonNode; query: JsonNode;
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
  var valid_600067 = header.getOrDefault("X-Amz-Date")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Date", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Security-Token")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Security-Token", valid_600068
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600069 = header.getOrDefault("X-Amz-Target")
  valid_600069 = validateParameter(valid_600069, JString, required = true, default = newJString(
      "AmazonAthena.GetQueryExecution"))
  if valid_600069 != nil:
    section.add "X-Amz-Target", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Content-Sha256", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Algorithm")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Algorithm", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Signature")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Signature", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-SignedHeaders", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-Credential")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Credential", valid_600074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600076: Call_GetQueryExecution_600064; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a single execution of a query if you have access to the workgroup in which the query ran. Each time a query executes, information about the query execution is saved with a unique ID.
  ## 
  let valid = call_600076.validator(path, query, header, formData, body)
  let scheme = call_600076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600076.url(scheme.get, call_600076.host, call_600076.base,
                         call_600076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600076, url, valid)

proc call*(call_600077: Call_GetQueryExecution_600064; body: JsonNode): Recallable =
  ## getQueryExecution
  ## Returns information about a single execution of a query if you have access to the workgroup in which the query ran. Each time a query executes, information about the query execution is saved with a unique ID.
  ##   body: JObject (required)
  var body_600078 = newJObject()
  if body != nil:
    body_600078 = body
  result = call_600077.call(nil, nil, nil, nil, body_600078)

var getQueryExecution* = Call_GetQueryExecution_600064(name: "getQueryExecution",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.GetQueryExecution",
    validator: validate_GetQueryExecution_600065, base: "/",
    url: url_GetQueryExecution_600066, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQueryResults_600079 = ref object of OpenApiRestCall_599368
proc url_GetQueryResults_600081(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetQueryResults_600080(path: JsonNode; query: JsonNode;
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
  var valid_600082 = query.getOrDefault("NextToken")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "NextToken", valid_600082
  var valid_600083 = query.getOrDefault("MaxResults")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "MaxResults", valid_600083
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
  var valid_600084 = header.getOrDefault("X-Amz-Date")
  valid_600084 = validateParameter(valid_600084, JString, required = false,
                                 default = nil)
  if valid_600084 != nil:
    section.add "X-Amz-Date", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Security-Token")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Security-Token", valid_600085
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600086 = header.getOrDefault("X-Amz-Target")
  valid_600086 = validateParameter(valid_600086, JString, required = true, default = newJString(
      "AmazonAthena.GetQueryResults"))
  if valid_600086 != nil:
    section.add "X-Amz-Target", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Content-Sha256", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-Algorithm")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-Algorithm", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Signature")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Signature", valid_600089
  var valid_600090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600090 = validateParameter(valid_600090, JString, required = false,
                                 default = nil)
  if valid_600090 != nil:
    section.add "X-Amz-SignedHeaders", valid_600090
  var valid_600091 = header.getOrDefault("X-Amz-Credential")
  valid_600091 = validateParameter(valid_600091, JString, required = false,
                                 default = nil)
  if valid_600091 != nil:
    section.add "X-Amz-Credential", valid_600091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600093: Call_GetQueryResults_600079; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Streams the results of a single query execution specified by <code>QueryExecutionId</code> from the Athena query results location in Amazon S3. For more information, see <a href="https://docs.aws.amazon.com/athena/latest/ug/querying.html">Query Results</a> in the <i>Amazon Athena User Guide</i>. This request does not execute the query but returns results. Use <a>StartQueryExecution</a> to run a query.</p> <p>To stream query results successfully, the IAM principal with permission to call <code>GetQueryResults</code> also must have permissions to the Amazon S3 <code>GetObject</code> action for the Athena query results location.</p> <important> <p>IAM principals with permission to the Amazon S3 <code>GetObject</code> action for the query results location are able to retrieve query results from Amazon S3 even if permission to the <code>GetQueryResults</code> action is denied. To restrict user or role access, ensure that Amazon S3 permissions to the Athena query location are denied.</p> </important>
  ## 
  let valid = call_600093.validator(path, query, header, formData, body)
  let scheme = call_600093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600093.url(scheme.get, call_600093.host, call_600093.base,
                         call_600093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600093, url, valid)

proc call*(call_600094: Call_GetQueryResults_600079; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getQueryResults
  ## <p>Streams the results of a single query execution specified by <code>QueryExecutionId</code> from the Athena query results location in Amazon S3. For more information, see <a href="https://docs.aws.amazon.com/athena/latest/ug/querying.html">Query Results</a> in the <i>Amazon Athena User Guide</i>. This request does not execute the query but returns results. Use <a>StartQueryExecution</a> to run a query.</p> <p>To stream query results successfully, the IAM principal with permission to call <code>GetQueryResults</code> also must have permissions to the Amazon S3 <code>GetObject</code> action for the Athena query results location.</p> <important> <p>IAM principals with permission to the Amazon S3 <code>GetObject</code> action for the query results location are able to retrieve query results from Amazon S3 even if permission to the <code>GetQueryResults</code> action is denied. To restrict user or role access, ensure that Amazon S3 permissions to the Athena query location are denied.</p> </important>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600095 = newJObject()
  var body_600096 = newJObject()
  add(query_600095, "NextToken", newJString(NextToken))
  if body != nil:
    body_600096 = body
  add(query_600095, "MaxResults", newJString(MaxResults))
  result = call_600094.call(nil, query_600095, nil, nil, body_600096)

var getQueryResults* = Call_GetQueryResults_600079(name: "getQueryResults",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.GetQueryResults",
    validator: validate_GetQueryResults_600080, base: "/", url: url_GetQueryResults_600081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkGroup_600098 = ref object of OpenApiRestCall_599368
proc url_GetWorkGroup_600100(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetWorkGroup_600099(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600101 = header.getOrDefault("X-Amz-Date")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Date", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Security-Token")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Security-Token", valid_600102
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600103 = header.getOrDefault("X-Amz-Target")
  valid_600103 = validateParameter(valid_600103, JString, required = true, default = newJString(
      "AmazonAthena.GetWorkGroup"))
  if valid_600103 != nil:
    section.add "X-Amz-Target", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Content-Sha256", valid_600104
  var valid_600105 = header.getOrDefault("X-Amz-Algorithm")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "X-Amz-Algorithm", valid_600105
  var valid_600106 = header.getOrDefault("X-Amz-Signature")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "X-Amz-Signature", valid_600106
  var valid_600107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600107 = validateParameter(valid_600107, JString, required = false,
                                 default = nil)
  if valid_600107 != nil:
    section.add "X-Amz-SignedHeaders", valid_600107
  var valid_600108 = header.getOrDefault("X-Amz-Credential")
  valid_600108 = validateParameter(valid_600108, JString, required = false,
                                 default = nil)
  if valid_600108 != nil:
    section.add "X-Amz-Credential", valid_600108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600110: Call_GetWorkGroup_600098; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the workgroup with the specified name.
  ## 
  let valid = call_600110.validator(path, query, header, formData, body)
  let scheme = call_600110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600110.url(scheme.get, call_600110.host, call_600110.base,
                         call_600110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600110, url, valid)

proc call*(call_600111: Call_GetWorkGroup_600098; body: JsonNode): Recallable =
  ## getWorkGroup
  ## Returns information about the workgroup with the specified name.
  ##   body: JObject (required)
  var body_600112 = newJObject()
  if body != nil:
    body_600112 = body
  result = call_600111.call(nil, nil, nil, nil, body_600112)

var getWorkGroup* = Call_GetWorkGroup_600098(name: "getWorkGroup",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.GetWorkGroup",
    validator: validate_GetWorkGroup_600099, base: "/", url: url_GetWorkGroup_600100,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNamedQueries_600113 = ref object of OpenApiRestCall_599368
proc url_ListNamedQueries_600115(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListNamedQueries_600114(path: JsonNode; query: JsonNode;
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
  var valid_600116 = query.getOrDefault("NextToken")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "NextToken", valid_600116
  var valid_600117 = query.getOrDefault("MaxResults")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "MaxResults", valid_600117
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
  var valid_600118 = header.getOrDefault("X-Amz-Date")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-Date", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Security-Token")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Security-Token", valid_600119
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600120 = header.getOrDefault("X-Amz-Target")
  valid_600120 = validateParameter(valid_600120, JString, required = true, default = newJString(
      "AmazonAthena.ListNamedQueries"))
  if valid_600120 != nil:
    section.add "X-Amz-Target", valid_600120
  var valid_600121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600121 = validateParameter(valid_600121, JString, required = false,
                                 default = nil)
  if valid_600121 != nil:
    section.add "X-Amz-Content-Sha256", valid_600121
  var valid_600122 = header.getOrDefault("X-Amz-Algorithm")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "X-Amz-Algorithm", valid_600122
  var valid_600123 = header.getOrDefault("X-Amz-Signature")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "X-Amz-Signature", valid_600123
  var valid_600124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600124 = validateParameter(valid_600124, JString, required = false,
                                 default = nil)
  if valid_600124 != nil:
    section.add "X-Amz-SignedHeaders", valid_600124
  var valid_600125 = header.getOrDefault("X-Amz-Credential")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "X-Amz-Credential", valid_600125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600127: Call_ListNamedQueries_600113; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provides a list of available query IDs only for queries saved in the specified workgroup. Requires that you have access to the workgroup.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  let valid = call_600127.validator(path, query, header, formData, body)
  let scheme = call_600127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600127.url(scheme.get, call_600127.host, call_600127.base,
                         call_600127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600127, url, valid)

proc call*(call_600128: Call_ListNamedQueries_600113; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listNamedQueries
  ## <p>Provides a list of available query IDs only for queries saved in the specified workgroup. Requires that you have access to the workgroup.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600129 = newJObject()
  var body_600130 = newJObject()
  add(query_600129, "NextToken", newJString(NextToken))
  if body != nil:
    body_600130 = body
  add(query_600129, "MaxResults", newJString(MaxResults))
  result = call_600128.call(nil, query_600129, nil, nil, body_600130)

var listNamedQueries* = Call_ListNamedQueries_600113(name: "listNamedQueries",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.ListNamedQueries",
    validator: validate_ListNamedQueries_600114, base: "/",
    url: url_ListNamedQueries_600115, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQueryExecutions_600131 = ref object of OpenApiRestCall_599368
proc url_ListQueryExecutions_600133(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListQueryExecutions_600132(path: JsonNode; query: JsonNode;
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
  var valid_600134 = query.getOrDefault("NextToken")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "NextToken", valid_600134
  var valid_600135 = query.getOrDefault("MaxResults")
  valid_600135 = validateParameter(valid_600135, JString, required = false,
                                 default = nil)
  if valid_600135 != nil:
    section.add "MaxResults", valid_600135
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
  var valid_600136 = header.getOrDefault("X-Amz-Date")
  valid_600136 = validateParameter(valid_600136, JString, required = false,
                                 default = nil)
  if valid_600136 != nil:
    section.add "X-Amz-Date", valid_600136
  var valid_600137 = header.getOrDefault("X-Amz-Security-Token")
  valid_600137 = validateParameter(valid_600137, JString, required = false,
                                 default = nil)
  if valid_600137 != nil:
    section.add "X-Amz-Security-Token", valid_600137
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600138 = header.getOrDefault("X-Amz-Target")
  valid_600138 = validateParameter(valid_600138, JString, required = true, default = newJString(
      "AmazonAthena.ListQueryExecutions"))
  if valid_600138 != nil:
    section.add "X-Amz-Target", valid_600138
  var valid_600139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600139 = validateParameter(valid_600139, JString, required = false,
                                 default = nil)
  if valid_600139 != nil:
    section.add "X-Amz-Content-Sha256", valid_600139
  var valid_600140 = header.getOrDefault("X-Amz-Algorithm")
  valid_600140 = validateParameter(valid_600140, JString, required = false,
                                 default = nil)
  if valid_600140 != nil:
    section.add "X-Amz-Algorithm", valid_600140
  var valid_600141 = header.getOrDefault("X-Amz-Signature")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "X-Amz-Signature", valid_600141
  var valid_600142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-SignedHeaders", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Credential")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Credential", valid_600143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600145: Call_ListQueryExecutions_600131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provides a list of available query execution IDs for the queries in the specified workgroup. Requires you to have access to the workgroup in which the queries ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  let valid = call_600145.validator(path, query, header, formData, body)
  let scheme = call_600145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600145.url(scheme.get, call_600145.host, call_600145.base,
                         call_600145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600145, url, valid)

proc call*(call_600146: Call_ListQueryExecutions_600131; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listQueryExecutions
  ## <p>Provides a list of available query execution IDs for the queries in the specified workgroup. Requires you to have access to the workgroup in which the queries ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600147 = newJObject()
  var body_600148 = newJObject()
  add(query_600147, "NextToken", newJString(NextToken))
  if body != nil:
    body_600148 = body
  add(query_600147, "MaxResults", newJString(MaxResults))
  result = call_600146.call(nil, query_600147, nil, nil, body_600148)

var listQueryExecutions* = Call_ListQueryExecutions_600131(
    name: "listQueryExecutions", meth: HttpMethod.HttpPost,
    host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.ListQueryExecutions",
    validator: validate_ListQueryExecutions_600132, base: "/",
    url: url_ListQueryExecutions_600133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600149 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_600151(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_600150(path: JsonNode; query: JsonNode;
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
  var valid_600152 = header.getOrDefault("X-Amz-Date")
  valid_600152 = validateParameter(valid_600152, JString, required = false,
                                 default = nil)
  if valid_600152 != nil:
    section.add "X-Amz-Date", valid_600152
  var valid_600153 = header.getOrDefault("X-Amz-Security-Token")
  valid_600153 = validateParameter(valid_600153, JString, required = false,
                                 default = nil)
  if valid_600153 != nil:
    section.add "X-Amz-Security-Token", valid_600153
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600154 = header.getOrDefault("X-Amz-Target")
  valid_600154 = validateParameter(valid_600154, JString, required = true, default = newJString(
      "AmazonAthena.ListTagsForResource"))
  if valid_600154 != nil:
    section.add "X-Amz-Target", valid_600154
  var valid_600155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600155 = validateParameter(valid_600155, JString, required = false,
                                 default = nil)
  if valid_600155 != nil:
    section.add "X-Amz-Content-Sha256", valid_600155
  var valid_600156 = header.getOrDefault("X-Amz-Algorithm")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "X-Amz-Algorithm", valid_600156
  var valid_600157 = header.getOrDefault("X-Amz-Signature")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Signature", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-SignedHeaders", valid_600158
  var valid_600159 = header.getOrDefault("X-Amz-Credential")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "X-Amz-Credential", valid_600159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600161: Call_ListTagsForResource_600149; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags associated with this workgroup.
  ## 
  let valid = call_600161.validator(path, query, header, formData, body)
  let scheme = call_600161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600161.url(scheme.get, call_600161.host, call_600161.base,
                         call_600161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600161, url, valid)

proc call*(call_600162: Call_ListTagsForResource_600149; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists the tags associated with this workgroup.
  ##   body: JObject (required)
  var body_600163 = newJObject()
  if body != nil:
    body_600163 = body
  result = call_600162.call(nil, nil, nil, nil, body_600163)

var listTagsForResource* = Call_ListTagsForResource_600149(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.ListTagsForResource",
    validator: validate_ListTagsForResource_600150, base: "/",
    url: url_ListTagsForResource_600151, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkGroups_600164 = ref object of OpenApiRestCall_599368
proc url_ListWorkGroups_600166(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListWorkGroups_600165(path: JsonNode; query: JsonNode;
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
  var valid_600167 = query.getOrDefault("NextToken")
  valid_600167 = validateParameter(valid_600167, JString, required = false,
                                 default = nil)
  if valid_600167 != nil:
    section.add "NextToken", valid_600167
  var valid_600168 = query.getOrDefault("MaxResults")
  valid_600168 = validateParameter(valid_600168, JString, required = false,
                                 default = nil)
  if valid_600168 != nil:
    section.add "MaxResults", valid_600168
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
  var valid_600169 = header.getOrDefault("X-Amz-Date")
  valid_600169 = validateParameter(valid_600169, JString, required = false,
                                 default = nil)
  if valid_600169 != nil:
    section.add "X-Amz-Date", valid_600169
  var valid_600170 = header.getOrDefault("X-Amz-Security-Token")
  valid_600170 = validateParameter(valid_600170, JString, required = false,
                                 default = nil)
  if valid_600170 != nil:
    section.add "X-Amz-Security-Token", valid_600170
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600171 = header.getOrDefault("X-Amz-Target")
  valid_600171 = validateParameter(valid_600171, JString, required = true, default = newJString(
      "AmazonAthena.ListWorkGroups"))
  if valid_600171 != nil:
    section.add "X-Amz-Target", valid_600171
  var valid_600172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Content-Sha256", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-Algorithm")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Algorithm", valid_600173
  var valid_600174 = header.getOrDefault("X-Amz-Signature")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "X-Amz-Signature", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-SignedHeaders", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Credential")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Credential", valid_600176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600178: Call_ListWorkGroups_600164; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists available workgroups for the account.
  ## 
  let valid = call_600178.validator(path, query, header, formData, body)
  let scheme = call_600178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600178.url(scheme.get, call_600178.host, call_600178.base,
                         call_600178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600178, url, valid)

proc call*(call_600179: Call_ListWorkGroups_600164; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listWorkGroups
  ## Lists available workgroups for the account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600180 = newJObject()
  var body_600181 = newJObject()
  add(query_600180, "NextToken", newJString(NextToken))
  if body != nil:
    body_600181 = body
  add(query_600180, "MaxResults", newJString(MaxResults))
  result = call_600179.call(nil, query_600180, nil, nil, body_600181)

var listWorkGroups* = Call_ListWorkGroups_600164(name: "listWorkGroups",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.ListWorkGroups",
    validator: validate_ListWorkGroups_600165, base: "/", url: url_ListWorkGroups_600166,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartQueryExecution_600182 = ref object of OpenApiRestCall_599368
proc url_StartQueryExecution_600184(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartQueryExecution_600183(path: JsonNode; query: JsonNode;
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
  var valid_600185 = header.getOrDefault("X-Amz-Date")
  valid_600185 = validateParameter(valid_600185, JString, required = false,
                                 default = nil)
  if valid_600185 != nil:
    section.add "X-Amz-Date", valid_600185
  var valid_600186 = header.getOrDefault("X-Amz-Security-Token")
  valid_600186 = validateParameter(valid_600186, JString, required = false,
                                 default = nil)
  if valid_600186 != nil:
    section.add "X-Amz-Security-Token", valid_600186
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600187 = header.getOrDefault("X-Amz-Target")
  valid_600187 = validateParameter(valid_600187, JString, required = true, default = newJString(
      "AmazonAthena.StartQueryExecution"))
  if valid_600187 != nil:
    section.add "X-Amz-Target", valid_600187
  var valid_600188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-Content-Sha256", valid_600188
  var valid_600189 = header.getOrDefault("X-Amz-Algorithm")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-Algorithm", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-Signature")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-Signature", valid_600190
  var valid_600191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-SignedHeaders", valid_600191
  var valid_600192 = header.getOrDefault("X-Amz-Credential")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-Credential", valid_600192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600194: Call_StartQueryExecution_600182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Runs the SQL query statements contained in the <code>Query</code>. Requires you to have access to the workgroup in which the query ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  let valid = call_600194.validator(path, query, header, formData, body)
  let scheme = call_600194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600194.url(scheme.get, call_600194.host, call_600194.base,
                         call_600194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600194, url, valid)

proc call*(call_600195: Call_StartQueryExecution_600182; body: JsonNode): Recallable =
  ## startQueryExecution
  ## <p>Runs the SQL query statements contained in the <code>Query</code>. Requires you to have access to the workgroup in which the query ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ##   body: JObject (required)
  var body_600196 = newJObject()
  if body != nil:
    body_600196 = body
  result = call_600195.call(nil, nil, nil, nil, body_600196)

var startQueryExecution* = Call_StartQueryExecution_600182(
    name: "startQueryExecution", meth: HttpMethod.HttpPost,
    host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.StartQueryExecution",
    validator: validate_StartQueryExecution_600183, base: "/",
    url: url_StartQueryExecution_600184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopQueryExecution_600197 = ref object of OpenApiRestCall_599368
proc url_StopQueryExecution_600199(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopQueryExecution_600198(path: JsonNode; query: JsonNode;
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
  var valid_600200 = header.getOrDefault("X-Amz-Date")
  valid_600200 = validateParameter(valid_600200, JString, required = false,
                                 default = nil)
  if valid_600200 != nil:
    section.add "X-Amz-Date", valid_600200
  var valid_600201 = header.getOrDefault("X-Amz-Security-Token")
  valid_600201 = validateParameter(valid_600201, JString, required = false,
                                 default = nil)
  if valid_600201 != nil:
    section.add "X-Amz-Security-Token", valid_600201
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600202 = header.getOrDefault("X-Amz-Target")
  valid_600202 = validateParameter(valid_600202, JString, required = true, default = newJString(
      "AmazonAthena.StopQueryExecution"))
  if valid_600202 != nil:
    section.add "X-Amz-Target", valid_600202
  var valid_600203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-Content-Sha256", valid_600203
  var valid_600204 = header.getOrDefault("X-Amz-Algorithm")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-Algorithm", valid_600204
  var valid_600205 = header.getOrDefault("X-Amz-Signature")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-Signature", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-SignedHeaders", valid_600206
  var valid_600207 = header.getOrDefault("X-Amz-Credential")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-Credential", valid_600207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600209: Call_StopQueryExecution_600197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a query execution. Requires you to have access to the workgroup in which the query ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ## 
  let valid = call_600209.validator(path, query, header, formData, body)
  let scheme = call_600209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600209.url(scheme.get, call_600209.host, call_600209.base,
                         call_600209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600209, url, valid)

proc call*(call_600210: Call_StopQueryExecution_600197; body: JsonNode): Recallable =
  ## stopQueryExecution
  ## <p>Stops a query execution. Requires you to have access to the workgroup in which the query ran.</p> <p>For code samples using the AWS SDK for Java, see <a href="http://docs.aws.amazon.com/athena/latest/ug/code-samples.html">Examples and Code Samples</a> in the <i>Amazon Athena User Guide</i>.</p>
  ##   body: JObject (required)
  var body_600211 = newJObject()
  if body != nil:
    body_600211 = body
  result = call_600210.call(nil, nil, nil, nil, body_600211)

var stopQueryExecution* = Call_StopQueryExecution_600197(
    name: "stopQueryExecution", meth: HttpMethod.HttpPost,
    host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.StopQueryExecution",
    validator: validate_StopQueryExecution_600198, base: "/",
    url: url_StopQueryExecution_600199, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600212 = ref object of OpenApiRestCall_599368
proc url_TagResource_600214(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_600213(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600215 = header.getOrDefault("X-Amz-Date")
  valid_600215 = validateParameter(valid_600215, JString, required = false,
                                 default = nil)
  if valid_600215 != nil:
    section.add "X-Amz-Date", valid_600215
  var valid_600216 = header.getOrDefault("X-Amz-Security-Token")
  valid_600216 = validateParameter(valid_600216, JString, required = false,
                                 default = nil)
  if valid_600216 != nil:
    section.add "X-Amz-Security-Token", valid_600216
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600217 = header.getOrDefault("X-Amz-Target")
  valid_600217 = validateParameter(valid_600217, JString, required = true, default = newJString(
      "AmazonAthena.TagResource"))
  if valid_600217 != nil:
    section.add "X-Amz-Target", valid_600217
  var valid_600218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-Content-Sha256", valid_600218
  var valid_600219 = header.getOrDefault("X-Amz-Algorithm")
  valid_600219 = validateParameter(valid_600219, JString, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "X-Amz-Algorithm", valid_600219
  var valid_600220 = header.getOrDefault("X-Amz-Signature")
  valid_600220 = validateParameter(valid_600220, JString, required = false,
                                 default = nil)
  if valid_600220 != nil:
    section.add "X-Amz-Signature", valid_600220
  var valid_600221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-SignedHeaders", valid_600221
  var valid_600222 = header.getOrDefault("X-Amz-Credential")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-Credential", valid_600222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600224: Call_TagResource_600212; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to the resource, such as a workgroup. A tag is a label that you assign to an AWS Athena resource (a workgroup). Each tag consists of a key and an optional value, both of which you define. Tags enable you to categorize resources (workgroups) in Athena, for example, by purpose, owner, or environment. Use a consistent set of tag keys to make it easier to search and filter workgroups in your account. For best practices, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>. The key length is from 1 (minimum) to 128 (maximum) Unicode characters in UTF-8. The tag value length is from 0 (minimum) to 256 (maximum) Unicode characters in UTF-8. You can use letters and numbers representable in UTF-8, and the following characters: + - = . _ : / @. Tag keys and values are case-sensitive. Tag keys must be unique per resource. If you specify more than one, separate them by commas.
  ## 
  let valid = call_600224.validator(path, query, header, formData, body)
  let scheme = call_600224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600224.url(scheme.get, call_600224.host, call_600224.base,
                         call_600224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600224, url, valid)

proc call*(call_600225: Call_TagResource_600212; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags to the resource, such as a workgroup. A tag is a label that you assign to an AWS Athena resource (a workgroup). Each tag consists of a key and an optional value, both of which you define. Tags enable you to categorize resources (workgroups) in Athena, for example, by purpose, owner, or environment. Use a consistent set of tag keys to make it easier to search and filter workgroups in your account. For best practices, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>. The key length is from 1 (minimum) to 128 (maximum) Unicode characters in UTF-8. The tag value length is from 0 (minimum) to 256 (maximum) Unicode characters in UTF-8. You can use letters and numbers representable in UTF-8, and the following characters: + - = . _ : / @. Tag keys and values are case-sensitive. Tag keys must be unique per resource. If you specify more than one, separate them by commas.
  ##   body: JObject (required)
  var body_600226 = newJObject()
  if body != nil:
    body_600226 = body
  result = call_600225.call(nil, nil, nil, nil, body_600226)

var tagResource* = Call_TagResource_600212(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "athena.amazonaws.com", route: "/#X-Amz-Target=AmazonAthena.TagResource",
                                        validator: validate_TagResource_600213,
                                        base: "/", url: url_TagResource_600214,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600227 = ref object of OpenApiRestCall_599368
proc url_UntagResource_600229(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_600228(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600230 = header.getOrDefault("X-Amz-Date")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "X-Amz-Date", valid_600230
  var valid_600231 = header.getOrDefault("X-Amz-Security-Token")
  valid_600231 = validateParameter(valid_600231, JString, required = false,
                                 default = nil)
  if valid_600231 != nil:
    section.add "X-Amz-Security-Token", valid_600231
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600232 = header.getOrDefault("X-Amz-Target")
  valid_600232 = validateParameter(valid_600232, JString, required = true, default = newJString(
      "AmazonAthena.UntagResource"))
  if valid_600232 != nil:
    section.add "X-Amz-Target", valid_600232
  var valid_600233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-Content-Sha256", valid_600233
  var valid_600234 = header.getOrDefault("X-Amz-Algorithm")
  valid_600234 = validateParameter(valid_600234, JString, required = false,
                                 default = nil)
  if valid_600234 != nil:
    section.add "X-Amz-Algorithm", valid_600234
  var valid_600235 = header.getOrDefault("X-Amz-Signature")
  valid_600235 = validateParameter(valid_600235, JString, required = false,
                                 default = nil)
  if valid_600235 != nil:
    section.add "X-Amz-Signature", valid_600235
  var valid_600236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600236 = validateParameter(valid_600236, JString, required = false,
                                 default = nil)
  if valid_600236 != nil:
    section.add "X-Amz-SignedHeaders", valid_600236
  var valid_600237 = header.getOrDefault("X-Amz-Credential")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "X-Amz-Credential", valid_600237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600239: Call_UntagResource_600227; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the workgroup resource. Takes as an input a list of TagKey Strings separated by commas, and removes their tags at the same time.
  ## 
  let valid = call_600239.validator(path, query, header, formData, body)
  let scheme = call_600239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600239.url(scheme.get, call_600239.host, call_600239.base,
                         call_600239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600239, url, valid)

proc call*(call_600240: Call_UntagResource_600227; body: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags from the workgroup resource. Takes as an input a list of TagKey Strings separated by commas, and removes their tags at the same time.
  ##   body: JObject (required)
  var body_600241 = newJObject()
  if body != nil:
    body_600241 = body
  result = call_600240.call(nil, nil, nil, nil, body_600241)

var untagResource* = Call_UntagResource_600227(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.UntagResource",
    validator: validate_UntagResource_600228, base: "/", url: url_UntagResource_600229,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkGroup_600242 = ref object of OpenApiRestCall_599368
proc url_UpdateWorkGroup_600244(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateWorkGroup_600243(path: JsonNode; query: JsonNode;
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
  var valid_600245 = header.getOrDefault("X-Amz-Date")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "X-Amz-Date", valid_600245
  var valid_600246 = header.getOrDefault("X-Amz-Security-Token")
  valid_600246 = validateParameter(valid_600246, JString, required = false,
                                 default = nil)
  if valid_600246 != nil:
    section.add "X-Amz-Security-Token", valid_600246
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600247 = header.getOrDefault("X-Amz-Target")
  valid_600247 = validateParameter(valid_600247, JString, required = true, default = newJString(
      "AmazonAthena.UpdateWorkGroup"))
  if valid_600247 != nil:
    section.add "X-Amz-Target", valid_600247
  var valid_600248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-Content-Sha256", valid_600248
  var valid_600249 = header.getOrDefault("X-Amz-Algorithm")
  valid_600249 = validateParameter(valid_600249, JString, required = false,
                                 default = nil)
  if valid_600249 != nil:
    section.add "X-Amz-Algorithm", valid_600249
  var valid_600250 = header.getOrDefault("X-Amz-Signature")
  valid_600250 = validateParameter(valid_600250, JString, required = false,
                                 default = nil)
  if valid_600250 != nil:
    section.add "X-Amz-Signature", valid_600250
  var valid_600251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "X-Amz-SignedHeaders", valid_600251
  var valid_600252 = header.getOrDefault("X-Amz-Credential")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "X-Amz-Credential", valid_600252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600254: Call_UpdateWorkGroup_600242; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the workgroup with the specified name. The workgroup's name cannot be changed.
  ## 
  let valid = call_600254.validator(path, query, header, formData, body)
  let scheme = call_600254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600254.url(scheme.get, call_600254.host, call_600254.base,
                         call_600254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600254, url, valid)

proc call*(call_600255: Call_UpdateWorkGroup_600242; body: JsonNode): Recallable =
  ## updateWorkGroup
  ## Updates the workgroup with the specified name. The workgroup's name cannot be changed.
  ##   body: JObject (required)
  var body_600256 = newJObject()
  if body != nil:
    body_600256 = body
  result = call_600255.call(nil, nil, nil, nil, body_600256)

var updateWorkGroup* = Call_UpdateWorkGroup_600242(name: "updateWorkGroup",
    meth: HttpMethod.HttpPost, host: "athena.amazonaws.com",
    route: "/#X-Amz-Target=AmazonAthena.UpdateWorkGroup",
    validator: validate_UpdateWorkGroup_600243, base: "/", url: url_UpdateWorkGroup_600244,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
