
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
      "DynamoDB_20120810.BatchGetItem"))
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
  ## <p>The <code>BatchGetItem</code> operation returns the attributes of one or more items from one or more tables. You identify requested items by primary key.</p> <p>A single operation can retrieve up to 16 MB of data, which can contain as many as 100 items. <code>BatchGetItem</code> returns a partial result if the response size limit is exceeded, the table's provisioned throughput is exceeded, or an internal processing failure occurs. If a partial result is returned, the operation returns a value for <code>UnprocessedKeys</code>. You can use this value to retry the operation starting with the next item to get.</p> <important> <p>If you request more than 100 items, <code>BatchGetItem</code> returns a <code>ValidationException</code> with the message "Too many items requested for the BatchGetItem call."</p> </important> <p>For example, if you ask to retrieve 100 items, but each individual item is 300 KB in size, the system returns 52 items (so as not to exceed the 16 MB limit). It also returns an appropriate <code>UnprocessedKeys</code> value so you can get the next page of results. If desired, your application can include its own logic to assemble the pages of results into one dataset.</p> <p>If <i>none</i> of the items can be processed due to insufficient provisioned throughput on all of the tables in the request, then <code>BatchGetItem</code> returns a <code>ProvisionedThroughputExceededException</code>. If <i>at least one</i> of the items is successfully processed, then <code>BatchGetItem</code> completes successfully, while returning the keys of the unread items in <code>UnprocessedKeys</code>.</p> <important> <p>If DynamoDB returns any unprocessed items, you should retry the batch operation on those items. However, <i>we strongly recommend that you use an exponential backoff algorithm</i>. If you retry the batch operation immediately, the underlying read or write requests can still fail due to throttling on the individual tables. If you delay the batch operation using exponential backoff, the individual requests in the batch are much more likely to succeed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ErrorHandling.html#BatchOperations">Batch Operations and Error Handling</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p> </important> <p>By default, <code>BatchGetItem</code> performs eventually consistent reads on every table in the request. If you want strongly consistent reads instead, you can set <code>ConsistentRead</code> to <code>true</code> for any or all tables.</p> <p>In order to minimize response latency, <code>BatchGetItem</code> retrieves items in parallel.</p> <p>When designing your application, keep in mind that DynamoDB does not return items in any particular order. To help parse the response by item, include the primary key values for the items in your request in the <code>ProjectionExpression</code> parameter.</p> <p>If a requested item does not exist, it is not returned in the result. Requests for nonexistent items consume the minimum read capacity units according to the type of read. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/WorkingWithTables.html#CapacityUnitCalculations">Working with Tables</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
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
  ## <p>The <code>BatchGetItem</code> operation returns the attributes of one or more items from one or more tables. You identify requested items by primary key.</p> <p>A single operation can retrieve up to 16 MB of data, which can contain as many as 100 items. <code>BatchGetItem</code> returns a partial result if the response size limit is exceeded, the table's provisioned throughput is exceeded, or an internal processing failure occurs. If a partial result is returned, the operation returns a value for <code>UnprocessedKeys</code>. You can use this value to retry the operation starting with the next item to get.</p> <important> <p>If you request more than 100 items, <code>BatchGetItem</code> returns a <code>ValidationException</code> with the message "Too many items requested for the BatchGetItem call."</p> </important> <p>For example, if you ask to retrieve 100 items, but each individual item is 300 KB in size, the system returns 52 items (so as not to exceed the 16 MB limit). It also returns an appropriate <code>UnprocessedKeys</code> value so you can get the next page of results. If desired, your application can include its own logic to assemble the pages of results into one dataset.</p> <p>If <i>none</i> of the items can be processed due to insufficient provisioned throughput on all of the tables in the request, then <code>BatchGetItem</code> returns a <code>ProvisionedThroughputExceededException</code>. If <i>at least one</i> of the items is successfully processed, then <code>BatchGetItem</code> completes successfully, while returning the keys of the unread items in <code>UnprocessedKeys</code>.</p> <important> <p>If DynamoDB returns any unprocessed items, you should retry the batch operation on those items. However, <i>we strongly recommend that you use an exponential backoff algorithm</i>. If you retry the batch operation immediately, the underlying read or write requests can still fail due to throttling on the individual tables. If you delay the batch operation using exponential backoff, the individual requests in the batch are much more likely to succeed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ErrorHandling.html#BatchOperations">Batch Operations and Error Handling</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p> </important> <p>By default, <code>BatchGetItem</code> performs eventually consistent reads on every table in the request. If you want strongly consistent reads instead, you can set <code>ConsistentRead</code> to <code>true</code> for any or all tables.</p> <p>In order to minimize response latency, <code>BatchGetItem</code> retrieves items in parallel.</p> <p>When designing your application, keep in mind that DynamoDB does not return items in any particular order. To help parse the response by item, include the primary key values for the items in your request in the <code>ProjectionExpression</code> parameter.</p> <p>If a requested item does not exist, it is not returned in the result. Requests for nonexistent items consume the minimum read capacity units according to the type of read. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/WorkingWithTables.html#CapacityUnitCalculations">Working with Tables</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
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
    route: "/#X-Amz-Target=DynamoDB_20120810.BatchGetItem",
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
      "DynamoDB_20120810.BatchWriteItem"))
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
  ## <p>The <code>BatchWriteItem</code> operation puts or deletes multiple items in one or more tables. A single call to <code>BatchWriteItem</code> can write up to 16 MB of data, which can comprise as many as 25 put or delete requests. Individual items to be written can be as large as 400 KB.</p> <note> <p> <code>BatchWriteItem</code> cannot update items. To update items, use the <code>UpdateItem</code> action.</p> </note> <p>The individual <code>PutItem</code> and <code>DeleteItem</code> operations specified in <code>BatchWriteItem</code> are atomic; however <code>BatchWriteItem</code> as a whole is not. If any requested operations fail because the table's provisioned throughput is exceeded or an internal processing failure occurs, the failed operations are returned in the <code>UnprocessedItems</code> response parameter. You can investigate and optionally resend the requests. Typically, you would call <code>BatchWriteItem</code> in a loop. Each iteration would check for unprocessed items and submit a new <code>BatchWriteItem</code> request with those unprocessed items until all items have been processed.</p> <p>If <i>none</i> of the items can be processed due to insufficient provisioned throughput on all of the tables in the request, then <code>BatchWriteItem</code> returns a <code>ProvisionedThroughputExceededException</code>.</p> <important> <p>If DynamoDB returns any unprocessed items, you should retry the batch operation on those items. However, <i>we strongly recommend that you use an exponential backoff algorithm</i>. If you retry the batch operation immediately, the underlying read or write requests can still fail due to throttling on the individual tables. If you delay the batch operation using exponential backoff, the individual requests in the batch are much more likely to succeed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ErrorHandling.html#Programming.Errors.BatchOperations">Batch Operations and Error Handling</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p> </important> <p>With <code>BatchWriteItem</code>, you can efficiently write or delete large amounts of data, such as from Amazon EMR, or copy data from another database into DynamoDB. In order to improve performance with these large-scale operations, <code>BatchWriteItem</code> does not behave in the same way as individual <code>PutItem</code> and <code>DeleteItem</code> calls would. For example, you cannot specify conditions on individual put and delete requests, and <code>BatchWriteItem</code> does not return deleted items in the response.</p> <p>If you use a programming language that supports concurrency, you can use threads to write items in parallel. Your application must include the necessary logic to manage the threads. With languages that don't support threading, you must update or delete the specified items one at a time. In both situations, <code>BatchWriteItem</code> performs the specified put and delete operations in parallel, giving you the power of the thread pool approach without having to introduce complexity into your application.</p> <p>Parallel processing reduces latency, but each specified put and delete request consumes the same number of write capacity units whether it is processed in parallel or not. Delete operations on nonexistent items consume one write capacity unit.</p> <p>If one or more of the following is true, DynamoDB rejects the entire batch write operation:</p> <ul> <li> <p>One or more tables specified in the <code>BatchWriteItem</code> request does not exist.</p> </li> <li> <p>Primary key attributes specified on an item in the request do not match those in the corresponding table's primary key schema.</p> </li> <li> <p>You try to perform multiple operations on the same item in the same <code>BatchWriteItem</code> request. For example, you cannot put and delete the same item in the same <code>BatchWriteItem</code> request. </p> </li> <li> <p> Your request contains at least two items with identical hash and range keys (which essentially is two put operations). </p> </li> <li> <p>There are more than 25 requests in the batch.</p> </li> <li> <p>Any individual item in a batch exceeds 400 KB.</p> </li> <li> <p>The total request size exceeds 16 MB.</p> </li> </ul>
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
  ## <p>The <code>BatchWriteItem</code> operation puts or deletes multiple items in one or more tables. A single call to <code>BatchWriteItem</code> can write up to 16 MB of data, which can comprise as many as 25 put or delete requests. Individual items to be written can be as large as 400 KB.</p> <note> <p> <code>BatchWriteItem</code> cannot update items. To update items, use the <code>UpdateItem</code> action.</p> </note> <p>The individual <code>PutItem</code> and <code>DeleteItem</code> operations specified in <code>BatchWriteItem</code> are atomic; however <code>BatchWriteItem</code> as a whole is not. If any requested operations fail because the table's provisioned throughput is exceeded or an internal processing failure occurs, the failed operations are returned in the <code>UnprocessedItems</code> response parameter. You can investigate and optionally resend the requests. Typically, you would call <code>BatchWriteItem</code> in a loop. Each iteration would check for unprocessed items and submit a new <code>BatchWriteItem</code> request with those unprocessed items until all items have been processed.</p> <p>If <i>none</i> of the items can be processed due to insufficient provisioned throughput on all of the tables in the request, then <code>BatchWriteItem</code> returns a <code>ProvisionedThroughputExceededException</code>.</p> <important> <p>If DynamoDB returns any unprocessed items, you should retry the batch operation on those items. However, <i>we strongly recommend that you use an exponential backoff algorithm</i>. If you retry the batch operation immediately, the underlying read or write requests can still fail due to throttling on the individual tables. If you delay the batch operation using exponential backoff, the individual requests in the batch are much more likely to succeed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ErrorHandling.html#Programming.Errors.BatchOperations">Batch Operations and Error Handling</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p> </important> <p>With <code>BatchWriteItem</code>, you can efficiently write or delete large amounts of data, such as from Amazon EMR, or copy data from another database into DynamoDB. In order to improve performance with these large-scale operations, <code>BatchWriteItem</code> does not behave in the same way as individual <code>PutItem</code> and <code>DeleteItem</code> calls would. For example, you cannot specify conditions on individual put and delete requests, and <code>BatchWriteItem</code> does not return deleted items in the response.</p> <p>If you use a programming language that supports concurrency, you can use threads to write items in parallel. Your application must include the necessary logic to manage the threads. With languages that don't support threading, you must update or delete the specified items one at a time. In both situations, <code>BatchWriteItem</code> performs the specified put and delete operations in parallel, giving you the power of the thread pool approach without having to introduce complexity into your application.</p> <p>Parallel processing reduces latency, but each specified put and delete request consumes the same number of write capacity units whether it is processed in parallel or not. Delete operations on nonexistent items consume one write capacity unit.</p> <p>If one or more of the following is true, DynamoDB rejects the entire batch write operation:</p> <ul> <li> <p>One or more tables specified in the <code>BatchWriteItem</code> request does not exist.</p> </li> <li> <p>Primary key attributes specified on an item in the request do not match those in the corresponding table's primary key schema.</p> </li> <li> <p>You try to perform multiple operations on the same item in the same <code>BatchWriteItem</code> request. For example, you cannot put and delete the same item in the same <code>BatchWriteItem</code> request. </p> </li> <li> <p> Your request contains at least two items with identical hash and range keys (which essentially is two put operations). </p> </li> <li> <p>There are more than 25 requests in the batch.</p> </li> <li> <p>Any individual item in a batch exceeds 400 KB.</p> </li> <li> <p>The total request size exceeds 16 MB.</p> </li> </ul>
  ##   body: JObject (required)
  var body_592989 = newJObject()
  if body != nil:
    body_592989 = body
  result = call_592988.call(nil, nil, nil, nil, body_592989)

var batchWriteItem* = Call_BatchWriteItem_592975(name: "batchWriteItem",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.BatchWriteItem",
    validator: validate_BatchWriteItem_592976, base: "/", url: url_BatchWriteItem_592977,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackup_592990 = ref object of OpenApiRestCall_592364
proc url_CreateBackup_592992(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateBackup_592991(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
      "DynamoDB_20120810.CreateBackup"))
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

proc call*(call_593002: Call_CreateBackup_592990; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a backup for an existing table.</p> <p> Each time you create an on-demand backup, the entire table data is backed up. There is no limit to the number of on-demand backups that can be taken. </p> <p> When you create an on-demand backup, a time marker of the request is cataloged, and the backup is created asynchronously, by applying all changes until the time of the request to the last full table snapshot. Backup requests are processed instantaneously and become available for restore within minutes. </p> <p>You can call <code>CreateBackup</code> at a maximum rate of 50 times per second.</p> <p>All backups in DynamoDB work without consuming any provisioned throughput on the table.</p> <p> If you submit a backup request on 2018-12-14 at 14:25:00, the backup is guaranteed to contain all data committed to the table up to 14:24:00, and data committed after 14:26:00 will not be. The backup might contain data modifications made between 14:24:00 and 14:26:00. On-demand backup does not support causal consistency. </p> <p> Along with data, the following are also included on the backups: </p> <ul> <li> <p>Global secondary indexes (GSIs)</p> </li> <li> <p>Local secondary indexes (LSIs)</p> </li> <li> <p>Streams</p> </li> <li> <p>Provisioned read and write capacity</p> </li> </ul>
  ## 
  let valid = call_593002.validator(path, query, header, formData, body)
  let scheme = call_593002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593002.url(scheme.get, call_593002.host, call_593002.base,
                         call_593002.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593002, url, valid)

proc call*(call_593003: Call_CreateBackup_592990; body: JsonNode): Recallable =
  ## createBackup
  ## <p>Creates a backup for an existing table.</p> <p> Each time you create an on-demand backup, the entire table data is backed up. There is no limit to the number of on-demand backups that can be taken. </p> <p> When you create an on-demand backup, a time marker of the request is cataloged, and the backup is created asynchronously, by applying all changes until the time of the request to the last full table snapshot. Backup requests are processed instantaneously and become available for restore within minutes. </p> <p>You can call <code>CreateBackup</code> at a maximum rate of 50 times per second.</p> <p>All backups in DynamoDB work without consuming any provisioned throughput on the table.</p> <p> If you submit a backup request on 2018-12-14 at 14:25:00, the backup is guaranteed to contain all data committed to the table up to 14:24:00, and data committed after 14:26:00 will not be. The backup might contain data modifications made between 14:24:00 and 14:26:00. On-demand backup does not support causal consistency. </p> <p> Along with data, the following are also included on the backups: </p> <ul> <li> <p>Global secondary indexes (GSIs)</p> </li> <li> <p>Local secondary indexes (LSIs)</p> </li> <li> <p>Streams</p> </li> <li> <p>Provisioned read and write capacity</p> </li> </ul>
  ##   body: JObject (required)
  var body_593004 = newJObject()
  if body != nil:
    body_593004 = body
  result = call_593003.call(nil, nil, nil, nil, body_593004)

var createBackup* = Call_CreateBackup_592990(name: "createBackup",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.CreateBackup",
    validator: validate_CreateBackup_592991, base: "/", url: url_CreateBackup_592992,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGlobalTable_593005 = ref object of OpenApiRestCall_592364
proc url_CreateGlobalTable_593007(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateGlobalTable_593006(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates a global table from an existing table. A global table creates a replication relationship between two or more DynamoDB tables with the same table name in the provided Regions. </p> <p>If you want to add a new replica table to a global table, each of the following conditions must be true:</p> <ul> <li> <p>The table must have the same primary key as all of the other replicas.</p> </li> <li> <p>The table must have the same name as all of the other replicas.</p> </li> <li> <p>The table must have DynamoDB Streams enabled, with the stream containing both the new and the old images of the item.</p> </li> <li> <p>None of the replica tables in the global table can contain any data.</p> </li> </ul> <p> If global secondary indexes are specified, then the following conditions must also be met: </p> <ul> <li> <p> The global secondary indexes must have the same name. </p> </li> <li> <p> The global secondary indexes must have the same hash key and sort key (if present). </p> </li> </ul> <important> <p> Write capacity settings should be set consistently across your replica tables and secondary indexes. DynamoDB strongly recommends enabling auto scaling to manage the write capacity settings for all of your global tables replicas and indexes. </p> <p> If you prefer to manage write capacity settings manually, you should provision equal replicated write capacity units to your replica tables. You should also provision equal replicated write capacity units to matching secondary indexes across your global table. </p> </important>
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
      "DynamoDB_20120810.CreateGlobalTable"))
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

proc call*(call_593017: Call_CreateGlobalTable_593005; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a global table from an existing table. A global table creates a replication relationship between two or more DynamoDB tables with the same table name in the provided Regions. </p> <p>If you want to add a new replica table to a global table, each of the following conditions must be true:</p> <ul> <li> <p>The table must have the same primary key as all of the other replicas.</p> </li> <li> <p>The table must have the same name as all of the other replicas.</p> </li> <li> <p>The table must have DynamoDB Streams enabled, with the stream containing both the new and the old images of the item.</p> </li> <li> <p>None of the replica tables in the global table can contain any data.</p> </li> </ul> <p> If global secondary indexes are specified, then the following conditions must also be met: </p> <ul> <li> <p> The global secondary indexes must have the same name. </p> </li> <li> <p> The global secondary indexes must have the same hash key and sort key (if present). </p> </li> </ul> <important> <p> Write capacity settings should be set consistently across your replica tables and secondary indexes. DynamoDB strongly recommends enabling auto scaling to manage the write capacity settings for all of your global tables replicas and indexes. </p> <p> If you prefer to manage write capacity settings manually, you should provision equal replicated write capacity units to your replica tables. You should also provision equal replicated write capacity units to matching secondary indexes across your global table. </p> </important>
  ## 
  let valid = call_593017.validator(path, query, header, formData, body)
  let scheme = call_593017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593017.url(scheme.get, call_593017.host, call_593017.base,
                         call_593017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593017, url, valid)

proc call*(call_593018: Call_CreateGlobalTable_593005; body: JsonNode): Recallable =
  ## createGlobalTable
  ## <p>Creates a global table from an existing table. A global table creates a replication relationship between two or more DynamoDB tables with the same table name in the provided Regions. </p> <p>If you want to add a new replica table to a global table, each of the following conditions must be true:</p> <ul> <li> <p>The table must have the same primary key as all of the other replicas.</p> </li> <li> <p>The table must have the same name as all of the other replicas.</p> </li> <li> <p>The table must have DynamoDB Streams enabled, with the stream containing both the new and the old images of the item.</p> </li> <li> <p>None of the replica tables in the global table can contain any data.</p> </li> </ul> <p> If global secondary indexes are specified, then the following conditions must also be met: </p> <ul> <li> <p> The global secondary indexes must have the same name. </p> </li> <li> <p> The global secondary indexes must have the same hash key and sort key (if present). </p> </li> </ul> <important> <p> Write capacity settings should be set consistently across your replica tables and secondary indexes. DynamoDB strongly recommends enabling auto scaling to manage the write capacity settings for all of your global tables replicas and indexes. </p> <p> If you prefer to manage write capacity settings manually, you should provision equal replicated write capacity units to your replica tables. You should also provision equal replicated write capacity units to matching secondary indexes across your global table. </p> </important>
  ##   body: JObject (required)
  var body_593019 = newJObject()
  if body != nil:
    body_593019 = body
  result = call_593018.call(nil, nil, nil, nil, body_593019)

var createGlobalTable* = Call_CreateGlobalTable_593005(name: "createGlobalTable",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.CreateGlobalTable",
    validator: validate_CreateGlobalTable_593006, base: "/",
    url: url_CreateGlobalTable_593007, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTable_593020 = ref object of OpenApiRestCall_592364
proc url_CreateTable_593022(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTable_593021(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
      "DynamoDB_20120810.CreateTable"))
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

proc call*(call_593032: Call_CreateTable_593020; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>CreateTable</code> operation adds a new table to your account. In an AWS account, table names must be unique within each Region. That is, you can have two tables with same name if you create the tables in different Regions.</p> <p> <code>CreateTable</code> is an asynchronous operation. Upon receiving a <code>CreateTable</code> request, DynamoDB immediately returns a response with a <code>TableStatus</code> of <code>CREATING</code>. After the table is created, DynamoDB sets the <code>TableStatus</code> to <code>ACTIVE</code>. You can perform read and write operations only on an <code>ACTIVE</code> table. </p> <p>You can optionally define secondary indexes on the new table, as part of the <code>CreateTable</code> operation. If you want to create multiple tables with secondary indexes on them, you must create the tables sequentially. Only one table with secondary indexes can be in the <code>CREATING</code> state at any given time.</p> <p>You can use the <code>DescribeTable</code> action to check the table status.</p>
  ## 
  let valid = call_593032.validator(path, query, header, formData, body)
  let scheme = call_593032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593032.url(scheme.get, call_593032.host, call_593032.base,
                         call_593032.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593032, url, valid)

proc call*(call_593033: Call_CreateTable_593020; body: JsonNode): Recallable =
  ## createTable
  ## <p>The <code>CreateTable</code> operation adds a new table to your account. In an AWS account, table names must be unique within each Region. That is, you can have two tables with same name if you create the tables in different Regions.</p> <p> <code>CreateTable</code> is an asynchronous operation. Upon receiving a <code>CreateTable</code> request, DynamoDB immediately returns a response with a <code>TableStatus</code> of <code>CREATING</code>. After the table is created, DynamoDB sets the <code>TableStatus</code> to <code>ACTIVE</code>. You can perform read and write operations only on an <code>ACTIVE</code> table. </p> <p>You can optionally define secondary indexes on the new table, as part of the <code>CreateTable</code> operation. If you want to create multiple tables with secondary indexes on them, you must create the tables sequentially. Only one table with secondary indexes can be in the <code>CREATING</code> state at any given time.</p> <p>You can use the <code>DescribeTable</code> action to check the table status.</p>
  ##   body: JObject (required)
  var body_593034 = newJObject()
  if body != nil:
    body_593034 = body
  result = call_593033.call(nil, nil, nil, nil, body_593034)

var createTable* = Call_CreateTable_593020(name: "createTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20120810.CreateTable",
                                        validator: validate_CreateTable_593021,
                                        base: "/", url: url_CreateTable_593022,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackup_593035 = ref object of OpenApiRestCall_592364
proc url_DeleteBackup_593037(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteBackup_593036(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
      "DynamoDB_20120810.DeleteBackup"))
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

proc call*(call_593047: Call_DeleteBackup_593035; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing backup of a table.</p> <p>You can call <code>DeleteBackup</code> at a maximum rate of 10 times per second.</p>
  ## 
  let valid = call_593047.validator(path, query, header, formData, body)
  let scheme = call_593047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593047.url(scheme.get, call_593047.host, call_593047.base,
                         call_593047.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593047, url, valid)

proc call*(call_593048: Call_DeleteBackup_593035; body: JsonNode): Recallable =
  ## deleteBackup
  ## <p>Deletes an existing backup of a table.</p> <p>You can call <code>DeleteBackup</code> at a maximum rate of 10 times per second.</p>
  ##   body: JObject (required)
  var body_593049 = newJObject()
  if body != nil:
    body_593049 = body
  result = call_593048.call(nil, nil, nil, nil, body_593049)

var deleteBackup* = Call_DeleteBackup_593035(name: "deleteBackup",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DeleteBackup",
    validator: validate_DeleteBackup_593036, base: "/", url: url_DeleteBackup_593037,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteItem_593050 = ref object of OpenApiRestCall_592364
proc url_DeleteItem_593052(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteItem_593051(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
      "DynamoDB_20120810.DeleteItem"))
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

proc call*(call_593062: Call_DeleteItem_593050; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a single item in a table by primary key. You can perform a conditional delete operation that deletes the item if it exists, or if it has an expected attribute value.</p> <p>In addition to deleting an item, you can also return the item's attribute values in the same operation, using the <code>ReturnValues</code> parameter.</p> <p>Unless you specify conditions, the <code>DeleteItem</code> is an idempotent operation; running it multiple times on the same item or attribute does <i>not</i> result in an error response.</p> <p>Conditional deletes are useful for deleting items only if specific conditions are met. If those conditions are met, DynamoDB performs the delete. Otherwise, the item is not deleted.</p>
  ## 
  let valid = call_593062.validator(path, query, header, formData, body)
  let scheme = call_593062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593062.url(scheme.get, call_593062.host, call_593062.base,
                         call_593062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593062, url, valid)

proc call*(call_593063: Call_DeleteItem_593050; body: JsonNode): Recallable =
  ## deleteItem
  ## <p>Deletes a single item in a table by primary key. You can perform a conditional delete operation that deletes the item if it exists, or if it has an expected attribute value.</p> <p>In addition to deleting an item, you can also return the item's attribute values in the same operation, using the <code>ReturnValues</code> parameter.</p> <p>Unless you specify conditions, the <code>DeleteItem</code> is an idempotent operation; running it multiple times on the same item or attribute does <i>not</i> result in an error response.</p> <p>Conditional deletes are useful for deleting items only if specific conditions are met. If those conditions are met, DynamoDB performs the delete. Otherwise, the item is not deleted.</p>
  ##   body: JObject (required)
  var body_593064 = newJObject()
  if body != nil:
    body_593064 = body
  result = call_593063.call(nil, nil, nil, nil, body_593064)

var deleteItem* = Call_DeleteItem_593050(name: "deleteItem",
                                      meth: HttpMethod.HttpPost,
                                      host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20120810.DeleteItem",
                                      validator: validate_DeleteItem_593051,
                                      base: "/", url: url_DeleteItem_593052,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTable_593065 = ref object of OpenApiRestCall_592364
proc url_DeleteTable_593067(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTable_593066(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_593068 = header.getOrDefault("X-Amz-Target")
  valid_593068 = validateParameter(valid_593068, JString, required = true, default = newJString(
      "DynamoDB_20120810.DeleteTable"))
  if valid_593068 != nil:
    section.add "X-Amz-Target", valid_593068
  var valid_593069 = header.getOrDefault("X-Amz-Signature")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "X-Amz-Signature", valid_593069
  var valid_593070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "X-Amz-Content-Sha256", valid_593070
  var valid_593071 = header.getOrDefault("X-Amz-Date")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-Date", valid_593071
  var valid_593072 = header.getOrDefault("X-Amz-Credential")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-Credential", valid_593072
  var valid_593073 = header.getOrDefault("X-Amz-Security-Token")
  valid_593073 = validateParameter(valid_593073, JString, required = false,
                                 default = nil)
  if valid_593073 != nil:
    section.add "X-Amz-Security-Token", valid_593073
  var valid_593074 = header.getOrDefault("X-Amz-Algorithm")
  valid_593074 = validateParameter(valid_593074, JString, required = false,
                                 default = nil)
  if valid_593074 != nil:
    section.add "X-Amz-Algorithm", valid_593074
  var valid_593075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "X-Amz-SignedHeaders", valid_593075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593077: Call_DeleteTable_593065; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>DeleteTable</code> operation deletes a table and all of its items. After a <code>DeleteTable</code> request, the specified table is in the <code>DELETING</code> state until DynamoDB completes the deletion. If the table is in the <code>ACTIVE</code> state, you can delete it. If a table is in <code>CREATING</code> or <code>UPDATING</code> states, then DynamoDB returns a <code>ResourceInUseException</code>. If the specified table does not exist, DynamoDB returns a <code>ResourceNotFoundException</code>. If table is already in the <code>DELETING</code> state, no error is returned. </p> <note> <p>DynamoDB might continue to accept data read and write operations, such as <code>GetItem</code> and <code>PutItem</code>, on a table in the <code>DELETING</code> state until the table deletion is complete.</p> </note> <p>When you delete a table, any indexes on that table are also deleted.</p> <p>If you have DynamoDB Streams enabled on the table, then the corresponding stream on that table goes into the <code>DISABLED</code> state, and the stream is automatically deleted after 24 hours.</p> <p>Use the <code>DescribeTable</code> action to check the status of the table. </p>
  ## 
  let valid = call_593077.validator(path, query, header, formData, body)
  let scheme = call_593077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593077.url(scheme.get, call_593077.host, call_593077.base,
                         call_593077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593077, url, valid)

proc call*(call_593078: Call_DeleteTable_593065; body: JsonNode): Recallable =
  ## deleteTable
  ## <p>The <code>DeleteTable</code> operation deletes a table and all of its items. After a <code>DeleteTable</code> request, the specified table is in the <code>DELETING</code> state until DynamoDB completes the deletion. If the table is in the <code>ACTIVE</code> state, you can delete it. If a table is in <code>CREATING</code> or <code>UPDATING</code> states, then DynamoDB returns a <code>ResourceInUseException</code>. If the specified table does not exist, DynamoDB returns a <code>ResourceNotFoundException</code>. If table is already in the <code>DELETING</code> state, no error is returned. </p> <note> <p>DynamoDB might continue to accept data read and write operations, such as <code>GetItem</code> and <code>PutItem</code>, on a table in the <code>DELETING</code> state until the table deletion is complete.</p> </note> <p>When you delete a table, any indexes on that table are also deleted.</p> <p>If you have DynamoDB Streams enabled on the table, then the corresponding stream on that table goes into the <code>DISABLED</code> state, and the stream is automatically deleted after 24 hours.</p> <p>Use the <code>DescribeTable</code> action to check the status of the table. </p>
  ##   body: JObject (required)
  var body_593079 = newJObject()
  if body != nil:
    body_593079 = body
  result = call_593078.call(nil, nil, nil, nil, body_593079)

var deleteTable* = Call_DeleteTable_593065(name: "deleteTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20120810.DeleteTable",
                                        validator: validate_DeleteTable_593066,
                                        base: "/", url: url_DeleteTable_593067,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBackup_593080 = ref object of OpenApiRestCall_592364
proc url_DescribeBackup_593082(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeBackup_593081(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_593083 = header.getOrDefault("X-Amz-Target")
  valid_593083 = validateParameter(valid_593083, JString, required = true, default = newJString(
      "DynamoDB_20120810.DescribeBackup"))
  if valid_593083 != nil:
    section.add "X-Amz-Target", valid_593083
  var valid_593084 = header.getOrDefault("X-Amz-Signature")
  valid_593084 = validateParameter(valid_593084, JString, required = false,
                                 default = nil)
  if valid_593084 != nil:
    section.add "X-Amz-Signature", valid_593084
  var valid_593085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "X-Amz-Content-Sha256", valid_593085
  var valid_593086 = header.getOrDefault("X-Amz-Date")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "X-Amz-Date", valid_593086
  var valid_593087 = header.getOrDefault("X-Amz-Credential")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "X-Amz-Credential", valid_593087
  var valid_593088 = header.getOrDefault("X-Amz-Security-Token")
  valid_593088 = validateParameter(valid_593088, JString, required = false,
                                 default = nil)
  if valid_593088 != nil:
    section.add "X-Amz-Security-Token", valid_593088
  var valid_593089 = header.getOrDefault("X-Amz-Algorithm")
  valid_593089 = validateParameter(valid_593089, JString, required = false,
                                 default = nil)
  if valid_593089 != nil:
    section.add "X-Amz-Algorithm", valid_593089
  var valid_593090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "X-Amz-SignedHeaders", valid_593090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593092: Call_DescribeBackup_593080; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes an existing backup of a table.</p> <p>You can call <code>DescribeBackup</code> at a maximum rate of 10 times per second.</p>
  ## 
  let valid = call_593092.validator(path, query, header, formData, body)
  let scheme = call_593092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593092.url(scheme.get, call_593092.host, call_593092.base,
                         call_593092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593092, url, valid)

proc call*(call_593093: Call_DescribeBackup_593080; body: JsonNode): Recallable =
  ## describeBackup
  ## <p>Describes an existing backup of a table.</p> <p>You can call <code>DescribeBackup</code> at a maximum rate of 10 times per second.</p>
  ##   body: JObject (required)
  var body_593094 = newJObject()
  if body != nil:
    body_593094 = body
  result = call_593093.call(nil, nil, nil, nil, body_593094)

var describeBackup* = Call_DescribeBackup_593080(name: "describeBackup",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DescribeBackup",
    validator: validate_DescribeBackup_593081, base: "/", url: url_DescribeBackup_593082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeContinuousBackups_593095 = ref object of OpenApiRestCall_592364
proc url_DescribeContinuousBackups_593097(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeContinuousBackups_593096(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_593098 = header.getOrDefault("X-Amz-Target")
  valid_593098 = validateParameter(valid_593098, JString, required = true, default = newJString(
      "DynamoDB_20120810.DescribeContinuousBackups"))
  if valid_593098 != nil:
    section.add "X-Amz-Target", valid_593098
  var valid_593099 = header.getOrDefault("X-Amz-Signature")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "X-Amz-Signature", valid_593099
  var valid_593100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-Content-Sha256", valid_593100
  var valid_593101 = header.getOrDefault("X-Amz-Date")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-Date", valid_593101
  var valid_593102 = header.getOrDefault("X-Amz-Credential")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "X-Amz-Credential", valid_593102
  var valid_593103 = header.getOrDefault("X-Amz-Security-Token")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "X-Amz-Security-Token", valid_593103
  var valid_593104 = header.getOrDefault("X-Amz-Algorithm")
  valid_593104 = validateParameter(valid_593104, JString, required = false,
                                 default = nil)
  if valid_593104 != nil:
    section.add "X-Amz-Algorithm", valid_593104
  var valid_593105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "X-Amz-SignedHeaders", valid_593105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593107: Call_DescribeContinuousBackups_593095; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Checks the status of continuous backups and point in time recovery on the specified table. Continuous backups are <code>ENABLED</code> on all tables at table creation. If point in time recovery is enabled, <code>PointInTimeRecoveryStatus</code> will be set to ENABLED.</p> <p> After continuous backups and point in time recovery are enabled, you can restore to any point in time within <code>EarliestRestorableDateTime</code> and <code>LatestRestorableDateTime</code>. </p> <p> <code>LatestRestorableDateTime</code> is typically 5 minutes before the current time. You can restore your table to any point in time during the last 35 days. </p> <p>You can call <code>DescribeContinuousBackups</code> at a maximum rate of 10 times per second.</p>
  ## 
  let valid = call_593107.validator(path, query, header, formData, body)
  let scheme = call_593107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593107.url(scheme.get, call_593107.host, call_593107.base,
                         call_593107.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593107, url, valid)

proc call*(call_593108: Call_DescribeContinuousBackups_593095; body: JsonNode): Recallable =
  ## describeContinuousBackups
  ## <p>Checks the status of continuous backups and point in time recovery on the specified table. Continuous backups are <code>ENABLED</code> on all tables at table creation. If point in time recovery is enabled, <code>PointInTimeRecoveryStatus</code> will be set to ENABLED.</p> <p> After continuous backups and point in time recovery are enabled, you can restore to any point in time within <code>EarliestRestorableDateTime</code> and <code>LatestRestorableDateTime</code>. </p> <p> <code>LatestRestorableDateTime</code> is typically 5 minutes before the current time. You can restore your table to any point in time during the last 35 days. </p> <p>You can call <code>DescribeContinuousBackups</code> at a maximum rate of 10 times per second.</p>
  ##   body: JObject (required)
  var body_593109 = newJObject()
  if body != nil:
    body_593109 = body
  result = call_593108.call(nil, nil, nil, nil, body_593109)

var describeContinuousBackups* = Call_DescribeContinuousBackups_593095(
    name: "describeContinuousBackups", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DescribeContinuousBackups",
    validator: validate_DescribeContinuousBackups_593096, base: "/",
    url: url_DescribeContinuousBackups_593097,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoints_593110 = ref object of OpenApiRestCall_592364
proc url_DescribeEndpoints_593112(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEndpoints_593111(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_593113 = header.getOrDefault("X-Amz-Target")
  valid_593113 = validateParameter(valid_593113, JString, required = true, default = newJString(
      "DynamoDB_20120810.DescribeEndpoints"))
  if valid_593113 != nil:
    section.add "X-Amz-Target", valid_593113
  var valid_593114 = header.getOrDefault("X-Amz-Signature")
  valid_593114 = validateParameter(valid_593114, JString, required = false,
                                 default = nil)
  if valid_593114 != nil:
    section.add "X-Amz-Signature", valid_593114
  var valid_593115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "X-Amz-Content-Sha256", valid_593115
  var valid_593116 = header.getOrDefault("X-Amz-Date")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "X-Amz-Date", valid_593116
  var valid_593117 = header.getOrDefault("X-Amz-Credential")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "X-Amz-Credential", valid_593117
  var valid_593118 = header.getOrDefault("X-Amz-Security-Token")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "X-Amz-Security-Token", valid_593118
  var valid_593119 = header.getOrDefault("X-Amz-Algorithm")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "X-Amz-Algorithm", valid_593119
  var valid_593120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "X-Amz-SignedHeaders", valid_593120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593122: Call_DescribeEndpoints_593110; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the regional endpoint information.
  ## 
  let valid = call_593122.validator(path, query, header, formData, body)
  let scheme = call_593122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593122.url(scheme.get, call_593122.host, call_593122.base,
                         call_593122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593122, url, valid)

proc call*(call_593123: Call_DescribeEndpoints_593110; body: JsonNode): Recallable =
  ## describeEndpoints
  ## Returns the regional endpoint information.
  ##   body: JObject (required)
  var body_593124 = newJObject()
  if body != nil:
    body_593124 = body
  result = call_593123.call(nil, nil, nil, nil, body_593124)

var describeEndpoints* = Call_DescribeEndpoints_593110(name: "describeEndpoints",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DescribeEndpoints",
    validator: validate_DescribeEndpoints_593111, base: "/",
    url: url_DescribeEndpoints_593112, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGlobalTable_593125 = ref object of OpenApiRestCall_592364
proc url_DescribeGlobalTable_593127(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeGlobalTable_593126(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns information about the specified global table.
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
  var valid_593128 = header.getOrDefault("X-Amz-Target")
  valid_593128 = validateParameter(valid_593128, JString, required = true, default = newJString(
      "DynamoDB_20120810.DescribeGlobalTable"))
  if valid_593128 != nil:
    section.add "X-Amz-Target", valid_593128
  var valid_593129 = header.getOrDefault("X-Amz-Signature")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-Signature", valid_593129
  var valid_593130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "X-Amz-Content-Sha256", valid_593130
  var valid_593131 = header.getOrDefault("X-Amz-Date")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "X-Amz-Date", valid_593131
  var valid_593132 = header.getOrDefault("X-Amz-Credential")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "X-Amz-Credential", valid_593132
  var valid_593133 = header.getOrDefault("X-Amz-Security-Token")
  valid_593133 = validateParameter(valid_593133, JString, required = false,
                                 default = nil)
  if valid_593133 != nil:
    section.add "X-Amz-Security-Token", valid_593133
  var valid_593134 = header.getOrDefault("X-Amz-Algorithm")
  valid_593134 = validateParameter(valid_593134, JString, required = false,
                                 default = nil)
  if valid_593134 != nil:
    section.add "X-Amz-Algorithm", valid_593134
  var valid_593135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "X-Amz-SignedHeaders", valid_593135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593137: Call_DescribeGlobalTable_593125; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified global table.
  ## 
  let valid = call_593137.validator(path, query, header, formData, body)
  let scheme = call_593137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593137.url(scheme.get, call_593137.host, call_593137.base,
                         call_593137.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593137, url, valid)

proc call*(call_593138: Call_DescribeGlobalTable_593125; body: JsonNode): Recallable =
  ## describeGlobalTable
  ## Returns information about the specified global table.
  ##   body: JObject (required)
  var body_593139 = newJObject()
  if body != nil:
    body_593139 = body
  result = call_593138.call(nil, nil, nil, nil, body_593139)

var describeGlobalTable* = Call_DescribeGlobalTable_593125(
    name: "describeGlobalTable", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DescribeGlobalTable",
    validator: validate_DescribeGlobalTable_593126, base: "/",
    url: url_DescribeGlobalTable_593127, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGlobalTableSettings_593140 = ref object of OpenApiRestCall_592364
proc url_DescribeGlobalTableSettings_593142(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeGlobalTableSettings_593141(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes Region-specific settings for a global table.
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
  var valid_593143 = header.getOrDefault("X-Amz-Target")
  valid_593143 = validateParameter(valid_593143, JString, required = true, default = newJString(
      "DynamoDB_20120810.DescribeGlobalTableSettings"))
  if valid_593143 != nil:
    section.add "X-Amz-Target", valid_593143
  var valid_593144 = header.getOrDefault("X-Amz-Signature")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-Signature", valid_593144
  var valid_593145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593145 = validateParameter(valid_593145, JString, required = false,
                                 default = nil)
  if valid_593145 != nil:
    section.add "X-Amz-Content-Sha256", valid_593145
  var valid_593146 = header.getOrDefault("X-Amz-Date")
  valid_593146 = validateParameter(valid_593146, JString, required = false,
                                 default = nil)
  if valid_593146 != nil:
    section.add "X-Amz-Date", valid_593146
  var valid_593147 = header.getOrDefault("X-Amz-Credential")
  valid_593147 = validateParameter(valid_593147, JString, required = false,
                                 default = nil)
  if valid_593147 != nil:
    section.add "X-Amz-Credential", valid_593147
  var valid_593148 = header.getOrDefault("X-Amz-Security-Token")
  valid_593148 = validateParameter(valid_593148, JString, required = false,
                                 default = nil)
  if valid_593148 != nil:
    section.add "X-Amz-Security-Token", valid_593148
  var valid_593149 = header.getOrDefault("X-Amz-Algorithm")
  valid_593149 = validateParameter(valid_593149, JString, required = false,
                                 default = nil)
  if valid_593149 != nil:
    section.add "X-Amz-Algorithm", valid_593149
  var valid_593150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593150 = validateParameter(valid_593150, JString, required = false,
                                 default = nil)
  if valid_593150 != nil:
    section.add "X-Amz-SignedHeaders", valid_593150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593152: Call_DescribeGlobalTableSettings_593140; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes Region-specific settings for a global table.
  ## 
  let valid = call_593152.validator(path, query, header, formData, body)
  let scheme = call_593152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593152.url(scheme.get, call_593152.host, call_593152.base,
                         call_593152.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593152, url, valid)

proc call*(call_593153: Call_DescribeGlobalTableSettings_593140; body: JsonNode): Recallable =
  ## describeGlobalTableSettings
  ## Describes Region-specific settings for a global table.
  ##   body: JObject (required)
  var body_593154 = newJObject()
  if body != nil:
    body_593154 = body
  result = call_593153.call(nil, nil, nil, nil, body_593154)

var describeGlobalTableSettings* = Call_DescribeGlobalTableSettings_593140(
    name: "describeGlobalTableSettings", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DescribeGlobalTableSettings",
    validator: validate_DescribeGlobalTableSettings_593141, base: "/",
    url: url_DescribeGlobalTableSettings_593142,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLimits_593155 = ref object of OpenApiRestCall_592364
proc url_DescribeLimits_593157(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeLimits_593156(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_593158 = header.getOrDefault("X-Amz-Target")
  valid_593158 = validateParameter(valid_593158, JString, required = true, default = newJString(
      "DynamoDB_20120810.DescribeLimits"))
  if valid_593158 != nil:
    section.add "X-Amz-Target", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-Signature")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-Signature", valid_593159
  var valid_593160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593160 = validateParameter(valid_593160, JString, required = false,
                                 default = nil)
  if valid_593160 != nil:
    section.add "X-Amz-Content-Sha256", valid_593160
  var valid_593161 = header.getOrDefault("X-Amz-Date")
  valid_593161 = validateParameter(valid_593161, JString, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "X-Amz-Date", valid_593161
  var valid_593162 = header.getOrDefault("X-Amz-Credential")
  valid_593162 = validateParameter(valid_593162, JString, required = false,
                                 default = nil)
  if valid_593162 != nil:
    section.add "X-Amz-Credential", valid_593162
  var valid_593163 = header.getOrDefault("X-Amz-Security-Token")
  valid_593163 = validateParameter(valid_593163, JString, required = false,
                                 default = nil)
  if valid_593163 != nil:
    section.add "X-Amz-Security-Token", valid_593163
  var valid_593164 = header.getOrDefault("X-Amz-Algorithm")
  valid_593164 = validateParameter(valid_593164, JString, required = false,
                                 default = nil)
  if valid_593164 != nil:
    section.add "X-Amz-Algorithm", valid_593164
  var valid_593165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593165 = validateParameter(valid_593165, JString, required = false,
                                 default = nil)
  if valid_593165 != nil:
    section.add "X-Amz-SignedHeaders", valid_593165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593167: Call_DescribeLimits_593155; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the current provisioned-capacity limits for your AWS account in a Region, both for the Region as a whole and for any one DynamoDB table that you create there.</p> <p>When you establish an AWS account, the account has initial limits on the maximum read capacity units and write capacity units that you can provision across all of your DynamoDB tables in a given Region. Also, there are per-table limits that apply when you create a table there. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Limits.html">Limits</a> page in the <i>Amazon DynamoDB Developer Guide</i>.</p> <p>Although you can increase these limits by filing a case at <a href="https://console.aws.amazon.com/support/home#/">AWS Support Center</a>, obtaining the increase is not instantaneous. The <code>DescribeLimits</code> action lets you write code to compare the capacity you are currently using to those limits imposed by your account so that you have enough time to apply for an increase before you hit a limit.</p> <p>For example, you could use one of the AWS SDKs to do the following:</p> <ol> <li> <p>Call <code>DescribeLimits</code> for a particular Region to obtain your current account limits on provisioned capacity there.</p> </li> <li> <p>Create a variable to hold the aggregate read capacity units provisioned for all your tables in that Region, and one to hold the aggregate write capacity units. Zero them both.</p> </li> <li> <p>Call <code>ListTables</code> to obtain a list of all your DynamoDB tables.</p> </li> <li> <p>For each table name listed by <code>ListTables</code>, do the following:</p> <ul> <li> <p>Call <code>DescribeTable</code> with the table name.</p> </li> <li> <p>Use the data returned by <code>DescribeTable</code> to add the read capacity units and write capacity units provisioned for the table itself to your variables.</p> </li> <li> <p>If the table has one or more global secondary indexes (GSIs), loop over these GSIs and add their provisioned capacity values to your variables as well.</p> </li> </ul> </li> <li> <p>Report the account limits for that Region returned by <code>DescribeLimits</code>, along with the total current provisioned capacity levels you have calculated.</p> </li> </ol> <p>This will let you see whether you are getting close to your account-level limits.</p> <p>The per-table limits apply only when you are creating a new table. They restrict the sum of the provisioned capacity of the new table itself and all its global secondary indexes.</p> <p>For existing tables and their GSIs, DynamoDB doesn't let you increase provisioned capacity extremely rapidly. But the only upper limit that applies is that the aggregate provisioned capacity over all your tables and GSIs cannot exceed either of the per-account limits.</p> <note> <p> <code>DescribeLimits</code> should only be called periodically. You can expect throttling errors if you call it more than once in a minute.</p> </note> <p>The <code>DescribeLimits</code> Request element has no content.</p>
  ## 
  let valid = call_593167.validator(path, query, header, formData, body)
  let scheme = call_593167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593167.url(scheme.get, call_593167.host, call_593167.base,
                         call_593167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593167, url, valid)

proc call*(call_593168: Call_DescribeLimits_593155; body: JsonNode): Recallable =
  ## describeLimits
  ## <p>Returns the current provisioned-capacity limits for your AWS account in a Region, both for the Region as a whole and for any one DynamoDB table that you create there.</p> <p>When you establish an AWS account, the account has initial limits on the maximum read capacity units and write capacity units that you can provision across all of your DynamoDB tables in a given Region. Also, there are per-table limits that apply when you create a table there. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Limits.html">Limits</a> page in the <i>Amazon DynamoDB Developer Guide</i>.</p> <p>Although you can increase these limits by filing a case at <a href="https://console.aws.amazon.com/support/home#/">AWS Support Center</a>, obtaining the increase is not instantaneous. The <code>DescribeLimits</code> action lets you write code to compare the capacity you are currently using to those limits imposed by your account so that you have enough time to apply for an increase before you hit a limit.</p> <p>For example, you could use one of the AWS SDKs to do the following:</p> <ol> <li> <p>Call <code>DescribeLimits</code> for a particular Region to obtain your current account limits on provisioned capacity there.</p> </li> <li> <p>Create a variable to hold the aggregate read capacity units provisioned for all your tables in that Region, and one to hold the aggregate write capacity units. Zero them both.</p> </li> <li> <p>Call <code>ListTables</code> to obtain a list of all your DynamoDB tables.</p> </li> <li> <p>For each table name listed by <code>ListTables</code>, do the following:</p> <ul> <li> <p>Call <code>DescribeTable</code> with the table name.</p> </li> <li> <p>Use the data returned by <code>DescribeTable</code> to add the read capacity units and write capacity units provisioned for the table itself to your variables.</p> </li> <li> <p>If the table has one or more global secondary indexes (GSIs), loop over these GSIs and add their provisioned capacity values to your variables as well.</p> </li> </ul> </li> <li> <p>Report the account limits for that Region returned by <code>DescribeLimits</code>, along with the total current provisioned capacity levels you have calculated.</p> </li> </ol> <p>This will let you see whether you are getting close to your account-level limits.</p> <p>The per-table limits apply only when you are creating a new table. They restrict the sum of the provisioned capacity of the new table itself and all its global secondary indexes.</p> <p>For existing tables and their GSIs, DynamoDB doesn't let you increase provisioned capacity extremely rapidly. But the only upper limit that applies is that the aggregate provisioned capacity over all your tables and GSIs cannot exceed either of the per-account limits.</p> <note> <p> <code>DescribeLimits</code> should only be called periodically. You can expect throttling errors if you call it more than once in a minute.</p> </note> <p>The <code>DescribeLimits</code> Request element has no content.</p>
  ##   body: JObject (required)
  var body_593169 = newJObject()
  if body != nil:
    body_593169 = body
  result = call_593168.call(nil, nil, nil, nil, body_593169)

var describeLimits* = Call_DescribeLimits_593155(name: "describeLimits",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DescribeLimits",
    validator: validate_DescribeLimits_593156, base: "/", url: url_DescribeLimits_593157,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTable_593170 = ref object of OpenApiRestCall_592364
proc url_DescribeTable_593172(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTable_593171(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_593173 = header.getOrDefault("X-Amz-Target")
  valid_593173 = validateParameter(valid_593173, JString, required = true, default = newJString(
      "DynamoDB_20120810.DescribeTable"))
  if valid_593173 != nil:
    section.add "X-Amz-Target", valid_593173
  var valid_593174 = header.getOrDefault("X-Amz-Signature")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "X-Amz-Signature", valid_593174
  var valid_593175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "X-Amz-Content-Sha256", valid_593175
  var valid_593176 = header.getOrDefault("X-Amz-Date")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "X-Amz-Date", valid_593176
  var valid_593177 = header.getOrDefault("X-Amz-Credential")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "X-Amz-Credential", valid_593177
  var valid_593178 = header.getOrDefault("X-Amz-Security-Token")
  valid_593178 = validateParameter(valid_593178, JString, required = false,
                                 default = nil)
  if valid_593178 != nil:
    section.add "X-Amz-Security-Token", valid_593178
  var valid_593179 = header.getOrDefault("X-Amz-Algorithm")
  valid_593179 = validateParameter(valid_593179, JString, required = false,
                                 default = nil)
  if valid_593179 != nil:
    section.add "X-Amz-Algorithm", valid_593179
  var valid_593180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593180 = validateParameter(valid_593180, JString, required = false,
                                 default = nil)
  if valid_593180 != nil:
    section.add "X-Amz-SignedHeaders", valid_593180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593182: Call_DescribeTable_593170; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the table, including the current status of the table, when it was created, the primary key schema, and any indexes on the table.</p> <note> <p>If you issue a <code>DescribeTable</code> request immediately after a <code>CreateTable</code> request, DynamoDB might return a <code>ResourceNotFoundException</code>. This is because <code>DescribeTable</code> uses an eventually consistent query, and the metadata for your table might not be available at that moment. Wait for a few seconds, and then try the <code>DescribeTable</code> request again.</p> </note>
  ## 
  let valid = call_593182.validator(path, query, header, formData, body)
  let scheme = call_593182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593182.url(scheme.get, call_593182.host, call_593182.base,
                         call_593182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593182, url, valid)

proc call*(call_593183: Call_DescribeTable_593170; body: JsonNode): Recallable =
  ## describeTable
  ## <p>Returns information about the table, including the current status of the table, when it was created, the primary key schema, and any indexes on the table.</p> <note> <p>If you issue a <code>DescribeTable</code> request immediately after a <code>CreateTable</code> request, DynamoDB might return a <code>ResourceNotFoundException</code>. This is because <code>DescribeTable</code> uses an eventually consistent query, and the metadata for your table might not be available at that moment. Wait for a few seconds, and then try the <code>DescribeTable</code> request again.</p> </note>
  ##   body: JObject (required)
  var body_593184 = newJObject()
  if body != nil:
    body_593184 = body
  result = call_593183.call(nil, nil, nil, nil, body_593184)

var describeTable* = Call_DescribeTable_593170(name: "describeTable",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DescribeTable",
    validator: validate_DescribeTable_593171, base: "/", url: url_DescribeTable_593172,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTimeToLive_593185 = ref object of OpenApiRestCall_592364
proc url_DescribeTimeToLive_593187(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTimeToLive_593186(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_593188 = header.getOrDefault("X-Amz-Target")
  valid_593188 = validateParameter(valid_593188, JString, required = true, default = newJString(
      "DynamoDB_20120810.DescribeTimeToLive"))
  if valid_593188 != nil:
    section.add "X-Amz-Target", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-Signature")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-Signature", valid_593189
  var valid_593190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "X-Amz-Content-Sha256", valid_593190
  var valid_593191 = header.getOrDefault("X-Amz-Date")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "X-Amz-Date", valid_593191
  var valid_593192 = header.getOrDefault("X-Amz-Credential")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-Credential", valid_593192
  var valid_593193 = header.getOrDefault("X-Amz-Security-Token")
  valid_593193 = validateParameter(valid_593193, JString, required = false,
                                 default = nil)
  if valid_593193 != nil:
    section.add "X-Amz-Security-Token", valid_593193
  var valid_593194 = header.getOrDefault("X-Amz-Algorithm")
  valid_593194 = validateParameter(valid_593194, JString, required = false,
                                 default = nil)
  if valid_593194 != nil:
    section.add "X-Amz-Algorithm", valid_593194
  var valid_593195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593195 = validateParameter(valid_593195, JString, required = false,
                                 default = nil)
  if valid_593195 != nil:
    section.add "X-Amz-SignedHeaders", valid_593195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593197: Call_DescribeTimeToLive_593185; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gives a description of the Time to Live (TTL) status on the specified table. 
  ## 
  let valid = call_593197.validator(path, query, header, formData, body)
  let scheme = call_593197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593197.url(scheme.get, call_593197.host, call_593197.base,
                         call_593197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593197, url, valid)

proc call*(call_593198: Call_DescribeTimeToLive_593185; body: JsonNode): Recallable =
  ## describeTimeToLive
  ## Gives a description of the Time to Live (TTL) status on the specified table. 
  ##   body: JObject (required)
  var body_593199 = newJObject()
  if body != nil:
    body_593199 = body
  result = call_593198.call(nil, nil, nil, nil, body_593199)

var describeTimeToLive* = Call_DescribeTimeToLive_593185(
    name: "describeTimeToLive", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DescribeTimeToLive",
    validator: validate_DescribeTimeToLive_593186, base: "/",
    url: url_DescribeTimeToLive_593187, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetItem_593200 = ref object of OpenApiRestCall_592364
proc url_GetItem_593202(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetItem_593201(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_593203 = header.getOrDefault("X-Amz-Target")
  valid_593203 = validateParameter(valid_593203, JString, required = true, default = newJString(
      "DynamoDB_20120810.GetItem"))
  if valid_593203 != nil:
    section.add "X-Amz-Target", valid_593203
  var valid_593204 = header.getOrDefault("X-Amz-Signature")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "X-Amz-Signature", valid_593204
  var valid_593205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-Content-Sha256", valid_593205
  var valid_593206 = header.getOrDefault("X-Amz-Date")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "X-Amz-Date", valid_593206
  var valid_593207 = header.getOrDefault("X-Amz-Credential")
  valid_593207 = validateParameter(valid_593207, JString, required = false,
                                 default = nil)
  if valid_593207 != nil:
    section.add "X-Amz-Credential", valid_593207
  var valid_593208 = header.getOrDefault("X-Amz-Security-Token")
  valid_593208 = validateParameter(valid_593208, JString, required = false,
                                 default = nil)
  if valid_593208 != nil:
    section.add "X-Amz-Security-Token", valid_593208
  var valid_593209 = header.getOrDefault("X-Amz-Algorithm")
  valid_593209 = validateParameter(valid_593209, JString, required = false,
                                 default = nil)
  if valid_593209 != nil:
    section.add "X-Amz-Algorithm", valid_593209
  var valid_593210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593210 = validateParameter(valid_593210, JString, required = false,
                                 default = nil)
  if valid_593210 != nil:
    section.add "X-Amz-SignedHeaders", valid_593210
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593212: Call_GetItem_593200; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>GetItem</code> operation returns a set of attributes for the item with the given primary key. If there is no matching item, <code>GetItem</code> does not return any data and there will be no <code>Item</code> element in the response.</p> <p> <code>GetItem</code> provides an eventually consistent read by default. If your application requires a strongly consistent read, set <code>ConsistentRead</code> to <code>true</code>. Although a strongly consistent read might take more time than an eventually consistent read, it always returns the last updated value.</p>
  ## 
  let valid = call_593212.validator(path, query, header, formData, body)
  let scheme = call_593212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593212.url(scheme.get, call_593212.host, call_593212.base,
                         call_593212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593212, url, valid)

proc call*(call_593213: Call_GetItem_593200; body: JsonNode): Recallable =
  ## getItem
  ## <p>The <code>GetItem</code> operation returns a set of attributes for the item with the given primary key. If there is no matching item, <code>GetItem</code> does not return any data and there will be no <code>Item</code> element in the response.</p> <p> <code>GetItem</code> provides an eventually consistent read by default. If your application requires a strongly consistent read, set <code>ConsistentRead</code> to <code>true</code>. Although a strongly consistent read might take more time than an eventually consistent read, it always returns the last updated value.</p>
  ##   body: JObject (required)
  var body_593214 = newJObject()
  if body != nil:
    body_593214 = body
  result = call_593213.call(nil, nil, nil, nil, body_593214)

var getItem* = Call_GetItem_593200(name: "getItem", meth: HttpMethod.HttpPost,
                                host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20120810.GetItem",
                                validator: validate_GetItem_593201, base: "/",
                                url: url_GetItem_593202,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackups_593215 = ref object of OpenApiRestCall_592364
proc url_ListBackups_593217(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBackups_593216(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_593218 = header.getOrDefault("X-Amz-Target")
  valid_593218 = validateParameter(valid_593218, JString, required = true, default = newJString(
      "DynamoDB_20120810.ListBackups"))
  if valid_593218 != nil:
    section.add "X-Amz-Target", valid_593218
  var valid_593219 = header.getOrDefault("X-Amz-Signature")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "X-Amz-Signature", valid_593219
  var valid_593220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593220 = validateParameter(valid_593220, JString, required = false,
                                 default = nil)
  if valid_593220 != nil:
    section.add "X-Amz-Content-Sha256", valid_593220
  var valid_593221 = header.getOrDefault("X-Amz-Date")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "X-Amz-Date", valid_593221
  var valid_593222 = header.getOrDefault("X-Amz-Credential")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "X-Amz-Credential", valid_593222
  var valid_593223 = header.getOrDefault("X-Amz-Security-Token")
  valid_593223 = validateParameter(valid_593223, JString, required = false,
                                 default = nil)
  if valid_593223 != nil:
    section.add "X-Amz-Security-Token", valid_593223
  var valid_593224 = header.getOrDefault("X-Amz-Algorithm")
  valid_593224 = validateParameter(valid_593224, JString, required = false,
                                 default = nil)
  if valid_593224 != nil:
    section.add "X-Amz-Algorithm", valid_593224
  var valid_593225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593225 = validateParameter(valid_593225, JString, required = false,
                                 default = nil)
  if valid_593225 != nil:
    section.add "X-Amz-SignedHeaders", valid_593225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593227: Call_ListBackups_593215; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List backups associated with an AWS account. To list backups for a given table, specify <code>TableName</code>. <code>ListBackups</code> returns a paginated list of results with at most 1 MB worth of items in a page. You can also specify a limit for the maximum number of entries to be returned in a page. </p> <p>In the request, start time is inclusive, but end time is exclusive. Note that these limits are for the time at which the original backup was requested.</p> <p>You can call <code>ListBackups</code> a maximum of five times per second.</p>
  ## 
  let valid = call_593227.validator(path, query, header, formData, body)
  let scheme = call_593227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593227.url(scheme.get, call_593227.host, call_593227.base,
                         call_593227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593227, url, valid)

proc call*(call_593228: Call_ListBackups_593215; body: JsonNode): Recallable =
  ## listBackups
  ## <p>List backups associated with an AWS account. To list backups for a given table, specify <code>TableName</code>. <code>ListBackups</code> returns a paginated list of results with at most 1 MB worth of items in a page. You can also specify a limit for the maximum number of entries to be returned in a page. </p> <p>In the request, start time is inclusive, but end time is exclusive. Note that these limits are for the time at which the original backup was requested.</p> <p>You can call <code>ListBackups</code> a maximum of five times per second.</p>
  ##   body: JObject (required)
  var body_593229 = newJObject()
  if body != nil:
    body_593229 = body
  result = call_593228.call(nil, nil, nil, nil, body_593229)

var listBackups* = Call_ListBackups_593215(name: "listBackups",
                                        meth: HttpMethod.HttpPost,
                                        host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20120810.ListBackups",
                                        validator: validate_ListBackups_593216,
                                        base: "/", url: url_ListBackups_593217,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGlobalTables_593230 = ref object of OpenApiRestCall_592364
proc url_ListGlobalTables_593232(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListGlobalTables_593231(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Lists all global tables that have a replica in the specified Region.
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
  var valid_593233 = header.getOrDefault("X-Amz-Target")
  valid_593233 = validateParameter(valid_593233, JString, required = true, default = newJString(
      "DynamoDB_20120810.ListGlobalTables"))
  if valid_593233 != nil:
    section.add "X-Amz-Target", valid_593233
  var valid_593234 = header.getOrDefault("X-Amz-Signature")
  valid_593234 = validateParameter(valid_593234, JString, required = false,
                                 default = nil)
  if valid_593234 != nil:
    section.add "X-Amz-Signature", valid_593234
  var valid_593235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593235 = validateParameter(valid_593235, JString, required = false,
                                 default = nil)
  if valid_593235 != nil:
    section.add "X-Amz-Content-Sha256", valid_593235
  var valid_593236 = header.getOrDefault("X-Amz-Date")
  valid_593236 = validateParameter(valid_593236, JString, required = false,
                                 default = nil)
  if valid_593236 != nil:
    section.add "X-Amz-Date", valid_593236
  var valid_593237 = header.getOrDefault("X-Amz-Credential")
  valid_593237 = validateParameter(valid_593237, JString, required = false,
                                 default = nil)
  if valid_593237 != nil:
    section.add "X-Amz-Credential", valid_593237
  var valid_593238 = header.getOrDefault("X-Amz-Security-Token")
  valid_593238 = validateParameter(valid_593238, JString, required = false,
                                 default = nil)
  if valid_593238 != nil:
    section.add "X-Amz-Security-Token", valid_593238
  var valid_593239 = header.getOrDefault("X-Amz-Algorithm")
  valid_593239 = validateParameter(valid_593239, JString, required = false,
                                 default = nil)
  if valid_593239 != nil:
    section.add "X-Amz-Algorithm", valid_593239
  var valid_593240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593240 = validateParameter(valid_593240, JString, required = false,
                                 default = nil)
  if valid_593240 != nil:
    section.add "X-Amz-SignedHeaders", valid_593240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593242: Call_ListGlobalTables_593230; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all global tables that have a replica in the specified Region.
  ## 
  let valid = call_593242.validator(path, query, header, formData, body)
  let scheme = call_593242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593242.url(scheme.get, call_593242.host, call_593242.base,
                         call_593242.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593242, url, valid)

proc call*(call_593243: Call_ListGlobalTables_593230; body: JsonNode): Recallable =
  ## listGlobalTables
  ## Lists all global tables that have a replica in the specified Region.
  ##   body: JObject (required)
  var body_593244 = newJObject()
  if body != nil:
    body_593244 = body
  result = call_593243.call(nil, nil, nil, nil, body_593244)

var listGlobalTables* = Call_ListGlobalTables_593230(name: "listGlobalTables",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.ListGlobalTables",
    validator: validate_ListGlobalTables_593231, base: "/",
    url: url_ListGlobalTables_593232, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTables_593245 = ref object of OpenApiRestCall_592364
proc url_ListTables_593247(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTables_593246(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of table names associated with the current account and endpoint. The output from <code>ListTables</code> is paginated, with each page returning a maximum of 100 table names.
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
  var valid_593248 = query.getOrDefault("Limit")
  valid_593248 = validateParameter(valid_593248, JString, required = false,
                                 default = nil)
  if valid_593248 != nil:
    section.add "Limit", valid_593248
  var valid_593249 = query.getOrDefault("ExclusiveStartTableName")
  valid_593249 = validateParameter(valid_593249, JString, required = false,
                                 default = nil)
  if valid_593249 != nil:
    section.add "ExclusiveStartTableName", valid_593249
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
  var valid_593250 = header.getOrDefault("X-Amz-Target")
  valid_593250 = validateParameter(valid_593250, JString, required = true, default = newJString(
      "DynamoDB_20120810.ListTables"))
  if valid_593250 != nil:
    section.add "X-Amz-Target", valid_593250
  var valid_593251 = header.getOrDefault("X-Amz-Signature")
  valid_593251 = validateParameter(valid_593251, JString, required = false,
                                 default = nil)
  if valid_593251 != nil:
    section.add "X-Amz-Signature", valid_593251
  var valid_593252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593252 = validateParameter(valid_593252, JString, required = false,
                                 default = nil)
  if valid_593252 != nil:
    section.add "X-Amz-Content-Sha256", valid_593252
  var valid_593253 = header.getOrDefault("X-Amz-Date")
  valid_593253 = validateParameter(valid_593253, JString, required = false,
                                 default = nil)
  if valid_593253 != nil:
    section.add "X-Amz-Date", valid_593253
  var valid_593254 = header.getOrDefault("X-Amz-Credential")
  valid_593254 = validateParameter(valid_593254, JString, required = false,
                                 default = nil)
  if valid_593254 != nil:
    section.add "X-Amz-Credential", valid_593254
  var valid_593255 = header.getOrDefault("X-Amz-Security-Token")
  valid_593255 = validateParameter(valid_593255, JString, required = false,
                                 default = nil)
  if valid_593255 != nil:
    section.add "X-Amz-Security-Token", valid_593255
  var valid_593256 = header.getOrDefault("X-Amz-Algorithm")
  valid_593256 = validateParameter(valid_593256, JString, required = false,
                                 default = nil)
  if valid_593256 != nil:
    section.add "X-Amz-Algorithm", valid_593256
  var valid_593257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593257 = validateParameter(valid_593257, JString, required = false,
                                 default = nil)
  if valid_593257 != nil:
    section.add "X-Amz-SignedHeaders", valid_593257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593259: Call_ListTables_593245; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of table names associated with the current account and endpoint. The output from <code>ListTables</code> is paginated, with each page returning a maximum of 100 table names.
  ## 
  let valid = call_593259.validator(path, query, header, formData, body)
  let scheme = call_593259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593259.url(scheme.get, call_593259.host, call_593259.base,
                         call_593259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593259, url, valid)

proc call*(call_593260: Call_ListTables_593245; body: JsonNode; Limit: string = "";
          ExclusiveStartTableName: string = ""): Recallable =
  ## listTables
  ## Returns an array of table names associated with the current account and endpoint. The output from <code>ListTables</code> is paginated, with each page returning a maximum of 100 table names.
  ##   Limit: string
  ##        : Pagination limit
  ##   ExclusiveStartTableName: string
  ##                          : Pagination token
  ##   body: JObject (required)
  var query_593261 = newJObject()
  var body_593262 = newJObject()
  add(query_593261, "Limit", newJString(Limit))
  add(query_593261, "ExclusiveStartTableName", newJString(ExclusiveStartTableName))
  if body != nil:
    body_593262 = body
  result = call_593260.call(nil, query_593261, nil, nil, body_593262)

var listTables* = Call_ListTables_593245(name: "listTables",
                                      meth: HttpMethod.HttpPost,
                                      host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20120810.ListTables",
                                      validator: validate_ListTables_593246,
                                      base: "/", url: url_ListTables_593247,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsOfResource_593263 = ref object of OpenApiRestCall_592364
proc url_ListTagsOfResource_593265(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsOfResource_593264(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_593266 = header.getOrDefault("X-Amz-Target")
  valid_593266 = validateParameter(valid_593266, JString, required = true, default = newJString(
      "DynamoDB_20120810.ListTagsOfResource"))
  if valid_593266 != nil:
    section.add "X-Amz-Target", valid_593266
  var valid_593267 = header.getOrDefault("X-Amz-Signature")
  valid_593267 = validateParameter(valid_593267, JString, required = false,
                                 default = nil)
  if valid_593267 != nil:
    section.add "X-Amz-Signature", valid_593267
  var valid_593268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593268 = validateParameter(valid_593268, JString, required = false,
                                 default = nil)
  if valid_593268 != nil:
    section.add "X-Amz-Content-Sha256", valid_593268
  var valid_593269 = header.getOrDefault("X-Amz-Date")
  valid_593269 = validateParameter(valid_593269, JString, required = false,
                                 default = nil)
  if valid_593269 != nil:
    section.add "X-Amz-Date", valid_593269
  var valid_593270 = header.getOrDefault("X-Amz-Credential")
  valid_593270 = validateParameter(valid_593270, JString, required = false,
                                 default = nil)
  if valid_593270 != nil:
    section.add "X-Amz-Credential", valid_593270
  var valid_593271 = header.getOrDefault("X-Amz-Security-Token")
  valid_593271 = validateParameter(valid_593271, JString, required = false,
                                 default = nil)
  if valid_593271 != nil:
    section.add "X-Amz-Security-Token", valid_593271
  var valid_593272 = header.getOrDefault("X-Amz-Algorithm")
  valid_593272 = validateParameter(valid_593272, JString, required = false,
                                 default = nil)
  if valid_593272 != nil:
    section.add "X-Amz-Algorithm", valid_593272
  var valid_593273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593273 = validateParameter(valid_593273, JString, required = false,
                                 default = nil)
  if valid_593273 != nil:
    section.add "X-Amz-SignedHeaders", valid_593273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593275: Call_ListTagsOfResource_593263; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List all tags on an Amazon DynamoDB resource. You can call ListTagsOfResource up to 10 times per second, per account.</p> <p>For an overview on tagging DynamoDB resources, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html">Tagging for DynamoDB</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
  ## 
  let valid = call_593275.validator(path, query, header, formData, body)
  let scheme = call_593275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593275.url(scheme.get, call_593275.host, call_593275.base,
                         call_593275.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593275, url, valid)

proc call*(call_593276: Call_ListTagsOfResource_593263; body: JsonNode): Recallable =
  ## listTagsOfResource
  ## <p>List all tags on an Amazon DynamoDB resource. You can call ListTagsOfResource up to 10 times per second, per account.</p> <p>For an overview on tagging DynamoDB resources, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html">Tagging for DynamoDB</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_593277 = newJObject()
  if body != nil:
    body_593277 = body
  result = call_593276.call(nil, nil, nil, nil, body_593277)

var listTagsOfResource* = Call_ListTagsOfResource_593263(
    name: "listTagsOfResource", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.ListTagsOfResource",
    validator: validate_ListTagsOfResource_593264, base: "/",
    url: url_ListTagsOfResource_593265, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutItem_593278 = ref object of OpenApiRestCall_592364
proc url_PutItem_593280(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutItem_593279(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_593281 = header.getOrDefault("X-Amz-Target")
  valid_593281 = validateParameter(valid_593281, JString, required = true, default = newJString(
      "DynamoDB_20120810.PutItem"))
  if valid_593281 != nil:
    section.add "X-Amz-Target", valid_593281
  var valid_593282 = header.getOrDefault("X-Amz-Signature")
  valid_593282 = validateParameter(valid_593282, JString, required = false,
                                 default = nil)
  if valid_593282 != nil:
    section.add "X-Amz-Signature", valid_593282
  var valid_593283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593283 = validateParameter(valid_593283, JString, required = false,
                                 default = nil)
  if valid_593283 != nil:
    section.add "X-Amz-Content-Sha256", valid_593283
  var valid_593284 = header.getOrDefault("X-Amz-Date")
  valid_593284 = validateParameter(valid_593284, JString, required = false,
                                 default = nil)
  if valid_593284 != nil:
    section.add "X-Amz-Date", valid_593284
  var valid_593285 = header.getOrDefault("X-Amz-Credential")
  valid_593285 = validateParameter(valid_593285, JString, required = false,
                                 default = nil)
  if valid_593285 != nil:
    section.add "X-Amz-Credential", valid_593285
  var valid_593286 = header.getOrDefault("X-Amz-Security-Token")
  valid_593286 = validateParameter(valid_593286, JString, required = false,
                                 default = nil)
  if valid_593286 != nil:
    section.add "X-Amz-Security-Token", valid_593286
  var valid_593287 = header.getOrDefault("X-Amz-Algorithm")
  valid_593287 = validateParameter(valid_593287, JString, required = false,
                                 default = nil)
  if valid_593287 != nil:
    section.add "X-Amz-Algorithm", valid_593287
  var valid_593288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593288 = validateParameter(valid_593288, JString, required = false,
                                 default = nil)
  if valid_593288 != nil:
    section.add "X-Amz-SignedHeaders", valid_593288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593290: Call_PutItem_593278; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new item, or replaces an old item with a new item. If an item that has the same primary key as the new item already exists in the specified table, the new item completely replaces the existing item. You can perform a conditional put operation (add a new item if one with the specified primary key doesn't exist), or replace an existing item if it has certain attribute values. You can return the item's attribute values in the same operation, using the <code>ReturnValues</code> parameter.</p> <important> <p>This topic provides general information about the <code>PutItem</code> API.</p> <p>For information on how to call the <code>PutItem</code> API using the AWS SDK in specific languages, see the following:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/goto/aws-cli/dynamodb-2012-08-10/PutItem"> PutItem in the AWS Command Line Interface</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/DotNetSDKV3/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for .NET</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForCpp/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for C++</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForGoV1/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Go</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForJava/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Java</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/AWSJavaScriptSDK/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for JavaScript</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForPHPV3/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for PHP V3</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/boto3/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Python</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForRubyV2/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Ruby V2</a> </p> </li> </ul> </important> <p>When you add an item, the primary key attributes are the only required attributes. Attribute values cannot be null. String and Binary type attributes must have lengths greater than zero. Set type attributes cannot be empty. Requests with empty values will be rejected with a <code>ValidationException</code> exception.</p> <note> <p>To prevent a new item from replacing an existing item, use a conditional expression that contains the <code>attribute_not_exists</code> function with the name of the attribute being used as the partition key for the table. Since every record must contain that attribute, the <code>attribute_not_exists</code> function will only succeed if no matching item exists.</p> </note> <p>For more information about <code>PutItem</code>, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/WorkingWithItems.html">Working with Items</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
  ## 
  let valid = call_593290.validator(path, query, header, formData, body)
  let scheme = call_593290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593290.url(scheme.get, call_593290.host, call_593290.base,
                         call_593290.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593290, url, valid)

proc call*(call_593291: Call_PutItem_593278; body: JsonNode): Recallable =
  ## putItem
  ## <p>Creates a new item, or replaces an old item with a new item. If an item that has the same primary key as the new item already exists in the specified table, the new item completely replaces the existing item. You can perform a conditional put operation (add a new item if one with the specified primary key doesn't exist), or replace an existing item if it has certain attribute values. You can return the item's attribute values in the same operation, using the <code>ReturnValues</code> parameter.</p> <important> <p>This topic provides general information about the <code>PutItem</code> API.</p> <p>For information on how to call the <code>PutItem</code> API using the AWS SDK in specific languages, see the following:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/goto/aws-cli/dynamodb-2012-08-10/PutItem"> PutItem in the AWS Command Line Interface</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/DotNetSDKV3/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for .NET</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForCpp/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for C++</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForGoV1/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Go</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForJava/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Java</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/AWSJavaScriptSDK/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for JavaScript</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForPHPV3/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for PHP V3</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/boto3/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Python</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForRubyV2/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Ruby V2</a> </p> </li> </ul> </important> <p>When you add an item, the primary key attributes are the only required attributes. Attribute values cannot be null. String and Binary type attributes must have lengths greater than zero. Set type attributes cannot be empty. Requests with empty values will be rejected with a <code>ValidationException</code> exception.</p> <note> <p>To prevent a new item from replacing an existing item, use a conditional expression that contains the <code>attribute_not_exists</code> function with the name of the attribute being used as the partition key for the table. Since every record must contain that attribute, the <code>attribute_not_exists</code> function will only succeed if no matching item exists.</p> </note> <p>For more information about <code>PutItem</code>, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/WorkingWithItems.html">Working with Items</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_593292 = newJObject()
  if body != nil:
    body_593292 = body
  result = call_593291.call(nil, nil, nil, nil, body_593292)

var putItem* = Call_PutItem_593278(name: "putItem", meth: HttpMethod.HttpPost,
                                host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20120810.PutItem",
                                validator: validate_PutItem_593279, base: "/",
                                url: url_PutItem_593280,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_Query_593293 = ref object of OpenApiRestCall_592364
proc url_Query_593295(protocol: Scheme; host: string; base: string; route: string;
                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_Query_593294(path: JsonNode; query: JsonNode; header: JsonNode;
                          formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>The <code>Query</code> operation finds items based on primary key values. You can query any table or secondary index that has a composite primary key (a partition key and a sort key). </p> <p>Use the <code>KeyConditionExpression</code> parameter to provide a specific value for the partition key. The <code>Query</code> operation will return all of the items from the table or index with that partition key value. You can optionally narrow the scope of the <code>Query</code> operation by specifying a sort key value and a comparison operator in <code>KeyConditionExpression</code>. To further refine the <code>Query</code> results, you can optionally provide a <code>FilterExpression</code>. A <code>FilterExpression</code> determines which items within the results should be returned to you. All of the other results are discarded. </p> <p> A <code>Query</code> operation always returns a result set. If no matching items are found, the result set will be empty. Queries that do not return results consume the minimum number of read capacity units for that type of read operation. </p> <note> <p> DynamoDB calculates the number of read capacity units consumed based on item size, not on the amount of data that is returned to an application. The number of capacity units consumed will be the same whether you request all of the attributes (the default behavior) or just some of them (using a projection expression). The number will also be the same whether or not you use a <code>FilterExpression</code>. </p> </note> <p> <code>Query</code> results are always sorted by the sort key value. If the data type of the sort key is Number, the results are returned in numeric order; otherwise, the results are returned in order of UTF-8 bytes. By default, the sort order is ascending. To reverse the order, set the <code>ScanIndexForward</code> parameter to false. </p> <p> A single <code>Query</code> operation will read up to the maximum number of items set (if using the <code>Limit</code> parameter) or a maximum of 1 MB of data and then apply any filtering to the results using <code>FilterExpression</code>. If <code>LastEvaluatedKey</code> is present in the response, you will need to paginate the result set. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Query.html#Query.Pagination">Paginating the Results</a> in the <i>Amazon DynamoDB Developer Guide</i>. </p> <p> <code>FilterExpression</code> is applied after a <code>Query</code> finishes, but before the results are returned. A <code>FilterExpression</code> cannot contain partition key or sort key attributes. You need to specify those attributes in the <code>KeyConditionExpression</code>. </p> <note> <p> A <code>Query</code> operation can return an empty result set and a <code>LastEvaluatedKey</code> if all the items read for the page of results are filtered out. </p> </note> <p>You can query a table, a local secondary index, or a global secondary index. For a query on a table or on a local secondary index, you can set the <code>ConsistentRead</code> parameter to <code>true</code> and obtain a strongly consistent result. Global secondary indexes support eventually consistent reads only, so do not specify <code>ConsistentRead</code> when querying a global secondary index.</p>
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
  var valid_593296 = query.getOrDefault("Limit")
  valid_593296 = validateParameter(valid_593296, JString, required = false,
                                 default = nil)
  if valid_593296 != nil:
    section.add "Limit", valid_593296
  var valid_593297 = query.getOrDefault("ExclusiveStartKey")
  valid_593297 = validateParameter(valid_593297, JString, required = false,
                                 default = nil)
  if valid_593297 != nil:
    section.add "ExclusiveStartKey", valid_593297
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
  var valid_593298 = header.getOrDefault("X-Amz-Target")
  valid_593298 = validateParameter(valid_593298, JString, required = true, default = newJString(
      "DynamoDB_20120810.Query"))
  if valid_593298 != nil:
    section.add "X-Amz-Target", valid_593298
  var valid_593299 = header.getOrDefault("X-Amz-Signature")
  valid_593299 = validateParameter(valid_593299, JString, required = false,
                                 default = nil)
  if valid_593299 != nil:
    section.add "X-Amz-Signature", valid_593299
  var valid_593300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593300 = validateParameter(valid_593300, JString, required = false,
                                 default = nil)
  if valid_593300 != nil:
    section.add "X-Amz-Content-Sha256", valid_593300
  var valid_593301 = header.getOrDefault("X-Amz-Date")
  valid_593301 = validateParameter(valid_593301, JString, required = false,
                                 default = nil)
  if valid_593301 != nil:
    section.add "X-Amz-Date", valid_593301
  var valid_593302 = header.getOrDefault("X-Amz-Credential")
  valid_593302 = validateParameter(valid_593302, JString, required = false,
                                 default = nil)
  if valid_593302 != nil:
    section.add "X-Amz-Credential", valid_593302
  var valid_593303 = header.getOrDefault("X-Amz-Security-Token")
  valid_593303 = validateParameter(valid_593303, JString, required = false,
                                 default = nil)
  if valid_593303 != nil:
    section.add "X-Amz-Security-Token", valid_593303
  var valid_593304 = header.getOrDefault("X-Amz-Algorithm")
  valid_593304 = validateParameter(valid_593304, JString, required = false,
                                 default = nil)
  if valid_593304 != nil:
    section.add "X-Amz-Algorithm", valid_593304
  var valid_593305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593305 = validateParameter(valid_593305, JString, required = false,
                                 default = nil)
  if valid_593305 != nil:
    section.add "X-Amz-SignedHeaders", valid_593305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593307: Call_Query_593293; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>Query</code> operation finds items based on primary key values. You can query any table or secondary index that has a composite primary key (a partition key and a sort key). </p> <p>Use the <code>KeyConditionExpression</code> parameter to provide a specific value for the partition key. The <code>Query</code> operation will return all of the items from the table or index with that partition key value. You can optionally narrow the scope of the <code>Query</code> operation by specifying a sort key value and a comparison operator in <code>KeyConditionExpression</code>. To further refine the <code>Query</code> results, you can optionally provide a <code>FilterExpression</code>. A <code>FilterExpression</code> determines which items within the results should be returned to you. All of the other results are discarded. </p> <p> A <code>Query</code> operation always returns a result set. If no matching items are found, the result set will be empty. Queries that do not return results consume the minimum number of read capacity units for that type of read operation. </p> <note> <p> DynamoDB calculates the number of read capacity units consumed based on item size, not on the amount of data that is returned to an application. The number of capacity units consumed will be the same whether you request all of the attributes (the default behavior) or just some of them (using a projection expression). The number will also be the same whether or not you use a <code>FilterExpression</code>. </p> </note> <p> <code>Query</code> results are always sorted by the sort key value. If the data type of the sort key is Number, the results are returned in numeric order; otherwise, the results are returned in order of UTF-8 bytes. By default, the sort order is ascending. To reverse the order, set the <code>ScanIndexForward</code> parameter to false. </p> <p> A single <code>Query</code> operation will read up to the maximum number of items set (if using the <code>Limit</code> parameter) or a maximum of 1 MB of data and then apply any filtering to the results using <code>FilterExpression</code>. If <code>LastEvaluatedKey</code> is present in the response, you will need to paginate the result set. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Query.html#Query.Pagination">Paginating the Results</a> in the <i>Amazon DynamoDB Developer Guide</i>. </p> <p> <code>FilterExpression</code> is applied after a <code>Query</code> finishes, but before the results are returned. A <code>FilterExpression</code> cannot contain partition key or sort key attributes. You need to specify those attributes in the <code>KeyConditionExpression</code>. </p> <note> <p> A <code>Query</code> operation can return an empty result set and a <code>LastEvaluatedKey</code> if all the items read for the page of results are filtered out. </p> </note> <p>You can query a table, a local secondary index, or a global secondary index. For a query on a table or on a local secondary index, you can set the <code>ConsistentRead</code> parameter to <code>true</code> and obtain a strongly consistent result. Global secondary indexes support eventually consistent reads only, so do not specify <code>ConsistentRead</code> when querying a global secondary index.</p>
  ## 
  let valid = call_593307.validator(path, query, header, formData, body)
  let scheme = call_593307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593307.url(scheme.get, call_593307.host, call_593307.base,
                         call_593307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593307, url, valid)

proc call*(call_593308: Call_Query_593293; body: JsonNode; Limit: string = "";
          ExclusiveStartKey: string = ""): Recallable =
  ## query
  ## <p>The <code>Query</code> operation finds items based on primary key values. You can query any table or secondary index that has a composite primary key (a partition key and a sort key). </p> <p>Use the <code>KeyConditionExpression</code> parameter to provide a specific value for the partition key. The <code>Query</code> operation will return all of the items from the table or index with that partition key value. You can optionally narrow the scope of the <code>Query</code> operation by specifying a sort key value and a comparison operator in <code>KeyConditionExpression</code>. To further refine the <code>Query</code> results, you can optionally provide a <code>FilterExpression</code>. A <code>FilterExpression</code> determines which items within the results should be returned to you. All of the other results are discarded. </p> <p> A <code>Query</code> operation always returns a result set. If no matching items are found, the result set will be empty. Queries that do not return results consume the minimum number of read capacity units for that type of read operation. </p> <note> <p> DynamoDB calculates the number of read capacity units consumed based on item size, not on the amount of data that is returned to an application. The number of capacity units consumed will be the same whether you request all of the attributes (the default behavior) or just some of them (using a projection expression). The number will also be the same whether or not you use a <code>FilterExpression</code>. </p> </note> <p> <code>Query</code> results are always sorted by the sort key value. If the data type of the sort key is Number, the results are returned in numeric order; otherwise, the results are returned in order of UTF-8 bytes. By default, the sort order is ascending. To reverse the order, set the <code>ScanIndexForward</code> parameter to false. </p> <p> A single <code>Query</code> operation will read up to the maximum number of items set (if using the <code>Limit</code> parameter) or a maximum of 1 MB of data and then apply any filtering to the results using <code>FilterExpression</code>. If <code>LastEvaluatedKey</code> is present in the response, you will need to paginate the result set. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Query.html#Query.Pagination">Paginating the Results</a> in the <i>Amazon DynamoDB Developer Guide</i>. </p> <p> <code>FilterExpression</code> is applied after a <code>Query</code> finishes, but before the results are returned. A <code>FilterExpression</code> cannot contain partition key or sort key attributes. You need to specify those attributes in the <code>KeyConditionExpression</code>. </p> <note> <p> A <code>Query</code> operation can return an empty result set and a <code>LastEvaluatedKey</code> if all the items read for the page of results are filtered out. </p> </note> <p>You can query a table, a local secondary index, or a global secondary index. For a query on a table or on a local secondary index, you can set the <code>ConsistentRead</code> parameter to <code>true</code> and obtain a strongly consistent result. Global secondary indexes support eventually consistent reads only, so do not specify <code>ConsistentRead</code> when querying a global secondary index.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  ##   ExclusiveStartKey: string
  ##                    : Pagination token
  var query_593309 = newJObject()
  var body_593310 = newJObject()
  add(query_593309, "Limit", newJString(Limit))
  if body != nil:
    body_593310 = body
  add(query_593309, "ExclusiveStartKey", newJString(ExclusiveStartKey))
  result = call_593308.call(nil, query_593309, nil, nil, body_593310)

var query* = Call_Query_593293(name: "query", meth: HttpMethod.HttpPost,
                            host: "dynamodb.amazonaws.com",
                            route: "/#X-Amz-Target=DynamoDB_20120810.Query",
                            validator: validate_Query_593294, base: "/",
                            url: url_Query_593295,
                            schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreTableFromBackup_593311 = ref object of OpenApiRestCall_592364
proc url_RestoreTableFromBackup_593313(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RestoreTableFromBackup_593312(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_593314 = header.getOrDefault("X-Amz-Target")
  valid_593314 = validateParameter(valid_593314, JString, required = true, default = newJString(
      "DynamoDB_20120810.RestoreTableFromBackup"))
  if valid_593314 != nil:
    section.add "X-Amz-Target", valid_593314
  var valid_593315 = header.getOrDefault("X-Amz-Signature")
  valid_593315 = validateParameter(valid_593315, JString, required = false,
                                 default = nil)
  if valid_593315 != nil:
    section.add "X-Amz-Signature", valid_593315
  var valid_593316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593316 = validateParameter(valid_593316, JString, required = false,
                                 default = nil)
  if valid_593316 != nil:
    section.add "X-Amz-Content-Sha256", valid_593316
  var valid_593317 = header.getOrDefault("X-Amz-Date")
  valid_593317 = validateParameter(valid_593317, JString, required = false,
                                 default = nil)
  if valid_593317 != nil:
    section.add "X-Amz-Date", valid_593317
  var valid_593318 = header.getOrDefault("X-Amz-Credential")
  valid_593318 = validateParameter(valid_593318, JString, required = false,
                                 default = nil)
  if valid_593318 != nil:
    section.add "X-Amz-Credential", valid_593318
  var valid_593319 = header.getOrDefault("X-Amz-Security-Token")
  valid_593319 = validateParameter(valid_593319, JString, required = false,
                                 default = nil)
  if valid_593319 != nil:
    section.add "X-Amz-Security-Token", valid_593319
  var valid_593320 = header.getOrDefault("X-Amz-Algorithm")
  valid_593320 = validateParameter(valid_593320, JString, required = false,
                                 default = nil)
  if valid_593320 != nil:
    section.add "X-Amz-Algorithm", valid_593320
  var valid_593321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593321 = validateParameter(valid_593321, JString, required = false,
                                 default = nil)
  if valid_593321 != nil:
    section.add "X-Amz-SignedHeaders", valid_593321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593323: Call_RestoreTableFromBackup_593311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new table from an existing backup. Any number of users can execute up to 4 concurrent restores (any type of restore) in a given account. </p> <p>You can call <code>RestoreTableFromBackup</code> at a maximum rate of 10 times per second.</p> <p>You must manually set up the following on the restored table:</p> <ul> <li> <p>Auto scaling policies</p> </li> <li> <p>IAM policies</p> </li> <li> <p>Amazon CloudWatch metrics and alarms</p> </li> <li> <p>Tags</p> </li> <li> <p>Stream settings</p> </li> <li> <p>Time to Live (TTL) settings</p> </li> </ul>
  ## 
  let valid = call_593323.validator(path, query, header, formData, body)
  let scheme = call_593323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593323.url(scheme.get, call_593323.host, call_593323.base,
                         call_593323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593323, url, valid)

proc call*(call_593324: Call_RestoreTableFromBackup_593311; body: JsonNode): Recallable =
  ## restoreTableFromBackup
  ## <p>Creates a new table from an existing backup. Any number of users can execute up to 4 concurrent restores (any type of restore) in a given account. </p> <p>You can call <code>RestoreTableFromBackup</code> at a maximum rate of 10 times per second.</p> <p>You must manually set up the following on the restored table:</p> <ul> <li> <p>Auto scaling policies</p> </li> <li> <p>IAM policies</p> </li> <li> <p>Amazon CloudWatch metrics and alarms</p> </li> <li> <p>Tags</p> </li> <li> <p>Stream settings</p> </li> <li> <p>Time to Live (TTL) settings</p> </li> </ul>
  ##   body: JObject (required)
  var body_593325 = newJObject()
  if body != nil:
    body_593325 = body
  result = call_593324.call(nil, nil, nil, nil, body_593325)

var restoreTableFromBackup* = Call_RestoreTableFromBackup_593311(
    name: "restoreTableFromBackup", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.RestoreTableFromBackup",
    validator: validate_RestoreTableFromBackup_593312, base: "/",
    url: url_RestoreTableFromBackup_593313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreTableToPointInTime_593326 = ref object of OpenApiRestCall_592364
proc url_RestoreTableToPointInTime_593328(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RestoreTableToPointInTime_593327(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_593329 = header.getOrDefault("X-Amz-Target")
  valid_593329 = validateParameter(valid_593329, JString, required = true, default = newJString(
      "DynamoDB_20120810.RestoreTableToPointInTime"))
  if valid_593329 != nil:
    section.add "X-Amz-Target", valid_593329
  var valid_593330 = header.getOrDefault("X-Amz-Signature")
  valid_593330 = validateParameter(valid_593330, JString, required = false,
                                 default = nil)
  if valid_593330 != nil:
    section.add "X-Amz-Signature", valid_593330
  var valid_593331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593331 = validateParameter(valid_593331, JString, required = false,
                                 default = nil)
  if valid_593331 != nil:
    section.add "X-Amz-Content-Sha256", valid_593331
  var valid_593332 = header.getOrDefault("X-Amz-Date")
  valid_593332 = validateParameter(valid_593332, JString, required = false,
                                 default = nil)
  if valid_593332 != nil:
    section.add "X-Amz-Date", valid_593332
  var valid_593333 = header.getOrDefault("X-Amz-Credential")
  valid_593333 = validateParameter(valid_593333, JString, required = false,
                                 default = nil)
  if valid_593333 != nil:
    section.add "X-Amz-Credential", valid_593333
  var valid_593334 = header.getOrDefault("X-Amz-Security-Token")
  valid_593334 = validateParameter(valid_593334, JString, required = false,
                                 default = nil)
  if valid_593334 != nil:
    section.add "X-Amz-Security-Token", valid_593334
  var valid_593335 = header.getOrDefault("X-Amz-Algorithm")
  valid_593335 = validateParameter(valid_593335, JString, required = false,
                                 default = nil)
  if valid_593335 != nil:
    section.add "X-Amz-Algorithm", valid_593335
  var valid_593336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593336 = validateParameter(valid_593336, JString, required = false,
                                 default = nil)
  if valid_593336 != nil:
    section.add "X-Amz-SignedHeaders", valid_593336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593338: Call_RestoreTableToPointInTime_593326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Restores the specified table to the specified point in time within <code>EarliestRestorableDateTime</code> and <code>LatestRestorableDateTime</code>. You can restore your table to any point in time during the last 35 days. Any number of users can execute up to 4 concurrent restores (any type of restore) in a given account. </p> <p> When you restore using point in time recovery, DynamoDB restores your table data to the state based on the selected date and time (day:hour:minute:second) to a new table. </p> <p> Along with data, the following are also included on the new restored table using point in time recovery: </p> <ul> <li> <p>Global secondary indexes (GSIs)</p> </li> <li> <p>Local secondary indexes (LSIs)</p> </li> <li> <p>Provisioned read and write capacity</p> </li> <li> <p>Encryption settings</p> <important> <p> All these settings come from the current settings of the source table at the time of restore. </p> </important> </li> </ul> <p>You must manually set up the following on the restored table:</p> <ul> <li> <p>Auto scaling policies</p> </li> <li> <p>IAM policies</p> </li> <li> <p>Amazon CloudWatch metrics and alarms</p> </li> <li> <p>Tags</p> </li> <li> <p>Stream settings</p> </li> <li> <p>Time to Live (TTL) settings</p> </li> <li> <p>Point in time recovery settings</p> </li> </ul>
  ## 
  let valid = call_593338.validator(path, query, header, formData, body)
  let scheme = call_593338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593338.url(scheme.get, call_593338.host, call_593338.base,
                         call_593338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593338, url, valid)

proc call*(call_593339: Call_RestoreTableToPointInTime_593326; body: JsonNode): Recallable =
  ## restoreTableToPointInTime
  ## <p>Restores the specified table to the specified point in time within <code>EarliestRestorableDateTime</code> and <code>LatestRestorableDateTime</code>. You can restore your table to any point in time during the last 35 days. Any number of users can execute up to 4 concurrent restores (any type of restore) in a given account. </p> <p> When you restore using point in time recovery, DynamoDB restores your table data to the state based on the selected date and time (day:hour:minute:second) to a new table. </p> <p> Along with data, the following are also included on the new restored table using point in time recovery: </p> <ul> <li> <p>Global secondary indexes (GSIs)</p> </li> <li> <p>Local secondary indexes (LSIs)</p> </li> <li> <p>Provisioned read and write capacity</p> </li> <li> <p>Encryption settings</p> <important> <p> All these settings come from the current settings of the source table at the time of restore. </p> </important> </li> </ul> <p>You must manually set up the following on the restored table:</p> <ul> <li> <p>Auto scaling policies</p> </li> <li> <p>IAM policies</p> </li> <li> <p>Amazon CloudWatch metrics and alarms</p> </li> <li> <p>Tags</p> </li> <li> <p>Stream settings</p> </li> <li> <p>Time to Live (TTL) settings</p> </li> <li> <p>Point in time recovery settings</p> </li> </ul>
  ##   body: JObject (required)
  var body_593340 = newJObject()
  if body != nil:
    body_593340 = body
  result = call_593339.call(nil, nil, nil, nil, body_593340)

var restoreTableToPointInTime* = Call_RestoreTableToPointInTime_593326(
    name: "restoreTableToPointInTime", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.RestoreTableToPointInTime",
    validator: validate_RestoreTableToPointInTime_593327, base: "/",
    url: url_RestoreTableToPointInTime_593328,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_Scan_593341 = ref object of OpenApiRestCall_592364
proc url_Scan_593343(protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_Scan_593342(path: JsonNode; query: JsonNode; header: JsonNode;
                         formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>The <code>Scan</code> operation returns one or more items and item attributes by accessing every item in a table or a secondary index. To have DynamoDB return fewer items, you can provide a <code>FilterExpression</code> operation.</p> <p>If the total number of scanned items exceeds the maximum dataset size limit of 1 MB, the scan stops and results are returned to the user as a <code>LastEvaluatedKey</code> value to continue the scan in a subsequent operation. The results also include the number of items exceeding the limit. A scan can result in no table data meeting the filter criteria. </p> <p>A single <code>Scan</code> operation reads up to the maximum number of items set (if using the <code>Limit</code> parameter) or a maximum of 1 MB of data and then apply any filtering to the results using <code>FilterExpression</code>. If <code>LastEvaluatedKey</code> is present in the response, you need to paginate the result set. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Scan.html#Scan.Pagination">Paginating the Results</a> in the <i>Amazon DynamoDB Developer Guide</i>. </p> <p> <code>Scan</code> operations proceed sequentially; however, for faster performance on a large table or secondary index, applications can request a parallel <code>Scan</code> operation by providing the <code>Segment</code> and <code>TotalSegments</code> parameters. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Scan.html#Scan.ParallelScan">Parallel Scan</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p> <p> <code>Scan</code> uses eventually consistent reads when accessing the data in a table; therefore, the result set might not include the changes to data in the table immediately before the operation began. If you need a consistent copy of the data, as of the time that the <code>Scan</code> begins, you can set the <code>ConsistentRead</code> parameter to <code>true</code>.</p>
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
  var valid_593344 = query.getOrDefault("Limit")
  valid_593344 = validateParameter(valid_593344, JString, required = false,
                                 default = nil)
  if valid_593344 != nil:
    section.add "Limit", valid_593344
  var valid_593345 = query.getOrDefault("ExclusiveStartKey")
  valid_593345 = validateParameter(valid_593345, JString, required = false,
                                 default = nil)
  if valid_593345 != nil:
    section.add "ExclusiveStartKey", valid_593345
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
  var valid_593346 = header.getOrDefault("X-Amz-Target")
  valid_593346 = validateParameter(valid_593346, JString, required = true,
                                 default = newJString("DynamoDB_20120810.Scan"))
  if valid_593346 != nil:
    section.add "X-Amz-Target", valid_593346
  var valid_593347 = header.getOrDefault("X-Amz-Signature")
  valid_593347 = validateParameter(valid_593347, JString, required = false,
                                 default = nil)
  if valid_593347 != nil:
    section.add "X-Amz-Signature", valid_593347
  var valid_593348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593348 = validateParameter(valid_593348, JString, required = false,
                                 default = nil)
  if valid_593348 != nil:
    section.add "X-Amz-Content-Sha256", valid_593348
  var valid_593349 = header.getOrDefault("X-Amz-Date")
  valid_593349 = validateParameter(valid_593349, JString, required = false,
                                 default = nil)
  if valid_593349 != nil:
    section.add "X-Amz-Date", valid_593349
  var valid_593350 = header.getOrDefault("X-Amz-Credential")
  valid_593350 = validateParameter(valid_593350, JString, required = false,
                                 default = nil)
  if valid_593350 != nil:
    section.add "X-Amz-Credential", valid_593350
  var valid_593351 = header.getOrDefault("X-Amz-Security-Token")
  valid_593351 = validateParameter(valid_593351, JString, required = false,
                                 default = nil)
  if valid_593351 != nil:
    section.add "X-Amz-Security-Token", valid_593351
  var valid_593352 = header.getOrDefault("X-Amz-Algorithm")
  valid_593352 = validateParameter(valid_593352, JString, required = false,
                                 default = nil)
  if valid_593352 != nil:
    section.add "X-Amz-Algorithm", valid_593352
  var valid_593353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593353 = validateParameter(valid_593353, JString, required = false,
                                 default = nil)
  if valid_593353 != nil:
    section.add "X-Amz-SignedHeaders", valid_593353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593355: Call_Scan_593341; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>Scan</code> operation returns one or more items and item attributes by accessing every item in a table or a secondary index. To have DynamoDB return fewer items, you can provide a <code>FilterExpression</code> operation.</p> <p>If the total number of scanned items exceeds the maximum dataset size limit of 1 MB, the scan stops and results are returned to the user as a <code>LastEvaluatedKey</code> value to continue the scan in a subsequent operation. The results also include the number of items exceeding the limit. A scan can result in no table data meeting the filter criteria. </p> <p>A single <code>Scan</code> operation reads up to the maximum number of items set (if using the <code>Limit</code> parameter) or a maximum of 1 MB of data and then apply any filtering to the results using <code>FilterExpression</code>. If <code>LastEvaluatedKey</code> is present in the response, you need to paginate the result set. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Scan.html#Scan.Pagination">Paginating the Results</a> in the <i>Amazon DynamoDB Developer Guide</i>. </p> <p> <code>Scan</code> operations proceed sequentially; however, for faster performance on a large table or secondary index, applications can request a parallel <code>Scan</code> operation by providing the <code>Segment</code> and <code>TotalSegments</code> parameters. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Scan.html#Scan.ParallelScan">Parallel Scan</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p> <p> <code>Scan</code> uses eventually consistent reads when accessing the data in a table; therefore, the result set might not include the changes to data in the table immediately before the operation began. If you need a consistent copy of the data, as of the time that the <code>Scan</code> begins, you can set the <code>ConsistentRead</code> parameter to <code>true</code>.</p>
  ## 
  let valid = call_593355.validator(path, query, header, formData, body)
  let scheme = call_593355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593355.url(scheme.get, call_593355.host, call_593355.base,
                         call_593355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593355, url, valid)

proc call*(call_593356: Call_Scan_593341; body: JsonNode; Limit: string = "";
          ExclusiveStartKey: string = ""): Recallable =
  ## scan
  ## <p>The <code>Scan</code> operation returns one or more items and item attributes by accessing every item in a table or a secondary index. To have DynamoDB return fewer items, you can provide a <code>FilterExpression</code> operation.</p> <p>If the total number of scanned items exceeds the maximum dataset size limit of 1 MB, the scan stops and results are returned to the user as a <code>LastEvaluatedKey</code> value to continue the scan in a subsequent operation. The results also include the number of items exceeding the limit. A scan can result in no table data meeting the filter criteria. </p> <p>A single <code>Scan</code> operation reads up to the maximum number of items set (if using the <code>Limit</code> parameter) or a maximum of 1 MB of data and then apply any filtering to the results using <code>FilterExpression</code>. If <code>LastEvaluatedKey</code> is present in the response, you need to paginate the result set. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Scan.html#Scan.Pagination">Paginating the Results</a> in the <i>Amazon DynamoDB Developer Guide</i>. </p> <p> <code>Scan</code> operations proceed sequentially; however, for faster performance on a large table or secondary index, applications can request a parallel <code>Scan</code> operation by providing the <code>Segment</code> and <code>TotalSegments</code> parameters. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Scan.html#Scan.ParallelScan">Parallel Scan</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p> <p> <code>Scan</code> uses eventually consistent reads when accessing the data in a table; therefore, the result set might not include the changes to data in the table immediately before the operation began. If you need a consistent copy of the data, as of the time that the <code>Scan</code> begins, you can set the <code>ConsistentRead</code> parameter to <code>true</code>.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  ##   ExclusiveStartKey: string
  ##                    : Pagination token
  var query_593357 = newJObject()
  var body_593358 = newJObject()
  add(query_593357, "Limit", newJString(Limit))
  if body != nil:
    body_593358 = body
  add(query_593357, "ExclusiveStartKey", newJString(ExclusiveStartKey))
  result = call_593356.call(nil, query_593357, nil, nil, body_593358)

var scan* = Call_Scan_593341(name: "scan", meth: HttpMethod.HttpPost,
                          host: "dynamodb.amazonaws.com",
                          route: "/#X-Amz-Target=DynamoDB_20120810.Scan",
                          validator: validate_Scan_593342, base: "/", url: url_Scan_593343,
                          schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_593359 = ref object of OpenApiRestCall_592364
proc url_TagResource_593361(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_593360(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_593362 = header.getOrDefault("X-Amz-Target")
  valid_593362 = validateParameter(valid_593362, JString, required = true, default = newJString(
      "DynamoDB_20120810.TagResource"))
  if valid_593362 != nil:
    section.add "X-Amz-Target", valid_593362
  var valid_593363 = header.getOrDefault("X-Amz-Signature")
  valid_593363 = validateParameter(valid_593363, JString, required = false,
                                 default = nil)
  if valid_593363 != nil:
    section.add "X-Amz-Signature", valid_593363
  var valid_593364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593364 = validateParameter(valid_593364, JString, required = false,
                                 default = nil)
  if valid_593364 != nil:
    section.add "X-Amz-Content-Sha256", valid_593364
  var valid_593365 = header.getOrDefault("X-Amz-Date")
  valid_593365 = validateParameter(valid_593365, JString, required = false,
                                 default = nil)
  if valid_593365 != nil:
    section.add "X-Amz-Date", valid_593365
  var valid_593366 = header.getOrDefault("X-Amz-Credential")
  valid_593366 = validateParameter(valid_593366, JString, required = false,
                                 default = nil)
  if valid_593366 != nil:
    section.add "X-Amz-Credential", valid_593366
  var valid_593367 = header.getOrDefault("X-Amz-Security-Token")
  valid_593367 = validateParameter(valid_593367, JString, required = false,
                                 default = nil)
  if valid_593367 != nil:
    section.add "X-Amz-Security-Token", valid_593367
  var valid_593368 = header.getOrDefault("X-Amz-Algorithm")
  valid_593368 = validateParameter(valid_593368, JString, required = false,
                                 default = nil)
  if valid_593368 != nil:
    section.add "X-Amz-Algorithm", valid_593368
  var valid_593369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593369 = validateParameter(valid_593369, JString, required = false,
                                 default = nil)
  if valid_593369 != nil:
    section.add "X-Amz-SignedHeaders", valid_593369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593371: Call_TagResource_593359; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associate a set of tags with an Amazon DynamoDB resource. You can then activate these user-defined tags so that they appear on the Billing and Cost Management console for cost allocation tracking. You can call TagResource up to five times per second, per account. </p> <p>For an overview on tagging DynamoDB resources, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html">Tagging for DynamoDB</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
  ## 
  let valid = call_593371.validator(path, query, header, formData, body)
  let scheme = call_593371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593371.url(scheme.get, call_593371.host, call_593371.base,
                         call_593371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593371, url, valid)

proc call*(call_593372: Call_TagResource_593359; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Associate a set of tags with an Amazon DynamoDB resource. You can then activate these user-defined tags so that they appear on the Billing and Cost Management console for cost allocation tracking. You can call TagResource up to five times per second, per account. </p> <p>For an overview on tagging DynamoDB resources, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html">Tagging for DynamoDB</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_593373 = newJObject()
  if body != nil:
    body_593373 = body
  result = call_593372.call(nil, nil, nil, nil, body_593373)

var tagResource* = Call_TagResource_593359(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20120810.TagResource",
                                        validator: validate_TagResource_593360,
                                        base: "/", url: url_TagResource_593361,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TransactGetItems_593374 = ref object of OpenApiRestCall_592364
proc url_TransactGetItems_593376(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TransactGetItems_593375(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p> <code>TransactGetItems</code> is a synchronous operation that atomically retrieves multiple items from one or more tables (but not from indexes) in a single account and Region. A <code>TransactGetItems</code> call can contain up to 25 <code>TransactGetItem</code> objects, each of which contains a <code>Get</code> structure that specifies an item to retrieve from a table in the account and Region. A call to <code>TransactGetItems</code> cannot retrieve items from tables in more than one AWS account or Region. The aggregate size of the items in the transaction cannot exceed 4 MB.</p> <note> <p>All AWS Regions and AWS GovCloud (US) support up to 25 items per transaction with up to 4 MB of data, except the following AWS Regions: </p> <ul> <li> <p>China (Beijing)</p> </li> <li> <p>China (Ningxia)</p> </li> </ul> <p>The China (Beijing) and China (Ningxia) Regions support up to 10 items per transaction with up to 4 MB of data. </p> </note> <p>DynamoDB rejects the entire <code>TransactGetItems</code> request if any of the following is true:</p> <ul> <li> <p>A conflicting operation is in the process of updating an item to be read.</p> </li> <li> <p>There is insufficient provisioned capacity for the transaction to be completed.</p> </li> <li> <p>There is a user error, such as an invalid data format.</p> </li> <li> <p>The aggregate size of the items in the transaction cannot exceed 4 MB.</p> </li> </ul>
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
  var valid_593377 = header.getOrDefault("X-Amz-Target")
  valid_593377 = validateParameter(valid_593377, JString, required = true, default = newJString(
      "DynamoDB_20120810.TransactGetItems"))
  if valid_593377 != nil:
    section.add "X-Amz-Target", valid_593377
  var valid_593378 = header.getOrDefault("X-Amz-Signature")
  valid_593378 = validateParameter(valid_593378, JString, required = false,
                                 default = nil)
  if valid_593378 != nil:
    section.add "X-Amz-Signature", valid_593378
  var valid_593379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593379 = validateParameter(valid_593379, JString, required = false,
                                 default = nil)
  if valid_593379 != nil:
    section.add "X-Amz-Content-Sha256", valid_593379
  var valid_593380 = header.getOrDefault("X-Amz-Date")
  valid_593380 = validateParameter(valid_593380, JString, required = false,
                                 default = nil)
  if valid_593380 != nil:
    section.add "X-Amz-Date", valid_593380
  var valid_593381 = header.getOrDefault("X-Amz-Credential")
  valid_593381 = validateParameter(valid_593381, JString, required = false,
                                 default = nil)
  if valid_593381 != nil:
    section.add "X-Amz-Credential", valid_593381
  var valid_593382 = header.getOrDefault("X-Amz-Security-Token")
  valid_593382 = validateParameter(valid_593382, JString, required = false,
                                 default = nil)
  if valid_593382 != nil:
    section.add "X-Amz-Security-Token", valid_593382
  var valid_593383 = header.getOrDefault("X-Amz-Algorithm")
  valid_593383 = validateParameter(valid_593383, JString, required = false,
                                 default = nil)
  if valid_593383 != nil:
    section.add "X-Amz-Algorithm", valid_593383
  var valid_593384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593384 = validateParameter(valid_593384, JString, required = false,
                                 default = nil)
  if valid_593384 != nil:
    section.add "X-Amz-SignedHeaders", valid_593384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593386: Call_TransactGetItems_593374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>TransactGetItems</code> is a synchronous operation that atomically retrieves multiple items from one or more tables (but not from indexes) in a single account and Region. A <code>TransactGetItems</code> call can contain up to 25 <code>TransactGetItem</code> objects, each of which contains a <code>Get</code> structure that specifies an item to retrieve from a table in the account and Region. A call to <code>TransactGetItems</code> cannot retrieve items from tables in more than one AWS account or Region. The aggregate size of the items in the transaction cannot exceed 4 MB.</p> <note> <p>All AWS Regions and AWS GovCloud (US) support up to 25 items per transaction with up to 4 MB of data, except the following AWS Regions: </p> <ul> <li> <p>China (Beijing)</p> </li> <li> <p>China (Ningxia)</p> </li> </ul> <p>The China (Beijing) and China (Ningxia) Regions support up to 10 items per transaction with up to 4 MB of data. </p> </note> <p>DynamoDB rejects the entire <code>TransactGetItems</code> request if any of the following is true:</p> <ul> <li> <p>A conflicting operation is in the process of updating an item to be read.</p> </li> <li> <p>There is insufficient provisioned capacity for the transaction to be completed.</p> </li> <li> <p>There is a user error, such as an invalid data format.</p> </li> <li> <p>The aggregate size of the items in the transaction cannot exceed 4 MB.</p> </li> </ul>
  ## 
  let valid = call_593386.validator(path, query, header, formData, body)
  let scheme = call_593386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593386.url(scheme.get, call_593386.host, call_593386.base,
                         call_593386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593386, url, valid)

proc call*(call_593387: Call_TransactGetItems_593374; body: JsonNode): Recallable =
  ## transactGetItems
  ## <p> <code>TransactGetItems</code> is a synchronous operation that atomically retrieves multiple items from one or more tables (but not from indexes) in a single account and Region. A <code>TransactGetItems</code> call can contain up to 25 <code>TransactGetItem</code> objects, each of which contains a <code>Get</code> structure that specifies an item to retrieve from a table in the account and Region. A call to <code>TransactGetItems</code> cannot retrieve items from tables in more than one AWS account or Region. The aggregate size of the items in the transaction cannot exceed 4 MB.</p> <note> <p>All AWS Regions and AWS GovCloud (US) support up to 25 items per transaction with up to 4 MB of data, except the following AWS Regions: </p> <ul> <li> <p>China (Beijing)</p> </li> <li> <p>China (Ningxia)</p> </li> </ul> <p>The China (Beijing) and China (Ningxia) Regions support up to 10 items per transaction with up to 4 MB of data. </p> </note> <p>DynamoDB rejects the entire <code>TransactGetItems</code> request if any of the following is true:</p> <ul> <li> <p>A conflicting operation is in the process of updating an item to be read.</p> </li> <li> <p>There is insufficient provisioned capacity for the transaction to be completed.</p> </li> <li> <p>There is a user error, such as an invalid data format.</p> </li> <li> <p>The aggregate size of the items in the transaction cannot exceed 4 MB.</p> </li> </ul>
  ##   body: JObject (required)
  var body_593388 = newJObject()
  if body != nil:
    body_593388 = body
  result = call_593387.call(nil, nil, nil, nil, body_593388)

var transactGetItems* = Call_TransactGetItems_593374(name: "transactGetItems",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.TransactGetItems",
    validator: validate_TransactGetItems_593375, base: "/",
    url: url_TransactGetItems_593376, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TransactWriteItems_593389 = ref object of OpenApiRestCall_592364
proc url_TransactWriteItems_593391(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TransactWriteItems_593390(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p> <code>TransactWriteItems</code> is a synchronous write operation that groups up to 25 action requests. These actions can target items in different tables, but not in different AWS accounts or Regions, and no two actions can target the same item. For example, you cannot both <code>ConditionCheck</code> and <code>Update</code> the same item. The aggregate size of the items in the transaction cannot exceed 4 MB.</p> <note> <p>All AWS Regions and AWS GovCloud (US) support up to 25 items per transaction with up to 4 MB of data, except the following AWS Regions: </p> <ul> <li> <p>China (Beijing)</p> </li> <li> <p>China (Ningxia)</p> </li> </ul> <p>The China (Beijing) and China (Ningxia) Regions support up to 10 items per transaction with up to 4 MB of data. </p> </note> <p>The actions are completed atomically so that either all of them succeed, or all of them fail. They are defined by the following objects:</p> <ul> <li> <p> <code>Put</code>  &#x97;   Initiates a <code>PutItem</code> operation to write a new item. This structure specifies the primary key of the item to be written, the name of the table to write it in, an optional condition expression that must be satisfied for the write to succeed, a list of the item's attributes, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> <li> <p> <code>Update</code>  &#x97;   Initiates an <code>UpdateItem</code> operation to update an existing item. This structure specifies the primary key of the item to be updated, the name of the table where it resides, an optional condition expression that must be satisfied for the update to succeed, an expression that defines one or more attributes to be updated, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> <li> <p> <code>Delete</code>  &#x97;   Initiates a <code>DeleteItem</code> operation to delete an existing item. This structure specifies the primary key of the item to be deleted, the name of the table where it resides, an optional condition expression that must be satisfied for the deletion to succeed, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> <li> <p> <code>ConditionCheck</code>  &#x97;   Applies a condition to an item that is not being modified by the transaction. This structure specifies the primary key of the item to be checked, the name of the table where it resides, a condition expression that must be satisfied for the transaction to succeed, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> </ul> <p>DynamoDB rejects the entire <code>TransactWriteItems</code> request if any of the following is true:</p> <ul> <li> <p>A condition in one of the condition expressions is not met.</p> </li> <li> <p>An ongoing operation is in the process of updating the same item.</p> </li> <li> <p>There is insufficient provisioned capacity for the transaction to be completed.</p> </li> <li> <p>An item size becomes too large (bigger than 400 KB), a local secondary index (LSI) becomes too large, or a similar validation error occurs because of changes made by the transaction.</p> </li> <li> <p>The aggregate size of the items in the transaction exceeds 4 MB.</p> </li> <li> <p>There is a user error, such as an invalid data format.</p> </li> </ul>
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
  var valid_593392 = header.getOrDefault("X-Amz-Target")
  valid_593392 = validateParameter(valid_593392, JString, required = true, default = newJString(
      "DynamoDB_20120810.TransactWriteItems"))
  if valid_593392 != nil:
    section.add "X-Amz-Target", valid_593392
  var valid_593393 = header.getOrDefault("X-Amz-Signature")
  valid_593393 = validateParameter(valid_593393, JString, required = false,
                                 default = nil)
  if valid_593393 != nil:
    section.add "X-Amz-Signature", valid_593393
  var valid_593394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593394 = validateParameter(valid_593394, JString, required = false,
                                 default = nil)
  if valid_593394 != nil:
    section.add "X-Amz-Content-Sha256", valid_593394
  var valid_593395 = header.getOrDefault("X-Amz-Date")
  valid_593395 = validateParameter(valid_593395, JString, required = false,
                                 default = nil)
  if valid_593395 != nil:
    section.add "X-Amz-Date", valid_593395
  var valid_593396 = header.getOrDefault("X-Amz-Credential")
  valid_593396 = validateParameter(valid_593396, JString, required = false,
                                 default = nil)
  if valid_593396 != nil:
    section.add "X-Amz-Credential", valid_593396
  var valid_593397 = header.getOrDefault("X-Amz-Security-Token")
  valid_593397 = validateParameter(valid_593397, JString, required = false,
                                 default = nil)
  if valid_593397 != nil:
    section.add "X-Amz-Security-Token", valid_593397
  var valid_593398 = header.getOrDefault("X-Amz-Algorithm")
  valid_593398 = validateParameter(valid_593398, JString, required = false,
                                 default = nil)
  if valid_593398 != nil:
    section.add "X-Amz-Algorithm", valid_593398
  var valid_593399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593399 = validateParameter(valid_593399, JString, required = false,
                                 default = nil)
  if valid_593399 != nil:
    section.add "X-Amz-SignedHeaders", valid_593399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593401: Call_TransactWriteItems_593389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>TransactWriteItems</code> is a synchronous write operation that groups up to 25 action requests. These actions can target items in different tables, but not in different AWS accounts or Regions, and no two actions can target the same item. For example, you cannot both <code>ConditionCheck</code> and <code>Update</code> the same item. The aggregate size of the items in the transaction cannot exceed 4 MB.</p> <note> <p>All AWS Regions and AWS GovCloud (US) support up to 25 items per transaction with up to 4 MB of data, except the following AWS Regions: </p> <ul> <li> <p>China (Beijing)</p> </li> <li> <p>China (Ningxia)</p> </li> </ul> <p>The China (Beijing) and China (Ningxia) Regions support up to 10 items per transaction with up to 4 MB of data. </p> </note> <p>The actions are completed atomically so that either all of them succeed, or all of them fail. They are defined by the following objects:</p> <ul> <li> <p> <code>Put</code>  &#x97;   Initiates a <code>PutItem</code> operation to write a new item. This structure specifies the primary key of the item to be written, the name of the table to write it in, an optional condition expression that must be satisfied for the write to succeed, a list of the item's attributes, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> <li> <p> <code>Update</code>  &#x97;   Initiates an <code>UpdateItem</code> operation to update an existing item. This structure specifies the primary key of the item to be updated, the name of the table where it resides, an optional condition expression that must be satisfied for the update to succeed, an expression that defines one or more attributes to be updated, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> <li> <p> <code>Delete</code>  &#x97;   Initiates a <code>DeleteItem</code> operation to delete an existing item. This structure specifies the primary key of the item to be deleted, the name of the table where it resides, an optional condition expression that must be satisfied for the deletion to succeed, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> <li> <p> <code>ConditionCheck</code>  &#x97;   Applies a condition to an item that is not being modified by the transaction. This structure specifies the primary key of the item to be checked, the name of the table where it resides, a condition expression that must be satisfied for the transaction to succeed, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> </ul> <p>DynamoDB rejects the entire <code>TransactWriteItems</code> request if any of the following is true:</p> <ul> <li> <p>A condition in one of the condition expressions is not met.</p> </li> <li> <p>An ongoing operation is in the process of updating the same item.</p> </li> <li> <p>There is insufficient provisioned capacity for the transaction to be completed.</p> </li> <li> <p>An item size becomes too large (bigger than 400 KB), a local secondary index (LSI) becomes too large, or a similar validation error occurs because of changes made by the transaction.</p> </li> <li> <p>The aggregate size of the items in the transaction exceeds 4 MB.</p> </li> <li> <p>There is a user error, such as an invalid data format.</p> </li> </ul>
  ## 
  let valid = call_593401.validator(path, query, header, formData, body)
  let scheme = call_593401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593401.url(scheme.get, call_593401.host, call_593401.base,
                         call_593401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593401, url, valid)

proc call*(call_593402: Call_TransactWriteItems_593389; body: JsonNode): Recallable =
  ## transactWriteItems
  ## <p> <code>TransactWriteItems</code> is a synchronous write operation that groups up to 25 action requests. These actions can target items in different tables, but not in different AWS accounts or Regions, and no two actions can target the same item. For example, you cannot both <code>ConditionCheck</code> and <code>Update</code> the same item. The aggregate size of the items in the transaction cannot exceed 4 MB.</p> <note> <p>All AWS Regions and AWS GovCloud (US) support up to 25 items per transaction with up to 4 MB of data, except the following AWS Regions: </p> <ul> <li> <p>China (Beijing)</p> </li> <li> <p>China (Ningxia)</p> </li> </ul> <p>The China (Beijing) and China (Ningxia) Regions support up to 10 items per transaction with up to 4 MB of data. </p> </note> <p>The actions are completed atomically so that either all of them succeed, or all of them fail. They are defined by the following objects:</p> <ul> <li> <p> <code>Put</code>  &#x97;   Initiates a <code>PutItem</code> operation to write a new item. This structure specifies the primary key of the item to be written, the name of the table to write it in, an optional condition expression that must be satisfied for the write to succeed, a list of the item's attributes, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> <li> <p> <code>Update</code>  &#x97;   Initiates an <code>UpdateItem</code> operation to update an existing item. This structure specifies the primary key of the item to be updated, the name of the table where it resides, an optional condition expression that must be satisfied for the update to succeed, an expression that defines one or more attributes to be updated, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> <li> <p> <code>Delete</code>  &#x97;   Initiates a <code>DeleteItem</code> operation to delete an existing item. This structure specifies the primary key of the item to be deleted, the name of the table where it resides, an optional condition expression that must be satisfied for the deletion to succeed, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> <li> <p> <code>ConditionCheck</code>  &#x97;   Applies a condition to an item that is not being modified by the transaction. This structure specifies the primary key of the item to be checked, the name of the table where it resides, a condition expression that must be satisfied for the transaction to succeed, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> </ul> <p>DynamoDB rejects the entire <code>TransactWriteItems</code> request if any of the following is true:</p> <ul> <li> <p>A condition in one of the condition expressions is not met.</p> </li> <li> <p>An ongoing operation is in the process of updating the same item.</p> </li> <li> <p>There is insufficient provisioned capacity for the transaction to be completed.</p> </li> <li> <p>An item size becomes too large (bigger than 400 KB), a local secondary index (LSI) becomes too large, or a similar validation error occurs because of changes made by the transaction.</p> </li> <li> <p>The aggregate size of the items in the transaction exceeds 4 MB.</p> </li> <li> <p>There is a user error, such as an invalid data format.</p> </li> </ul>
  ##   body: JObject (required)
  var body_593403 = newJObject()
  if body != nil:
    body_593403 = body
  result = call_593402.call(nil, nil, nil, nil, body_593403)

var transactWriteItems* = Call_TransactWriteItems_593389(
    name: "transactWriteItems", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.TransactWriteItems",
    validator: validate_TransactWriteItems_593390, base: "/",
    url: url_TransactWriteItems_593391, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_593404 = ref object of OpenApiRestCall_592364
proc url_UntagResource_593406(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_593405(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_593407 = header.getOrDefault("X-Amz-Target")
  valid_593407 = validateParameter(valid_593407, JString, required = true, default = newJString(
      "DynamoDB_20120810.UntagResource"))
  if valid_593407 != nil:
    section.add "X-Amz-Target", valid_593407
  var valid_593408 = header.getOrDefault("X-Amz-Signature")
  valid_593408 = validateParameter(valid_593408, JString, required = false,
                                 default = nil)
  if valid_593408 != nil:
    section.add "X-Amz-Signature", valid_593408
  var valid_593409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593409 = validateParameter(valid_593409, JString, required = false,
                                 default = nil)
  if valid_593409 != nil:
    section.add "X-Amz-Content-Sha256", valid_593409
  var valid_593410 = header.getOrDefault("X-Amz-Date")
  valid_593410 = validateParameter(valid_593410, JString, required = false,
                                 default = nil)
  if valid_593410 != nil:
    section.add "X-Amz-Date", valid_593410
  var valid_593411 = header.getOrDefault("X-Amz-Credential")
  valid_593411 = validateParameter(valid_593411, JString, required = false,
                                 default = nil)
  if valid_593411 != nil:
    section.add "X-Amz-Credential", valid_593411
  var valid_593412 = header.getOrDefault("X-Amz-Security-Token")
  valid_593412 = validateParameter(valid_593412, JString, required = false,
                                 default = nil)
  if valid_593412 != nil:
    section.add "X-Amz-Security-Token", valid_593412
  var valid_593413 = header.getOrDefault("X-Amz-Algorithm")
  valid_593413 = validateParameter(valid_593413, JString, required = false,
                                 default = nil)
  if valid_593413 != nil:
    section.add "X-Amz-Algorithm", valid_593413
  var valid_593414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593414 = validateParameter(valid_593414, JString, required = false,
                                 default = nil)
  if valid_593414 != nil:
    section.add "X-Amz-SignedHeaders", valid_593414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593416: Call_UntagResource_593404; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the association of tags from an Amazon DynamoDB resource. You can call <code>UntagResource</code> up to five times per second, per account. </p> <p>For an overview on tagging DynamoDB resources, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html">Tagging for DynamoDB</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
  ## 
  let valid = call_593416.validator(path, query, header, formData, body)
  let scheme = call_593416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593416.url(scheme.get, call_593416.host, call_593416.base,
                         call_593416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593416, url, valid)

proc call*(call_593417: Call_UntagResource_593404; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Removes the association of tags from an Amazon DynamoDB resource. You can call <code>UntagResource</code> up to five times per second, per account. </p> <p>For an overview on tagging DynamoDB resources, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html">Tagging for DynamoDB</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_593418 = newJObject()
  if body != nil:
    body_593418 = body
  result = call_593417.call(nil, nil, nil, nil, body_593418)

var untagResource* = Call_UntagResource_593404(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.UntagResource",
    validator: validate_UntagResource_593405, base: "/", url: url_UntagResource_593406,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContinuousBackups_593419 = ref object of OpenApiRestCall_592364
proc url_UpdateContinuousBackups_593421(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateContinuousBackups_593420(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_593422 = header.getOrDefault("X-Amz-Target")
  valid_593422 = validateParameter(valid_593422, JString, required = true, default = newJString(
      "DynamoDB_20120810.UpdateContinuousBackups"))
  if valid_593422 != nil:
    section.add "X-Amz-Target", valid_593422
  var valid_593423 = header.getOrDefault("X-Amz-Signature")
  valid_593423 = validateParameter(valid_593423, JString, required = false,
                                 default = nil)
  if valid_593423 != nil:
    section.add "X-Amz-Signature", valid_593423
  var valid_593424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593424 = validateParameter(valid_593424, JString, required = false,
                                 default = nil)
  if valid_593424 != nil:
    section.add "X-Amz-Content-Sha256", valid_593424
  var valid_593425 = header.getOrDefault("X-Amz-Date")
  valid_593425 = validateParameter(valid_593425, JString, required = false,
                                 default = nil)
  if valid_593425 != nil:
    section.add "X-Amz-Date", valid_593425
  var valid_593426 = header.getOrDefault("X-Amz-Credential")
  valid_593426 = validateParameter(valid_593426, JString, required = false,
                                 default = nil)
  if valid_593426 != nil:
    section.add "X-Amz-Credential", valid_593426
  var valid_593427 = header.getOrDefault("X-Amz-Security-Token")
  valid_593427 = validateParameter(valid_593427, JString, required = false,
                                 default = nil)
  if valid_593427 != nil:
    section.add "X-Amz-Security-Token", valid_593427
  var valid_593428 = header.getOrDefault("X-Amz-Algorithm")
  valid_593428 = validateParameter(valid_593428, JString, required = false,
                                 default = nil)
  if valid_593428 != nil:
    section.add "X-Amz-Algorithm", valid_593428
  var valid_593429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593429 = validateParameter(valid_593429, JString, required = false,
                                 default = nil)
  if valid_593429 != nil:
    section.add "X-Amz-SignedHeaders", valid_593429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593431: Call_UpdateContinuousBackups_593419; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>UpdateContinuousBackups</code> enables or disables point in time recovery for the specified table. A successful <code>UpdateContinuousBackups</code> call returns the current <code>ContinuousBackupsDescription</code>. Continuous backups are <code>ENABLED</code> on all tables at table creation. If point in time recovery is enabled, <code>PointInTimeRecoveryStatus</code> will be set to ENABLED.</p> <p> Once continuous backups and point in time recovery are enabled, you can restore to any point in time within <code>EarliestRestorableDateTime</code> and <code>LatestRestorableDateTime</code>. </p> <p> <code>LatestRestorableDateTime</code> is typically 5 minutes before the current time. You can restore your table to any point in time during the last 35 days. </p>
  ## 
  let valid = call_593431.validator(path, query, header, formData, body)
  let scheme = call_593431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593431.url(scheme.get, call_593431.host, call_593431.base,
                         call_593431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593431, url, valid)

proc call*(call_593432: Call_UpdateContinuousBackups_593419; body: JsonNode): Recallable =
  ## updateContinuousBackups
  ## <p> <code>UpdateContinuousBackups</code> enables or disables point in time recovery for the specified table. A successful <code>UpdateContinuousBackups</code> call returns the current <code>ContinuousBackupsDescription</code>. Continuous backups are <code>ENABLED</code> on all tables at table creation. If point in time recovery is enabled, <code>PointInTimeRecoveryStatus</code> will be set to ENABLED.</p> <p> Once continuous backups and point in time recovery are enabled, you can restore to any point in time within <code>EarliestRestorableDateTime</code> and <code>LatestRestorableDateTime</code>. </p> <p> <code>LatestRestorableDateTime</code> is typically 5 minutes before the current time. You can restore your table to any point in time during the last 35 days. </p>
  ##   body: JObject (required)
  var body_593433 = newJObject()
  if body != nil:
    body_593433 = body
  result = call_593432.call(nil, nil, nil, nil, body_593433)

var updateContinuousBackups* = Call_UpdateContinuousBackups_593419(
    name: "updateContinuousBackups", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.UpdateContinuousBackups",
    validator: validate_UpdateContinuousBackups_593420, base: "/",
    url: url_UpdateContinuousBackups_593421, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGlobalTable_593434 = ref object of OpenApiRestCall_592364
proc url_UpdateGlobalTable_593436(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateGlobalTable_593435(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_593437 = header.getOrDefault("X-Amz-Target")
  valid_593437 = validateParameter(valid_593437, JString, required = true, default = newJString(
      "DynamoDB_20120810.UpdateGlobalTable"))
  if valid_593437 != nil:
    section.add "X-Amz-Target", valid_593437
  var valid_593438 = header.getOrDefault("X-Amz-Signature")
  valid_593438 = validateParameter(valid_593438, JString, required = false,
                                 default = nil)
  if valid_593438 != nil:
    section.add "X-Amz-Signature", valid_593438
  var valid_593439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593439 = validateParameter(valid_593439, JString, required = false,
                                 default = nil)
  if valid_593439 != nil:
    section.add "X-Amz-Content-Sha256", valid_593439
  var valid_593440 = header.getOrDefault("X-Amz-Date")
  valid_593440 = validateParameter(valid_593440, JString, required = false,
                                 default = nil)
  if valid_593440 != nil:
    section.add "X-Amz-Date", valid_593440
  var valid_593441 = header.getOrDefault("X-Amz-Credential")
  valid_593441 = validateParameter(valid_593441, JString, required = false,
                                 default = nil)
  if valid_593441 != nil:
    section.add "X-Amz-Credential", valid_593441
  var valid_593442 = header.getOrDefault("X-Amz-Security-Token")
  valid_593442 = validateParameter(valid_593442, JString, required = false,
                                 default = nil)
  if valid_593442 != nil:
    section.add "X-Amz-Security-Token", valid_593442
  var valid_593443 = header.getOrDefault("X-Amz-Algorithm")
  valid_593443 = validateParameter(valid_593443, JString, required = false,
                                 default = nil)
  if valid_593443 != nil:
    section.add "X-Amz-Algorithm", valid_593443
  var valid_593444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593444 = validateParameter(valid_593444, JString, required = false,
                                 default = nil)
  if valid_593444 != nil:
    section.add "X-Amz-SignedHeaders", valid_593444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593446: Call_UpdateGlobalTable_593434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or removes replicas in the specified global table. The global table must already exist to be able to use this operation. Any replica to be added must be empty, have the same name as the global table, have the same key schema, have DynamoDB Streams enabled, and have the same provisioned and maximum write capacity units.</p> <note> <p>Although you can use <code>UpdateGlobalTable</code> to add replicas and remove replicas in a single request, for simplicity we recommend that you issue separate requests for adding or removing replicas.</p> </note> <p> If global secondary indexes are specified, then the following conditions must also be met: </p> <ul> <li> <p> The global secondary indexes must have the same name. </p> </li> <li> <p> The global secondary indexes must have the same hash key and sort key (if present). </p> </li> <li> <p> The global secondary indexes must have the same provisioned and maximum write capacity units. </p> </li> </ul>
  ## 
  let valid = call_593446.validator(path, query, header, formData, body)
  let scheme = call_593446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593446.url(scheme.get, call_593446.host, call_593446.base,
                         call_593446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593446, url, valid)

proc call*(call_593447: Call_UpdateGlobalTable_593434; body: JsonNode): Recallable =
  ## updateGlobalTable
  ## <p>Adds or removes replicas in the specified global table. The global table must already exist to be able to use this operation. Any replica to be added must be empty, have the same name as the global table, have the same key schema, have DynamoDB Streams enabled, and have the same provisioned and maximum write capacity units.</p> <note> <p>Although you can use <code>UpdateGlobalTable</code> to add replicas and remove replicas in a single request, for simplicity we recommend that you issue separate requests for adding or removing replicas.</p> </note> <p> If global secondary indexes are specified, then the following conditions must also be met: </p> <ul> <li> <p> The global secondary indexes must have the same name. </p> </li> <li> <p> The global secondary indexes must have the same hash key and sort key (if present). </p> </li> <li> <p> The global secondary indexes must have the same provisioned and maximum write capacity units. </p> </li> </ul>
  ##   body: JObject (required)
  var body_593448 = newJObject()
  if body != nil:
    body_593448 = body
  result = call_593447.call(nil, nil, nil, nil, body_593448)

var updateGlobalTable* = Call_UpdateGlobalTable_593434(name: "updateGlobalTable",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.UpdateGlobalTable",
    validator: validate_UpdateGlobalTable_593435, base: "/",
    url: url_UpdateGlobalTable_593436, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGlobalTableSettings_593449 = ref object of OpenApiRestCall_592364
proc url_UpdateGlobalTableSettings_593451(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateGlobalTableSettings_593450(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_593452 = header.getOrDefault("X-Amz-Target")
  valid_593452 = validateParameter(valid_593452, JString, required = true, default = newJString(
      "DynamoDB_20120810.UpdateGlobalTableSettings"))
  if valid_593452 != nil:
    section.add "X-Amz-Target", valid_593452
  var valid_593453 = header.getOrDefault("X-Amz-Signature")
  valid_593453 = validateParameter(valid_593453, JString, required = false,
                                 default = nil)
  if valid_593453 != nil:
    section.add "X-Amz-Signature", valid_593453
  var valid_593454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593454 = validateParameter(valid_593454, JString, required = false,
                                 default = nil)
  if valid_593454 != nil:
    section.add "X-Amz-Content-Sha256", valid_593454
  var valid_593455 = header.getOrDefault("X-Amz-Date")
  valid_593455 = validateParameter(valid_593455, JString, required = false,
                                 default = nil)
  if valid_593455 != nil:
    section.add "X-Amz-Date", valid_593455
  var valid_593456 = header.getOrDefault("X-Amz-Credential")
  valid_593456 = validateParameter(valid_593456, JString, required = false,
                                 default = nil)
  if valid_593456 != nil:
    section.add "X-Amz-Credential", valid_593456
  var valid_593457 = header.getOrDefault("X-Amz-Security-Token")
  valid_593457 = validateParameter(valid_593457, JString, required = false,
                                 default = nil)
  if valid_593457 != nil:
    section.add "X-Amz-Security-Token", valid_593457
  var valid_593458 = header.getOrDefault("X-Amz-Algorithm")
  valid_593458 = validateParameter(valid_593458, JString, required = false,
                                 default = nil)
  if valid_593458 != nil:
    section.add "X-Amz-Algorithm", valid_593458
  var valid_593459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593459 = validateParameter(valid_593459, JString, required = false,
                                 default = nil)
  if valid_593459 != nil:
    section.add "X-Amz-SignedHeaders", valid_593459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593461: Call_UpdateGlobalTableSettings_593449; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates settings for a global table.
  ## 
  let valid = call_593461.validator(path, query, header, formData, body)
  let scheme = call_593461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593461.url(scheme.get, call_593461.host, call_593461.base,
                         call_593461.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593461, url, valid)

proc call*(call_593462: Call_UpdateGlobalTableSettings_593449; body: JsonNode): Recallable =
  ## updateGlobalTableSettings
  ## Updates settings for a global table.
  ##   body: JObject (required)
  var body_593463 = newJObject()
  if body != nil:
    body_593463 = body
  result = call_593462.call(nil, nil, nil, nil, body_593463)

var updateGlobalTableSettings* = Call_UpdateGlobalTableSettings_593449(
    name: "updateGlobalTableSettings", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.UpdateGlobalTableSettings",
    validator: validate_UpdateGlobalTableSettings_593450, base: "/",
    url: url_UpdateGlobalTableSettings_593451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateItem_593464 = ref object of OpenApiRestCall_592364
proc url_UpdateItem_593466(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateItem_593465(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_593467 = header.getOrDefault("X-Amz-Target")
  valid_593467 = validateParameter(valid_593467, JString, required = true, default = newJString(
      "DynamoDB_20120810.UpdateItem"))
  if valid_593467 != nil:
    section.add "X-Amz-Target", valid_593467
  var valid_593468 = header.getOrDefault("X-Amz-Signature")
  valid_593468 = validateParameter(valid_593468, JString, required = false,
                                 default = nil)
  if valid_593468 != nil:
    section.add "X-Amz-Signature", valid_593468
  var valid_593469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593469 = validateParameter(valid_593469, JString, required = false,
                                 default = nil)
  if valid_593469 != nil:
    section.add "X-Amz-Content-Sha256", valid_593469
  var valid_593470 = header.getOrDefault("X-Amz-Date")
  valid_593470 = validateParameter(valid_593470, JString, required = false,
                                 default = nil)
  if valid_593470 != nil:
    section.add "X-Amz-Date", valid_593470
  var valid_593471 = header.getOrDefault("X-Amz-Credential")
  valid_593471 = validateParameter(valid_593471, JString, required = false,
                                 default = nil)
  if valid_593471 != nil:
    section.add "X-Amz-Credential", valid_593471
  var valid_593472 = header.getOrDefault("X-Amz-Security-Token")
  valid_593472 = validateParameter(valid_593472, JString, required = false,
                                 default = nil)
  if valid_593472 != nil:
    section.add "X-Amz-Security-Token", valid_593472
  var valid_593473 = header.getOrDefault("X-Amz-Algorithm")
  valid_593473 = validateParameter(valid_593473, JString, required = false,
                                 default = nil)
  if valid_593473 != nil:
    section.add "X-Amz-Algorithm", valid_593473
  var valid_593474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593474 = validateParameter(valid_593474, JString, required = false,
                                 default = nil)
  if valid_593474 != nil:
    section.add "X-Amz-SignedHeaders", valid_593474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593476: Call_UpdateItem_593464; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Edits an existing item's attributes, or adds a new item to the table if it does not already exist. You can put, delete, or add attribute values. You can also perform a conditional update on an existing item (insert a new attribute name-value pair if it doesn't exist, or replace an existing name-value pair if it has certain expected attribute values).</p> <p>You can also return the item's attribute values in the same <code>UpdateItem</code> operation using the <code>ReturnValues</code> parameter.</p>
  ## 
  let valid = call_593476.validator(path, query, header, formData, body)
  let scheme = call_593476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593476.url(scheme.get, call_593476.host, call_593476.base,
                         call_593476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593476, url, valid)

proc call*(call_593477: Call_UpdateItem_593464; body: JsonNode): Recallable =
  ## updateItem
  ## <p>Edits an existing item's attributes, or adds a new item to the table if it does not already exist. You can put, delete, or add attribute values. You can also perform a conditional update on an existing item (insert a new attribute name-value pair if it doesn't exist, or replace an existing name-value pair if it has certain expected attribute values).</p> <p>You can also return the item's attribute values in the same <code>UpdateItem</code> operation using the <code>ReturnValues</code> parameter.</p>
  ##   body: JObject (required)
  var body_593478 = newJObject()
  if body != nil:
    body_593478 = body
  result = call_593477.call(nil, nil, nil, nil, body_593478)

var updateItem* = Call_UpdateItem_593464(name: "updateItem",
                                      meth: HttpMethod.HttpPost,
                                      host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20120810.UpdateItem",
                                      validator: validate_UpdateItem_593465,
                                      base: "/", url: url_UpdateItem_593466,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTable_593479 = ref object of OpenApiRestCall_592364
proc url_UpdateTable_593481(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateTable_593480(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_593482 = header.getOrDefault("X-Amz-Target")
  valid_593482 = validateParameter(valid_593482, JString, required = true, default = newJString(
      "DynamoDB_20120810.UpdateTable"))
  if valid_593482 != nil:
    section.add "X-Amz-Target", valid_593482
  var valid_593483 = header.getOrDefault("X-Amz-Signature")
  valid_593483 = validateParameter(valid_593483, JString, required = false,
                                 default = nil)
  if valid_593483 != nil:
    section.add "X-Amz-Signature", valid_593483
  var valid_593484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593484 = validateParameter(valid_593484, JString, required = false,
                                 default = nil)
  if valid_593484 != nil:
    section.add "X-Amz-Content-Sha256", valid_593484
  var valid_593485 = header.getOrDefault("X-Amz-Date")
  valid_593485 = validateParameter(valid_593485, JString, required = false,
                                 default = nil)
  if valid_593485 != nil:
    section.add "X-Amz-Date", valid_593485
  var valid_593486 = header.getOrDefault("X-Amz-Credential")
  valid_593486 = validateParameter(valid_593486, JString, required = false,
                                 default = nil)
  if valid_593486 != nil:
    section.add "X-Amz-Credential", valid_593486
  var valid_593487 = header.getOrDefault("X-Amz-Security-Token")
  valid_593487 = validateParameter(valid_593487, JString, required = false,
                                 default = nil)
  if valid_593487 != nil:
    section.add "X-Amz-Security-Token", valid_593487
  var valid_593488 = header.getOrDefault("X-Amz-Algorithm")
  valid_593488 = validateParameter(valid_593488, JString, required = false,
                                 default = nil)
  if valid_593488 != nil:
    section.add "X-Amz-Algorithm", valid_593488
  var valid_593489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593489 = validateParameter(valid_593489, JString, required = false,
                                 default = nil)
  if valid_593489 != nil:
    section.add "X-Amz-SignedHeaders", valid_593489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593491: Call_UpdateTable_593479; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the provisioned throughput settings, global secondary indexes, or DynamoDB Streams settings for a given table.</p> <p>You can only perform one of the following operations at once:</p> <ul> <li> <p>Modify the provisioned throughput settings of the table.</p> </li> <li> <p>Enable or disable DynamoDB Streams on the table.</p> </li> <li> <p>Remove a global secondary index from the table.</p> </li> <li> <p>Create a new global secondary index on the table. After the index begins backfilling, you can use <code>UpdateTable</code> to perform other operations.</p> </li> </ul> <p> <code>UpdateTable</code> is an asynchronous operation; while it is executing, the table status changes from <code>ACTIVE</code> to <code>UPDATING</code>. While it is <code>UPDATING</code>, you cannot issue another <code>UpdateTable</code> request. When the table returns to the <code>ACTIVE</code> state, the <code>UpdateTable</code> operation is complete.</p>
  ## 
  let valid = call_593491.validator(path, query, header, formData, body)
  let scheme = call_593491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593491.url(scheme.get, call_593491.host, call_593491.base,
                         call_593491.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593491, url, valid)

proc call*(call_593492: Call_UpdateTable_593479; body: JsonNode): Recallable =
  ## updateTable
  ## <p>Modifies the provisioned throughput settings, global secondary indexes, or DynamoDB Streams settings for a given table.</p> <p>You can only perform one of the following operations at once:</p> <ul> <li> <p>Modify the provisioned throughput settings of the table.</p> </li> <li> <p>Enable or disable DynamoDB Streams on the table.</p> </li> <li> <p>Remove a global secondary index from the table.</p> </li> <li> <p>Create a new global secondary index on the table. After the index begins backfilling, you can use <code>UpdateTable</code> to perform other operations.</p> </li> </ul> <p> <code>UpdateTable</code> is an asynchronous operation; while it is executing, the table status changes from <code>ACTIVE</code> to <code>UPDATING</code>. While it is <code>UPDATING</code>, you cannot issue another <code>UpdateTable</code> request. When the table returns to the <code>ACTIVE</code> state, the <code>UpdateTable</code> operation is complete.</p>
  ##   body: JObject (required)
  var body_593493 = newJObject()
  if body != nil:
    body_593493 = body
  result = call_593492.call(nil, nil, nil, nil, body_593493)

var updateTable* = Call_UpdateTable_593479(name: "updateTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20120810.UpdateTable",
                                        validator: validate_UpdateTable_593480,
                                        base: "/", url: url_UpdateTable_593481,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTimeToLive_593494 = ref object of OpenApiRestCall_592364
proc url_UpdateTimeToLive_593496(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateTimeToLive_593495(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_593497 = header.getOrDefault("X-Amz-Target")
  valid_593497 = validateParameter(valid_593497, JString, required = true, default = newJString(
      "DynamoDB_20120810.UpdateTimeToLive"))
  if valid_593497 != nil:
    section.add "X-Amz-Target", valid_593497
  var valid_593498 = header.getOrDefault("X-Amz-Signature")
  valid_593498 = validateParameter(valid_593498, JString, required = false,
                                 default = nil)
  if valid_593498 != nil:
    section.add "X-Amz-Signature", valid_593498
  var valid_593499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593499 = validateParameter(valid_593499, JString, required = false,
                                 default = nil)
  if valid_593499 != nil:
    section.add "X-Amz-Content-Sha256", valid_593499
  var valid_593500 = header.getOrDefault("X-Amz-Date")
  valid_593500 = validateParameter(valid_593500, JString, required = false,
                                 default = nil)
  if valid_593500 != nil:
    section.add "X-Amz-Date", valid_593500
  var valid_593501 = header.getOrDefault("X-Amz-Credential")
  valid_593501 = validateParameter(valid_593501, JString, required = false,
                                 default = nil)
  if valid_593501 != nil:
    section.add "X-Amz-Credential", valid_593501
  var valid_593502 = header.getOrDefault("X-Amz-Security-Token")
  valid_593502 = validateParameter(valid_593502, JString, required = false,
                                 default = nil)
  if valid_593502 != nil:
    section.add "X-Amz-Security-Token", valid_593502
  var valid_593503 = header.getOrDefault("X-Amz-Algorithm")
  valid_593503 = validateParameter(valid_593503, JString, required = false,
                                 default = nil)
  if valid_593503 != nil:
    section.add "X-Amz-Algorithm", valid_593503
  var valid_593504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593504 = validateParameter(valid_593504, JString, required = false,
                                 default = nil)
  if valid_593504 != nil:
    section.add "X-Amz-SignedHeaders", valid_593504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593506: Call_UpdateTimeToLive_593494; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>UpdateTimeToLive</code> method enables or disables Time to Live (TTL) for the specified table. A successful <code>UpdateTimeToLive</code> call returns the current <code>TimeToLiveSpecification</code>. It can take up to one hour for the change to fully process. Any additional <code>UpdateTimeToLive</code> calls for the same table during this one hour duration result in a <code>ValidationException</code>. </p> <p>TTL compares the current time in epoch time format to the time stored in the TTL attribute of an item. If the epoch time value stored in the attribute is less than the current time, the item is marked as expired and subsequently deleted.</p> <note> <p> The epoch time format is the number of seconds elapsed since 12:00:00 AM January 1, 1970 UTC. </p> </note> <p>DynamoDB deletes expired items on a best-effort basis to ensure availability of throughput for other data operations. </p> <important> <p>DynamoDB typically deletes expired items within two days of expiration. The exact duration within which an item gets deleted after expiration is specific to the nature of the workload. Items that have expired and not been deleted will still show up in reads, queries, and scans.</p> </important> <p>As items are deleted, they are removed from any local secondary index and global secondary index immediately in the same eventually consistent way as a standard delete operation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/TTL.html">Time To Live</a> in the Amazon DynamoDB Developer Guide. </p>
  ## 
  let valid = call_593506.validator(path, query, header, formData, body)
  let scheme = call_593506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593506.url(scheme.get, call_593506.host, call_593506.base,
                         call_593506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593506, url, valid)

proc call*(call_593507: Call_UpdateTimeToLive_593494; body: JsonNode): Recallable =
  ## updateTimeToLive
  ## <p>The <code>UpdateTimeToLive</code> method enables or disables Time to Live (TTL) for the specified table. A successful <code>UpdateTimeToLive</code> call returns the current <code>TimeToLiveSpecification</code>. It can take up to one hour for the change to fully process. Any additional <code>UpdateTimeToLive</code> calls for the same table during this one hour duration result in a <code>ValidationException</code>. </p> <p>TTL compares the current time in epoch time format to the time stored in the TTL attribute of an item. If the epoch time value stored in the attribute is less than the current time, the item is marked as expired and subsequently deleted.</p> <note> <p> The epoch time format is the number of seconds elapsed since 12:00:00 AM January 1, 1970 UTC. </p> </note> <p>DynamoDB deletes expired items on a best-effort basis to ensure availability of throughput for other data operations. </p> <important> <p>DynamoDB typically deletes expired items within two days of expiration. The exact duration within which an item gets deleted after expiration is specific to the nature of the workload. Items that have expired and not been deleted will still show up in reads, queries, and scans.</p> </important> <p>As items are deleted, they are removed from any local secondary index and global secondary index immediately in the same eventually consistent way as a standard delete operation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/TTL.html">Time To Live</a> in the Amazon DynamoDB Developer Guide. </p>
  ##   body: JObject (required)
  var body_593508 = newJObject()
  if body != nil:
    body_593508 = body
  result = call_593507.call(nil, nil, nil, nil, body_593508)

var updateTimeToLive* = Call_UpdateTimeToLive_593494(name: "updateTimeToLive",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.UpdateTimeToLive",
    validator: validate_UpdateTimeToLive_593495, base: "/",
    url: url_UpdateTimeToLive_593496, schemes: {Scheme.Https, Scheme.Http})
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
