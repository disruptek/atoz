
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon DynamoDB
## version: 2011-12-05
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Amazon DynamoDB is a fast, highly scalable, highly available, cost-effective non-relational database service.</p> <p>Amazon DynamoDB removes traditional scalability limitations on data storage while maintaining low latency and predictable performance.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/dynamodb/
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "dynamodb.ap-northeast-1.amazonaws.com", "ap-southeast-1": "dynamodb.ap-southeast-1.amazonaws.com",
                           "us-west-2": "dynamodb.us-west-2.amazonaws.com",
                           "eu-west-2": "dynamodb.eu-west-2.amazonaws.com", "ap-northeast-3": "dynamodb.ap-northeast-3.amazonaws.com", "eu-central-1": "dynamodb.eu-central-1.amazonaws.com",
                           "us-east-2": "dynamodb.us-east-2.amazonaws.com",
                           "us-east-1": "dynamodb.us-east-1.amazonaws.com", "cn-northwest-1": "dynamodb.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "dynamodb.ap-south-1.amazonaws.com",
                           "eu-north-1": "dynamodb.eu-north-1.amazonaws.com", "ap-northeast-2": "dynamodb.ap-northeast-2.amazonaws.com",
                           "us-west-1": "dynamodb.us-west-1.amazonaws.com", "us-gov-east-1": "dynamodb.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "dynamodb.eu-west-3.amazonaws.com", "cn-north-1": "dynamodb.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "dynamodb.sa-east-1.amazonaws.com",
                           "eu-west-1": "dynamodb.eu-west-1.amazonaws.com", "us-gov-west-1": "dynamodb.us-gov-west-1.amazonaws.com", "ap-southeast-2": "dynamodb.ap-southeast-2.amazonaws.com", "ca-central-1": "dynamodb.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "dynamodb.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "dynamodb.ap-southeast-1.amazonaws.com",
      "us-west-2": "dynamodb.us-west-2.amazonaws.com",
      "eu-west-2": "dynamodb.eu-west-2.amazonaws.com",
      "ap-northeast-3": "dynamodb.ap-northeast-3.amazonaws.com",
      "eu-central-1": "dynamodb.eu-central-1.amazonaws.com",
      "us-east-2": "dynamodb.us-east-2.amazonaws.com",
      "us-east-1": "dynamodb.us-east-1.amazonaws.com",
      "cn-northwest-1": "dynamodb.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "dynamodb.ap-south-1.amazonaws.com",
      "eu-north-1": "dynamodb.eu-north-1.amazonaws.com",
      "ap-northeast-2": "dynamodb.ap-northeast-2.amazonaws.com",
      "us-west-1": "dynamodb.us-west-1.amazonaws.com",
      "us-gov-east-1": "dynamodb.us-gov-east-1.amazonaws.com",
      "eu-west-3": "dynamodb.eu-west-3.amazonaws.com",
      "cn-north-1": "dynamodb.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "dynamodb.sa-east-1.amazonaws.com",
      "eu-west-1": "dynamodb.eu-west-1.amazonaws.com",
      "us-gov-west-1": "dynamodb.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "dynamodb.ap-southeast-2.amazonaws.com",
      "ca-central-1": "dynamodb.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "dynamodb"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchGetItem_605927 = ref object of OpenApiRestCall_605589
proc url_BatchGetItem_605929(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetItem_605928(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the attributes for multiple items from multiple tables using their primary keys.</p> <p>The maximum number of item attributes that can be retrieved for a single operation is 100. Also, the number of items retrieved is constrained by a 1 MB the size limit. If the response size limit is exceeded or a partial result is returned due to an internal processing failure, Amazon DynamoDB returns an <code>UnprocessedKeys</code> value so you can retry the operation starting with the next item to get.</p> <p>Amazon DynamoDB automatically adjusts the number of items returned per page to enforce this limit. For example, even if you ask to retrieve 100 items, but each individual item is 50k in size, the system returns 20 items and an appropriate <code>UnprocessedKeys</code> value so you can get the next page of results. If necessary, your application needs its own logic to assemble the pages of results into one set.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   RequestItems: JString
  ##               : Pagination token
  section = newJObject()
  var valid_606041 = query.getOrDefault("RequestItems")
  valid_606041 = validateParameter(valid_606041, JString, required = false,
                                 default = nil)
  if valid_606041 != nil:
    section.add "RequestItems", valid_606041
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
  var valid_606055 = header.getOrDefault("X-Amz-Target")
  valid_606055 = validateParameter(valid_606055, JString, required = true, default = newJString(
      "DynamoDB_20111205.BatchGetItem"))
  if valid_606055 != nil:
    section.add "X-Amz-Target", valid_606055
  var valid_606056 = header.getOrDefault("X-Amz-Signature")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Signature", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Content-Sha256", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Date")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Date", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Credential")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Credential", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Security-Token")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Security-Token", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-Algorithm")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Algorithm", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-SignedHeaders", valid_606062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606086: Call_BatchGetItem_605927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the attributes for multiple items from multiple tables using their primary keys.</p> <p>The maximum number of item attributes that can be retrieved for a single operation is 100. Also, the number of items retrieved is constrained by a 1 MB the size limit. If the response size limit is exceeded or a partial result is returned due to an internal processing failure, Amazon DynamoDB returns an <code>UnprocessedKeys</code> value so you can retry the operation starting with the next item to get.</p> <p>Amazon DynamoDB automatically adjusts the number of items returned per page to enforce this limit. For example, even if you ask to retrieve 100 items, but each individual item is 50k in size, the system returns 20 items and an appropriate <code>UnprocessedKeys</code> value so you can get the next page of results. If necessary, your application needs its own logic to assemble the pages of results into one set.</p>
  ## 
  let valid = call_606086.validator(path, query, header, formData, body)
  let scheme = call_606086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606086.url(scheme.get, call_606086.host, call_606086.base,
                         call_606086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606086, url, valid)

proc call*(call_606157: Call_BatchGetItem_605927; body: JsonNode;
          RequestItems: string = ""): Recallable =
  ## batchGetItem
  ## <p>Retrieves the attributes for multiple items from multiple tables using their primary keys.</p> <p>The maximum number of item attributes that can be retrieved for a single operation is 100. Also, the number of items retrieved is constrained by a 1 MB the size limit. If the response size limit is exceeded or a partial result is returned due to an internal processing failure, Amazon DynamoDB returns an <code>UnprocessedKeys</code> value so you can retry the operation starting with the next item to get.</p> <p>Amazon DynamoDB automatically adjusts the number of items returned per page to enforce this limit. For example, even if you ask to retrieve 100 items, but each individual item is 50k in size, the system returns 20 items and an appropriate <code>UnprocessedKeys</code> value so you can get the next page of results. If necessary, your application needs its own logic to assemble the pages of results into one set.</p>
  ##   RequestItems: string
  ##               : Pagination token
  ##   body: JObject (required)
  var query_606158 = newJObject()
  var body_606160 = newJObject()
  add(query_606158, "RequestItems", newJString(RequestItems))
  if body != nil:
    body_606160 = body
  result = call_606157.call(nil, query_606158, nil, nil, body_606160)

var batchGetItem* = Call_BatchGetItem_605927(name: "batchGetItem",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20111205.BatchGetItem",
    validator: validate_BatchGetItem_605928, base: "/", url: url_BatchGetItem_605929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchWriteItem_606199 = ref object of OpenApiRestCall_605589
proc url_BatchWriteItem_606201(protocol: Scheme; host: string; base: string;
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

proc validate_BatchWriteItem_606200(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Allows to execute a batch of Put and/or Delete Requests for many tables in a single call. A total of 25 requests are allowed.</p> <p>There are no transaction guarantees provided by this API. It does not allow conditional puts nor does it support return values.</p>
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
  var valid_606202 = header.getOrDefault("X-Amz-Target")
  valid_606202 = validateParameter(valid_606202, JString, required = true, default = newJString(
      "DynamoDB_20111205.BatchWriteItem"))
  if valid_606202 != nil:
    section.add "X-Amz-Target", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Signature")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Signature", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Content-Sha256", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Date")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Date", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Credential")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Credential", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Security-Token")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Security-Token", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-Algorithm")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Algorithm", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-SignedHeaders", valid_606209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606211: Call_BatchWriteItem_606199; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Allows to execute a batch of Put and/or Delete Requests for many tables in a single call. A total of 25 requests are allowed.</p> <p>There are no transaction guarantees provided by this API. It does not allow conditional puts nor does it support return values.</p>
  ## 
  let valid = call_606211.validator(path, query, header, formData, body)
  let scheme = call_606211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606211.url(scheme.get, call_606211.host, call_606211.base,
                         call_606211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606211, url, valid)

proc call*(call_606212: Call_BatchWriteItem_606199; body: JsonNode): Recallable =
  ## batchWriteItem
  ## <p>Allows to execute a batch of Put and/or Delete Requests for many tables in a single call. A total of 25 requests are allowed.</p> <p>There are no transaction guarantees provided by this API. It does not allow conditional puts nor does it support return values.</p>
  ##   body: JObject (required)
  var body_606213 = newJObject()
  if body != nil:
    body_606213 = body
  result = call_606212.call(nil, nil, nil, nil, body_606213)

var batchWriteItem* = Call_BatchWriteItem_606199(name: "batchWriteItem",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20111205.BatchWriteItem",
    validator: validate_BatchWriteItem_606200, base: "/", url: url_BatchWriteItem_606201,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTable_606214 = ref object of OpenApiRestCall_605589
proc url_CreateTable_606216(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTable_606215(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds a new table to your account.</p> <p>The table name must be unique among those associated with the AWS Account issuing the request, and the AWS Region that receives the request (e.g. <code>us-east-1</code>).</p> <p>The <code>CreateTable</code> operation triggers an asynchronous workflow to begin creating the table. Amazon DynamoDB immediately returns the state of the table (<code>CREATING</code>) until the table is in the <code>ACTIVE</code> state. Once the table is in the <code>ACTIVE</code> state, you can perform data plane operations.</p>
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
  var valid_606217 = header.getOrDefault("X-Amz-Target")
  valid_606217 = validateParameter(valid_606217, JString, required = true, default = newJString(
      "DynamoDB_20111205.CreateTable"))
  if valid_606217 != nil:
    section.add "X-Amz-Target", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Signature")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Signature", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Content-Sha256", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Date")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Date", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-Credential")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-Credential", valid_606221
  var valid_606222 = header.getOrDefault("X-Amz-Security-Token")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-Security-Token", valid_606222
  var valid_606223 = header.getOrDefault("X-Amz-Algorithm")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Algorithm", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-SignedHeaders", valid_606224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606226: Call_CreateTable_606214; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a new table to your account.</p> <p>The table name must be unique among those associated with the AWS Account issuing the request, and the AWS Region that receives the request (e.g. <code>us-east-1</code>).</p> <p>The <code>CreateTable</code> operation triggers an asynchronous workflow to begin creating the table. Amazon DynamoDB immediately returns the state of the table (<code>CREATING</code>) until the table is in the <code>ACTIVE</code> state. Once the table is in the <code>ACTIVE</code> state, you can perform data plane operations.</p>
  ## 
  let valid = call_606226.validator(path, query, header, formData, body)
  let scheme = call_606226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606226.url(scheme.get, call_606226.host, call_606226.base,
                         call_606226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606226, url, valid)

proc call*(call_606227: Call_CreateTable_606214; body: JsonNode): Recallable =
  ## createTable
  ## <p>Adds a new table to your account.</p> <p>The table name must be unique among those associated with the AWS Account issuing the request, and the AWS Region that receives the request (e.g. <code>us-east-1</code>).</p> <p>The <code>CreateTable</code> operation triggers an asynchronous workflow to begin creating the table. Amazon DynamoDB immediately returns the state of the table (<code>CREATING</code>) until the table is in the <code>ACTIVE</code> state. Once the table is in the <code>ACTIVE</code> state, you can perform data plane operations.</p>
  ##   body: JObject (required)
  var body_606228 = newJObject()
  if body != nil:
    body_606228 = body
  result = call_606227.call(nil, nil, nil, nil, body_606228)

var createTable* = Call_CreateTable_606214(name: "createTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.CreateTable",
                                        validator: validate_CreateTable_606215,
                                        base: "/", url: url_CreateTable_606216,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteItem_606229 = ref object of OpenApiRestCall_605589
proc url_DeleteItem_606231(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteItem_606230(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a single item in a table by primary key.</p> <p>You can perform a conditional delete operation that deletes the item if it exists, or if it has an expected attribute value.</p>
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
  var valid_606232 = header.getOrDefault("X-Amz-Target")
  valid_606232 = validateParameter(valid_606232, JString, required = true, default = newJString(
      "DynamoDB_20111205.DeleteItem"))
  if valid_606232 != nil:
    section.add "X-Amz-Target", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Signature")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Signature", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Content-Sha256", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Date")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Date", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-Credential")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-Credential", valid_606236
  var valid_606237 = header.getOrDefault("X-Amz-Security-Token")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "X-Amz-Security-Token", valid_606237
  var valid_606238 = header.getOrDefault("X-Amz-Algorithm")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-Algorithm", valid_606238
  var valid_606239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-SignedHeaders", valid_606239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606241: Call_DeleteItem_606229; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a single item in a table by primary key.</p> <p>You can perform a conditional delete operation that deletes the item if it exists, or if it has an expected attribute value.</p>
  ## 
  let valid = call_606241.validator(path, query, header, formData, body)
  let scheme = call_606241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606241.url(scheme.get, call_606241.host, call_606241.base,
                         call_606241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606241, url, valid)

proc call*(call_606242: Call_DeleteItem_606229; body: JsonNode): Recallable =
  ## deleteItem
  ## <p>Deletes a single item in a table by primary key.</p> <p>You can perform a conditional delete operation that deletes the item if it exists, or if it has an expected attribute value.</p>
  ##   body: JObject (required)
  var body_606243 = newJObject()
  if body != nil:
    body_606243 = body
  result = call_606242.call(nil, nil, nil, nil, body_606243)

var deleteItem* = Call_DeleteItem_606229(name: "deleteItem",
                                      meth: HttpMethod.HttpPost,
                                      host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.DeleteItem",
                                      validator: validate_DeleteItem_606230,
                                      base: "/", url: url_DeleteItem_606231,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTable_606244 = ref object of OpenApiRestCall_605589
proc url_DeleteTable_606246(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTable_606245(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a table and all of its items.</p> <p>If the table is in the <code>ACTIVE</code> state, you can delete it. If a table is in <code>CREATING</code> or <code>UPDATING</code> states then Amazon DynamoDB returns a <code>ResourceInUseException</code>. If the specified table does not exist, Amazon DynamoDB returns a <code>ResourceNotFoundException</code>.</p>
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
  var valid_606247 = header.getOrDefault("X-Amz-Target")
  valid_606247 = validateParameter(valid_606247, JString, required = true, default = newJString(
      "DynamoDB_20111205.DeleteTable"))
  if valid_606247 != nil:
    section.add "X-Amz-Target", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Signature")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Signature", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Content-Sha256", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Date")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Date", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-Credential")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-Credential", valid_606251
  var valid_606252 = header.getOrDefault("X-Amz-Security-Token")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-Security-Token", valid_606252
  var valid_606253 = header.getOrDefault("X-Amz-Algorithm")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "X-Amz-Algorithm", valid_606253
  var valid_606254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606254 = validateParameter(valid_606254, JString, required = false,
                                 default = nil)
  if valid_606254 != nil:
    section.add "X-Amz-SignedHeaders", valid_606254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606256: Call_DeleteTable_606244; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a table and all of its items.</p> <p>If the table is in the <code>ACTIVE</code> state, you can delete it. If a table is in <code>CREATING</code> or <code>UPDATING</code> states then Amazon DynamoDB returns a <code>ResourceInUseException</code>. If the specified table does not exist, Amazon DynamoDB returns a <code>ResourceNotFoundException</code>.</p>
  ## 
  let valid = call_606256.validator(path, query, header, formData, body)
  let scheme = call_606256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606256.url(scheme.get, call_606256.host, call_606256.base,
                         call_606256.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606256, url, valid)

proc call*(call_606257: Call_DeleteTable_606244; body: JsonNode): Recallable =
  ## deleteTable
  ## <p>Deletes a table and all of its items.</p> <p>If the table is in the <code>ACTIVE</code> state, you can delete it. If a table is in <code>CREATING</code> or <code>UPDATING</code> states then Amazon DynamoDB returns a <code>ResourceInUseException</code>. If the specified table does not exist, Amazon DynamoDB returns a <code>ResourceNotFoundException</code>.</p>
  ##   body: JObject (required)
  var body_606258 = newJObject()
  if body != nil:
    body_606258 = body
  result = call_606257.call(nil, nil, nil, nil, body_606258)

var deleteTable* = Call_DeleteTable_606244(name: "deleteTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.DeleteTable",
                                        validator: validate_DeleteTable_606245,
                                        base: "/", url: url_DeleteTable_606246,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTable_606259 = ref object of OpenApiRestCall_605589
proc url_DescribeTable_606261(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTable_606260(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves information about the table, including the current status of the table, the primary key schema and when the table was created.</p> <p>If the table does not exist, Amazon DynamoDB returns a <code>ResourceNotFoundException</code>.</p>
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
  var valid_606262 = header.getOrDefault("X-Amz-Target")
  valid_606262 = validateParameter(valid_606262, JString, required = true, default = newJString(
      "DynamoDB_20111205.DescribeTable"))
  if valid_606262 != nil:
    section.add "X-Amz-Target", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Signature")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Signature", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Content-Sha256", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Date")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Date", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-Credential")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-Credential", valid_606266
  var valid_606267 = header.getOrDefault("X-Amz-Security-Token")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "X-Amz-Security-Token", valid_606267
  var valid_606268 = header.getOrDefault("X-Amz-Algorithm")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-Algorithm", valid_606268
  var valid_606269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606269 = validateParameter(valid_606269, JString, required = false,
                                 default = nil)
  if valid_606269 != nil:
    section.add "X-Amz-SignedHeaders", valid_606269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606271: Call_DescribeTable_606259; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about the table, including the current status of the table, the primary key schema and when the table was created.</p> <p>If the table does not exist, Amazon DynamoDB returns a <code>ResourceNotFoundException</code>.</p>
  ## 
  let valid = call_606271.validator(path, query, header, formData, body)
  let scheme = call_606271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606271.url(scheme.get, call_606271.host, call_606271.base,
                         call_606271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606271, url, valid)

proc call*(call_606272: Call_DescribeTable_606259; body: JsonNode): Recallable =
  ## describeTable
  ## <p>Retrieves information about the table, including the current status of the table, the primary key schema and when the table was created.</p> <p>If the table does not exist, Amazon DynamoDB returns a <code>ResourceNotFoundException</code>.</p>
  ##   body: JObject (required)
  var body_606273 = newJObject()
  if body != nil:
    body_606273 = body
  result = call_606272.call(nil, nil, nil, nil, body_606273)

var describeTable* = Call_DescribeTable_606259(name: "describeTable",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20111205.DescribeTable",
    validator: validate_DescribeTable_606260, base: "/", url: url_DescribeTable_606261,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetItem_606274 = ref object of OpenApiRestCall_605589
proc url_GetItem_606276(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetItem_606275(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves a set of Attributes for an item that matches the primary key.</p> <p>The <code>GetItem</code> operation provides an eventually-consistent read by default. If eventually-consistent reads are not acceptable for your application, use <code>ConsistentRead</code>. Although this operation might take longer than a standard read, it always returns the last updated value.</p>
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
  var valid_606277 = header.getOrDefault("X-Amz-Target")
  valid_606277 = validateParameter(valid_606277, JString, required = true, default = newJString(
      "DynamoDB_20111205.GetItem"))
  if valid_606277 != nil:
    section.add "X-Amz-Target", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Signature")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Signature", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Content-Sha256", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Date")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Date", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-Credential")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-Credential", valid_606281
  var valid_606282 = header.getOrDefault("X-Amz-Security-Token")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "X-Amz-Security-Token", valid_606282
  var valid_606283 = header.getOrDefault("X-Amz-Algorithm")
  valid_606283 = validateParameter(valid_606283, JString, required = false,
                                 default = nil)
  if valid_606283 != nil:
    section.add "X-Amz-Algorithm", valid_606283
  var valid_606284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-SignedHeaders", valid_606284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606286: Call_GetItem_606274; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a set of Attributes for an item that matches the primary key.</p> <p>The <code>GetItem</code> operation provides an eventually-consistent read by default. If eventually-consistent reads are not acceptable for your application, use <code>ConsistentRead</code>. Although this operation might take longer than a standard read, it always returns the last updated value.</p>
  ## 
  let valid = call_606286.validator(path, query, header, formData, body)
  let scheme = call_606286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606286.url(scheme.get, call_606286.host, call_606286.base,
                         call_606286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606286, url, valid)

proc call*(call_606287: Call_GetItem_606274; body: JsonNode): Recallable =
  ## getItem
  ## <p>Retrieves a set of Attributes for an item that matches the primary key.</p> <p>The <code>GetItem</code> operation provides an eventually-consistent read by default. If eventually-consistent reads are not acceptable for your application, use <code>ConsistentRead</code>. Although this operation might take longer than a standard read, it always returns the last updated value.</p>
  ##   body: JObject (required)
  var body_606288 = newJObject()
  if body != nil:
    body_606288 = body
  result = call_606287.call(nil, nil, nil, nil, body_606288)

var getItem* = Call_GetItem_606274(name: "getItem", meth: HttpMethod.HttpPost,
                                host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.GetItem",
                                validator: validate_GetItem_606275, base: "/",
                                url: url_GetItem_606276,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTables_606289 = ref object of OpenApiRestCall_605589
proc url_ListTables_606291(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTables_606290(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a paginated list of table names created by the AWS Account of the caller in the AWS Region (e.g. <code>us-east-1</code>).
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   ExclusiveStartTableName: JString
  ##                          : Pagination token
  section = newJObject()
  var valid_606292 = query.getOrDefault("Limit")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "Limit", valid_606292
  var valid_606293 = query.getOrDefault("ExclusiveStartTableName")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "ExclusiveStartTableName", valid_606293
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
  var valid_606294 = header.getOrDefault("X-Amz-Target")
  valid_606294 = validateParameter(valid_606294, JString, required = true, default = newJString(
      "DynamoDB_20111205.ListTables"))
  if valid_606294 != nil:
    section.add "X-Amz-Target", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Signature")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Signature", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-Content-Sha256", valid_606296
  var valid_606297 = header.getOrDefault("X-Amz-Date")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "X-Amz-Date", valid_606297
  var valid_606298 = header.getOrDefault("X-Amz-Credential")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "X-Amz-Credential", valid_606298
  var valid_606299 = header.getOrDefault("X-Amz-Security-Token")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-Security-Token", valid_606299
  var valid_606300 = header.getOrDefault("X-Amz-Algorithm")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-Algorithm", valid_606300
  var valid_606301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-SignedHeaders", valid_606301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606303: Call_ListTables_606289; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a paginated list of table names created by the AWS Account of the caller in the AWS Region (e.g. <code>us-east-1</code>).
  ## 
  let valid = call_606303.validator(path, query, header, formData, body)
  let scheme = call_606303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606303.url(scheme.get, call_606303.host, call_606303.base,
                         call_606303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606303, url, valid)

proc call*(call_606304: Call_ListTables_606289; body: JsonNode; Limit: string = "";
          ExclusiveStartTableName: string = ""): Recallable =
  ## listTables
  ## Retrieves a paginated list of table names created by the AWS Account of the caller in the AWS Region (e.g. <code>us-east-1</code>).
  ##   Limit: string
  ##        : Pagination limit
  ##   ExclusiveStartTableName: string
  ##                          : Pagination token
  ##   body: JObject (required)
  var query_606305 = newJObject()
  var body_606306 = newJObject()
  add(query_606305, "Limit", newJString(Limit))
  add(query_606305, "ExclusiveStartTableName", newJString(ExclusiveStartTableName))
  if body != nil:
    body_606306 = body
  result = call_606304.call(nil, query_606305, nil, nil, body_606306)

var listTables* = Call_ListTables_606289(name: "listTables",
                                      meth: HttpMethod.HttpPost,
                                      host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.ListTables",
                                      validator: validate_ListTables_606290,
                                      base: "/", url: url_ListTables_606291,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutItem_606307 = ref object of OpenApiRestCall_605589
proc url_PutItem_606309(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutItem_606308(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new item, or replaces an old item with a new item (including all the attributes).</p> <p>If an item already exists in the specified table with the same primary key, the new item completely replaces the existing item. You can perform a conditional put (insert a new item if one with the specified primary key doesn't exist), or replace an existing item if it has certain attribute values.</p>
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
  var valid_606310 = header.getOrDefault("X-Amz-Target")
  valid_606310 = validateParameter(valid_606310, JString, required = true, default = newJString(
      "DynamoDB_20111205.PutItem"))
  if valid_606310 != nil:
    section.add "X-Amz-Target", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-Signature")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-Signature", valid_606311
  var valid_606312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-Content-Sha256", valid_606312
  var valid_606313 = header.getOrDefault("X-Amz-Date")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-Date", valid_606313
  var valid_606314 = header.getOrDefault("X-Amz-Credential")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "X-Amz-Credential", valid_606314
  var valid_606315 = header.getOrDefault("X-Amz-Security-Token")
  valid_606315 = validateParameter(valid_606315, JString, required = false,
                                 default = nil)
  if valid_606315 != nil:
    section.add "X-Amz-Security-Token", valid_606315
  var valid_606316 = header.getOrDefault("X-Amz-Algorithm")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "X-Amz-Algorithm", valid_606316
  var valid_606317 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606317 = validateParameter(valid_606317, JString, required = false,
                                 default = nil)
  if valid_606317 != nil:
    section.add "X-Amz-SignedHeaders", valid_606317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606319: Call_PutItem_606307; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new item, or replaces an old item with a new item (including all the attributes).</p> <p>If an item already exists in the specified table with the same primary key, the new item completely replaces the existing item. You can perform a conditional put (insert a new item if one with the specified primary key doesn't exist), or replace an existing item if it has certain attribute values.</p>
  ## 
  let valid = call_606319.validator(path, query, header, formData, body)
  let scheme = call_606319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606319.url(scheme.get, call_606319.host, call_606319.base,
                         call_606319.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606319, url, valid)

proc call*(call_606320: Call_PutItem_606307; body: JsonNode): Recallable =
  ## putItem
  ## <p>Creates a new item, or replaces an old item with a new item (including all the attributes).</p> <p>If an item already exists in the specified table with the same primary key, the new item completely replaces the existing item. You can perform a conditional put (insert a new item if one with the specified primary key doesn't exist), or replace an existing item if it has certain attribute values.</p>
  ##   body: JObject (required)
  var body_606321 = newJObject()
  if body != nil:
    body_606321 = body
  result = call_606320.call(nil, nil, nil, nil, body_606321)

var putItem* = Call_PutItem_606307(name: "putItem", meth: HttpMethod.HttpPost,
                                host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.PutItem",
                                validator: validate_PutItem_606308, base: "/",
                                url: url_PutItem_606309,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_Query_606322 = ref object of OpenApiRestCall_605589
proc url_Query_606324(protocol: Scheme; host: string; base: string; route: string;
                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Query_606323(path: JsonNode; query: JsonNode; header: JsonNode;
                          formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets the values of one or more items and its attributes by primary key (composite primary key, only).</p> <p>Narrow the scope of the query using comparison operators on the <code>RangeKeyValue</code> of the composite key. Use the <code>ScanIndexForward</code> parameter to get results in forward or reverse order by range key.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   ExclusiveStartKey: JString
  ##                    : Pagination token
  section = newJObject()
  var valid_606325 = query.getOrDefault("Limit")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "Limit", valid_606325
  var valid_606326 = query.getOrDefault("ExclusiveStartKey")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "ExclusiveStartKey", valid_606326
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
  var valid_606327 = header.getOrDefault("X-Amz-Target")
  valid_606327 = validateParameter(valid_606327, JString, required = true, default = newJString(
      "DynamoDB_20111205.Query"))
  if valid_606327 != nil:
    section.add "X-Amz-Target", valid_606327
  var valid_606328 = header.getOrDefault("X-Amz-Signature")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "X-Amz-Signature", valid_606328
  var valid_606329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "X-Amz-Content-Sha256", valid_606329
  var valid_606330 = header.getOrDefault("X-Amz-Date")
  valid_606330 = validateParameter(valid_606330, JString, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "X-Amz-Date", valid_606330
  var valid_606331 = header.getOrDefault("X-Amz-Credential")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = nil)
  if valid_606331 != nil:
    section.add "X-Amz-Credential", valid_606331
  var valid_606332 = header.getOrDefault("X-Amz-Security-Token")
  valid_606332 = validateParameter(valid_606332, JString, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "X-Amz-Security-Token", valid_606332
  var valid_606333 = header.getOrDefault("X-Amz-Algorithm")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "X-Amz-Algorithm", valid_606333
  var valid_606334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606334 = validateParameter(valid_606334, JString, required = false,
                                 default = nil)
  if valid_606334 != nil:
    section.add "X-Amz-SignedHeaders", valid_606334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606336: Call_Query_606322; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the values of one or more items and its attributes by primary key (composite primary key, only).</p> <p>Narrow the scope of the query using comparison operators on the <code>RangeKeyValue</code> of the composite key. Use the <code>ScanIndexForward</code> parameter to get results in forward or reverse order by range key.</p>
  ## 
  let valid = call_606336.validator(path, query, header, formData, body)
  let scheme = call_606336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606336.url(scheme.get, call_606336.host, call_606336.base,
                         call_606336.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606336, url, valid)

proc call*(call_606337: Call_Query_606322; body: JsonNode; Limit: string = "";
          ExclusiveStartKey: string = ""): Recallable =
  ## query
  ## <p>Gets the values of one or more items and its attributes by primary key (composite primary key, only).</p> <p>Narrow the scope of the query using comparison operators on the <code>RangeKeyValue</code> of the composite key. Use the <code>ScanIndexForward</code> parameter to get results in forward or reverse order by range key.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  ##   ExclusiveStartKey: string
  ##                    : Pagination token
  var query_606338 = newJObject()
  var body_606339 = newJObject()
  add(query_606338, "Limit", newJString(Limit))
  if body != nil:
    body_606339 = body
  add(query_606338, "ExclusiveStartKey", newJString(ExclusiveStartKey))
  result = call_606337.call(nil, query_606338, nil, nil, body_606339)

var query* = Call_Query_606322(name: "query", meth: HttpMethod.HttpPost,
                            host: "dynamodb.amazonaws.com",
                            route: "/#X-Amz-Target=DynamoDB_20111205.Query",
                            validator: validate_Query_606323, base: "/",
                            url: url_Query_606324,
                            schemes: {Scheme.Https, Scheme.Http})
type
  Call_Scan_606340 = ref object of OpenApiRestCall_605589
proc url_Scan_606342(protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Scan_606341(path: JsonNode; query: JsonNode; header: JsonNode;
                         formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves one or more items and its attributes by performing a full scan of a table.</p> <p>Provide a <code>ScanFilter</code> to get more specific results.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   ExclusiveStartKey: JString
  ##                    : Pagination token
  section = newJObject()
  var valid_606343 = query.getOrDefault("Limit")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "Limit", valid_606343
  var valid_606344 = query.getOrDefault("ExclusiveStartKey")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "ExclusiveStartKey", valid_606344
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
  var valid_606345 = header.getOrDefault("X-Amz-Target")
  valid_606345 = validateParameter(valid_606345, JString, required = true,
                                 default = newJString("DynamoDB_20111205.Scan"))
  if valid_606345 != nil:
    section.add "X-Amz-Target", valid_606345
  var valid_606346 = header.getOrDefault("X-Amz-Signature")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-Signature", valid_606346
  var valid_606347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-Content-Sha256", valid_606347
  var valid_606348 = header.getOrDefault("X-Amz-Date")
  valid_606348 = validateParameter(valid_606348, JString, required = false,
                                 default = nil)
  if valid_606348 != nil:
    section.add "X-Amz-Date", valid_606348
  var valid_606349 = header.getOrDefault("X-Amz-Credential")
  valid_606349 = validateParameter(valid_606349, JString, required = false,
                                 default = nil)
  if valid_606349 != nil:
    section.add "X-Amz-Credential", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-Security-Token")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Security-Token", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Algorithm")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Algorithm", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-SignedHeaders", valid_606352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606354: Call_Scan_606340; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves one or more items and its attributes by performing a full scan of a table.</p> <p>Provide a <code>ScanFilter</code> to get more specific results.</p>
  ## 
  let valid = call_606354.validator(path, query, header, formData, body)
  let scheme = call_606354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606354.url(scheme.get, call_606354.host, call_606354.base,
                         call_606354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606354, url, valid)

proc call*(call_606355: Call_Scan_606340; body: JsonNode; Limit: string = "";
          ExclusiveStartKey: string = ""): Recallable =
  ## scan
  ## <p>Retrieves one or more items and its attributes by performing a full scan of a table.</p> <p>Provide a <code>ScanFilter</code> to get more specific results.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  ##   ExclusiveStartKey: string
  ##                    : Pagination token
  var query_606356 = newJObject()
  var body_606357 = newJObject()
  add(query_606356, "Limit", newJString(Limit))
  if body != nil:
    body_606357 = body
  add(query_606356, "ExclusiveStartKey", newJString(ExclusiveStartKey))
  result = call_606355.call(nil, query_606356, nil, nil, body_606357)

var scan* = Call_Scan_606340(name: "scan", meth: HttpMethod.HttpPost,
                          host: "dynamodb.amazonaws.com",
                          route: "/#X-Amz-Target=DynamoDB_20111205.Scan",
                          validator: validate_Scan_606341, base: "/", url: url_Scan_606342,
                          schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateItem_606358 = ref object of OpenApiRestCall_605589
proc url_UpdateItem_606360(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateItem_606359(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Edits an existing item's attributes.</p> <p>You can perform a conditional update (insert a new attribute name-value pair if it doesn't exist, or replace an existing name-value pair if it has certain expected attribute values).</p>
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
  var valid_606361 = header.getOrDefault("X-Amz-Target")
  valid_606361 = validateParameter(valid_606361, JString, required = true, default = newJString(
      "DynamoDB_20111205.UpdateItem"))
  if valid_606361 != nil:
    section.add "X-Amz-Target", valid_606361
  var valid_606362 = header.getOrDefault("X-Amz-Signature")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "X-Amz-Signature", valid_606362
  var valid_606363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "X-Amz-Content-Sha256", valid_606363
  var valid_606364 = header.getOrDefault("X-Amz-Date")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-Date", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Credential")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Credential", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Security-Token")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Security-Token", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Algorithm")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Algorithm", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-SignedHeaders", valid_606368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606370: Call_UpdateItem_606358; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Edits an existing item's attributes.</p> <p>You can perform a conditional update (insert a new attribute name-value pair if it doesn't exist, or replace an existing name-value pair if it has certain expected attribute values).</p>
  ## 
  let valid = call_606370.validator(path, query, header, formData, body)
  let scheme = call_606370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606370.url(scheme.get, call_606370.host, call_606370.base,
                         call_606370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606370, url, valid)

proc call*(call_606371: Call_UpdateItem_606358; body: JsonNode): Recallable =
  ## updateItem
  ## <p>Edits an existing item's attributes.</p> <p>You can perform a conditional update (insert a new attribute name-value pair if it doesn't exist, or replace an existing name-value pair if it has certain expected attribute values).</p>
  ##   body: JObject (required)
  var body_606372 = newJObject()
  if body != nil:
    body_606372 = body
  result = call_606371.call(nil, nil, nil, nil, body_606372)

var updateItem* = Call_UpdateItem_606358(name: "updateItem",
                                      meth: HttpMethod.HttpPost,
                                      host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.UpdateItem",
                                      validator: validate_UpdateItem_606359,
                                      base: "/", url: url_UpdateItem_606360,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTable_606373 = ref object of OpenApiRestCall_605589
proc url_UpdateTable_606375(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTable_606374(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the provisioned throughput for the given table.</p> <p>Setting the throughput for a table helps you manage performance and is part of the Provisioned Throughput feature of Amazon DynamoDB.</p>
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
  var valid_606376 = header.getOrDefault("X-Amz-Target")
  valid_606376 = validateParameter(valid_606376, JString, required = true, default = newJString(
      "DynamoDB_20111205.UpdateTable"))
  if valid_606376 != nil:
    section.add "X-Amz-Target", valid_606376
  var valid_606377 = header.getOrDefault("X-Amz-Signature")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-Signature", valid_606377
  var valid_606378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-Content-Sha256", valid_606378
  var valid_606379 = header.getOrDefault("X-Amz-Date")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-Date", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Credential")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Credential", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Security-Token")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Security-Token", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Algorithm")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Algorithm", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-SignedHeaders", valid_606383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606385: Call_UpdateTable_606373; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the provisioned throughput for the given table.</p> <p>Setting the throughput for a table helps you manage performance and is part of the Provisioned Throughput feature of Amazon DynamoDB.</p>
  ## 
  let valid = call_606385.validator(path, query, header, formData, body)
  let scheme = call_606385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606385.url(scheme.get, call_606385.host, call_606385.base,
                         call_606385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606385, url, valid)

proc call*(call_606386: Call_UpdateTable_606373; body: JsonNode): Recallable =
  ## updateTable
  ## <p>Updates the provisioned throughput for the given table.</p> <p>Setting the throughput for a table helps you manage performance and is part of the Provisioned Throughput feature of Amazon DynamoDB.</p>
  ##   body: JObject (required)
  var body_606387 = newJObject()
  if body != nil:
    body_606387 = body
  result = call_606386.call(nil, nil, nil, nil, body_606387)

var updateTable* = Call_UpdateTable_606373(name: "updateTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.UpdateTable",
                                        validator: validate_UpdateTable_606374,
                                        base: "/", url: url_UpdateTable_606375,
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
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
