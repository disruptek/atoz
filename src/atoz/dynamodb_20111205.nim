
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  Call_BatchGetItem_601727 = ref object of OpenApiRestCall_601389
proc url_BatchGetItem_601729(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetItem_601728(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601841 = query.getOrDefault("RequestItems")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "RequestItems", valid_601841
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
  var valid_601855 = header.getOrDefault("X-Amz-Target")
  valid_601855 = validateParameter(valid_601855, JString, required = true, default = newJString(
      "DynamoDB_20111205.BatchGetItem"))
  if valid_601855 != nil:
    section.add "X-Amz-Target", valid_601855
  var valid_601856 = header.getOrDefault("X-Amz-Signature")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Signature", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Content-Sha256", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Date")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Date", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Credential")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Credential", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Security-Token")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Security-Token", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Algorithm")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Algorithm", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-SignedHeaders", valid_601862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601886: Call_BatchGetItem_601727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the attributes for multiple items from multiple tables using their primary keys.</p> <p>The maximum number of item attributes that can be retrieved for a single operation is 100. Also, the number of items retrieved is constrained by a 1 MB the size limit. If the response size limit is exceeded or a partial result is returned due to an internal processing failure, Amazon DynamoDB returns an <code>UnprocessedKeys</code> value so you can retry the operation starting with the next item to get.</p> <p>Amazon DynamoDB automatically adjusts the number of items returned per page to enforce this limit. For example, even if you ask to retrieve 100 items, but each individual item is 50k in size, the system returns 20 items and an appropriate <code>UnprocessedKeys</code> value so you can get the next page of results. If necessary, your application needs its own logic to assemble the pages of results into one set.</p>
  ## 
  let valid = call_601886.validator(path, query, header, formData, body)
  let scheme = call_601886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601886.url(scheme.get, call_601886.host, call_601886.base,
                         call_601886.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601886, url, valid)

proc call*(call_601957: Call_BatchGetItem_601727; body: JsonNode;
          RequestItems: string = ""): Recallable =
  ## batchGetItem
  ## <p>Retrieves the attributes for multiple items from multiple tables using their primary keys.</p> <p>The maximum number of item attributes that can be retrieved for a single operation is 100. Also, the number of items retrieved is constrained by a 1 MB the size limit. If the response size limit is exceeded or a partial result is returned due to an internal processing failure, Amazon DynamoDB returns an <code>UnprocessedKeys</code> value so you can retry the operation starting with the next item to get.</p> <p>Amazon DynamoDB automatically adjusts the number of items returned per page to enforce this limit. For example, even if you ask to retrieve 100 items, but each individual item is 50k in size, the system returns 20 items and an appropriate <code>UnprocessedKeys</code> value so you can get the next page of results. If necessary, your application needs its own logic to assemble the pages of results into one set.</p>
  ##   RequestItems: string
  ##               : Pagination token
  ##   body: JObject (required)
  var query_601958 = newJObject()
  var body_601960 = newJObject()
  add(query_601958, "RequestItems", newJString(RequestItems))
  if body != nil:
    body_601960 = body
  result = call_601957.call(nil, query_601958, nil, nil, body_601960)

var batchGetItem* = Call_BatchGetItem_601727(name: "batchGetItem",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20111205.BatchGetItem",
    validator: validate_BatchGetItem_601728, base: "/", url: url_BatchGetItem_601729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchWriteItem_601999 = ref object of OpenApiRestCall_601389
proc url_BatchWriteItem_602001(protocol: Scheme; host: string; base: string;
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

proc validate_BatchWriteItem_602000(path: JsonNode; query: JsonNode;
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
  var valid_602002 = header.getOrDefault("X-Amz-Target")
  valid_602002 = validateParameter(valid_602002, JString, required = true, default = newJString(
      "DynamoDB_20111205.BatchWriteItem"))
  if valid_602002 != nil:
    section.add "X-Amz-Target", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Signature")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Signature", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Content-Sha256", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Date")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Date", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Credential")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Credential", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Security-Token")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Security-Token", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Algorithm")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Algorithm", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-SignedHeaders", valid_602009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602011: Call_BatchWriteItem_601999; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Allows to execute a batch of Put and/or Delete Requests for many tables in a single call. A total of 25 requests are allowed.</p> <p>There are no transaction guarantees provided by this API. It does not allow conditional puts nor does it support return values.</p>
  ## 
  let valid = call_602011.validator(path, query, header, formData, body)
  let scheme = call_602011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602011.url(scheme.get, call_602011.host, call_602011.base,
                         call_602011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602011, url, valid)

proc call*(call_602012: Call_BatchWriteItem_601999; body: JsonNode): Recallable =
  ## batchWriteItem
  ## <p>Allows to execute a batch of Put and/or Delete Requests for many tables in a single call. A total of 25 requests are allowed.</p> <p>There are no transaction guarantees provided by this API. It does not allow conditional puts nor does it support return values.</p>
  ##   body: JObject (required)
  var body_602013 = newJObject()
  if body != nil:
    body_602013 = body
  result = call_602012.call(nil, nil, nil, nil, body_602013)

var batchWriteItem* = Call_BatchWriteItem_601999(name: "batchWriteItem",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20111205.BatchWriteItem",
    validator: validate_BatchWriteItem_602000, base: "/", url: url_BatchWriteItem_602001,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTable_602014 = ref object of OpenApiRestCall_601389
proc url_CreateTable_602016(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTable_602015(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602017 = header.getOrDefault("X-Amz-Target")
  valid_602017 = validateParameter(valid_602017, JString, required = true, default = newJString(
      "DynamoDB_20111205.CreateTable"))
  if valid_602017 != nil:
    section.add "X-Amz-Target", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Signature")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Signature", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Content-Sha256", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Date")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Date", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-Credential")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Credential", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-Security-Token")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Security-Token", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-Algorithm")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Algorithm", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-SignedHeaders", valid_602024
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602026: Call_CreateTable_602014; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a new table to your account.</p> <p>The table name must be unique among those associated with the AWS Account issuing the request, and the AWS Region that receives the request (e.g. <code>us-east-1</code>).</p> <p>The <code>CreateTable</code> operation triggers an asynchronous workflow to begin creating the table. Amazon DynamoDB immediately returns the state of the table (<code>CREATING</code>) until the table is in the <code>ACTIVE</code> state. Once the table is in the <code>ACTIVE</code> state, you can perform data plane operations.</p>
  ## 
  let valid = call_602026.validator(path, query, header, formData, body)
  let scheme = call_602026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602026.url(scheme.get, call_602026.host, call_602026.base,
                         call_602026.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602026, url, valid)

proc call*(call_602027: Call_CreateTable_602014; body: JsonNode): Recallable =
  ## createTable
  ## <p>Adds a new table to your account.</p> <p>The table name must be unique among those associated with the AWS Account issuing the request, and the AWS Region that receives the request (e.g. <code>us-east-1</code>).</p> <p>The <code>CreateTable</code> operation triggers an asynchronous workflow to begin creating the table. Amazon DynamoDB immediately returns the state of the table (<code>CREATING</code>) until the table is in the <code>ACTIVE</code> state. Once the table is in the <code>ACTIVE</code> state, you can perform data plane operations.</p>
  ##   body: JObject (required)
  var body_602028 = newJObject()
  if body != nil:
    body_602028 = body
  result = call_602027.call(nil, nil, nil, nil, body_602028)

var createTable* = Call_CreateTable_602014(name: "createTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.CreateTable",
                                        validator: validate_CreateTable_602015,
                                        base: "/", url: url_CreateTable_602016,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteItem_602029 = ref object of OpenApiRestCall_601389
proc url_DeleteItem_602031(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteItem_602030(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602032 = header.getOrDefault("X-Amz-Target")
  valid_602032 = validateParameter(valid_602032, JString, required = true, default = newJString(
      "DynamoDB_20111205.DeleteItem"))
  if valid_602032 != nil:
    section.add "X-Amz-Target", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Signature")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Signature", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Content-Sha256", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Date")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Date", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-Credential")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Credential", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-Security-Token")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-Security-Token", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-Algorithm")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Algorithm", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-SignedHeaders", valid_602039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602041: Call_DeleteItem_602029; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a single item in a table by primary key.</p> <p>You can perform a conditional delete operation that deletes the item if it exists, or if it has an expected attribute value.</p>
  ## 
  let valid = call_602041.validator(path, query, header, formData, body)
  let scheme = call_602041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602041.url(scheme.get, call_602041.host, call_602041.base,
                         call_602041.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602041, url, valid)

proc call*(call_602042: Call_DeleteItem_602029; body: JsonNode): Recallable =
  ## deleteItem
  ## <p>Deletes a single item in a table by primary key.</p> <p>You can perform a conditional delete operation that deletes the item if it exists, or if it has an expected attribute value.</p>
  ##   body: JObject (required)
  var body_602043 = newJObject()
  if body != nil:
    body_602043 = body
  result = call_602042.call(nil, nil, nil, nil, body_602043)

var deleteItem* = Call_DeleteItem_602029(name: "deleteItem",
                                      meth: HttpMethod.HttpPost,
                                      host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.DeleteItem",
                                      validator: validate_DeleteItem_602030,
                                      base: "/", url: url_DeleteItem_602031,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTable_602044 = ref object of OpenApiRestCall_601389
proc url_DeleteTable_602046(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTable_602045(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602047 = header.getOrDefault("X-Amz-Target")
  valid_602047 = validateParameter(valid_602047, JString, required = true, default = newJString(
      "DynamoDB_20111205.DeleteTable"))
  if valid_602047 != nil:
    section.add "X-Amz-Target", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Signature")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Signature", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Content-Sha256", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Date")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Date", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-Credential")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Credential", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-Security-Token")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-Security-Token", valid_602052
  var valid_602053 = header.getOrDefault("X-Amz-Algorithm")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-Algorithm", valid_602053
  var valid_602054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-SignedHeaders", valid_602054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602056: Call_DeleteTable_602044; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a table and all of its items.</p> <p>If the table is in the <code>ACTIVE</code> state, you can delete it. If a table is in <code>CREATING</code> or <code>UPDATING</code> states then Amazon DynamoDB returns a <code>ResourceInUseException</code>. If the specified table does not exist, Amazon DynamoDB returns a <code>ResourceNotFoundException</code>.</p>
  ## 
  let valid = call_602056.validator(path, query, header, formData, body)
  let scheme = call_602056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602056.url(scheme.get, call_602056.host, call_602056.base,
                         call_602056.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602056, url, valid)

proc call*(call_602057: Call_DeleteTable_602044; body: JsonNode): Recallable =
  ## deleteTable
  ## <p>Deletes a table and all of its items.</p> <p>If the table is in the <code>ACTIVE</code> state, you can delete it. If a table is in <code>CREATING</code> or <code>UPDATING</code> states then Amazon DynamoDB returns a <code>ResourceInUseException</code>. If the specified table does not exist, Amazon DynamoDB returns a <code>ResourceNotFoundException</code>.</p>
  ##   body: JObject (required)
  var body_602058 = newJObject()
  if body != nil:
    body_602058 = body
  result = call_602057.call(nil, nil, nil, nil, body_602058)

var deleteTable* = Call_DeleteTable_602044(name: "deleteTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.DeleteTable",
                                        validator: validate_DeleteTable_602045,
                                        base: "/", url: url_DeleteTable_602046,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTable_602059 = ref object of OpenApiRestCall_601389
proc url_DescribeTable_602061(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTable_602060(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602062 = header.getOrDefault("X-Amz-Target")
  valid_602062 = validateParameter(valid_602062, JString, required = true, default = newJString(
      "DynamoDB_20111205.DescribeTable"))
  if valid_602062 != nil:
    section.add "X-Amz-Target", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Signature")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Signature", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Content-Sha256", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Date")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Date", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-Credential")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Credential", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-Security-Token")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-Security-Token", valid_602067
  var valid_602068 = header.getOrDefault("X-Amz-Algorithm")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Algorithm", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-SignedHeaders", valid_602069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602071: Call_DescribeTable_602059; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about the table, including the current status of the table, the primary key schema and when the table was created.</p> <p>If the table does not exist, Amazon DynamoDB returns a <code>ResourceNotFoundException</code>.</p>
  ## 
  let valid = call_602071.validator(path, query, header, formData, body)
  let scheme = call_602071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602071.url(scheme.get, call_602071.host, call_602071.base,
                         call_602071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602071, url, valid)

proc call*(call_602072: Call_DescribeTable_602059; body: JsonNode): Recallable =
  ## describeTable
  ## <p>Retrieves information about the table, including the current status of the table, the primary key schema and when the table was created.</p> <p>If the table does not exist, Amazon DynamoDB returns a <code>ResourceNotFoundException</code>.</p>
  ##   body: JObject (required)
  var body_602073 = newJObject()
  if body != nil:
    body_602073 = body
  result = call_602072.call(nil, nil, nil, nil, body_602073)

var describeTable* = Call_DescribeTable_602059(name: "describeTable",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20111205.DescribeTable",
    validator: validate_DescribeTable_602060, base: "/", url: url_DescribeTable_602061,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetItem_602074 = ref object of OpenApiRestCall_601389
proc url_GetItem_602076(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetItem_602075(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602077 = header.getOrDefault("X-Amz-Target")
  valid_602077 = validateParameter(valid_602077, JString, required = true, default = newJString(
      "DynamoDB_20111205.GetItem"))
  if valid_602077 != nil:
    section.add "X-Amz-Target", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Signature")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Signature", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Content-Sha256", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Date")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Date", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-Credential")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-Credential", valid_602081
  var valid_602082 = header.getOrDefault("X-Amz-Security-Token")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-Security-Token", valid_602082
  var valid_602083 = header.getOrDefault("X-Amz-Algorithm")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-Algorithm", valid_602083
  var valid_602084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-SignedHeaders", valid_602084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602086: Call_GetItem_602074; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a set of Attributes for an item that matches the primary key.</p> <p>The <code>GetItem</code> operation provides an eventually-consistent read by default. If eventually-consistent reads are not acceptable for your application, use <code>ConsistentRead</code>. Although this operation might take longer than a standard read, it always returns the last updated value.</p>
  ## 
  let valid = call_602086.validator(path, query, header, formData, body)
  let scheme = call_602086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602086.url(scheme.get, call_602086.host, call_602086.base,
                         call_602086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602086, url, valid)

proc call*(call_602087: Call_GetItem_602074; body: JsonNode): Recallable =
  ## getItem
  ## <p>Retrieves a set of Attributes for an item that matches the primary key.</p> <p>The <code>GetItem</code> operation provides an eventually-consistent read by default. If eventually-consistent reads are not acceptable for your application, use <code>ConsistentRead</code>. Although this operation might take longer than a standard read, it always returns the last updated value.</p>
  ##   body: JObject (required)
  var body_602088 = newJObject()
  if body != nil:
    body_602088 = body
  result = call_602087.call(nil, nil, nil, nil, body_602088)

var getItem* = Call_GetItem_602074(name: "getItem", meth: HttpMethod.HttpPost,
                                host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.GetItem",
                                validator: validate_GetItem_602075, base: "/",
                                url: url_GetItem_602076,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTables_602089 = ref object of OpenApiRestCall_601389
proc url_ListTables_602091(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListTables_602090(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602092 = query.getOrDefault("Limit")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "Limit", valid_602092
  var valid_602093 = query.getOrDefault("ExclusiveStartTableName")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "ExclusiveStartTableName", valid_602093
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
  var valid_602094 = header.getOrDefault("X-Amz-Target")
  valid_602094 = validateParameter(valid_602094, JString, required = true, default = newJString(
      "DynamoDB_20111205.ListTables"))
  if valid_602094 != nil:
    section.add "X-Amz-Target", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Signature")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Signature", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-Content-Sha256", valid_602096
  var valid_602097 = header.getOrDefault("X-Amz-Date")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "X-Amz-Date", valid_602097
  var valid_602098 = header.getOrDefault("X-Amz-Credential")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "X-Amz-Credential", valid_602098
  var valid_602099 = header.getOrDefault("X-Amz-Security-Token")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "X-Amz-Security-Token", valid_602099
  var valid_602100 = header.getOrDefault("X-Amz-Algorithm")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "X-Amz-Algorithm", valid_602100
  var valid_602101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "X-Amz-SignedHeaders", valid_602101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602103: Call_ListTables_602089; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a paginated list of table names created by the AWS Account of the caller in the AWS Region (e.g. <code>us-east-1</code>).
  ## 
  let valid = call_602103.validator(path, query, header, formData, body)
  let scheme = call_602103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602103.url(scheme.get, call_602103.host, call_602103.base,
                         call_602103.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602103, url, valid)

proc call*(call_602104: Call_ListTables_602089; body: JsonNode; Limit: string = "";
          ExclusiveStartTableName: string = ""): Recallable =
  ## listTables
  ## Retrieves a paginated list of table names created by the AWS Account of the caller in the AWS Region (e.g. <code>us-east-1</code>).
  ##   Limit: string
  ##        : Pagination limit
  ##   ExclusiveStartTableName: string
  ##                          : Pagination token
  ##   body: JObject (required)
  var query_602105 = newJObject()
  var body_602106 = newJObject()
  add(query_602105, "Limit", newJString(Limit))
  add(query_602105, "ExclusiveStartTableName", newJString(ExclusiveStartTableName))
  if body != nil:
    body_602106 = body
  result = call_602104.call(nil, query_602105, nil, nil, body_602106)

var listTables* = Call_ListTables_602089(name: "listTables",
                                      meth: HttpMethod.HttpPost,
                                      host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.ListTables",
                                      validator: validate_ListTables_602090,
                                      base: "/", url: url_ListTables_602091,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutItem_602107 = ref object of OpenApiRestCall_601389
proc url_PutItem_602109(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutItem_602108(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602110 = header.getOrDefault("X-Amz-Target")
  valid_602110 = validateParameter(valid_602110, JString, required = true, default = newJString(
      "DynamoDB_20111205.PutItem"))
  if valid_602110 != nil:
    section.add "X-Amz-Target", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Signature")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Signature", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-Content-Sha256", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-Date")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-Date", valid_602113
  var valid_602114 = header.getOrDefault("X-Amz-Credential")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "X-Amz-Credential", valid_602114
  var valid_602115 = header.getOrDefault("X-Amz-Security-Token")
  valid_602115 = validateParameter(valid_602115, JString, required = false,
                                 default = nil)
  if valid_602115 != nil:
    section.add "X-Amz-Security-Token", valid_602115
  var valid_602116 = header.getOrDefault("X-Amz-Algorithm")
  valid_602116 = validateParameter(valid_602116, JString, required = false,
                                 default = nil)
  if valid_602116 != nil:
    section.add "X-Amz-Algorithm", valid_602116
  var valid_602117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602117 = validateParameter(valid_602117, JString, required = false,
                                 default = nil)
  if valid_602117 != nil:
    section.add "X-Amz-SignedHeaders", valid_602117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602119: Call_PutItem_602107; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new item, or replaces an old item with a new item (including all the attributes).</p> <p>If an item already exists in the specified table with the same primary key, the new item completely replaces the existing item. You can perform a conditional put (insert a new item if one with the specified primary key doesn't exist), or replace an existing item if it has certain attribute values.</p>
  ## 
  let valid = call_602119.validator(path, query, header, formData, body)
  let scheme = call_602119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602119.url(scheme.get, call_602119.host, call_602119.base,
                         call_602119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602119, url, valid)

proc call*(call_602120: Call_PutItem_602107; body: JsonNode): Recallable =
  ## putItem
  ## <p>Creates a new item, or replaces an old item with a new item (including all the attributes).</p> <p>If an item already exists in the specified table with the same primary key, the new item completely replaces the existing item. You can perform a conditional put (insert a new item if one with the specified primary key doesn't exist), or replace an existing item if it has certain attribute values.</p>
  ##   body: JObject (required)
  var body_602121 = newJObject()
  if body != nil:
    body_602121 = body
  result = call_602120.call(nil, nil, nil, nil, body_602121)

var putItem* = Call_PutItem_602107(name: "putItem", meth: HttpMethod.HttpPost,
                                host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.PutItem",
                                validator: validate_PutItem_602108, base: "/",
                                url: url_PutItem_602109,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_Query_602122 = ref object of OpenApiRestCall_601389
proc url_Query_602124(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_Query_602123(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602125 = query.getOrDefault("Limit")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "Limit", valid_602125
  var valid_602126 = query.getOrDefault("ExclusiveStartKey")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "ExclusiveStartKey", valid_602126
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
  var valid_602127 = header.getOrDefault("X-Amz-Target")
  valid_602127 = validateParameter(valid_602127, JString, required = true, default = newJString(
      "DynamoDB_20111205.Query"))
  if valid_602127 != nil:
    section.add "X-Amz-Target", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-Signature")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Signature", valid_602128
  var valid_602129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "X-Amz-Content-Sha256", valid_602129
  var valid_602130 = header.getOrDefault("X-Amz-Date")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "X-Amz-Date", valid_602130
  var valid_602131 = header.getOrDefault("X-Amz-Credential")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "X-Amz-Credential", valid_602131
  var valid_602132 = header.getOrDefault("X-Amz-Security-Token")
  valid_602132 = validateParameter(valid_602132, JString, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "X-Amz-Security-Token", valid_602132
  var valid_602133 = header.getOrDefault("X-Amz-Algorithm")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "X-Amz-Algorithm", valid_602133
  var valid_602134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "X-Amz-SignedHeaders", valid_602134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602136: Call_Query_602122; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the values of one or more items and its attributes by primary key (composite primary key, only).</p> <p>Narrow the scope of the query using comparison operators on the <code>RangeKeyValue</code> of the composite key. Use the <code>ScanIndexForward</code> parameter to get results in forward or reverse order by range key.</p>
  ## 
  let valid = call_602136.validator(path, query, header, formData, body)
  let scheme = call_602136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602136.url(scheme.get, call_602136.host, call_602136.base,
                         call_602136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602136, url, valid)

proc call*(call_602137: Call_Query_602122; body: JsonNode; Limit: string = "";
          ExclusiveStartKey: string = ""): Recallable =
  ## query
  ## <p>Gets the values of one or more items and its attributes by primary key (composite primary key, only).</p> <p>Narrow the scope of the query using comparison operators on the <code>RangeKeyValue</code> of the composite key. Use the <code>ScanIndexForward</code> parameter to get results in forward or reverse order by range key.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  ##   ExclusiveStartKey: string
  ##                    : Pagination token
  var query_602138 = newJObject()
  var body_602139 = newJObject()
  add(query_602138, "Limit", newJString(Limit))
  if body != nil:
    body_602139 = body
  add(query_602138, "ExclusiveStartKey", newJString(ExclusiveStartKey))
  result = call_602137.call(nil, query_602138, nil, nil, body_602139)

var query* = Call_Query_602122(name: "query", meth: HttpMethod.HttpPost,
                            host: "dynamodb.amazonaws.com",
                            route: "/#X-Amz-Target=DynamoDB_20111205.Query",
                            validator: validate_Query_602123, base: "/",
                            url: url_Query_602124,
                            schemes: {Scheme.Https, Scheme.Http})
type
  Call_Scan_602140 = ref object of OpenApiRestCall_601389
proc url_Scan_602142(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_Scan_602141(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602143 = query.getOrDefault("Limit")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "Limit", valid_602143
  var valid_602144 = query.getOrDefault("ExclusiveStartKey")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "ExclusiveStartKey", valid_602144
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
  var valid_602145 = header.getOrDefault("X-Amz-Target")
  valid_602145 = validateParameter(valid_602145, JString, required = true,
                                 default = newJString("DynamoDB_20111205.Scan"))
  if valid_602145 != nil:
    section.add "X-Amz-Target", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-Signature")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Signature", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-Content-Sha256", valid_602147
  var valid_602148 = header.getOrDefault("X-Amz-Date")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "X-Amz-Date", valid_602148
  var valid_602149 = header.getOrDefault("X-Amz-Credential")
  valid_602149 = validateParameter(valid_602149, JString, required = false,
                                 default = nil)
  if valid_602149 != nil:
    section.add "X-Amz-Credential", valid_602149
  var valid_602150 = header.getOrDefault("X-Amz-Security-Token")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Security-Token", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-Algorithm")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Algorithm", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-SignedHeaders", valid_602152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602154: Call_Scan_602140; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves one or more items and its attributes by performing a full scan of a table.</p> <p>Provide a <code>ScanFilter</code> to get more specific results.</p>
  ## 
  let valid = call_602154.validator(path, query, header, formData, body)
  let scheme = call_602154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602154.url(scheme.get, call_602154.host, call_602154.base,
                         call_602154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602154, url, valid)

proc call*(call_602155: Call_Scan_602140; body: JsonNode; Limit: string = "";
          ExclusiveStartKey: string = ""): Recallable =
  ## scan
  ## <p>Retrieves one or more items and its attributes by performing a full scan of a table.</p> <p>Provide a <code>ScanFilter</code> to get more specific results.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  ##   ExclusiveStartKey: string
  ##                    : Pagination token
  var query_602156 = newJObject()
  var body_602157 = newJObject()
  add(query_602156, "Limit", newJString(Limit))
  if body != nil:
    body_602157 = body
  add(query_602156, "ExclusiveStartKey", newJString(ExclusiveStartKey))
  result = call_602155.call(nil, query_602156, nil, nil, body_602157)

var scan* = Call_Scan_602140(name: "scan", meth: HttpMethod.HttpPost,
                          host: "dynamodb.amazonaws.com",
                          route: "/#X-Amz-Target=DynamoDB_20111205.Scan",
                          validator: validate_Scan_602141, base: "/", url: url_Scan_602142,
                          schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateItem_602158 = ref object of OpenApiRestCall_601389
proc url_UpdateItem_602160(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateItem_602159(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602161 = header.getOrDefault("X-Amz-Target")
  valid_602161 = validateParameter(valid_602161, JString, required = true, default = newJString(
      "DynamoDB_20111205.UpdateItem"))
  if valid_602161 != nil:
    section.add "X-Amz-Target", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-Signature")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Signature", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Content-Sha256", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-Date")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-Date", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Credential")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Credential", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Security-Token")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Security-Token", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Algorithm")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Algorithm", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-SignedHeaders", valid_602168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602170: Call_UpdateItem_602158; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Edits an existing item's attributes.</p> <p>You can perform a conditional update (insert a new attribute name-value pair if it doesn't exist, or replace an existing name-value pair if it has certain expected attribute values).</p>
  ## 
  let valid = call_602170.validator(path, query, header, formData, body)
  let scheme = call_602170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602170.url(scheme.get, call_602170.host, call_602170.base,
                         call_602170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602170, url, valid)

proc call*(call_602171: Call_UpdateItem_602158; body: JsonNode): Recallable =
  ## updateItem
  ## <p>Edits an existing item's attributes.</p> <p>You can perform a conditional update (insert a new attribute name-value pair if it doesn't exist, or replace an existing name-value pair if it has certain expected attribute values).</p>
  ##   body: JObject (required)
  var body_602172 = newJObject()
  if body != nil:
    body_602172 = body
  result = call_602171.call(nil, nil, nil, nil, body_602172)

var updateItem* = Call_UpdateItem_602158(name: "updateItem",
                                      meth: HttpMethod.HttpPost,
                                      host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.UpdateItem",
                                      validator: validate_UpdateItem_602159,
                                      base: "/", url: url_UpdateItem_602160,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTable_602173 = ref object of OpenApiRestCall_601389
proc url_UpdateTable_602175(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTable_602174(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602176 = header.getOrDefault("X-Amz-Target")
  valid_602176 = validateParameter(valid_602176, JString, required = true, default = newJString(
      "DynamoDB_20111205.UpdateTable"))
  if valid_602176 != nil:
    section.add "X-Amz-Target", valid_602176
  var valid_602177 = header.getOrDefault("X-Amz-Signature")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Signature", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Content-Sha256", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Date")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Date", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Credential")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Credential", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Security-Token")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Security-Token", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Algorithm")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Algorithm", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-SignedHeaders", valid_602183
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602185: Call_UpdateTable_602173; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the provisioned throughput for the given table.</p> <p>Setting the throughput for a table helps you manage performance and is part of the Provisioned Throughput feature of Amazon DynamoDB.</p>
  ## 
  let valid = call_602185.validator(path, query, header, formData, body)
  let scheme = call_602185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602185.url(scheme.get, call_602185.host, call_602185.base,
                         call_602185.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602185, url, valid)

proc call*(call_602186: Call_UpdateTable_602173; body: JsonNode): Recallable =
  ## updateTable
  ## <p>Updates the provisioned throughput for the given table.</p> <p>Setting the throughput for a table helps you manage performance and is part of the Provisioned Throughput feature of Amazon DynamoDB.</p>
  ##   body: JObject (required)
  var body_602187 = newJObject()
  if body != nil:
    body_602187 = body
  result = call_602186.call(nil, nil, nil, nil, body_602187)

var updateTable* = Call_UpdateTable_602173(name: "updateTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20111205.UpdateTable",
                                        validator: validate_UpdateTable_602174,
                                        base: "/", url: url_UpdateTable_602175,
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
