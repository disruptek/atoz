
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_BatchGetItem_600768 = ref object of OpenApiRestCall_600426
proc url_BatchGetItem_600770(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchGetItem_600769(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600882 = query.getOrDefault("RequestItems")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "RequestItems", valid_600882
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
  var valid_600883 = header.getOrDefault("X-Amz-Date")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Date", valid_600883
  var valid_600884 = header.getOrDefault("X-Amz-Security-Token")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "X-Amz-Security-Token", valid_600884
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600898 = header.getOrDefault("X-Amz-Target")
  valid_600898 = validateParameter(valid_600898, JString, required = true, default = newJString(
      "DynamoDB_20111205.BatchGetItem"))
  if valid_600898 != nil:
    section.add "X-Amz-Target", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Content-Sha256", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Algorithm")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Algorithm", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-Signature")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-Signature", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-SignedHeaders", valid_600902
  var valid_600903 = header.getOrDefault("X-Amz-Credential")
  valid_600903 = validateParameter(valid_600903, JString, required = false,
                                 default = nil)
  if valid_600903 != nil:
    section.add "X-Amz-Credential", valid_600903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600927: Call_BatchGetItem_600768; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the attributes for multiple items from multiple tables using their primary keys.</p> <p>The maximum number of item attributes that can be retrieved for a single operation is 100. Also, the number of items retrieved is constrained by a 1 MB the size limit. If the response size limit is exceeded or a partial result is returned due to an internal processing failure, Amazon DynamoDB returns an <code>UnprocessedKeys</code> value so you can retry the operation starting with the next item to get.</p> <p>Amazon DynamoDB automatically adjusts the number of items returned per page to enforce this limit. For example, even if you ask to retrieve 100 items, but each individual item is 50k in size, the system returns 20 items and an appropriate <code>UnprocessedKeys</code> value so you can get the next page of results. If necessary, your application needs its own logic to assemble the pages of results into one set.</p>
  ## 
  let valid = call_600927.validator(path, query, header, formData, body)
  let scheme = call_600927.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600927.url(scheme.get, call_600927.host, call_600927.base,
                         call_600927.route, valid.getOrDefault("path"))
  result = hook(call_600927, url, valid)

proc call*(call_600998: Call_BatchGetItem_600768; body: JsonNode;
          RequestItems: string = ""): Recallable =
  ## batchGetItem
  ## <p>Retrieves the attributes for multiple items from multiple tables using their primary keys.</p> <p>The maximum number of item attributes that can be retrieved for a single operation is 100. Also, the number of items retrieved is constrained by a 1 MB the size limit. If the response size limit is exceeded or a partial result is returned due to an internal processing failure, Amazon DynamoDB returns an <code>UnprocessedKeys</code> value so you can retry the operation starting with the next item to get.</p> <p>Amazon DynamoDB automatically adjusts the number of items returned per page to enforce this limit. For example, even if you ask to retrieve 100 items, but each individual item is 50k in size, the system returns 20 items and an appropriate <code>UnprocessedKeys</code> value so you can get the next page of results. If necessary, your application needs its own logic to assemble the pages of results into one set.</p>
  ##   RequestItems: string
  ##               : Pagination token
  ##   body: JObject (required)
  var query_600999 = newJObject()
  var body_601001 = newJObject()
  add(query_600999, "RequestItems", newJString(RequestItems))
  if body != nil:
    body_601001 = body
  result = call_600998.call(nil, query_600999, nil, nil, body_601001)

var batchGetItem* = Call_BatchGetItem_600768(name: "batchGetItem",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20111205.BatchGetItem",
    validator: validate_BatchGetItem_600769, base: "/", url: url_BatchGetItem_600770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchWriteItem_601040 = ref object of OpenApiRestCall_600426
proc url_BatchWriteItem_601042(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchWriteItem_601041(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601043 = header.getOrDefault("X-Amz-Date")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Date", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Security-Token")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Security-Token", valid_601044
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601045 = header.getOrDefault("X-Amz-Target")
  valid_601045 = validateParameter(valid_601045, JString, required = true, default = newJString(
      "DynamoDB_20111205.BatchWriteItem"))
  if valid_601045 != nil:
    section.add "X-Amz-Target", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Content-Sha256", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Algorithm")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Algorithm", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Signature")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Signature", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-SignedHeaders", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Credential")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Credential", valid_601050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601052: Call_BatchWriteItem_601040; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Allows to execute a batch of Put and/or Delete Requests for many tables in a single call. A total of 25 requests are allowed.</p> <p>There are no transaction guarantees provided by this API. It does not allow conditional puts nor does it support return values.</p>
  ## 
  let valid = call_601052.validator(path, query, header, formData, body)
  let scheme = call_601052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601052.url(scheme.get, call_601052.host, call_601052.base,
                         call_601052.route, valid.getOrDefault("path"))
  result = hook(call_601052, url, valid)

proc call*(call_601053: Call_BatchWriteItem_601040; body: JsonNode): Recallable =
  ## batchWriteItem
  ## <p>Allows to execute a batch of Put and/or Delete Requests for many tables in a single call. A total of 25 requests are allowed.</p> <p>There are no transaction guarantees provided by this API. It does not allow conditional puts nor does it support return values.</p>
  ##   body: JObject (required)
  var body_601054 = newJObject()
  if body != nil:
    body_601054 = body
  result = call_601053.call(nil, nil, nil, nil, body_601054)

var batchWriteItem* = Call_BatchWriteItem_601040(name: "batchWriteItem",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20111205.BatchWriteItem",
    validator: validate_BatchWriteItem_601041, base: "/", url: url_BatchWriteItem_601042,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTable_601055 = ref object of OpenApiRestCall_600426
proc url_CreateTable_601057(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateTable_601056(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601058 = header.getOrDefault("X-Amz-Date")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Date", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Security-Token")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Security-Token", valid_601059
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601060 = header.getOrDefault("X-Amz-Target")
  valid_601060 = validateParameter(valid_601060, JString, required = true, default = newJString(
      "DynamoDB_20111205.CreateTable"))
  if valid_601060 != nil:
    section.add "X-Amz-Target", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Content-Sha256", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Algorithm")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Algorithm", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-Signature")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-Signature", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-SignedHeaders", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-Credential")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Credential", valid_601065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601067: Call_CreateTable_601055; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a new table to your account.</p> <p>The table name must be unique among those associated with the AWS Account issuing the request, and the AWS Region that receives the request (e.g. <code>us-east-1</code>).</p> <p>The <code>CreateTable</code> operation triggers an asynchronous workflow to begin creating the table. Amazon DynamoDB immediately returns the state of the table (<code>CREATING</code>) until the table is in the <code>ACTIVE</code> state. Once the table is in the <code>ACTIVE</code> state, you can perform data plane operations.</p>
  ## 
  let valid = call_601067.validator(path, query, header, formData, body)
  let scheme = call_601067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601067.url(scheme.get, call_601067.host, call_601067.base,
                         call_601067.route, valid.getOrDefault("path"))
  result = hook(call_601067, url, valid)

proc call*(call_601068: Call_CreateTable_601055; body: JsonNode): Recallable =
  ## createTable
  ## <p>Adds a new table to your account.</p> <p>The table name must be unique among those associated with the AWS Account issuing the request, and the AWS Region that receives the request (e.g. <code>us-east-1</code>).</p> <p>The <code>CreateTable</code> operation triggers an asynchronous workflow to begin creating the table. Amazon DynamoDB immediately returns the state of the table (<code>CREATING</code>) until the table is in the <code>ACTIVE</code> state. Once the table is in the <code>ACTIVE</code> state, you can perform data plane operations.</p>
  ##   body: JObject (required)
  var body_601069 = newJObject()
  if body != nil:
    body_601069 = body
  result = call_601068.call(nil, nil, nil, nil, body_601069)

var createTable* = Call_CreateTable_601055(name: "createTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.CreateTable",
                                        validator: validate_CreateTable_601056,
                                        base: "/", url: url_CreateTable_601057,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteItem_601070 = ref object of OpenApiRestCall_600426
proc url_DeleteItem_601072(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteItem_601071(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601073 = header.getOrDefault("X-Amz-Date")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Date", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Security-Token")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Security-Token", valid_601074
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601075 = header.getOrDefault("X-Amz-Target")
  valid_601075 = validateParameter(valid_601075, JString, required = true, default = newJString(
      "DynamoDB_20111205.DeleteItem"))
  if valid_601075 != nil:
    section.add "X-Amz-Target", valid_601075
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

proc call*(call_601082: Call_DeleteItem_601070; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a single item in a table by primary key.</p> <p>You can perform a conditional delete operation that deletes the item if it exists, or if it has an expected attribute value.</p>
  ## 
  let valid = call_601082.validator(path, query, header, formData, body)
  let scheme = call_601082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601082.url(scheme.get, call_601082.host, call_601082.base,
                         call_601082.route, valid.getOrDefault("path"))
  result = hook(call_601082, url, valid)

proc call*(call_601083: Call_DeleteItem_601070; body: JsonNode): Recallable =
  ## deleteItem
  ## <p>Deletes a single item in a table by primary key.</p> <p>You can perform a conditional delete operation that deletes the item if it exists, or if it has an expected attribute value.</p>
  ##   body: JObject (required)
  var body_601084 = newJObject()
  if body != nil:
    body_601084 = body
  result = call_601083.call(nil, nil, nil, nil, body_601084)

var deleteItem* = Call_DeleteItem_601070(name: "deleteItem",
                                      meth: HttpMethod.HttpPost,
                                      host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.DeleteItem",
                                      validator: validate_DeleteItem_601071,
                                      base: "/", url: url_DeleteItem_601072,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTable_601085 = ref object of OpenApiRestCall_600426
proc url_DeleteTable_601087(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteTable_601086(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601090 = header.getOrDefault("X-Amz-Target")
  valid_601090 = validateParameter(valid_601090, JString, required = true, default = newJString(
      "DynamoDB_20111205.DeleteTable"))
  if valid_601090 != nil:
    section.add "X-Amz-Target", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Content-Sha256", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Algorithm")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Algorithm", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-Signature")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Signature", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-SignedHeaders", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-Credential")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Credential", valid_601095
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601097: Call_DeleteTable_601085; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a table and all of its items.</p> <p>If the table is in the <code>ACTIVE</code> state, you can delete it. If a table is in <code>CREATING</code> or <code>UPDATING</code> states then Amazon DynamoDB returns a <code>ResourceInUseException</code>. If the specified table does not exist, Amazon DynamoDB returns a <code>ResourceNotFoundException</code>.</p>
  ## 
  let valid = call_601097.validator(path, query, header, formData, body)
  let scheme = call_601097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601097.url(scheme.get, call_601097.host, call_601097.base,
                         call_601097.route, valid.getOrDefault("path"))
  result = hook(call_601097, url, valid)

proc call*(call_601098: Call_DeleteTable_601085; body: JsonNode): Recallable =
  ## deleteTable
  ## <p>Deletes a table and all of its items.</p> <p>If the table is in the <code>ACTIVE</code> state, you can delete it. If a table is in <code>CREATING</code> or <code>UPDATING</code> states then Amazon DynamoDB returns a <code>ResourceInUseException</code>. If the specified table does not exist, Amazon DynamoDB returns a <code>ResourceNotFoundException</code>.</p>
  ##   body: JObject (required)
  var body_601099 = newJObject()
  if body != nil:
    body_601099 = body
  result = call_601098.call(nil, nil, nil, nil, body_601099)

var deleteTable* = Call_DeleteTable_601085(name: "deleteTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.DeleteTable",
                                        validator: validate_DeleteTable_601086,
                                        base: "/", url: url_DeleteTable_601087,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTable_601100 = ref object of OpenApiRestCall_600426
proc url_DescribeTable_601102(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeTable_601101(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601103 = header.getOrDefault("X-Amz-Date")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Date", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Security-Token")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Security-Token", valid_601104
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601105 = header.getOrDefault("X-Amz-Target")
  valid_601105 = validateParameter(valid_601105, JString, required = true, default = newJString(
      "DynamoDB_20111205.DescribeTable"))
  if valid_601105 != nil:
    section.add "X-Amz-Target", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Content-Sha256", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Algorithm")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Algorithm", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-Signature")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Signature", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-SignedHeaders", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Credential")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Credential", valid_601110
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601112: Call_DescribeTable_601100; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about the table, including the current status of the table, the primary key schema and when the table was created.</p> <p>If the table does not exist, Amazon DynamoDB returns a <code>ResourceNotFoundException</code>.</p>
  ## 
  let valid = call_601112.validator(path, query, header, formData, body)
  let scheme = call_601112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601112.url(scheme.get, call_601112.host, call_601112.base,
                         call_601112.route, valid.getOrDefault("path"))
  result = hook(call_601112, url, valid)

proc call*(call_601113: Call_DescribeTable_601100; body: JsonNode): Recallable =
  ## describeTable
  ## <p>Retrieves information about the table, including the current status of the table, the primary key schema and when the table was created.</p> <p>If the table does not exist, Amazon DynamoDB returns a <code>ResourceNotFoundException</code>.</p>
  ##   body: JObject (required)
  var body_601114 = newJObject()
  if body != nil:
    body_601114 = body
  result = call_601113.call(nil, nil, nil, nil, body_601114)

var describeTable* = Call_DescribeTable_601100(name: "describeTable",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20111205.DescribeTable",
    validator: validate_DescribeTable_601101, base: "/", url: url_DescribeTable_601102,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetItem_601115 = ref object of OpenApiRestCall_600426
proc url_GetItem_601117(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetItem_601116(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601118 = header.getOrDefault("X-Amz-Date")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Date", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Security-Token")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Security-Token", valid_601119
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601120 = header.getOrDefault("X-Amz-Target")
  valid_601120 = validateParameter(valid_601120, JString, required = true, default = newJString(
      "DynamoDB_20111205.GetItem"))
  if valid_601120 != nil:
    section.add "X-Amz-Target", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Content-Sha256", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Algorithm")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Algorithm", valid_601122
  var valid_601123 = header.getOrDefault("X-Amz-Signature")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "X-Amz-Signature", valid_601123
  var valid_601124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-SignedHeaders", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-Credential")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Credential", valid_601125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601127: Call_GetItem_601115; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a set of Attributes for an item that matches the primary key.</p> <p>The <code>GetItem</code> operation provides an eventually-consistent read by default. If eventually-consistent reads are not acceptable for your application, use <code>ConsistentRead</code>. Although this operation might take longer than a standard read, it always returns the last updated value.</p>
  ## 
  let valid = call_601127.validator(path, query, header, formData, body)
  let scheme = call_601127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601127.url(scheme.get, call_601127.host, call_601127.base,
                         call_601127.route, valid.getOrDefault("path"))
  result = hook(call_601127, url, valid)

proc call*(call_601128: Call_GetItem_601115; body: JsonNode): Recallable =
  ## getItem
  ## <p>Retrieves a set of Attributes for an item that matches the primary key.</p> <p>The <code>GetItem</code> operation provides an eventually-consistent read by default. If eventually-consistent reads are not acceptable for your application, use <code>ConsistentRead</code>. Although this operation might take longer than a standard read, it always returns the last updated value.</p>
  ##   body: JObject (required)
  var body_601129 = newJObject()
  if body != nil:
    body_601129 = body
  result = call_601128.call(nil, nil, nil, nil, body_601129)

var getItem* = Call_GetItem_601115(name: "getItem", meth: HttpMethod.HttpPost,
                                host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.GetItem",
                                validator: validate_GetItem_601116, base: "/",
                                url: url_GetItem_601117,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTables_601130 = ref object of OpenApiRestCall_600426
proc url_ListTables_601132(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTables_601131(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601133 = query.getOrDefault("Limit")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "Limit", valid_601133
  var valid_601134 = query.getOrDefault("ExclusiveStartTableName")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "ExclusiveStartTableName", valid_601134
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
  var valid_601135 = header.getOrDefault("X-Amz-Date")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Date", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-Security-Token")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Security-Token", valid_601136
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601137 = header.getOrDefault("X-Amz-Target")
  valid_601137 = validateParameter(valid_601137, JString, required = true, default = newJString(
      "DynamoDB_20111205.ListTables"))
  if valid_601137 != nil:
    section.add "X-Amz-Target", valid_601137
  var valid_601138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "X-Amz-Content-Sha256", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Algorithm")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Algorithm", valid_601139
  var valid_601140 = header.getOrDefault("X-Amz-Signature")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Signature", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-SignedHeaders", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-Credential")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-Credential", valid_601142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601144: Call_ListTables_601130; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a paginated list of table names created by the AWS Account of the caller in the AWS Region (e.g. <code>us-east-1</code>).
  ## 
  let valid = call_601144.validator(path, query, header, formData, body)
  let scheme = call_601144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601144.url(scheme.get, call_601144.host, call_601144.base,
                         call_601144.route, valid.getOrDefault("path"))
  result = hook(call_601144, url, valid)

proc call*(call_601145: Call_ListTables_601130; body: JsonNode; Limit: string = "";
          ExclusiveStartTableName: string = ""): Recallable =
  ## listTables
  ## Retrieves a paginated list of table names created by the AWS Account of the caller in the AWS Region (e.g. <code>us-east-1</code>).
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  ##   ExclusiveStartTableName: string
  ##                          : Pagination token
  var query_601146 = newJObject()
  var body_601147 = newJObject()
  add(query_601146, "Limit", newJString(Limit))
  if body != nil:
    body_601147 = body
  add(query_601146, "ExclusiveStartTableName", newJString(ExclusiveStartTableName))
  result = call_601145.call(nil, query_601146, nil, nil, body_601147)

var listTables* = Call_ListTables_601130(name: "listTables",
                                      meth: HttpMethod.HttpPost,
                                      host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.ListTables",
                                      validator: validate_ListTables_601131,
                                      base: "/", url: url_ListTables_601132,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutItem_601148 = ref object of OpenApiRestCall_600426
proc url_PutItem_601150(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutItem_601149(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601151 = header.getOrDefault("X-Amz-Date")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Date", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Security-Token")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Security-Token", valid_601152
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601153 = header.getOrDefault("X-Amz-Target")
  valid_601153 = validateParameter(valid_601153, JString, required = true, default = newJString(
      "DynamoDB_20111205.PutItem"))
  if valid_601153 != nil:
    section.add "X-Amz-Target", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Content-Sha256", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-Algorithm")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-Algorithm", valid_601155
  var valid_601156 = header.getOrDefault("X-Amz-Signature")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-Signature", valid_601156
  var valid_601157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-SignedHeaders", valid_601157
  var valid_601158 = header.getOrDefault("X-Amz-Credential")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-Credential", valid_601158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601160: Call_PutItem_601148; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new item, or replaces an old item with a new item (including all the attributes).</p> <p>If an item already exists in the specified table with the same primary key, the new item completely replaces the existing item. You can perform a conditional put (insert a new item if one with the specified primary key doesn't exist), or replace an existing item if it has certain attribute values.</p>
  ## 
  let valid = call_601160.validator(path, query, header, formData, body)
  let scheme = call_601160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601160.url(scheme.get, call_601160.host, call_601160.base,
                         call_601160.route, valid.getOrDefault("path"))
  result = hook(call_601160, url, valid)

proc call*(call_601161: Call_PutItem_601148; body: JsonNode): Recallable =
  ## putItem
  ## <p>Creates a new item, or replaces an old item with a new item (including all the attributes).</p> <p>If an item already exists in the specified table with the same primary key, the new item completely replaces the existing item. You can perform a conditional put (insert a new item if one with the specified primary key doesn't exist), or replace an existing item if it has certain attribute values.</p>
  ##   body: JObject (required)
  var body_601162 = newJObject()
  if body != nil:
    body_601162 = body
  result = call_601161.call(nil, nil, nil, nil, body_601162)

var putItem* = Call_PutItem_601148(name: "putItem", meth: HttpMethod.HttpPost,
                                host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.PutItem",
                                validator: validate_PutItem_601149, base: "/",
                                url: url_PutItem_601150,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_Query_601163 = ref object of OpenApiRestCall_600426
proc url_Query_601165(protocol: Scheme; host: string; base: string; route: string;
                     path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_Query_601164(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601166 = query.getOrDefault("Limit")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "Limit", valid_601166
  var valid_601167 = query.getOrDefault("ExclusiveStartKey")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "ExclusiveStartKey", valid_601167
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
  var valid_601168 = header.getOrDefault("X-Amz-Date")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Date", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Security-Token")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Security-Token", valid_601169
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601170 = header.getOrDefault("X-Amz-Target")
  valid_601170 = validateParameter(valid_601170, JString, required = true, default = newJString(
      "DynamoDB_20111205.Query"))
  if valid_601170 != nil:
    section.add "X-Amz-Target", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Content-Sha256", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-Algorithm")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-Algorithm", valid_601172
  var valid_601173 = header.getOrDefault("X-Amz-Signature")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "X-Amz-Signature", valid_601173
  var valid_601174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601174 = validateParameter(valid_601174, JString, required = false,
                                 default = nil)
  if valid_601174 != nil:
    section.add "X-Amz-SignedHeaders", valid_601174
  var valid_601175 = header.getOrDefault("X-Amz-Credential")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "X-Amz-Credential", valid_601175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601177: Call_Query_601163; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the values of one or more items and its attributes by primary key (composite primary key, only).</p> <p>Narrow the scope of the query using comparison operators on the <code>RangeKeyValue</code> of the composite key. Use the <code>ScanIndexForward</code> parameter to get results in forward or reverse order by range key.</p>
  ## 
  let valid = call_601177.validator(path, query, header, formData, body)
  let scheme = call_601177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601177.url(scheme.get, call_601177.host, call_601177.base,
                         call_601177.route, valid.getOrDefault("path"))
  result = hook(call_601177, url, valid)

proc call*(call_601178: Call_Query_601163; body: JsonNode; Limit: string = "";
          ExclusiveStartKey: string = ""): Recallable =
  ## query
  ## <p>Gets the values of one or more items and its attributes by primary key (composite primary key, only).</p> <p>Narrow the scope of the query using comparison operators on the <code>RangeKeyValue</code> of the composite key. Use the <code>ScanIndexForward</code> parameter to get results in forward or reverse order by range key.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  ##   ExclusiveStartKey: string
  ##                    : Pagination token
  var query_601179 = newJObject()
  var body_601180 = newJObject()
  add(query_601179, "Limit", newJString(Limit))
  if body != nil:
    body_601180 = body
  add(query_601179, "ExclusiveStartKey", newJString(ExclusiveStartKey))
  result = call_601178.call(nil, query_601179, nil, nil, body_601180)

var query* = Call_Query_601163(name: "query", meth: HttpMethod.HttpPost,
                            host: "dynamodb.amazonaws.com",
                            route: "/#X-Amz-Target=DynamoDB_20111205.Query",
                            validator: validate_Query_601164, base: "/",
                            url: url_Query_601165,
                            schemes: {Scheme.Https, Scheme.Http})
type
  Call_Scan_601181 = ref object of OpenApiRestCall_600426
proc url_Scan_601183(protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_Scan_601182(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601184 = query.getOrDefault("Limit")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "Limit", valid_601184
  var valid_601185 = query.getOrDefault("ExclusiveStartKey")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "ExclusiveStartKey", valid_601185
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
  var valid_601186 = header.getOrDefault("X-Amz-Date")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Date", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-Security-Token")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-Security-Token", valid_601187
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601188 = header.getOrDefault("X-Amz-Target")
  valid_601188 = validateParameter(valid_601188, JString, required = true,
                                 default = newJString("DynamoDB_20111205.Scan"))
  if valid_601188 != nil:
    section.add "X-Amz-Target", valid_601188
  var valid_601189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601189 = validateParameter(valid_601189, JString, required = false,
                                 default = nil)
  if valid_601189 != nil:
    section.add "X-Amz-Content-Sha256", valid_601189
  var valid_601190 = header.getOrDefault("X-Amz-Algorithm")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-Algorithm", valid_601190
  var valid_601191 = header.getOrDefault("X-Amz-Signature")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-Signature", valid_601191
  var valid_601192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601192 = validateParameter(valid_601192, JString, required = false,
                                 default = nil)
  if valid_601192 != nil:
    section.add "X-Amz-SignedHeaders", valid_601192
  var valid_601193 = header.getOrDefault("X-Amz-Credential")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Credential", valid_601193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601195: Call_Scan_601181; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves one or more items and its attributes by performing a full scan of a table.</p> <p>Provide a <code>ScanFilter</code> to get more specific results.</p>
  ## 
  let valid = call_601195.validator(path, query, header, formData, body)
  let scheme = call_601195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601195.url(scheme.get, call_601195.host, call_601195.base,
                         call_601195.route, valid.getOrDefault("path"))
  result = hook(call_601195, url, valid)

proc call*(call_601196: Call_Scan_601181; body: JsonNode; Limit: string = "";
          ExclusiveStartKey: string = ""): Recallable =
  ## scan
  ## <p>Retrieves one or more items and its attributes by performing a full scan of a table.</p> <p>Provide a <code>ScanFilter</code> to get more specific results.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  ##   ExclusiveStartKey: string
  ##                    : Pagination token
  var query_601197 = newJObject()
  var body_601198 = newJObject()
  add(query_601197, "Limit", newJString(Limit))
  if body != nil:
    body_601198 = body
  add(query_601197, "ExclusiveStartKey", newJString(ExclusiveStartKey))
  result = call_601196.call(nil, query_601197, nil, nil, body_601198)

var scan* = Call_Scan_601181(name: "scan", meth: HttpMethod.HttpPost,
                          host: "dynamodb.amazonaws.com",
                          route: "/#X-Amz-Target=DynamoDB_20111205.Scan",
                          validator: validate_Scan_601182, base: "/", url: url_Scan_601183,
                          schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateItem_601199 = ref object of OpenApiRestCall_600426
proc url_UpdateItem_601201(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateItem_601200(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601202 = header.getOrDefault("X-Amz-Date")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-Date", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-Security-Token")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Security-Token", valid_601203
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601204 = header.getOrDefault("X-Amz-Target")
  valid_601204 = validateParameter(valid_601204, JString, required = true, default = newJString(
      "DynamoDB_20111205.UpdateItem"))
  if valid_601204 != nil:
    section.add "X-Amz-Target", valid_601204
  var valid_601205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-Content-Sha256", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-Algorithm")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Algorithm", valid_601206
  var valid_601207 = header.getOrDefault("X-Amz-Signature")
  valid_601207 = validateParameter(valid_601207, JString, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "X-Amz-Signature", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-SignedHeaders", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-Credential")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Credential", valid_601209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601211: Call_UpdateItem_601199; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Edits an existing item's attributes.</p> <p>You can perform a conditional update (insert a new attribute name-value pair if it doesn't exist, or replace an existing name-value pair if it has certain expected attribute values).</p>
  ## 
  let valid = call_601211.validator(path, query, header, formData, body)
  let scheme = call_601211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601211.url(scheme.get, call_601211.host, call_601211.base,
                         call_601211.route, valid.getOrDefault("path"))
  result = hook(call_601211, url, valid)

proc call*(call_601212: Call_UpdateItem_601199; body: JsonNode): Recallable =
  ## updateItem
  ## <p>Edits an existing item's attributes.</p> <p>You can perform a conditional update (insert a new attribute name-value pair if it doesn't exist, or replace an existing name-value pair if it has certain expected attribute values).</p>
  ##   body: JObject (required)
  var body_601213 = newJObject()
  if body != nil:
    body_601213 = body
  result = call_601212.call(nil, nil, nil, nil, body_601213)

var updateItem* = Call_UpdateItem_601199(name: "updateItem",
                                      meth: HttpMethod.HttpPost,
                                      host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.UpdateItem",
                                      validator: validate_UpdateItem_601200,
                                      base: "/", url: url_UpdateItem_601201,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTable_601214 = ref object of OpenApiRestCall_600426
proc url_UpdateTable_601216(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateTable_601215(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601217 = header.getOrDefault("X-Amz-Date")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-Date", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-Security-Token")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Security-Token", valid_601218
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601219 = header.getOrDefault("X-Amz-Target")
  valid_601219 = validateParameter(valid_601219, JString, required = true, default = newJString(
      "DynamoDB_20111205.UpdateTable"))
  if valid_601219 != nil:
    section.add "X-Amz-Target", valid_601219
  var valid_601220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Content-Sha256", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-Algorithm")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-Algorithm", valid_601221
  var valid_601222 = header.getOrDefault("X-Amz-Signature")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "X-Amz-Signature", valid_601222
  var valid_601223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "X-Amz-SignedHeaders", valid_601223
  var valid_601224 = header.getOrDefault("X-Amz-Credential")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-Credential", valid_601224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601226: Call_UpdateTable_601214; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the provisioned throughput for the given table.</p> <p>Setting the throughput for a table helps you manage performance and is part of the Provisioned Throughput feature of Amazon DynamoDB.</p>
  ## 
  let valid = call_601226.validator(path, query, header, formData, body)
  let scheme = call_601226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601226.url(scheme.get, call_601226.host, call_601226.base,
                         call_601226.route, valid.getOrDefault("path"))
  result = hook(call_601226, url, valid)

proc call*(call_601227: Call_UpdateTable_601214; body: JsonNode): Recallable =
  ## updateTable
  ## <p>Updates the provisioned throughput for the given table.</p> <p>Setting the throughput for a table helps you manage performance and is part of the Provisioned Throughput feature of Amazon DynamoDB.</p>
  ##   body: JObject (required)
  var body_601228 = newJObject()
  if body != nil:
    body_601228 = body
  result = call_601227.call(nil, nil, nil, nil, body_601228)

var updateTable* = Call_UpdateTable_601214(name: "updateTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.UpdateTable",
                                        validator: validate_UpdateTable_601215,
                                        base: "/", url: url_UpdateTable_601216,
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
