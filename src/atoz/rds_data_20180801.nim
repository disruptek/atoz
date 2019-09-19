
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_BatchExecuteStatement_600768 = ref object of OpenApiRestCall_600426
proc url_BatchExecuteStatement_600770(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchExecuteStatement_600769(path: JsonNode; query: JsonNode;
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
  var valid_600884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "X-Amz-Content-Sha256", valid_600884
  var valid_600885 = header.getOrDefault("X-Amz-Algorithm")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "X-Amz-Algorithm", valid_600885
  var valid_600886 = header.getOrDefault("X-Amz-Signature")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Signature", valid_600886
  var valid_600887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-SignedHeaders", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Credential")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Credential", valid_600888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600912: Call_BatchExecuteStatement_600768; path: JsonNode;
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
  let valid = call_600912.validator(path, query, header, formData, body)
  let scheme = call_600912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600912.url(scheme.get, call_600912.host, call_600912.base,
                         call_600912.route, valid.getOrDefault("path"))
  result = hook(call_600912, url, valid)

proc call*(call_600983: Call_BatchExecuteStatement_600768; body: JsonNode): Recallable =
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
  var body_600984 = newJObject()
  if body != nil:
    body_600984 = body
  result = call_600983.call(nil, nil, nil, nil, body_600984)

var batchExecuteStatement* = Call_BatchExecuteStatement_600768(
    name: "batchExecuteStatement", meth: HttpMethod.HttpPost,
    host: "rds-data.amazonaws.com", route: "/BatchExecute",
    validator: validate_BatchExecuteStatement_600769, base: "/",
    url: url_BatchExecuteStatement_600770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BeginTransaction_601023 = ref object of OpenApiRestCall_600426
proc url_BeginTransaction_601025(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BeginTransaction_601024(path: JsonNode; query: JsonNode;
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
  var valid_601026 = header.getOrDefault("X-Amz-Date")
  valid_601026 = validateParameter(valid_601026, JString, required = false,
                                 default = nil)
  if valid_601026 != nil:
    section.add "X-Amz-Date", valid_601026
  var valid_601027 = header.getOrDefault("X-Amz-Security-Token")
  valid_601027 = validateParameter(valid_601027, JString, required = false,
                                 default = nil)
  if valid_601027 != nil:
    section.add "X-Amz-Security-Token", valid_601027
  var valid_601028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601028 = validateParameter(valid_601028, JString, required = false,
                                 default = nil)
  if valid_601028 != nil:
    section.add "X-Amz-Content-Sha256", valid_601028
  var valid_601029 = header.getOrDefault("X-Amz-Algorithm")
  valid_601029 = validateParameter(valid_601029, JString, required = false,
                                 default = nil)
  if valid_601029 != nil:
    section.add "X-Amz-Algorithm", valid_601029
  var valid_601030 = header.getOrDefault("X-Amz-Signature")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-Signature", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-SignedHeaders", valid_601031
  var valid_601032 = header.getOrDefault("X-Amz-Credential")
  valid_601032 = validateParameter(valid_601032, JString, required = false,
                                 default = nil)
  if valid_601032 != nil:
    section.add "X-Amz-Credential", valid_601032
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601034: Call_BeginTransaction_601023; path: JsonNode;
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
  let valid = call_601034.validator(path, query, header, formData, body)
  let scheme = call_601034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601034.url(scheme.get, call_601034.host, call_601034.base,
                         call_601034.route, valid.getOrDefault("path"))
  result = hook(call_601034, url, valid)

proc call*(call_601035: Call_BeginTransaction_601023; body: JsonNode): Recallable =
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
  var body_601036 = newJObject()
  if body != nil:
    body_601036 = body
  result = call_601035.call(nil, nil, nil, nil, body_601036)

var beginTransaction* = Call_BeginTransaction_601023(name: "beginTransaction",
    meth: HttpMethod.HttpPost, host: "rds-data.amazonaws.com",
    route: "/BeginTransaction", validator: validate_BeginTransaction_601024,
    base: "/", url: url_BeginTransaction_601025,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CommitTransaction_601037 = ref object of OpenApiRestCall_600426
proc url_CommitTransaction_601039(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CommitTransaction_601038(path: JsonNode; query: JsonNode;
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
  var valid_601042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601042 = validateParameter(valid_601042, JString, required = false,
                                 default = nil)
  if valid_601042 != nil:
    section.add "X-Amz-Content-Sha256", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Algorithm")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Algorithm", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Signature")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Signature", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-SignedHeaders", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Credential")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Credential", valid_601046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601048: Call_CommitTransaction_601037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Ends a SQL transaction started with the <code>BeginTransaction</code> operation and
  ##             commits the changes.
  ## 
  let valid = call_601048.validator(path, query, header, formData, body)
  let scheme = call_601048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601048.url(scheme.get, call_601048.host, call_601048.base,
                         call_601048.route, valid.getOrDefault("path"))
  result = hook(call_601048, url, valid)

proc call*(call_601049: Call_CommitTransaction_601037; body: JsonNode): Recallable =
  ## commitTransaction
  ## Ends a SQL transaction started with the <code>BeginTransaction</code> operation and
  ##             commits the changes.
  ##   body: JObject (required)
  var body_601050 = newJObject()
  if body != nil:
    body_601050 = body
  result = call_601049.call(nil, nil, nil, nil, body_601050)

var commitTransaction* = Call_CommitTransaction_601037(name: "commitTransaction",
    meth: HttpMethod.HttpPost, host: "rds-data.amazonaws.com",
    route: "/CommitTransaction", validator: validate_CommitTransaction_601038,
    base: "/", url: url_CommitTransaction_601039,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExecuteSql_601051 = ref object of OpenApiRestCall_600426
proc url_ExecuteSql_601053(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ExecuteSql_601052(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601054 = header.getOrDefault("X-Amz-Date")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "X-Amz-Date", valid_601054
  var valid_601055 = header.getOrDefault("X-Amz-Security-Token")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Security-Token", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Content-Sha256", valid_601056
  var valid_601057 = header.getOrDefault("X-Amz-Algorithm")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Algorithm", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Signature")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Signature", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-SignedHeaders", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Credential")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Credential", valid_601060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601062: Call_ExecuteSql_601051; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Runs one or more SQL statements.</p>
  ##         <important>
  ##             <p>This operation is deprecated. Use the <code>BatchExecuteStatement</code> or
  ##                     <code>ExecuteStatement</code> operation.</p>
  ##         </important>
  ## 
  let valid = call_601062.validator(path, query, header, formData, body)
  let scheme = call_601062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601062.url(scheme.get, call_601062.host, call_601062.base,
                         call_601062.route, valid.getOrDefault("path"))
  result = hook(call_601062, url, valid)

proc call*(call_601063: Call_ExecuteSql_601051; body: JsonNode): Recallable =
  ## executeSql
  ## <p>Runs one or more SQL statements.</p>
  ##         <important>
  ##             <p>This operation is deprecated. Use the <code>BatchExecuteStatement</code> or
  ##                     <code>ExecuteStatement</code> operation.</p>
  ##         </important>
  ##   body: JObject (required)
  var body_601064 = newJObject()
  if body != nil:
    body_601064 = body
  result = call_601063.call(nil, nil, nil, nil, body_601064)

var executeSql* = Call_ExecuteSql_601051(name: "executeSql",
                                      meth: HttpMethod.HttpPost,
                                      host: "rds-data.amazonaws.com",
                                      route: "/ExecuteSql",
                                      validator: validate_ExecuteSql_601052,
                                      base: "/", url: url_ExecuteSql_601053,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExecuteStatement_601065 = ref object of OpenApiRestCall_600426
proc url_ExecuteStatement_601067(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ExecuteStatement_601066(path: JsonNode; query: JsonNode;
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
  var valid_601068 = header.getOrDefault("X-Amz-Date")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-Date", valid_601068
  var valid_601069 = header.getOrDefault("X-Amz-Security-Token")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Security-Token", valid_601069
  var valid_601070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Content-Sha256", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Algorithm")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Algorithm", valid_601071
  var valid_601072 = header.getOrDefault("X-Amz-Signature")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Signature", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-SignedHeaders", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Credential")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Credential", valid_601074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601076: Call_ExecuteStatement_601065; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Runs a SQL statement against a database.</p>
  ##         <important>    
  ##             <p>If a call isn't part of a transaction because it doesn't include the
  ##                     <code>transactionID</code> parameter, changes that result from the call are
  ##                 committed automatically.</p>    
  ##         </important>
  ##         <p>The response size limit is 1 MB or 1,000 records. If the call returns more than 1 MB of response data or over 1,000 records, the call is terminated.</p>
  ## 
  let valid = call_601076.validator(path, query, header, formData, body)
  let scheme = call_601076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601076.url(scheme.get, call_601076.host, call_601076.base,
                         call_601076.route, valid.getOrDefault("path"))
  result = hook(call_601076, url, valid)

proc call*(call_601077: Call_ExecuteStatement_601065; body: JsonNode): Recallable =
  ## executeStatement
  ## <p>Runs a SQL statement against a database.</p>
  ##         <important>    
  ##             <p>If a call isn't part of a transaction because it doesn't include the
  ##                     <code>transactionID</code> parameter, changes that result from the call are
  ##                 committed automatically.</p>    
  ##         </important>
  ##         <p>The response size limit is 1 MB or 1,000 records. If the call returns more than 1 MB of response data or over 1,000 records, the call is terminated.</p>
  ##   body: JObject (required)
  var body_601078 = newJObject()
  if body != nil:
    body_601078 = body
  result = call_601077.call(nil, nil, nil, nil, body_601078)

var executeStatement* = Call_ExecuteStatement_601065(name: "executeStatement",
    meth: HttpMethod.HttpPost, host: "rds-data.amazonaws.com", route: "/Execute",
    validator: validate_ExecuteStatement_601066, base: "/",
    url: url_ExecuteStatement_601067, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RollbackTransaction_601079 = ref object of OpenApiRestCall_600426
proc url_RollbackTransaction_601081(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RollbackTransaction_601080(path: JsonNode; query: JsonNode;
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
  var valid_601082 = header.getOrDefault("X-Amz-Date")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-Date", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-Security-Token")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Security-Token", valid_601083
  var valid_601084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-Content-Sha256", valid_601084
  var valid_601085 = header.getOrDefault("X-Amz-Algorithm")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Algorithm", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Signature")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Signature", valid_601086
  var valid_601087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-SignedHeaders", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Credential")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Credential", valid_601088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601090: Call_RollbackTransaction_601079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Performs a rollback of a transaction. Rolling back a transaction cancels its changes.
  ## 
  let valid = call_601090.validator(path, query, header, formData, body)
  let scheme = call_601090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601090.url(scheme.get, call_601090.host, call_601090.base,
                         call_601090.route, valid.getOrDefault("path"))
  result = hook(call_601090, url, valid)

proc call*(call_601091: Call_RollbackTransaction_601079; body: JsonNode): Recallable =
  ## rollbackTransaction
  ## Performs a rollback of a transaction. Rolling back a transaction cancels its changes.
  ##   body: JObject (required)
  var body_601092 = newJObject()
  if body != nil:
    body_601092 = body
  result = call_601091.call(nil, nil, nil, nil, body_601092)

var rollbackTransaction* = Call_RollbackTransaction_601079(
    name: "rollbackTransaction", meth: HttpMethod.HttpPost,
    host: "rds-data.amazonaws.com", route: "/RollbackTransaction",
    validator: validate_RollbackTransaction_601080, base: "/",
    url: url_RollbackTransaction_601081, schemes: {Scheme.Https, Scheme.Http})
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
