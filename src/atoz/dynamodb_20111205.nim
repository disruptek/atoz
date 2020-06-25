
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_BatchGetItem_21625779 = ref object of OpenApiRestCall_21625435
proc url_BatchGetItem_21625781(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetItem_21625780(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21625882 = query.getOrDefault("RequestItems")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "RequestItems", valid_21625882
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
  var valid_21625883 = header.getOrDefault("X-Amz-Date")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "X-Amz-Date", valid_21625883
  var valid_21625884 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625884 = validateParameter(valid_21625884, JString, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "X-Amz-Security-Token", valid_21625884
  var valid_21625899 = header.getOrDefault("X-Amz-Target")
  valid_21625899 = validateParameter(valid_21625899, JString, required = true, default = newJString(
      "DynamoDB_20111205.BatchGetItem"))
  if valid_21625899 != nil:
    section.add "X-Amz-Target", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Algorithm", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-Signature")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-Signature", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625903
  var valid_21625904 = header.getOrDefault("X-Amz-Credential")
  valid_21625904 = validateParameter(valid_21625904, JString, required = false,
                                   default = nil)
  if valid_21625904 != nil:
    section.add "X-Amz-Credential", valid_21625904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21625930: Call_BatchGetItem_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the attributes for multiple items from multiple tables using their primary keys.</p> <p>The maximum number of item attributes that can be retrieved for a single operation is 100. Also, the number of items retrieved is constrained by a 1 MB the size limit. If the response size limit is exceeded or a partial result is returned due to an internal processing failure, Amazon DynamoDB returns an <code>UnprocessedKeys</code> value so you can retry the operation starting with the next item to get.</p> <p>Amazon DynamoDB automatically adjusts the number of items returned per page to enforce this limit. For example, even if you ask to retrieve 100 items, but each individual item is 50k in size, the system returns 20 items and an appropriate <code>UnprocessedKeys</code> value so you can get the next page of results. If necessary, your application needs its own logic to assemble the pages of results into one set.</p>
  ## 
  let valid = call_21625930.validator(path, query, header, formData, body, _)
  let scheme = call_21625930.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625930.makeUrl(scheme.get, call_21625930.host, call_21625930.base,
                               call_21625930.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625930, uri, valid, _)

proc call*(call_21625993: Call_BatchGetItem_21625779; body: JsonNode;
          RequestItems: string = ""): Recallable =
  ## batchGetItem
  ## <p>Retrieves the attributes for multiple items from multiple tables using their primary keys.</p> <p>The maximum number of item attributes that can be retrieved for a single operation is 100. Also, the number of items retrieved is constrained by a 1 MB the size limit. If the response size limit is exceeded or a partial result is returned due to an internal processing failure, Amazon DynamoDB returns an <code>UnprocessedKeys</code> value so you can retry the operation starting with the next item to get.</p> <p>Amazon DynamoDB automatically adjusts the number of items returned per page to enforce this limit. For example, even if you ask to retrieve 100 items, but each individual item is 50k in size, the system returns 20 items and an appropriate <code>UnprocessedKeys</code> value so you can get the next page of results. If necessary, your application needs its own logic to assemble the pages of results into one set.</p>
  ##   RequestItems: string
  ##               : Pagination token
  ##   body: JObject (required)
  var query_21625995 = newJObject()
  var body_21625997 = newJObject()
  add(query_21625995, "RequestItems", newJString(RequestItems))
  if body != nil:
    body_21625997 = body
  result = call_21625993.call(nil, query_21625995, nil, nil, body_21625997)

var batchGetItem* = Call_BatchGetItem_21625779(name: "batchGetItem",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20111205.BatchGetItem",
    validator: validate_BatchGetItem_21625780, base: "/", makeUrl: url_BatchGetItem_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchWriteItem_21626035 = ref object of OpenApiRestCall_21625435
proc url_BatchWriteItem_21626037(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchWriteItem_21626036(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Allows to execute a batch of Put and/or Delete Requests for many tables in a single call. A total of 25 requests are allowed.</p> <p>There are no transaction guarantees provided by this API. It does not allow conditional puts nor does it support return values.</p>
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
  var valid_21626038 = header.getOrDefault("X-Amz-Date")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Date", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Security-Token", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Target")
  valid_21626040 = validateParameter(valid_21626040, JString, required = true, default = newJString(
      "DynamoDB_20111205.BatchWriteItem"))
  if valid_21626040 != nil:
    section.add "X-Amz-Target", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-Algorithm", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-Signature")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-Signature", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626044
  var valid_21626045 = header.getOrDefault("X-Amz-Credential")
  valid_21626045 = validateParameter(valid_21626045, JString, required = false,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "X-Amz-Credential", valid_21626045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626047: Call_BatchWriteItem_21626035; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Allows to execute a batch of Put and/or Delete Requests for many tables in a single call. A total of 25 requests are allowed.</p> <p>There are no transaction guarantees provided by this API. It does not allow conditional puts nor does it support return values.</p>
  ## 
  let valid = call_21626047.validator(path, query, header, formData, body, _)
  let scheme = call_21626047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626047.makeUrl(scheme.get, call_21626047.host, call_21626047.base,
                               call_21626047.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626047, uri, valid, _)

proc call*(call_21626048: Call_BatchWriteItem_21626035; body: JsonNode): Recallable =
  ## batchWriteItem
  ## <p>Allows to execute a batch of Put and/or Delete Requests for many tables in a single call. A total of 25 requests are allowed.</p> <p>There are no transaction guarantees provided by this API. It does not allow conditional puts nor does it support return values.</p>
  ##   body: JObject (required)
  var body_21626049 = newJObject()
  if body != nil:
    body_21626049 = body
  result = call_21626048.call(nil, nil, nil, nil, body_21626049)

var batchWriteItem* = Call_BatchWriteItem_21626035(name: "batchWriteItem",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20111205.BatchWriteItem",
    validator: validate_BatchWriteItem_21626036, base: "/",
    makeUrl: url_BatchWriteItem_21626037, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTable_21626050 = ref object of OpenApiRestCall_21625435
proc url_CreateTable_21626052(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTable_21626051(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Adds a new table to your account.</p> <p>The table name must be unique among those associated with the AWS Account issuing the request, and the AWS Region that receives the request (e.g. <code>us-east-1</code>).</p> <p>The <code>CreateTable</code> operation triggers an asynchronous workflow to begin creating the table. Amazon DynamoDB immediately returns the state of the table (<code>CREATING</code>) until the table is in the <code>ACTIVE</code> state. Once the table is in the <code>ACTIVE</code> state, you can perform data plane operations.</p>
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
  var valid_21626053 = header.getOrDefault("X-Amz-Date")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-Date", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Security-Token", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-Target")
  valid_21626055 = validateParameter(valid_21626055, JString, required = true, default = newJString(
      "DynamoDB_20111205.CreateTable"))
  if valid_21626055 != nil:
    section.add "X-Amz-Target", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Algorithm", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-Signature")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-Signature", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626059
  var valid_21626060 = header.getOrDefault("X-Amz-Credential")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-Credential", valid_21626060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626062: Call_CreateTable_21626050; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds a new table to your account.</p> <p>The table name must be unique among those associated with the AWS Account issuing the request, and the AWS Region that receives the request (e.g. <code>us-east-1</code>).</p> <p>The <code>CreateTable</code> operation triggers an asynchronous workflow to begin creating the table. Amazon DynamoDB immediately returns the state of the table (<code>CREATING</code>) until the table is in the <code>ACTIVE</code> state. Once the table is in the <code>ACTIVE</code> state, you can perform data plane operations.</p>
  ## 
  let valid = call_21626062.validator(path, query, header, formData, body, _)
  let scheme = call_21626062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626062.makeUrl(scheme.get, call_21626062.host, call_21626062.base,
                               call_21626062.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626062, uri, valid, _)

proc call*(call_21626063: Call_CreateTable_21626050; body: JsonNode): Recallable =
  ## createTable
  ## <p>Adds a new table to your account.</p> <p>The table name must be unique among those associated with the AWS Account issuing the request, and the AWS Region that receives the request (e.g. <code>us-east-1</code>).</p> <p>The <code>CreateTable</code> operation triggers an asynchronous workflow to begin creating the table. Amazon DynamoDB immediately returns the state of the table (<code>CREATING</code>) until the table is in the <code>ACTIVE</code> state. Once the table is in the <code>ACTIVE</code> state, you can perform data plane operations.</p>
  ##   body: JObject (required)
  var body_21626064 = newJObject()
  if body != nil:
    body_21626064 = body
  result = call_21626063.call(nil, nil, nil, nil, body_21626064)

var createTable* = Call_CreateTable_21626050(name: "createTable",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20111205.CreateTable",
    validator: validate_CreateTable_21626051, base: "/", makeUrl: url_CreateTable_21626052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteItem_21626065 = ref object of OpenApiRestCall_21625435
proc url_DeleteItem_21626067(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteItem_21626066(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes a single item in a table by primary key.</p> <p>You can perform a conditional delete operation that deletes the item if it exists, or if it has an expected attribute value.</p>
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
  var valid_21626068 = header.getOrDefault("X-Amz-Date")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-Date", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Security-Token", valid_21626069
  var valid_21626070 = header.getOrDefault("X-Amz-Target")
  valid_21626070 = validateParameter(valid_21626070, JString, required = true, default = newJString(
      "DynamoDB_20111205.DeleteItem"))
  if valid_21626070 != nil:
    section.add "X-Amz-Target", valid_21626070
  var valid_21626071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626071
  var valid_21626072 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-Algorithm", valid_21626072
  var valid_21626073 = header.getOrDefault("X-Amz-Signature")
  valid_21626073 = validateParameter(valid_21626073, JString, required = false,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "X-Amz-Signature", valid_21626073
  var valid_21626074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626074 = validateParameter(valid_21626074, JString, required = false,
                                   default = nil)
  if valid_21626074 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626074
  var valid_21626075 = header.getOrDefault("X-Amz-Credential")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-Credential", valid_21626075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626077: Call_DeleteItem_21626065; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a single item in a table by primary key.</p> <p>You can perform a conditional delete operation that deletes the item if it exists, or if it has an expected attribute value.</p>
  ## 
  let valid = call_21626077.validator(path, query, header, formData, body, _)
  let scheme = call_21626077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626077.makeUrl(scheme.get, call_21626077.host, call_21626077.base,
                               call_21626077.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626077, uri, valid, _)

proc call*(call_21626078: Call_DeleteItem_21626065; body: JsonNode): Recallable =
  ## deleteItem
  ## <p>Deletes a single item in a table by primary key.</p> <p>You can perform a conditional delete operation that deletes the item if it exists, or if it has an expected attribute value.</p>
  ##   body: JObject (required)
  var body_21626079 = newJObject()
  if body != nil:
    body_21626079 = body
  result = call_21626078.call(nil, nil, nil, nil, body_21626079)

var deleteItem* = Call_DeleteItem_21626065(name: "deleteItem",
                                        meth: HttpMethod.HttpPost,
                                        host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.DeleteItem",
                                        validator: validate_DeleteItem_21626066,
                                        base: "/", makeUrl: url_DeleteItem_21626067,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTable_21626080 = ref object of OpenApiRestCall_21625435
proc url_DeleteTable_21626082(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTable_21626081(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes a table and all of its items.</p> <p>If the table is in the <code>ACTIVE</code> state, you can delete it. If a table is in <code>CREATING</code> or <code>UPDATING</code> states then Amazon DynamoDB returns a <code>ResourceInUseException</code>. If the specified table does not exist, Amazon DynamoDB returns a <code>ResourceNotFoundException</code>.</p>
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
  var valid_21626083 = header.getOrDefault("X-Amz-Date")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-Date", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Security-Token", valid_21626084
  var valid_21626085 = header.getOrDefault("X-Amz-Target")
  valid_21626085 = validateParameter(valid_21626085, JString, required = true, default = newJString(
      "DynamoDB_20111205.DeleteTable"))
  if valid_21626085 != nil:
    section.add "X-Amz-Target", valid_21626085
  var valid_21626086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-Algorithm", valid_21626087
  var valid_21626088 = header.getOrDefault("X-Amz-Signature")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "X-Amz-Signature", valid_21626088
  var valid_21626089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626089
  var valid_21626090 = header.getOrDefault("X-Amz-Credential")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "X-Amz-Credential", valid_21626090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626092: Call_DeleteTable_21626080; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a table and all of its items.</p> <p>If the table is in the <code>ACTIVE</code> state, you can delete it. If a table is in <code>CREATING</code> or <code>UPDATING</code> states then Amazon DynamoDB returns a <code>ResourceInUseException</code>. If the specified table does not exist, Amazon DynamoDB returns a <code>ResourceNotFoundException</code>.</p>
  ## 
  let valid = call_21626092.validator(path, query, header, formData, body, _)
  let scheme = call_21626092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626092.makeUrl(scheme.get, call_21626092.host, call_21626092.base,
                               call_21626092.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626092, uri, valid, _)

proc call*(call_21626093: Call_DeleteTable_21626080; body: JsonNode): Recallable =
  ## deleteTable
  ## <p>Deletes a table and all of its items.</p> <p>If the table is in the <code>ACTIVE</code> state, you can delete it. If a table is in <code>CREATING</code> or <code>UPDATING</code> states then Amazon DynamoDB returns a <code>ResourceInUseException</code>. If the specified table does not exist, Amazon DynamoDB returns a <code>ResourceNotFoundException</code>.</p>
  ##   body: JObject (required)
  var body_21626094 = newJObject()
  if body != nil:
    body_21626094 = body
  result = call_21626093.call(nil, nil, nil, nil, body_21626094)

var deleteTable* = Call_DeleteTable_21626080(name: "deleteTable",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20111205.DeleteTable",
    validator: validate_DeleteTable_21626081, base: "/", makeUrl: url_DeleteTable_21626082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTable_21626095 = ref object of OpenApiRestCall_21625435
proc url_DescribeTable_21626097(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTable_21626096(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Retrieves information about the table, including the current status of the table, the primary key schema and when the table was created.</p> <p>If the table does not exist, Amazon DynamoDB returns a <code>ResourceNotFoundException</code>.</p>
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
  var valid_21626098 = header.getOrDefault("X-Amz-Date")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-Date", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Security-Token", valid_21626099
  var valid_21626100 = header.getOrDefault("X-Amz-Target")
  valid_21626100 = validateParameter(valid_21626100, JString, required = true, default = newJString(
      "DynamoDB_20111205.DescribeTable"))
  if valid_21626100 != nil:
    section.add "X-Amz-Target", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Algorithm", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-Signature")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-Signature", valid_21626103
  var valid_21626104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626104
  var valid_21626105 = header.getOrDefault("X-Amz-Credential")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-Credential", valid_21626105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626107: Call_DescribeTable_21626095; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves information about the table, including the current status of the table, the primary key schema and when the table was created.</p> <p>If the table does not exist, Amazon DynamoDB returns a <code>ResourceNotFoundException</code>.</p>
  ## 
  let valid = call_21626107.validator(path, query, header, formData, body, _)
  let scheme = call_21626107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626107.makeUrl(scheme.get, call_21626107.host, call_21626107.base,
                               call_21626107.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626107, uri, valid, _)

proc call*(call_21626108: Call_DescribeTable_21626095; body: JsonNode): Recallable =
  ## describeTable
  ## <p>Retrieves information about the table, including the current status of the table, the primary key schema and when the table was created.</p> <p>If the table does not exist, Amazon DynamoDB returns a <code>ResourceNotFoundException</code>.</p>
  ##   body: JObject (required)
  var body_21626109 = newJObject()
  if body != nil:
    body_21626109 = body
  result = call_21626108.call(nil, nil, nil, nil, body_21626109)

var describeTable* = Call_DescribeTable_21626095(name: "describeTable",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20111205.DescribeTable",
    validator: validate_DescribeTable_21626096, base: "/",
    makeUrl: url_DescribeTable_21626097, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetItem_21626110 = ref object of OpenApiRestCall_21625435
proc url_GetItem_21626112(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetItem_21626111(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Retrieves a set of Attributes for an item that matches the primary key.</p> <p>The <code>GetItem</code> operation provides an eventually-consistent read by default. If eventually-consistent reads are not acceptable for your application, use <code>ConsistentRead</code>. Although this operation might take longer than a standard read, it always returns the last updated value.</p>
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
  var valid_21626113 = header.getOrDefault("X-Amz-Date")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-Date", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Security-Token", valid_21626114
  var valid_21626115 = header.getOrDefault("X-Amz-Target")
  valid_21626115 = validateParameter(valid_21626115, JString, required = true, default = newJString(
      "DynamoDB_20111205.GetItem"))
  if valid_21626115 != nil:
    section.add "X-Amz-Target", valid_21626115
  var valid_21626116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626116
  var valid_21626117 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "X-Amz-Algorithm", valid_21626117
  var valid_21626118 = header.getOrDefault("X-Amz-Signature")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-Signature", valid_21626118
  var valid_21626119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626119
  var valid_21626120 = header.getOrDefault("X-Amz-Credential")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-Credential", valid_21626120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626122: Call_GetItem_21626110; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves a set of Attributes for an item that matches the primary key.</p> <p>The <code>GetItem</code> operation provides an eventually-consistent read by default. If eventually-consistent reads are not acceptable for your application, use <code>ConsistentRead</code>. Although this operation might take longer than a standard read, it always returns the last updated value.</p>
  ## 
  let valid = call_21626122.validator(path, query, header, formData, body, _)
  let scheme = call_21626122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626122.makeUrl(scheme.get, call_21626122.host, call_21626122.base,
                               call_21626122.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626122, uri, valid, _)

proc call*(call_21626123: Call_GetItem_21626110; body: JsonNode): Recallable =
  ## getItem
  ## <p>Retrieves a set of Attributes for an item that matches the primary key.</p> <p>The <code>GetItem</code> operation provides an eventually-consistent read by default. If eventually-consistent reads are not acceptable for your application, use <code>ConsistentRead</code>. Although this operation might take longer than a standard read, it always returns the last updated value.</p>
  ##   body: JObject (required)
  var body_21626124 = newJObject()
  if body != nil:
    body_21626124 = body
  result = call_21626123.call(nil, nil, nil, nil, body_21626124)

var getItem* = Call_GetItem_21626110(name: "getItem", meth: HttpMethod.HttpPost,
                                  host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.GetItem",
                                  validator: validate_GetItem_21626111, base: "/",
                                  makeUrl: url_GetItem_21626112,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTables_21626125 = ref object of OpenApiRestCall_21625435
proc url_ListTables_21626127(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTables_21626126(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626128 = query.getOrDefault("Limit")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "Limit", valid_21626128
  var valid_21626129 = query.getOrDefault("ExclusiveStartTableName")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "ExclusiveStartTableName", valid_21626129
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
  var valid_21626130 = header.getOrDefault("X-Amz-Date")
  valid_21626130 = validateParameter(valid_21626130, JString, required = false,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "X-Amz-Date", valid_21626130
  var valid_21626131 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626131 = validateParameter(valid_21626131, JString, required = false,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "X-Amz-Security-Token", valid_21626131
  var valid_21626132 = header.getOrDefault("X-Amz-Target")
  valid_21626132 = validateParameter(valid_21626132, JString, required = true, default = newJString(
      "DynamoDB_20111205.ListTables"))
  if valid_21626132 != nil:
    section.add "X-Amz-Target", valid_21626132
  var valid_21626133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626133
  var valid_21626134 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "X-Amz-Algorithm", valid_21626134
  var valid_21626135 = header.getOrDefault("X-Amz-Signature")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-Signature", valid_21626135
  var valid_21626136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626136
  var valid_21626137 = header.getOrDefault("X-Amz-Credential")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Credential", valid_21626137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626139: Call_ListTables_21626125; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a paginated list of table names created by the AWS Account of the caller in the AWS Region (e.g. <code>us-east-1</code>).
  ## 
  let valid = call_21626139.validator(path, query, header, formData, body, _)
  let scheme = call_21626139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626139.makeUrl(scheme.get, call_21626139.host, call_21626139.base,
                               call_21626139.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626139, uri, valid, _)

proc call*(call_21626140: Call_ListTables_21626125; body: JsonNode;
          Limit: string = ""; ExclusiveStartTableName: string = ""): Recallable =
  ## listTables
  ## Retrieves a paginated list of table names created by the AWS Account of the caller in the AWS Region (e.g. <code>us-east-1</code>).
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  ##   ExclusiveStartTableName: string
  ##                          : Pagination token
  var query_21626141 = newJObject()
  var body_21626142 = newJObject()
  add(query_21626141, "Limit", newJString(Limit))
  if body != nil:
    body_21626142 = body
  add(query_21626141, "ExclusiveStartTableName",
      newJString(ExclusiveStartTableName))
  result = call_21626140.call(nil, query_21626141, nil, nil, body_21626142)

var listTables* = Call_ListTables_21626125(name: "listTables",
                                        meth: HttpMethod.HttpPost,
                                        host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.ListTables",
                                        validator: validate_ListTables_21626126,
                                        base: "/", makeUrl: url_ListTables_21626127,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutItem_21626143 = ref object of OpenApiRestCall_21625435
proc url_PutItem_21626145(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutItem_21626144(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a new item, or replaces an old item with a new item (including all the attributes).</p> <p>If an item already exists in the specified table with the same primary key, the new item completely replaces the existing item. You can perform a conditional put (insert a new item if one with the specified primary key doesn't exist), or replace an existing item if it has certain attribute values.</p>
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
  var valid_21626146 = header.getOrDefault("X-Amz-Date")
  valid_21626146 = validateParameter(valid_21626146, JString, required = false,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "X-Amz-Date", valid_21626146
  var valid_21626147 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626147 = validateParameter(valid_21626147, JString, required = false,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "X-Amz-Security-Token", valid_21626147
  var valid_21626148 = header.getOrDefault("X-Amz-Target")
  valid_21626148 = validateParameter(valid_21626148, JString, required = true, default = newJString(
      "DynamoDB_20111205.PutItem"))
  if valid_21626148 != nil:
    section.add "X-Amz-Target", valid_21626148
  var valid_21626149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626149 = validateParameter(valid_21626149, JString, required = false,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626149
  var valid_21626150 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "X-Amz-Algorithm", valid_21626150
  var valid_21626151 = header.getOrDefault("X-Amz-Signature")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "X-Amz-Signature", valid_21626151
  var valid_21626152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Credential")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Credential", valid_21626153
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626155: Call_PutItem_21626143; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new item, or replaces an old item with a new item (including all the attributes).</p> <p>If an item already exists in the specified table with the same primary key, the new item completely replaces the existing item. You can perform a conditional put (insert a new item if one with the specified primary key doesn't exist), or replace an existing item if it has certain attribute values.</p>
  ## 
  let valid = call_21626155.validator(path, query, header, formData, body, _)
  let scheme = call_21626155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626155.makeUrl(scheme.get, call_21626155.host, call_21626155.base,
                               call_21626155.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626155, uri, valid, _)

proc call*(call_21626156: Call_PutItem_21626143; body: JsonNode): Recallable =
  ## putItem
  ## <p>Creates a new item, or replaces an old item with a new item (including all the attributes).</p> <p>If an item already exists in the specified table with the same primary key, the new item completely replaces the existing item. You can perform a conditional put (insert a new item if one with the specified primary key doesn't exist), or replace an existing item if it has certain attribute values.</p>
  ##   body: JObject (required)
  var body_21626157 = newJObject()
  if body != nil:
    body_21626157 = body
  result = call_21626156.call(nil, nil, nil, nil, body_21626157)

var putItem* = Call_PutItem_21626143(name: "putItem", meth: HttpMethod.HttpPost,
                                  host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.PutItem",
                                  validator: validate_PutItem_21626144, base: "/",
                                  makeUrl: url_PutItem_21626145,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_Query_21626158 = ref object of OpenApiRestCall_21625435
proc url_Query_21626160(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Query_21626159(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626161 = query.getOrDefault("Limit")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "Limit", valid_21626161
  var valid_21626162 = query.getOrDefault("ExclusiveStartKey")
  valid_21626162 = validateParameter(valid_21626162, JString, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "ExclusiveStartKey", valid_21626162
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
  var valid_21626163 = header.getOrDefault("X-Amz-Date")
  valid_21626163 = validateParameter(valid_21626163, JString, required = false,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "X-Amz-Date", valid_21626163
  var valid_21626164 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626164 = validateParameter(valid_21626164, JString, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "X-Amz-Security-Token", valid_21626164
  var valid_21626165 = header.getOrDefault("X-Amz-Target")
  valid_21626165 = validateParameter(valid_21626165, JString, required = true, default = newJString(
      "DynamoDB_20111205.Query"))
  if valid_21626165 != nil:
    section.add "X-Amz-Target", valid_21626165
  var valid_21626166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626166
  var valid_21626167 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Algorithm", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Signature")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Signature", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Credential")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Credential", valid_21626170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626172: Call_Query_21626158; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets the values of one or more items and its attributes by primary key (composite primary key, only).</p> <p>Narrow the scope of the query using comparison operators on the <code>RangeKeyValue</code> of the composite key. Use the <code>ScanIndexForward</code> parameter to get results in forward or reverse order by range key.</p>
  ## 
  let valid = call_21626172.validator(path, query, header, formData, body, _)
  let scheme = call_21626172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626172.makeUrl(scheme.get, call_21626172.host, call_21626172.base,
                               call_21626172.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626172, uri, valid, _)

proc call*(call_21626173: Call_Query_21626158; body: JsonNode; Limit: string = "";
          ExclusiveStartKey: string = ""): Recallable =
  ## query
  ## <p>Gets the values of one or more items and its attributes by primary key (composite primary key, only).</p> <p>Narrow the scope of the query using comparison operators on the <code>RangeKeyValue</code> of the composite key. Use the <code>ScanIndexForward</code> parameter to get results in forward or reverse order by range key.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  ##   ExclusiveStartKey: string
  ##                    : Pagination token
  var query_21626174 = newJObject()
  var body_21626175 = newJObject()
  add(query_21626174, "Limit", newJString(Limit))
  if body != nil:
    body_21626175 = body
  add(query_21626174, "ExclusiveStartKey", newJString(ExclusiveStartKey))
  result = call_21626173.call(nil, query_21626174, nil, nil, body_21626175)

var query* = Call_Query_21626158(name: "query", meth: HttpMethod.HttpPost,
                              host: "dynamodb.amazonaws.com",
                              route: "/#X-Amz-Target=DynamoDB_20111205.Query",
                              validator: validate_Query_21626159, base: "/",
                              makeUrl: url_Query_21626160,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_Scan_21626176 = ref object of OpenApiRestCall_21625435
proc url_Scan_21626178(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Scan_21626177(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626179 = query.getOrDefault("Limit")
  valid_21626179 = validateParameter(valid_21626179, JString, required = false,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "Limit", valid_21626179
  var valid_21626180 = query.getOrDefault("ExclusiveStartKey")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "ExclusiveStartKey", valid_21626180
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
  var valid_21626181 = header.getOrDefault("X-Amz-Date")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-Date", valid_21626181
  var valid_21626182 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Security-Token", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Target")
  valid_21626183 = validateParameter(valid_21626183, JString, required = true, default = newJString(
      "DynamoDB_20111205.Scan"))
  if valid_21626183 != nil:
    section.add "X-Amz-Target", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Algorithm", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Signature")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Signature", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-Credential")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-Credential", valid_21626188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626190: Call_Scan_21626176; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves one or more items and its attributes by performing a full scan of a table.</p> <p>Provide a <code>ScanFilter</code> to get more specific results.</p>
  ## 
  let valid = call_21626190.validator(path, query, header, formData, body, _)
  let scheme = call_21626190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626190.makeUrl(scheme.get, call_21626190.host, call_21626190.base,
                               call_21626190.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626190, uri, valid, _)

proc call*(call_21626191: Call_Scan_21626176; body: JsonNode; Limit: string = "";
          ExclusiveStartKey: string = ""): Recallable =
  ## scan
  ## <p>Retrieves one or more items and its attributes by performing a full scan of a table.</p> <p>Provide a <code>ScanFilter</code> to get more specific results.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  ##   ExclusiveStartKey: string
  ##                    : Pagination token
  var query_21626192 = newJObject()
  var body_21626193 = newJObject()
  add(query_21626192, "Limit", newJString(Limit))
  if body != nil:
    body_21626193 = body
  add(query_21626192, "ExclusiveStartKey", newJString(ExclusiveStartKey))
  result = call_21626191.call(nil, query_21626192, nil, nil, body_21626193)

var scan* = Call_Scan_21626176(name: "scan", meth: HttpMethod.HttpPost,
                            host: "dynamodb.amazonaws.com",
                            route: "/#X-Amz-Target=DynamoDB_20111205.Scan",
                            validator: validate_Scan_21626177, base: "/",
                            makeUrl: url_Scan_21626178,
                            schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateItem_21626194 = ref object of OpenApiRestCall_21625435
proc url_UpdateItem_21626196(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateItem_21626195(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Edits an existing item's attributes.</p> <p>You can perform a conditional update (insert a new attribute name-value pair if it doesn't exist, or replace an existing name-value pair if it has certain expected attribute values).</p>
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
  var valid_21626197 = header.getOrDefault("X-Amz-Date")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Date", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Security-Token", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Target")
  valid_21626199 = validateParameter(valid_21626199, JString, required = true, default = newJString(
      "DynamoDB_20111205.UpdateItem"))
  if valid_21626199 != nil:
    section.add "X-Amz-Target", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Algorithm", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Signature")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Signature", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Credential")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Credential", valid_21626204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626206: Call_UpdateItem_21626194; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Edits an existing item's attributes.</p> <p>You can perform a conditional update (insert a new attribute name-value pair if it doesn't exist, or replace an existing name-value pair if it has certain expected attribute values).</p>
  ## 
  let valid = call_21626206.validator(path, query, header, formData, body, _)
  let scheme = call_21626206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626206.makeUrl(scheme.get, call_21626206.host, call_21626206.base,
                               call_21626206.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626206, uri, valid, _)

proc call*(call_21626207: Call_UpdateItem_21626194; body: JsonNode): Recallable =
  ## updateItem
  ## <p>Edits an existing item's attributes.</p> <p>You can perform a conditional update (insert a new attribute name-value pair if it doesn't exist, or replace an existing name-value pair if it has certain expected attribute values).</p>
  ##   body: JObject (required)
  var body_21626208 = newJObject()
  if body != nil:
    body_21626208 = body
  result = call_21626207.call(nil, nil, nil, nil, body_21626208)

var updateItem* = Call_UpdateItem_21626194(name: "updateItem",
                                        meth: HttpMethod.HttpPost,
                                        host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.UpdateItem",
                                        validator: validate_UpdateItem_21626195,
                                        base: "/", makeUrl: url_UpdateItem_21626196,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTable_21626209 = ref object of OpenApiRestCall_21625435
proc url_UpdateTable_21626211(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTable_21626210(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates the provisioned throughput for the given table.</p> <p>Setting the throughput for a table helps you manage performance and is part of the Provisioned Throughput feature of Amazon DynamoDB.</p>
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
  var valid_21626212 = header.getOrDefault("X-Amz-Date")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Date", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Security-Token", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Target")
  valid_21626214 = validateParameter(valid_21626214, JString, required = true, default = newJString(
      "DynamoDB_20111205.UpdateTable"))
  if valid_21626214 != nil:
    section.add "X-Amz-Target", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Algorithm", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Signature")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Signature", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Credential")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Credential", valid_21626219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626221: Call_UpdateTable_21626209; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the provisioned throughput for the given table.</p> <p>Setting the throughput for a table helps you manage performance and is part of the Provisioned Throughput feature of Amazon DynamoDB.</p>
  ## 
  let valid = call_21626221.validator(path, query, header, formData, body, _)
  let scheme = call_21626221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626221.makeUrl(scheme.get, call_21626221.host, call_21626221.base,
                               call_21626221.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626221, uri, valid, _)

proc call*(call_21626222: Call_UpdateTable_21626209; body: JsonNode): Recallable =
  ## updateTable
  ## <p>Updates the provisioned throughput for the given table.</p> <p>Setting the throughput for a table helps you manage performance and is part of the Provisioned Throughput feature of Amazon DynamoDB.</p>
  ##   body: JObject (required)
  var body_21626223 = newJObject()
  if body != nil:
    body_21626223 = body
  result = call_21626222.call(nil, nil, nil, nil, body_21626223)

var updateTable* = Call_UpdateTable_21626209(name: "updateTable",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20111205.UpdateTable",
    validator: validate_UpdateTable_21626210, base: "/", makeUrl: url_UpdateTable_21626211,
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}