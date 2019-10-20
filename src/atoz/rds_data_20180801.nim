
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchExecuteStatement_592703 = ref object of OpenApiRestCall_592364
proc url_BatchExecuteStatement_592705(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchExecuteStatement_592704(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592817 = header.getOrDefault("X-Amz-Signature")
  valid_592817 = validateParameter(valid_592817, JString, required = false,
                                 default = nil)
  if valid_592817 != nil:
    section.add "X-Amz-Signature", valid_592817
  var valid_592818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592818 = validateParameter(valid_592818, JString, required = false,
                                 default = nil)
  if valid_592818 != nil:
    section.add "X-Amz-Content-Sha256", valid_592818
  var valid_592819 = header.getOrDefault("X-Amz-Date")
  valid_592819 = validateParameter(valid_592819, JString, required = false,
                                 default = nil)
  if valid_592819 != nil:
    section.add "X-Amz-Date", valid_592819
  var valid_592820 = header.getOrDefault("X-Amz-Credential")
  valid_592820 = validateParameter(valid_592820, JString, required = false,
                                 default = nil)
  if valid_592820 != nil:
    section.add "X-Amz-Credential", valid_592820
  var valid_592821 = header.getOrDefault("X-Amz-Security-Token")
  valid_592821 = validateParameter(valid_592821, JString, required = false,
                                 default = nil)
  if valid_592821 != nil:
    section.add "X-Amz-Security-Token", valid_592821
  var valid_592822 = header.getOrDefault("X-Amz-Algorithm")
  valid_592822 = validateParameter(valid_592822, JString, required = false,
                                 default = nil)
  if valid_592822 != nil:
    section.add "X-Amz-Algorithm", valid_592822
  var valid_592823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592823 = validateParameter(valid_592823, JString, required = false,
                                 default = nil)
  if valid_592823 != nil:
    section.add "X-Amz-SignedHeaders", valid_592823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592847: Call_BatchExecuteStatement_592703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Runs a batch SQL statement over an array of data.</p> <p>You can run bulk update and insert operations for multiple records using a DML statement with different parameter sets. Bulk operations can provide a significant performance improvement over individual insert and update operations.</p> <important> <p>If a call isn't part of a transaction because it doesn't include the <code>transactionID</code> parameter, changes that result from the call are committed automatically.</p> </important>
  ## 
  let valid = call_592847.validator(path, query, header, formData, body)
  let scheme = call_592847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592847.url(scheme.get, call_592847.host, call_592847.base,
                         call_592847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592847, url, valid)

proc call*(call_592918: Call_BatchExecuteStatement_592703; body: JsonNode): Recallable =
  ## batchExecuteStatement
  ## <p>Runs a batch SQL statement over an array of data.</p> <p>You can run bulk update and insert operations for multiple records using a DML statement with different parameter sets. Bulk operations can provide a significant performance improvement over individual insert and update operations.</p> <important> <p>If a call isn't part of a transaction because it doesn't include the <code>transactionID</code> parameter, changes that result from the call are committed automatically.</p> </important>
  ##   body: JObject (required)
  var body_592919 = newJObject()
  if body != nil:
    body_592919 = body
  result = call_592918.call(nil, nil, nil, nil, body_592919)

var batchExecuteStatement* = Call_BatchExecuteStatement_592703(
    name: "batchExecuteStatement", meth: HttpMethod.HttpPost,
    host: "rds-data.amazonaws.com", route: "/BatchExecute",
    validator: validate_BatchExecuteStatement_592704, base: "/",
    url: url_BatchExecuteStatement_592705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BeginTransaction_592958 = ref object of OpenApiRestCall_592364
proc url_BeginTransaction_592960(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BeginTransaction_592959(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592961 = header.getOrDefault("X-Amz-Signature")
  valid_592961 = validateParameter(valid_592961, JString, required = false,
                                 default = nil)
  if valid_592961 != nil:
    section.add "X-Amz-Signature", valid_592961
  var valid_592962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592962 = validateParameter(valid_592962, JString, required = false,
                                 default = nil)
  if valid_592962 != nil:
    section.add "X-Amz-Content-Sha256", valid_592962
  var valid_592963 = header.getOrDefault("X-Amz-Date")
  valid_592963 = validateParameter(valid_592963, JString, required = false,
                                 default = nil)
  if valid_592963 != nil:
    section.add "X-Amz-Date", valid_592963
  var valid_592964 = header.getOrDefault("X-Amz-Credential")
  valid_592964 = validateParameter(valid_592964, JString, required = false,
                                 default = nil)
  if valid_592964 != nil:
    section.add "X-Amz-Credential", valid_592964
  var valid_592965 = header.getOrDefault("X-Amz-Security-Token")
  valid_592965 = validateParameter(valid_592965, JString, required = false,
                                 default = nil)
  if valid_592965 != nil:
    section.add "X-Amz-Security-Token", valid_592965
  var valid_592966 = header.getOrDefault("X-Amz-Algorithm")
  valid_592966 = validateParameter(valid_592966, JString, required = false,
                                 default = nil)
  if valid_592966 != nil:
    section.add "X-Amz-Algorithm", valid_592966
  var valid_592967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592967 = validateParameter(valid_592967, JString, required = false,
                                 default = nil)
  if valid_592967 != nil:
    section.add "X-Amz-SignedHeaders", valid_592967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592969: Call_BeginTransaction_592958; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a SQL transaction.</p> <pre><code> &lt;important&gt; &lt;p&gt;A transaction can run for a maximum of 24 hours. A transaction is terminated and rolled back automatically after 24 hours.&lt;/p&gt; &lt;p&gt;A transaction times out if no calls use its transaction ID in three minutes. If a transaction times out before it's committed, it's rolled back automatically.&lt;/p&gt; &lt;p&gt;DDL statements inside a transaction cause an implicit commit. We recommend that you run each DDL statement in a separate &lt;code&gt;ExecuteStatement&lt;/code&gt; call with &lt;code&gt;continueAfterTimeout&lt;/code&gt; enabled.&lt;/p&gt; &lt;/important&gt; </code></pre>
  ## 
  let valid = call_592969.validator(path, query, header, formData, body)
  let scheme = call_592969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592969.url(scheme.get, call_592969.host, call_592969.base,
                         call_592969.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592969, url, valid)

proc call*(call_592970: Call_BeginTransaction_592958; body: JsonNode): Recallable =
  ## beginTransaction
  ## <p>Starts a SQL transaction.</p> <pre><code> &lt;important&gt; &lt;p&gt;A transaction can run for a maximum of 24 hours. A transaction is terminated and rolled back automatically after 24 hours.&lt;/p&gt; &lt;p&gt;A transaction times out if no calls use its transaction ID in three minutes. If a transaction times out before it's committed, it's rolled back automatically.&lt;/p&gt; &lt;p&gt;DDL statements inside a transaction cause an implicit commit. We recommend that you run each DDL statement in a separate &lt;code&gt;ExecuteStatement&lt;/code&gt; call with &lt;code&gt;continueAfterTimeout&lt;/code&gt; enabled.&lt;/p&gt; &lt;/important&gt; </code></pre>
  ##   body: JObject (required)
  var body_592971 = newJObject()
  if body != nil:
    body_592971 = body
  result = call_592970.call(nil, nil, nil, nil, body_592971)

var beginTransaction* = Call_BeginTransaction_592958(name: "beginTransaction",
    meth: HttpMethod.HttpPost, host: "rds-data.amazonaws.com",
    route: "/BeginTransaction", validator: validate_BeginTransaction_592959,
    base: "/", url: url_BeginTransaction_592960,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CommitTransaction_592972 = ref object of OpenApiRestCall_592364
proc url_CommitTransaction_592974(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CommitTransaction_592973(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592975 = header.getOrDefault("X-Amz-Signature")
  valid_592975 = validateParameter(valid_592975, JString, required = false,
                                 default = nil)
  if valid_592975 != nil:
    section.add "X-Amz-Signature", valid_592975
  var valid_592976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592976 = validateParameter(valid_592976, JString, required = false,
                                 default = nil)
  if valid_592976 != nil:
    section.add "X-Amz-Content-Sha256", valid_592976
  var valid_592977 = header.getOrDefault("X-Amz-Date")
  valid_592977 = validateParameter(valid_592977, JString, required = false,
                                 default = nil)
  if valid_592977 != nil:
    section.add "X-Amz-Date", valid_592977
  var valid_592978 = header.getOrDefault("X-Amz-Credential")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "X-Amz-Credential", valid_592978
  var valid_592979 = header.getOrDefault("X-Amz-Security-Token")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Security-Token", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Algorithm")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Algorithm", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-SignedHeaders", valid_592981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592983: Call_CommitTransaction_592972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Ends a SQL transaction started with the <code>BeginTransaction</code> operation and commits the changes.
  ## 
  let valid = call_592983.validator(path, query, header, formData, body)
  let scheme = call_592983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592983.url(scheme.get, call_592983.host, call_592983.base,
                         call_592983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592983, url, valid)

proc call*(call_592984: Call_CommitTransaction_592972; body: JsonNode): Recallable =
  ## commitTransaction
  ## Ends a SQL transaction started with the <code>BeginTransaction</code> operation and commits the changes.
  ##   body: JObject (required)
  var body_592985 = newJObject()
  if body != nil:
    body_592985 = body
  result = call_592984.call(nil, nil, nil, nil, body_592985)

var commitTransaction* = Call_CommitTransaction_592972(name: "commitTransaction",
    meth: HttpMethod.HttpPost, host: "rds-data.amazonaws.com",
    route: "/CommitTransaction", validator: validate_CommitTransaction_592973,
    base: "/", url: url_CommitTransaction_592974,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExecuteSql_592986 = ref object of OpenApiRestCall_592364
proc url_ExecuteSql_592988(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ExecuteSql_592987(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592989 = header.getOrDefault("X-Amz-Signature")
  valid_592989 = validateParameter(valid_592989, JString, required = false,
                                 default = nil)
  if valid_592989 != nil:
    section.add "X-Amz-Signature", valid_592989
  var valid_592990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592990 = validateParameter(valid_592990, JString, required = false,
                                 default = nil)
  if valid_592990 != nil:
    section.add "X-Amz-Content-Sha256", valid_592990
  var valid_592991 = header.getOrDefault("X-Amz-Date")
  valid_592991 = validateParameter(valid_592991, JString, required = false,
                                 default = nil)
  if valid_592991 != nil:
    section.add "X-Amz-Date", valid_592991
  var valid_592992 = header.getOrDefault("X-Amz-Credential")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "X-Amz-Credential", valid_592992
  var valid_592993 = header.getOrDefault("X-Amz-Security-Token")
  valid_592993 = validateParameter(valid_592993, JString, required = false,
                                 default = nil)
  if valid_592993 != nil:
    section.add "X-Amz-Security-Token", valid_592993
  var valid_592994 = header.getOrDefault("X-Amz-Algorithm")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Algorithm", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-SignedHeaders", valid_592995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592997: Call_ExecuteSql_592986; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Runs one or more SQL statements.</p> <important> <p>This operation is deprecated. Use the <code>BatchExecuteStatement</code> or <code>ExecuteStatement</code> operation.</p> </important>
  ## 
  let valid = call_592997.validator(path, query, header, formData, body)
  let scheme = call_592997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592997.url(scheme.get, call_592997.host, call_592997.base,
                         call_592997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592997, url, valid)

proc call*(call_592998: Call_ExecuteSql_592986; body: JsonNode): Recallable =
  ## executeSql
  ## <p>Runs one or more SQL statements.</p> <important> <p>This operation is deprecated. Use the <code>BatchExecuteStatement</code> or <code>ExecuteStatement</code> operation.</p> </important>
  ##   body: JObject (required)
  var body_592999 = newJObject()
  if body != nil:
    body_592999 = body
  result = call_592998.call(nil, nil, nil, nil, body_592999)

var executeSql* = Call_ExecuteSql_592986(name: "executeSql",
                                      meth: HttpMethod.HttpPost,
                                      host: "rds-data.amazonaws.com",
                                      route: "/ExecuteSql",
                                      validator: validate_ExecuteSql_592987,
                                      base: "/", url: url_ExecuteSql_592988,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExecuteStatement_593000 = ref object of OpenApiRestCall_592364
proc url_ExecuteStatement_593002(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ExecuteStatement_593001(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593003 = header.getOrDefault("X-Amz-Signature")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-Signature", valid_593003
  var valid_593004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-Content-Sha256", valid_593004
  var valid_593005 = header.getOrDefault("X-Amz-Date")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "X-Amz-Date", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-Credential")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-Credential", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-Security-Token")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Security-Token", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-Algorithm")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-Algorithm", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-SignedHeaders", valid_593009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593011: Call_ExecuteStatement_593000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Runs a SQL statement against a database.</p> <important> <p>If a call isn't part of a transaction because it doesn't include the <code>transactionID</code> parameter, changes that result from the call are committed automatically.</p> </important> <p>The response size limit is 1 MB or 1,000 records. If the call returns more than 1 MB of response data or over 1,000 records, the call is terminated.</p>
  ## 
  let valid = call_593011.validator(path, query, header, formData, body)
  let scheme = call_593011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593011.url(scheme.get, call_593011.host, call_593011.base,
                         call_593011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593011, url, valid)

proc call*(call_593012: Call_ExecuteStatement_593000; body: JsonNode): Recallable =
  ## executeStatement
  ## <p>Runs a SQL statement against a database.</p> <important> <p>If a call isn't part of a transaction because it doesn't include the <code>transactionID</code> parameter, changes that result from the call are committed automatically.</p> </important> <p>The response size limit is 1 MB or 1,000 records. If the call returns more than 1 MB of response data or over 1,000 records, the call is terminated.</p>
  ##   body: JObject (required)
  var body_593013 = newJObject()
  if body != nil:
    body_593013 = body
  result = call_593012.call(nil, nil, nil, nil, body_593013)

var executeStatement* = Call_ExecuteStatement_593000(name: "executeStatement",
    meth: HttpMethod.HttpPost, host: "rds-data.amazonaws.com", route: "/Execute",
    validator: validate_ExecuteStatement_593001, base: "/",
    url: url_ExecuteStatement_593002, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RollbackTransaction_593014 = ref object of OpenApiRestCall_592364
proc url_RollbackTransaction_593016(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RollbackTransaction_593015(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593017 = header.getOrDefault("X-Amz-Signature")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "X-Amz-Signature", valid_593017
  var valid_593018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "X-Amz-Content-Sha256", valid_593018
  var valid_593019 = header.getOrDefault("X-Amz-Date")
  valid_593019 = validateParameter(valid_593019, JString, required = false,
                                 default = nil)
  if valid_593019 != nil:
    section.add "X-Amz-Date", valid_593019
  var valid_593020 = header.getOrDefault("X-Amz-Credential")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = nil)
  if valid_593020 != nil:
    section.add "X-Amz-Credential", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-Security-Token")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-Security-Token", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-Algorithm")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Algorithm", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-SignedHeaders", valid_593023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593025: Call_RollbackTransaction_593014; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Performs a rollback of a transaction. Rolling back a transaction cancels its changes.
  ## 
  let valid = call_593025.validator(path, query, header, formData, body)
  let scheme = call_593025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593025.url(scheme.get, call_593025.host, call_593025.base,
                         call_593025.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593025, url, valid)

proc call*(call_593026: Call_RollbackTransaction_593014; body: JsonNode): Recallable =
  ## rollbackTransaction
  ## Performs a rollback of a transaction. Rolling back a transaction cancels its changes.
  ##   body: JObject (required)
  var body_593027 = newJObject()
  if body != nil:
    body_593027 = body
  result = call_593026.call(nil, nil, nil, nil, body_593027)

var rollbackTransaction* = Call_RollbackTransaction_593014(
    name: "rollbackTransaction", meth: HttpMethod.HttpPost,
    host: "rds-data.amazonaws.com", route: "/RollbackTransaction",
    validator: validate_RollbackTransaction_593015, base: "/",
    url: url_RollbackTransaction_593016, schemes: {Scheme.Https, Scheme.Http})
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
