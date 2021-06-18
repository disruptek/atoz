
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon DynamoDB
## version: 2012-08-10
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon DynamoDB</fullname> <p>Amazon DynamoDB is a fully managed NoSQL database service that provides fast and predictable performance with seamless scalability. DynamoDB lets you offload the administrative burdens of operating and scaling a distributed database, so that you don't have to worry about hardware provisioning, setup and configuration, replication, software patching, or cluster scaling.</p> <p>With DynamoDB, you can create database tables that can store and retrieve any amount of data, and serve any level of request traffic. You can scale up or scale down your tables' throughput capacity without downtime or performance degradation, and use the AWS Management Console to monitor resource utilization and performance metrics.</p> <p>DynamoDB automatically spreads the data and traffic for your tables over a sufficient number of servers to handle your throughput and storage requirements, while maintaining consistent and fast performance. All of your data is stored on solid state disks (SSDs) and automatically replicated across multiple Availability Zones in an AWS region, providing built-in high availability and data durability. </p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/dynamodb/
type
  Scheme* {.pure.} = enum
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

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "dynamodb.ap-northeast-1.amazonaws.com", "ap-southeast-1": "dynamodb.ap-southeast-1.amazonaws.com",
                               "us-west-2": "dynamodb.us-west-2.amazonaws.com",
                               "eu-west-2": "dynamodb.eu-west-2.amazonaws.com", "ap-northeast-3": "dynamodb.ap-northeast-3.amazonaws.com", "eu-central-1": "dynamodb.eu-central-1.amazonaws.com",
                               "us-east-2": "dynamodb.us-east-2.amazonaws.com",
                               "us-east-1": "dynamodb.us-east-1.amazonaws.com", "cn-northwest-1": "dynamodb.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "dynamodb.ap-south-1.amazonaws.com", "eu-north-1": "dynamodb.eu-north-1.amazonaws.com", "ap-northeast-2": "dynamodb.ap-northeast-2.amazonaws.com",
                               "us-west-1": "dynamodb.us-west-1.amazonaws.com", "us-gov-east-1": "dynamodb.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "dynamodb.eu-west-3.amazonaws.com", "cn-north-1": "dynamodb.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "dynamodb.sa-east-1.amazonaws.com",
                               "eu-west-1": "dynamodb.eu-west-1.amazonaws.com", "us-gov-west-1": "dynamodb.us-gov-west-1.amazonaws.com", "ap-southeast-2": "dynamodb.ap-southeast-2.amazonaws.com", "ca-central-1": "dynamodb.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_BatchGetItem_402656294 = ref object of OpenApiRestCall_402656044
proc url_BatchGetItem_402656296(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetItem_402656295(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>The <code>BatchGetItem</code> operation returns the attributes of one or more items from one or more tables. You identify requested items by primary key.</p> <p>A single operation can retrieve up to 16 MB of data, which can contain as many as 100 items. <code>BatchGetItem</code> returns a partial result if the response size limit is exceeded, the table's provisioned throughput is exceeded, or an internal processing failure occurs. If a partial result is returned, the operation returns a value for <code>UnprocessedKeys</code>. You can use this value to retry the operation starting with the next item to get.</p> <important> <p>If you request more than 100 items, <code>BatchGetItem</code> returns a <code>ValidationException</code> with the message "Too many items requested for the BatchGetItem call."</p> </important> <p>For example, if you ask to retrieve 100 items, but each individual item is 300 KB in size, the system returns 52 items (so as not to exceed the 16 MB limit). It also returns an appropriate <code>UnprocessedKeys</code> value so you can get the next page of results. If desired, your application can include its own logic to assemble the pages of results into one dataset.</p> <p>If <i>none</i> of the items can be processed due to insufficient provisioned throughput on all of the tables in the request, then <code>BatchGetItem</code> returns a <code>ProvisionedThroughputExceededException</code>. If <i>at least one</i> of the items is successfully processed, then <code>BatchGetItem</code> completes successfully, while returning the keys of the unread items in <code>UnprocessedKeys</code>.</p> <important> <p>If DynamoDB returns any unprocessed items, you should retry the batch operation on those items. However, <i>we strongly recommend that you use an exponential backoff algorithm</i>. If you retry the batch operation immediately, the underlying read or write requests can still fail due to throttling on the individual tables. If you delay the batch operation using exponential backoff, the individual requests in the batch are much more likely to succeed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ErrorHandling.html#BatchOperations">Batch Operations and Error Handling</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p> </important> <p>By default, <code>BatchGetItem</code> performs eventually consistent reads on every table in the request. If you want strongly consistent reads instead, you can set <code>ConsistentRead</code> to <code>true</code> for any or all tables.</p> <p>In order to minimize response latency, <code>BatchGetItem</code> retrieves items in parallel.</p> <p>When designing your application, keep in mind that DynamoDB does not return items in any particular order. To help parse the response by item, include the primary key values for the items in your request in the <code>ProjectionExpression</code> parameter.</p> <p>If a requested item does not exist, it is not returned in the result. Requests for nonexistent items consume the minimum read capacity units according to the type of read. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/WorkingWithTables.html#CapacityUnitCalculations">Working with Tables</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   RequestItems: JString
                                  ##               : Pagination token
  section = newJObject()
  var valid_402656378 = query.getOrDefault("RequestItems")
  valid_402656378 = validateParameter(valid_402656378, JString,
                                      required = false, default = nil)
  if valid_402656378 != nil:
    section.add "RequestItems", valid_402656378
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656391 = header.getOrDefault("X-Amz-Target")
  valid_402656391 = validateParameter(valid_402656391, JString, required = true, default = newJString(
      "DynamoDB_20120810.BatchGetItem"))
  if valid_402656391 != nil:
    section.add "X-Amz-Target", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-Security-Token", valid_402656392
  var valid_402656393 = header.getOrDefault("X-Amz-Signature")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "X-Amz-Signature", valid_402656393
  var valid_402656394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656394 = validateParameter(valid_402656394, JString,
                                      required = false, default = nil)
  if valid_402656394 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656394
  var valid_402656395 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656395 = validateParameter(valid_402656395, JString,
                                      required = false, default = nil)
  if valid_402656395 != nil:
    section.add "X-Amz-Algorithm", valid_402656395
  var valid_402656396 = header.getOrDefault("X-Amz-Date")
  valid_402656396 = validateParameter(valid_402656396, JString,
                                      required = false, default = nil)
  if valid_402656396 != nil:
    section.add "X-Amz-Date", valid_402656396
  var valid_402656397 = header.getOrDefault("X-Amz-Credential")
  valid_402656397 = validateParameter(valid_402656397, JString,
                                      required = false, default = nil)
  if valid_402656397 != nil:
    section.add "X-Amz-Credential", valid_402656397
  var valid_402656398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656398 = validateParameter(valid_402656398, JString,
                                      required = false, default = nil)
  if valid_402656398 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656398
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

proc call*(call_402656413: Call_BatchGetItem_402656294; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>The <code>BatchGetItem</code> operation returns the attributes of one or more items from one or more tables. You identify requested items by primary key.</p> <p>A single operation can retrieve up to 16 MB of data, which can contain as many as 100 items. <code>BatchGetItem</code> returns a partial result if the response size limit is exceeded, the table's provisioned throughput is exceeded, or an internal processing failure occurs. If a partial result is returned, the operation returns a value for <code>UnprocessedKeys</code>. You can use this value to retry the operation starting with the next item to get.</p> <important> <p>If you request more than 100 items, <code>BatchGetItem</code> returns a <code>ValidationException</code> with the message "Too many items requested for the BatchGetItem call."</p> </important> <p>For example, if you ask to retrieve 100 items, but each individual item is 300 KB in size, the system returns 52 items (so as not to exceed the 16 MB limit). It also returns an appropriate <code>UnprocessedKeys</code> value so you can get the next page of results. If desired, your application can include its own logic to assemble the pages of results into one dataset.</p> <p>If <i>none</i> of the items can be processed due to insufficient provisioned throughput on all of the tables in the request, then <code>BatchGetItem</code> returns a <code>ProvisionedThroughputExceededException</code>. If <i>at least one</i> of the items is successfully processed, then <code>BatchGetItem</code> completes successfully, while returning the keys of the unread items in <code>UnprocessedKeys</code>.</p> <important> <p>If DynamoDB returns any unprocessed items, you should retry the batch operation on those items. However, <i>we strongly recommend that you use an exponential backoff algorithm</i>. If you retry the batch operation immediately, the underlying read or write requests can still fail due to throttling on the individual tables. If you delay the batch operation using exponential backoff, the individual requests in the batch are much more likely to succeed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ErrorHandling.html#BatchOperations">Batch Operations and Error Handling</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p> </important> <p>By default, <code>BatchGetItem</code> performs eventually consistent reads on every table in the request. If you want strongly consistent reads instead, you can set <code>ConsistentRead</code> to <code>true</code> for any or all tables.</p> <p>In order to minimize response latency, <code>BatchGetItem</code> retrieves items in parallel.</p> <p>When designing your application, keep in mind that DynamoDB does not return items in any particular order. To help parse the response by item, include the primary key values for the items in your request in the <code>ProjectionExpression</code> parameter.</p> <p>If a requested item does not exist, it is not returned in the result. Requests for nonexistent items consume the minimum read capacity units according to the type of read. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/WorkingWithTables.html#CapacityUnitCalculations">Working with Tables</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656413.validator(path, query, header, formData, body, _)
  let scheme = call_402656413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656413.makeUrl(scheme.get, call_402656413.host, call_402656413.base,
                                   call_402656413.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656413, uri, valid, _)

proc call*(call_402656462: Call_BatchGetItem_402656294; body: JsonNode;
           RequestItems: string = ""): Recallable =
  ## batchGetItem
  ## <p>The <code>BatchGetItem</code> operation returns the attributes of one or more items from one or more tables. You identify requested items by primary key.</p> <p>A single operation can retrieve up to 16 MB of data, which can contain as many as 100 items. <code>BatchGetItem</code> returns a partial result if the response size limit is exceeded, the table's provisioned throughput is exceeded, or an internal processing failure occurs. If a partial result is returned, the operation returns a value for <code>UnprocessedKeys</code>. You can use this value to retry the operation starting with the next item to get.</p> <important> <p>If you request more than 100 items, <code>BatchGetItem</code> returns a <code>ValidationException</code> with the message "Too many items requested for the BatchGetItem call."</p> </important> <p>For example, if you ask to retrieve 100 items, but each individual item is 300 KB in size, the system returns 52 items (so as not to exceed the 16 MB limit). It also returns an appropriate <code>UnprocessedKeys</code> value so you can get the next page of results. If desired, your application can include its own logic to assemble the pages of results into one dataset.</p> <p>If <i>none</i> of the items can be processed due to insufficient provisioned throughput on all of the tables in the request, then <code>BatchGetItem</code> returns a <code>ProvisionedThroughputExceededException</code>. If <i>at least one</i> of the items is successfully processed, then <code>BatchGetItem</code> completes successfully, while returning the keys of the unread items in <code>UnprocessedKeys</code>.</p> <important> <p>If DynamoDB returns any unprocessed items, you should retry the batch operation on those items. However, <i>we strongly recommend that you use an exponential backoff algorithm</i>. If you retry the batch operation immediately, the underlying read or write requests can still fail due to throttling on the individual tables. If you delay the batch operation using exponential backoff, the individual requests in the batch are much more likely to succeed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ErrorHandling.html#BatchOperations">Batch Operations and Error Handling</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p> </important> <p>By default, <code>BatchGetItem</code> performs eventually consistent reads on every table in the request. If you want strongly consistent reads instead, you can set <code>ConsistentRead</code> to <code>true</code> for any or all tables.</p> <p>In order to minimize response latency, <code>BatchGetItem</code> retrieves items in parallel.</p> <p>When designing your application, keep in mind that DynamoDB does not return items in any particular order. To help parse the response by item, include the primary key values for the items in your request in the <code>ProjectionExpression</code> parameter.</p> <p>If a requested item does not exist, it is not returned in the result. Requests for nonexistent items consume the minimum read capacity units according to the type of read. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/WorkingWithTables.html#CapacityUnitCalculations">Working with Tables</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## RequestItems: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ##               
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## token
  var query_402656463 = newJObject()
  var body_402656465 = newJObject()
  if body != nil:
    body_402656465 = body
  add(query_402656463, "RequestItems", newJString(RequestItems))
  result = call_402656462.call(nil, query_402656463, nil, nil, body_402656465)

var batchGetItem* = Call_BatchGetItem_402656294(name: "batchGetItem",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.BatchGetItem",
    validator: validate_BatchGetItem_402656295, base: "/",
    makeUrl: url_BatchGetItem_402656296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchWriteItem_402656491 = ref object of OpenApiRestCall_402656044
proc url_BatchWriteItem_402656493(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchWriteItem_402656492(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>The <code>BatchWriteItem</code> operation puts or deletes multiple items in one or more tables. A single call to <code>BatchWriteItem</code> can write up to 16 MB of data, which can comprise as many as 25 put or delete requests. Individual items to be written can be as large as 400 KB.</p> <note> <p> <code>BatchWriteItem</code> cannot update items. To update items, use the <code>UpdateItem</code> action.</p> </note> <p>The individual <code>PutItem</code> and <code>DeleteItem</code> operations specified in <code>BatchWriteItem</code> are atomic; however <code>BatchWriteItem</code> as a whole is not. If any requested operations fail because the table's provisioned throughput is exceeded or an internal processing failure occurs, the failed operations are returned in the <code>UnprocessedItems</code> response parameter. You can investigate and optionally resend the requests. Typically, you would call <code>BatchWriteItem</code> in a loop. Each iteration would check for unprocessed items and submit a new <code>BatchWriteItem</code> request with those unprocessed items until all items have been processed.</p> <p>If <i>none</i> of the items can be processed due to insufficient provisioned throughput on all of the tables in the request, then <code>BatchWriteItem</code> returns a <code>ProvisionedThroughputExceededException</code>.</p> <important> <p>If DynamoDB returns any unprocessed items, you should retry the batch operation on those items. However, <i>we strongly recommend that you use an exponential backoff algorithm</i>. If you retry the batch operation immediately, the underlying read or write requests can still fail due to throttling on the individual tables. If you delay the batch operation using exponential backoff, the individual requests in the batch are much more likely to succeed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ErrorHandling.html#Programming.Errors.BatchOperations">Batch Operations and Error Handling</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p> </important> <p>With <code>BatchWriteItem</code>, you can efficiently write or delete large amounts of data, such as from Amazon EMR, or copy data from another database into DynamoDB. In order to improve performance with these large-scale operations, <code>BatchWriteItem</code> does not behave in the same way as individual <code>PutItem</code> and <code>DeleteItem</code> calls would. For example, you cannot specify conditions on individual put and delete requests, and <code>BatchWriteItem</code> does not return deleted items in the response.</p> <p>If you use a programming language that supports concurrency, you can use threads to write items in parallel. Your application must include the necessary logic to manage the threads. With languages that don't support threading, you must update or delete the specified items one at a time. In both situations, <code>BatchWriteItem</code> performs the specified put and delete operations in parallel, giving you the power of the thread pool approach without having to introduce complexity into your application.</p> <p>Parallel processing reduces latency, but each specified put and delete request consumes the same number of write capacity units whether it is processed in parallel or not. Delete operations on nonexistent items consume one write capacity unit.</p> <p>If one or more of the following is true, DynamoDB rejects the entire batch write operation:</p> <ul> <li> <p>One or more tables specified in the <code>BatchWriteItem</code> request does not exist.</p> </li> <li> <p>Primary key attributes specified on an item in the request do not match those in the corresponding table's primary key schema.</p> </li> <li> <p>You try to perform multiple operations on the same item in the same <code>BatchWriteItem</code> request. For example, you cannot put and delete the same item in the same <code>BatchWriteItem</code> request. </p> </li> <li> <p> Your request contains at least two items with identical hash and range keys (which essentially is two put operations). </p> </li> <li> <p>There are more than 25 requests in the batch.</p> </li> <li> <p>Any individual item in a batch exceeds 400 KB.</p> </li> <li> <p>The total request size exceeds 16 MB.</p> </li> </ul>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656494 = header.getOrDefault("X-Amz-Target")
  valid_402656494 = validateParameter(valid_402656494, JString, required = true, default = newJString(
      "DynamoDB_20120810.BatchWriteItem"))
  if valid_402656494 != nil:
    section.add "X-Amz-Target", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Security-Token", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Signature")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Signature", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Algorithm", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-Date")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-Date", valid_402656499
  var valid_402656500 = header.getOrDefault("X-Amz-Credential")
  valid_402656500 = validateParameter(valid_402656500, JString,
                                      required = false, default = nil)
  if valid_402656500 != nil:
    section.add "X-Amz-Credential", valid_402656500
  var valid_402656501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656501
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

proc call*(call_402656503: Call_BatchWriteItem_402656491; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>The <code>BatchWriteItem</code> operation puts or deletes multiple items in one or more tables. A single call to <code>BatchWriteItem</code> can write up to 16 MB of data, which can comprise as many as 25 put or delete requests. Individual items to be written can be as large as 400 KB.</p> <note> <p> <code>BatchWriteItem</code> cannot update items. To update items, use the <code>UpdateItem</code> action.</p> </note> <p>The individual <code>PutItem</code> and <code>DeleteItem</code> operations specified in <code>BatchWriteItem</code> are atomic; however <code>BatchWriteItem</code> as a whole is not. If any requested operations fail because the table's provisioned throughput is exceeded or an internal processing failure occurs, the failed operations are returned in the <code>UnprocessedItems</code> response parameter. You can investigate and optionally resend the requests. Typically, you would call <code>BatchWriteItem</code> in a loop. Each iteration would check for unprocessed items and submit a new <code>BatchWriteItem</code> request with those unprocessed items until all items have been processed.</p> <p>If <i>none</i> of the items can be processed due to insufficient provisioned throughput on all of the tables in the request, then <code>BatchWriteItem</code> returns a <code>ProvisionedThroughputExceededException</code>.</p> <important> <p>If DynamoDB returns any unprocessed items, you should retry the batch operation on those items. However, <i>we strongly recommend that you use an exponential backoff algorithm</i>. If you retry the batch operation immediately, the underlying read or write requests can still fail due to throttling on the individual tables. If you delay the batch operation using exponential backoff, the individual requests in the batch are much more likely to succeed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ErrorHandling.html#Programming.Errors.BatchOperations">Batch Operations and Error Handling</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p> </important> <p>With <code>BatchWriteItem</code>, you can efficiently write or delete large amounts of data, such as from Amazon EMR, or copy data from another database into DynamoDB. In order to improve performance with these large-scale operations, <code>BatchWriteItem</code> does not behave in the same way as individual <code>PutItem</code> and <code>DeleteItem</code> calls would. For example, you cannot specify conditions on individual put and delete requests, and <code>BatchWriteItem</code> does not return deleted items in the response.</p> <p>If you use a programming language that supports concurrency, you can use threads to write items in parallel. Your application must include the necessary logic to manage the threads. With languages that don't support threading, you must update or delete the specified items one at a time. In both situations, <code>BatchWriteItem</code> performs the specified put and delete operations in parallel, giving you the power of the thread pool approach without having to introduce complexity into your application.</p> <p>Parallel processing reduces latency, but each specified put and delete request consumes the same number of write capacity units whether it is processed in parallel or not. Delete operations on nonexistent items consume one write capacity unit.</p> <p>If one or more of the following is true, DynamoDB rejects the entire batch write operation:</p> <ul> <li> <p>One or more tables specified in the <code>BatchWriteItem</code> request does not exist.</p> </li> <li> <p>Primary key attributes specified on an item in the request do not match those in the corresponding table's primary key schema.</p> </li> <li> <p>You try to perform multiple operations on the same item in the same <code>BatchWriteItem</code> request. For example, you cannot put and delete the same item in the same <code>BatchWriteItem</code> request. </p> </li> <li> <p> Your request contains at least two items with identical hash and range keys (which essentially is two put operations). </p> </li> <li> <p>There are more than 25 requests in the batch.</p> </li> <li> <p>Any individual item in a batch exceeds 400 KB.</p> </li> <li> <p>The total request size exceeds 16 MB.</p> </li> </ul>
                                                                                         ## 
  let valid = call_402656503.validator(path, query, header, formData, body, _)
  let scheme = call_402656503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656503.makeUrl(scheme.get, call_402656503.host, call_402656503.base,
                                   call_402656503.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656503, uri, valid, _)

proc call*(call_402656504: Call_BatchWriteItem_402656491; body: JsonNode): Recallable =
  ## batchWriteItem
  ## <p>The <code>BatchWriteItem</code> operation puts or deletes multiple items in one or more tables. A single call to <code>BatchWriteItem</code> can write up to 16 MB of data, which can comprise as many as 25 put or delete requests. Individual items to be written can be as large as 400 KB.</p> <note> <p> <code>BatchWriteItem</code> cannot update items. To update items, use the <code>UpdateItem</code> action.</p> </note> <p>The individual <code>PutItem</code> and <code>DeleteItem</code> operations specified in <code>BatchWriteItem</code> are atomic; however <code>BatchWriteItem</code> as a whole is not. If any requested operations fail because the table's provisioned throughput is exceeded or an internal processing failure occurs, the failed operations are returned in the <code>UnprocessedItems</code> response parameter. You can investigate and optionally resend the requests. Typically, you would call <code>BatchWriteItem</code> in a loop. Each iteration would check for unprocessed items and submit a new <code>BatchWriteItem</code> request with those unprocessed items until all items have been processed.</p> <p>If <i>none</i> of the items can be processed due to insufficient provisioned throughput on all of the tables in the request, then <code>BatchWriteItem</code> returns a <code>ProvisionedThroughputExceededException</code>.</p> <important> <p>If DynamoDB returns any unprocessed items, you should retry the batch operation on those items. However, <i>we strongly recommend that you use an exponential backoff algorithm</i>. If you retry the batch operation immediately, the underlying read or write requests can still fail due to throttling on the individual tables. If you delay the batch operation using exponential backoff, the individual requests in the batch are much more likely to succeed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ErrorHandling.html#Programming.Errors.BatchOperations">Batch Operations and Error Handling</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p> </important> <p>With <code>BatchWriteItem</code>, you can efficiently write or delete large amounts of data, such as from Amazon EMR, or copy data from another database into DynamoDB. In order to improve performance with these large-scale operations, <code>BatchWriteItem</code> does not behave in the same way as individual <code>PutItem</code> and <code>DeleteItem</code> calls would. For example, you cannot specify conditions on individual put and delete requests, and <code>BatchWriteItem</code> does not return deleted items in the response.</p> <p>If you use a programming language that supports concurrency, you can use threads to write items in parallel. Your application must include the necessary logic to manage the threads. With languages that don't support threading, you must update or delete the specified items one at a time. In both situations, <code>BatchWriteItem</code> performs the specified put and delete operations in parallel, giving you the power of the thread pool approach without having to introduce complexity into your application.</p> <p>Parallel processing reduces latency, but each specified put and delete request consumes the same number of write capacity units whether it is processed in parallel or not. Delete operations on nonexistent items consume one write capacity unit.</p> <p>If one or more of the following is true, DynamoDB rejects the entire batch write operation:</p> <ul> <li> <p>One or more tables specified in the <code>BatchWriteItem</code> request does not exist.</p> </li> <li> <p>Primary key attributes specified on an item in the request do not match those in the corresponding table's primary key schema.</p> </li> <li> <p>You try to perform multiple operations on the same item in the same <code>BatchWriteItem</code> request. For example, you cannot put and delete the same item in the same <code>BatchWriteItem</code> request. </p> </li> <li> <p> Your request contains at least two items with identical hash and range keys (which essentially is two put operations). </p> </li> <li> <p>There are more than 25 requests in the batch.</p> </li> <li> <p>Any individual item in a batch exceeds 400 KB.</p> </li> <li> <p>The total request size exceeds 16 MB.</p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402656505 = newJObject()
  if body != nil:
    body_402656505 = body
  result = call_402656504.call(nil, nil, nil, nil, body_402656505)

var batchWriteItem* = Call_BatchWriteItem_402656491(name: "batchWriteItem",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.BatchWriteItem",
    validator: validate_BatchWriteItem_402656492, base: "/",
    makeUrl: url_BatchWriteItem_402656493, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackup_402656506 = ref object of OpenApiRestCall_402656044
proc url_CreateBackup_402656508(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateBackup_402656507(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a backup for an existing table.</p> <p> Each time you create an on-demand backup, the entire table data is backed up. There is no limit to the number of on-demand backups that can be taken. </p> <p> When you create an on-demand backup, a time marker of the request is cataloged, and the backup is created asynchronously, by applying all changes until the time of the request to the last full table snapshot. Backup requests are processed instantaneously and become available for restore within minutes. </p> <p>You can call <code>CreateBackup</code> at a maximum rate of 50 times per second.</p> <p>All backups in DynamoDB work without consuming any provisioned throughput on the table.</p> <p> If you submit a backup request on 2018-12-14 at 14:25:00, the backup is guaranteed to contain all data committed to the table up to 14:24:00, and data committed after 14:26:00 will not be. The backup might contain data modifications made between 14:24:00 and 14:26:00. On-demand backup does not support causal consistency. </p> <p> Along with data, the following are also included on the backups: </p> <ul> <li> <p>Global secondary indexes (GSIs)</p> </li> <li> <p>Local secondary indexes (LSIs)</p> </li> <li> <p>Streams</p> </li> <li> <p>Provisioned read and write capacity</p> </li> </ul>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656509 = header.getOrDefault("X-Amz-Target")
  valid_402656509 = validateParameter(valid_402656509, JString, required = true, default = newJString(
      "DynamoDB_20120810.CreateBackup"))
  if valid_402656509 != nil:
    section.add "X-Amz-Target", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Security-Token", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Signature")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Signature", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Algorithm", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-Date")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-Date", valid_402656514
  var valid_402656515 = header.getOrDefault("X-Amz-Credential")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-Credential", valid_402656515
  var valid_402656516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656516 = validateParameter(valid_402656516, JString,
                                      required = false, default = nil)
  if valid_402656516 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656516
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

proc call*(call_402656518: Call_CreateBackup_402656506; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a backup for an existing table.</p> <p> Each time you create an on-demand backup, the entire table data is backed up. There is no limit to the number of on-demand backups that can be taken. </p> <p> When you create an on-demand backup, a time marker of the request is cataloged, and the backup is created asynchronously, by applying all changes until the time of the request to the last full table snapshot. Backup requests are processed instantaneously and become available for restore within minutes. </p> <p>You can call <code>CreateBackup</code> at a maximum rate of 50 times per second.</p> <p>All backups in DynamoDB work without consuming any provisioned throughput on the table.</p> <p> If you submit a backup request on 2018-12-14 at 14:25:00, the backup is guaranteed to contain all data committed to the table up to 14:24:00, and data committed after 14:26:00 will not be. The backup might contain data modifications made between 14:24:00 and 14:26:00. On-demand backup does not support causal consistency. </p> <p> Along with data, the following are also included on the backups: </p> <ul> <li> <p>Global secondary indexes (GSIs)</p> </li> <li> <p>Local secondary indexes (LSIs)</p> </li> <li> <p>Streams</p> </li> <li> <p>Provisioned read and write capacity</p> </li> </ul>
                                                                                         ## 
  let valid = call_402656518.validator(path, query, header, formData, body, _)
  let scheme = call_402656518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656518.makeUrl(scheme.get, call_402656518.host, call_402656518.base,
                                   call_402656518.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656518, uri, valid, _)

proc call*(call_402656519: Call_CreateBackup_402656506; body: JsonNode): Recallable =
  ## createBackup
  ## <p>Creates a backup for an existing table.</p> <p> Each time you create an on-demand backup, the entire table data is backed up. There is no limit to the number of on-demand backups that can be taken. </p> <p> When you create an on-demand backup, a time marker of the request is cataloged, and the backup is created asynchronously, by applying all changes until the time of the request to the last full table snapshot. Backup requests are processed instantaneously and become available for restore within minutes. </p> <p>You can call <code>CreateBackup</code> at a maximum rate of 50 times per second.</p> <p>All backups in DynamoDB work without consuming any provisioned throughput on the table.</p> <p> If you submit a backup request on 2018-12-14 at 14:25:00, the backup is guaranteed to contain all data committed to the table up to 14:24:00, and data committed after 14:26:00 will not be. The backup might contain data modifications made between 14:24:00 and 14:26:00. On-demand backup does not support causal consistency. </p> <p> Along with data, the following are also included on the backups: </p> <ul> <li> <p>Global secondary indexes (GSIs)</p> </li> <li> <p>Local secondary indexes (LSIs)</p> </li> <li> <p>Streams</p> </li> <li> <p>Provisioned read and write capacity</p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402656520 = newJObject()
  if body != nil:
    body_402656520 = body
  result = call_402656519.call(nil, nil, nil, nil, body_402656520)

var createBackup* = Call_CreateBackup_402656506(name: "createBackup",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.CreateBackup",
    validator: validate_CreateBackup_402656507, base: "/",
    makeUrl: url_CreateBackup_402656508, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGlobalTable_402656521 = ref object of OpenApiRestCall_402656044
proc url_CreateGlobalTable_402656523(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGlobalTable_402656522(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a global table from an existing table. A global table creates a replication relationship between two or more DynamoDB tables with the same table name in the provided Regions. </p> <note> <p>This method only applies to <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V1.html">Version 2017.11.29</a> of global tables.</p> </note> <p>If you want to add a new replica table to a global table, each of the following conditions must be true:</p> <ul> <li> <p>The table must have the same primary key as all of the other replicas.</p> </li> <li> <p>The table must have the same name as all of the other replicas.</p> </li> <li> <p>The table must have DynamoDB Streams enabled, with the stream containing both the new and the old images of the item.</p> </li> <li> <p>None of the replica tables in the global table can contain any data.</p> </li> </ul> <p> If global secondary indexes are specified, then the following conditions must also be met: </p> <ul> <li> <p> The global secondary indexes must have the same name. </p> </li> <li> <p> The global secondary indexes must have the same hash key and sort key (if present). </p> </li> </ul> <important> <p> Write capacity settings should be set consistently across your replica tables and secondary indexes. DynamoDB strongly recommends enabling auto scaling to manage the write capacity settings for all of your global tables replicas and indexes. </p> <p> If you prefer to manage write capacity settings manually, you should provision equal replicated write capacity units to your replica tables. You should also provision equal replicated write capacity units to matching secondary indexes across your global table. </p> </important>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656524 = header.getOrDefault("X-Amz-Target")
  valid_402656524 = validateParameter(valid_402656524, JString, required = true, default = newJString(
      "DynamoDB_20120810.CreateGlobalTable"))
  if valid_402656524 != nil:
    section.add "X-Amz-Target", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Security-Token", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Signature")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Signature", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Algorithm", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-Date")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-Date", valid_402656529
  var valid_402656530 = header.getOrDefault("X-Amz-Credential")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "X-Amz-Credential", valid_402656530
  var valid_402656531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656531 = validateParameter(valid_402656531, JString,
                                      required = false, default = nil)
  if valid_402656531 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656531
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

proc call*(call_402656533: Call_CreateGlobalTable_402656521;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a global table from an existing table. A global table creates a replication relationship between two or more DynamoDB tables with the same table name in the provided Regions. </p> <note> <p>This method only applies to <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V1.html">Version 2017.11.29</a> of global tables.</p> </note> <p>If you want to add a new replica table to a global table, each of the following conditions must be true:</p> <ul> <li> <p>The table must have the same primary key as all of the other replicas.</p> </li> <li> <p>The table must have the same name as all of the other replicas.</p> </li> <li> <p>The table must have DynamoDB Streams enabled, with the stream containing both the new and the old images of the item.</p> </li> <li> <p>None of the replica tables in the global table can contain any data.</p> </li> </ul> <p> If global secondary indexes are specified, then the following conditions must also be met: </p> <ul> <li> <p> The global secondary indexes must have the same name. </p> </li> <li> <p> The global secondary indexes must have the same hash key and sort key (if present). </p> </li> </ul> <important> <p> Write capacity settings should be set consistently across your replica tables and secondary indexes. DynamoDB strongly recommends enabling auto scaling to manage the write capacity settings for all of your global tables replicas and indexes. </p> <p> If you prefer to manage write capacity settings manually, you should provision equal replicated write capacity units to your replica tables. You should also provision equal replicated write capacity units to matching secondary indexes across your global table. </p> </important>
                                                                                         ## 
  let valid = call_402656533.validator(path, query, header, formData, body, _)
  let scheme = call_402656533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656533.makeUrl(scheme.get, call_402656533.host, call_402656533.base,
                                   call_402656533.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656533, uri, valid, _)

proc call*(call_402656534: Call_CreateGlobalTable_402656521; body: JsonNode): Recallable =
  ## createGlobalTable
  ## <p>Creates a global table from an existing table. A global table creates a replication relationship between two or more DynamoDB tables with the same table name in the provided Regions. </p> <note> <p>This method only applies to <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V1.html">Version 2017.11.29</a> of global tables.</p> </note> <p>If you want to add a new replica table to a global table, each of the following conditions must be true:</p> <ul> <li> <p>The table must have the same primary key as all of the other replicas.</p> </li> <li> <p>The table must have the same name as all of the other replicas.</p> </li> <li> <p>The table must have DynamoDB Streams enabled, with the stream containing both the new and the old images of the item.</p> </li> <li> <p>None of the replica tables in the global table can contain any data.</p> </li> </ul> <p> If global secondary indexes are specified, then the following conditions must also be met: </p> <ul> <li> <p> The global secondary indexes must have the same name. </p> </li> <li> <p> The global secondary indexes must have the same hash key and sort key (if present). </p> </li> </ul> <important> <p> Write capacity settings should be set consistently across your replica tables and secondary indexes. DynamoDB strongly recommends enabling auto scaling to manage the write capacity settings for all of your global tables replicas and indexes. </p> <p> If you prefer to manage write capacity settings manually, you should provision equal replicated write capacity units to your replica tables. You should also provision equal replicated write capacity units to matching secondary indexes across your global table. </p> </important>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402656535 = newJObject()
  if body != nil:
    body_402656535 = body
  result = call_402656534.call(nil, nil, nil, nil, body_402656535)

var createGlobalTable* = Call_CreateGlobalTable_402656521(
    name: "createGlobalTable", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.CreateGlobalTable",
    validator: validate_CreateGlobalTable_402656522, base: "/",
    makeUrl: url_CreateGlobalTable_402656523,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTable_402656536 = ref object of OpenApiRestCall_402656044
proc url_CreateTable_402656538(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTable_402656537(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>The <code>CreateTable</code> operation adds a new table to your account. In an AWS account, table names must be unique within each Region. That is, you can have two tables with same name if you create the tables in different Regions.</p> <p> <code>CreateTable</code> is an asynchronous operation. Upon receiving a <code>CreateTable</code> request, DynamoDB immediately returns a response with a <code>TableStatus</code> of <code>CREATING</code>. After the table is created, DynamoDB sets the <code>TableStatus</code> to <code>ACTIVE</code>. You can perform read and write operations only on an <code>ACTIVE</code> table. </p> <p>You can optionally define secondary indexes on the new table, as part of the <code>CreateTable</code> operation. If you want to create multiple tables with secondary indexes on them, you must create the tables sequentially. Only one table with secondary indexes can be in the <code>CREATING</code> state at any given time.</p> <p>You can use the <code>DescribeTable</code> action to check the table status.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656539 = header.getOrDefault("X-Amz-Target")
  valid_402656539 = validateParameter(valid_402656539, JString, required = true, default = newJString(
      "DynamoDB_20120810.CreateTable"))
  if valid_402656539 != nil:
    section.add "X-Amz-Target", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Security-Token", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Signature")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Signature", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Algorithm", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-Date")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-Date", valid_402656544
  var valid_402656545 = header.getOrDefault("X-Amz-Credential")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-Credential", valid_402656545
  var valid_402656546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656546
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

proc call*(call_402656548: Call_CreateTable_402656536; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>The <code>CreateTable</code> operation adds a new table to your account. In an AWS account, table names must be unique within each Region. That is, you can have two tables with same name if you create the tables in different Regions.</p> <p> <code>CreateTable</code> is an asynchronous operation. Upon receiving a <code>CreateTable</code> request, DynamoDB immediately returns a response with a <code>TableStatus</code> of <code>CREATING</code>. After the table is created, DynamoDB sets the <code>TableStatus</code> to <code>ACTIVE</code>. You can perform read and write operations only on an <code>ACTIVE</code> table. </p> <p>You can optionally define secondary indexes on the new table, as part of the <code>CreateTable</code> operation. If you want to create multiple tables with secondary indexes on them, you must create the tables sequentially. Only one table with secondary indexes can be in the <code>CREATING</code> state at any given time.</p> <p>You can use the <code>DescribeTable</code> action to check the table status.</p>
                                                                                         ## 
  let valid = call_402656548.validator(path, query, header, formData, body, _)
  let scheme = call_402656548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656548.makeUrl(scheme.get, call_402656548.host, call_402656548.base,
                                   call_402656548.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656548, uri, valid, _)

proc call*(call_402656549: Call_CreateTable_402656536; body: JsonNode): Recallable =
  ## createTable
  ## <p>The <code>CreateTable</code> operation adds a new table to your account. In an AWS account, table names must be unique within each Region. That is, you can have two tables with same name if you create the tables in different Regions.</p> <p> <code>CreateTable</code> is an asynchronous operation. Upon receiving a <code>CreateTable</code> request, DynamoDB immediately returns a response with a <code>TableStatus</code> of <code>CREATING</code>. After the table is created, DynamoDB sets the <code>TableStatus</code> to <code>ACTIVE</code>. You can perform read and write operations only on an <code>ACTIVE</code> table. </p> <p>You can optionally define secondary indexes on the new table, as part of the <code>CreateTable</code> operation. If you want to create multiple tables with secondary indexes on them, you must create the tables sequentially. Only one table with secondary indexes can be in the <code>CREATING</code> state at any given time.</p> <p>You can use the <code>DescribeTable</code> action to check the table status.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402656550 = newJObject()
  if body != nil:
    body_402656550 = body
  result = call_402656549.call(nil, nil, nil, nil, body_402656550)

var createTable* = Call_CreateTable_402656536(name: "createTable",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.CreateTable",
    validator: validate_CreateTable_402656537, base: "/",
    makeUrl: url_CreateTable_402656538, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackup_402656551 = ref object of OpenApiRestCall_402656044
proc url_DeleteBackup_402656553(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteBackup_402656552(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes an existing backup of a table.</p> <p>You can call <code>DeleteBackup</code> at a maximum rate of 10 times per second.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656554 = header.getOrDefault("X-Amz-Target")
  valid_402656554 = validateParameter(valid_402656554, JString, required = true, default = newJString(
      "DynamoDB_20120810.DeleteBackup"))
  if valid_402656554 != nil:
    section.add "X-Amz-Target", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Security-Token", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Signature")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Signature", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Algorithm", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-Date")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-Date", valid_402656559
  var valid_402656560 = header.getOrDefault("X-Amz-Credential")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "X-Amz-Credential", valid_402656560
  var valid_402656561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656561
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

proc call*(call_402656563: Call_DeleteBackup_402656551; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes an existing backup of a table.</p> <p>You can call <code>DeleteBackup</code> at a maximum rate of 10 times per second.</p>
                                                                                         ## 
  let valid = call_402656563.validator(path, query, header, formData, body, _)
  let scheme = call_402656563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656563.makeUrl(scheme.get, call_402656563.host, call_402656563.base,
                                   call_402656563.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656563, uri, valid, _)

proc call*(call_402656564: Call_DeleteBackup_402656551; body: JsonNode): Recallable =
  ## deleteBackup
  ## <p>Deletes an existing backup of a table.</p> <p>You can call <code>DeleteBackup</code> at a maximum rate of 10 times per second.</p>
  ##   
                                                                                                                                          ## body: JObject (required)
  var body_402656565 = newJObject()
  if body != nil:
    body_402656565 = body
  result = call_402656564.call(nil, nil, nil, nil, body_402656565)

var deleteBackup* = Call_DeleteBackup_402656551(name: "deleteBackup",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DeleteBackup",
    validator: validate_DeleteBackup_402656552, base: "/",
    makeUrl: url_DeleteBackup_402656553, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteItem_402656566 = ref object of OpenApiRestCall_402656044
proc url_DeleteItem_402656568(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteItem_402656567(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes a single item in a table by primary key. You can perform a conditional delete operation that deletes the item if it exists, or if it has an expected attribute value.</p> <p>In addition to deleting an item, you can also return the item's attribute values in the same operation, using the <code>ReturnValues</code> parameter.</p> <p>Unless you specify conditions, the <code>DeleteItem</code> is an idempotent operation; running it multiple times on the same item or attribute does <i>not</i> result in an error response.</p> <p>Conditional deletes are useful for deleting items only if specific conditions are met. If those conditions are met, DynamoDB performs the delete. Otherwise, the item is not deleted.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656569 = header.getOrDefault("X-Amz-Target")
  valid_402656569 = validateParameter(valid_402656569, JString, required = true, default = newJString(
      "DynamoDB_20120810.DeleteItem"))
  if valid_402656569 != nil:
    section.add "X-Amz-Target", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Security-Token", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Signature")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Signature", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Algorithm", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-Date")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-Date", valid_402656574
  var valid_402656575 = header.getOrDefault("X-Amz-Credential")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "X-Amz-Credential", valid_402656575
  var valid_402656576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656576
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

proc call*(call_402656578: Call_DeleteItem_402656566; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a single item in a table by primary key. You can perform a conditional delete operation that deletes the item if it exists, or if it has an expected attribute value.</p> <p>In addition to deleting an item, you can also return the item's attribute values in the same operation, using the <code>ReturnValues</code> parameter.</p> <p>Unless you specify conditions, the <code>DeleteItem</code> is an idempotent operation; running it multiple times on the same item or attribute does <i>not</i> result in an error response.</p> <p>Conditional deletes are useful for deleting items only if specific conditions are met. If those conditions are met, DynamoDB performs the delete. Otherwise, the item is not deleted.</p>
                                                                                         ## 
  let valid = call_402656578.validator(path, query, header, formData, body, _)
  let scheme = call_402656578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656578.makeUrl(scheme.get, call_402656578.host, call_402656578.base,
                                   call_402656578.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656578, uri, valid, _)

proc call*(call_402656579: Call_DeleteItem_402656566; body: JsonNode): Recallable =
  ## deleteItem
  ## <p>Deletes a single item in a table by primary key. You can perform a conditional delete operation that deletes the item if it exists, or if it has an expected attribute value.</p> <p>In addition to deleting an item, you can also return the item's attribute values in the same operation, using the <code>ReturnValues</code> parameter.</p> <p>Unless you specify conditions, the <code>DeleteItem</code> is an idempotent operation; running it multiple times on the same item or attribute does <i>not</i> result in an error response.</p> <p>Conditional deletes are useful for deleting items only if specific conditions are met. If those conditions are met, DynamoDB performs the delete. Otherwise, the item is not deleted.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402656580 = newJObject()
  if body != nil:
    body_402656580 = body
  result = call_402656579.call(nil, nil, nil, nil, body_402656580)

var deleteItem* = Call_DeleteItem_402656566(name: "deleteItem",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DeleteItem",
    validator: validate_DeleteItem_402656567, base: "/",
    makeUrl: url_DeleteItem_402656568, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTable_402656581 = ref object of OpenApiRestCall_402656044
proc url_DeleteTable_402656583(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTable_402656582(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>The <code>DeleteTable</code> operation deletes a table and all of its items. After a <code>DeleteTable</code> request, the specified table is in the <code>DELETING</code> state until DynamoDB completes the deletion. If the table is in the <code>ACTIVE</code> state, you can delete it. If a table is in <code>CREATING</code> or <code>UPDATING</code> states, then DynamoDB returns a <code>ResourceInUseException</code>. If the specified table does not exist, DynamoDB returns a <code>ResourceNotFoundException</code>. If table is already in the <code>DELETING</code> state, no error is returned. </p> <note> <p>DynamoDB might continue to accept data read and write operations, such as <code>GetItem</code> and <code>PutItem</code>, on a table in the <code>DELETING</code> state until the table deletion is complete.</p> </note> <p>When you delete a table, any indexes on that table are also deleted.</p> <p>If you have DynamoDB Streams enabled on the table, then the corresponding stream on that table goes into the <code>DISABLED</code> state, and the stream is automatically deleted after 24 hours.</p> <p>Use the <code>DescribeTable</code> action to check the status of the table. </p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656584 = header.getOrDefault("X-Amz-Target")
  valid_402656584 = validateParameter(valid_402656584, JString, required = true, default = newJString(
      "DynamoDB_20120810.DeleteTable"))
  if valid_402656584 != nil:
    section.add "X-Amz-Target", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Security-Token", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Signature")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Signature", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Algorithm", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-Date")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-Date", valid_402656589
  var valid_402656590 = header.getOrDefault("X-Amz-Credential")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "X-Amz-Credential", valid_402656590
  var valid_402656591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656591
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

proc call*(call_402656593: Call_DeleteTable_402656581; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>The <code>DeleteTable</code> operation deletes a table and all of its items. After a <code>DeleteTable</code> request, the specified table is in the <code>DELETING</code> state until DynamoDB completes the deletion. If the table is in the <code>ACTIVE</code> state, you can delete it. If a table is in <code>CREATING</code> or <code>UPDATING</code> states, then DynamoDB returns a <code>ResourceInUseException</code>. If the specified table does not exist, DynamoDB returns a <code>ResourceNotFoundException</code>. If table is already in the <code>DELETING</code> state, no error is returned. </p> <note> <p>DynamoDB might continue to accept data read and write operations, such as <code>GetItem</code> and <code>PutItem</code>, on a table in the <code>DELETING</code> state until the table deletion is complete.</p> </note> <p>When you delete a table, any indexes on that table are also deleted.</p> <p>If you have DynamoDB Streams enabled on the table, then the corresponding stream on that table goes into the <code>DISABLED</code> state, and the stream is automatically deleted after 24 hours.</p> <p>Use the <code>DescribeTable</code> action to check the status of the table. </p>
                                                                                         ## 
  let valid = call_402656593.validator(path, query, header, formData, body, _)
  let scheme = call_402656593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656593.makeUrl(scheme.get, call_402656593.host, call_402656593.base,
                                   call_402656593.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656593, uri, valid, _)

proc call*(call_402656594: Call_DeleteTable_402656581; body: JsonNode): Recallable =
  ## deleteTable
  ## <p>The <code>DeleteTable</code> operation deletes a table and all of its items. After a <code>DeleteTable</code> request, the specified table is in the <code>DELETING</code> state until DynamoDB completes the deletion. If the table is in the <code>ACTIVE</code> state, you can delete it. If a table is in <code>CREATING</code> or <code>UPDATING</code> states, then DynamoDB returns a <code>ResourceInUseException</code>. If the specified table does not exist, DynamoDB returns a <code>ResourceNotFoundException</code>. If table is already in the <code>DELETING</code> state, no error is returned. </p> <note> <p>DynamoDB might continue to accept data read and write operations, such as <code>GetItem</code> and <code>PutItem</code>, on a table in the <code>DELETING</code> state until the table deletion is complete.</p> </note> <p>When you delete a table, any indexes on that table are also deleted.</p> <p>If you have DynamoDB Streams enabled on the table, then the corresponding stream on that table goes into the <code>DISABLED</code> state, and the stream is automatically deleted after 24 hours.</p> <p>Use the <code>DescribeTable</code> action to check the status of the table. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656595 = newJObject()
  if body != nil:
    body_402656595 = body
  result = call_402656594.call(nil, nil, nil, nil, body_402656595)

var deleteTable* = Call_DeleteTable_402656581(name: "deleteTable",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DeleteTable",
    validator: validate_DeleteTable_402656582, base: "/",
    makeUrl: url_DeleteTable_402656583, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBackup_402656596 = ref object of OpenApiRestCall_402656044
proc url_DescribeBackup_402656598(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeBackup_402656597(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Describes an existing backup of a table.</p> <p>You can call <code>DescribeBackup</code> at a maximum rate of 10 times per second.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656599 = header.getOrDefault("X-Amz-Target")
  valid_402656599 = validateParameter(valid_402656599, JString, required = true, default = newJString(
      "DynamoDB_20120810.DescribeBackup"))
  if valid_402656599 != nil:
    section.add "X-Amz-Target", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Security-Token", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Signature")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Signature", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Algorithm", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-Date")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-Date", valid_402656604
  var valid_402656605 = header.getOrDefault("X-Amz-Credential")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "X-Amz-Credential", valid_402656605
  var valid_402656606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656606
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

proc call*(call_402656608: Call_DescribeBackup_402656596; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes an existing backup of a table.</p> <p>You can call <code>DescribeBackup</code> at a maximum rate of 10 times per second.</p>
                                                                                         ## 
  let valid = call_402656608.validator(path, query, header, formData, body, _)
  let scheme = call_402656608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656608.makeUrl(scheme.get, call_402656608.host, call_402656608.base,
                                   call_402656608.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656608, uri, valid, _)

proc call*(call_402656609: Call_DescribeBackup_402656596; body: JsonNode): Recallable =
  ## describeBackup
  ## <p>Describes an existing backup of a table.</p> <p>You can call <code>DescribeBackup</code> at a maximum rate of 10 times per second.</p>
  ##   
                                                                                                                                              ## body: JObject (required)
  var body_402656610 = newJObject()
  if body != nil:
    body_402656610 = body
  result = call_402656609.call(nil, nil, nil, nil, body_402656610)

var describeBackup* = Call_DescribeBackup_402656596(name: "describeBackup",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DescribeBackup",
    validator: validate_DescribeBackup_402656597, base: "/",
    makeUrl: url_DescribeBackup_402656598, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeContinuousBackups_402656611 = ref object of OpenApiRestCall_402656044
proc url_DescribeContinuousBackups_402656613(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeContinuousBackups_402656612(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Checks the status of continuous backups and point in time recovery on the specified table. Continuous backups are <code>ENABLED</code> on all tables at table creation. If point in time recovery is enabled, <code>PointInTimeRecoveryStatus</code> will be set to ENABLED.</p> <p> After continuous backups and point in time recovery are enabled, you can restore to any point in time within <code>EarliestRestorableDateTime</code> and <code>LatestRestorableDateTime</code>. </p> <p> <code>LatestRestorableDateTime</code> is typically 5 minutes before the current time. You can restore your table to any point in time during the last 35 days. </p> <p>You can call <code>DescribeContinuousBackups</code> at a maximum rate of 10 times per second.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656614 = header.getOrDefault("X-Amz-Target")
  valid_402656614 = validateParameter(valid_402656614, JString, required = true, default = newJString(
      "DynamoDB_20120810.DescribeContinuousBackups"))
  if valid_402656614 != nil:
    section.add "X-Amz-Target", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Security-Token", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Signature")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Signature", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Algorithm", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-Date")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-Date", valid_402656619
  var valid_402656620 = header.getOrDefault("X-Amz-Credential")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "X-Amz-Credential", valid_402656620
  var valid_402656621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656621
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

proc call*(call_402656623: Call_DescribeContinuousBackups_402656611;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Checks the status of continuous backups and point in time recovery on the specified table. Continuous backups are <code>ENABLED</code> on all tables at table creation. If point in time recovery is enabled, <code>PointInTimeRecoveryStatus</code> will be set to ENABLED.</p> <p> After continuous backups and point in time recovery are enabled, you can restore to any point in time within <code>EarliestRestorableDateTime</code> and <code>LatestRestorableDateTime</code>. </p> <p> <code>LatestRestorableDateTime</code> is typically 5 minutes before the current time. You can restore your table to any point in time during the last 35 days. </p> <p>You can call <code>DescribeContinuousBackups</code> at a maximum rate of 10 times per second.</p>
                                                                                         ## 
  let valid = call_402656623.validator(path, query, header, formData, body, _)
  let scheme = call_402656623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656623.makeUrl(scheme.get, call_402656623.host, call_402656623.base,
                                   call_402656623.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656623, uri, valid, _)

proc call*(call_402656624: Call_DescribeContinuousBackups_402656611;
           body: JsonNode): Recallable =
  ## describeContinuousBackups
  ## <p>Checks the status of continuous backups and point in time recovery on the specified table. Continuous backups are <code>ENABLED</code> on all tables at table creation. If point in time recovery is enabled, <code>PointInTimeRecoveryStatus</code> will be set to ENABLED.</p> <p> After continuous backups and point in time recovery are enabled, you can restore to any point in time within <code>EarliestRestorableDateTime</code> and <code>LatestRestorableDateTime</code>. </p> <p> <code>LatestRestorableDateTime</code> is typically 5 minutes before the current time. You can restore your table to any point in time during the last 35 days. </p> <p>You can call <code>DescribeContinuousBackups</code> at a maximum rate of 10 times per second.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656625 = newJObject()
  if body != nil:
    body_402656625 = body
  result = call_402656624.call(nil, nil, nil, nil, body_402656625)

var describeContinuousBackups* = Call_DescribeContinuousBackups_402656611(
    name: "describeContinuousBackups", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DescribeContinuousBackups",
    validator: validate_DescribeContinuousBackups_402656612, base: "/",
    makeUrl: url_DescribeContinuousBackups_402656613,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeContributorInsights_402656626 = ref object of OpenApiRestCall_402656044
proc url_DescribeContributorInsights_402656628(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeContributorInsights_402656627(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns information about contributor insights, for a given table or global secondary index.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656629 = header.getOrDefault("X-Amz-Target")
  valid_402656629 = validateParameter(valid_402656629, JString, required = true, default = newJString(
      "DynamoDB_20120810.DescribeContributorInsights"))
  if valid_402656629 != nil:
    section.add "X-Amz-Target", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Security-Token", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Signature")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Signature", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Algorithm", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-Date")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-Date", valid_402656634
  var valid_402656635 = header.getOrDefault("X-Amz-Credential")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "X-Amz-Credential", valid_402656635
  var valid_402656636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656636 = validateParameter(valid_402656636, JString,
                                      required = false, default = nil)
  if valid_402656636 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656636
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

proc call*(call_402656638: Call_DescribeContributorInsights_402656626;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about contributor insights, for a given table or global secondary index.
                                                                                         ## 
  let valid = call_402656638.validator(path, query, header, formData, body, _)
  let scheme = call_402656638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656638.makeUrl(scheme.get, call_402656638.host, call_402656638.base,
                                   call_402656638.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656638, uri, valid, _)

proc call*(call_402656639: Call_DescribeContributorInsights_402656626;
           body: JsonNode): Recallable =
  ## describeContributorInsights
  ## Returns information about contributor insights, for a given table or global secondary index.
  ##   
                                                                                                 ## body: JObject (required)
  var body_402656640 = newJObject()
  if body != nil:
    body_402656640 = body
  result = call_402656639.call(nil, nil, nil, nil, body_402656640)

var describeContributorInsights* = Call_DescribeContributorInsights_402656626(
    name: "describeContributorInsights", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DescribeContributorInsights",
    validator: validate_DescribeContributorInsights_402656627, base: "/",
    makeUrl: url_DescribeContributorInsights_402656628,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoints_402656641 = ref object of OpenApiRestCall_402656044
proc url_DescribeEndpoints_402656643(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEndpoints_402656642(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the regional endpoint information.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656644 = header.getOrDefault("X-Amz-Target")
  valid_402656644 = validateParameter(valid_402656644, JString, required = true, default = newJString(
      "DynamoDB_20120810.DescribeEndpoints"))
  if valid_402656644 != nil:
    section.add "X-Amz-Target", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Security-Token", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Signature")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Signature", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Algorithm", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-Date")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-Date", valid_402656649
  var valid_402656650 = header.getOrDefault("X-Amz-Credential")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "X-Amz-Credential", valid_402656650
  var valid_402656651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656651
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

proc call*(call_402656653: Call_DescribeEndpoints_402656641;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the regional endpoint information.
                                                                                         ## 
  let valid = call_402656653.validator(path, query, header, formData, body, _)
  let scheme = call_402656653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656653.makeUrl(scheme.get, call_402656653.host, call_402656653.base,
                                   call_402656653.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656653, uri, valid, _)

proc call*(call_402656654: Call_DescribeEndpoints_402656641; body: JsonNode): Recallable =
  ## describeEndpoints
  ## Returns the regional endpoint information.
  ##   body: JObject (required)
  var body_402656655 = newJObject()
  if body != nil:
    body_402656655 = body
  result = call_402656654.call(nil, nil, nil, nil, body_402656655)

var describeEndpoints* = Call_DescribeEndpoints_402656641(
    name: "describeEndpoints", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DescribeEndpoints",
    validator: validate_DescribeEndpoints_402656642, base: "/",
    makeUrl: url_DescribeEndpoints_402656643,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGlobalTable_402656656 = ref object of OpenApiRestCall_402656044
proc url_DescribeGlobalTable_402656658(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeGlobalTable_402656657(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns information about the specified global table.</p> <note> <p>This method only applies to <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V1.html">Version 2017.11.29</a> of global tables.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656659 = header.getOrDefault("X-Amz-Target")
  valid_402656659 = validateParameter(valid_402656659, JString, required = true, default = newJString(
      "DynamoDB_20120810.DescribeGlobalTable"))
  if valid_402656659 != nil:
    section.add "X-Amz-Target", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Security-Token", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Signature")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Signature", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Algorithm", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-Date")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-Date", valid_402656664
  var valid_402656665 = header.getOrDefault("X-Amz-Credential")
  valid_402656665 = validateParameter(valid_402656665, JString,
                                      required = false, default = nil)
  if valid_402656665 != nil:
    section.add "X-Amz-Credential", valid_402656665
  var valid_402656666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656666
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

proc call*(call_402656668: Call_DescribeGlobalTable_402656656;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about the specified global table.</p> <note> <p>This method only applies to <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V1.html">Version 2017.11.29</a> of global tables.</p> </note>
                                                                                         ## 
  let valid = call_402656668.validator(path, query, header, formData, body, _)
  let scheme = call_402656668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656668.makeUrl(scheme.get, call_402656668.host, call_402656668.base,
                                   call_402656668.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656668, uri, valid, _)

proc call*(call_402656669: Call_DescribeGlobalTable_402656656; body: JsonNode): Recallable =
  ## describeGlobalTable
  ## <p>Returns information about the specified global table.</p> <note> <p>This method only applies to <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V1.html">Version 2017.11.29</a> of global tables.</p> </note>
  ##   
                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656670 = newJObject()
  if body != nil:
    body_402656670 = body
  result = call_402656669.call(nil, nil, nil, nil, body_402656670)

var describeGlobalTable* = Call_DescribeGlobalTable_402656656(
    name: "describeGlobalTable", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DescribeGlobalTable",
    validator: validate_DescribeGlobalTable_402656657, base: "/",
    makeUrl: url_DescribeGlobalTable_402656658,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGlobalTableSettings_402656671 = ref object of OpenApiRestCall_402656044
proc url_DescribeGlobalTableSettings_402656673(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeGlobalTableSettings_402656672(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Describes Region-specific settings for a global table.</p> <note> <p>This method only applies to <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V1.html">Version 2017.11.29</a> of global tables.</p> </note>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656674 = header.getOrDefault("X-Amz-Target")
  valid_402656674 = validateParameter(valid_402656674, JString, required = true, default = newJString(
      "DynamoDB_20120810.DescribeGlobalTableSettings"))
  if valid_402656674 != nil:
    section.add "X-Amz-Target", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Security-Token", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Signature")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Signature", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Algorithm", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-Date")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-Date", valid_402656679
  var valid_402656680 = header.getOrDefault("X-Amz-Credential")
  valid_402656680 = validateParameter(valid_402656680, JString,
                                      required = false, default = nil)
  if valid_402656680 != nil:
    section.add "X-Amz-Credential", valid_402656680
  var valid_402656681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656681 = validateParameter(valid_402656681, JString,
                                      required = false, default = nil)
  if valid_402656681 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656681
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

proc call*(call_402656683: Call_DescribeGlobalTableSettings_402656671;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes Region-specific settings for a global table.</p> <note> <p>This method only applies to <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V1.html">Version 2017.11.29</a> of global tables.</p> </note>
                                                                                         ## 
  let valid = call_402656683.validator(path, query, header, formData, body, _)
  let scheme = call_402656683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656683.makeUrl(scheme.get, call_402656683.host, call_402656683.base,
                                   call_402656683.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656683, uri, valid, _)

proc call*(call_402656684: Call_DescribeGlobalTableSettings_402656671;
           body: JsonNode): Recallable =
  ## describeGlobalTableSettings
  ## <p>Describes Region-specific settings for a global table.</p> <note> <p>This method only applies to <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V1.html">Version 2017.11.29</a> of global tables.</p> </note>
  ##   
                                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402656685 = newJObject()
  if body != nil:
    body_402656685 = body
  result = call_402656684.call(nil, nil, nil, nil, body_402656685)

var describeGlobalTableSettings* = Call_DescribeGlobalTableSettings_402656671(
    name: "describeGlobalTableSettings", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DescribeGlobalTableSettings",
    validator: validate_DescribeGlobalTableSettings_402656672, base: "/",
    makeUrl: url_DescribeGlobalTableSettings_402656673,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLimits_402656686 = ref object of OpenApiRestCall_402656044
proc url_DescribeLimits_402656688(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeLimits_402656687(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns the current provisioned-capacity limits for your AWS account in a Region, both for the Region as a whole and for any one DynamoDB table that you create there.</p> <p>When you establish an AWS account, the account has initial limits on the maximum read capacity units and write capacity units that you can provision across all of your DynamoDB tables in a given Region. Also, there are per-table limits that apply when you create a table there. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Limits.html">Limits</a> page in the <i>Amazon DynamoDB Developer Guide</i>.</p> <p>Although you can increase these limits by filing a case at <a href="https://console.aws.amazon.com/support/home#/">AWS Support Center</a>, obtaining the increase is not instantaneous. The <code>DescribeLimits</code> action lets you write code to compare the capacity you are currently using to those limits imposed by your account so that you have enough time to apply for an increase before you hit a limit.</p> <p>For example, you could use one of the AWS SDKs to do the following:</p> <ol> <li> <p>Call <code>DescribeLimits</code> for a particular Region to obtain your current account limits on provisioned capacity there.</p> </li> <li> <p>Create a variable to hold the aggregate read capacity units provisioned for all your tables in that Region, and one to hold the aggregate write capacity units. Zero them both.</p> </li> <li> <p>Call <code>ListTables</code> to obtain a list of all your DynamoDB tables.</p> </li> <li> <p>For each table name listed by <code>ListTables</code>, do the following:</p> <ul> <li> <p>Call <code>DescribeTable</code> with the table name.</p> </li> <li> <p>Use the data returned by <code>DescribeTable</code> to add the read capacity units and write capacity units provisioned for the table itself to your variables.</p> </li> <li> <p>If the table has one or more global secondary indexes (GSIs), loop over these GSIs and add their provisioned capacity values to your variables as well.</p> </li> </ul> </li> <li> <p>Report the account limits for that Region returned by <code>DescribeLimits</code>, along with the total current provisioned capacity levels you have calculated.</p> </li> </ol> <p>This will let you see whether you are getting close to your account-level limits.</p> <p>The per-table limits apply only when you are creating a new table. They restrict the sum of the provisioned capacity of the new table itself and all its global secondary indexes.</p> <p>For existing tables and their GSIs, DynamoDB doesn't let you increase provisioned capacity extremely rapidly. But the only upper limit that applies is that the aggregate provisioned capacity over all your tables and GSIs cannot exceed either of the per-account limits.</p> <note> <p> <code>DescribeLimits</code> should only be called periodically. You can expect throttling errors if you call it more than once in a minute.</p> </note> <p>The <code>DescribeLimits</code> Request element has no content.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656689 = header.getOrDefault("X-Amz-Target")
  valid_402656689 = validateParameter(valid_402656689, JString, required = true, default = newJString(
      "DynamoDB_20120810.DescribeLimits"))
  if valid_402656689 != nil:
    section.add "X-Amz-Target", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Security-Token", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Signature")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Signature", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Algorithm", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-Date")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-Date", valid_402656694
  var valid_402656695 = header.getOrDefault("X-Amz-Credential")
  valid_402656695 = validateParameter(valid_402656695, JString,
                                      required = false, default = nil)
  if valid_402656695 != nil:
    section.add "X-Amz-Credential", valid_402656695
  var valid_402656696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656696 = validateParameter(valid_402656696, JString,
                                      required = false, default = nil)
  if valid_402656696 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656696
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

proc call*(call_402656698: Call_DescribeLimits_402656686; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the current provisioned-capacity limits for your AWS account in a Region, both for the Region as a whole and for any one DynamoDB table that you create there.</p> <p>When you establish an AWS account, the account has initial limits on the maximum read capacity units and write capacity units that you can provision across all of your DynamoDB tables in a given Region. Also, there are per-table limits that apply when you create a table there. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Limits.html">Limits</a> page in the <i>Amazon DynamoDB Developer Guide</i>.</p> <p>Although you can increase these limits by filing a case at <a href="https://console.aws.amazon.com/support/home#/">AWS Support Center</a>, obtaining the increase is not instantaneous. The <code>DescribeLimits</code> action lets you write code to compare the capacity you are currently using to those limits imposed by your account so that you have enough time to apply for an increase before you hit a limit.</p> <p>For example, you could use one of the AWS SDKs to do the following:</p> <ol> <li> <p>Call <code>DescribeLimits</code> for a particular Region to obtain your current account limits on provisioned capacity there.</p> </li> <li> <p>Create a variable to hold the aggregate read capacity units provisioned for all your tables in that Region, and one to hold the aggregate write capacity units. Zero them both.</p> </li> <li> <p>Call <code>ListTables</code> to obtain a list of all your DynamoDB tables.</p> </li> <li> <p>For each table name listed by <code>ListTables</code>, do the following:</p> <ul> <li> <p>Call <code>DescribeTable</code> with the table name.</p> </li> <li> <p>Use the data returned by <code>DescribeTable</code> to add the read capacity units and write capacity units provisioned for the table itself to your variables.</p> </li> <li> <p>If the table has one or more global secondary indexes (GSIs), loop over these GSIs and add their provisioned capacity values to your variables as well.</p> </li> </ul> </li> <li> <p>Report the account limits for that Region returned by <code>DescribeLimits</code>, along with the total current provisioned capacity levels you have calculated.</p> </li> </ol> <p>This will let you see whether you are getting close to your account-level limits.</p> <p>The per-table limits apply only when you are creating a new table. They restrict the sum of the provisioned capacity of the new table itself and all its global secondary indexes.</p> <p>For existing tables and their GSIs, DynamoDB doesn't let you increase provisioned capacity extremely rapidly. But the only upper limit that applies is that the aggregate provisioned capacity over all your tables and GSIs cannot exceed either of the per-account limits.</p> <note> <p> <code>DescribeLimits</code> should only be called periodically. You can expect throttling errors if you call it more than once in a minute.</p> </note> <p>The <code>DescribeLimits</code> Request element has no content.</p>
                                                                                         ## 
  let valid = call_402656698.validator(path, query, header, formData, body, _)
  let scheme = call_402656698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656698.makeUrl(scheme.get, call_402656698.host, call_402656698.base,
                                   call_402656698.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656698, uri, valid, _)

proc call*(call_402656699: Call_DescribeLimits_402656686; body: JsonNode): Recallable =
  ## describeLimits
  ## <p>Returns the current provisioned-capacity limits for your AWS account in a Region, both for the Region as a whole and for any one DynamoDB table that you create there.</p> <p>When you establish an AWS account, the account has initial limits on the maximum read capacity units and write capacity units that you can provision across all of your DynamoDB tables in a given Region. Also, there are per-table limits that apply when you create a table there. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Limits.html">Limits</a> page in the <i>Amazon DynamoDB Developer Guide</i>.</p> <p>Although you can increase these limits by filing a case at <a href="https://console.aws.amazon.com/support/home#/">AWS Support Center</a>, obtaining the increase is not instantaneous. The <code>DescribeLimits</code> action lets you write code to compare the capacity you are currently using to those limits imposed by your account so that you have enough time to apply for an increase before you hit a limit.</p> <p>For example, you could use one of the AWS SDKs to do the following:</p> <ol> <li> <p>Call <code>DescribeLimits</code> for a particular Region to obtain your current account limits on provisioned capacity there.</p> </li> <li> <p>Create a variable to hold the aggregate read capacity units provisioned for all your tables in that Region, and one to hold the aggregate write capacity units. Zero them both.</p> </li> <li> <p>Call <code>ListTables</code> to obtain a list of all your DynamoDB tables.</p> </li> <li> <p>For each table name listed by <code>ListTables</code>, do the following:</p> <ul> <li> <p>Call <code>DescribeTable</code> with the table name.</p> </li> <li> <p>Use the data returned by <code>DescribeTable</code> to add the read capacity units and write capacity units provisioned for the table itself to your variables.</p> </li> <li> <p>If the table has one or more global secondary indexes (GSIs), loop over these GSIs and add their provisioned capacity values to your variables as well.</p> </li> </ul> </li> <li> <p>Report the account limits for that Region returned by <code>DescribeLimits</code>, along with the total current provisioned capacity levels you have calculated.</p> </li> </ol> <p>This will let you see whether you are getting close to your account-level limits.</p> <p>The per-table limits apply only when you are creating a new table. They restrict the sum of the provisioned capacity of the new table itself and all its global secondary indexes.</p> <p>For existing tables and their GSIs, DynamoDB doesn't let you increase provisioned capacity extremely rapidly. But the only upper limit that applies is that the aggregate provisioned capacity over all your tables and GSIs cannot exceed either of the per-account limits.</p> <note> <p> <code>DescribeLimits</code> should only be called periodically. You can expect throttling errors if you call it more than once in a minute.</p> </note> <p>The <code>DescribeLimits</code> Request element has no content.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402656700 = newJObject()
  if body != nil:
    body_402656700 = body
  result = call_402656699.call(nil, nil, nil, nil, body_402656700)

var describeLimits* = Call_DescribeLimits_402656686(name: "describeLimits",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DescribeLimits",
    validator: validate_DescribeLimits_402656687, base: "/",
    makeUrl: url_DescribeLimits_402656688, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTable_402656701 = ref object of OpenApiRestCall_402656044
proc url_DescribeTable_402656703(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTable_402656702(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns information about the table, including the current status of the table, when it was created, the primary key schema, and any indexes on the table.</p> <note> <p>If you issue a <code>DescribeTable</code> request immediately after a <code>CreateTable</code> request, DynamoDB might return a <code>ResourceNotFoundException</code>. This is because <code>DescribeTable</code> uses an eventually consistent query, and the metadata for your table might not be available at that moment. Wait for a few seconds, and then try the <code>DescribeTable</code> request again.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656704 = header.getOrDefault("X-Amz-Target")
  valid_402656704 = validateParameter(valid_402656704, JString, required = true, default = newJString(
      "DynamoDB_20120810.DescribeTable"))
  if valid_402656704 != nil:
    section.add "X-Amz-Target", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Security-Token", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Signature")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Signature", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-Algorithm", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-Date")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-Date", valid_402656709
  var valid_402656710 = header.getOrDefault("X-Amz-Credential")
  valid_402656710 = validateParameter(valid_402656710, JString,
                                      required = false, default = nil)
  if valid_402656710 != nil:
    section.add "X-Amz-Credential", valid_402656710
  var valid_402656711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656711 = validateParameter(valid_402656711, JString,
                                      required = false, default = nil)
  if valid_402656711 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656711
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

proc call*(call_402656713: Call_DescribeTable_402656701; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about the table, including the current status of the table, when it was created, the primary key schema, and any indexes on the table.</p> <note> <p>If you issue a <code>DescribeTable</code> request immediately after a <code>CreateTable</code> request, DynamoDB might return a <code>ResourceNotFoundException</code>. This is because <code>DescribeTable</code> uses an eventually consistent query, and the metadata for your table might not be available at that moment. Wait for a few seconds, and then try the <code>DescribeTable</code> request again.</p> </note>
                                                                                         ## 
  let valid = call_402656713.validator(path, query, header, formData, body, _)
  let scheme = call_402656713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656713.makeUrl(scheme.get, call_402656713.host, call_402656713.base,
                                   call_402656713.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656713, uri, valid, _)

proc call*(call_402656714: Call_DescribeTable_402656701; body: JsonNode): Recallable =
  ## describeTable
  ## <p>Returns information about the table, including the current status of the table, when it was created, the primary key schema, and any indexes on the table.</p> <note> <p>If you issue a <code>DescribeTable</code> request immediately after a <code>CreateTable</code> request, DynamoDB might return a <code>ResourceNotFoundException</code>. This is because <code>DescribeTable</code> uses an eventually consistent query, and the metadata for your table might not be available at that moment. Wait for a few seconds, and then try the <code>DescribeTable</code> request again.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656715 = newJObject()
  if body != nil:
    body_402656715 = body
  result = call_402656714.call(nil, nil, nil, nil, body_402656715)

var describeTable* = Call_DescribeTable_402656701(name: "describeTable",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DescribeTable",
    validator: validate_DescribeTable_402656702, base: "/",
    makeUrl: url_DescribeTable_402656703, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTableReplicaAutoScaling_402656716 = ref object of OpenApiRestCall_402656044
proc url_DescribeTableReplicaAutoScaling_402656718(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTableReplicaAutoScaling_402656717(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Describes auto scaling settings across replicas of the global table at once.</p> <note> <p>This method only applies to <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html">Version 2019.11.21</a> of global tables.</p> </note>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656719 = header.getOrDefault("X-Amz-Target")
  valid_402656719 = validateParameter(valid_402656719, JString, required = true, default = newJString(
      "DynamoDB_20120810.DescribeTableReplicaAutoScaling"))
  if valid_402656719 != nil:
    section.add "X-Amz-Target", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Security-Token", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Signature")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Signature", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Algorithm", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-Date")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-Date", valid_402656724
  var valid_402656725 = header.getOrDefault("X-Amz-Credential")
  valid_402656725 = validateParameter(valid_402656725, JString,
                                      required = false, default = nil)
  if valid_402656725 != nil:
    section.add "X-Amz-Credential", valid_402656725
  var valid_402656726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656726 = validateParameter(valid_402656726, JString,
                                      required = false, default = nil)
  if valid_402656726 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656726
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

proc call*(call_402656728: Call_DescribeTableReplicaAutoScaling_402656716;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes auto scaling settings across replicas of the global table at once.</p> <note> <p>This method only applies to <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html">Version 2019.11.21</a> of global tables.</p> </note>
                                                                                         ## 
  let valid = call_402656728.validator(path, query, header, formData, body, _)
  let scheme = call_402656728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656728.makeUrl(scheme.get, call_402656728.host, call_402656728.base,
                                   call_402656728.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656728, uri, valid, _)

proc call*(call_402656729: Call_DescribeTableReplicaAutoScaling_402656716;
           body: JsonNode): Recallable =
  ## describeTableReplicaAutoScaling
  ## <p>Describes auto scaling settings across replicas of the global table at once.</p> <note> <p>This method only applies to <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html">Version 2019.11.21</a> of global tables.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656730 = newJObject()
  if body != nil:
    body_402656730 = body
  result = call_402656729.call(nil, nil, nil, nil, body_402656730)

var describeTableReplicaAutoScaling* = Call_DescribeTableReplicaAutoScaling_402656716(
    name: "describeTableReplicaAutoScaling", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DescribeTableReplicaAutoScaling",
    validator: validate_DescribeTableReplicaAutoScaling_402656717, base: "/",
    makeUrl: url_DescribeTableReplicaAutoScaling_402656718,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTimeToLive_402656731 = ref object of OpenApiRestCall_402656044
proc url_DescribeTimeToLive_402656733(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTimeToLive_402656732(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gives a description of the Time to Live (TTL) status on the specified table. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656734 = header.getOrDefault("X-Amz-Target")
  valid_402656734 = validateParameter(valid_402656734, JString, required = true, default = newJString(
      "DynamoDB_20120810.DescribeTimeToLive"))
  if valid_402656734 != nil:
    section.add "X-Amz-Target", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Security-Token", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Signature")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Signature", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Algorithm", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-Date")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-Date", valid_402656739
  var valid_402656740 = header.getOrDefault("X-Amz-Credential")
  valid_402656740 = validateParameter(valid_402656740, JString,
                                      required = false, default = nil)
  if valid_402656740 != nil:
    section.add "X-Amz-Credential", valid_402656740
  var valid_402656741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656741 = validateParameter(valid_402656741, JString,
                                      required = false, default = nil)
  if valid_402656741 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656741
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

proc call*(call_402656743: Call_DescribeTimeToLive_402656731;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gives a description of the Time to Live (TTL) status on the specified table. 
                                                                                         ## 
  let valid = call_402656743.validator(path, query, header, formData, body, _)
  let scheme = call_402656743.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656743.makeUrl(scheme.get, call_402656743.host, call_402656743.base,
                                   call_402656743.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656743, uri, valid, _)

proc call*(call_402656744: Call_DescribeTimeToLive_402656731; body: JsonNode): Recallable =
  ## describeTimeToLive
  ## Gives a description of the Time to Live (TTL) status on the specified table. 
  ##   
                                                                                  ## body: JObject (required)
  var body_402656745 = newJObject()
  if body != nil:
    body_402656745 = body
  result = call_402656744.call(nil, nil, nil, nil, body_402656745)

var describeTimeToLive* = Call_DescribeTimeToLive_402656731(
    name: "describeTimeToLive", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DescribeTimeToLive",
    validator: validate_DescribeTimeToLive_402656732, base: "/",
    makeUrl: url_DescribeTimeToLive_402656733,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetItem_402656746 = ref object of OpenApiRestCall_402656044
proc url_GetItem_402656748(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetItem_402656747(path: JsonNode; query: JsonNode;
                                header: JsonNode; formData: JsonNode;
                                body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>The <code>GetItem</code> operation returns a set of attributes for the item with the given primary key. If there is no matching item, <code>GetItem</code> does not return any data and there will be no <code>Item</code> element in the response.</p> <p> <code>GetItem</code> provides an eventually consistent read by default. If your application requires a strongly consistent read, set <code>ConsistentRead</code> to <code>true</code>. Although a strongly consistent read might take more time than an eventually consistent read, it always returns the last updated value.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656749 = header.getOrDefault("X-Amz-Target")
  valid_402656749 = validateParameter(valid_402656749, JString, required = true, default = newJString(
      "DynamoDB_20120810.GetItem"))
  if valid_402656749 != nil:
    section.add "X-Amz-Target", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Security-Token", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-Signature")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Signature", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Algorithm", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-Date")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-Date", valid_402656754
  var valid_402656755 = header.getOrDefault("X-Amz-Credential")
  valid_402656755 = validateParameter(valid_402656755, JString,
                                      required = false, default = nil)
  if valid_402656755 != nil:
    section.add "X-Amz-Credential", valid_402656755
  var valid_402656756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656756 = validateParameter(valid_402656756, JString,
                                      required = false, default = nil)
  if valid_402656756 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656756
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

proc call*(call_402656758: Call_GetItem_402656746; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>The <code>GetItem</code> operation returns a set of attributes for the item with the given primary key. If there is no matching item, <code>GetItem</code> does not return any data and there will be no <code>Item</code> element in the response.</p> <p> <code>GetItem</code> provides an eventually consistent read by default. If your application requires a strongly consistent read, set <code>ConsistentRead</code> to <code>true</code>. Although a strongly consistent read might take more time than an eventually consistent read, it always returns the last updated value.</p>
                                                                                         ## 
  let valid = call_402656758.validator(path, query, header, formData, body, _)
  let scheme = call_402656758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656758.makeUrl(scheme.get, call_402656758.host, call_402656758.base,
                                   call_402656758.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656758, uri, valid, _)

proc call*(call_402656759: Call_GetItem_402656746; body: JsonNode): Recallable =
  ## getItem
  ## <p>The <code>GetItem</code> operation returns a set of attributes for the item with the given primary key. If there is no matching item, <code>GetItem</code> does not return any data and there will be no <code>Item</code> element in the response.</p> <p> <code>GetItem</code> provides an eventually consistent read by default. If your application requires a strongly consistent read, set <code>ConsistentRead</code> to <code>true</code>. Although a strongly consistent read might take more time than an eventually consistent read, it always returns the last updated value.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402656760 = newJObject()
  if body != nil:
    body_402656760 = body
  result = call_402656759.call(nil, nil, nil, nil, body_402656760)

var getItem* = Call_GetItem_402656746(name: "getItem",
                                      meth: HttpMethod.HttpPost,
                                      host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20120810.GetItem",
                                      validator: validate_GetItem_402656747,
                                      base: "/", makeUrl: url_GetItem_402656748,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackups_402656761 = ref object of OpenApiRestCall_402656044
proc url_ListBackups_402656763(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBackups_402656762(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>List backups associated with an AWS account. To list backups for a given table, specify <code>TableName</code>. <code>ListBackups</code> returns a paginated list of results with at most 1 MB worth of items in a page. You can also specify a limit for the maximum number of entries to be returned in a page. </p> <p>In the request, start time is inclusive, but end time is exclusive. Note that these limits are for the time at which the original backup was requested.</p> <p>You can call <code>ListBackups</code> a maximum of five times per second.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656764 = header.getOrDefault("X-Amz-Target")
  valid_402656764 = validateParameter(valid_402656764, JString, required = true, default = newJString(
      "DynamoDB_20120810.ListBackups"))
  if valid_402656764 != nil:
    section.add "X-Amz-Target", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Security-Token", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-Signature")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-Signature", valid_402656766
  var valid_402656767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656767
  var valid_402656768 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "X-Amz-Algorithm", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-Date")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-Date", valid_402656769
  var valid_402656770 = header.getOrDefault("X-Amz-Credential")
  valid_402656770 = validateParameter(valid_402656770, JString,
                                      required = false, default = nil)
  if valid_402656770 != nil:
    section.add "X-Amz-Credential", valid_402656770
  var valid_402656771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656771 = validateParameter(valid_402656771, JString,
                                      required = false, default = nil)
  if valid_402656771 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656771
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

proc call*(call_402656773: Call_ListBackups_402656761; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>List backups associated with an AWS account. To list backups for a given table, specify <code>TableName</code>. <code>ListBackups</code> returns a paginated list of results with at most 1 MB worth of items in a page. You can also specify a limit for the maximum number of entries to be returned in a page. </p> <p>In the request, start time is inclusive, but end time is exclusive. Note that these limits are for the time at which the original backup was requested.</p> <p>You can call <code>ListBackups</code> a maximum of five times per second.</p>
                                                                                         ## 
  let valid = call_402656773.validator(path, query, header, formData, body, _)
  let scheme = call_402656773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656773.makeUrl(scheme.get, call_402656773.host, call_402656773.base,
                                   call_402656773.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656773, uri, valid, _)

proc call*(call_402656774: Call_ListBackups_402656761; body: JsonNode): Recallable =
  ## listBackups
  ## <p>List backups associated with an AWS account. To list backups for a given table, specify <code>TableName</code>. <code>ListBackups</code> returns a paginated list of results with at most 1 MB worth of items in a page. You can also specify a limit for the maximum number of entries to be returned in a page. </p> <p>In the request, start time is inclusive, but end time is exclusive. Note that these limits are for the time at which the original backup was requested.</p> <p>You can call <code>ListBackups</code> a maximum of five times per second.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656775 = newJObject()
  if body != nil:
    body_402656775 = body
  result = call_402656774.call(nil, nil, nil, nil, body_402656775)

var listBackups* = Call_ListBackups_402656761(name: "listBackups",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.ListBackups",
    validator: validate_ListBackups_402656762, base: "/",
    makeUrl: url_ListBackups_402656763, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListContributorInsights_402656776 = ref object of OpenApiRestCall_402656044
proc url_ListContributorInsights_402656778(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListContributorInsights_402656777(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of ContributorInsightsSummary for a table and all its global secondary indexes.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656779 = query.getOrDefault("MaxResults")
  valid_402656779 = validateParameter(valid_402656779, JString,
                                      required = false, default = nil)
  if valid_402656779 != nil:
    section.add "MaxResults", valid_402656779
  var valid_402656780 = query.getOrDefault("NextToken")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "NextToken", valid_402656780
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656781 = header.getOrDefault("X-Amz-Target")
  valid_402656781 = validateParameter(valid_402656781, JString, required = true, default = newJString(
      "DynamoDB_20120810.ListContributorInsights"))
  if valid_402656781 != nil:
    section.add "X-Amz-Target", valid_402656781
  var valid_402656782 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656782 = validateParameter(valid_402656782, JString,
                                      required = false, default = nil)
  if valid_402656782 != nil:
    section.add "X-Amz-Security-Token", valid_402656782
  var valid_402656783 = header.getOrDefault("X-Amz-Signature")
  valid_402656783 = validateParameter(valid_402656783, JString,
                                      required = false, default = nil)
  if valid_402656783 != nil:
    section.add "X-Amz-Signature", valid_402656783
  var valid_402656784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656784
  var valid_402656785 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656785 = validateParameter(valid_402656785, JString,
                                      required = false, default = nil)
  if valid_402656785 != nil:
    section.add "X-Amz-Algorithm", valid_402656785
  var valid_402656786 = header.getOrDefault("X-Amz-Date")
  valid_402656786 = validateParameter(valid_402656786, JString,
                                      required = false, default = nil)
  if valid_402656786 != nil:
    section.add "X-Amz-Date", valid_402656786
  var valid_402656787 = header.getOrDefault("X-Amz-Credential")
  valid_402656787 = validateParameter(valid_402656787, JString,
                                      required = false, default = nil)
  if valid_402656787 != nil:
    section.add "X-Amz-Credential", valid_402656787
  var valid_402656788 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656788 = validateParameter(valid_402656788, JString,
                                      required = false, default = nil)
  if valid_402656788 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656788
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

proc call*(call_402656790: Call_ListContributorInsights_402656776;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of ContributorInsightsSummary for a table and all its global secondary indexes.
                                                                                         ## 
  let valid = call_402656790.validator(path, query, header, formData, body, _)
  let scheme = call_402656790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656790.makeUrl(scheme.get, call_402656790.host, call_402656790.base,
                                   call_402656790.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656790, uri, valid, _)

proc call*(call_402656791: Call_ListContributorInsights_402656776;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listContributorInsights
  ## Returns a list of ContributorInsightsSummary for a table and all its global secondary indexes.
  ##   
                                                                                                   ## MaxResults: string
                                                                                                   ##             
                                                                                                   ## : 
                                                                                                   ## Pagination 
                                                                                                   ## limit
  ##   
                                                                                                           ## body: JObject (required)
  ##   
                                                                                                                                      ## NextToken: string
                                                                                                                                      ##            
                                                                                                                                      ## : 
                                                                                                                                      ## Pagination 
                                                                                                                                      ## token
  var query_402656792 = newJObject()
  var body_402656793 = newJObject()
  add(query_402656792, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656793 = body
  add(query_402656792, "NextToken", newJString(NextToken))
  result = call_402656791.call(nil, query_402656792, nil, nil, body_402656793)

var listContributorInsights* = Call_ListContributorInsights_402656776(
    name: "listContributorInsights", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.ListContributorInsights",
    validator: validate_ListContributorInsights_402656777, base: "/",
    makeUrl: url_ListContributorInsights_402656778,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGlobalTables_402656794 = ref object of OpenApiRestCall_402656044
proc url_ListGlobalTables_402656796(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGlobalTables_402656795(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Lists all global tables that have a replica in the specified Region.</p> <note> <p>This method only applies to <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V1.html">Version 2017.11.29</a> of global tables.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656797 = header.getOrDefault("X-Amz-Target")
  valid_402656797 = validateParameter(valid_402656797, JString, required = true, default = newJString(
      "DynamoDB_20120810.ListGlobalTables"))
  if valid_402656797 != nil:
    section.add "X-Amz-Target", valid_402656797
  var valid_402656798 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656798 = validateParameter(valid_402656798, JString,
                                      required = false, default = nil)
  if valid_402656798 != nil:
    section.add "X-Amz-Security-Token", valid_402656798
  var valid_402656799 = header.getOrDefault("X-Amz-Signature")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-Signature", valid_402656799
  var valid_402656800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656800 = validateParameter(valid_402656800, JString,
                                      required = false, default = nil)
  if valid_402656800 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656800
  var valid_402656801 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656801 = validateParameter(valid_402656801, JString,
                                      required = false, default = nil)
  if valid_402656801 != nil:
    section.add "X-Amz-Algorithm", valid_402656801
  var valid_402656802 = header.getOrDefault("X-Amz-Date")
  valid_402656802 = validateParameter(valid_402656802, JString,
                                      required = false, default = nil)
  if valid_402656802 != nil:
    section.add "X-Amz-Date", valid_402656802
  var valid_402656803 = header.getOrDefault("X-Amz-Credential")
  valid_402656803 = validateParameter(valid_402656803, JString,
                                      required = false, default = nil)
  if valid_402656803 != nil:
    section.add "X-Amz-Credential", valid_402656803
  var valid_402656804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656804 = validateParameter(valid_402656804, JString,
                                      required = false, default = nil)
  if valid_402656804 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656804
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

proc call*(call_402656806: Call_ListGlobalTables_402656794;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists all global tables that have a replica in the specified Region.</p> <note> <p>This method only applies to <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V1.html">Version 2017.11.29</a> of global tables.</p> </note>
                                                                                         ## 
  let valid = call_402656806.validator(path, query, header, formData, body, _)
  let scheme = call_402656806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656806.makeUrl(scheme.get, call_402656806.host, call_402656806.base,
                                   call_402656806.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656806, uri, valid, _)

proc call*(call_402656807: Call_ListGlobalTables_402656794; body: JsonNode): Recallable =
  ## listGlobalTables
  ## <p>Lists all global tables that have a replica in the specified Region.</p> <note> <p>This method only applies to <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V1.html">Version 2017.11.29</a> of global tables.</p> </note>
  ##   
                                                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402656808 = newJObject()
  if body != nil:
    body_402656808 = body
  result = call_402656807.call(nil, nil, nil, nil, body_402656808)

var listGlobalTables* = Call_ListGlobalTables_402656794(
    name: "listGlobalTables", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.ListGlobalTables",
    validator: validate_ListGlobalTables_402656795, base: "/",
    makeUrl: url_ListGlobalTables_402656796,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTables_402656809 = ref object of OpenApiRestCall_402656044
proc url_ListTables_402656811(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTables_402656810(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns an array of table names associated with the current account and endpoint. The output from <code>ListTables</code> is paginated, with each page returning a maximum of 100 table names.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ExclusiveStartTableName: JString
                                  ##                          : Pagination token
  ##   
                                                                                ## Limit: JString
                                                                                ##        
                                                                                ## : 
                                                                                ## Pagination 
                                                                                ## limit
  section = newJObject()
  var valid_402656812 = query.getOrDefault("ExclusiveStartTableName")
  valid_402656812 = validateParameter(valid_402656812, JString,
                                      required = false, default = nil)
  if valid_402656812 != nil:
    section.add "ExclusiveStartTableName", valid_402656812
  var valid_402656813 = query.getOrDefault("Limit")
  valid_402656813 = validateParameter(valid_402656813, JString,
                                      required = false, default = nil)
  if valid_402656813 != nil:
    section.add "Limit", valid_402656813
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656814 = header.getOrDefault("X-Amz-Target")
  valid_402656814 = validateParameter(valid_402656814, JString, required = true, default = newJString(
      "DynamoDB_20120810.ListTables"))
  if valid_402656814 != nil:
    section.add "X-Amz-Target", valid_402656814
  var valid_402656815 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656815 = validateParameter(valid_402656815, JString,
                                      required = false, default = nil)
  if valid_402656815 != nil:
    section.add "X-Amz-Security-Token", valid_402656815
  var valid_402656816 = header.getOrDefault("X-Amz-Signature")
  valid_402656816 = validateParameter(valid_402656816, JString,
                                      required = false, default = nil)
  if valid_402656816 != nil:
    section.add "X-Amz-Signature", valid_402656816
  var valid_402656817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656817 = validateParameter(valid_402656817, JString,
                                      required = false, default = nil)
  if valid_402656817 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656817
  var valid_402656818 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656818 = validateParameter(valid_402656818, JString,
                                      required = false, default = nil)
  if valid_402656818 != nil:
    section.add "X-Amz-Algorithm", valid_402656818
  var valid_402656819 = header.getOrDefault("X-Amz-Date")
  valid_402656819 = validateParameter(valid_402656819, JString,
                                      required = false, default = nil)
  if valid_402656819 != nil:
    section.add "X-Amz-Date", valid_402656819
  var valid_402656820 = header.getOrDefault("X-Amz-Credential")
  valid_402656820 = validateParameter(valid_402656820, JString,
                                      required = false, default = nil)
  if valid_402656820 != nil:
    section.add "X-Amz-Credential", valid_402656820
  var valid_402656821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656821 = validateParameter(valid_402656821, JString,
                                      required = false, default = nil)
  if valid_402656821 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656821
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

proc call*(call_402656823: Call_ListTables_402656809; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns an array of table names associated with the current account and endpoint. The output from <code>ListTables</code> is paginated, with each page returning a maximum of 100 table names.
                                                                                         ## 
  let valid = call_402656823.validator(path, query, header, formData, body, _)
  let scheme = call_402656823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656823.makeUrl(scheme.get, call_402656823.host, call_402656823.base,
                                   call_402656823.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656823, uri, valid, _)

proc call*(call_402656824: Call_ListTables_402656809; body: JsonNode;
           ExclusiveStartTableName: string = ""; Limit: string = ""): Recallable =
  ## listTables
  ## Returns an array of table names associated with the current account and endpoint. The output from <code>ListTables</code> is paginated, with each page returning a maximum of 100 table names.
  ##   
                                                                                                                                                                                                   ## body: JObject (required)
  ##   
                                                                                                                                                                                                                              ## ExclusiveStartTableName: string
                                                                                                                                                                                                                              ##                          
                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                              ## Pagination 
                                                                                                                                                                                                                              ## token
  ##   
                                                                                                                                                                                                                                      ## Limit: string
                                                                                                                                                                                                                                      ##        
                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                      ## Pagination 
                                                                                                                                                                                                                                      ## limit
  var query_402656825 = newJObject()
  var body_402656826 = newJObject()
  if body != nil:
    body_402656826 = body
  add(query_402656825, "ExclusiveStartTableName",
      newJString(ExclusiveStartTableName))
  add(query_402656825, "Limit", newJString(Limit))
  result = call_402656824.call(nil, query_402656825, nil, nil, body_402656826)

var listTables* = Call_ListTables_402656809(name: "listTables",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.ListTables",
    validator: validate_ListTables_402656810, base: "/",
    makeUrl: url_ListTables_402656811, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsOfResource_402656827 = ref object of OpenApiRestCall_402656044
proc url_ListTagsOfResource_402656829(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsOfResource_402656828(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>List all tags on an Amazon DynamoDB resource. You can call ListTagsOfResource up to 10 times per second, per account.</p> <p>For an overview on tagging DynamoDB resources, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html">Tagging for DynamoDB</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656830 = header.getOrDefault("X-Amz-Target")
  valid_402656830 = validateParameter(valid_402656830, JString, required = true, default = newJString(
      "DynamoDB_20120810.ListTagsOfResource"))
  if valid_402656830 != nil:
    section.add "X-Amz-Target", valid_402656830
  var valid_402656831 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656831 = validateParameter(valid_402656831, JString,
                                      required = false, default = nil)
  if valid_402656831 != nil:
    section.add "X-Amz-Security-Token", valid_402656831
  var valid_402656832 = header.getOrDefault("X-Amz-Signature")
  valid_402656832 = validateParameter(valid_402656832, JString,
                                      required = false, default = nil)
  if valid_402656832 != nil:
    section.add "X-Amz-Signature", valid_402656832
  var valid_402656833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656833 = validateParameter(valid_402656833, JString,
                                      required = false, default = nil)
  if valid_402656833 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656833
  var valid_402656834 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656834 = validateParameter(valid_402656834, JString,
                                      required = false, default = nil)
  if valid_402656834 != nil:
    section.add "X-Amz-Algorithm", valid_402656834
  var valid_402656835 = header.getOrDefault("X-Amz-Date")
  valid_402656835 = validateParameter(valid_402656835, JString,
                                      required = false, default = nil)
  if valid_402656835 != nil:
    section.add "X-Amz-Date", valid_402656835
  var valid_402656836 = header.getOrDefault("X-Amz-Credential")
  valid_402656836 = validateParameter(valid_402656836, JString,
                                      required = false, default = nil)
  if valid_402656836 != nil:
    section.add "X-Amz-Credential", valid_402656836
  var valid_402656837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656837 = validateParameter(valid_402656837, JString,
                                      required = false, default = nil)
  if valid_402656837 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656837
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

proc call*(call_402656839: Call_ListTagsOfResource_402656827;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>List all tags on an Amazon DynamoDB resource. You can call ListTagsOfResource up to 10 times per second, per account.</p> <p>For an overview on tagging DynamoDB resources, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html">Tagging for DynamoDB</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656839.validator(path, query, header, formData, body, _)
  let scheme = call_402656839.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656839.makeUrl(scheme.get, call_402656839.host, call_402656839.base,
                                   call_402656839.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656839, uri, valid, _)

proc call*(call_402656840: Call_ListTagsOfResource_402656827; body: JsonNode): Recallable =
  ## listTagsOfResource
  ## <p>List all tags on an Amazon DynamoDB resource. You can call ListTagsOfResource up to 10 times per second, per account.</p> <p>For an overview on tagging DynamoDB resources, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html">Tagging for DynamoDB</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402656841 = newJObject()
  if body != nil:
    body_402656841 = body
  result = call_402656840.call(nil, nil, nil, nil, body_402656841)

var listTagsOfResource* = Call_ListTagsOfResource_402656827(
    name: "listTagsOfResource", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.ListTagsOfResource",
    validator: validate_ListTagsOfResource_402656828, base: "/",
    makeUrl: url_ListTagsOfResource_402656829,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutItem_402656842 = ref object of OpenApiRestCall_402656044
proc url_PutItem_402656844(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutItem_402656843(path: JsonNode; query: JsonNode;
                                header: JsonNode; formData: JsonNode;
                                body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a new item, or replaces an old item with a new item. If an item that has the same primary key as the new item already exists in the specified table, the new item completely replaces the existing item. You can perform a conditional put operation (add a new item if one with the specified primary key doesn't exist), or replace an existing item if it has certain attribute values. You can return the item's attribute values in the same operation, using the <code>ReturnValues</code> parameter.</p> <important> <p>This topic provides general information about the <code>PutItem</code> API.</p> <p>For information on how to call the <code>PutItem</code> API using the AWS SDK in specific languages, see the following:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/goto/aws-cli/dynamodb-2012-08-10/PutItem"> PutItem in the AWS Command Line Interface</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/DotNetSDKV3/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for .NET</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForCpp/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for C++</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForGoV1/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Go</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForJava/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Java</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/AWSJavaScriptSDK/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for JavaScript</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForPHPV3/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for PHP V3</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/boto3/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Python</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForRubyV2/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Ruby V2</a> </p> </li> </ul> </important> <p>When you add an item, the primary key attributes are the only required attributes. Attribute values cannot be null. String and Binary type attributes must have lengths greater than zero. Set type attributes cannot be empty. Requests with empty values will be rejected with a <code>ValidationException</code> exception.</p> <note> <p>To prevent a new item from replacing an existing item, use a conditional expression that contains the <code>attribute_not_exists</code> function with the name of the attribute being used as the partition key for the table. Since every record must contain that attribute, the <code>attribute_not_exists</code> function will only succeed if no matching item exists.</p> </note> <p>For more information about <code>PutItem</code>, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/WorkingWithItems.html">Working with Items</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656845 = header.getOrDefault("X-Amz-Target")
  valid_402656845 = validateParameter(valid_402656845, JString, required = true, default = newJString(
      "DynamoDB_20120810.PutItem"))
  if valid_402656845 != nil:
    section.add "X-Amz-Target", valid_402656845
  var valid_402656846 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656846 = validateParameter(valid_402656846, JString,
                                      required = false, default = nil)
  if valid_402656846 != nil:
    section.add "X-Amz-Security-Token", valid_402656846
  var valid_402656847 = header.getOrDefault("X-Amz-Signature")
  valid_402656847 = validateParameter(valid_402656847, JString,
                                      required = false, default = nil)
  if valid_402656847 != nil:
    section.add "X-Amz-Signature", valid_402656847
  var valid_402656848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656848 = validateParameter(valid_402656848, JString,
                                      required = false, default = nil)
  if valid_402656848 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656848
  var valid_402656849 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656849 = validateParameter(valid_402656849, JString,
                                      required = false, default = nil)
  if valid_402656849 != nil:
    section.add "X-Amz-Algorithm", valid_402656849
  var valid_402656850 = header.getOrDefault("X-Amz-Date")
  valid_402656850 = validateParameter(valid_402656850, JString,
                                      required = false, default = nil)
  if valid_402656850 != nil:
    section.add "X-Amz-Date", valid_402656850
  var valid_402656851 = header.getOrDefault("X-Amz-Credential")
  valid_402656851 = validateParameter(valid_402656851, JString,
                                      required = false, default = nil)
  if valid_402656851 != nil:
    section.add "X-Amz-Credential", valid_402656851
  var valid_402656852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656852 = validateParameter(valid_402656852, JString,
                                      required = false, default = nil)
  if valid_402656852 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656852
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

proc call*(call_402656854: Call_PutItem_402656842; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new item, or replaces an old item with a new item. If an item that has the same primary key as the new item already exists in the specified table, the new item completely replaces the existing item. You can perform a conditional put operation (add a new item if one with the specified primary key doesn't exist), or replace an existing item if it has certain attribute values. You can return the item's attribute values in the same operation, using the <code>ReturnValues</code> parameter.</p> <important> <p>This topic provides general information about the <code>PutItem</code> API.</p> <p>For information on how to call the <code>PutItem</code> API using the AWS SDK in specific languages, see the following:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/goto/aws-cli/dynamodb-2012-08-10/PutItem"> PutItem in the AWS Command Line Interface</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/DotNetSDKV3/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for .NET</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForCpp/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for C++</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForGoV1/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Go</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForJava/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Java</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/AWSJavaScriptSDK/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for JavaScript</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForPHPV3/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for PHP V3</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/boto3/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Python</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForRubyV2/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Ruby V2</a> </p> </li> </ul> </important> <p>When you add an item, the primary key attributes are the only required attributes. Attribute values cannot be null. String and Binary type attributes must have lengths greater than zero. Set type attributes cannot be empty. Requests with empty values will be rejected with a <code>ValidationException</code> exception.</p> <note> <p>To prevent a new item from replacing an existing item, use a conditional expression that contains the <code>attribute_not_exists</code> function with the name of the attribute being used as the partition key for the table. Since every record must contain that attribute, the <code>attribute_not_exists</code> function will only succeed if no matching item exists.</p> </note> <p>For more information about <code>PutItem</code>, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/WorkingWithItems.html">Working with Items</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656854.validator(path, query, header, formData, body, _)
  let scheme = call_402656854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656854.makeUrl(scheme.get, call_402656854.host, call_402656854.base,
                                   call_402656854.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656854, uri, valid, _)

proc call*(call_402656855: Call_PutItem_402656842; body: JsonNode): Recallable =
  ## putItem
  ## <p>Creates a new item, or replaces an old item with a new item. If an item that has the same primary key as the new item already exists in the specified table, the new item completely replaces the existing item. You can perform a conditional put operation (add a new item if one with the specified primary key doesn't exist), or replace an existing item if it has certain attribute values. You can return the item's attribute values in the same operation, using the <code>ReturnValues</code> parameter.</p> <important> <p>This topic provides general information about the <code>PutItem</code> API.</p> <p>For information on how to call the <code>PutItem</code> API using the AWS SDK in specific languages, see the following:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/goto/aws-cli/dynamodb-2012-08-10/PutItem"> PutItem in the AWS Command Line Interface</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/DotNetSDKV3/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for .NET</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForCpp/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for C++</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForGoV1/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Go</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForJava/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Java</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/AWSJavaScriptSDK/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for JavaScript</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForPHPV3/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for PHP V3</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/boto3/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Python</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForRubyV2/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Ruby V2</a> </p> </li> </ul> </important> <p>When you add an item, the primary key attributes are the only required attributes. Attribute values cannot be null. String and Binary type attributes must have lengths greater than zero. Set type attributes cannot be empty. Requests with empty values will be rejected with a <code>ValidationException</code> exception.</p> <note> <p>To prevent a new item from replacing an existing item, use a conditional expression that contains the <code>attribute_not_exists</code> function with the name of the attribute being used as the partition key for the table. Since every record must contain that attribute, the <code>attribute_not_exists</code> function will only succeed if no matching item exists.</p> </note> <p>For more information about <code>PutItem</code>, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/WorkingWithItems.html">Working with Items</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656856 = newJObject()
  if body != nil:
    body_402656856 = body
  result = call_402656855.call(nil, nil, nil, nil, body_402656856)

var putItem* = Call_PutItem_402656842(name: "putItem",
                                      meth: HttpMethod.HttpPost,
                                      host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20120810.PutItem",
                                      validator: validate_PutItem_402656843,
                                      base: "/", makeUrl: url_PutItem_402656844,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_Query_402656857 = ref object of OpenApiRestCall_402656044
proc url_Query_402656859(protocol: Scheme; host: string; base: string;
                         route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Query_402656858(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>The <code>Query</code> operation finds items based on primary key values. You can query any table or secondary index that has a composite primary key (a partition key and a sort key). </p> <p>Use the <code>KeyConditionExpression</code> parameter to provide a specific value for the partition key. The <code>Query</code> operation will return all of the items from the table or index with that partition key value. You can optionally narrow the scope of the <code>Query</code> operation by specifying a sort key value and a comparison operator in <code>KeyConditionExpression</code>. To further refine the <code>Query</code> results, you can optionally provide a <code>FilterExpression</code>. A <code>FilterExpression</code> determines which items within the results should be returned to you. All of the other results are discarded. </p> <p> A <code>Query</code> operation always returns a result set. If no matching items are found, the result set will be empty. Queries that do not return results consume the minimum number of read capacity units for that type of read operation. </p> <note> <p> DynamoDB calculates the number of read capacity units consumed based on item size, not on the amount of data that is returned to an application. The number of capacity units consumed will be the same whether you request all of the attributes (the default behavior) or just some of them (using a projection expression). The number will also be the same whether or not you use a <code>FilterExpression</code>. </p> </note> <p> <code>Query</code> results are always sorted by the sort key value. If the data type of the sort key is Number, the results are returned in numeric order; otherwise, the results are returned in order of UTF-8 bytes. By default, the sort order is ascending. To reverse the order, set the <code>ScanIndexForward</code> parameter to false. </p> <p> A single <code>Query</code> operation will read up to the maximum number of items set (if using the <code>Limit</code> parameter) or a maximum of 1 MB of data and then apply any filtering to the results using <code>FilterExpression</code>. If <code>LastEvaluatedKey</code> is present in the response, you will need to paginate the result set. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Query.html#Query.Pagination">Paginating the Results</a> in the <i>Amazon DynamoDB Developer Guide</i>. </p> <p> <code>FilterExpression</code> is applied after a <code>Query</code> finishes, but before the results are returned. A <code>FilterExpression</code> cannot contain partition key or sort key attributes. You need to specify those attributes in the <code>KeyConditionExpression</code>. </p> <note> <p> A <code>Query</code> operation can return an empty result set and a <code>LastEvaluatedKey</code> if all the items read for the page of results are filtered out. </p> </note> <p>You can query a table, a local secondary index, or a global secondary index. For a query on a table or on a local secondary index, you can set the <code>ConsistentRead</code> parameter to <code>true</code> and obtain a strongly consistent result. Global secondary indexes support eventually consistent reads only, so do not specify <code>ConsistentRead</code> when querying a global secondary index.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ExclusiveStartKey: JString
                                  ##                    : Pagination token
  ##   Limit: 
                                                                          ## JString
                                                                          ##        
                                                                          ## : 
                                                                          ## Pagination 
                                                                          ## limit
  section = newJObject()
  var valid_402656860 = query.getOrDefault("ExclusiveStartKey")
  valid_402656860 = validateParameter(valid_402656860, JString,
                                      required = false, default = nil)
  if valid_402656860 != nil:
    section.add "ExclusiveStartKey", valid_402656860
  var valid_402656861 = query.getOrDefault("Limit")
  valid_402656861 = validateParameter(valid_402656861, JString,
                                      required = false, default = nil)
  if valid_402656861 != nil:
    section.add "Limit", valid_402656861
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656862 = header.getOrDefault("X-Amz-Target")
  valid_402656862 = validateParameter(valid_402656862, JString, required = true, default = newJString(
      "DynamoDB_20120810.Query"))
  if valid_402656862 != nil:
    section.add "X-Amz-Target", valid_402656862
  var valid_402656863 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656863 = validateParameter(valid_402656863, JString,
                                      required = false, default = nil)
  if valid_402656863 != nil:
    section.add "X-Amz-Security-Token", valid_402656863
  var valid_402656864 = header.getOrDefault("X-Amz-Signature")
  valid_402656864 = validateParameter(valid_402656864, JString,
                                      required = false, default = nil)
  if valid_402656864 != nil:
    section.add "X-Amz-Signature", valid_402656864
  var valid_402656865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656865 = validateParameter(valid_402656865, JString,
                                      required = false, default = nil)
  if valid_402656865 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656865
  var valid_402656866 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656866 = validateParameter(valid_402656866, JString,
                                      required = false, default = nil)
  if valid_402656866 != nil:
    section.add "X-Amz-Algorithm", valid_402656866
  var valid_402656867 = header.getOrDefault("X-Amz-Date")
  valid_402656867 = validateParameter(valid_402656867, JString,
                                      required = false, default = nil)
  if valid_402656867 != nil:
    section.add "X-Amz-Date", valid_402656867
  var valid_402656868 = header.getOrDefault("X-Amz-Credential")
  valid_402656868 = validateParameter(valid_402656868, JString,
                                      required = false, default = nil)
  if valid_402656868 != nil:
    section.add "X-Amz-Credential", valid_402656868
  var valid_402656869 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656869 = validateParameter(valid_402656869, JString,
                                      required = false, default = nil)
  if valid_402656869 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656869
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

proc call*(call_402656871: Call_Query_402656857; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>The <code>Query</code> operation finds items based on primary key values. You can query any table or secondary index that has a composite primary key (a partition key and a sort key). </p> <p>Use the <code>KeyConditionExpression</code> parameter to provide a specific value for the partition key. The <code>Query</code> operation will return all of the items from the table or index with that partition key value. You can optionally narrow the scope of the <code>Query</code> operation by specifying a sort key value and a comparison operator in <code>KeyConditionExpression</code>. To further refine the <code>Query</code> results, you can optionally provide a <code>FilterExpression</code>. A <code>FilterExpression</code> determines which items within the results should be returned to you. All of the other results are discarded. </p> <p> A <code>Query</code> operation always returns a result set. If no matching items are found, the result set will be empty. Queries that do not return results consume the minimum number of read capacity units for that type of read operation. </p> <note> <p> DynamoDB calculates the number of read capacity units consumed based on item size, not on the amount of data that is returned to an application. The number of capacity units consumed will be the same whether you request all of the attributes (the default behavior) or just some of them (using a projection expression). The number will also be the same whether or not you use a <code>FilterExpression</code>. </p> </note> <p> <code>Query</code> results are always sorted by the sort key value. If the data type of the sort key is Number, the results are returned in numeric order; otherwise, the results are returned in order of UTF-8 bytes. By default, the sort order is ascending. To reverse the order, set the <code>ScanIndexForward</code> parameter to false. </p> <p> A single <code>Query</code> operation will read up to the maximum number of items set (if using the <code>Limit</code> parameter) or a maximum of 1 MB of data and then apply any filtering to the results using <code>FilterExpression</code>. If <code>LastEvaluatedKey</code> is present in the response, you will need to paginate the result set. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Query.html#Query.Pagination">Paginating the Results</a> in the <i>Amazon DynamoDB Developer Guide</i>. </p> <p> <code>FilterExpression</code> is applied after a <code>Query</code> finishes, but before the results are returned. A <code>FilterExpression</code> cannot contain partition key or sort key attributes. You need to specify those attributes in the <code>KeyConditionExpression</code>. </p> <note> <p> A <code>Query</code> operation can return an empty result set and a <code>LastEvaluatedKey</code> if all the items read for the page of results are filtered out. </p> </note> <p>You can query a table, a local secondary index, or a global secondary index. For a query on a table or on a local secondary index, you can set the <code>ConsistentRead</code> parameter to <code>true</code> and obtain a strongly consistent result. Global secondary indexes support eventually consistent reads only, so do not specify <code>ConsistentRead</code> when querying a global secondary index.</p>
                                                                                         ## 
  let valid = call_402656871.validator(path, query, header, formData, body, _)
  let scheme = call_402656871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656871.makeUrl(scheme.get, call_402656871.host, call_402656871.base,
                                   call_402656871.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656871, uri, valid, _)

proc call*(call_402656872: Call_Query_402656857; body: JsonNode;
           ExclusiveStartKey: string = ""; Limit: string = ""): Recallable =
  ## query
  ## <p>The <code>Query</code> operation finds items based on primary key values. You can query any table or secondary index that has a composite primary key (a partition key and a sort key). </p> <p>Use the <code>KeyConditionExpression</code> parameter to provide a specific value for the partition key. The <code>Query</code> operation will return all of the items from the table or index with that partition key value. You can optionally narrow the scope of the <code>Query</code> operation by specifying a sort key value and a comparison operator in <code>KeyConditionExpression</code>. To further refine the <code>Query</code> results, you can optionally provide a <code>FilterExpression</code>. A <code>FilterExpression</code> determines which items within the results should be returned to you. All of the other results are discarded. </p> <p> A <code>Query</code> operation always returns a result set. If no matching items are found, the result set will be empty. Queries that do not return results consume the minimum number of read capacity units for that type of read operation. </p> <note> <p> DynamoDB calculates the number of read capacity units consumed based on item size, not on the amount of data that is returned to an application. The number of capacity units consumed will be the same whether you request all of the attributes (the default behavior) or just some of them (using a projection expression). The number will also be the same whether or not you use a <code>FilterExpression</code>. </p> </note> <p> <code>Query</code> results are always sorted by the sort key value. If the data type of the sort key is Number, the results are returned in numeric order; otherwise, the results are returned in order of UTF-8 bytes. By default, the sort order is ascending. To reverse the order, set the <code>ScanIndexForward</code> parameter to false. </p> <p> A single <code>Query</code> operation will read up to the maximum number of items set (if using the <code>Limit</code> parameter) or a maximum of 1 MB of data and then apply any filtering to the results using <code>FilterExpression</code>. If <code>LastEvaluatedKey</code> is present in the response, you will need to paginate the result set. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Query.html#Query.Pagination">Paginating the Results</a> in the <i>Amazon DynamoDB Developer Guide</i>. </p> <p> <code>FilterExpression</code> is applied after a <code>Query</code> finishes, but before the results are returned. A <code>FilterExpression</code> cannot contain partition key or sort key attributes. You need to specify those attributes in the <code>KeyConditionExpression</code>. </p> <note> <p> A <code>Query</code> operation can return an empty result set and a <code>LastEvaluatedKey</code> if all the items read for the page of results are filtered out. </p> </note> <p>You can query a table, a local secondary index, or a global secondary index. For a query on a table or on a local secondary index, you can set the <code>ConsistentRead</code> parameter to <code>true</code> and obtain a strongly consistent result. Global secondary indexes support eventually consistent reads only, so do not specify <code>ConsistentRead</code> when querying a global secondary index.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## ExclusiveStartKey: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ##                    
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## token
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Limit: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ##        
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## limit
  var query_402656873 = newJObject()
  var body_402656874 = newJObject()
  add(query_402656873, "ExclusiveStartKey", newJString(ExclusiveStartKey))
  if body != nil:
    body_402656874 = body
  add(query_402656873, "Limit", newJString(Limit))
  result = call_402656872.call(nil, query_402656873, nil, nil, body_402656874)

var query* = Call_Query_402656857(name: "query", meth: HttpMethod.HttpPost,
                                  host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20120810.Query",
                                  validator: validate_Query_402656858,
                                  base: "/", makeUrl: url_Query_402656859,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreTableFromBackup_402656875 = ref object of OpenApiRestCall_402656044
proc url_RestoreTableFromBackup_402656877(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RestoreTableFromBackup_402656876(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a new table from an existing backup. Any number of users can execute up to 4 concurrent restores (any type of restore) in a given account. </p> <p>You can call <code>RestoreTableFromBackup</code> at a maximum rate of 10 times per second.</p> <p>You must manually set up the following on the restored table:</p> <ul> <li> <p>Auto scaling policies</p> </li> <li> <p>IAM policies</p> </li> <li> <p>Amazon CloudWatch metrics and alarms</p> </li> <li> <p>Tags</p> </li> <li> <p>Stream settings</p> </li> <li> <p>Time to Live (TTL) settings</p> </li> </ul>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656878 = header.getOrDefault("X-Amz-Target")
  valid_402656878 = validateParameter(valid_402656878, JString, required = true, default = newJString(
      "DynamoDB_20120810.RestoreTableFromBackup"))
  if valid_402656878 != nil:
    section.add "X-Amz-Target", valid_402656878
  var valid_402656879 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656879 = validateParameter(valid_402656879, JString,
                                      required = false, default = nil)
  if valid_402656879 != nil:
    section.add "X-Amz-Security-Token", valid_402656879
  var valid_402656880 = header.getOrDefault("X-Amz-Signature")
  valid_402656880 = validateParameter(valid_402656880, JString,
                                      required = false, default = nil)
  if valid_402656880 != nil:
    section.add "X-Amz-Signature", valid_402656880
  var valid_402656881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656881 = validateParameter(valid_402656881, JString,
                                      required = false, default = nil)
  if valid_402656881 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656881
  var valid_402656882 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656882 = validateParameter(valid_402656882, JString,
                                      required = false, default = nil)
  if valid_402656882 != nil:
    section.add "X-Amz-Algorithm", valid_402656882
  var valid_402656883 = header.getOrDefault("X-Amz-Date")
  valid_402656883 = validateParameter(valid_402656883, JString,
                                      required = false, default = nil)
  if valid_402656883 != nil:
    section.add "X-Amz-Date", valid_402656883
  var valid_402656884 = header.getOrDefault("X-Amz-Credential")
  valid_402656884 = validateParameter(valid_402656884, JString,
                                      required = false, default = nil)
  if valid_402656884 != nil:
    section.add "X-Amz-Credential", valid_402656884
  var valid_402656885 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656885 = validateParameter(valid_402656885, JString,
                                      required = false, default = nil)
  if valid_402656885 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656885
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

proc call*(call_402656887: Call_RestoreTableFromBackup_402656875;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new table from an existing backup. Any number of users can execute up to 4 concurrent restores (any type of restore) in a given account. </p> <p>You can call <code>RestoreTableFromBackup</code> at a maximum rate of 10 times per second.</p> <p>You must manually set up the following on the restored table:</p> <ul> <li> <p>Auto scaling policies</p> </li> <li> <p>IAM policies</p> </li> <li> <p>Amazon CloudWatch metrics and alarms</p> </li> <li> <p>Tags</p> </li> <li> <p>Stream settings</p> </li> <li> <p>Time to Live (TTL) settings</p> </li> </ul>
                                                                                         ## 
  let valid = call_402656887.validator(path, query, header, formData, body, _)
  let scheme = call_402656887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656887.makeUrl(scheme.get, call_402656887.host, call_402656887.base,
                                   call_402656887.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656887, uri, valid, _)

proc call*(call_402656888: Call_RestoreTableFromBackup_402656875; body: JsonNode): Recallable =
  ## restoreTableFromBackup
  ## <p>Creates a new table from an existing backup. Any number of users can execute up to 4 concurrent restores (any type of restore) in a given account. </p> <p>You can call <code>RestoreTableFromBackup</code> at a maximum rate of 10 times per second.</p> <p>You must manually set up the following on the restored table:</p> <ul> <li> <p>Auto scaling policies</p> </li> <li> <p>IAM policies</p> </li> <li> <p>Amazon CloudWatch metrics and alarms</p> </li> <li> <p>Tags</p> </li> <li> <p>Stream settings</p> </li> <li> <p>Time to Live (TTL) settings</p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402656889 = newJObject()
  if body != nil:
    body_402656889 = body
  result = call_402656888.call(nil, nil, nil, nil, body_402656889)

var restoreTableFromBackup* = Call_RestoreTableFromBackup_402656875(
    name: "restoreTableFromBackup", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.RestoreTableFromBackup",
    validator: validate_RestoreTableFromBackup_402656876, base: "/",
    makeUrl: url_RestoreTableFromBackup_402656877,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreTableToPointInTime_402656890 = ref object of OpenApiRestCall_402656044
proc url_RestoreTableToPointInTime_402656892(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RestoreTableToPointInTime_402656891(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Restores the specified table to the specified point in time within <code>EarliestRestorableDateTime</code> and <code>LatestRestorableDateTime</code>. You can restore your table to any point in time during the last 35 days. Any number of users can execute up to 4 concurrent restores (any type of restore) in a given account. </p> <p> When you restore using point in time recovery, DynamoDB restores your table data to the state based on the selected date and time (day:hour:minute:second) to a new table. </p> <p> Along with data, the following are also included on the new restored table using point in time recovery: </p> <ul> <li> <p>Global secondary indexes (GSIs)</p> </li> <li> <p>Local secondary indexes (LSIs)</p> </li> <li> <p>Provisioned read and write capacity</p> </li> <li> <p>Encryption settings</p> <important> <p> All these settings come from the current settings of the source table at the time of restore. </p> </important> </li> </ul> <p>You must manually set up the following on the restored table:</p> <ul> <li> <p>Auto scaling policies</p> </li> <li> <p>IAM policies</p> </li> <li> <p>Amazon CloudWatch metrics and alarms</p> </li> <li> <p>Tags</p> </li> <li> <p>Stream settings</p> </li> <li> <p>Time to Live (TTL) settings</p> </li> <li> <p>Point in time recovery settings</p> </li> </ul>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656893 = header.getOrDefault("X-Amz-Target")
  valid_402656893 = validateParameter(valid_402656893, JString, required = true, default = newJString(
      "DynamoDB_20120810.RestoreTableToPointInTime"))
  if valid_402656893 != nil:
    section.add "X-Amz-Target", valid_402656893
  var valid_402656894 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656894 = validateParameter(valid_402656894, JString,
                                      required = false, default = nil)
  if valid_402656894 != nil:
    section.add "X-Amz-Security-Token", valid_402656894
  var valid_402656895 = header.getOrDefault("X-Amz-Signature")
  valid_402656895 = validateParameter(valid_402656895, JString,
                                      required = false, default = nil)
  if valid_402656895 != nil:
    section.add "X-Amz-Signature", valid_402656895
  var valid_402656896 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656896 = validateParameter(valid_402656896, JString,
                                      required = false, default = nil)
  if valid_402656896 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656896
  var valid_402656897 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656897 = validateParameter(valid_402656897, JString,
                                      required = false, default = nil)
  if valid_402656897 != nil:
    section.add "X-Amz-Algorithm", valid_402656897
  var valid_402656898 = header.getOrDefault("X-Amz-Date")
  valid_402656898 = validateParameter(valid_402656898, JString,
                                      required = false, default = nil)
  if valid_402656898 != nil:
    section.add "X-Amz-Date", valid_402656898
  var valid_402656899 = header.getOrDefault("X-Amz-Credential")
  valid_402656899 = validateParameter(valid_402656899, JString,
                                      required = false, default = nil)
  if valid_402656899 != nil:
    section.add "X-Amz-Credential", valid_402656899
  var valid_402656900 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656900 = validateParameter(valid_402656900, JString,
                                      required = false, default = nil)
  if valid_402656900 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656900
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

proc call*(call_402656902: Call_RestoreTableToPointInTime_402656890;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Restores the specified table to the specified point in time within <code>EarliestRestorableDateTime</code> and <code>LatestRestorableDateTime</code>. You can restore your table to any point in time during the last 35 days. Any number of users can execute up to 4 concurrent restores (any type of restore) in a given account. </p> <p> When you restore using point in time recovery, DynamoDB restores your table data to the state based on the selected date and time (day:hour:minute:second) to a new table. </p> <p> Along with data, the following are also included on the new restored table using point in time recovery: </p> <ul> <li> <p>Global secondary indexes (GSIs)</p> </li> <li> <p>Local secondary indexes (LSIs)</p> </li> <li> <p>Provisioned read and write capacity</p> </li> <li> <p>Encryption settings</p> <important> <p> All these settings come from the current settings of the source table at the time of restore. </p> </important> </li> </ul> <p>You must manually set up the following on the restored table:</p> <ul> <li> <p>Auto scaling policies</p> </li> <li> <p>IAM policies</p> </li> <li> <p>Amazon CloudWatch metrics and alarms</p> </li> <li> <p>Tags</p> </li> <li> <p>Stream settings</p> </li> <li> <p>Time to Live (TTL) settings</p> </li> <li> <p>Point in time recovery settings</p> </li> </ul>
                                                                                         ## 
  let valid = call_402656902.validator(path, query, header, formData, body, _)
  let scheme = call_402656902.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656902.makeUrl(scheme.get, call_402656902.host, call_402656902.base,
                                   call_402656902.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656902, uri, valid, _)

proc call*(call_402656903: Call_RestoreTableToPointInTime_402656890;
           body: JsonNode): Recallable =
  ## restoreTableToPointInTime
  ## <p>Restores the specified table to the specified point in time within <code>EarliestRestorableDateTime</code> and <code>LatestRestorableDateTime</code>. You can restore your table to any point in time during the last 35 days. Any number of users can execute up to 4 concurrent restores (any type of restore) in a given account. </p> <p> When you restore using point in time recovery, DynamoDB restores your table data to the state based on the selected date and time (day:hour:minute:second) to a new table. </p> <p> Along with data, the following are also included on the new restored table using point in time recovery: </p> <ul> <li> <p>Global secondary indexes (GSIs)</p> </li> <li> <p>Local secondary indexes (LSIs)</p> </li> <li> <p>Provisioned read and write capacity</p> </li> <li> <p>Encryption settings</p> <important> <p> All these settings come from the current settings of the source table at the time of restore. </p> </important> </li> </ul> <p>You must manually set up the following on the restored table:</p> <ul> <li> <p>Auto scaling policies</p> </li> <li> <p>IAM policies</p> </li> <li> <p>Amazon CloudWatch metrics and alarms</p> </li> <li> <p>Tags</p> </li> <li> <p>Stream settings</p> </li> <li> <p>Time to Live (TTL) settings</p> </li> <li> <p>Point in time recovery settings</p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402656904 = newJObject()
  if body != nil:
    body_402656904 = body
  result = call_402656903.call(nil, nil, nil, nil, body_402656904)

var restoreTableToPointInTime* = Call_RestoreTableToPointInTime_402656890(
    name: "restoreTableToPointInTime", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.RestoreTableToPointInTime",
    validator: validate_RestoreTableToPointInTime_402656891, base: "/",
    makeUrl: url_RestoreTableToPointInTime_402656892,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_Scan_402656905 = ref object of OpenApiRestCall_402656044
proc url_Scan_402656907(protocol: Scheme; host: string; base: string;
                        route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Scan_402656906(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>The <code>Scan</code> operation returns one or more items and item attributes by accessing every item in a table or a secondary index. To have DynamoDB return fewer items, you can provide a <code>FilterExpression</code> operation.</p> <p>If the total number of scanned items exceeds the maximum dataset size limit of 1 MB, the scan stops and results are returned to the user as a <code>LastEvaluatedKey</code> value to continue the scan in a subsequent operation. The results also include the number of items exceeding the limit. A scan can result in no table data meeting the filter criteria. </p> <p>A single <code>Scan</code> operation reads up to the maximum number of items set (if using the <code>Limit</code> parameter) or a maximum of 1 MB of data and then apply any filtering to the results using <code>FilterExpression</code>. If <code>LastEvaluatedKey</code> is present in the response, you need to paginate the result set. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Scan.html#Scan.Pagination">Paginating the Results</a> in the <i>Amazon DynamoDB Developer Guide</i>. </p> <p> <code>Scan</code> operations proceed sequentially; however, for faster performance on a large table or secondary index, applications can request a parallel <code>Scan</code> operation by providing the <code>Segment</code> and <code>TotalSegments</code> parameters. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Scan.html#Scan.ParallelScan">Parallel Scan</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p> <p> <code>Scan</code> uses eventually consistent reads when accessing the data in a table; therefore, the result set might not include the changes to data in the table immediately before the operation began. If you need a consistent copy of the data, as of the time that the <code>Scan</code> begins, you can set the <code>ConsistentRead</code> parameter to <code>true</code>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ExclusiveStartKey: JString
                                  ##                    : Pagination token
  ##   Limit: 
                                                                          ## JString
                                                                          ##        
                                                                          ## : 
                                                                          ## Pagination 
                                                                          ## limit
  section = newJObject()
  var valid_402656908 = query.getOrDefault("ExclusiveStartKey")
  valid_402656908 = validateParameter(valid_402656908, JString,
                                      required = false, default = nil)
  if valid_402656908 != nil:
    section.add "ExclusiveStartKey", valid_402656908
  var valid_402656909 = query.getOrDefault("Limit")
  valid_402656909 = validateParameter(valid_402656909, JString,
                                      required = false, default = nil)
  if valid_402656909 != nil:
    section.add "Limit", valid_402656909
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656910 = header.getOrDefault("X-Amz-Target")
  valid_402656910 = validateParameter(valid_402656910, JString, required = true, default = newJString(
      "DynamoDB_20120810.Scan"))
  if valid_402656910 != nil:
    section.add "X-Amz-Target", valid_402656910
  var valid_402656911 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656911 = validateParameter(valid_402656911, JString,
                                      required = false, default = nil)
  if valid_402656911 != nil:
    section.add "X-Amz-Security-Token", valid_402656911
  var valid_402656912 = header.getOrDefault("X-Amz-Signature")
  valid_402656912 = validateParameter(valid_402656912, JString,
                                      required = false, default = nil)
  if valid_402656912 != nil:
    section.add "X-Amz-Signature", valid_402656912
  var valid_402656913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656913 = validateParameter(valid_402656913, JString,
                                      required = false, default = nil)
  if valid_402656913 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656913
  var valid_402656914 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656914 = validateParameter(valid_402656914, JString,
                                      required = false, default = nil)
  if valid_402656914 != nil:
    section.add "X-Amz-Algorithm", valid_402656914
  var valid_402656915 = header.getOrDefault("X-Amz-Date")
  valid_402656915 = validateParameter(valid_402656915, JString,
                                      required = false, default = nil)
  if valid_402656915 != nil:
    section.add "X-Amz-Date", valid_402656915
  var valid_402656916 = header.getOrDefault("X-Amz-Credential")
  valid_402656916 = validateParameter(valid_402656916, JString,
                                      required = false, default = nil)
  if valid_402656916 != nil:
    section.add "X-Amz-Credential", valid_402656916
  var valid_402656917 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656917 = validateParameter(valid_402656917, JString,
                                      required = false, default = nil)
  if valid_402656917 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656917
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

proc call*(call_402656919: Call_Scan_402656905; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>The <code>Scan</code> operation returns one or more items and item attributes by accessing every item in a table or a secondary index. To have DynamoDB return fewer items, you can provide a <code>FilterExpression</code> operation.</p> <p>If the total number of scanned items exceeds the maximum dataset size limit of 1 MB, the scan stops and results are returned to the user as a <code>LastEvaluatedKey</code> value to continue the scan in a subsequent operation. The results also include the number of items exceeding the limit. A scan can result in no table data meeting the filter criteria. </p> <p>A single <code>Scan</code> operation reads up to the maximum number of items set (if using the <code>Limit</code> parameter) or a maximum of 1 MB of data and then apply any filtering to the results using <code>FilterExpression</code>. If <code>LastEvaluatedKey</code> is present in the response, you need to paginate the result set. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Scan.html#Scan.Pagination">Paginating the Results</a> in the <i>Amazon DynamoDB Developer Guide</i>. </p> <p> <code>Scan</code> operations proceed sequentially; however, for faster performance on a large table or secondary index, applications can request a parallel <code>Scan</code> operation by providing the <code>Segment</code> and <code>TotalSegments</code> parameters. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Scan.html#Scan.ParallelScan">Parallel Scan</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p> <p> <code>Scan</code> uses eventually consistent reads when accessing the data in a table; therefore, the result set might not include the changes to data in the table immediately before the operation began. If you need a consistent copy of the data, as of the time that the <code>Scan</code> begins, you can set the <code>ConsistentRead</code> parameter to <code>true</code>.</p>
                                                                                         ## 
  let valid = call_402656919.validator(path, query, header, formData, body, _)
  let scheme = call_402656919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656919.makeUrl(scheme.get, call_402656919.host, call_402656919.base,
                                   call_402656919.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656919, uri, valid, _)

proc call*(call_402656920: Call_Scan_402656905; body: JsonNode;
           ExclusiveStartKey: string = ""; Limit: string = ""): Recallable =
  ## scan
  ## <p>The <code>Scan</code> operation returns one or more items and item attributes by accessing every item in a table or a secondary index. To have DynamoDB return fewer items, you can provide a <code>FilterExpression</code> operation.</p> <p>If the total number of scanned items exceeds the maximum dataset size limit of 1 MB, the scan stops and results are returned to the user as a <code>LastEvaluatedKey</code> value to continue the scan in a subsequent operation. The results also include the number of items exceeding the limit. A scan can result in no table data meeting the filter criteria. </p> <p>A single <code>Scan</code> operation reads up to the maximum number of items set (if using the <code>Limit</code> parameter) or a maximum of 1 MB of data and then apply any filtering to the results using <code>FilterExpression</code>. If <code>LastEvaluatedKey</code> is present in the response, you need to paginate the result set. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Scan.html#Scan.Pagination">Paginating the Results</a> in the <i>Amazon DynamoDB Developer Guide</i>. </p> <p> <code>Scan</code> operations proceed sequentially; however, for faster performance on a large table or secondary index, applications can request a parallel <code>Scan</code> operation by providing the <code>Segment</code> and <code>TotalSegments</code> parameters. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Scan.html#Scan.ParallelScan">Parallel Scan</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p> <p> <code>Scan</code> uses eventually consistent reads when accessing the data in a table; therefore, the result set might not include the changes to data in the table immediately before the operation began. If you need a consistent copy of the data, as of the time that the <code>Scan</code> begins, you can set the <code>ConsistentRead</code> parameter to <code>true</code>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## ExclusiveStartKey: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ##                    
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## token
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## Limit: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ##        
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## limit
  var query_402656921 = newJObject()
  var body_402656922 = newJObject()
  add(query_402656921, "ExclusiveStartKey", newJString(ExclusiveStartKey))
  if body != nil:
    body_402656922 = body
  add(query_402656921, "Limit", newJString(Limit))
  result = call_402656920.call(nil, query_402656921, nil, nil, body_402656922)

var scan* = Call_Scan_402656905(name: "scan", meth: HttpMethod.HttpPost,
                                host: "dynamodb.amazonaws.com",
                                route: "/#X-Amz-Target=DynamoDB_20120810.Scan",
                                validator: validate_Scan_402656906, base: "/",
                                makeUrl: url_Scan_402656907,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656923 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402656925(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_402656924(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Associate a set of tags with an Amazon DynamoDB resource. You can then activate these user-defined tags so that they appear on the Billing and Cost Management console for cost allocation tracking. You can call TagResource up to five times per second, per account. </p> <p>For an overview on tagging DynamoDB resources, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html">Tagging for DynamoDB</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656926 = header.getOrDefault("X-Amz-Target")
  valid_402656926 = validateParameter(valid_402656926, JString, required = true, default = newJString(
      "DynamoDB_20120810.TagResource"))
  if valid_402656926 != nil:
    section.add "X-Amz-Target", valid_402656926
  var valid_402656927 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656927 = validateParameter(valid_402656927, JString,
                                      required = false, default = nil)
  if valid_402656927 != nil:
    section.add "X-Amz-Security-Token", valid_402656927
  var valid_402656928 = header.getOrDefault("X-Amz-Signature")
  valid_402656928 = validateParameter(valid_402656928, JString,
                                      required = false, default = nil)
  if valid_402656928 != nil:
    section.add "X-Amz-Signature", valid_402656928
  var valid_402656929 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656929 = validateParameter(valid_402656929, JString,
                                      required = false, default = nil)
  if valid_402656929 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656929
  var valid_402656930 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656930 = validateParameter(valid_402656930, JString,
                                      required = false, default = nil)
  if valid_402656930 != nil:
    section.add "X-Amz-Algorithm", valid_402656930
  var valid_402656931 = header.getOrDefault("X-Amz-Date")
  valid_402656931 = validateParameter(valid_402656931, JString,
                                      required = false, default = nil)
  if valid_402656931 != nil:
    section.add "X-Amz-Date", valid_402656931
  var valid_402656932 = header.getOrDefault("X-Amz-Credential")
  valid_402656932 = validateParameter(valid_402656932, JString,
                                      required = false, default = nil)
  if valid_402656932 != nil:
    section.add "X-Amz-Credential", valid_402656932
  var valid_402656933 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656933 = validateParameter(valid_402656933, JString,
                                      required = false, default = nil)
  if valid_402656933 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656933
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

proc call*(call_402656935: Call_TagResource_402656923; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Associate a set of tags with an Amazon DynamoDB resource. You can then activate these user-defined tags so that they appear on the Billing and Cost Management console for cost allocation tracking. You can call TagResource up to five times per second, per account. </p> <p>For an overview on tagging DynamoDB resources, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html">Tagging for DynamoDB</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656935.validator(path, query, header, formData, body, _)
  let scheme = call_402656935.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656935.makeUrl(scheme.get, call_402656935.host, call_402656935.base,
                                   call_402656935.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656935, uri, valid, _)

proc call*(call_402656936: Call_TagResource_402656923; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Associate a set of tags with an Amazon DynamoDB resource. You can then activate these user-defined tags so that they appear on the Billing and Cost Management console for cost allocation tracking. You can call TagResource up to five times per second, per account. </p> <p>For an overview on tagging DynamoDB resources, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html">Tagging for DynamoDB</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656937 = newJObject()
  if body != nil:
    body_402656937 = body
  result = call_402656936.call(nil, nil, nil, nil, body_402656937)

var tagResource* = Call_TagResource_402656923(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.TagResource",
    validator: validate_TagResource_402656924, base: "/",
    makeUrl: url_TagResource_402656925, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TransactGetItems_402656938 = ref object of OpenApiRestCall_402656044
proc url_TransactGetItems_402656940(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TransactGetItems_402656939(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p> <code>TransactGetItems</code> is a synchronous operation that atomically retrieves multiple items from one or more tables (but not from indexes) in a single account and Region. A <code>TransactGetItems</code> call can contain up to 25 <code>TransactGetItem</code> objects, each of which contains a <code>Get</code> structure that specifies an item to retrieve from a table in the account and Region. A call to <code>TransactGetItems</code> cannot retrieve items from tables in more than one AWS account or Region. The aggregate size of the items in the transaction cannot exceed 4 MB.</p> <p>DynamoDB rejects the entire <code>TransactGetItems</code> request if any of the following is true:</p> <ul> <li> <p>A conflicting operation is in the process of updating an item to be read.</p> </li> <li> <p>There is insufficient provisioned capacity for the transaction to be completed.</p> </li> <li> <p>There is a user error, such as an invalid data format.</p> </li> <li> <p>The aggregate size of the items in the transaction cannot exceed 4 MB.</p> </li> </ul>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656941 = header.getOrDefault("X-Amz-Target")
  valid_402656941 = validateParameter(valid_402656941, JString, required = true, default = newJString(
      "DynamoDB_20120810.TransactGetItems"))
  if valid_402656941 != nil:
    section.add "X-Amz-Target", valid_402656941
  var valid_402656942 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656942 = validateParameter(valid_402656942, JString,
                                      required = false, default = nil)
  if valid_402656942 != nil:
    section.add "X-Amz-Security-Token", valid_402656942
  var valid_402656943 = header.getOrDefault("X-Amz-Signature")
  valid_402656943 = validateParameter(valid_402656943, JString,
                                      required = false, default = nil)
  if valid_402656943 != nil:
    section.add "X-Amz-Signature", valid_402656943
  var valid_402656944 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656944 = validateParameter(valid_402656944, JString,
                                      required = false, default = nil)
  if valid_402656944 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656944
  var valid_402656945 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656945 = validateParameter(valid_402656945, JString,
                                      required = false, default = nil)
  if valid_402656945 != nil:
    section.add "X-Amz-Algorithm", valid_402656945
  var valid_402656946 = header.getOrDefault("X-Amz-Date")
  valid_402656946 = validateParameter(valid_402656946, JString,
                                      required = false, default = nil)
  if valid_402656946 != nil:
    section.add "X-Amz-Date", valid_402656946
  var valid_402656947 = header.getOrDefault("X-Amz-Credential")
  valid_402656947 = validateParameter(valid_402656947, JString,
                                      required = false, default = nil)
  if valid_402656947 != nil:
    section.add "X-Amz-Credential", valid_402656947
  var valid_402656948 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656948 = validateParameter(valid_402656948, JString,
                                      required = false, default = nil)
  if valid_402656948 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656948
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

proc call*(call_402656950: Call_TransactGetItems_402656938;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> <code>TransactGetItems</code> is a synchronous operation that atomically retrieves multiple items from one or more tables (but not from indexes) in a single account and Region. A <code>TransactGetItems</code> call can contain up to 25 <code>TransactGetItem</code> objects, each of which contains a <code>Get</code> structure that specifies an item to retrieve from a table in the account and Region. A call to <code>TransactGetItems</code> cannot retrieve items from tables in more than one AWS account or Region. The aggregate size of the items in the transaction cannot exceed 4 MB.</p> <p>DynamoDB rejects the entire <code>TransactGetItems</code> request if any of the following is true:</p> <ul> <li> <p>A conflicting operation is in the process of updating an item to be read.</p> </li> <li> <p>There is insufficient provisioned capacity for the transaction to be completed.</p> </li> <li> <p>There is a user error, such as an invalid data format.</p> </li> <li> <p>The aggregate size of the items in the transaction cannot exceed 4 MB.</p> </li> </ul>
                                                                                         ## 
  let valid = call_402656950.validator(path, query, header, formData, body, _)
  let scheme = call_402656950.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656950.makeUrl(scheme.get, call_402656950.host, call_402656950.base,
                                   call_402656950.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656950, uri, valid, _)

proc call*(call_402656951: Call_TransactGetItems_402656938; body: JsonNode): Recallable =
  ## transactGetItems
  ## <p> <code>TransactGetItems</code> is a synchronous operation that atomically retrieves multiple items from one or more tables (but not from indexes) in a single account and Region. A <code>TransactGetItems</code> call can contain up to 25 <code>TransactGetItem</code> objects, each of which contains a <code>Get</code> structure that specifies an item to retrieve from a table in the account and Region. A call to <code>TransactGetItems</code> cannot retrieve items from tables in more than one AWS account or Region. The aggregate size of the items in the transaction cannot exceed 4 MB.</p> <p>DynamoDB rejects the entire <code>TransactGetItems</code> request if any of the following is true:</p> <ul> <li> <p>A conflicting operation is in the process of updating an item to be read.</p> </li> <li> <p>There is insufficient provisioned capacity for the transaction to be completed.</p> </li> <li> <p>There is a user error, such as an invalid data format.</p> </li> <li> <p>The aggregate size of the items in the transaction cannot exceed 4 MB.</p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656952 = newJObject()
  if body != nil:
    body_402656952 = body
  result = call_402656951.call(nil, nil, nil, nil, body_402656952)

var transactGetItems* = Call_TransactGetItems_402656938(
    name: "transactGetItems", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.TransactGetItems",
    validator: validate_TransactGetItems_402656939, base: "/",
    makeUrl: url_TransactGetItems_402656940,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TransactWriteItems_402656953 = ref object of OpenApiRestCall_402656044
proc url_TransactWriteItems_402656955(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TransactWriteItems_402656954(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p> <code>TransactWriteItems</code> is a synchronous write operation that groups up to 25 action requests. These actions can target items in different tables, but not in different AWS accounts or Regions, and no two actions can target the same item. For example, you cannot both <code>ConditionCheck</code> and <code>Update</code> the same item. The aggregate size of the items in the transaction cannot exceed 4 MB.</p> <p>The actions are completed atomically so that either all of them succeed, or all of them fail. They are defined by the following objects:</p> <ul> <li> <p> <code>Put</code>  &#x97;   Initiates a <code>PutItem</code> operation to write a new item. This structure specifies the primary key of the item to be written, the name of the table to write it in, an optional condition expression that must be satisfied for the write to succeed, a list of the item's attributes, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> <li> <p> <code>Update</code>  &#x97;   Initiates an <code>UpdateItem</code> operation to update an existing item. This structure specifies the primary key of the item to be updated, the name of the table where it resides, an optional condition expression that must be satisfied for the update to succeed, an expression that defines one or more attributes to be updated, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> <li> <p> <code>Delete</code>  &#x97;   Initiates a <code>DeleteItem</code> operation to delete an existing item. This structure specifies the primary key of the item to be deleted, the name of the table where it resides, an optional condition expression that must be satisfied for the deletion to succeed, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> <li> <p> <code>ConditionCheck</code>  &#x97;   Applies a condition to an item that is not being modified by the transaction. This structure specifies the primary key of the item to be checked, the name of the table where it resides, a condition expression that must be satisfied for the transaction to succeed, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> </ul> <p>DynamoDB rejects the entire <code>TransactWriteItems</code> request if any of the following is true:</p> <ul> <li> <p>A condition in one of the condition expressions is not met.</p> </li> <li> <p>An ongoing operation is in the process of updating the same item.</p> </li> <li> <p>There is insufficient provisioned capacity for the transaction to be completed.</p> </li> <li> <p>An item size becomes too large (bigger than 400 KB), a local secondary index (LSI) becomes too large, or a similar validation error occurs because of changes made by the transaction.</p> </li> <li> <p>The aggregate size of the items in the transaction exceeds 4 MB.</p> </li> <li> <p>There is a user error, such as an invalid data format.</p> </li> </ul>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656956 = header.getOrDefault("X-Amz-Target")
  valid_402656956 = validateParameter(valid_402656956, JString, required = true, default = newJString(
      "DynamoDB_20120810.TransactWriteItems"))
  if valid_402656956 != nil:
    section.add "X-Amz-Target", valid_402656956
  var valid_402656957 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656957 = validateParameter(valid_402656957, JString,
                                      required = false, default = nil)
  if valid_402656957 != nil:
    section.add "X-Amz-Security-Token", valid_402656957
  var valid_402656958 = header.getOrDefault("X-Amz-Signature")
  valid_402656958 = validateParameter(valid_402656958, JString,
                                      required = false, default = nil)
  if valid_402656958 != nil:
    section.add "X-Amz-Signature", valid_402656958
  var valid_402656959 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656959 = validateParameter(valid_402656959, JString,
                                      required = false, default = nil)
  if valid_402656959 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656959
  var valid_402656960 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656960 = validateParameter(valid_402656960, JString,
                                      required = false, default = nil)
  if valid_402656960 != nil:
    section.add "X-Amz-Algorithm", valid_402656960
  var valid_402656961 = header.getOrDefault("X-Amz-Date")
  valid_402656961 = validateParameter(valid_402656961, JString,
                                      required = false, default = nil)
  if valid_402656961 != nil:
    section.add "X-Amz-Date", valid_402656961
  var valid_402656962 = header.getOrDefault("X-Amz-Credential")
  valid_402656962 = validateParameter(valid_402656962, JString,
                                      required = false, default = nil)
  if valid_402656962 != nil:
    section.add "X-Amz-Credential", valid_402656962
  var valid_402656963 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656963 = validateParameter(valid_402656963, JString,
                                      required = false, default = nil)
  if valid_402656963 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656963
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

proc call*(call_402656965: Call_TransactWriteItems_402656953;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> <code>TransactWriteItems</code> is a synchronous write operation that groups up to 25 action requests. These actions can target items in different tables, but not in different AWS accounts or Regions, and no two actions can target the same item. For example, you cannot both <code>ConditionCheck</code> and <code>Update</code> the same item. The aggregate size of the items in the transaction cannot exceed 4 MB.</p> <p>The actions are completed atomically so that either all of them succeed, or all of them fail. They are defined by the following objects:</p> <ul> <li> <p> <code>Put</code>  &#x97;   Initiates a <code>PutItem</code> operation to write a new item. This structure specifies the primary key of the item to be written, the name of the table to write it in, an optional condition expression that must be satisfied for the write to succeed, a list of the item's attributes, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> <li> <p> <code>Update</code>  &#x97;   Initiates an <code>UpdateItem</code> operation to update an existing item. This structure specifies the primary key of the item to be updated, the name of the table where it resides, an optional condition expression that must be satisfied for the update to succeed, an expression that defines one or more attributes to be updated, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> <li> <p> <code>Delete</code>  &#x97;   Initiates a <code>DeleteItem</code> operation to delete an existing item. This structure specifies the primary key of the item to be deleted, the name of the table where it resides, an optional condition expression that must be satisfied for the deletion to succeed, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> <li> <p> <code>ConditionCheck</code>  &#x97;   Applies a condition to an item that is not being modified by the transaction. This structure specifies the primary key of the item to be checked, the name of the table where it resides, a condition expression that must be satisfied for the transaction to succeed, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> </ul> <p>DynamoDB rejects the entire <code>TransactWriteItems</code> request if any of the following is true:</p> <ul> <li> <p>A condition in one of the condition expressions is not met.</p> </li> <li> <p>An ongoing operation is in the process of updating the same item.</p> </li> <li> <p>There is insufficient provisioned capacity for the transaction to be completed.</p> </li> <li> <p>An item size becomes too large (bigger than 400 KB), a local secondary index (LSI) becomes too large, or a similar validation error occurs because of changes made by the transaction.</p> </li> <li> <p>The aggregate size of the items in the transaction exceeds 4 MB.</p> </li> <li> <p>There is a user error, such as an invalid data format.</p> </li> </ul>
                                                                                         ## 
  let valid = call_402656965.validator(path, query, header, formData, body, _)
  let scheme = call_402656965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656965.makeUrl(scheme.get, call_402656965.host, call_402656965.base,
                                   call_402656965.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656965, uri, valid, _)

proc call*(call_402656966: Call_TransactWriteItems_402656953; body: JsonNode): Recallable =
  ## transactWriteItems
  ## <p> <code>TransactWriteItems</code> is a synchronous write operation that groups up to 25 action requests. These actions can target items in different tables, but not in different AWS accounts or Regions, and no two actions can target the same item. For example, you cannot both <code>ConditionCheck</code> and <code>Update</code> the same item. The aggregate size of the items in the transaction cannot exceed 4 MB.</p> <p>The actions are completed atomically so that either all of them succeed, or all of them fail. They are defined by the following objects:</p> <ul> <li> <p> <code>Put</code>  &#x97;   Initiates a <code>PutItem</code> operation to write a new item. This structure specifies the primary key of the item to be written, the name of the table to write it in, an optional condition expression that must be satisfied for the write to succeed, a list of the item's attributes, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> <li> <p> <code>Update</code>  &#x97;   Initiates an <code>UpdateItem</code> operation to update an existing item. This structure specifies the primary key of the item to be updated, the name of the table where it resides, an optional condition expression that must be satisfied for the update to succeed, an expression that defines one or more attributes to be updated, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> <li> <p> <code>Delete</code>  &#x97;   Initiates a <code>DeleteItem</code> operation to delete an existing item. This structure specifies the primary key of the item to be deleted, the name of the table where it resides, an optional condition expression that must be satisfied for the deletion to succeed, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> <li> <p> <code>ConditionCheck</code>  &#x97;   Applies a condition to an item that is not being modified by the transaction. This structure specifies the primary key of the item to be checked, the name of the table where it resides, a condition expression that must be satisfied for the transaction to succeed, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> </ul> <p>DynamoDB rejects the entire <code>TransactWriteItems</code> request if any of the following is true:</p> <ul> <li> <p>A condition in one of the condition expressions is not met.</p> </li> <li> <p>An ongoing operation is in the process of updating the same item.</p> </li> <li> <p>There is insufficient provisioned capacity for the transaction to be completed.</p> </li> <li> <p>An item size becomes too large (bigger than 400 KB), a local secondary index (LSI) becomes too large, or a similar validation error occurs because of changes made by the transaction.</p> </li> <li> <p>The aggregate size of the items in the transaction exceeds 4 MB.</p> </li> <li> <p>There is a user error, such as an invalid data format.</p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402656967 = newJObject()
  if body != nil:
    body_402656967 = body
  result = call_402656966.call(nil, nil, nil, nil, body_402656967)

var transactWriteItems* = Call_TransactWriteItems_402656953(
    name: "transactWriteItems", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.TransactWriteItems",
    validator: validate_TransactWriteItems_402656954, base: "/",
    makeUrl: url_TransactWriteItems_402656955,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656968 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402656970(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_402656969(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Removes the association of tags from an Amazon DynamoDB resource. You can call <code>UntagResource</code> up to five times per second, per account. </p> <p>For an overview on tagging DynamoDB resources, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html">Tagging for DynamoDB</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656971 = header.getOrDefault("X-Amz-Target")
  valid_402656971 = validateParameter(valid_402656971, JString, required = true, default = newJString(
      "DynamoDB_20120810.UntagResource"))
  if valid_402656971 != nil:
    section.add "X-Amz-Target", valid_402656971
  var valid_402656972 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656972 = validateParameter(valid_402656972, JString,
                                      required = false, default = nil)
  if valid_402656972 != nil:
    section.add "X-Amz-Security-Token", valid_402656972
  var valid_402656973 = header.getOrDefault("X-Amz-Signature")
  valid_402656973 = validateParameter(valid_402656973, JString,
                                      required = false, default = nil)
  if valid_402656973 != nil:
    section.add "X-Amz-Signature", valid_402656973
  var valid_402656974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656974 = validateParameter(valid_402656974, JString,
                                      required = false, default = nil)
  if valid_402656974 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656974
  var valid_402656975 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656975 = validateParameter(valid_402656975, JString,
                                      required = false, default = nil)
  if valid_402656975 != nil:
    section.add "X-Amz-Algorithm", valid_402656975
  var valid_402656976 = header.getOrDefault("X-Amz-Date")
  valid_402656976 = validateParameter(valid_402656976, JString,
                                      required = false, default = nil)
  if valid_402656976 != nil:
    section.add "X-Amz-Date", valid_402656976
  var valid_402656977 = header.getOrDefault("X-Amz-Credential")
  valid_402656977 = validateParameter(valid_402656977, JString,
                                      required = false, default = nil)
  if valid_402656977 != nil:
    section.add "X-Amz-Credential", valid_402656977
  var valid_402656978 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656978 = validateParameter(valid_402656978, JString,
                                      required = false, default = nil)
  if valid_402656978 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656978
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

proc call*(call_402656980: Call_UntagResource_402656968; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Removes the association of tags from an Amazon DynamoDB resource. You can call <code>UntagResource</code> up to five times per second, per account. </p> <p>For an overview on tagging DynamoDB resources, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html">Tagging for DynamoDB</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656980.validator(path, query, header, formData, body, _)
  let scheme = call_402656980.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656980.makeUrl(scheme.get, call_402656980.host, call_402656980.base,
                                   call_402656980.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656980, uri, valid, _)

proc call*(call_402656981: Call_UntagResource_402656968; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Removes the association of tags from an Amazon DynamoDB resource. You can call <code>UntagResource</code> up to five times per second, per account. </p> <p>For an overview on tagging DynamoDB resources, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html">Tagging for DynamoDB</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656982 = newJObject()
  if body != nil:
    body_402656982 = body
  result = call_402656981.call(nil, nil, nil, nil, body_402656982)

var untagResource* = Call_UntagResource_402656968(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.UntagResource",
    validator: validate_UntagResource_402656969, base: "/",
    makeUrl: url_UntagResource_402656970, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContinuousBackups_402656983 = ref object of OpenApiRestCall_402656044
proc url_UpdateContinuousBackups_402656985(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateContinuousBackups_402656984(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p> <code>UpdateContinuousBackups</code> enables or disables point in time recovery for the specified table. A successful <code>UpdateContinuousBackups</code> call returns the current <code>ContinuousBackupsDescription</code>. Continuous backups are <code>ENABLED</code> on all tables at table creation. If point in time recovery is enabled, <code>PointInTimeRecoveryStatus</code> will be set to ENABLED.</p> <p> Once continuous backups and point in time recovery are enabled, you can restore to any point in time within <code>EarliestRestorableDateTime</code> and <code>LatestRestorableDateTime</code>. </p> <p> <code>LatestRestorableDateTime</code> is typically 5 minutes before the current time. You can restore your table to any point in time during the last 35 days. </p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656986 = header.getOrDefault("X-Amz-Target")
  valid_402656986 = validateParameter(valid_402656986, JString, required = true, default = newJString(
      "DynamoDB_20120810.UpdateContinuousBackups"))
  if valid_402656986 != nil:
    section.add "X-Amz-Target", valid_402656986
  var valid_402656987 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656987 = validateParameter(valid_402656987, JString,
                                      required = false, default = nil)
  if valid_402656987 != nil:
    section.add "X-Amz-Security-Token", valid_402656987
  var valid_402656988 = header.getOrDefault("X-Amz-Signature")
  valid_402656988 = validateParameter(valid_402656988, JString,
                                      required = false, default = nil)
  if valid_402656988 != nil:
    section.add "X-Amz-Signature", valid_402656988
  var valid_402656989 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656989 = validateParameter(valid_402656989, JString,
                                      required = false, default = nil)
  if valid_402656989 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656989
  var valid_402656990 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656990 = validateParameter(valid_402656990, JString,
                                      required = false, default = nil)
  if valid_402656990 != nil:
    section.add "X-Amz-Algorithm", valid_402656990
  var valid_402656991 = header.getOrDefault("X-Amz-Date")
  valid_402656991 = validateParameter(valid_402656991, JString,
                                      required = false, default = nil)
  if valid_402656991 != nil:
    section.add "X-Amz-Date", valid_402656991
  var valid_402656992 = header.getOrDefault("X-Amz-Credential")
  valid_402656992 = validateParameter(valid_402656992, JString,
                                      required = false, default = nil)
  if valid_402656992 != nil:
    section.add "X-Amz-Credential", valid_402656992
  var valid_402656993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656993 = validateParameter(valid_402656993, JString,
                                      required = false, default = nil)
  if valid_402656993 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656993
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

proc call*(call_402656995: Call_UpdateContinuousBackups_402656983;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> <code>UpdateContinuousBackups</code> enables or disables point in time recovery for the specified table. A successful <code>UpdateContinuousBackups</code> call returns the current <code>ContinuousBackupsDescription</code>. Continuous backups are <code>ENABLED</code> on all tables at table creation. If point in time recovery is enabled, <code>PointInTimeRecoveryStatus</code> will be set to ENABLED.</p> <p> Once continuous backups and point in time recovery are enabled, you can restore to any point in time within <code>EarliestRestorableDateTime</code> and <code>LatestRestorableDateTime</code>. </p> <p> <code>LatestRestorableDateTime</code> is typically 5 minutes before the current time. You can restore your table to any point in time during the last 35 days. </p>
                                                                                         ## 
  let valid = call_402656995.validator(path, query, header, formData, body, _)
  let scheme = call_402656995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656995.makeUrl(scheme.get, call_402656995.host, call_402656995.base,
                                   call_402656995.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656995, uri, valid, _)

proc call*(call_402656996: Call_UpdateContinuousBackups_402656983;
           body: JsonNode): Recallable =
  ## updateContinuousBackups
  ## <p> <code>UpdateContinuousBackups</code> enables or disables point in time recovery for the specified table. A successful <code>UpdateContinuousBackups</code> call returns the current <code>ContinuousBackupsDescription</code>. Continuous backups are <code>ENABLED</code> on all tables at table creation. If point in time recovery is enabled, <code>PointInTimeRecoveryStatus</code> will be set to ENABLED.</p> <p> Once continuous backups and point in time recovery are enabled, you can restore to any point in time within <code>EarliestRestorableDateTime</code> and <code>LatestRestorableDateTime</code>. </p> <p> <code>LatestRestorableDateTime</code> is typically 5 minutes before the current time. You can restore your table to any point in time during the last 35 days. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402656997 = newJObject()
  if body != nil:
    body_402656997 = body
  result = call_402656996.call(nil, nil, nil, nil, body_402656997)

var updateContinuousBackups* = Call_UpdateContinuousBackups_402656983(
    name: "updateContinuousBackups", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.UpdateContinuousBackups",
    validator: validate_UpdateContinuousBackups_402656984, base: "/",
    makeUrl: url_UpdateContinuousBackups_402656985,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContributorInsights_402656998 = ref object of OpenApiRestCall_402656044
proc url_UpdateContributorInsights_402657000(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateContributorInsights_402656999(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Updates the status for contributor insights for a specific table or index.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657001 = header.getOrDefault("X-Amz-Target")
  valid_402657001 = validateParameter(valid_402657001, JString, required = true, default = newJString(
      "DynamoDB_20120810.UpdateContributorInsights"))
  if valid_402657001 != nil:
    section.add "X-Amz-Target", valid_402657001
  var valid_402657002 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657002 = validateParameter(valid_402657002, JString,
                                      required = false, default = nil)
  if valid_402657002 != nil:
    section.add "X-Amz-Security-Token", valid_402657002
  var valid_402657003 = header.getOrDefault("X-Amz-Signature")
  valid_402657003 = validateParameter(valid_402657003, JString,
                                      required = false, default = nil)
  if valid_402657003 != nil:
    section.add "X-Amz-Signature", valid_402657003
  var valid_402657004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657004 = validateParameter(valid_402657004, JString,
                                      required = false, default = nil)
  if valid_402657004 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657004
  var valid_402657005 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657005 = validateParameter(valid_402657005, JString,
                                      required = false, default = nil)
  if valid_402657005 != nil:
    section.add "X-Amz-Algorithm", valid_402657005
  var valid_402657006 = header.getOrDefault("X-Amz-Date")
  valid_402657006 = validateParameter(valid_402657006, JString,
                                      required = false, default = nil)
  if valid_402657006 != nil:
    section.add "X-Amz-Date", valid_402657006
  var valid_402657007 = header.getOrDefault("X-Amz-Credential")
  valid_402657007 = validateParameter(valid_402657007, JString,
                                      required = false, default = nil)
  if valid_402657007 != nil:
    section.add "X-Amz-Credential", valid_402657007
  var valid_402657008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657008 = validateParameter(valid_402657008, JString,
                                      required = false, default = nil)
  if valid_402657008 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657008
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

proc call*(call_402657010: Call_UpdateContributorInsights_402656998;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the status for contributor insights for a specific table or index.
                                                                                         ## 
  let valid = call_402657010.validator(path, query, header, formData, body, _)
  let scheme = call_402657010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657010.makeUrl(scheme.get, call_402657010.host, call_402657010.base,
                                   call_402657010.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657010, uri, valid, _)

proc call*(call_402657011: Call_UpdateContributorInsights_402656998;
           body: JsonNode): Recallable =
  ## updateContributorInsights
  ## Updates the status for contributor insights for a specific table or index.
  ##   
                                                                               ## body: JObject (required)
  var body_402657012 = newJObject()
  if body != nil:
    body_402657012 = body
  result = call_402657011.call(nil, nil, nil, nil, body_402657012)

var updateContributorInsights* = Call_UpdateContributorInsights_402656998(
    name: "updateContributorInsights", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.UpdateContributorInsights",
    validator: validate_UpdateContributorInsights_402656999, base: "/",
    makeUrl: url_UpdateContributorInsights_402657000,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGlobalTable_402657013 = ref object of OpenApiRestCall_402656044
proc url_UpdateGlobalTable_402657015(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateGlobalTable_402657014(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Adds or removes replicas in the specified global table. The global table must already exist to be able to use this operation. Any replica to be added must be empty, have the same name as the global table, have the same key schema, have DynamoDB Streams enabled, and have the same provisioned and maximum write capacity units.</p> <note> <p>Although you can use <code>UpdateGlobalTable</code> to add replicas and remove replicas in a single request, for simplicity we recommend that you issue separate requests for adding or removing replicas.</p> </note> <p> If global secondary indexes are specified, then the following conditions must also be met: </p> <ul> <li> <p> The global secondary indexes must have the same name. </p> </li> <li> <p> The global secondary indexes must have the same hash key and sort key (if present). </p> </li> <li> <p> The global secondary indexes must have the same provisioned and maximum write capacity units. </p> </li> </ul>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657016 = header.getOrDefault("X-Amz-Target")
  valid_402657016 = validateParameter(valid_402657016, JString, required = true, default = newJString(
      "DynamoDB_20120810.UpdateGlobalTable"))
  if valid_402657016 != nil:
    section.add "X-Amz-Target", valid_402657016
  var valid_402657017 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657017 = validateParameter(valid_402657017, JString,
                                      required = false, default = nil)
  if valid_402657017 != nil:
    section.add "X-Amz-Security-Token", valid_402657017
  var valid_402657018 = header.getOrDefault("X-Amz-Signature")
  valid_402657018 = validateParameter(valid_402657018, JString,
                                      required = false, default = nil)
  if valid_402657018 != nil:
    section.add "X-Amz-Signature", valid_402657018
  var valid_402657019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657019 = validateParameter(valid_402657019, JString,
                                      required = false, default = nil)
  if valid_402657019 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657019
  var valid_402657020 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657020 = validateParameter(valid_402657020, JString,
                                      required = false, default = nil)
  if valid_402657020 != nil:
    section.add "X-Amz-Algorithm", valid_402657020
  var valid_402657021 = header.getOrDefault("X-Amz-Date")
  valid_402657021 = validateParameter(valid_402657021, JString,
                                      required = false, default = nil)
  if valid_402657021 != nil:
    section.add "X-Amz-Date", valid_402657021
  var valid_402657022 = header.getOrDefault("X-Amz-Credential")
  valid_402657022 = validateParameter(valid_402657022, JString,
                                      required = false, default = nil)
  if valid_402657022 != nil:
    section.add "X-Amz-Credential", valid_402657022
  var valid_402657023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657023 = validateParameter(valid_402657023, JString,
                                      required = false, default = nil)
  if valid_402657023 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657023
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

proc call*(call_402657025: Call_UpdateGlobalTable_402657013;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds or removes replicas in the specified global table. The global table must already exist to be able to use this operation. Any replica to be added must be empty, have the same name as the global table, have the same key schema, have DynamoDB Streams enabled, and have the same provisioned and maximum write capacity units.</p> <note> <p>Although you can use <code>UpdateGlobalTable</code> to add replicas and remove replicas in a single request, for simplicity we recommend that you issue separate requests for adding or removing replicas.</p> </note> <p> If global secondary indexes are specified, then the following conditions must also be met: </p> <ul> <li> <p> The global secondary indexes must have the same name. </p> </li> <li> <p> The global secondary indexes must have the same hash key and sort key (if present). </p> </li> <li> <p> The global secondary indexes must have the same provisioned and maximum write capacity units. </p> </li> </ul>
                                                                                         ## 
  let valid = call_402657025.validator(path, query, header, formData, body, _)
  let scheme = call_402657025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657025.makeUrl(scheme.get, call_402657025.host, call_402657025.base,
                                   call_402657025.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657025, uri, valid, _)

proc call*(call_402657026: Call_UpdateGlobalTable_402657013; body: JsonNode): Recallable =
  ## updateGlobalTable
  ## <p>Adds or removes replicas in the specified global table. The global table must already exist to be able to use this operation. Any replica to be added must be empty, have the same name as the global table, have the same key schema, have DynamoDB Streams enabled, and have the same provisioned and maximum write capacity units.</p> <note> <p>Although you can use <code>UpdateGlobalTable</code> to add replicas and remove replicas in a single request, for simplicity we recommend that you issue separate requests for adding or removing replicas.</p> </note> <p> If global secondary indexes are specified, then the following conditions must also be met: </p> <ul> <li> <p> The global secondary indexes must have the same name. </p> </li> <li> <p> The global secondary indexes must have the same hash key and sort key (if present). </p> </li> <li> <p> The global secondary indexes must have the same provisioned and maximum write capacity units. </p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402657027 = newJObject()
  if body != nil:
    body_402657027 = body
  result = call_402657026.call(nil, nil, nil, nil, body_402657027)

var updateGlobalTable* = Call_UpdateGlobalTable_402657013(
    name: "updateGlobalTable", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.UpdateGlobalTable",
    validator: validate_UpdateGlobalTable_402657014, base: "/",
    makeUrl: url_UpdateGlobalTable_402657015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGlobalTableSettings_402657028 = ref object of OpenApiRestCall_402656044
proc url_UpdateGlobalTableSettings_402657030(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateGlobalTableSettings_402657029(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Updates settings for a global table.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657031 = header.getOrDefault("X-Amz-Target")
  valid_402657031 = validateParameter(valid_402657031, JString, required = true, default = newJString(
      "DynamoDB_20120810.UpdateGlobalTableSettings"))
  if valid_402657031 != nil:
    section.add "X-Amz-Target", valid_402657031
  var valid_402657032 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657032 = validateParameter(valid_402657032, JString,
                                      required = false, default = nil)
  if valid_402657032 != nil:
    section.add "X-Amz-Security-Token", valid_402657032
  var valid_402657033 = header.getOrDefault("X-Amz-Signature")
  valid_402657033 = validateParameter(valid_402657033, JString,
                                      required = false, default = nil)
  if valid_402657033 != nil:
    section.add "X-Amz-Signature", valid_402657033
  var valid_402657034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657034 = validateParameter(valid_402657034, JString,
                                      required = false, default = nil)
  if valid_402657034 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657034
  var valid_402657035 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657035 = validateParameter(valid_402657035, JString,
                                      required = false, default = nil)
  if valid_402657035 != nil:
    section.add "X-Amz-Algorithm", valid_402657035
  var valid_402657036 = header.getOrDefault("X-Amz-Date")
  valid_402657036 = validateParameter(valid_402657036, JString,
                                      required = false, default = nil)
  if valid_402657036 != nil:
    section.add "X-Amz-Date", valid_402657036
  var valid_402657037 = header.getOrDefault("X-Amz-Credential")
  valid_402657037 = validateParameter(valid_402657037, JString,
                                      required = false, default = nil)
  if valid_402657037 != nil:
    section.add "X-Amz-Credential", valid_402657037
  var valid_402657038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657038 = validateParameter(valid_402657038, JString,
                                      required = false, default = nil)
  if valid_402657038 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657038
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

proc call*(call_402657040: Call_UpdateGlobalTableSettings_402657028;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates settings for a global table.
                                                                                         ## 
  let valid = call_402657040.validator(path, query, header, formData, body, _)
  let scheme = call_402657040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657040.makeUrl(scheme.get, call_402657040.host, call_402657040.base,
                                   call_402657040.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657040, uri, valid, _)

proc call*(call_402657041: Call_UpdateGlobalTableSettings_402657028;
           body: JsonNode): Recallable =
  ## updateGlobalTableSettings
  ## Updates settings for a global table.
  ##   body: JObject (required)
  var body_402657042 = newJObject()
  if body != nil:
    body_402657042 = body
  result = call_402657041.call(nil, nil, nil, nil, body_402657042)

var updateGlobalTableSettings* = Call_UpdateGlobalTableSettings_402657028(
    name: "updateGlobalTableSettings", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.UpdateGlobalTableSettings",
    validator: validate_UpdateGlobalTableSettings_402657029, base: "/",
    makeUrl: url_UpdateGlobalTableSettings_402657030,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateItem_402657043 = ref object of OpenApiRestCall_402656044
proc url_UpdateItem_402657045(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateItem_402657044(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Edits an existing item's attributes, or adds a new item to the table if it does not already exist. You can put, delete, or add attribute values. You can also perform a conditional update on an existing item (insert a new attribute name-value pair if it doesn't exist, or replace an existing name-value pair if it has certain expected attribute values).</p> <p>You can also return the item's attribute values in the same <code>UpdateItem</code> operation using the <code>ReturnValues</code> parameter.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657046 = header.getOrDefault("X-Amz-Target")
  valid_402657046 = validateParameter(valid_402657046, JString, required = true, default = newJString(
      "DynamoDB_20120810.UpdateItem"))
  if valid_402657046 != nil:
    section.add "X-Amz-Target", valid_402657046
  var valid_402657047 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657047 = validateParameter(valid_402657047, JString,
                                      required = false, default = nil)
  if valid_402657047 != nil:
    section.add "X-Amz-Security-Token", valid_402657047
  var valid_402657048 = header.getOrDefault("X-Amz-Signature")
  valid_402657048 = validateParameter(valid_402657048, JString,
                                      required = false, default = nil)
  if valid_402657048 != nil:
    section.add "X-Amz-Signature", valid_402657048
  var valid_402657049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657049 = validateParameter(valid_402657049, JString,
                                      required = false, default = nil)
  if valid_402657049 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657049
  var valid_402657050 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657050 = validateParameter(valid_402657050, JString,
                                      required = false, default = nil)
  if valid_402657050 != nil:
    section.add "X-Amz-Algorithm", valid_402657050
  var valid_402657051 = header.getOrDefault("X-Amz-Date")
  valid_402657051 = validateParameter(valid_402657051, JString,
                                      required = false, default = nil)
  if valid_402657051 != nil:
    section.add "X-Amz-Date", valid_402657051
  var valid_402657052 = header.getOrDefault("X-Amz-Credential")
  valid_402657052 = validateParameter(valid_402657052, JString,
                                      required = false, default = nil)
  if valid_402657052 != nil:
    section.add "X-Amz-Credential", valid_402657052
  var valid_402657053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657053 = validateParameter(valid_402657053, JString,
                                      required = false, default = nil)
  if valid_402657053 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657053
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

proc call*(call_402657055: Call_UpdateItem_402657043; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Edits an existing item's attributes, or adds a new item to the table if it does not already exist. You can put, delete, or add attribute values. You can also perform a conditional update on an existing item (insert a new attribute name-value pair if it doesn't exist, or replace an existing name-value pair if it has certain expected attribute values).</p> <p>You can also return the item's attribute values in the same <code>UpdateItem</code> operation using the <code>ReturnValues</code> parameter.</p>
                                                                                         ## 
  let valid = call_402657055.validator(path, query, header, formData, body, _)
  let scheme = call_402657055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657055.makeUrl(scheme.get, call_402657055.host, call_402657055.base,
                                   call_402657055.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657055, uri, valid, _)

proc call*(call_402657056: Call_UpdateItem_402657043; body: JsonNode): Recallable =
  ## updateItem
  ## <p>Edits an existing item's attributes, or adds a new item to the table if it does not already exist. You can put, delete, or add attribute values. You can also perform a conditional update on an existing item (insert a new attribute name-value pair if it doesn't exist, or replace an existing name-value pair if it has certain expected attribute values).</p> <p>You can also return the item's attribute values in the same <code>UpdateItem</code> operation using the <code>ReturnValues</code> parameter.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var body_402657057 = newJObject()
  if body != nil:
    body_402657057 = body
  result = call_402657056.call(nil, nil, nil, nil, body_402657057)

var updateItem* = Call_UpdateItem_402657043(name: "updateItem",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.UpdateItem",
    validator: validate_UpdateItem_402657044, base: "/",
    makeUrl: url_UpdateItem_402657045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTable_402657058 = ref object of OpenApiRestCall_402656044
proc url_UpdateTable_402657060(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTable_402657059(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Modifies the provisioned throughput settings, global secondary indexes, or DynamoDB Streams settings for a given table.</p> <p>You can only perform one of the following operations at once:</p> <ul> <li> <p>Modify the provisioned throughput settings of the table.</p> </li> <li> <p>Enable or disable DynamoDB Streams on the table.</p> </li> <li> <p>Remove a global secondary index from the table.</p> </li> <li> <p>Create a new global secondary index on the table. After the index begins backfilling, you can use <code>UpdateTable</code> to perform other operations.</p> </li> </ul> <p> <code>UpdateTable</code> is an asynchronous operation; while it is executing, the table status changes from <code>ACTIVE</code> to <code>UPDATING</code>. While it is <code>UPDATING</code>, you cannot issue another <code>UpdateTable</code> request. When the table returns to the <code>ACTIVE</code> state, the <code>UpdateTable</code> operation is complete.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657061 = header.getOrDefault("X-Amz-Target")
  valid_402657061 = validateParameter(valid_402657061, JString, required = true, default = newJString(
      "DynamoDB_20120810.UpdateTable"))
  if valid_402657061 != nil:
    section.add "X-Amz-Target", valid_402657061
  var valid_402657062 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657062 = validateParameter(valid_402657062, JString,
                                      required = false, default = nil)
  if valid_402657062 != nil:
    section.add "X-Amz-Security-Token", valid_402657062
  var valid_402657063 = header.getOrDefault("X-Amz-Signature")
  valid_402657063 = validateParameter(valid_402657063, JString,
                                      required = false, default = nil)
  if valid_402657063 != nil:
    section.add "X-Amz-Signature", valid_402657063
  var valid_402657064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657064 = validateParameter(valid_402657064, JString,
                                      required = false, default = nil)
  if valid_402657064 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657064
  var valid_402657065 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657065 = validateParameter(valid_402657065, JString,
                                      required = false, default = nil)
  if valid_402657065 != nil:
    section.add "X-Amz-Algorithm", valid_402657065
  var valid_402657066 = header.getOrDefault("X-Amz-Date")
  valid_402657066 = validateParameter(valid_402657066, JString,
                                      required = false, default = nil)
  if valid_402657066 != nil:
    section.add "X-Amz-Date", valid_402657066
  var valid_402657067 = header.getOrDefault("X-Amz-Credential")
  valid_402657067 = validateParameter(valid_402657067, JString,
                                      required = false, default = nil)
  if valid_402657067 != nil:
    section.add "X-Amz-Credential", valid_402657067
  var valid_402657068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657068 = validateParameter(valid_402657068, JString,
                                      required = false, default = nil)
  if valid_402657068 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657068
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

proc call*(call_402657070: Call_UpdateTable_402657058; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Modifies the provisioned throughput settings, global secondary indexes, or DynamoDB Streams settings for a given table.</p> <p>You can only perform one of the following operations at once:</p> <ul> <li> <p>Modify the provisioned throughput settings of the table.</p> </li> <li> <p>Enable or disable DynamoDB Streams on the table.</p> </li> <li> <p>Remove a global secondary index from the table.</p> </li> <li> <p>Create a new global secondary index on the table. After the index begins backfilling, you can use <code>UpdateTable</code> to perform other operations.</p> </li> </ul> <p> <code>UpdateTable</code> is an asynchronous operation; while it is executing, the table status changes from <code>ACTIVE</code> to <code>UPDATING</code>. While it is <code>UPDATING</code>, you cannot issue another <code>UpdateTable</code> request. When the table returns to the <code>ACTIVE</code> state, the <code>UpdateTable</code> operation is complete.</p>
                                                                                         ## 
  let valid = call_402657070.validator(path, query, header, formData, body, _)
  let scheme = call_402657070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657070.makeUrl(scheme.get, call_402657070.host, call_402657070.base,
                                   call_402657070.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657070, uri, valid, _)

proc call*(call_402657071: Call_UpdateTable_402657058; body: JsonNode): Recallable =
  ## updateTable
  ## <p>Modifies the provisioned throughput settings, global secondary indexes, or DynamoDB Streams settings for a given table.</p> <p>You can only perform one of the following operations at once:</p> <ul> <li> <p>Modify the provisioned throughput settings of the table.</p> </li> <li> <p>Enable or disable DynamoDB Streams on the table.</p> </li> <li> <p>Remove a global secondary index from the table.</p> </li> <li> <p>Create a new global secondary index on the table. After the index begins backfilling, you can use <code>UpdateTable</code> to perform other operations.</p> </li> </ul> <p> <code>UpdateTable</code> is an asynchronous operation; while it is executing, the table status changes from <code>ACTIVE</code> to <code>UPDATING</code>. While it is <code>UPDATING</code>, you cannot issue another <code>UpdateTable</code> request. When the table returns to the <code>ACTIVE</code> state, the <code>UpdateTable</code> operation is complete.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402657072 = newJObject()
  if body != nil:
    body_402657072 = body
  result = call_402657071.call(nil, nil, nil, nil, body_402657072)

var updateTable* = Call_UpdateTable_402657058(name: "updateTable",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.UpdateTable",
    validator: validate_UpdateTable_402657059, base: "/",
    makeUrl: url_UpdateTable_402657060, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTableReplicaAutoScaling_402657073 = ref object of OpenApiRestCall_402656044
proc url_UpdateTableReplicaAutoScaling_402657075(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTableReplicaAutoScaling_402657074(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Updates auto scaling settings on your global tables at once.</p> <note> <p>This method only applies to <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html">Version 2019.11.21</a> of global tables.</p> </note>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657076 = header.getOrDefault("X-Amz-Target")
  valid_402657076 = validateParameter(valid_402657076, JString, required = true, default = newJString(
      "DynamoDB_20120810.UpdateTableReplicaAutoScaling"))
  if valid_402657076 != nil:
    section.add "X-Amz-Target", valid_402657076
  var valid_402657077 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657077 = validateParameter(valid_402657077, JString,
                                      required = false, default = nil)
  if valid_402657077 != nil:
    section.add "X-Amz-Security-Token", valid_402657077
  var valid_402657078 = header.getOrDefault("X-Amz-Signature")
  valid_402657078 = validateParameter(valid_402657078, JString,
                                      required = false, default = nil)
  if valid_402657078 != nil:
    section.add "X-Amz-Signature", valid_402657078
  var valid_402657079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657079 = validateParameter(valid_402657079, JString,
                                      required = false, default = nil)
  if valid_402657079 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657079
  var valid_402657080 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657080 = validateParameter(valid_402657080, JString,
                                      required = false, default = nil)
  if valid_402657080 != nil:
    section.add "X-Amz-Algorithm", valid_402657080
  var valid_402657081 = header.getOrDefault("X-Amz-Date")
  valid_402657081 = validateParameter(valid_402657081, JString,
                                      required = false, default = nil)
  if valid_402657081 != nil:
    section.add "X-Amz-Date", valid_402657081
  var valid_402657082 = header.getOrDefault("X-Amz-Credential")
  valid_402657082 = validateParameter(valid_402657082, JString,
                                      required = false, default = nil)
  if valid_402657082 != nil:
    section.add "X-Amz-Credential", valid_402657082
  var valid_402657083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657083 = validateParameter(valid_402657083, JString,
                                      required = false, default = nil)
  if valid_402657083 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657083
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

proc call*(call_402657085: Call_UpdateTableReplicaAutoScaling_402657073;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates auto scaling settings on your global tables at once.</p> <note> <p>This method only applies to <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html">Version 2019.11.21</a> of global tables.</p> </note>
                                                                                         ## 
  let valid = call_402657085.validator(path, query, header, formData, body, _)
  let scheme = call_402657085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657085.makeUrl(scheme.get, call_402657085.host, call_402657085.base,
                                   call_402657085.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657085, uri, valid, _)

proc call*(call_402657086: Call_UpdateTableReplicaAutoScaling_402657073;
           body: JsonNode): Recallable =
  ## updateTableReplicaAutoScaling
  ## <p>Updates auto scaling settings on your global tables at once.</p> <note> <p>This method only applies to <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html">Version 2019.11.21</a> of global tables.</p> </note>
  ##   
                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402657087 = newJObject()
  if body != nil:
    body_402657087 = body
  result = call_402657086.call(nil, nil, nil, nil, body_402657087)

var updateTableReplicaAutoScaling* = Call_UpdateTableReplicaAutoScaling_402657073(
    name: "updateTableReplicaAutoScaling", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.UpdateTableReplicaAutoScaling",
    validator: validate_UpdateTableReplicaAutoScaling_402657074, base: "/",
    makeUrl: url_UpdateTableReplicaAutoScaling_402657075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTimeToLive_402657088 = ref object of OpenApiRestCall_402656044
proc url_UpdateTimeToLive_402657090(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTimeToLive_402657089(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>The <code>UpdateTimeToLive</code> method enables or disables Time to Live (TTL) for the specified table. A successful <code>UpdateTimeToLive</code> call returns the current <code>TimeToLiveSpecification</code>. It can take up to one hour for the change to fully process. Any additional <code>UpdateTimeToLive</code> calls for the same table during this one hour duration result in a <code>ValidationException</code>. </p> <p>TTL compares the current time in epoch time format to the time stored in the TTL attribute of an item. If the epoch time value stored in the attribute is less than the current time, the item is marked as expired and subsequently deleted.</p> <note> <p> The epoch time format is the number of seconds elapsed since 12:00:00 AM January 1, 1970 UTC. </p> </note> <p>DynamoDB deletes expired items on a best-effort basis to ensure availability of throughput for other data operations. </p> <important> <p>DynamoDB typically deletes expired items within two days of expiration. The exact duration within which an item gets deleted after expiration is specific to the nature of the workload. Items that have expired and not been deleted will still show up in reads, queries, and scans.</p> </important> <p>As items are deleted, they are removed from any local secondary index and global secondary index immediately in the same eventually consistent way as a standard delete operation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/TTL.html">Time To Live</a> in the Amazon DynamoDB Developer Guide. </p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657091 = header.getOrDefault("X-Amz-Target")
  valid_402657091 = validateParameter(valid_402657091, JString, required = true, default = newJString(
      "DynamoDB_20120810.UpdateTimeToLive"))
  if valid_402657091 != nil:
    section.add "X-Amz-Target", valid_402657091
  var valid_402657092 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657092 = validateParameter(valid_402657092, JString,
                                      required = false, default = nil)
  if valid_402657092 != nil:
    section.add "X-Amz-Security-Token", valid_402657092
  var valid_402657093 = header.getOrDefault("X-Amz-Signature")
  valid_402657093 = validateParameter(valid_402657093, JString,
                                      required = false, default = nil)
  if valid_402657093 != nil:
    section.add "X-Amz-Signature", valid_402657093
  var valid_402657094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657094 = validateParameter(valid_402657094, JString,
                                      required = false, default = nil)
  if valid_402657094 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657094
  var valid_402657095 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657095 = validateParameter(valid_402657095, JString,
                                      required = false, default = nil)
  if valid_402657095 != nil:
    section.add "X-Amz-Algorithm", valid_402657095
  var valid_402657096 = header.getOrDefault("X-Amz-Date")
  valid_402657096 = validateParameter(valid_402657096, JString,
                                      required = false, default = nil)
  if valid_402657096 != nil:
    section.add "X-Amz-Date", valid_402657096
  var valid_402657097 = header.getOrDefault("X-Amz-Credential")
  valid_402657097 = validateParameter(valid_402657097, JString,
                                      required = false, default = nil)
  if valid_402657097 != nil:
    section.add "X-Amz-Credential", valid_402657097
  var valid_402657098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657098 = validateParameter(valid_402657098, JString,
                                      required = false, default = nil)
  if valid_402657098 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657098
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

proc call*(call_402657100: Call_UpdateTimeToLive_402657088;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>The <code>UpdateTimeToLive</code> method enables or disables Time to Live (TTL) for the specified table. A successful <code>UpdateTimeToLive</code> call returns the current <code>TimeToLiveSpecification</code>. It can take up to one hour for the change to fully process. Any additional <code>UpdateTimeToLive</code> calls for the same table during this one hour duration result in a <code>ValidationException</code>. </p> <p>TTL compares the current time in epoch time format to the time stored in the TTL attribute of an item. If the epoch time value stored in the attribute is less than the current time, the item is marked as expired and subsequently deleted.</p> <note> <p> The epoch time format is the number of seconds elapsed since 12:00:00 AM January 1, 1970 UTC. </p> </note> <p>DynamoDB deletes expired items on a best-effort basis to ensure availability of throughput for other data operations. </p> <important> <p>DynamoDB typically deletes expired items within two days of expiration. The exact duration within which an item gets deleted after expiration is specific to the nature of the workload. Items that have expired and not been deleted will still show up in reads, queries, and scans.</p> </important> <p>As items are deleted, they are removed from any local secondary index and global secondary index immediately in the same eventually consistent way as a standard delete operation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/TTL.html">Time To Live</a> in the Amazon DynamoDB Developer Guide. </p>
                                                                                         ## 
  let valid = call_402657100.validator(path, query, header, formData, body, _)
  let scheme = call_402657100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657100.makeUrl(scheme.get, call_402657100.host, call_402657100.base,
                                   call_402657100.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657100, uri, valid, _)

proc call*(call_402657101: Call_UpdateTimeToLive_402657088; body: JsonNode): Recallable =
  ## updateTimeToLive
  ## <p>The <code>UpdateTimeToLive</code> method enables or disables Time to Live (TTL) for the specified table. A successful <code>UpdateTimeToLive</code> call returns the current <code>TimeToLiveSpecification</code>. It can take up to one hour for the change to fully process. Any additional <code>UpdateTimeToLive</code> calls for the same table during this one hour duration result in a <code>ValidationException</code>. </p> <p>TTL compares the current time in epoch time format to the time stored in the TTL attribute of an item. If the epoch time value stored in the attribute is less than the current time, the item is marked as expired and subsequently deleted.</p> <note> <p> The epoch time format is the number of seconds elapsed since 12:00:00 AM January 1, 1970 UTC. </p> </note> <p>DynamoDB deletes expired items on a best-effort basis to ensure availability of throughput for other data operations. </p> <important> <p>DynamoDB typically deletes expired items within two days of expiration. The exact duration within which an item gets deleted after expiration is specific to the nature of the workload. Items that have expired and not been deleted will still show up in reads, queries, and scans.</p> </important> <p>As items are deleted, they are removed from any local secondary index and global secondary index immediately in the same eventually consistent way as a standard delete operation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/TTL.html">Time To Live</a> in the Amazon DynamoDB Developer Guide. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402657102 = newJObject()
  if body != nil:
    body_402657102 = body
  result = call_402657101.call(nil, nil, nil, nil, body_402657102)

var updateTimeToLive* = Call_UpdateTimeToLive_402657088(
    name: "updateTimeToLive", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.UpdateTimeToLive",
    validator: validate_UpdateTimeToLive_402657089, base: "/",
    makeUrl: url_UpdateTimeToLive_402657090,
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
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
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