
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS RDS DataService
## version: 2018-08-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon RDS Data Service</fullname>
##         <p>Amazon RDS provides an HTTP endpoint to run SQL statements on an Amazon Aurora
##             Serverless DB cluster. To run these statements, you work with the Data Service
##             API.</p>
##         <p>For more information about the Data Service API, see <a href="https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/data-api.html">Using the Data API for Aurora
##                 Serverless</a> in the <i>Amazon Aurora User Guide</i>.</p>
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

  OpenApiRestCall_600437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600437): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

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
  Call_BatchExecuteStatement_600774 = ref object of OpenApiRestCall_600437
proc url_BatchExecuteStatement_600776(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchExecuteStatement_600775(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Runs a batch SQL statement over an array of data.</p>
  ##         <p>You can run bulk update and insert operations for multiple records using a DML 
  ##             statement with different parameter sets. Bulk operations can provide a significant 
  ##             performance improvement over individual insert and update operations.</p>
  ##         <important>    
  ##             <p>If a call isn't part of a transaction because it doesn't include the
  ##                     <code>transactionID</code> parameter, changes that result from the call are
  ##                 committed automatically.</p>    
  ##         </important>
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
  var valid_600888 = header.getOrDefault("X-Amz-Date")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Date", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-Security-Token")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Security-Token", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Content-Sha256", valid_600890
  var valid_600891 = header.getOrDefault("X-Amz-Algorithm")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-Algorithm", valid_600891
  var valid_600892 = header.getOrDefault("X-Amz-Signature")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "X-Amz-Signature", valid_600892
  var valid_600893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600893 = validateParameter(valid_600893, JString, required = false,
                                 default = nil)
  if valid_600893 != nil:
    section.add "X-Amz-SignedHeaders", valid_600893
  var valid_600894 = header.getOrDefault("X-Amz-Credential")
  valid_600894 = validateParameter(valid_600894, JString, required = false,
                                 default = nil)
  if valid_600894 != nil:
    section.add "X-Amz-Credential", valid_600894
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600918: Call_BatchExecuteStatement_600774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Runs a batch SQL statement over an array of data.</p>
  ##         <p>You can run bulk update and insert operations for multiple records using a DML 
  ##             statement with different parameter sets. Bulk operations can provide a significant 
  ##             performance improvement over individual insert and update operations.</p>
  ##         <important>    
  ##             <p>If a call isn't part of a transaction because it doesn't include the
  ##                     <code>transactionID</code> parameter, changes that result from the call are
  ##                 committed automatically.</p>    
  ##         </important>
  ## 
  let valid = call_600918.validator(path, query, header, formData, body)
  let scheme = call_600918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600918.url(scheme.get, call_600918.host, call_600918.base,
                         call_600918.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600918, url, valid)

proc call*(call_600989: Call_BatchExecuteStatement_600774; body: JsonNode): Recallable =
  ## batchExecuteStatement
  ## <p>Runs a batch SQL statement over an array of data.</p>
  ##         <p>You can run bulk update and insert operations for multiple records using a DML 
  ##             statement with different parameter sets. Bulk operations can provide a significant 
  ##             performance improvement over individual insert and update operations.</p>
  ##         <important>    
  ##             <p>If a call isn't part of a transaction because it doesn't include the
  ##                     <code>transactionID</code> parameter, changes that result from the call are
  ##                 committed automatically.</p>    
  ##         </important>
  ##   body: JObject (required)
  var body_600990 = newJObject()
  if body != nil:
    body_600990 = body
  result = call_600989.call(nil, nil, nil, nil, body_600990)

var batchExecuteStatement* = Call_BatchExecuteStatement_600774(
    name: "batchExecuteStatement", meth: HttpMethod.HttpPost,
    host: "rds-data.amazonaws.com", route: "/BatchExecute",
    validator: validate_BatchExecuteStatement_600775, base: "/",
    url: url_BatchExecuteStatement_600776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BeginTransaction_601029 = ref object of OpenApiRestCall_600437
proc url_BeginTransaction_601031(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BeginTransaction_601030(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Starts a SQL transaction.</p>
  ##         
  ##         <important>
  ##             <p>A transaction can run for a maximum of 24 hours. A transaction is terminated and 
  ##                 rolled back automatically after 24 hours.</p>
  ##             <p>A transaction times out if no calls use its transaction ID in three minutes. 
  ##                 If a transaction times out before it's committed, it's rolled back
  ##                 automatically.</p>
  ##             <p>DDL statements inside a transaction cause an implicit commit. We recommend 
  ##                 that you run each DDL statement in a separate <code>ExecuteStatement</code> call with 
  ##                 <code>continueAfterTimeout</code> enabled.</p>
  ##         </important>
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
  var valid_601032 = header.getOrDefault("X-Amz-Date")
  valid_601032 = validateParameter(valid_601032, JString, required = false,
                                 default = nil)
  if valid_601032 != nil:
    section.add "X-Amz-Date", valid_601032
  var valid_601033 = header.getOrDefault("X-Amz-Security-Token")
  valid_601033 = validateParameter(valid_601033, JString, required = false,
                                 default = nil)
  if valid_601033 != nil:
    section.add "X-Amz-Security-Token", valid_601033
  var valid_601034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601034 = validateParameter(valid_601034, JString, required = false,
                                 default = nil)
  if valid_601034 != nil:
    section.add "X-Amz-Content-Sha256", valid_601034
  var valid_601035 = header.getOrDefault("X-Amz-Algorithm")
  valid_601035 = validateParameter(valid_601035, JString, required = false,
                                 default = nil)
  if valid_601035 != nil:
    section.add "X-Amz-Algorithm", valid_601035
  var valid_601036 = header.getOrDefault("X-Amz-Signature")
  valid_601036 = validateParameter(valid_601036, JString, required = false,
                                 default = nil)
  if valid_601036 != nil:
    section.add "X-Amz-Signature", valid_601036
  var valid_601037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601037 = validateParameter(valid_601037, JString, required = false,
                                 default = nil)
  if valid_601037 != nil:
    section.add "X-Amz-SignedHeaders", valid_601037
  var valid_601038 = header.getOrDefault("X-Amz-Credential")
  valid_601038 = validateParameter(valid_601038, JString, required = false,
                                 default = nil)
  if valid_601038 != nil:
    section.add "X-Amz-Credential", valid_601038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601040: Call_BeginTransaction_601029; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a SQL transaction.</p>
  ##         
  ##         <important>
  ##             <p>A transaction can run for a maximum of 24 hours. A transaction is terminated and 
  ##                 rolled back automatically after 24 hours.</p>
  ##             <p>A transaction times out if no calls use its transaction ID in three minutes. 
  ##                 If a transaction times out before it's committed, it's rolled back
  ##                 automatically.</p>
  ##             <p>DDL statements inside a transaction cause an implicit commit. We recommend 
  ##                 that you run each DDL statement in a separate <code>ExecuteStatement</code> call with 
  ##                 <code>continueAfterTimeout</code> enabled.</p>
  ##         </important>
  ## 
  let valid = call_601040.validator(path, query, header, formData, body)
  let scheme = call_601040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601040.url(scheme.get, call_601040.host, call_601040.base,
                         call_601040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601040, url, valid)

proc call*(call_601041: Call_BeginTransaction_601029; body: JsonNode): Recallable =
  ## beginTransaction
  ## <p>Starts a SQL transaction.</p>
  ##         
  ##         <important>
  ##             <p>A transaction can run for a maximum of 24 hours. A transaction is terminated and 
  ##                 rolled back automatically after 24 hours.</p>
  ##             <p>A transaction times out if no calls use its transaction ID in three minutes. 
  ##                 If a transaction times out before it's committed, it's rolled back
  ##                 automatically.</p>
  ##             <p>DDL statements inside a transaction cause an implicit commit. We recommend 
  ##                 that you run each DDL statement in a separate <code>ExecuteStatement</code> call with 
  ##                 <code>continueAfterTimeout</code> enabled.</p>
  ##         </important>
  ##   body: JObject (required)
  var body_601042 = newJObject()
  if body != nil:
    body_601042 = body
  result = call_601041.call(nil, nil, nil, nil, body_601042)

var beginTransaction* = Call_BeginTransaction_601029(name: "beginTransaction",
    meth: HttpMethod.HttpPost, host: "rds-data.amazonaws.com",
    route: "/BeginTransaction", validator: validate_BeginTransaction_601030,
    base: "/", url: url_BeginTransaction_601031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CommitTransaction_601043 = ref object of OpenApiRestCall_600437
proc url_CommitTransaction_601045(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CommitTransaction_601044(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Ends a SQL transaction started with the <code>BeginTransaction</code> operation and
  ##             commits the changes.
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
  var valid_601046 = header.getOrDefault("X-Amz-Date")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Date", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Security-Token")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Security-Token", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Content-Sha256", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-Algorithm")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-Algorithm", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Signature")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Signature", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-SignedHeaders", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-Credential")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-Credential", valid_601052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601054: Call_CommitTransaction_601043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Ends a SQL transaction started with the <code>BeginTransaction</code> operation and
  ##             commits the changes.
  ## 
  let valid = call_601054.validator(path, query, header, formData, body)
  let scheme = call_601054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601054.url(scheme.get, call_601054.host, call_601054.base,
                         call_601054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601054, url, valid)

proc call*(call_601055: Call_CommitTransaction_601043; body: JsonNode): Recallable =
  ## commitTransaction
  ## Ends a SQL transaction started with the <code>BeginTransaction</code> operation and
  ##             commits the changes.
  ##   body: JObject (required)
  var body_601056 = newJObject()
  if body != nil:
    body_601056 = body
  result = call_601055.call(nil, nil, nil, nil, body_601056)

var commitTransaction* = Call_CommitTransaction_601043(name: "commitTransaction",
    meth: HttpMethod.HttpPost, host: "rds-data.amazonaws.com",
    route: "/CommitTransaction", validator: validate_CommitTransaction_601044,
    base: "/", url: url_CommitTransaction_601045,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExecuteSql_601057 = ref object of OpenApiRestCall_600437
proc url_ExecuteSql_601059(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ExecuteSql_601058(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Runs one or more SQL statements.</p>
  ##         <important>
  ##             <p>This operation is deprecated. Use the <code>BatchExecuteStatement</code> or
  ##                     <code>ExecuteStatement</code> operation.</p>
  ##         </important>
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
  var valid_601060 = header.getOrDefault("X-Amz-Date")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Date", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Security-Token")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Security-Token", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Content-Sha256", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-Algorithm")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-Algorithm", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-Signature")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-Signature", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-SignedHeaders", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-Credential")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-Credential", valid_601066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601068: Call_ExecuteSql_601057; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Runs one or more SQL statements.</p>
  ##         <important>
  ##             <p>This operation is deprecated. Use the <code>BatchExecuteStatement</code> or
  ##                     <code>ExecuteStatement</code> operation.</p>
  ##         </important>
  ## 
  let valid = call_601068.validator(path, query, header, formData, body)
  let scheme = call_601068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601068.url(scheme.get, call_601068.host, call_601068.base,
                         call_601068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601068, url, valid)

proc call*(call_601069: Call_ExecuteSql_601057; body: JsonNode): Recallable =
  ## executeSql
  ## <p>Runs one or more SQL statements.</p>
  ##         <important>
  ##             <p>This operation is deprecated. Use the <code>BatchExecuteStatement</code> or
  ##                     <code>ExecuteStatement</code> operation.</p>
  ##         </important>
  ##   body: JObject (required)
  var body_601070 = newJObject()
  if body != nil:
    body_601070 = body
  result = call_601069.call(nil, nil, nil, nil, body_601070)

var executeSql* = Call_ExecuteSql_601057(name: "executeSql",
                                      meth: HttpMethod.HttpPost,
                                      host: "rds-data.amazonaws.com",
                                      route: "/ExecuteSql",
                                      validator: validate_ExecuteSql_601058,
                                      base: "/", url: url_ExecuteSql_601059,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExecuteStatement_601071 = ref object of OpenApiRestCall_600437
proc url_ExecuteStatement_601073(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ExecuteStatement_601072(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Runs a SQL statement against a database.</p>
  ##         <important>    
  ##             <p>If a call isn't part of a transaction because it doesn't include the
  ##                     <code>transactionID</code> parameter, changes that result from the call are
  ##                 committed automatically.</p>    
  ##         </important>
  ##         <p>The response size limit is 1 MB or 1,000 records. If the call returns more than 1 MB of response data or over 1,000 records, the call is terminated.</p>
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
  var valid_601074 = header.getOrDefault("X-Amz-Date")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Date", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Security-Token")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Security-Token", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Content-Sha256", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Algorithm")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Algorithm", valid_601077
  var valid_601078 = header.getOrDefault("X-Amz-Signature")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = nil)
  if valid_601078 != nil:
    section.add "X-Amz-Signature", valid_601078
  var valid_601079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-SignedHeaders", valid_601079
  var valid_601080 = header.getOrDefault("X-Amz-Credential")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-Credential", valid_601080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601082: Call_ExecuteStatement_601071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Runs a SQL statement against a database.</p>
  ##         <important>    
  ##             <p>If a call isn't part of a transaction because it doesn't include the
  ##                     <code>transactionID</code> parameter, changes that result from the call are
  ##                 committed automatically.</p>    
  ##         </important>
  ##         <p>The response size limit is 1 MB or 1,000 records. If the call returns more than 1 MB of response data or over 1,000 records, the call is terminated.</p>
  ## 
  let valid = call_601082.validator(path, query, header, formData, body)
  let scheme = call_601082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601082.url(scheme.get, call_601082.host, call_601082.base,
                         call_601082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601082, url, valid)

proc call*(call_601083: Call_ExecuteStatement_601071; body: JsonNode): Recallable =
  ## executeStatement
  ## <p>Runs a SQL statement against a database.</p>
  ##         <important>    
  ##             <p>If a call isn't part of a transaction because it doesn't include the
  ##                     <code>transactionID</code> parameter, changes that result from the call are
  ##                 committed automatically.</p>    
  ##         </important>
  ##         <p>The response size limit is 1 MB or 1,000 records. If the call returns more than 1 MB of response data or over 1,000 records, the call is terminated.</p>
  ##   body: JObject (required)
  var body_601084 = newJObject()
  if body != nil:
    body_601084 = body
  result = call_601083.call(nil, nil, nil, nil, body_601084)

var executeStatement* = Call_ExecuteStatement_601071(name: "executeStatement",
    meth: HttpMethod.HttpPost, host: "rds-data.amazonaws.com", route: "/Execute",
    validator: validate_ExecuteStatement_601072, base: "/",
    url: url_ExecuteStatement_601073, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RollbackTransaction_601085 = ref object of OpenApiRestCall_600437
proc url_RollbackTransaction_601087(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RollbackTransaction_601086(path: JsonNode; query: JsonNode;
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
  var valid_601088 = header.getOrDefault("X-Amz-Date")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Date", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Security-Token")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Security-Token", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Content-Sha256", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Algorithm")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Algorithm", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Signature")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Signature", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-SignedHeaders", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Credential")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Credential", valid_601094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601096: Call_RollbackTransaction_601085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Performs a rollback of a transaction. Rolling back a transaction cancels its changes.
  ## 
  let valid = call_601096.validator(path, query, header, formData, body)
  let scheme = call_601096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601096.url(scheme.get, call_601096.host, call_601096.base,
                         call_601096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601096, url, valid)

proc call*(call_601097: Call_RollbackTransaction_601085; body: JsonNode): Recallable =
  ## rollbackTransaction
  ## Performs a rollback of a transaction. Rolling back a transaction cancels its changes.
  ##   body: JObject (required)
  var body_601098 = newJObject()
  if body != nil:
    body_601098 = body
  result = call_601097.call(nil, nil, nil, nil, body_601098)

var rollbackTransaction* = Call_RollbackTransaction_601085(
    name: "rollbackTransaction", meth: HttpMethod.HttpPost,
    host: "rds-data.amazonaws.com", route: "/RollbackTransaction",
    validator: validate_RollbackTransaction_601086, base: "/",
    url: url_RollbackTransaction_601087, schemes: {Scheme.Https, Scheme.Http})
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
