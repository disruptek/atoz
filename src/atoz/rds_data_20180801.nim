
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

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
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
  Call_BatchExecuteStatement_772933 = ref object of OpenApiRestCall_772597
proc url_BatchExecuteStatement_772935(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchExecuteStatement_772934(path: JsonNode; query: JsonNode;
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
  var valid_773047 = header.getOrDefault("X-Amz-Date")
  valid_773047 = validateParameter(valid_773047, JString, required = false,
                                 default = nil)
  if valid_773047 != nil:
    section.add "X-Amz-Date", valid_773047
  var valid_773048 = header.getOrDefault("X-Amz-Security-Token")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "X-Amz-Security-Token", valid_773048
  var valid_773049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773049 = validateParameter(valid_773049, JString, required = false,
                                 default = nil)
  if valid_773049 != nil:
    section.add "X-Amz-Content-Sha256", valid_773049
  var valid_773050 = header.getOrDefault("X-Amz-Algorithm")
  valid_773050 = validateParameter(valid_773050, JString, required = false,
                                 default = nil)
  if valid_773050 != nil:
    section.add "X-Amz-Algorithm", valid_773050
  var valid_773051 = header.getOrDefault("X-Amz-Signature")
  valid_773051 = validateParameter(valid_773051, JString, required = false,
                                 default = nil)
  if valid_773051 != nil:
    section.add "X-Amz-Signature", valid_773051
  var valid_773052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773052 = validateParameter(valid_773052, JString, required = false,
                                 default = nil)
  if valid_773052 != nil:
    section.add "X-Amz-SignedHeaders", valid_773052
  var valid_773053 = header.getOrDefault("X-Amz-Credential")
  valid_773053 = validateParameter(valid_773053, JString, required = false,
                                 default = nil)
  if valid_773053 != nil:
    section.add "X-Amz-Credential", valid_773053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773077: Call_BatchExecuteStatement_772933; path: JsonNode;
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
  let valid = call_773077.validator(path, query, header, formData, body)
  let scheme = call_773077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773077.url(scheme.get, call_773077.host, call_773077.base,
                         call_773077.route, valid.getOrDefault("path"))
  result = hook(call_773077, url, valid)

proc call*(call_773148: Call_BatchExecuteStatement_772933; body: JsonNode): Recallable =
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
  var body_773149 = newJObject()
  if body != nil:
    body_773149 = body
  result = call_773148.call(nil, nil, nil, nil, body_773149)

var batchExecuteStatement* = Call_BatchExecuteStatement_772933(
    name: "batchExecuteStatement", meth: HttpMethod.HttpPost,
    host: "rds-data.amazonaws.com", route: "/BatchExecute",
    validator: validate_BatchExecuteStatement_772934, base: "/",
    url: url_BatchExecuteStatement_772935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BeginTransaction_773188 = ref object of OpenApiRestCall_772597
proc url_BeginTransaction_773190(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BeginTransaction_773189(path: JsonNode; query: JsonNode;
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
  var valid_773191 = header.getOrDefault("X-Amz-Date")
  valid_773191 = validateParameter(valid_773191, JString, required = false,
                                 default = nil)
  if valid_773191 != nil:
    section.add "X-Amz-Date", valid_773191
  var valid_773192 = header.getOrDefault("X-Amz-Security-Token")
  valid_773192 = validateParameter(valid_773192, JString, required = false,
                                 default = nil)
  if valid_773192 != nil:
    section.add "X-Amz-Security-Token", valid_773192
  var valid_773193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773193 = validateParameter(valid_773193, JString, required = false,
                                 default = nil)
  if valid_773193 != nil:
    section.add "X-Amz-Content-Sha256", valid_773193
  var valid_773194 = header.getOrDefault("X-Amz-Algorithm")
  valid_773194 = validateParameter(valid_773194, JString, required = false,
                                 default = nil)
  if valid_773194 != nil:
    section.add "X-Amz-Algorithm", valid_773194
  var valid_773195 = header.getOrDefault("X-Amz-Signature")
  valid_773195 = validateParameter(valid_773195, JString, required = false,
                                 default = nil)
  if valid_773195 != nil:
    section.add "X-Amz-Signature", valid_773195
  var valid_773196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773196 = validateParameter(valid_773196, JString, required = false,
                                 default = nil)
  if valid_773196 != nil:
    section.add "X-Amz-SignedHeaders", valid_773196
  var valid_773197 = header.getOrDefault("X-Amz-Credential")
  valid_773197 = validateParameter(valid_773197, JString, required = false,
                                 default = nil)
  if valid_773197 != nil:
    section.add "X-Amz-Credential", valid_773197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773199: Call_BeginTransaction_773188; path: JsonNode;
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
  let valid = call_773199.validator(path, query, header, formData, body)
  let scheme = call_773199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773199.url(scheme.get, call_773199.host, call_773199.base,
                         call_773199.route, valid.getOrDefault("path"))
  result = hook(call_773199, url, valid)

proc call*(call_773200: Call_BeginTransaction_773188; body: JsonNode): Recallable =
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
  var body_773201 = newJObject()
  if body != nil:
    body_773201 = body
  result = call_773200.call(nil, nil, nil, nil, body_773201)

var beginTransaction* = Call_BeginTransaction_773188(name: "beginTransaction",
    meth: HttpMethod.HttpPost, host: "rds-data.amazonaws.com",
    route: "/BeginTransaction", validator: validate_BeginTransaction_773189,
    base: "/", url: url_BeginTransaction_773190,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CommitTransaction_773202 = ref object of OpenApiRestCall_772597
proc url_CommitTransaction_773204(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CommitTransaction_773203(path: JsonNode; query: JsonNode;
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
  var valid_773205 = header.getOrDefault("X-Amz-Date")
  valid_773205 = validateParameter(valid_773205, JString, required = false,
                                 default = nil)
  if valid_773205 != nil:
    section.add "X-Amz-Date", valid_773205
  var valid_773206 = header.getOrDefault("X-Amz-Security-Token")
  valid_773206 = validateParameter(valid_773206, JString, required = false,
                                 default = nil)
  if valid_773206 != nil:
    section.add "X-Amz-Security-Token", valid_773206
  var valid_773207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773207 = validateParameter(valid_773207, JString, required = false,
                                 default = nil)
  if valid_773207 != nil:
    section.add "X-Amz-Content-Sha256", valid_773207
  var valid_773208 = header.getOrDefault("X-Amz-Algorithm")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "X-Amz-Algorithm", valid_773208
  var valid_773209 = header.getOrDefault("X-Amz-Signature")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Signature", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-SignedHeaders", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-Credential")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-Credential", valid_773211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773213: Call_CommitTransaction_773202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Ends a SQL transaction started with the <code>BeginTransaction</code> operation and
  ##             commits the changes.
  ## 
  let valid = call_773213.validator(path, query, header, formData, body)
  let scheme = call_773213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773213.url(scheme.get, call_773213.host, call_773213.base,
                         call_773213.route, valid.getOrDefault("path"))
  result = hook(call_773213, url, valid)

proc call*(call_773214: Call_CommitTransaction_773202; body: JsonNode): Recallable =
  ## commitTransaction
  ## Ends a SQL transaction started with the <code>BeginTransaction</code> operation and
  ##             commits the changes.
  ##   body: JObject (required)
  var body_773215 = newJObject()
  if body != nil:
    body_773215 = body
  result = call_773214.call(nil, nil, nil, nil, body_773215)

var commitTransaction* = Call_CommitTransaction_773202(name: "commitTransaction",
    meth: HttpMethod.HttpPost, host: "rds-data.amazonaws.com",
    route: "/CommitTransaction", validator: validate_CommitTransaction_773203,
    base: "/", url: url_CommitTransaction_773204,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExecuteSql_773216 = ref object of OpenApiRestCall_772597
proc url_ExecuteSql_773218(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ExecuteSql_773217(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773219 = header.getOrDefault("X-Amz-Date")
  valid_773219 = validateParameter(valid_773219, JString, required = false,
                                 default = nil)
  if valid_773219 != nil:
    section.add "X-Amz-Date", valid_773219
  var valid_773220 = header.getOrDefault("X-Amz-Security-Token")
  valid_773220 = validateParameter(valid_773220, JString, required = false,
                                 default = nil)
  if valid_773220 != nil:
    section.add "X-Amz-Security-Token", valid_773220
  var valid_773221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773221 = validateParameter(valid_773221, JString, required = false,
                                 default = nil)
  if valid_773221 != nil:
    section.add "X-Amz-Content-Sha256", valid_773221
  var valid_773222 = header.getOrDefault("X-Amz-Algorithm")
  valid_773222 = validateParameter(valid_773222, JString, required = false,
                                 default = nil)
  if valid_773222 != nil:
    section.add "X-Amz-Algorithm", valid_773222
  var valid_773223 = header.getOrDefault("X-Amz-Signature")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Signature", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-SignedHeaders", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-Credential")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Credential", valid_773225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773227: Call_ExecuteSql_773216; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Runs one or more SQL statements.</p>
  ##         <important>
  ##             <p>This operation is deprecated. Use the <code>BatchExecuteStatement</code> or
  ##                     <code>ExecuteStatement</code> operation.</p>
  ##         </important>
  ## 
  let valid = call_773227.validator(path, query, header, formData, body)
  let scheme = call_773227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773227.url(scheme.get, call_773227.host, call_773227.base,
                         call_773227.route, valid.getOrDefault("path"))
  result = hook(call_773227, url, valid)

proc call*(call_773228: Call_ExecuteSql_773216; body: JsonNode): Recallable =
  ## executeSql
  ## <p>Runs one or more SQL statements.</p>
  ##         <important>
  ##             <p>This operation is deprecated. Use the <code>BatchExecuteStatement</code> or
  ##                     <code>ExecuteStatement</code> operation.</p>
  ##         </important>
  ##   body: JObject (required)
  var body_773229 = newJObject()
  if body != nil:
    body_773229 = body
  result = call_773228.call(nil, nil, nil, nil, body_773229)

var executeSql* = Call_ExecuteSql_773216(name: "executeSql",
                                      meth: HttpMethod.HttpPost,
                                      host: "rds-data.amazonaws.com",
                                      route: "/ExecuteSql",
                                      validator: validate_ExecuteSql_773217,
                                      base: "/", url: url_ExecuteSql_773218,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExecuteStatement_773230 = ref object of OpenApiRestCall_772597
proc url_ExecuteStatement_773232(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ExecuteStatement_773231(path: JsonNode; query: JsonNode;
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
  var valid_773233 = header.getOrDefault("X-Amz-Date")
  valid_773233 = validateParameter(valid_773233, JString, required = false,
                                 default = nil)
  if valid_773233 != nil:
    section.add "X-Amz-Date", valid_773233
  var valid_773234 = header.getOrDefault("X-Amz-Security-Token")
  valid_773234 = validateParameter(valid_773234, JString, required = false,
                                 default = nil)
  if valid_773234 != nil:
    section.add "X-Amz-Security-Token", valid_773234
  var valid_773235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-Content-Sha256", valid_773235
  var valid_773236 = header.getOrDefault("X-Amz-Algorithm")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-Algorithm", valid_773236
  var valid_773237 = header.getOrDefault("X-Amz-Signature")
  valid_773237 = validateParameter(valid_773237, JString, required = false,
                                 default = nil)
  if valid_773237 != nil:
    section.add "X-Amz-Signature", valid_773237
  var valid_773238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "X-Amz-SignedHeaders", valid_773238
  var valid_773239 = header.getOrDefault("X-Amz-Credential")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "X-Amz-Credential", valid_773239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773241: Call_ExecuteStatement_773230; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Runs a SQL statement against a database.</p>
  ##         <important>    
  ##             <p>If a call isn't part of a transaction because it doesn't include the
  ##                     <code>transactionID</code> parameter, changes that result from the call are
  ##                 committed automatically.</p>    
  ##         </important>
  ##         <p>The response size limit is 1 MB or 1,000 records. If the call returns more than 1 MB of response data or over 1,000 records, the call is terminated.</p>
  ## 
  let valid = call_773241.validator(path, query, header, formData, body)
  let scheme = call_773241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773241.url(scheme.get, call_773241.host, call_773241.base,
                         call_773241.route, valid.getOrDefault("path"))
  result = hook(call_773241, url, valid)

proc call*(call_773242: Call_ExecuteStatement_773230; body: JsonNode): Recallable =
  ## executeStatement
  ## <p>Runs a SQL statement against a database.</p>
  ##         <important>    
  ##             <p>If a call isn't part of a transaction because it doesn't include the
  ##                     <code>transactionID</code> parameter, changes that result from the call are
  ##                 committed automatically.</p>    
  ##         </important>
  ##         <p>The response size limit is 1 MB or 1,000 records. If the call returns more than 1 MB of response data or over 1,000 records, the call is terminated.</p>
  ##   body: JObject (required)
  var body_773243 = newJObject()
  if body != nil:
    body_773243 = body
  result = call_773242.call(nil, nil, nil, nil, body_773243)

var executeStatement* = Call_ExecuteStatement_773230(name: "executeStatement",
    meth: HttpMethod.HttpPost, host: "rds-data.amazonaws.com", route: "/Execute",
    validator: validate_ExecuteStatement_773231, base: "/",
    url: url_ExecuteStatement_773232, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RollbackTransaction_773244 = ref object of OpenApiRestCall_772597
proc url_RollbackTransaction_773246(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RollbackTransaction_773245(path: JsonNode; query: JsonNode;
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
  var valid_773247 = header.getOrDefault("X-Amz-Date")
  valid_773247 = validateParameter(valid_773247, JString, required = false,
                                 default = nil)
  if valid_773247 != nil:
    section.add "X-Amz-Date", valid_773247
  var valid_773248 = header.getOrDefault("X-Amz-Security-Token")
  valid_773248 = validateParameter(valid_773248, JString, required = false,
                                 default = nil)
  if valid_773248 != nil:
    section.add "X-Amz-Security-Token", valid_773248
  var valid_773249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773249 = validateParameter(valid_773249, JString, required = false,
                                 default = nil)
  if valid_773249 != nil:
    section.add "X-Amz-Content-Sha256", valid_773249
  var valid_773250 = header.getOrDefault("X-Amz-Algorithm")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-Algorithm", valid_773250
  var valid_773251 = header.getOrDefault("X-Amz-Signature")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-Signature", valid_773251
  var valid_773252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773252 = validateParameter(valid_773252, JString, required = false,
                                 default = nil)
  if valid_773252 != nil:
    section.add "X-Amz-SignedHeaders", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-Credential")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Credential", valid_773253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773255: Call_RollbackTransaction_773244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Performs a rollback of a transaction. Rolling back a transaction cancels its changes.
  ## 
  let valid = call_773255.validator(path, query, header, formData, body)
  let scheme = call_773255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773255.url(scheme.get, call_773255.host, call_773255.base,
                         call_773255.route, valid.getOrDefault("path"))
  result = hook(call_773255, url, valid)

proc call*(call_773256: Call_RollbackTransaction_773244; body: JsonNode): Recallable =
  ## rollbackTransaction
  ## Performs a rollback of a transaction. Rolling back a transaction cancels its changes.
  ##   body: JObject (required)
  var body_773257 = newJObject()
  if body != nil:
    body_773257 = body
  result = call_773256.call(nil, nil, nil, nil, body_773257)

var rollbackTransaction* = Call_RollbackTransaction_773244(
    name: "rollbackTransaction", meth: HttpMethod.HttpPost,
    host: "rds-data.amazonaws.com", route: "/RollbackTransaction",
    validator: validate_RollbackTransaction_773245, base: "/",
    url: url_RollbackTransaction_773246, schemes: {Scheme.Https, Scheme.Http})
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
