
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS RDS DataService
## version: 2018-08-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p><fullname>Amazon RDS Data Service</fullname> <p>Amazon RDS provides an HTTP endpoint to run SQL statements on an Amazon Aurora Serverless DB cluster. To run these statements, you work with the Data Service API.</p> <p>For more information about the Data Service API, see <a href="https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/data-api.html">Using the Data API for Aurora Serverless</a> in the <i>Amazon Aurora User Guide</i>.</p> <note> <p>If you have questions or comments related to the Data API, send email to <a href="mailto:Rds-data-api-feedback@amazon.com">Rds-data-api-feedback@amazon.com</a>.</p> </note></p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/rds-data/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "rds-data.ap-northeast-1.amazonaws.com", "ap-southeast-1": "rds-data.ap-southeast-1.amazonaws.com",
                           "us-west-2": "rds-data.us-west-2.amazonaws.com",
                           "eu-west-2": "rds-data.eu-west-2.amazonaws.com", "ap-northeast-3": "rds-data.ap-northeast-3.amazonaws.com", "eu-central-1": "rds-data.eu-central-1.amazonaws.com",
                           "us-east-2": "rds-data.us-east-2.amazonaws.com",
                           "us-east-1": "rds-data.us-east-1.amazonaws.com", "cn-northwest-1": "rds-data.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "rds-data.ap-south-1.amazonaws.com",
                           "eu-north-1": "rds-data.eu-north-1.amazonaws.com", "ap-northeast-2": "rds-data.ap-northeast-2.amazonaws.com",
                           "us-west-1": "rds-data.us-west-1.amazonaws.com", "us-gov-east-1": "rds-data.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "rds-data.eu-west-3.amazonaws.com", "cn-north-1": "rds-data.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "rds-data.sa-east-1.amazonaws.com",
                           "eu-west-1": "rds-data.eu-west-1.amazonaws.com", "us-gov-west-1": "rds-data.us-gov-west-1.amazonaws.com", "ap-southeast-2": "rds-data.ap-southeast-2.amazonaws.com", "ca-central-1": "rds-data.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "rds-data.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "rds-data.ap-southeast-1.amazonaws.com",
      "us-west-2": "rds-data.us-west-2.amazonaws.com",
      "eu-west-2": "rds-data.eu-west-2.amazonaws.com",
      "ap-northeast-3": "rds-data.ap-northeast-3.amazonaws.com",
      "eu-central-1": "rds-data.eu-central-1.amazonaws.com",
      "us-east-2": "rds-data.us-east-2.amazonaws.com",
      "us-east-1": "rds-data.us-east-1.amazonaws.com",
      "cn-northwest-1": "rds-data.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "rds-data.ap-south-1.amazonaws.com",
      "eu-north-1": "rds-data.eu-north-1.amazonaws.com",
      "ap-northeast-2": "rds-data.ap-northeast-2.amazonaws.com",
      "us-west-1": "rds-data.us-west-1.amazonaws.com",
      "us-gov-east-1": "rds-data.us-gov-east-1.amazonaws.com",
      "eu-west-3": "rds-data.eu-west-3.amazonaws.com",
      "cn-north-1": "rds-data.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "rds-data.sa-east-1.amazonaws.com",
      "eu-west-1": "rds-data.eu-west-1.amazonaws.com",
      "us-gov-west-1": "rds-data.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "rds-data.ap-southeast-2.amazonaws.com",
      "ca-central-1": "rds-data.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "rds-data"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchExecuteStatement_599705 = ref object of OpenApiRestCall_599368
proc url_BatchExecuteStatement_599707(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchExecuteStatement_599706(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Runs a batch SQL statement over an array of data.</p> <p>You can run bulk update and insert operations for multiple records using a DML statement with different parameter sets. Bulk operations can provide a significant performance improvement over individual insert and update operations.</p> <important> <p>If a call isn't part of a transaction because it doesn't include the <code>transactionID</code> parameter, changes that result from the call are committed automatically.</p> </important>
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
  var valid_599821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599821 = validateParameter(valid_599821, JString, required = false,
                                 default = nil)
  if valid_599821 != nil:
    section.add "X-Amz-Content-Sha256", valid_599821
  var valid_599822 = header.getOrDefault("X-Amz-Algorithm")
  valid_599822 = validateParameter(valid_599822, JString, required = false,
                                 default = nil)
  if valid_599822 != nil:
    section.add "X-Amz-Algorithm", valid_599822
  var valid_599823 = header.getOrDefault("X-Amz-Signature")
  valid_599823 = validateParameter(valid_599823, JString, required = false,
                                 default = nil)
  if valid_599823 != nil:
    section.add "X-Amz-Signature", valid_599823
  var valid_599824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599824 = validateParameter(valid_599824, JString, required = false,
                                 default = nil)
  if valid_599824 != nil:
    section.add "X-Amz-SignedHeaders", valid_599824
  var valid_599825 = header.getOrDefault("X-Amz-Credential")
  valid_599825 = validateParameter(valid_599825, JString, required = false,
                                 default = nil)
  if valid_599825 != nil:
    section.add "X-Amz-Credential", valid_599825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599849: Call_BatchExecuteStatement_599705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Runs a batch SQL statement over an array of data.</p> <p>You can run bulk update and insert operations for multiple records using a DML statement with different parameter sets. Bulk operations can provide a significant performance improvement over individual insert and update operations.</p> <important> <p>If a call isn't part of a transaction because it doesn't include the <code>transactionID</code> parameter, changes that result from the call are committed automatically.</p> </important>
  ## 
  let valid = call_599849.validator(path, query, header, formData, body)
  let scheme = call_599849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599849.url(scheme.get, call_599849.host, call_599849.base,
                         call_599849.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599849, url, valid)

proc call*(call_599920: Call_BatchExecuteStatement_599705; body: JsonNode): Recallable =
  ## batchExecuteStatement
  ## <p>Runs a batch SQL statement over an array of data.</p> <p>You can run bulk update and insert operations for multiple records using a DML statement with different parameter sets. Bulk operations can provide a significant performance improvement over individual insert and update operations.</p> <important> <p>If a call isn't part of a transaction because it doesn't include the <code>transactionID</code> parameter, changes that result from the call are committed automatically.</p> </important>
  ##   body: JObject (required)
  var body_599921 = newJObject()
  if body != nil:
    body_599921 = body
  result = call_599920.call(nil, nil, nil, nil, body_599921)

var batchExecuteStatement* = Call_BatchExecuteStatement_599705(
    name: "batchExecuteStatement", meth: HttpMethod.HttpPost,
    host: "rds-data.amazonaws.com", route: "/BatchExecute",
    validator: validate_BatchExecuteStatement_599706, base: "/",
    url: url_BatchExecuteStatement_599707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BeginTransaction_599960 = ref object of OpenApiRestCall_599368
proc url_BeginTransaction_599962(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BeginTransaction_599961(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Starts a SQL transaction.</p> <pre><code> &lt;important&gt; &lt;p&gt;A transaction can run for a maximum of 24 hours. A transaction is terminated and rolled back automatically after 24 hours.&lt;/p&gt; &lt;p&gt;A transaction times out if no calls use its transaction ID in three minutes. If a transaction times out before it's committed, it's rolled back automatically.&lt;/p&gt; &lt;p&gt;DDL statements inside a transaction cause an implicit commit. We recommend that you run each DDL statement in a separate &lt;code&gt;ExecuteStatement&lt;/code&gt; call with &lt;code&gt;continueAfterTimeout&lt;/code&gt; enabled.&lt;/p&gt; &lt;/important&gt; </code></pre>
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599963 = header.getOrDefault("X-Amz-Date")
  valid_599963 = validateParameter(valid_599963, JString, required = false,
                                 default = nil)
  if valid_599963 != nil:
    section.add "X-Amz-Date", valid_599963
  var valid_599964 = header.getOrDefault("X-Amz-Security-Token")
  valid_599964 = validateParameter(valid_599964, JString, required = false,
                                 default = nil)
  if valid_599964 != nil:
    section.add "X-Amz-Security-Token", valid_599964
  var valid_599965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599965 = validateParameter(valid_599965, JString, required = false,
                                 default = nil)
  if valid_599965 != nil:
    section.add "X-Amz-Content-Sha256", valid_599965
  var valid_599966 = header.getOrDefault("X-Amz-Algorithm")
  valid_599966 = validateParameter(valid_599966, JString, required = false,
                                 default = nil)
  if valid_599966 != nil:
    section.add "X-Amz-Algorithm", valid_599966
  var valid_599967 = header.getOrDefault("X-Amz-Signature")
  valid_599967 = validateParameter(valid_599967, JString, required = false,
                                 default = nil)
  if valid_599967 != nil:
    section.add "X-Amz-Signature", valid_599967
  var valid_599968 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599968 = validateParameter(valid_599968, JString, required = false,
                                 default = nil)
  if valid_599968 != nil:
    section.add "X-Amz-SignedHeaders", valid_599968
  var valid_599969 = header.getOrDefault("X-Amz-Credential")
  valid_599969 = validateParameter(valid_599969, JString, required = false,
                                 default = nil)
  if valid_599969 != nil:
    section.add "X-Amz-Credential", valid_599969
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599971: Call_BeginTransaction_599960; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a SQL transaction.</p> <pre><code> &lt;important&gt; &lt;p&gt;A transaction can run for a maximum of 24 hours. A transaction is terminated and rolled back automatically after 24 hours.&lt;/p&gt; &lt;p&gt;A transaction times out if no calls use its transaction ID in three minutes. If a transaction times out before it's committed, it's rolled back automatically.&lt;/p&gt; &lt;p&gt;DDL statements inside a transaction cause an implicit commit. We recommend that you run each DDL statement in a separate &lt;code&gt;ExecuteStatement&lt;/code&gt; call with &lt;code&gt;continueAfterTimeout&lt;/code&gt; enabled.&lt;/p&gt; &lt;/important&gt; </code></pre>
  ## 
  let valid = call_599971.validator(path, query, header, formData, body)
  let scheme = call_599971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599971.url(scheme.get, call_599971.host, call_599971.base,
                         call_599971.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599971, url, valid)

proc call*(call_599972: Call_BeginTransaction_599960; body: JsonNode): Recallable =
  ## beginTransaction
  ## <p>Starts a SQL transaction.</p> <pre><code> &lt;important&gt; &lt;p&gt;A transaction can run for a maximum of 24 hours. A transaction is terminated and rolled back automatically after 24 hours.&lt;/p&gt; &lt;p&gt;A transaction times out if no calls use its transaction ID in three minutes. If a transaction times out before it's committed, it's rolled back automatically.&lt;/p&gt; &lt;p&gt;DDL statements inside a transaction cause an implicit commit. We recommend that you run each DDL statement in a separate &lt;code&gt;ExecuteStatement&lt;/code&gt; call with &lt;code&gt;continueAfterTimeout&lt;/code&gt; enabled.&lt;/p&gt; &lt;/important&gt; </code></pre>
  ##   body: JObject (required)
  var body_599973 = newJObject()
  if body != nil:
    body_599973 = body
  result = call_599972.call(nil, nil, nil, nil, body_599973)

var beginTransaction* = Call_BeginTransaction_599960(name: "beginTransaction",
    meth: HttpMethod.HttpPost, host: "rds-data.amazonaws.com",
    route: "/BeginTransaction", validator: validate_BeginTransaction_599961,
    base: "/", url: url_BeginTransaction_599962,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CommitTransaction_599974 = ref object of OpenApiRestCall_599368
proc url_CommitTransaction_599976(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CommitTransaction_599975(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Ends a SQL transaction started with the <code>BeginTransaction</code> operation and commits the changes.
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
  var valid_599979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599979 = validateParameter(valid_599979, JString, required = false,
                                 default = nil)
  if valid_599979 != nil:
    section.add "X-Amz-Content-Sha256", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Algorithm")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Algorithm", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Signature")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Signature", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-SignedHeaders", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Credential")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Credential", valid_599983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599985: Call_CommitTransaction_599974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Ends a SQL transaction started with the <code>BeginTransaction</code> operation and commits the changes.
  ## 
  let valid = call_599985.validator(path, query, header, formData, body)
  let scheme = call_599985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599985.url(scheme.get, call_599985.host, call_599985.base,
                         call_599985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599985, url, valid)

proc call*(call_599986: Call_CommitTransaction_599974; body: JsonNode): Recallable =
  ## commitTransaction
  ## Ends a SQL transaction started with the <code>BeginTransaction</code> operation and commits the changes.
  ##   body: JObject (required)
  var body_599987 = newJObject()
  if body != nil:
    body_599987 = body
  result = call_599986.call(nil, nil, nil, nil, body_599987)

var commitTransaction* = Call_CommitTransaction_599974(name: "commitTransaction",
    meth: HttpMethod.HttpPost, host: "rds-data.amazonaws.com",
    route: "/CommitTransaction", validator: validate_CommitTransaction_599975,
    base: "/", url: url_CommitTransaction_599976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExecuteSql_599988 = ref object of OpenApiRestCall_599368
proc url_ExecuteSql_599990(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ExecuteSql_599989(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Runs one or more SQL statements.</p> <important> <p>This operation is deprecated. Use the <code>BatchExecuteStatement</code> or <code>ExecuteStatement</code> operation.</p> </important>
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599991 = header.getOrDefault("X-Amz-Date")
  valid_599991 = validateParameter(valid_599991, JString, required = false,
                                 default = nil)
  if valid_599991 != nil:
    section.add "X-Amz-Date", valid_599991
  var valid_599992 = header.getOrDefault("X-Amz-Security-Token")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Security-Token", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Content-Sha256", valid_599993
  var valid_599994 = header.getOrDefault("X-Amz-Algorithm")
  valid_599994 = validateParameter(valid_599994, JString, required = false,
                                 default = nil)
  if valid_599994 != nil:
    section.add "X-Amz-Algorithm", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Signature")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Signature", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-SignedHeaders", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Credential")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Credential", valid_599997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599999: Call_ExecuteSql_599988; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Runs one or more SQL statements.</p> <important> <p>This operation is deprecated. Use the <code>BatchExecuteStatement</code> or <code>ExecuteStatement</code> operation.</p> </important>
  ## 
  let valid = call_599999.validator(path, query, header, formData, body)
  let scheme = call_599999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599999.url(scheme.get, call_599999.host, call_599999.base,
                         call_599999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599999, url, valid)

proc call*(call_600000: Call_ExecuteSql_599988; body: JsonNode): Recallable =
  ## executeSql
  ## <p>Runs one or more SQL statements.</p> <important> <p>This operation is deprecated. Use the <code>BatchExecuteStatement</code> or <code>ExecuteStatement</code> operation.</p> </important>
  ##   body: JObject (required)
  var body_600001 = newJObject()
  if body != nil:
    body_600001 = body
  result = call_600000.call(nil, nil, nil, nil, body_600001)

var executeSql* = Call_ExecuteSql_599988(name: "executeSql",
                                      meth: HttpMethod.HttpPost,
                                      host: "rds-data.amazonaws.com",
                                      route: "/ExecuteSql",
                                      validator: validate_ExecuteSql_599989,
                                      base: "/", url: url_ExecuteSql_599990,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExecuteStatement_600002 = ref object of OpenApiRestCall_599368
proc url_ExecuteStatement_600004(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ExecuteStatement_600003(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Runs a SQL statement against a database.</p> <important> <p>If a call isn't part of a transaction because it doesn't include the <code>transactionID</code> parameter, changes that result from the call are committed automatically.</p> </important> <p>The response size limit is 1 MB or 1,000 records. If the call returns more than 1 MB of response data or over 1,000 records, the call is terminated.</p>
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600005 = header.getOrDefault("X-Amz-Date")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Date", valid_600005
  var valid_600006 = header.getOrDefault("X-Amz-Security-Token")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-Security-Token", valid_600006
  var valid_600007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Content-Sha256", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Algorithm")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Algorithm", valid_600008
  var valid_600009 = header.getOrDefault("X-Amz-Signature")
  valid_600009 = validateParameter(valid_600009, JString, required = false,
                                 default = nil)
  if valid_600009 != nil:
    section.add "X-Amz-Signature", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-SignedHeaders", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Credential")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Credential", valid_600011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600013: Call_ExecuteStatement_600002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Runs a SQL statement against a database.</p> <important> <p>If a call isn't part of a transaction because it doesn't include the <code>transactionID</code> parameter, changes that result from the call are committed automatically.</p> </important> <p>The response size limit is 1 MB or 1,000 records. If the call returns more than 1 MB of response data or over 1,000 records, the call is terminated.</p>
  ## 
  let valid = call_600013.validator(path, query, header, formData, body)
  let scheme = call_600013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600013.url(scheme.get, call_600013.host, call_600013.base,
                         call_600013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600013, url, valid)

proc call*(call_600014: Call_ExecuteStatement_600002; body: JsonNode): Recallable =
  ## executeStatement
  ## <p>Runs a SQL statement against a database.</p> <important> <p>If a call isn't part of a transaction because it doesn't include the <code>transactionID</code> parameter, changes that result from the call are committed automatically.</p> </important> <p>The response size limit is 1 MB or 1,000 records. If the call returns more than 1 MB of response data or over 1,000 records, the call is terminated.</p>
  ##   body: JObject (required)
  var body_600015 = newJObject()
  if body != nil:
    body_600015 = body
  result = call_600014.call(nil, nil, nil, nil, body_600015)

var executeStatement* = Call_ExecuteStatement_600002(name: "executeStatement",
    meth: HttpMethod.HttpPost, host: "rds-data.amazonaws.com", route: "/Execute",
    validator: validate_ExecuteStatement_600003, base: "/",
    url: url_ExecuteStatement_600004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RollbackTransaction_600016 = ref object of OpenApiRestCall_599368
proc url_RollbackTransaction_600018(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RollbackTransaction_600017(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Performs a rollback of a transaction. Rolling back a transaction cancels its changes.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600019 = header.getOrDefault("X-Amz-Date")
  valid_600019 = validateParameter(valid_600019, JString, required = false,
                                 default = nil)
  if valid_600019 != nil:
    section.add "X-Amz-Date", valid_600019
  var valid_600020 = header.getOrDefault("X-Amz-Security-Token")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "X-Amz-Security-Token", valid_600020
  var valid_600021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "X-Amz-Content-Sha256", valid_600021
  var valid_600022 = header.getOrDefault("X-Amz-Algorithm")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Algorithm", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-Signature")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Signature", valid_600023
  var valid_600024 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "X-Amz-SignedHeaders", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Credential")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Credential", valid_600025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600027: Call_RollbackTransaction_600016; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Performs a rollback of a transaction. Rolling back a transaction cancels its changes.
  ## 
  let valid = call_600027.validator(path, query, header, formData, body)
  let scheme = call_600027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600027.url(scheme.get, call_600027.host, call_600027.base,
                         call_600027.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600027, url, valid)

proc call*(call_600028: Call_RollbackTransaction_600016; body: JsonNode): Recallable =
  ## rollbackTransaction
  ## Performs a rollback of a transaction. Rolling back a transaction cancels its changes.
  ##   body: JObject (required)
  var body_600029 = newJObject()
  if body != nil:
    body_600029 = body
  result = call_600028.call(nil, nil, nil, nil, body_600029)

var rollbackTransaction* = Call_RollbackTransaction_600016(
    name: "rollbackTransaction", meth: HttpMethod.HttpPost,
    host: "rds-data.amazonaws.com", route: "/RollbackTransaction",
    validator: validate_RollbackTransaction_600017, base: "/",
    url: url_RollbackTransaction_600018, schemes: {Scheme.Https, Scheme.Http})
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
