
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchGetItem_592703 = ref object of OpenApiRestCall_592364
proc url_BatchGetItem_592705(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetItem_592704(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592817 = query.getOrDefault("RequestItems")
  valid_592817 = validateParameter(valid_592817, JString, required = false,
                                 default = nil)
  if valid_592817 != nil:
    section.add "RequestItems", valid_592817
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
  var valid_592831 = header.getOrDefault("X-Amz-Target")
  valid_592831 = validateParameter(valid_592831, JString, required = true, default = newJString(
      "DynamoDB_20111205.BatchGetItem"))
  if valid_592831 != nil:
    section.add "X-Amz-Target", valid_592831
  var valid_592832 = header.getOrDefault("X-Amz-Signature")
  valid_592832 = validateParameter(valid_592832, JString, required = false,
                                 default = nil)
  if valid_592832 != nil:
    section.add "X-Amz-Signature", valid_592832
  var valid_592833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592833 = validateParameter(valid_592833, JString, required = false,
                                 default = nil)
  if valid_592833 != nil:
    section.add "X-Amz-Content-Sha256", valid_592833
  var valid_592834 = header.getOrDefault("X-Amz-Date")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "X-Amz-Date", valid_592834
  var valid_592835 = header.getOrDefault("X-Amz-Credential")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Credential", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Security-Token")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Security-Token", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-Algorithm")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-Algorithm", valid_592837
  var valid_592838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592838 = validateParameter(valid_592838, JString, required = false,
                                 default = nil)
  if valid_592838 != nil:
    section.add "X-Amz-SignedHeaders", valid_592838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592862: Call_BatchGetItem_592703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the attributes for multiple items from multiple tables using their primary keys.</p> <p>The maximum number of item attributes that can be retrieved for a single operation is 100. Also, the number of items retrieved is constrained by a 1 MB the size limit. If the response size limit is exceeded or a partial result is returned due to an internal processing failure, Amazon DynamoDB returns an <code>UnprocessedKeys</code> value so you can retry the operation starting with the next item to get.</p> <p>Amazon DynamoDB automatically adjusts the number of items returned per page to enforce this limit. For example, even if you ask to retrieve 100 items, but each individual item is 50k in size, the system returns 20 items and an appropriate <code>UnprocessedKeys</code> value so you can get the next page of results. If necessary, your application needs its own logic to assemble the pages of results into one set.</p>
  ## 
  let valid = call_592862.validator(path, query, header, formData, body)
  let scheme = call_592862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592862.url(scheme.get, call_592862.host, call_592862.base,
                         call_592862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592862, url, valid)

proc call*(call_592933: Call_BatchGetItem_592703; body: JsonNode;
          RequestItems: string = ""): Recallable =
  ## batchGetItem
  ## <p>Retrieves the attributes for multiple items from multiple tables using their primary keys.</p> <p>The maximum number of item attributes that can be retrieved for a single operation is 100. Also, the number of items retrieved is constrained by a 1 MB the size limit. If the response size limit is exceeded or a partial result is returned due to an internal processing failure, Amazon DynamoDB returns an <code>UnprocessedKeys</code> value so you can retry the operation starting with the next item to get.</p> <p>Amazon DynamoDB automatically adjusts the number of items returned per page to enforce this limit. For example, even if you ask to retrieve 100 items, but each individual item is 50k in size, the system returns 20 items and an appropriate <code>UnprocessedKeys</code> value so you can get the next page of results. If necessary, your application needs its own logic to assemble the pages of results into one set.</p>
  ##   RequestItems: string
  ##               : Pagination token
  ##   body: JObject (required)
  var query_592934 = newJObject()
  var body_592936 = newJObject()
  add(query_592934, "RequestItems", newJString(RequestItems))
  if body != nil:
    body_592936 = body
  result = call_592933.call(nil, query_592934, nil, nil, body_592936)

var batchGetItem* = Call_BatchGetItem_592703(name: "batchGetItem",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20111205.BatchGetItem",
    validator: validate_BatchGetItem_592704, base: "/", url: url_BatchGetItem_592705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchWriteItem_592975 = ref object of OpenApiRestCall_592364
proc url_BatchWriteItem_592977(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchWriteItem_592976(path: JsonNode; query: JsonNode;
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
  var valid_592978 = header.getOrDefault("X-Amz-Target")
  valid_592978 = validateParameter(valid_592978, JString, required = true, default = newJString(
      "DynamoDB_20111205.BatchWriteItem"))
  if valid_592978 != nil:
    section.add "X-Amz-Target", valid_592978
  var valid_592979 = header.getOrDefault("X-Amz-Signature")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Signature", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Content-Sha256", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Date")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Date", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-Credential")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-Credential", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-Security-Token")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-Security-Token", valid_592983
  var valid_592984 = header.getOrDefault("X-Amz-Algorithm")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-Algorithm", valid_592984
  var valid_592985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-SignedHeaders", valid_592985
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592987: Call_BatchWriteItem_592975; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Allows to execute a batch of Put and/or Delete Requests for many tables in a single call. A total of 25 requests are allowed.</p> <p>There are no transaction guarantees provided by this API. It does not allow conditional puts nor does it support return values.</p>
  ## 
  let valid = call_592987.validator(path, query, header, formData, body)
  let scheme = call_592987.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592987.url(scheme.get, call_592987.host, call_592987.base,
                         call_592987.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592987, url, valid)

proc call*(call_592988: Call_BatchWriteItem_592975; body: JsonNode): Recallable =
  ## batchWriteItem
  ## <p>Allows to execute a batch of Put and/or Delete Requests for many tables in a single call. A total of 25 requests are allowed.</p> <p>There are no transaction guarantees provided by this API. It does not allow conditional puts nor does it support return values.</p>
  ##   body: JObject (required)
  var body_592989 = newJObject()
  if body != nil:
    body_592989 = body
  result = call_592988.call(nil, nil, nil, nil, body_592989)

var batchWriteItem* = Call_BatchWriteItem_592975(name: "batchWriteItem",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20111205.BatchWriteItem",
    validator: validate_BatchWriteItem_592976, base: "/", url: url_BatchWriteItem_592977,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTable_592990 = ref object of OpenApiRestCall_592364
proc url_CreateTable_592992(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTable_592991(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592993 = header.getOrDefault("X-Amz-Target")
  valid_592993 = validateParameter(valid_592993, JString, required = true, default = newJString(
      "DynamoDB_20111205.CreateTable"))
  if valid_592993 != nil:
    section.add "X-Amz-Target", valid_592993
  var valid_592994 = header.getOrDefault("X-Amz-Signature")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Signature", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Content-Sha256", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-Date")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Date", valid_592996
  var valid_592997 = header.getOrDefault("X-Amz-Credential")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-Credential", valid_592997
  var valid_592998 = header.getOrDefault("X-Amz-Security-Token")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "X-Amz-Security-Token", valid_592998
  var valid_592999 = header.getOrDefault("X-Amz-Algorithm")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-Algorithm", valid_592999
  var valid_593000 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-SignedHeaders", valid_593000
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593002: Call_CreateTable_592990; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a new table to your account.</p> <p>The table name must be unique among those associated with the AWS Account issuing the request, and the AWS Region that receives the request (e.g. <code>us-east-1</code>).</p> <p>The <code>CreateTable</code> operation triggers an asynchronous workflow to begin creating the table. Amazon DynamoDB immediately returns the state of the table (<code>CREATING</code>) until the table is in the <code>ACTIVE</code> state. Once the table is in the <code>ACTIVE</code> state, you can perform data plane operations.</p>
  ## 
  let valid = call_593002.validator(path, query, header, formData, body)
  let scheme = call_593002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593002.url(scheme.get, call_593002.host, call_593002.base,
                         call_593002.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593002, url, valid)

proc call*(call_593003: Call_CreateTable_592990; body: JsonNode): Recallable =
  ## createTable
  ## <p>Adds a new table to your account.</p> <p>The table name must be unique among those associated with the AWS Account issuing the request, and the AWS Region that receives the request (e.g. <code>us-east-1</code>).</p> <p>The <code>CreateTable</code> operation triggers an asynchronous workflow to begin creating the table. Amazon DynamoDB immediately returns the state of the table (<code>CREATING</code>) until the table is in the <code>ACTIVE</code> state. Once the table is in the <code>ACTIVE</code> state, you can perform data plane operations.</p>
  ##   body: JObject (required)
  var body_593004 = newJObject()
  if body != nil:
    body_593004 = body
  result = call_593003.call(nil, nil, nil, nil, body_593004)

var createTable* = Call_CreateTable_592990(name: "createTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.CreateTable",
                                        validator: validate_CreateTable_592991,
                                        base: "/", url: url_CreateTable_592992,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteItem_593005 = ref object of OpenApiRestCall_592364
proc url_DeleteItem_593007(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteItem_593006(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593008 = header.getOrDefault("X-Amz-Target")
  valid_593008 = validateParameter(valid_593008, JString, required = true, default = newJString(
      "DynamoDB_20111205.DeleteItem"))
  if valid_593008 != nil:
    section.add "X-Amz-Target", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-Signature")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-Signature", valid_593009
  var valid_593010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Content-Sha256", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-Date")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Date", valid_593011
  var valid_593012 = header.getOrDefault("X-Amz-Credential")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-Credential", valid_593012
  var valid_593013 = header.getOrDefault("X-Amz-Security-Token")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "X-Amz-Security-Token", valid_593013
  var valid_593014 = header.getOrDefault("X-Amz-Algorithm")
  valid_593014 = validateParameter(valid_593014, JString, required = false,
                                 default = nil)
  if valid_593014 != nil:
    section.add "X-Amz-Algorithm", valid_593014
  var valid_593015 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "X-Amz-SignedHeaders", valid_593015
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593017: Call_DeleteItem_593005; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a single item in a table by primary key.</p> <p>You can perform a conditional delete operation that deletes the item if it exists, or if it has an expected attribute value.</p>
  ## 
  let valid = call_593017.validator(path, query, header, formData, body)
  let scheme = call_593017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593017.url(scheme.get, call_593017.host, call_593017.base,
                         call_593017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593017, url, valid)

proc call*(call_593018: Call_DeleteItem_593005; body: JsonNode): Recallable =
  ## deleteItem
  ## <p>Deletes a single item in a table by primary key.</p> <p>You can perform a conditional delete operation that deletes the item if it exists, or if it has an expected attribute value.</p>
  ##   body: JObject (required)
  var body_593019 = newJObject()
  if body != nil:
    body_593019 = body
  result = call_593018.call(nil, nil, nil, nil, body_593019)

var deleteItem* = Call_DeleteItem_593005(name: "deleteItem",
                                      meth: HttpMethod.HttpPost,
                                      host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.DeleteItem",
                                      validator: validate_DeleteItem_593006,
                                      base: "/", url: url_DeleteItem_593007,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTable_593020 = ref object of OpenApiRestCall_592364
proc url_DeleteTable_593022(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTable_593021(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593023 = header.getOrDefault("X-Amz-Target")
  valid_593023 = validateParameter(valid_593023, JString, required = true, default = newJString(
      "DynamoDB_20111205.DeleteTable"))
  if valid_593023 != nil:
    section.add "X-Amz-Target", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-Signature")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Signature", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Content-Sha256", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-Date")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Date", valid_593026
  var valid_593027 = header.getOrDefault("X-Amz-Credential")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-Credential", valid_593027
  var valid_593028 = header.getOrDefault("X-Amz-Security-Token")
  valid_593028 = validateParameter(valid_593028, JString, required = false,
                                 default = nil)
  if valid_593028 != nil:
    section.add "X-Amz-Security-Token", valid_593028
  var valid_593029 = header.getOrDefault("X-Amz-Algorithm")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "X-Amz-Algorithm", valid_593029
  var valid_593030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593030 = validateParameter(valid_593030, JString, required = false,
                                 default = nil)
  if valid_593030 != nil:
    section.add "X-Amz-SignedHeaders", valid_593030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593032: Call_DeleteTable_593020; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a table and all of its items.</p> <p>If the table is in the <code>ACTIVE</code> state, you can delete it. If a table is in <code>CREATING</code> or <code>UPDATING</code> states then Amazon DynamoDB returns a <code>ResourceInUseException</code>. If the specified table does not exist, Amazon DynamoDB returns a <code>ResourceNotFoundException</code>.</p>
  ## 
  let valid = call_593032.validator(path, query, header, formData, body)
  let scheme = call_593032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593032.url(scheme.get, call_593032.host, call_593032.base,
                         call_593032.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593032, url, valid)

proc call*(call_593033: Call_DeleteTable_593020; body: JsonNode): Recallable =
  ## deleteTable
  ## <p>Deletes a table and all of its items.</p> <p>If the table is in the <code>ACTIVE</code> state, you can delete it. If a table is in <code>CREATING</code> or <code>UPDATING</code> states then Amazon DynamoDB returns a <code>ResourceInUseException</code>. If the specified table does not exist, Amazon DynamoDB returns a <code>ResourceNotFoundException</code>.</p>
  ##   body: JObject (required)
  var body_593034 = newJObject()
  if body != nil:
    body_593034 = body
  result = call_593033.call(nil, nil, nil, nil, body_593034)

var deleteTable* = Call_DeleteTable_593020(name: "deleteTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.DeleteTable",
                                        validator: validate_DeleteTable_593021,
                                        base: "/", url: url_DeleteTable_593022,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTable_593035 = ref object of OpenApiRestCall_592364
proc url_DescribeTable_593037(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTable_593036(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593038 = header.getOrDefault("X-Amz-Target")
  valid_593038 = validateParameter(valid_593038, JString, required = true, default = newJString(
      "DynamoDB_20111205.DescribeTable"))
  if valid_593038 != nil:
    section.add "X-Amz-Target", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Signature")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Signature", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Content-Sha256", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Date")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Date", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-Credential")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-Credential", valid_593042
  var valid_593043 = header.getOrDefault("X-Amz-Security-Token")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "X-Amz-Security-Token", valid_593043
  var valid_593044 = header.getOrDefault("X-Amz-Algorithm")
  valid_593044 = validateParameter(valid_593044, JString, required = false,
                                 default = nil)
  if valid_593044 != nil:
    section.add "X-Amz-Algorithm", valid_593044
  var valid_593045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593045 = validateParameter(valid_593045, JString, required = false,
                                 default = nil)
  if valid_593045 != nil:
    section.add "X-Amz-SignedHeaders", valid_593045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593047: Call_DescribeTable_593035; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about the table, including the current status of the table, the primary key schema and when the table was created.</p> <p>If the table does not exist, Amazon DynamoDB returns a <code>ResourceNotFoundException</code>.</p>
  ## 
  let valid = call_593047.validator(path, query, header, formData, body)
  let scheme = call_593047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593047.url(scheme.get, call_593047.host, call_593047.base,
                         call_593047.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593047, url, valid)

proc call*(call_593048: Call_DescribeTable_593035; body: JsonNode): Recallable =
  ## describeTable
  ## <p>Retrieves information about the table, including the current status of the table, the primary key schema and when the table was created.</p> <p>If the table does not exist, Amazon DynamoDB returns a <code>ResourceNotFoundException</code>.</p>
  ##   body: JObject (required)
  var body_593049 = newJObject()
  if body != nil:
    body_593049 = body
  result = call_593048.call(nil, nil, nil, nil, body_593049)

var describeTable* = Call_DescribeTable_593035(name: "describeTable",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20111205.DescribeTable",
    validator: validate_DescribeTable_593036, base: "/", url: url_DescribeTable_593037,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetItem_593050 = ref object of OpenApiRestCall_592364
proc url_GetItem_593052(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetItem_593051(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593053 = header.getOrDefault("X-Amz-Target")
  valid_593053 = validateParameter(valid_593053, JString, required = true, default = newJString(
      "DynamoDB_20111205.GetItem"))
  if valid_593053 != nil:
    section.add "X-Amz-Target", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-Signature")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Signature", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Content-Sha256", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-Date")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-Date", valid_593056
  var valid_593057 = header.getOrDefault("X-Amz-Credential")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "X-Amz-Credential", valid_593057
  var valid_593058 = header.getOrDefault("X-Amz-Security-Token")
  valid_593058 = validateParameter(valid_593058, JString, required = false,
                                 default = nil)
  if valid_593058 != nil:
    section.add "X-Amz-Security-Token", valid_593058
  var valid_593059 = header.getOrDefault("X-Amz-Algorithm")
  valid_593059 = validateParameter(valid_593059, JString, required = false,
                                 default = nil)
  if valid_593059 != nil:
    section.add "X-Amz-Algorithm", valid_593059
  var valid_593060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "X-Amz-SignedHeaders", valid_593060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593062: Call_GetItem_593050; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a set of Attributes for an item that matches the primary key.</p> <p>The <code>GetItem</code> operation provides an eventually-consistent read by default. If eventually-consistent reads are not acceptable for your application, use <code>ConsistentRead</code>. Although this operation might take longer than a standard read, it always returns the last updated value.</p>
  ## 
  let valid = call_593062.validator(path, query, header, formData, body)
  let scheme = call_593062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593062.url(scheme.get, call_593062.host, call_593062.base,
                         call_593062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593062, url, valid)

proc call*(call_593063: Call_GetItem_593050; body: JsonNode): Recallable =
  ## getItem
  ## <p>Retrieves a set of Attributes for an item that matches the primary key.</p> <p>The <code>GetItem</code> operation provides an eventually-consistent read by default. If eventually-consistent reads are not acceptable for your application, use <code>ConsistentRead</code>. Although this operation might take longer than a standard read, it always returns the last updated value.</p>
  ##   body: JObject (required)
  var body_593064 = newJObject()
  if body != nil:
    body_593064 = body
  result = call_593063.call(nil, nil, nil, nil, body_593064)

var getItem* = Call_GetItem_593050(name: "getItem", meth: HttpMethod.HttpPost,
                                host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.GetItem",
                                validator: validate_GetItem_593051, base: "/",
                                url: url_GetItem_593052,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTables_593065 = ref object of OpenApiRestCall_592364
proc url_ListTables_593067(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTables_593066(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593068 = query.getOrDefault("Limit")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "Limit", valid_593068
  var valid_593069 = query.getOrDefault("ExclusiveStartTableName")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "ExclusiveStartTableName", valid_593069
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
  var valid_593070 = header.getOrDefault("X-Amz-Target")
  valid_593070 = validateParameter(valid_593070, JString, required = true, default = newJString(
      "DynamoDB_20111205.ListTables"))
  if valid_593070 != nil:
    section.add "X-Amz-Target", valid_593070
  var valid_593071 = header.getOrDefault("X-Amz-Signature")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-Signature", valid_593071
  var valid_593072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-Content-Sha256", valid_593072
  var valid_593073 = header.getOrDefault("X-Amz-Date")
  valid_593073 = validateParameter(valid_593073, JString, required = false,
                                 default = nil)
  if valid_593073 != nil:
    section.add "X-Amz-Date", valid_593073
  var valid_593074 = header.getOrDefault("X-Amz-Credential")
  valid_593074 = validateParameter(valid_593074, JString, required = false,
                                 default = nil)
  if valid_593074 != nil:
    section.add "X-Amz-Credential", valid_593074
  var valid_593075 = header.getOrDefault("X-Amz-Security-Token")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "X-Amz-Security-Token", valid_593075
  var valid_593076 = header.getOrDefault("X-Amz-Algorithm")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "X-Amz-Algorithm", valid_593076
  var valid_593077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-SignedHeaders", valid_593077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593079: Call_ListTables_593065; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a paginated list of table names created by the AWS Account of the caller in the AWS Region (e.g. <code>us-east-1</code>).
  ## 
  let valid = call_593079.validator(path, query, header, formData, body)
  let scheme = call_593079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593079.url(scheme.get, call_593079.host, call_593079.base,
                         call_593079.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593079, url, valid)

proc call*(call_593080: Call_ListTables_593065; body: JsonNode; Limit: string = "";
          ExclusiveStartTableName: string = ""): Recallable =
  ## listTables
  ## Retrieves a paginated list of table names created by the AWS Account of the caller in the AWS Region (e.g. <code>us-east-1</code>).
  ##   Limit: string
  ##        : Pagination limit
  ##   ExclusiveStartTableName: string
  ##                          : Pagination token
  ##   body: JObject (required)
  var query_593081 = newJObject()
  var body_593082 = newJObject()
  add(query_593081, "Limit", newJString(Limit))
  add(query_593081, "ExclusiveStartTableName", newJString(ExclusiveStartTableName))
  if body != nil:
    body_593082 = body
  result = call_593080.call(nil, query_593081, nil, nil, body_593082)

var listTables* = Call_ListTables_593065(name: "listTables",
                                      meth: HttpMethod.HttpPost,
                                      host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.ListTables",
                                      validator: validate_ListTables_593066,
                                      base: "/", url: url_ListTables_593067,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutItem_593083 = ref object of OpenApiRestCall_592364
proc url_PutItem_593085(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutItem_593084(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593086 = header.getOrDefault("X-Amz-Target")
  valid_593086 = validateParameter(valid_593086, JString, required = true, default = newJString(
      "DynamoDB_20111205.PutItem"))
  if valid_593086 != nil:
    section.add "X-Amz-Target", valid_593086
  var valid_593087 = header.getOrDefault("X-Amz-Signature")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "X-Amz-Signature", valid_593087
  var valid_593088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593088 = validateParameter(valid_593088, JString, required = false,
                                 default = nil)
  if valid_593088 != nil:
    section.add "X-Amz-Content-Sha256", valid_593088
  var valid_593089 = header.getOrDefault("X-Amz-Date")
  valid_593089 = validateParameter(valid_593089, JString, required = false,
                                 default = nil)
  if valid_593089 != nil:
    section.add "X-Amz-Date", valid_593089
  var valid_593090 = header.getOrDefault("X-Amz-Credential")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "X-Amz-Credential", valid_593090
  var valid_593091 = header.getOrDefault("X-Amz-Security-Token")
  valid_593091 = validateParameter(valid_593091, JString, required = false,
                                 default = nil)
  if valid_593091 != nil:
    section.add "X-Amz-Security-Token", valid_593091
  var valid_593092 = header.getOrDefault("X-Amz-Algorithm")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "X-Amz-Algorithm", valid_593092
  var valid_593093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593093 = validateParameter(valid_593093, JString, required = false,
                                 default = nil)
  if valid_593093 != nil:
    section.add "X-Amz-SignedHeaders", valid_593093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593095: Call_PutItem_593083; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new item, or replaces an old item with a new item (including all the attributes).</p> <p>If an item already exists in the specified table with the same primary key, the new item completely replaces the existing item. You can perform a conditional put (insert a new item if one with the specified primary key doesn't exist), or replace an existing item if it has certain attribute values.</p>
  ## 
  let valid = call_593095.validator(path, query, header, formData, body)
  let scheme = call_593095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593095.url(scheme.get, call_593095.host, call_593095.base,
                         call_593095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593095, url, valid)

proc call*(call_593096: Call_PutItem_593083; body: JsonNode): Recallable =
  ## putItem
  ## <p>Creates a new item, or replaces an old item with a new item (including all the attributes).</p> <p>If an item already exists in the specified table with the same primary key, the new item completely replaces the existing item. You can perform a conditional put (insert a new item if one with the specified primary key doesn't exist), or replace an existing item if it has certain attribute values.</p>
  ##   body: JObject (required)
  var body_593097 = newJObject()
  if body != nil:
    body_593097 = body
  result = call_593096.call(nil, nil, nil, nil, body_593097)

var putItem* = Call_PutItem_593083(name: "putItem", meth: HttpMethod.HttpPost,
                                host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.PutItem",
                                validator: validate_PutItem_593084, base: "/",
                                url: url_PutItem_593085,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_Query_593098 = ref object of OpenApiRestCall_592364
proc url_Query_593100(protocol: Scheme; host: string; base: string; route: string;
                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_Query_593099(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593101 = query.getOrDefault("Limit")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "Limit", valid_593101
  var valid_593102 = query.getOrDefault("ExclusiveStartKey")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "ExclusiveStartKey", valid_593102
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
  var valid_593103 = header.getOrDefault("X-Amz-Target")
  valid_593103 = validateParameter(valid_593103, JString, required = true, default = newJString(
      "DynamoDB_20111205.Query"))
  if valid_593103 != nil:
    section.add "X-Amz-Target", valid_593103
  var valid_593104 = header.getOrDefault("X-Amz-Signature")
  valid_593104 = validateParameter(valid_593104, JString, required = false,
                                 default = nil)
  if valid_593104 != nil:
    section.add "X-Amz-Signature", valid_593104
  var valid_593105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "X-Amz-Content-Sha256", valid_593105
  var valid_593106 = header.getOrDefault("X-Amz-Date")
  valid_593106 = validateParameter(valid_593106, JString, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "X-Amz-Date", valid_593106
  var valid_593107 = header.getOrDefault("X-Amz-Credential")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "X-Amz-Credential", valid_593107
  var valid_593108 = header.getOrDefault("X-Amz-Security-Token")
  valid_593108 = validateParameter(valid_593108, JString, required = false,
                                 default = nil)
  if valid_593108 != nil:
    section.add "X-Amz-Security-Token", valid_593108
  var valid_593109 = header.getOrDefault("X-Amz-Algorithm")
  valid_593109 = validateParameter(valid_593109, JString, required = false,
                                 default = nil)
  if valid_593109 != nil:
    section.add "X-Amz-Algorithm", valid_593109
  var valid_593110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593110 = validateParameter(valid_593110, JString, required = false,
                                 default = nil)
  if valid_593110 != nil:
    section.add "X-Amz-SignedHeaders", valid_593110
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593112: Call_Query_593098; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the values of one or more items and its attributes by primary key (composite primary key, only).</p> <p>Narrow the scope of the query using comparison operators on the <code>RangeKeyValue</code> of the composite key. Use the <code>ScanIndexForward</code> parameter to get results in forward or reverse order by range key.</p>
  ## 
  let valid = call_593112.validator(path, query, header, formData, body)
  let scheme = call_593112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593112.url(scheme.get, call_593112.host, call_593112.base,
                         call_593112.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593112, url, valid)

proc call*(call_593113: Call_Query_593098; body: JsonNode; Limit: string = "";
          ExclusiveStartKey: string = ""): Recallable =
  ## query
  ## <p>Gets the values of one or more items and its attributes by primary key (composite primary key, only).</p> <p>Narrow the scope of the query using comparison operators on the <code>RangeKeyValue</code> of the composite key. Use the <code>ScanIndexForward</code> parameter to get results in forward or reverse order by range key.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  ##   ExclusiveStartKey: string
  ##                    : Pagination token
  var query_593114 = newJObject()
  var body_593115 = newJObject()
  add(query_593114, "Limit", newJString(Limit))
  if body != nil:
    body_593115 = body
  add(query_593114, "ExclusiveStartKey", newJString(ExclusiveStartKey))
  result = call_593113.call(nil, query_593114, nil, nil, body_593115)

var query* = Call_Query_593098(name: "query", meth: HttpMethod.HttpPost,
                            host: "dynamodb.amazonaws.com",
                            route: "/#X-Amz-Target=DynamoDB_20111205.Query",
                            validator: validate_Query_593099, base: "/",
                            url: url_Query_593100,
                            schemes: {Scheme.Https, Scheme.Http})
type
  Call_Scan_593116 = ref object of OpenApiRestCall_592364
proc url_Scan_593118(protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_Scan_593117(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593119 = query.getOrDefault("Limit")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "Limit", valid_593119
  var valid_593120 = query.getOrDefault("ExclusiveStartKey")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "ExclusiveStartKey", valid_593120
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
  var valid_593121 = header.getOrDefault("X-Amz-Target")
  valid_593121 = validateParameter(valid_593121, JString, required = true,
                                 default = newJString("DynamoDB_20111205.Scan"))
  if valid_593121 != nil:
    section.add "X-Amz-Target", valid_593121
  var valid_593122 = header.getOrDefault("X-Amz-Signature")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "X-Amz-Signature", valid_593122
  var valid_593123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-Content-Sha256", valid_593123
  var valid_593124 = header.getOrDefault("X-Amz-Date")
  valid_593124 = validateParameter(valid_593124, JString, required = false,
                                 default = nil)
  if valid_593124 != nil:
    section.add "X-Amz-Date", valid_593124
  var valid_593125 = header.getOrDefault("X-Amz-Credential")
  valid_593125 = validateParameter(valid_593125, JString, required = false,
                                 default = nil)
  if valid_593125 != nil:
    section.add "X-Amz-Credential", valid_593125
  var valid_593126 = header.getOrDefault("X-Amz-Security-Token")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-Security-Token", valid_593126
  var valid_593127 = header.getOrDefault("X-Amz-Algorithm")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-Algorithm", valid_593127
  var valid_593128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-SignedHeaders", valid_593128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593130: Call_Scan_593116; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves one or more items and its attributes by performing a full scan of a table.</p> <p>Provide a <code>ScanFilter</code> to get more specific results.</p>
  ## 
  let valid = call_593130.validator(path, query, header, formData, body)
  let scheme = call_593130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593130.url(scheme.get, call_593130.host, call_593130.base,
                         call_593130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593130, url, valid)

proc call*(call_593131: Call_Scan_593116; body: JsonNode; Limit: string = "";
          ExclusiveStartKey: string = ""): Recallable =
  ## scan
  ## <p>Retrieves one or more items and its attributes by performing a full scan of a table.</p> <p>Provide a <code>ScanFilter</code> to get more specific results.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  ##   ExclusiveStartKey: string
  ##                    : Pagination token
  var query_593132 = newJObject()
  var body_593133 = newJObject()
  add(query_593132, "Limit", newJString(Limit))
  if body != nil:
    body_593133 = body
  add(query_593132, "ExclusiveStartKey", newJString(ExclusiveStartKey))
  result = call_593131.call(nil, query_593132, nil, nil, body_593133)

var scan* = Call_Scan_593116(name: "scan", meth: HttpMethod.HttpPost,
                          host: "dynamodb.amazonaws.com",
                          route: "/#X-Amz-Target=DynamoDB_20111205.Scan",
                          validator: validate_Scan_593117, base: "/", url: url_Scan_593118,
                          schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateItem_593134 = ref object of OpenApiRestCall_592364
proc url_UpdateItem_593136(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateItem_593135(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593137 = header.getOrDefault("X-Amz-Target")
  valid_593137 = validateParameter(valid_593137, JString, required = true, default = newJString(
      "DynamoDB_20111205.UpdateItem"))
  if valid_593137 != nil:
    section.add "X-Amz-Target", valid_593137
  var valid_593138 = header.getOrDefault("X-Amz-Signature")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-Signature", valid_593138
  var valid_593139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "X-Amz-Content-Sha256", valid_593139
  var valid_593140 = header.getOrDefault("X-Amz-Date")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-Date", valid_593140
  var valid_593141 = header.getOrDefault("X-Amz-Credential")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-Credential", valid_593141
  var valid_593142 = header.getOrDefault("X-Amz-Security-Token")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-Security-Token", valid_593142
  var valid_593143 = header.getOrDefault("X-Amz-Algorithm")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-Algorithm", valid_593143
  var valid_593144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-SignedHeaders", valid_593144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593146: Call_UpdateItem_593134; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Edits an existing item's attributes.</p> <p>You can perform a conditional update (insert a new attribute name-value pair if it doesn't exist, or replace an existing name-value pair if it has certain expected attribute values).</p>
  ## 
  let valid = call_593146.validator(path, query, header, formData, body)
  let scheme = call_593146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593146.url(scheme.get, call_593146.host, call_593146.base,
                         call_593146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593146, url, valid)

proc call*(call_593147: Call_UpdateItem_593134; body: JsonNode): Recallable =
  ## updateItem
  ## <p>Edits an existing item's attributes.</p> <p>You can perform a conditional update (insert a new attribute name-value pair if it doesn't exist, or replace an existing name-value pair if it has certain expected attribute values).</p>
  ##   body: JObject (required)
  var body_593148 = newJObject()
  if body != nil:
    body_593148 = body
  result = call_593147.call(nil, nil, nil, nil, body_593148)

var updateItem* = Call_UpdateItem_593134(name: "updateItem",
                                      meth: HttpMethod.HttpPost,
                                      host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.UpdateItem",
                                      validator: validate_UpdateItem_593135,
                                      base: "/", url: url_UpdateItem_593136,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTable_593149 = ref object of OpenApiRestCall_592364
proc url_UpdateTable_593151(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateTable_593150(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593152 = header.getOrDefault("X-Amz-Target")
  valid_593152 = validateParameter(valid_593152, JString, required = true, default = newJString(
      "DynamoDB_20111205.UpdateTable"))
  if valid_593152 != nil:
    section.add "X-Amz-Target", valid_593152
  var valid_593153 = header.getOrDefault("X-Amz-Signature")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "X-Amz-Signature", valid_593153
  var valid_593154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "X-Amz-Content-Sha256", valid_593154
  var valid_593155 = header.getOrDefault("X-Amz-Date")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "X-Amz-Date", valid_593155
  var valid_593156 = header.getOrDefault("X-Amz-Credential")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "X-Amz-Credential", valid_593156
  var valid_593157 = header.getOrDefault("X-Amz-Security-Token")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-Security-Token", valid_593157
  var valid_593158 = header.getOrDefault("X-Amz-Algorithm")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-Algorithm", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-SignedHeaders", valid_593159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593161: Call_UpdateTable_593149; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the provisioned throughput for the given table.</p> <p>Setting the throughput for a table helps you manage performance and is part of the Provisioned Throughput feature of Amazon DynamoDB.</p>
  ## 
  let valid = call_593161.validator(path, query, header, formData, body)
  let scheme = call_593161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593161.url(scheme.get, call_593161.host, call_593161.base,
                         call_593161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593161, url, valid)

proc call*(call_593162: Call_UpdateTable_593149; body: JsonNode): Recallable =
  ## updateTable
  ## <p>Updates the provisioned throughput for the given table.</p> <p>Setting the throughput for a table helps you manage performance and is part of the Provisioned Throughput feature of Amazon DynamoDB.</p>
  ##   body: JObject (required)
  var body_593163 = newJObject()
  if body != nil:
    body_593163 = body
  result = call_593162.call(nil, nil, nil, nil, body_593163)

var updateTable* = Call_UpdateTable_593149(name: "updateTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.UpdateTable",
                                        validator: validate_UpdateTable_593150,
                                        base: "/", url: url_UpdateTable_593151,
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
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
