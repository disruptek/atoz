
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
  Call_BatchGetItem_772933 = ref object of OpenApiRestCall_772597
proc url_BatchGetItem_772935(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchGetItem_772934(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773047 = query.getOrDefault("RequestItems")
  valid_773047 = validateParameter(valid_773047, JString, required = false,
                                 default = nil)
  if valid_773047 != nil:
    section.add "RequestItems", valid_773047
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
  var valid_773048 = header.getOrDefault("X-Amz-Date")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "X-Amz-Date", valid_773048
  var valid_773049 = header.getOrDefault("X-Amz-Security-Token")
  valid_773049 = validateParameter(valid_773049, JString, required = false,
                                 default = nil)
  if valid_773049 != nil:
    section.add "X-Amz-Security-Token", valid_773049
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773063 = header.getOrDefault("X-Amz-Target")
  valid_773063 = validateParameter(valid_773063, JString, required = true, default = newJString(
      "DynamoDB_20120810.BatchGetItem"))
  if valid_773063 != nil:
    section.add "X-Amz-Target", valid_773063
  var valid_773064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773064 = validateParameter(valid_773064, JString, required = false,
                                 default = nil)
  if valid_773064 != nil:
    section.add "X-Amz-Content-Sha256", valid_773064
  var valid_773065 = header.getOrDefault("X-Amz-Algorithm")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "X-Amz-Algorithm", valid_773065
  var valid_773066 = header.getOrDefault("X-Amz-Signature")
  valid_773066 = validateParameter(valid_773066, JString, required = false,
                                 default = nil)
  if valid_773066 != nil:
    section.add "X-Amz-Signature", valid_773066
  var valid_773067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "X-Amz-SignedHeaders", valid_773067
  var valid_773068 = header.getOrDefault("X-Amz-Credential")
  valid_773068 = validateParameter(valid_773068, JString, required = false,
                                 default = nil)
  if valid_773068 != nil:
    section.add "X-Amz-Credential", valid_773068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773092: Call_BatchGetItem_772933; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>BatchGetItem</code> operation returns the attributes of one or more items from one or more tables. You identify requested items by primary key.</p> <p>A single operation can retrieve up to 16 MB of data, which can contain as many as 100 items. <code>BatchGetItem</code> returns a partial result if the response size limit is exceeded, the table's provisioned throughput is exceeded, or an internal processing failure occurs. If a partial result is returned, the operation returns a value for <code>UnprocessedKeys</code>. You can use this value to retry the operation starting with the next item to get.</p> <important> <p>If you request more than 100 items, <code>BatchGetItem</code> returns a <code>ValidationException</code> with the message "Too many items requested for the BatchGetItem call."</p> </important> <p>For example, if you ask to retrieve 100 items, but each individual item is 300 KB in size, the system returns 52 items (so as not to exceed the 16 MB limit). It also returns an appropriate <code>UnprocessedKeys</code> value so you can get the next page of results. If desired, your application can include its own logic to assemble the pages of results into one dataset.</p> <p>If <i>none</i> of the items can be processed due to insufficient provisioned throughput on all of the tables in the request, then <code>BatchGetItem</code> returns a <code>ProvisionedThroughputExceededException</code>. If <i>at least one</i> of the items is successfully processed, then <code>BatchGetItem</code> completes successfully, while returning the keys of the unread items in <code>UnprocessedKeys</code>.</p> <important> <p>If DynamoDB returns any unprocessed items, you should retry the batch operation on those items. However, <i>we strongly recommend that you use an exponential backoff algorithm</i>. If you retry the batch operation immediately, the underlying read or write requests can still fail due to throttling on the individual tables. If you delay the batch operation using exponential backoff, the individual requests in the batch are much more likely to succeed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ErrorHandling.html#BatchOperations">Batch Operations and Error Handling</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p> </important> <p>By default, <code>BatchGetItem</code> performs eventually consistent reads on every table in the request. If you want strongly consistent reads instead, you can set <code>ConsistentRead</code> to <code>true</code> for any or all tables.</p> <p>In order to minimize response latency, <code>BatchGetItem</code> retrieves items in parallel.</p> <p>When designing your application, keep in mind that DynamoDB does not return items in any particular order. To help parse the response by item, include the primary key values for the items in your request in the <code>ProjectionExpression</code> parameter.</p> <p>If a requested item does not exist, it is not returned in the result. Requests for nonexistent items consume the minimum read capacity units according to the type of read. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/WorkingWithTables.html#CapacityUnitCalculations">Working with Tables</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
  ## 
  let valid = call_773092.validator(path, query, header, formData, body)
  let scheme = call_773092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773092.url(scheme.get, call_773092.host, call_773092.base,
                         call_773092.route, valid.getOrDefault("path"))
  result = hook(call_773092, url, valid)

proc call*(call_773163: Call_BatchGetItem_772933; body: JsonNode;
          RequestItems: string = ""): Recallable =
  ## batchGetItem
  ## <p>The <code>BatchGetItem</code> operation returns the attributes of one or more items from one or more tables. You identify requested items by primary key.</p> <p>A single operation can retrieve up to 16 MB of data, which can contain as many as 100 items. <code>BatchGetItem</code> returns a partial result if the response size limit is exceeded, the table's provisioned throughput is exceeded, or an internal processing failure occurs. If a partial result is returned, the operation returns a value for <code>UnprocessedKeys</code>. You can use this value to retry the operation starting with the next item to get.</p> <important> <p>If you request more than 100 items, <code>BatchGetItem</code> returns a <code>ValidationException</code> with the message "Too many items requested for the BatchGetItem call."</p> </important> <p>For example, if you ask to retrieve 100 items, but each individual item is 300 KB in size, the system returns 52 items (so as not to exceed the 16 MB limit). It also returns an appropriate <code>UnprocessedKeys</code> value so you can get the next page of results. If desired, your application can include its own logic to assemble the pages of results into one dataset.</p> <p>If <i>none</i> of the items can be processed due to insufficient provisioned throughput on all of the tables in the request, then <code>BatchGetItem</code> returns a <code>ProvisionedThroughputExceededException</code>. If <i>at least one</i> of the items is successfully processed, then <code>BatchGetItem</code> completes successfully, while returning the keys of the unread items in <code>UnprocessedKeys</code>.</p> <important> <p>If DynamoDB returns any unprocessed items, you should retry the batch operation on those items. However, <i>we strongly recommend that you use an exponential backoff algorithm</i>. If you retry the batch operation immediately, the underlying read or write requests can still fail due to throttling on the individual tables. If you delay the batch operation using exponential backoff, the individual requests in the batch are much more likely to succeed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ErrorHandling.html#BatchOperations">Batch Operations and Error Handling</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p> </important> <p>By default, <code>BatchGetItem</code> performs eventually consistent reads on every table in the request. If you want strongly consistent reads instead, you can set <code>ConsistentRead</code> to <code>true</code> for any or all tables.</p> <p>In order to minimize response latency, <code>BatchGetItem</code> retrieves items in parallel.</p> <p>When designing your application, keep in mind that DynamoDB does not return items in any particular order. To help parse the response by item, include the primary key values for the items in your request in the <code>ProjectionExpression</code> parameter.</p> <p>If a requested item does not exist, it is not returned in the result. Requests for nonexistent items consume the minimum read capacity units according to the type of read. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/WorkingWithTables.html#CapacityUnitCalculations">Working with Tables</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
  ##   RequestItems: string
  ##               : Pagination token
  ##   body: JObject (required)
  var query_773164 = newJObject()
  var body_773166 = newJObject()
  add(query_773164, "RequestItems", newJString(RequestItems))
  if body != nil:
    body_773166 = body
  result = call_773163.call(nil, query_773164, nil, nil, body_773166)

var batchGetItem* = Call_BatchGetItem_772933(name: "batchGetItem",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.BatchGetItem",
    validator: validate_BatchGetItem_772934, base: "/", url: url_BatchGetItem_772935,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchWriteItem_773205 = ref object of OpenApiRestCall_772597
proc url_BatchWriteItem_773207(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchWriteItem_773206(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773208 = header.getOrDefault("X-Amz-Date")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "X-Amz-Date", valid_773208
  var valid_773209 = header.getOrDefault("X-Amz-Security-Token")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Security-Token", valid_773209
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773210 = header.getOrDefault("X-Amz-Target")
  valid_773210 = validateParameter(valid_773210, JString, required = true, default = newJString(
      "DynamoDB_20120810.BatchWriteItem"))
  if valid_773210 != nil:
    section.add "X-Amz-Target", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-Content-Sha256", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Algorithm")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Algorithm", valid_773212
  var valid_773213 = header.getOrDefault("X-Amz-Signature")
  valid_773213 = validateParameter(valid_773213, JString, required = false,
                                 default = nil)
  if valid_773213 != nil:
    section.add "X-Amz-Signature", valid_773213
  var valid_773214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773214 = validateParameter(valid_773214, JString, required = false,
                                 default = nil)
  if valid_773214 != nil:
    section.add "X-Amz-SignedHeaders", valid_773214
  var valid_773215 = header.getOrDefault("X-Amz-Credential")
  valid_773215 = validateParameter(valid_773215, JString, required = false,
                                 default = nil)
  if valid_773215 != nil:
    section.add "X-Amz-Credential", valid_773215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773217: Call_BatchWriteItem_773205; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>BatchWriteItem</code> operation puts or deletes multiple items in one or more tables. A single call to <code>BatchWriteItem</code> can write up to 16 MB of data, which can comprise as many as 25 put or delete requests. Individual items to be written can be as large as 400 KB.</p> <note> <p> <code>BatchWriteItem</code> cannot update items. To update items, use the <code>UpdateItem</code> action.</p> </note> <p>The individual <code>PutItem</code> and <code>DeleteItem</code> operations specified in <code>BatchWriteItem</code> are atomic; however <code>BatchWriteItem</code> as a whole is not. If any requested operations fail because the table's provisioned throughput is exceeded or an internal processing failure occurs, the failed operations are returned in the <code>UnprocessedItems</code> response parameter. You can investigate and optionally resend the requests. Typically, you would call <code>BatchWriteItem</code> in a loop. Each iteration would check for unprocessed items and submit a new <code>BatchWriteItem</code> request with those unprocessed items until all items have been processed.</p> <p>If <i>none</i> of the items can be processed due to insufficient provisioned throughput on all of the tables in the request, then <code>BatchWriteItem</code> returns a <code>ProvisionedThroughputExceededException</code>.</p> <important> <p>If DynamoDB returns any unprocessed items, you should retry the batch operation on those items. However, <i>we strongly recommend that you use an exponential backoff algorithm</i>. If you retry the batch operation immediately, the underlying read or write requests can still fail due to throttling on the individual tables. If you delay the batch operation using exponential backoff, the individual requests in the batch are much more likely to succeed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ErrorHandling.html#Programming.Errors.BatchOperations">Batch Operations and Error Handling</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p> </important> <p>With <code>BatchWriteItem</code>, you can efficiently write or delete large amounts of data, such as from Amazon EMR, or copy data from another database into DynamoDB. In order to improve performance with these large-scale operations, <code>BatchWriteItem</code> does not behave in the same way as individual <code>PutItem</code> and <code>DeleteItem</code> calls would. For example, you cannot specify conditions on individual put and delete requests, and <code>BatchWriteItem</code> does not return deleted items in the response.</p> <p>If you use a programming language that supports concurrency, you can use threads to write items in parallel. Your application must include the necessary logic to manage the threads. With languages that don't support threading, you must update or delete the specified items one at a time. In both situations, <code>BatchWriteItem</code> performs the specified put and delete operations in parallel, giving you the power of the thread pool approach without having to introduce complexity into your application.</p> <p>Parallel processing reduces latency, but each specified put and delete request consumes the same number of write capacity units whether it is processed in parallel or not. Delete operations on nonexistent items consume one write capacity unit.</p> <p>If one or more of the following is true, DynamoDB rejects the entire batch write operation:</p> <ul> <li> <p>One or more tables specified in the <code>BatchWriteItem</code> request does not exist.</p> </li> <li> <p>Primary key attributes specified on an item in the request do not match those in the corresponding table's primary key schema.</p> </li> <li> <p>You try to perform multiple operations on the same item in the same <code>BatchWriteItem</code> request. For example, you cannot put and delete the same item in the same <code>BatchWriteItem</code> request. </p> </li> <li> <p> Your request contains at least two items with identical hash and range keys (which essentially is two put operations). </p> </li> <li> <p>There are more than 25 requests in the batch.</p> </li> <li> <p>Any individual item in a batch exceeds 400 KB.</p> </li> <li> <p>The total request size exceeds 16 MB.</p> </li> </ul>
  ## 
  let valid = call_773217.validator(path, query, header, formData, body)
  let scheme = call_773217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773217.url(scheme.get, call_773217.host, call_773217.base,
                         call_773217.route, valid.getOrDefault("path"))
  result = hook(call_773217, url, valid)

proc call*(call_773218: Call_BatchWriteItem_773205; body: JsonNode): Recallable =
  ## batchWriteItem
  ## <p>The <code>BatchWriteItem</code> operation puts or deletes multiple items in one or more tables. A single call to <code>BatchWriteItem</code> can write up to 16 MB of data, which can comprise as many as 25 put or delete requests. Individual items to be written can be as large as 400 KB.</p> <note> <p> <code>BatchWriteItem</code> cannot update items. To update items, use the <code>UpdateItem</code> action.</p> </note> <p>The individual <code>PutItem</code> and <code>DeleteItem</code> operations specified in <code>BatchWriteItem</code> are atomic; however <code>BatchWriteItem</code> as a whole is not. If any requested operations fail because the table's provisioned throughput is exceeded or an internal processing failure occurs, the failed operations are returned in the <code>UnprocessedItems</code> response parameter. You can investigate and optionally resend the requests. Typically, you would call <code>BatchWriteItem</code> in a loop. Each iteration would check for unprocessed items and submit a new <code>BatchWriteItem</code> request with those unprocessed items until all items have been processed.</p> <p>If <i>none</i> of the items can be processed due to insufficient provisioned throughput on all of the tables in the request, then <code>BatchWriteItem</code> returns a <code>ProvisionedThroughputExceededException</code>.</p> <important> <p>If DynamoDB returns any unprocessed items, you should retry the batch operation on those items. However, <i>we strongly recommend that you use an exponential backoff algorithm</i>. If you retry the batch operation immediately, the underlying read or write requests can still fail due to throttling on the individual tables. If you delay the batch operation using exponential backoff, the individual requests in the batch are much more likely to succeed.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ErrorHandling.html#Programming.Errors.BatchOperations">Batch Operations and Error Handling</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p> </important> <p>With <code>BatchWriteItem</code>, you can efficiently write or delete large amounts of data, such as from Amazon EMR, or copy data from another database into DynamoDB. In order to improve performance with these large-scale operations, <code>BatchWriteItem</code> does not behave in the same way as individual <code>PutItem</code> and <code>DeleteItem</code> calls would. For example, you cannot specify conditions on individual put and delete requests, and <code>BatchWriteItem</code> does not return deleted items in the response.</p> <p>If you use a programming language that supports concurrency, you can use threads to write items in parallel. Your application must include the necessary logic to manage the threads. With languages that don't support threading, you must update or delete the specified items one at a time. In both situations, <code>BatchWriteItem</code> performs the specified put and delete operations in parallel, giving you the power of the thread pool approach without having to introduce complexity into your application.</p> <p>Parallel processing reduces latency, but each specified put and delete request consumes the same number of write capacity units whether it is processed in parallel or not. Delete operations on nonexistent items consume one write capacity unit.</p> <p>If one or more of the following is true, DynamoDB rejects the entire batch write operation:</p> <ul> <li> <p>One or more tables specified in the <code>BatchWriteItem</code> request does not exist.</p> </li> <li> <p>Primary key attributes specified on an item in the request do not match those in the corresponding table's primary key schema.</p> </li> <li> <p>You try to perform multiple operations on the same item in the same <code>BatchWriteItem</code> request. For example, you cannot put and delete the same item in the same <code>BatchWriteItem</code> request. </p> </li> <li> <p> Your request contains at least two items with identical hash and range keys (which essentially is two put operations). </p> </li> <li> <p>There are more than 25 requests in the batch.</p> </li> <li> <p>Any individual item in a batch exceeds 400 KB.</p> </li> <li> <p>The total request size exceeds 16 MB.</p> </li> </ul>
  ##   body: JObject (required)
  var body_773219 = newJObject()
  if body != nil:
    body_773219 = body
  result = call_773218.call(nil, nil, nil, nil, body_773219)

var batchWriteItem* = Call_BatchWriteItem_773205(name: "batchWriteItem",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.BatchWriteItem",
    validator: validate_BatchWriteItem_773206, base: "/", url: url_BatchWriteItem_773207,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackup_773220 = ref object of OpenApiRestCall_772597
proc url_CreateBackup_773222(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateBackup_773221(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773223 = header.getOrDefault("X-Amz-Date")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Date", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-Security-Token")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-Security-Token", valid_773224
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773225 = header.getOrDefault("X-Amz-Target")
  valid_773225 = validateParameter(valid_773225, JString, required = true, default = newJString(
      "DynamoDB_20120810.CreateBackup"))
  if valid_773225 != nil:
    section.add "X-Amz-Target", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-Content-Sha256", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-Algorithm")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Algorithm", valid_773227
  var valid_773228 = header.getOrDefault("X-Amz-Signature")
  valid_773228 = validateParameter(valid_773228, JString, required = false,
                                 default = nil)
  if valid_773228 != nil:
    section.add "X-Amz-Signature", valid_773228
  var valid_773229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773229 = validateParameter(valid_773229, JString, required = false,
                                 default = nil)
  if valid_773229 != nil:
    section.add "X-Amz-SignedHeaders", valid_773229
  var valid_773230 = header.getOrDefault("X-Amz-Credential")
  valid_773230 = validateParameter(valid_773230, JString, required = false,
                                 default = nil)
  if valid_773230 != nil:
    section.add "X-Amz-Credential", valid_773230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773232: Call_CreateBackup_773220; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a backup for an existing table.</p> <p> Each time you create an on-demand backup, the entire table data is backed up. There is no limit to the number of on-demand backups that can be taken. </p> <p> When you create an on-demand backup, a time marker of the request is cataloged, and the backup is created asynchronously, by applying all changes until the time of the request to the last full table snapshot. Backup requests are processed instantaneously and become available for restore within minutes. </p> <p>You can call <code>CreateBackup</code> at a maximum rate of 50 times per second.</p> <p>All backups in DynamoDB work without consuming any provisioned throughput on the table.</p> <p> If you submit a backup request on 2018-12-14 at 14:25:00, the backup is guaranteed to contain all data committed to the table up to 14:24:00, and data committed after 14:26:00 will not be. The backup might contain data modifications made between 14:24:00 and 14:26:00. On-demand backup does not support causal consistency. </p> <p> Along with data, the following are also included on the backups: </p> <ul> <li> <p>Global secondary indexes (GSIs)</p> </li> <li> <p>Local secondary indexes (LSIs)</p> </li> <li> <p>Streams</p> </li> <li> <p>Provisioned read and write capacity</p> </li> </ul>
  ## 
  let valid = call_773232.validator(path, query, header, formData, body)
  let scheme = call_773232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773232.url(scheme.get, call_773232.host, call_773232.base,
                         call_773232.route, valid.getOrDefault("path"))
  result = hook(call_773232, url, valid)

proc call*(call_773233: Call_CreateBackup_773220; body: JsonNode): Recallable =
  ## createBackup
  ## <p>Creates a backup for an existing table.</p> <p> Each time you create an on-demand backup, the entire table data is backed up. There is no limit to the number of on-demand backups that can be taken. </p> <p> When you create an on-demand backup, a time marker of the request is cataloged, and the backup is created asynchronously, by applying all changes until the time of the request to the last full table snapshot. Backup requests are processed instantaneously and become available for restore within minutes. </p> <p>You can call <code>CreateBackup</code> at a maximum rate of 50 times per second.</p> <p>All backups in DynamoDB work without consuming any provisioned throughput on the table.</p> <p> If you submit a backup request on 2018-12-14 at 14:25:00, the backup is guaranteed to contain all data committed to the table up to 14:24:00, and data committed after 14:26:00 will not be. The backup might contain data modifications made between 14:24:00 and 14:26:00. On-demand backup does not support causal consistency. </p> <p> Along with data, the following are also included on the backups: </p> <ul> <li> <p>Global secondary indexes (GSIs)</p> </li> <li> <p>Local secondary indexes (LSIs)</p> </li> <li> <p>Streams</p> </li> <li> <p>Provisioned read and write capacity</p> </li> </ul>
  ##   body: JObject (required)
  var body_773234 = newJObject()
  if body != nil:
    body_773234 = body
  result = call_773233.call(nil, nil, nil, nil, body_773234)

var createBackup* = Call_CreateBackup_773220(name: "createBackup",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.CreateBackup",
    validator: validate_CreateBackup_773221, base: "/", url: url_CreateBackup_773222,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGlobalTable_773235 = ref object of OpenApiRestCall_772597
proc url_CreateGlobalTable_773237(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateGlobalTable_773236(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773238 = header.getOrDefault("X-Amz-Date")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "X-Amz-Date", valid_773238
  var valid_773239 = header.getOrDefault("X-Amz-Security-Token")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "X-Amz-Security-Token", valid_773239
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773240 = header.getOrDefault("X-Amz-Target")
  valid_773240 = validateParameter(valid_773240, JString, required = true, default = newJString(
      "DynamoDB_20120810.CreateGlobalTable"))
  if valid_773240 != nil:
    section.add "X-Amz-Target", valid_773240
  var valid_773241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-Content-Sha256", valid_773241
  var valid_773242 = header.getOrDefault("X-Amz-Algorithm")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-Algorithm", valid_773242
  var valid_773243 = header.getOrDefault("X-Amz-Signature")
  valid_773243 = validateParameter(valid_773243, JString, required = false,
                                 default = nil)
  if valid_773243 != nil:
    section.add "X-Amz-Signature", valid_773243
  var valid_773244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773244 = validateParameter(valid_773244, JString, required = false,
                                 default = nil)
  if valid_773244 != nil:
    section.add "X-Amz-SignedHeaders", valid_773244
  var valid_773245 = header.getOrDefault("X-Amz-Credential")
  valid_773245 = validateParameter(valid_773245, JString, required = false,
                                 default = nil)
  if valid_773245 != nil:
    section.add "X-Amz-Credential", valid_773245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773247: Call_CreateGlobalTable_773235; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a global table from an existing table. A global table creates a replication relationship between two or more DynamoDB tables with the same table name in the provided Regions. </p> <p>If you want to add a new replica table to a global table, each of the following conditions must be true:</p> <ul> <li> <p>The table must have the same primary key as all of the other replicas.</p> </li> <li> <p>The table must have the same name as all of the other replicas.</p> </li> <li> <p>The table must have DynamoDB Streams enabled, with the stream containing both the new and the old images of the item.</p> </li> <li> <p>None of the replica tables in the global table can contain any data.</p> </li> </ul> <p> If global secondary indexes are specified, then the following conditions must also be met: </p> <ul> <li> <p> The global secondary indexes must have the same name. </p> </li> <li> <p> The global secondary indexes must have the same hash key and sort key (if present). </p> </li> </ul> <important> <p> Write capacity settings should be set consistently across your replica tables and secondary indexes. DynamoDB strongly recommends enabling auto scaling to manage the write capacity settings for all of your global tables replicas and indexes. </p> <p> If you prefer to manage write capacity settings manually, you should provision equal replicated write capacity units to your replica tables. You should also provision equal replicated write capacity units to matching secondary indexes across your global table. </p> </important>
  ## 
  let valid = call_773247.validator(path, query, header, formData, body)
  let scheme = call_773247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773247.url(scheme.get, call_773247.host, call_773247.base,
                         call_773247.route, valid.getOrDefault("path"))
  result = hook(call_773247, url, valid)

proc call*(call_773248: Call_CreateGlobalTable_773235; body: JsonNode): Recallable =
  ## createGlobalTable
  ## <p>Creates a global table from an existing table. A global table creates a replication relationship between two or more DynamoDB tables with the same table name in the provided Regions. </p> <p>If you want to add a new replica table to a global table, each of the following conditions must be true:</p> <ul> <li> <p>The table must have the same primary key as all of the other replicas.</p> </li> <li> <p>The table must have the same name as all of the other replicas.</p> </li> <li> <p>The table must have DynamoDB Streams enabled, with the stream containing both the new and the old images of the item.</p> </li> <li> <p>None of the replica tables in the global table can contain any data.</p> </li> </ul> <p> If global secondary indexes are specified, then the following conditions must also be met: </p> <ul> <li> <p> The global secondary indexes must have the same name. </p> </li> <li> <p> The global secondary indexes must have the same hash key and sort key (if present). </p> </li> </ul> <important> <p> Write capacity settings should be set consistently across your replica tables and secondary indexes. DynamoDB strongly recommends enabling auto scaling to manage the write capacity settings for all of your global tables replicas and indexes. </p> <p> If you prefer to manage write capacity settings manually, you should provision equal replicated write capacity units to your replica tables. You should also provision equal replicated write capacity units to matching secondary indexes across your global table. </p> </important>
  ##   body: JObject (required)
  var body_773249 = newJObject()
  if body != nil:
    body_773249 = body
  result = call_773248.call(nil, nil, nil, nil, body_773249)

var createGlobalTable* = Call_CreateGlobalTable_773235(name: "createGlobalTable",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.CreateGlobalTable",
    validator: validate_CreateGlobalTable_773236, base: "/",
    url: url_CreateGlobalTable_773237, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTable_773250 = ref object of OpenApiRestCall_772597
proc url_CreateTable_773252(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateTable_773251(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773253 = header.getOrDefault("X-Amz-Date")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Date", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-Security-Token")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Security-Token", valid_773254
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773255 = header.getOrDefault("X-Amz-Target")
  valid_773255 = validateParameter(valid_773255, JString, required = true, default = newJString(
      "DynamoDB_20120810.CreateTable"))
  if valid_773255 != nil:
    section.add "X-Amz-Target", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-Content-Sha256", valid_773256
  var valid_773257 = header.getOrDefault("X-Amz-Algorithm")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "X-Amz-Algorithm", valid_773257
  var valid_773258 = header.getOrDefault("X-Amz-Signature")
  valid_773258 = validateParameter(valid_773258, JString, required = false,
                                 default = nil)
  if valid_773258 != nil:
    section.add "X-Amz-Signature", valid_773258
  var valid_773259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773259 = validateParameter(valid_773259, JString, required = false,
                                 default = nil)
  if valid_773259 != nil:
    section.add "X-Amz-SignedHeaders", valid_773259
  var valid_773260 = header.getOrDefault("X-Amz-Credential")
  valid_773260 = validateParameter(valid_773260, JString, required = false,
                                 default = nil)
  if valid_773260 != nil:
    section.add "X-Amz-Credential", valid_773260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773262: Call_CreateTable_773250; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>CreateTable</code> operation adds a new table to your account. In an AWS account, table names must be unique within each Region. That is, you can have two tables with same name if you create the tables in different Regions.</p> <p> <code>CreateTable</code> is an asynchronous operation. Upon receiving a <code>CreateTable</code> request, DynamoDB immediately returns a response with a <code>TableStatus</code> of <code>CREATING</code>. After the table is created, DynamoDB sets the <code>TableStatus</code> to <code>ACTIVE</code>. You can perform read and write operations only on an <code>ACTIVE</code> table. </p> <p>You can optionally define secondary indexes on the new table, as part of the <code>CreateTable</code> operation. If you want to create multiple tables with secondary indexes on them, you must create the tables sequentially. Only one table with secondary indexes can be in the <code>CREATING</code> state at any given time.</p> <p>You can use the <code>DescribeTable</code> action to check the table status.</p>
  ## 
  let valid = call_773262.validator(path, query, header, formData, body)
  let scheme = call_773262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773262.url(scheme.get, call_773262.host, call_773262.base,
                         call_773262.route, valid.getOrDefault("path"))
  result = hook(call_773262, url, valid)

proc call*(call_773263: Call_CreateTable_773250; body: JsonNode): Recallable =
  ## createTable
  ## <p>The <code>CreateTable</code> operation adds a new table to your account. In an AWS account, table names must be unique within each Region. That is, you can have two tables with same name if you create the tables in different Regions.</p> <p> <code>CreateTable</code> is an asynchronous operation. Upon receiving a <code>CreateTable</code> request, DynamoDB immediately returns a response with a <code>TableStatus</code> of <code>CREATING</code>. After the table is created, DynamoDB sets the <code>TableStatus</code> to <code>ACTIVE</code>. You can perform read and write operations only on an <code>ACTIVE</code> table. </p> <p>You can optionally define secondary indexes on the new table, as part of the <code>CreateTable</code> operation. If you want to create multiple tables with secondary indexes on them, you must create the tables sequentially. Only one table with secondary indexes can be in the <code>CREATING</code> state at any given time.</p> <p>You can use the <code>DescribeTable</code> action to check the table status.</p>
  ##   body: JObject (required)
  var body_773264 = newJObject()
  if body != nil:
    body_773264 = body
  result = call_773263.call(nil, nil, nil, nil, body_773264)

var createTable* = Call_CreateTable_773250(name: "createTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20120810.CreateTable",
                                        validator: validate_CreateTable_773251,
                                        base: "/", url: url_CreateTable_773252,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackup_773265 = ref object of OpenApiRestCall_772597
proc url_DeleteBackup_773267(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteBackup_773266(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773268 = header.getOrDefault("X-Amz-Date")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Date", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Security-Token")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Security-Token", valid_773269
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773270 = header.getOrDefault("X-Amz-Target")
  valid_773270 = validateParameter(valid_773270, JString, required = true, default = newJString(
      "DynamoDB_20120810.DeleteBackup"))
  if valid_773270 != nil:
    section.add "X-Amz-Target", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-Content-Sha256", valid_773271
  var valid_773272 = header.getOrDefault("X-Amz-Algorithm")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "X-Amz-Algorithm", valid_773272
  var valid_773273 = header.getOrDefault("X-Amz-Signature")
  valid_773273 = validateParameter(valid_773273, JString, required = false,
                                 default = nil)
  if valid_773273 != nil:
    section.add "X-Amz-Signature", valid_773273
  var valid_773274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773274 = validateParameter(valid_773274, JString, required = false,
                                 default = nil)
  if valid_773274 != nil:
    section.add "X-Amz-SignedHeaders", valid_773274
  var valid_773275 = header.getOrDefault("X-Amz-Credential")
  valid_773275 = validateParameter(valid_773275, JString, required = false,
                                 default = nil)
  if valid_773275 != nil:
    section.add "X-Amz-Credential", valid_773275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773277: Call_DeleteBackup_773265; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing backup of a table.</p> <p>You can call <code>DeleteBackup</code> at a maximum rate of 10 times per second.</p>
  ## 
  let valid = call_773277.validator(path, query, header, formData, body)
  let scheme = call_773277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773277.url(scheme.get, call_773277.host, call_773277.base,
                         call_773277.route, valid.getOrDefault("path"))
  result = hook(call_773277, url, valid)

proc call*(call_773278: Call_DeleteBackup_773265; body: JsonNode): Recallable =
  ## deleteBackup
  ## <p>Deletes an existing backup of a table.</p> <p>You can call <code>DeleteBackup</code> at a maximum rate of 10 times per second.</p>
  ##   body: JObject (required)
  var body_773279 = newJObject()
  if body != nil:
    body_773279 = body
  result = call_773278.call(nil, nil, nil, nil, body_773279)

var deleteBackup* = Call_DeleteBackup_773265(name: "deleteBackup",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DeleteBackup",
    validator: validate_DeleteBackup_773266, base: "/", url: url_DeleteBackup_773267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteItem_773280 = ref object of OpenApiRestCall_772597
proc url_DeleteItem_773282(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteItem_773281(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773283 = header.getOrDefault("X-Amz-Date")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "X-Amz-Date", valid_773283
  var valid_773284 = header.getOrDefault("X-Amz-Security-Token")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "X-Amz-Security-Token", valid_773284
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773285 = header.getOrDefault("X-Amz-Target")
  valid_773285 = validateParameter(valid_773285, JString, required = true, default = newJString(
      "DynamoDB_20120810.DeleteItem"))
  if valid_773285 != nil:
    section.add "X-Amz-Target", valid_773285
  var valid_773286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-Content-Sha256", valid_773286
  var valid_773287 = header.getOrDefault("X-Amz-Algorithm")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "X-Amz-Algorithm", valid_773287
  var valid_773288 = header.getOrDefault("X-Amz-Signature")
  valid_773288 = validateParameter(valid_773288, JString, required = false,
                                 default = nil)
  if valid_773288 != nil:
    section.add "X-Amz-Signature", valid_773288
  var valid_773289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773289 = validateParameter(valid_773289, JString, required = false,
                                 default = nil)
  if valid_773289 != nil:
    section.add "X-Amz-SignedHeaders", valid_773289
  var valid_773290 = header.getOrDefault("X-Amz-Credential")
  valid_773290 = validateParameter(valid_773290, JString, required = false,
                                 default = nil)
  if valid_773290 != nil:
    section.add "X-Amz-Credential", valid_773290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773292: Call_DeleteItem_773280; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a single item in a table by primary key. You can perform a conditional delete operation that deletes the item if it exists, or if it has an expected attribute value.</p> <p>In addition to deleting an item, you can also return the item's attribute values in the same operation, using the <code>ReturnValues</code> parameter.</p> <p>Unless you specify conditions, the <code>DeleteItem</code> is an idempotent operation; running it multiple times on the same item or attribute does <i>not</i> result in an error response.</p> <p>Conditional deletes are useful for deleting items only if specific conditions are met. If those conditions are met, DynamoDB performs the delete. Otherwise, the item is not deleted.</p>
  ## 
  let valid = call_773292.validator(path, query, header, formData, body)
  let scheme = call_773292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773292.url(scheme.get, call_773292.host, call_773292.base,
                         call_773292.route, valid.getOrDefault("path"))
  result = hook(call_773292, url, valid)

proc call*(call_773293: Call_DeleteItem_773280; body: JsonNode): Recallable =
  ## deleteItem
  ## <p>Deletes a single item in a table by primary key. You can perform a conditional delete operation that deletes the item if it exists, or if it has an expected attribute value.</p> <p>In addition to deleting an item, you can also return the item's attribute values in the same operation, using the <code>ReturnValues</code> parameter.</p> <p>Unless you specify conditions, the <code>DeleteItem</code> is an idempotent operation; running it multiple times on the same item or attribute does <i>not</i> result in an error response.</p> <p>Conditional deletes are useful for deleting items only if specific conditions are met. If those conditions are met, DynamoDB performs the delete. Otherwise, the item is not deleted.</p>
  ##   body: JObject (required)
  var body_773294 = newJObject()
  if body != nil:
    body_773294 = body
  result = call_773293.call(nil, nil, nil, nil, body_773294)

var deleteItem* = Call_DeleteItem_773280(name: "deleteItem",
                                      meth: HttpMethod.HttpPost,
                                      host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20120810.DeleteItem",
                                      validator: validate_DeleteItem_773281,
                                      base: "/", url: url_DeleteItem_773282,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTable_773295 = ref object of OpenApiRestCall_772597
proc url_DeleteTable_773297(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteTable_773296(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773298 = header.getOrDefault("X-Amz-Date")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "X-Amz-Date", valid_773298
  var valid_773299 = header.getOrDefault("X-Amz-Security-Token")
  valid_773299 = validateParameter(valid_773299, JString, required = false,
                                 default = nil)
  if valid_773299 != nil:
    section.add "X-Amz-Security-Token", valid_773299
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773300 = header.getOrDefault("X-Amz-Target")
  valid_773300 = validateParameter(valid_773300, JString, required = true, default = newJString(
      "DynamoDB_20120810.DeleteTable"))
  if valid_773300 != nil:
    section.add "X-Amz-Target", valid_773300
  var valid_773301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773301 = validateParameter(valid_773301, JString, required = false,
                                 default = nil)
  if valid_773301 != nil:
    section.add "X-Amz-Content-Sha256", valid_773301
  var valid_773302 = header.getOrDefault("X-Amz-Algorithm")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "X-Amz-Algorithm", valid_773302
  var valid_773303 = header.getOrDefault("X-Amz-Signature")
  valid_773303 = validateParameter(valid_773303, JString, required = false,
                                 default = nil)
  if valid_773303 != nil:
    section.add "X-Amz-Signature", valid_773303
  var valid_773304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773304 = validateParameter(valid_773304, JString, required = false,
                                 default = nil)
  if valid_773304 != nil:
    section.add "X-Amz-SignedHeaders", valid_773304
  var valid_773305 = header.getOrDefault("X-Amz-Credential")
  valid_773305 = validateParameter(valid_773305, JString, required = false,
                                 default = nil)
  if valid_773305 != nil:
    section.add "X-Amz-Credential", valid_773305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773307: Call_DeleteTable_773295; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>DeleteTable</code> operation deletes a table and all of its items. After a <code>DeleteTable</code> request, the specified table is in the <code>DELETING</code> state until DynamoDB completes the deletion. If the table is in the <code>ACTIVE</code> state, you can delete it. If a table is in <code>CREATING</code> or <code>UPDATING</code> states, then DynamoDB returns a <code>ResourceInUseException</code>. If the specified table does not exist, DynamoDB returns a <code>ResourceNotFoundException</code>. If table is already in the <code>DELETING</code> state, no error is returned. </p> <note> <p>DynamoDB might continue to accept data read and write operations, such as <code>GetItem</code> and <code>PutItem</code>, on a table in the <code>DELETING</code> state until the table deletion is complete.</p> </note> <p>When you delete a table, any indexes on that table are also deleted.</p> <p>If you have DynamoDB Streams enabled on the table, then the corresponding stream on that table goes into the <code>DISABLED</code> state, and the stream is automatically deleted after 24 hours.</p> <p>Use the <code>DescribeTable</code> action to check the status of the table. </p>
  ## 
  let valid = call_773307.validator(path, query, header, formData, body)
  let scheme = call_773307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773307.url(scheme.get, call_773307.host, call_773307.base,
                         call_773307.route, valid.getOrDefault("path"))
  result = hook(call_773307, url, valid)

proc call*(call_773308: Call_DeleteTable_773295; body: JsonNode): Recallable =
  ## deleteTable
  ## <p>The <code>DeleteTable</code> operation deletes a table and all of its items. After a <code>DeleteTable</code> request, the specified table is in the <code>DELETING</code> state until DynamoDB completes the deletion. If the table is in the <code>ACTIVE</code> state, you can delete it. If a table is in <code>CREATING</code> or <code>UPDATING</code> states, then DynamoDB returns a <code>ResourceInUseException</code>. If the specified table does not exist, DynamoDB returns a <code>ResourceNotFoundException</code>. If table is already in the <code>DELETING</code> state, no error is returned. </p> <note> <p>DynamoDB might continue to accept data read and write operations, such as <code>GetItem</code> and <code>PutItem</code>, on a table in the <code>DELETING</code> state until the table deletion is complete.</p> </note> <p>When you delete a table, any indexes on that table are also deleted.</p> <p>If you have DynamoDB Streams enabled on the table, then the corresponding stream on that table goes into the <code>DISABLED</code> state, and the stream is automatically deleted after 24 hours.</p> <p>Use the <code>DescribeTable</code> action to check the status of the table. </p>
  ##   body: JObject (required)
  var body_773309 = newJObject()
  if body != nil:
    body_773309 = body
  result = call_773308.call(nil, nil, nil, nil, body_773309)

var deleteTable* = Call_DeleteTable_773295(name: "deleteTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20120810.DeleteTable",
                                        validator: validate_DeleteTable_773296,
                                        base: "/", url: url_DeleteTable_773297,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBackup_773310 = ref object of OpenApiRestCall_772597
proc url_DescribeBackup_773312(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeBackup_773311(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773313 = header.getOrDefault("X-Amz-Date")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "X-Amz-Date", valid_773313
  var valid_773314 = header.getOrDefault("X-Amz-Security-Token")
  valid_773314 = validateParameter(valid_773314, JString, required = false,
                                 default = nil)
  if valid_773314 != nil:
    section.add "X-Amz-Security-Token", valid_773314
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773315 = header.getOrDefault("X-Amz-Target")
  valid_773315 = validateParameter(valid_773315, JString, required = true, default = newJString(
      "DynamoDB_20120810.DescribeBackup"))
  if valid_773315 != nil:
    section.add "X-Amz-Target", valid_773315
  var valid_773316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "X-Amz-Content-Sha256", valid_773316
  var valid_773317 = header.getOrDefault("X-Amz-Algorithm")
  valid_773317 = validateParameter(valid_773317, JString, required = false,
                                 default = nil)
  if valid_773317 != nil:
    section.add "X-Amz-Algorithm", valid_773317
  var valid_773318 = header.getOrDefault("X-Amz-Signature")
  valid_773318 = validateParameter(valid_773318, JString, required = false,
                                 default = nil)
  if valid_773318 != nil:
    section.add "X-Amz-Signature", valid_773318
  var valid_773319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773319 = validateParameter(valid_773319, JString, required = false,
                                 default = nil)
  if valid_773319 != nil:
    section.add "X-Amz-SignedHeaders", valid_773319
  var valid_773320 = header.getOrDefault("X-Amz-Credential")
  valid_773320 = validateParameter(valid_773320, JString, required = false,
                                 default = nil)
  if valid_773320 != nil:
    section.add "X-Amz-Credential", valid_773320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773322: Call_DescribeBackup_773310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes an existing backup of a table.</p> <p>You can call <code>DescribeBackup</code> at a maximum rate of 10 times per second.</p>
  ## 
  let valid = call_773322.validator(path, query, header, formData, body)
  let scheme = call_773322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773322.url(scheme.get, call_773322.host, call_773322.base,
                         call_773322.route, valid.getOrDefault("path"))
  result = hook(call_773322, url, valid)

proc call*(call_773323: Call_DescribeBackup_773310; body: JsonNode): Recallable =
  ## describeBackup
  ## <p>Describes an existing backup of a table.</p> <p>You can call <code>DescribeBackup</code> at a maximum rate of 10 times per second.</p>
  ##   body: JObject (required)
  var body_773324 = newJObject()
  if body != nil:
    body_773324 = body
  result = call_773323.call(nil, nil, nil, nil, body_773324)

var describeBackup* = Call_DescribeBackup_773310(name: "describeBackup",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DescribeBackup",
    validator: validate_DescribeBackup_773311, base: "/", url: url_DescribeBackup_773312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeContinuousBackups_773325 = ref object of OpenApiRestCall_772597
proc url_DescribeContinuousBackups_773327(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeContinuousBackups_773326(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773328 = header.getOrDefault("X-Amz-Date")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "X-Amz-Date", valid_773328
  var valid_773329 = header.getOrDefault("X-Amz-Security-Token")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "X-Amz-Security-Token", valid_773329
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773330 = header.getOrDefault("X-Amz-Target")
  valid_773330 = validateParameter(valid_773330, JString, required = true, default = newJString(
      "DynamoDB_20120810.DescribeContinuousBackups"))
  if valid_773330 != nil:
    section.add "X-Amz-Target", valid_773330
  var valid_773331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "X-Amz-Content-Sha256", valid_773331
  var valid_773332 = header.getOrDefault("X-Amz-Algorithm")
  valid_773332 = validateParameter(valid_773332, JString, required = false,
                                 default = nil)
  if valid_773332 != nil:
    section.add "X-Amz-Algorithm", valid_773332
  var valid_773333 = header.getOrDefault("X-Amz-Signature")
  valid_773333 = validateParameter(valid_773333, JString, required = false,
                                 default = nil)
  if valid_773333 != nil:
    section.add "X-Amz-Signature", valid_773333
  var valid_773334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773334 = validateParameter(valid_773334, JString, required = false,
                                 default = nil)
  if valid_773334 != nil:
    section.add "X-Amz-SignedHeaders", valid_773334
  var valid_773335 = header.getOrDefault("X-Amz-Credential")
  valid_773335 = validateParameter(valid_773335, JString, required = false,
                                 default = nil)
  if valid_773335 != nil:
    section.add "X-Amz-Credential", valid_773335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773337: Call_DescribeContinuousBackups_773325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Checks the status of continuous backups and point in time recovery on the specified table. Continuous backups are <code>ENABLED</code> on all tables at table creation. If point in time recovery is enabled, <code>PointInTimeRecoveryStatus</code> will be set to ENABLED.</p> <p> After continuous backups and point in time recovery are enabled, you can restore to any point in time within <code>EarliestRestorableDateTime</code> and <code>LatestRestorableDateTime</code>. </p> <p> <code>LatestRestorableDateTime</code> is typically 5 minutes before the current time. You can restore your table to any point in time during the last 35 days. </p> <p>You can call <code>DescribeContinuousBackups</code> at a maximum rate of 10 times per second.</p>
  ## 
  let valid = call_773337.validator(path, query, header, formData, body)
  let scheme = call_773337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773337.url(scheme.get, call_773337.host, call_773337.base,
                         call_773337.route, valid.getOrDefault("path"))
  result = hook(call_773337, url, valid)

proc call*(call_773338: Call_DescribeContinuousBackups_773325; body: JsonNode): Recallable =
  ## describeContinuousBackups
  ## <p>Checks the status of continuous backups and point in time recovery on the specified table. Continuous backups are <code>ENABLED</code> on all tables at table creation. If point in time recovery is enabled, <code>PointInTimeRecoveryStatus</code> will be set to ENABLED.</p> <p> After continuous backups and point in time recovery are enabled, you can restore to any point in time within <code>EarliestRestorableDateTime</code> and <code>LatestRestorableDateTime</code>. </p> <p> <code>LatestRestorableDateTime</code> is typically 5 minutes before the current time. You can restore your table to any point in time during the last 35 days. </p> <p>You can call <code>DescribeContinuousBackups</code> at a maximum rate of 10 times per second.</p>
  ##   body: JObject (required)
  var body_773339 = newJObject()
  if body != nil:
    body_773339 = body
  result = call_773338.call(nil, nil, nil, nil, body_773339)

var describeContinuousBackups* = Call_DescribeContinuousBackups_773325(
    name: "describeContinuousBackups", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DescribeContinuousBackups",
    validator: validate_DescribeContinuousBackups_773326, base: "/",
    url: url_DescribeContinuousBackups_773327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoints_773340 = ref object of OpenApiRestCall_772597
proc url_DescribeEndpoints_773342(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEndpoints_773341(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773343 = header.getOrDefault("X-Amz-Date")
  valid_773343 = validateParameter(valid_773343, JString, required = false,
                                 default = nil)
  if valid_773343 != nil:
    section.add "X-Amz-Date", valid_773343
  var valid_773344 = header.getOrDefault("X-Amz-Security-Token")
  valid_773344 = validateParameter(valid_773344, JString, required = false,
                                 default = nil)
  if valid_773344 != nil:
    section.add "X-Amz-Security-Token", valid_773344
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773345 = header.getOrDefault("X-Amz-Target")
  valid_773345 = validateParameter(valid_773345, JString, required = true, default = newJString(
      "DynamoDB_20120810.DescribeEndpoints"))
  if valid_773345 != nil:
    section.add "X-Amz-Target", valid_773345
  var valid_773346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "X-Amz-Content-Sha256", valid_773346
  var valid_773347 = header.getOrDefault("X-Amz-Algorithm")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "X-Amz-Algorithm", valid_773347
  var valid_773348 = header.getOrDefault("X-Amz-Signature")
  valid_773348 = validateParameter(valid_773348, JString, required = false,
                                 default = nil)
  if valid_773348 != nil:
    section.add "X-Amz-Signature", valid_773348
  var valid_773349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773349 = validateParameter(valid_773349, JString, required = false,
                                 default = nil)
  if valid_773349 != nil:
    section.add "X-Amz-SignedHeaders", valid_773349
  var valid_773350 = header.getOrDefault("X-Amz-Credential")
  valid_773350 = validateParameter(valid_773350, JString, required = false,
                                 default = nil)
  if valid_773350 != nil:
    section.add "X-Amz-Credential", valid_773350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773352: Call_DescribeEndpoints_773340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the regional endpoint information.
  ## 
  let valid = call_773352.validator(path, query, header, formData, body)
  let scheme = call_773352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773352.url(scheme.get, call_773352.host, call_773352.base,
                         call_773352.route, valid.getOrDefault("path"))
  result = hook(call_773352, url, valid)

proc call*(call_773353: Call_DescribeEndpoints_773340; body: JsonNode): Recallable =
  ## describeEndpoints
  ## Returns the regional endpoint information.
  ##   body: JObject (required)
  var body_773354 = newJObject()
  if body != nil:
    body_773354 = body
  result = call_773353.call(nil, nil, nil, nil, body_773354)

var describeEndpoints* = Call_DescribeEndpoints_773340(name: "describeEndpoints",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DescribeEndpoints",
    validator: validate_DescribeEndpoints_773341, base: "/",
    url: url_DescribeEndpoints_773342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGlobalTable_773355 = ref object of OpenApiRestCall_772597
proc url_DescribeGlobalTable_773357(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeGlobalTable_773356(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773358 = header.getOrDefault("X-Amz-Date")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Date", valid_773358
  var valid_773359 = header.getOrDefault("X-Amz-Security-Token")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Security-Token", valid_773359
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773360 = header.getOrDefault("X-Amz-Target")
  valid_773360 = validateParameter(valid_773360, JString, required = true, default = newJString(
      "DynamoDB_20120810.DescribeGlobalTable"))
  if valid_773360 != nil:
    section.add "X-Amz-Target", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-Content-Sha256", valid_773361
  var valid_773362 = header.getOrDefault("X-Amz-Algorithm")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "X-Amz-Algorithm", valid_773362
  var valid_773363 = header.getOrDefault("X-Amz-Signature")
  valid_773363 = validateParameter(valid_773363, JString, required = false,
                                 default = nil)
  if valid_773363 != nil:
    section.add "X-Amz-Signature", valid_773363
  var valid_773364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773364 = validateParameter(valid_773364, JString, required = false,
                                 default = nil)
  if valid_773364 != nil:
    section.add "X-Amz-SignedHeaders", valid_773364
  var valid_773365 = header.getOrDefault("X-Amz-Credential")
  valid_773365 = validateParameter(valid_773365, JString, required = false,
                                 default = nil)
  if valid_773365 != nil:
    section.add "X-Amz-Credential", valid_773365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773367: Call_DescribeGlobalTable_773355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified global table.
  ## 
  let valid = call_773367.validator(path, query, header, formData, body)
  let scheme = call_773367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773367.url(scheme.get, call_773367.host, call_773367.base,
                         call_773367.route, valid.getOrDefault("path"))
  result = hook(call_773367, url, valid)

proc call*(call_773368: Call_DescribeGlobalTable_773355; body: JsonNode): Recallable =
  ## describeGlobalTable
  ## Returns information about the specified global table.
  ##   body: JObject (required)
  var body_773369 = newJObject()
  if body != nil:
    body_773369 = body
  result = call_773368.call(nil, nil, nil, nil, body_773369)

var describeGlobalTable* = Call_DescribeGlobalTable_773355(
    name: "describeGlobalTable", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DescribeGlobalTable",
    validator: validate_DescribeGlobalTable_773356, base: "/",
    url: url_DescribeGlobalTable_773357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGlobalTableSettings_773370 = ref object of OpenApiRestCall_772597
proc url_DescribeGlobalTableSettings_773372(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeGlobalTableSettings_773371(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773373 = header.getOrDefault("X-Amz-Date")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-Date", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-Security-Token")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-Security-Token", valid_773374
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773375 = header.getOrDefault("X-Amz-Target")
  valid_773375 = validateParameter(valid_773375, JString, required = true, default = newJString(
      "DynamoDB_20120810.DescribeGlobalTableSettings"))
  if valid_773375 != nil:
    section.add "X-Amz-Target", valid_773375
  var valid_773376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773376 = validateParameter(valid_773376, JString, required = false,
                                 default = nil)
  if valid_773376 != nil:
    section.add "X-Amz-Content-Sha256", valid_773376
  var valid_773377 = header.getOrDefault("X-Amz-Algorithm")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "X-Amz-Algorithm", valid_773377
  var valid_773378 = header.getOrDefault("X-Amz-Signature")
  valid_773378 = validateParameter(valid_773378, JString, required = false,
                                 default = nil)
  if valid_773378 != nil:
    section.add "X-Amz-Signature", valid_773378
  var valid_773379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773379 = validateParameter(valid_773379, JString, required = false,
                                 default = nil)
  if valid_773379 != nil:
    section.add "X-Amz-SignedHeaders", valid_773379
  var valid_773380 = header.getOrDefault("X-Amz-Credential")
  valid_773380 = validateParameter(valid_773380, JString, required = false,
                                 default = nil)
  if valid_773380 != nil:
    section.add "X-Amz-Credential", valid_773380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773382: Call_DescribeGlobalTableSettings_773370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes Region-specific settings for a global table.
  ## 
  let valid = call_773382.validator(path, query, header, formData, body)
  let scheme = call_773382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773382.url(scheme.get, call_773382.host, call_773382.base,
                         call_773382.route, valid.getOrDefault("path"))
  result = hook(call_773382, url, valid)

proc call*(call_773383: Call_DescribeGlobalTableSettings_773370; body: JsonNode): Recallable =
  ## describeGlobalTableSettings
  ## Describes Region-specific settings for a global table.
  ##   body: JObject (required)
  var body_773384 = newJObject()
  if body != nil:
    body_773384 = body
  result = call_773383.call(nil, nil, nil, nil, body_773384)

var describeGlobalTableSettings* = Call_DescribeGlobalTableSettings_773370(
    name: "describeGlobalTableSettings", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DescribeGlobalTableSettings",
    validator: validate_DescribeGlobalTableSettings_773371, base: "/",
    url: url_DescribeGlobalTableSettings_773372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLimits_773385 = ref object of OpenApiRestCall_772597
proc url_DescribeLimits_773387(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeLimits_773386(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773388 = header.getOrDefault("X-Amz-Date")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "X-Amz-Date", valid_773388
  var valid_773389 = header.getOrDefault("X-Amz-Security-Token")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "X-Amz-Security-Token", valid_773389
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773390 = header.getOrDefault("X-Amz-Target")
  valid_773390 = validateParameter(valid_773390, JString, required = true, default = newJString(
      "DynamoDB_20120810.DescribeLimits"))
  if valid_773390 != nil:
    section.add "X-Amz-Target", valid_773390
  var valid_773391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773391 = validateParameter(valid_773391, JString, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "X-Amz-Content-Sha256", valid_773391
  var valid_773392 = header.getOrDefault("X-Amz-Algorithm")
  valid_773392 = validateParameter(valid_773392, JString, required = false,
                                 default = nil)
  if valid_773392 != nil:
    section.add "X-Amz-Algorithm", valid_773392
  var valid_773393 = header.getOrDefault("X-Amz-Signature")
  valid_773393 = validateParameter(valid_773393, JString, required = false,
                                 default = nil)
  if valid_773393 != nil:
    section.add "X-Amz-Signature", valid_773393
  var valid_773394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773394 = validateParameter(valid_773394, JString, required = false,
                                 default = nil)
  if valid_773394 != nil:
    section.add "X-Amz-SignedHeaders", valid_773394
  var valid_773395 = header.getOrDefault("X-Amz-Credential")
  valid_773395 = validateParameter(valid_773395, JString, required = false,
                                 default = nil)
  if valid_773395 != nil:
    section.add "X-Amz-Credential", valid_773395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773397: Call_DescribeLimits_773385; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the current provisioned-capacity limits for your AWS account in a Region, both for the Region as a whole and for any one DynamoDB table that you create there.</p> <p>When you establish an AWS account, the account has initial limits on the maximum read capacity units and write capacity units that you can provision across all of your DynamoDB tables in a given Region. Also, there are per-table limits that apply when you create a table there. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Limits.html">Limits</a> page in the <i>Amazon DynamoDB Developer Guide</i>.</p> <p>Although you can increase these limits by filing a case at <a href="https://console.aws.amazon.com/support/home#/">AWS Support Center</a>, obtaining the increase is not instantaneous. The <code>DescribeLimits</code> action lets you write code to compare the capacity you are currently using to those limits imposed by your account so that you have enough time to apply for an increase before you hit a limit.</p> <p>For example, you could use one of the AWS SDKs to do the following:</p> <ol> <li> <p>Call <code>DescribeLimits</code> for a particular Region to obtain your current account limits on provisioned capacity there.</p> </li> <li> <p>Create a variable to hold the aggregate read capacity units provisioned for all your tables in that Region, and one to hold the aggregate write capacity units. Zero them both.</p> </li> <li> <p>Call <code>ListTables</code> to obtain a list of all your DynamoDB tables.</p> </li> <li> <p>For each table name listed by <code>ListTables</code>, do the following:</p> <ul> <li> <p>Call <code>DescribeTable</code> with the table name.</p> </li> <li> <p>Use the data returned by <code>DescribeTable</code> to add the read capacity units and write capacity units provisioned for the table itself to your variables.</p> </li> <li> <p>If the table has one or more global secondary indexes (GSIs), loop over these GSIs and add their provisioned capacity values to your variables as well.</p> </li> </ul> </li> <li> <p>Report the account limits for that Region returned by <code>DescribeLimits</code>, along with the total current provisioned capacity levels you have calculated.</p> </li> </ol> <p>This will let you see whether you are getting close to your account-level limits.</p> <p>The per-table limits apply only when you are creating a new table. They restrict the sum of the provisioned capacity of the new table itself and all its global secondary indexes.</p> <p>For existing tables and their GSIs, DynamoDB doesn't let you increase provisioned capacity extremely rapidly. But the only upper limit that applies is that the aggregate provisioned capacity over all your tables and GSIs cannot exceed either of the per-account limits.</p> <note> <p> <code>DescribeLimits</code> should only be called periodically. You can expect throttling errors if you call it more than once in a minute.</p> </note> <p>The <code>DescribeLimits</code> Request element has no content.</p>
  ## 
  let valid = call_773397.validator(path, query, header, formData, body)
  let scheme = call_773397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773397.url(scheme.get, call_773397.host, call_773397.base,
                         call_773397.route, valid.getOrDefault("path"))
  result = hook(call_773397, url, valid)

proc call*(call_773398: Call_DescribeLimits_773385; body: JsonNode): Recallable =
  ## describeLimits
  ## <p>Returns the current provisioned-capacity limits for your AWS account in a Region, both for the Region as a whole and for any one DynamoDB table that you create there.</p> <p>When you establish an AWS account, the account has initial limits on the maximum read capacity units and write capacity units that you can provision across all of your DynamoDB tables in a given Region. Also, there are per-table limits that apply when you create a table there. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Limits.html">Limits</a> page in the <i>Amazon DynamoDB Developer Guide</i>.</p> <p>Although you can increase these limits by filing a case at <a href="https://console.aws.amazon.com/support/home#/">AWS Support Center</a>, obtaining the increase is not instantaneous. The <code>DescribeLimits</code> action lets you write code to compare the capacity you are currently using to those limits imposed by your account so that you have enough time to apply for an increase before you hit a limit.</p> <p>For example, you could use one of the AWS SDKs to do the following:</p> <ol> <li> <p>Call <code>DescribeLimits</code> for a particular Region to obtain your current account limits on provisioned capacity there.</p> </li> <li> <p>Create a variable to hold the aggregate read capacity units provisioned for all your tables in that Region, and one to hold the aggregate write capacity units. Zero them both.</p> </li> <li> <p>Call <code>ListTables</code> to obtain a list of all your DynamoDB tables.</p> </li> <li> <p>For each table name listed by <code>ListTables</code>, do the following:</p> <ul> <li> <p>Call <code>DescribeTable</code> with the table name.</p> </li> <li> <p>Use the data returned by <code>DescribeTable</code> to add the read capacity units and write capacity units provisioned for the table itself to your variables.</p> </li> <li> <p>If the table has one or more global secondary indexes (GSIs), loop over these GSIs and add their provisioned capacity values to your variables as well.</p> </li> </ul> </li> <li> <p>Report the account limits for that Region returned by <code>DescribeLimits</code>, along with the total current provisioned capacity levels you have calculated.</p> </li> </ol> <p>This will let you see whether you are getting close to your account-level limits.</p> <p>The per-table limits apply only when you are creating a new table. They restrict the sum of the provisioned capacity of the new table itself and all its global secondary indexes.</p> <p>For existing tables and their GSIs, DynamoDB doesn't let you increase provisioned capacity extremely rapidly. But the only upper limit that applies is that the aggregate provisioned capacity over all your tables and GSIs cannot exceed either of the per-account limits.</p> <note> <p> <code>DescribeLimits</code> should only be called periodically. You can expect throttling errors if you call it more than once in a minute.</p> </note> <p>The <code>DescribeLimits</code> Request element has no content.</p>
  ##   body: JObject (required)
  var body_773399 = newJObject()
  if body != nil:
    body_773399 = body
  result = call_773398.call(nil, nil, nil, nil, body_773399)

var describeLimits* = Call_DescribeLimits_773385(name: "describeLimits",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DescribeLimits",
    validator: validate_DescribeLimits_773386, base: "/", url: url_DescribeLimits_773387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTable_773400 = ref object of OpenApiRestCall_772597
proc url_DescribeTable_773402(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeTable_773401(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773403 = header.getOrDefault("X-Amz-Date")
  valid_773403 = validateParameter(valid_773403, JString, required = false,
                                 default = nil)
  if valid_773403 != nil:
    section.add "X-Amz-Date", valid_773403
  var valid_773404 = header.getOrDefault("X-Amz-Security-Token")
  valid_773404 = validateParameter(valid_773404, JString, required = false,
                                 default = nil)
  if valid_773404 != nil:
    section.add "X-Amz-Security-Token", valid_773404
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773405 = header.getOrDefault("X-Amz-Target")
  valid_773405 = validateParameter(valid_773405, JString, required = true, default = newJString(
      "DynamoDB_20120810.DescribeTable"))
  if valid_773405 != nil:
    section.add "X-Amz-Target", valid_773405
  var valid_773406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773406 = validateParameter(valid_773406, JString, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "X-Amz-Content-Sha256", valid_773406
  var valid_773407 = header.getOrDefault("X-Amz-Algorithm")
  valid_773407 = validateParameter(valid_773407, JString, required = false,
                                 default = nil)
  if valid_773407 != nil:
    section.add "X-Amz-Algorithm", valid_773407
  var valid_773408 = header.getOrDefault("X-Amz-Signature")
  valid_773408 = validateParameter(valid_773408, JString, required = false,
                                 default = nil)
  if valid_773408 != nil:
    section.add "X-Amz-Signature", valid_773408
  var valid_773409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773409 = validateParameter(valid_773409, JString, required = false,
                                 default = nil)
  if valid_773409 != nil:
    section.add "X-Amz-SignedHeaders", valid_773409
  var valid_773410 = header.getOrDefault("X-Amz-Credential")
  valid_773410 = validateParameter(valid_773410, JString, required = false,
                                 default = nil)
  if valid_773410 != nil:
    section.add "X-Amz-Credential", valid_773410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773412: Call_DescribeTable_773400; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the table, including the current status of the table, when it was created, the primary key schema, and any indexes on the table.</p> <note> <p>If you issue a <code>DescribeTable</code> request immediately after a <code>CreateTable</code> request, DynamoDB might return a <code>ResourceNotFoundException</code>. This is because <code>DescribeTable</code> uses an eventually consistent query, and the metadata for your table might not be available at that moment. Wait for a few seconds, and then try the <code>DescribeTable</code> request again.</p> </note>
  ## 
  let valid = call_773412.validator(path, query, header, formData, body)
  let scheme = call_773412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773412.url(scheme.get, call_773412.host, call_773412.base,
                         call_773412.route, valid.getOrDefault("path"))
  result = hook(call_773412, url, valid)

proc call*(call_773413: Call_DescribeTable_773400; body: JsonNode): Recallable =
  ## describeTable
  ## <p>Returns information about the table, including the current status of the table, when it was created, the primary key schema, and any indexes on the table.</p> <note> <p>If you issue a <code>DescribeTable</code> request immediately after a <code>CreateTable</code> request, DynamoDB might return a <code>ResourceNotFoundException</code>. This is because <code>DescribeTable</code> uses an eventually consistent query, and the metadata for your table might not be available at that moment. Wait for a few seconds, and then try the <code>DescribeTable</code> request again.</p> </note>
  ##   body: JObject (required)
  var body_773414 = newJObject()
  if body != nil:
    body_773414 = body
  result = call_773413.call(nil, nil, nil, nil, body_773414)

var describeTable* = Call_DescribeTable_773400(name: "describeTable",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DescribeTable",
    validator: validate_DescribeTable_773401, base: "/", url: url_DescribeTable_773402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTimeToLive_773415 = ref object of OpenApiRestCall_772597
proc url_DescribeTimeToLive_773417(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeTimeToLive_773416(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773418 = header.getOrDefault("X-Amz-Date")
  valid_773418 = validateParameter(valid_773418, JString, required = false,
                                 default = nil)
  if valid_773418 != nil:
    section.add "X-Amz-Date", valid_773418
  var valid_773419 = header.getOrDefault("X-Amz-Security-Token")
  valid_773419 = validateParameter(valid_773419, JString, required = false,
                                 default = nil)
  if valid_773419 != nil:
    section.add "X-Amz-Security-Token", valid_773419
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773420 = header.getOrDefault("X-Amz-Target")
  valid_773420 = validateParameter(valid_773420, JString, required = true, default = newJString(
      "DynamoDB_20120810.DescribeTimeToLive"))
  if valid_773420 != nil:
    section.add "X-Amz-Target", valid_773420
  var valid_773421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773421 = validateParameter(valid_773421, JString, required = false,
                                 default = nil)
  if valid_773421 != nil:
    section.add "X-Amz-Content-Sha256", valid_773421
  var valid_773422 = header.getOrDefault("X-Amz-Algorithm")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "X-Amz-Algorithm", valid_773422
  var valid_773423 = header.getOrDefault("X-Amz-Signature")
  valid_773423 = validateParameter(valid_773423, JString, required = false,
                                 default = nil)
  if valid_773423 != nil:
    section.add "X-Amz-Signature", valid_773423
  var valid_773424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773424 = validateParameter(valid_773424, JString, required = false,
                                 default = nil)
  if valid_773424 != nil:
    section.add "X-Amz-SignedHeaders", valid_773424
  var valid_773425 = header.getOrDefault("X-Amz-Credential")
  valid_773425 = validateParameter(valid_773425, JString, required = false,
                                 default = nil)
  if valid_773425 != nil:
    section.add "X-Amz-Credential", valid_773425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773427: Call_DescribeTimeToLive_773415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gives a description of the Time to Live (TTL) status on the specified table. 
  ## 
  let valid = call_773427.validator(path, query, header, formData, body)
  let scheme = call_773427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773427.url(scheme.get, call_773427.host, call_773427.base,
                         call_773427.route, valid.getOrDefault("path"))
  result = hook(call_773427, url, valid)

proc call*(call_773428: Call_DescribeTimeToLive_773415; body: JsonNode): Recallable =
  ## describeTimeToLive
  ## Gives a description of the Time to Live (TTL) status on the specified table. 
  ##   body: JObject (required)
  var body_773429 = newJObject()
  if body != nil:
    body_773429 = body
  result = call_773428.call(nil, nil, nil, nil, body_773429)

var describeTimeToLive* = Call_DescribeTimeToLive_773415(
    name: "describeTimeToLive", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.DescribeTimeToLive",
    validator: validate_DescribeTimeToLive_773416, base: "/",
    url: url_DescribeTimeToLive_773417, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetItem_773430 = ref object of OpenApiRestCall_772597
proc url_GetItem_773432(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetItem_773431(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773433 = header.getOrDefault("X-Amz-Date")
  valid_773433 = validateParameter(valid_773433, JString, required = false,
                                 default = nil)
  if valid_773433 != nil:
    section.add "X-Amz-Date", valid_773433
  var valid_773434 = header.getOrDefault("X-Amz-Security-Token")
  valid_773434 = validateParameter(valid_773434, JString, required = false,
                                 default = nil)
  if valid_773434 != nil:
    section.add "X-Amz-Security-Token", valid_773434
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773435 = header.getOrDefault("X-Amz-Target")
  valid_773435 = validateParameter(valid_773435, JString, required = true, default = newJString(
      "DynamoDB_20120810.GetItem"))
  if valid_773435 != nil:
    section.add "X-Amz-Target", valid_773435
  var valid_773436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773436 = validateParameter(valid_773436, JString, required = false,
                                 default = nil)
  if valid_773436 != nil:
    section.add "X-Amz-Content-Sha256", valid_773436
  var valid_773437 = header.getOrDefault("X-Amz-Algorithm")
  valid_773437 = validateParameter(valid_773437, JString, required = false,
                                 default = nil)
  if valid_773437 != nil:
    section.add "X-Amz-Algorithm", valid_773437
  var valid_773438 = header.getOrDefault("X-Amz-Signature")
  valid_773438 = validateParameter(valid_773438, JString, required = false,
                                 default = nil)
  if valid_773438 != nil:
    section.add "X-Amz-Signature", valid_773438
  var valid_773439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773439 = validateParameter(valid_773439, JString, required = false,
                                 default = nil)
  if valid_773439 != nil:
    section.add "X-Amz-SignedHeaders", valid_773439
  var valid_773440 = header.getOrDefault("X-Amz-Credential")
  valid_773440 = validateParameter(valid_773440, JString, required = false,
                                 default = nil)
  if valid_773440 != nil:
    section.add "X-Amz-Credential", valid_773440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773442: Call_GetItem_773430; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>GetItem</code> operation returns a set of attributes for the item with the given primary key. If there is no matching item, <code>GetItem</code> does not return any data and there will be no <code>Item</code> element in the response.</p> <p> <code>GetItem</code> provides an eventually consistent read by default. If your application requires a strongly consistent read, set <code>ConsistentRead</code> to <code>true</code>. Although a strongly consistent read might take more time than an eventually consistent read, it always returns the last updated value.</p>
  ## 
  let valid = call_773442.validator(path, query, header, formData, body)
  let scheme = call_773442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773442.url(scheme.get, call_773442.host, call_773442.base,
                         call_773442.route, valid.getOrDefault("path"))
  result = hook(call_773442, url, valid)

proc call*(call_773443: Call_GetItem_773430; body: JsonNode): Recallable =
  ## getItem
  ## <p>The <code>GetItem</code> operation returns a set of attributes for the item with the given primary key. If there is no matching item, <code>GetItem</code> does not return any data and there will be no <code>Item</code> element in the response.</p> <p> <code>GetItem</code> provides an eventually consistent read by default. If your application requires a strongly consistent read, set <code>ConsistentRead</code> to <code>true</code>. Although a strongly consistent read might take more time than an eventually consistent read, it always returns the last updated value.</p>
  ##   body: JObject (required)
  var body_773444 = newJObject()
  if body != nil:
    body_773444 = body
  result = call_773443.call(nil, nil, nil, nil, body_773444)

var getItem* = Call_GetItem_773430(name: "getItem", meth: HttpMethod.HttpPost,
                                host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20120810.GetItem",
                                validator: validate_GetItem_773431, base: "/",
                                url: url_GetItem_773432,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackups_773445 = ref object of OpenApiRestCall_772597
proc url_ListBackups_773447(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListBackups_773446(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773448 = header.getOrDefault("X-Amz-Date")
  valid_773448 = validateParameter(valid_773448, JString, required = false,
                                 default = nil)
  if valid_773448 != nil:
    section.add "X-Amz-Date", valid_773448
  var valid_773449 = header.getOrDefault("X-Amz-Security-Token")
  valid_773449 = validateParameter(valid_773449, JString, required = false,
                                 default = nil)
  if valid_773449 != nil:
    section.add "X-Amz-Security-Token", valid_773449
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773450 = header.getOrDefault("X-Amz-Target")
  valid_773450 = validateParameter(valid_773450, JString, required = true, default = newJString(
      "DynamoDB_20120810.ListBackups"))
  if valid_773450 != nil:
    section.add "X-Amz-Target", valid_773450
  var valid_773451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773451 = validateParameter(valid_773451, JString, required = false,
                                 default = nil)
  if valid_773451 != nil:
    section.add "X-Amz-Content-Sha256", valid_773451
  var valid_773452 = header.getOrDefault("X-Amz-Algorithm")
  valid_773452 = validateParameter(valid_773452, JString, required = false,
                                 default = nil)
  if valid_773452 != nil:
    section.add "X-Amz-Algorithm", valid_773452
  var valid_773453 = header.getOrDefault("X-Amz-Signature")
  valid_773453 = validateParameter(valid_773453, JString, required = false,
                                 default = nil)
  if valid_773453 != nil:
    section.add "X-Amz-Signature", valid_773453
  var valid_773454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773454 = validateParameter(valid_773454, JString, required = false,
                                 default = nil)
  if valid_773454 != nil:
    section.add "X-Amz-SignedHeaders", valid_773454
  var valid_773455 = header.getOrDefault("X-Amz-Credential")
  valid_773455 = validateParameter(valid_773455, JString, required = false,
                                 default = nil)
  if valid_773455 != nil:
    section.add "X-Amz-Credential", valid_773455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773457: Call_ListBackups_773445; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List backups associated with an AWS account. To list backups for a given table, specify <code>TableName</code>. <code>ListBackups</code> returns a paginated list of results with at most 1 MB worth of items in a page. You can also specify a limit for the maximum number of entries to be returned in a page. </p> <p>In the request, start time is inclusive, but end time is exclusive. Note that these limits are for the time at which the original backup was requested.</p> <p>You can call <code>ListBackups</code> a maximum of five times per second.</p>
  ## 
  let valid = call_773457.validator(path, query, header, formData, body)
  let scheme = call_773457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773457.url(scheme.get, call_773457.host, call_773457.base,
                         call_773457.route, valid.getOrDefault("path"))
  result = hook(call_773457, url, valid)

proc call*(call_773458: Call_ListBackups_773445; body: JsonNode): Recallable =
  ## listBackups
  ## <p>List backups associated with an AWS account. To list backups for a given table, specify <code>TableName</code>. <code>ListBackups</code> returns a paginated list of results with at most 1 MB worth of items in a page. You can also specify a limit for the maximum number of entries to be returned in a page. </p> <p>In the request, start time is inclusive, but end time is exclusive. Note that these limits are for the time at which the original backup was requested.</p> <p>You can call <code>ListBackups</code> a maximum of five times per second.</p>
  ##   body: JObject (required)
  var body_773459 = newJObject()
  if body != nil:
    body_773459 = body
  result = call_773458.call(nil, nil, nil, nil, body_773459)

var listBackups* = Call_ListBackups_773445(name: "listBackups",
                                        meth: HttpMethod.HttpPost,
                                        host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20120810.ListBackups",
                                        validator: validate_ListBackups_773446,
                                        base: "/", url: url_ListBackups_773447,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGlobalTables_773460 = ref object of OpenApiRestCall_772597
proc url_ListGlobalTables_773462(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListGlobalTables_773461(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773463 = header.getOrDefault("X-Amz-Date")
  valid_773463 = validateParameter(valid_773463, JString, required = false,
                                 default = nil)
  if valid_773463 != nil:
    section.add "X-Amz-Date", valid_773463
  var valid_773464 = header.getOrDefault("X-Amz-Security-Token")
  valid_773464 = validateParameter(valid_773464, JString, required = false,
                                 default = nil)
  if valid_773464 != nil:
    section.add "X-Amz-Security-Token", valid_773464
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773465 = header.getOrDefault("X-Amz-Target")
  valid_773465 = validateParameter(valid_773465, JString, required = true, default = newJString(
      "DynamoDB_20120810.ListGlobalTables"))
  if valid_773465 != nil:
    section.add "X-Amz-Target", valid_773465
  var valid_773466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773466 = validateParameter(valid_773466, JString, required = false,
                                 default = nil)
  if valid_773466 != nil:
    section.add "X-Amz-Content-Sha256", valid_773466
  var valid_773467 = header.getOrDefault("X-Amz-Algorithm")
  valid_773467 = validateParameter(valid_773467, JString, required = false,
                                 default = nil)
  if valid_773467 != nil:
    section.add "X-Amz-Algorithm", valid_773467
  var valid_773468 = header.getOrDefault("X-Amz-Signature")
  valid_773468 = validateParameter(valid_773468, JString, required = false,
                                 default = nil)
  if valid_773468 != nil:
    section.add "X-Amz-Signature", valid_773468
  var valid_773469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773469 = validateParameter(valid_773469, JString, required = false,
                                 default = nil)
  if valid_773469 != nil:
    section.add "X-Amz-SignedHeaders", valid_773469
  var valid_773470 = header.getOrDefault("X-Amz-Credential")
  valid_773470 = validateParameter(valid_773470, JString, required = false,
                                 default = nil)
  if valid_773470 != nil:
    section.add "X-Amz-Credential", valid_773470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773472: Call_ListGlobalTables_773460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all global tables that have a replica in the specified Region.
  ## 
  let valid = call_773472.validator(path, query, header, formData, body)
  let scheme = call_773472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773472.url(scheme.get, call_773472.host, call_773472.base,
                         call_773472.route, valid.getOrDefault("path"))
  result = hook(call_773472, url, valid)

proc call*(call_773473: Call_ListGlobalTables_773460; body: JsonNode): Recallable =
  ## listGlobalTables
  ## Lists all global tables that have a replica in the specified Region.
  ##   body: JObject (required)
  var body_773474 = newJObject()
  if body != nil:
    body_773474 = body
  result = call_773473.call(nil, nil, nil, nil, body_773474)

var listGlobalTables* = Call_ListGlobalTables_773460(name: "listGlobalTables",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.ListGlobalTables",
    validator: validate_ListGlobalTables_773461, base: "/",
    url: url_ListGlobalTables_773462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTables_773475 = ref object of OpenApiRestCall_772597
proc url_ListTables_773477(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTables_773476(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773478 = query.getOrDefault("Limit")
  valid_773478 = validateParameter(valid_773478, JString, required = false,
                                 default = nil)
  if valid_773478 != nil:
    section.add "Limit", valid_773478
  var valid_773479 = query.getOrDefault("ExclusiveStartTableName")
  valid_773479 = validateParameter(valid_773479, JString, required = false,
                                 default = nil)
  if valid_773479 != nil:
    section.add "ExclusiveStartTableName", valid_773479
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
  var valid_773480 = header.getOrDefault("X-Amz-Date")
  valid_773480 = validateParameter(valid_773480, JString, required = false,
                                 default = nil)
  if valid_773480 != nil:
    section.add "X-Amz-Date", valid_773480
  var valid_773481 = header.getOrDefault("X-Amz-Security-Token")
  valid_773481 = validateParameter(valid_773481, JString, required = false,
                                 default = nil)
  if valid_773481 != nil:
    section.add "X-Amz-Security-Token", valid_773481
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773482 = header.getOrDefault("X-Amz-Target")
  valid_773482 = validateParameter(valid_773482, JString, required = true, default = newJString(
      "DynamoDB_20120810.ListTables"))
  if valid_773482 != nil:
    section.add "X-Amz-Target", valid_773482
  var valid_773483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773483 = validateParameter(valid_773483, JString, required = false,
                                 default = nil)
  if valid_773483 != nil:
    section.add "X-Amz-Content-Sha256", valid_773483
  var valid_773484 = header.getOrDefault("X-Amz-Algorithm")
  valid_773484 = validateParameter(valid_773484, JString, required = false,
                                 default = nil)
  if valid_773484 != nil:
    section.add "X-Amz-Algorithm", valid_773484
  var valid_773485 = header.getOrDefault("X-Amz-Signature")
  valid_773485 = validateParameter(valid_773485, JString, required = false,
                                 default = nil)
  if valid_773485 != nil:
    section.add "X-Amz-Signature", valid_773485
  var valid_773486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773486 = validateParameter(valid_773486, JString, required = false,
                                 default = nil)
  if valid_773486 != nil:
    section.add "X-Amz-SignedHeaders", valid_773486
  var valid_773487 = header.getOrDefault("X-Amz-Credential")
  valid_773487 = validateParameter(valid_773487, JString, required = false,
                                 default = nil)
  if valid_773487 != nil:
    section.add "X-Amz-Credential", valid_773487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773489: Call_ListTables_773475; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of table names associated with the current account and endpoint. The output from <code>ListTables</code> is paginated, with each page returning a maximum of 100 table names.
  ## 
  let valid = call_773489.validator(path, query, header, formData, body)
  let scheme = call_773489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773489.url(scheme.get, call_773489.host, call_773489.base,
                         call_773489.route, valid.getOrDefault("path"))
  result = hook(call_773489, url, valid)

proc call*(call_773490: Call_ListTables_773475; body: JsonNode; Limit: string = "";
          ExclusiveStartTableName: string = ""): Recallable =
  ## listTables
  ## Returns an array of table names associated with the current account and endpoint. The output from <code>ListTables</code> is paginated, with each page returning a maximum of 100 table names.
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  ##   ExclusiveStartTableName: string
  ##                          : Pagination token
  var query_773491 = newJObject()
  var body_773492 = newJObject()
  add(query_773491, "Limit", newJString(Limit))
  if body != nil:
    body_773492 = body
  add(query_773491, "ExclusiveStartTableName", newJString(ExclusiveStartTableName))
  result = call_773490.call(nil, query_773491, nil, nil, body_773492)

var listTables* = Call_ListTables_773475(name: "listTables",
                                      meth: HttpMethod.HttpPost,
                                      host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20120810.ListTables",
                                      validator: validate_ListTables_773476,
                                      base: "/", url: url_ListTables_773477,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsOfResource_773493 = ref object of OpenApiRestCall_772597
proc url_ListTagsOfResource_773495(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsOfResource_773494(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773496 = header.getOrDefault("X-Amz-Date")
  valid_773496 = validateParameter(valid_773496, JString, required = false,
                                 default = nil)
  if valid_773496 != nil:
    section.add "X-Amz-Date", valid_773496
  var valid_773497 = header.getOrDefault("X-Amz-Security-Token")
  valid_773497 = validateParameter(valid_773497, JString, required = false,
                                 default = nil)
  if valid_773497 != nil:
    section.add "X-Amz-Security-Token", valid_773497
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773498 = header.getOrDefault("X-Amz-Target")
  valid_773498 = validateParameter(valid_773498, JString, required = true, default = newJString(
      "DynamoDB_20120810.ListTagsOfResource"))
  if valid_773498 != nil:
    section.add "X-Amz-Target", valid_773498
  var valid_773499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773499 = validateParameter(valid_773499, JString, required = false,
                                 default = nil)
  if valid_773499 != nil:
    section.add "X-Amz-Content-Sha256", valid_773499
  var valid_773500 = header.getOrDefault("X-Amz-Algorithm")
  valid_773500 = validateParameter(valid_773500, JString, required = false,
                                 default = nil)
  if valid_773500 != nil:
    section.add "X-Amz-Algorithm", valid_773500
  var valid_773501 = header.getOrDefault("X-Amz-Signature")
  valid_773501 = validateParameter(valid_773501, JString, required = false,
                                 default = nil)
  if valid_773501 != nil:
    section.add "X-Amz-Signature", valid_773501
  var valid_773502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773502 = validateParameter(valid_773502, JString, required = false,
                                 default = nil)
  if valid_773502 != nil:
    section.add "X-Amz-SignedHeaders", valid_773502
  var valid_773503 = header.getOrDefault("X-Amz-Credential")
  valid_773503 = validateParameter(valid_773503, JString, required = false,
                                 default = nil)
  if valid_773503 != nil:
    section.add "X-Amz-Credential", valid_773503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773505: Call_ListTagsOfResource_773493; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List all tags on an Amazon DynamoDB resource. You can call ListTagsOfResource up to 10 times per second, per account.</p> <p>For an overview on tagging DynamoDB resources, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html">Tagging for DynamoDB</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
  ## 
  let valid = call_773505.validator(path, query, header, formData, body)
  let scheme = call_773505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773505.url(scheme.get, call_773505.host, call_773505.base,
                         call_773505.route, valid.getOrDefault("path"))
  result = hook(call_773505, url, valid)

proc call*(call_773506: Call_ListTagsOfResource_773493; body: JsonNode): Recallable =
  ## listTagsOfResource
  ## <p>List all tags on an Amazon DynamoDB resource. You can call ListTagsOfResource up to 10 times per second, per account.</p> <p>For an overview on tagging DynamoDB resources, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html">Tagging for DynamoDB</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_773507 = newJObject()
  if body != nil:
    body_773507 = body
  result = call_773506.call(nil, nil, nil, nil, body_773507)

var listTagsOfResource* = Call_ListTagsOfResource_773493(
    name: "listTagsOfResource", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.ListTagsOfResource",
    validator: validate_ListTagsOfResource_773494, base: "/",
    url: url_ListTagsOfResource_773495, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutItem_773508 = ref object of OpenApiRestCall_772597
proc url_PutItem_773510(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutItem_773509(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773511 = header.getOrDefault("X-Amz-Date")
  valid_773511 = validateParameter(valid_773511, JString, required = false,
                                 default = nil)
  if valid_773511 != nil:
    section.add "X-Amz-Date", valid_773511
  var valid_773512 = header.getOrDefault("X-Amz-Security-Token")
  valid_773512 = validateParameter(valid_773512, JString, required = false,
                                 default = nil)
  if valid_773512 != nil:
    section.add "X-Amz-Security-Token", valid_773512
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773513 = header.getOrDefault("X-Amz-Target")
  valid_773513 = validateParameter(valid_773513, JString, required = true, default = newJString(
      "DynamoDB_20120810.PutItem"))
  if valid_773513 != nil:
    section.add "X-Amz-Target", valid_773513
  var valid_773514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773514 = validateParameter(valid_773514, JString, required = false,
                                 default = nil)
  if valid_773514 != nil:
    section.add "X-Amz-Content-Sha256", valid_773514
  var valid_773515 = header.getOrDefault("X-Amz-Algorithm")
  valid_773515 = validateParameter(valid_773515, JString, required = false,
                                 default = nil)
  if valid_773515 != nil:
    section.add "X-Amz-Algorithm", valid_773515
  var valid_773516 = header.getOrDefault("X-Amz-Signature")
  valid_773516 = validateParameter(valid_773516, JString, required = false,
                                 default = nil)
  if valid_773516 != nil:
    section.add "X-Amz-Signature", valid_773516
  var valid_773517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773517 = validateParameter(valid_773517, JString, required = false,
                                 default = nil)
  if valid_773517 != nil:
    section.add "X-Amz-SignedHeaders", valid_773517
  var valid_773518 = header.getOrDefault("X-Amz-Credential")
  valid_773518 = validateParameter(valid_773518, JString, required = false,
                                 default = nil)
  if valid_773518 != nil:
    section.add "X-Amz-Credential", valid_773518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773520: Call_PutItem_773508; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new item, or replaces an old item with a new item. If an item that has the same primary key as the new item already exists in the specified table, the new item completely replaces the existing item. You can perform a conditional put operation (add a new item if one with the specified primary key doesn't exist), or replace an existing item if it has certain attribute values. You can return the item's attribute values in the same operation, using the <code>ReturnValues</code> parameter.</p> <important> <p>This topic provides general information about the <code>PutItem</code> API.</p> <p>For information on how to call the <code>PutItem</code> API using the AWS SDK in specific languages, see the following:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/goto/aws-cli/dynamodb-2012-08-10/PutItem"> PutItem in the AWS Command Line Interface</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/DotNetSDKV3/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for .NET</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForCpp/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for C++</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForGoV1/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Go</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForJava/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Java</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/AWSJavaScriptSDK/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for JavaScript</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForPHPV3/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for PHP V3</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/boto3/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Python</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForRubyV2/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Ruby V2</a> </p> </li> </ul> </important> <p>When you add an item, the primary key attributes are the only required attributes. Attribute values cannot be null. String and Binary type attributes must have lengths greater than zero. Set type attributes cannot be empty. Requests with empty values will be rejected with a <code>ValidationException</code> exception.</p> <note> <p>To prevent a new item from replacing an existing item, use a conditional expression that contains the <code>attribute_not_exists</code> function with the name of the attribute being used as the partition key for the table. Since every record must contain that attribute, the <code>attribute_not_exists</code> function will only succeed if no matching item exists.</p> </note> <p>For more information about <code>PutItem</code>, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/WorkingWithItems.html">Working with Items</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
  ## 
  let valid = call_773520.validator(path, query, header, formData, body)
  let scheme = call_773520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773520.url(scheme.get, call_773520.host, call_773520.base,
                         call_773520.route, valid.getOrDefault("path"))
  result = hook(call_773520, url, valid)

proc call*(call_773521: Call_PutItem_773508; body: JsonNode): Recallable =
  ## putItem
  ## <p>Creates a new item, or replaces an old item with a new item. If an item that has the same primary key as the new item already exists in the specified table, the new item completely replaces the existing item. You can perform a conditional put operation (add a new item if one with the specified primary key doesn't exist), or replace an existing item if it has certain attribute values. You can return the item's attribute values in the same operation, using the <code>ReturnValues</code> parameter.</p> <important> <p>This topic provides general information about the <code>PutItem</code> API.</p> <p>For information on how to call the <code>PutItem</code> API using the AWS SDK in specific languages, see the following:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/goto/aws-cli/dynamodb-2012-08-10/PutItem"> PutItem in the AWS Command Line Interface</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/DotNetSDKV3/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for .NET</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForCpp/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for C++</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForGoV1/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Go</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForJava/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Java</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/AWSJavaScriptSDK/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for JavaScript</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForPHPV3/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for PHP V3</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/boto3/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Python</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForRubyV2/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Ruby V2</a> </p> </li> </ul> </important> <p>When you add an item, the primary key attributes are the only required attributes. Attribute values cannot be null. String and Binary type attributes must have lengths greater than zero. Set type attributes cannot be empty. Requests with empty values will be rejected with a <code>ValidationException</code> exception.</p> <note> <p>To prevent a new item from replacing an existing item, use a conditional expression that contains the <code>attribute_not_exists</code> function with the name of the attribute being used as the partition key for the table. Since every record must contain that attribute, the <code>attribute_not_exists</code> function will only succeed if no matching item exists.</p> </note> <p>For more information about <code>PutItem</code>, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/WorkingWithItems.html">Working with Items</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_773522 = newJObject()
  if body != nil:
    body_773522 = body
  result = call_773521.call(nil, nil, nil, nil, body_773522)

var putItem* = Call_PutItem_773508(name: "putItem", meth: HttpMethod.HttpPost,
                                host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20120810.PutItem",
                                validator: validate_PutItem_773509, base: "/",
                                url: url_PutItem_773510,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_Query_773523 = ref object of OpenApiRestCall_772597
proc url_Query_773525(protocol: Scheme; host: string; base: string; route: string;
                     path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_Query_773524(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773526 = query.getOrDefault("Limit")
  valid_773526 = validateParameter(valid_773526, JString, required = false,
                                 default = nil)
  if valid_773526 != nil:
    section.add "Limit", valid_773526
  var valid_773527 = query.getOrDefault("ExclusiveStartKey")
  valid_773527 = validateParameter(valid_773527, JString, required = false,
                                 default = nil)
  if valid_773527 != nil:
    section.add "ExclusiveStartKey", valid_773527
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
  var valid_773528 = header.getOrDefault("X-Amz-Date")
  valid_773528 = validateParameter(valid_773528, JString, required = false,
                                 default = nil)
  if valid_773528 != nil:
    section.add "X-Amz-Date", valid_773528
  var valid_773529 = header.getOrDefault("X-Amz-Security-Token")
  valid_773529 = validateParameter(valid_773529, JString, required = false,
                                 default = nil)
  if valid_773529 != nil:
    section.add "X-Amz-Security-Token", valid_773529
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773530 = header.getOrDefault("X-Amz-Target")
  valid_773530 = validateParameter(valid_773530, JString, required = true, default = newJString(
      "DynamoDB_20120810.Query"))
  if valid_773530 != nil:
    section.add "X-Amz-Target", valid_773530
  var valid_773531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773531 = validateParameter(valid_773531, JString, required = false,
                                 default = nil)
  if valid_773531 != nil:
    section.add "X-Amz-Content-Sha256", valid_773531
  var valid_773532 = header.getOrDefault("X-Amz-Algorithm")
  valid_773532 = validateParameter(valid_773532, JString, required = false,
                                 default = nil)
  if valid_773532 != nil:
    section.add "X-Amz-Algorithm", valid_773532
  var valid_773533 = header.getOrDefault("X-Amz-Signature")
  valid_773533 = validateParameter(valid_773533, JString, required = false,
                                 default = nil)
  if valid_773533 != nil:
    section.add "X-Amz-Signature", valid_773533
  var valid_773534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773534 = validateParameter(valid_773534, JString, required = false,
                                 default = nil)
  if valid_773534 != nil:
    section.add "X-Amz-SignedHeaders", valid_773534
  var valid_773535 = header.getOrDefault("X-Amz-Credential")
  valid_773535 = validateParameter(valid_773535, JString, required = false,
                                 default = nil)
  if valid_773535 != nil:
    section.add "X-Amz-Credential", valid_773535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773537: Call_Query_773523; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>Query</code> operation finds items based on primary key values. You can query any table or secondary index that has a composite primary key (a partition key and a sort key). </p> <p>Use the <code>KeyConditionExpression</code> parameter to provide a specific value for the partition key. The <code>Query</code> operation will return all of the items from the table or index with that partition key value. You can optionally narrow the scope of the <code>Query</code> operation by specifying a sort key value and a comparison operator in <code>KeyConditionExpression</code>. To further refine the <code>Query</code> results, you can optionally provide a <code>FilterExpression</code>. A <code>FilterExpression</code> determines which items within the results should be returned to you. All of the other results are discarded. </p> <p> A <code>Query</code> operation always returns a result set. If no matching items are found, the result set will be empty. Queries that do not return results consume the minimum number of read capacity units for that type of read operation. </p> <note> <p> DynamoDB calculates the number of read capacity units consumed based on item size, not on the amount of data that is returned to an application. The number of capacity units consumed will be the same whether you request all of the attributes (the default behavior) or just some of them (using a projection expression). The number will also be the same whether or not you use a <code>FilterExpression</code>. </p> </note> <p> <code>Query</code> results are always sorted by the sort key value. If the data type of the sort key is Number, the results are returned in numeric order; otherwise, the results are returned in order of UTF-8 bytes. By default, the sort order is ascending. To reverse the order, set the <code>ScanIndexForward</code> parameter to false. </p> <p> A single <code>Query</code> operation will read up to the maximum number of items set (if using the <code>Limit</code> parameter) or a maximum of 1 MB of data and then apply any filtering to the results using <code>FilterExpression</code>. If <code>LastEvaluatedKey</code> is present in the response, you will need to paginate the result set. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Query.html#Query.Pagination">Paginating the Results</a> in the <i>Amazon DynamoDB Developer Guide</i>. </p> <p> <code>FilterExpression</code> is applied after a <code>Query</code> finishes, but before the results are returned. A <code>FilterExpression</code> cannot contain partition key or sort key attributes. You need to specify those attributes in the <code>KeyConditionExpression</code>. </p> <note> <p> A <code>Query</code> operation can return an empty result set and a <code>LastEvaluatedKey</code> if all the items read for the page of results are filtered out. </p> </note> <p>You can query a table, a local secondary index, or a global secondary index. For a query on a table or on a local secondary index, you can set the <code>ConsistentRead</code> parameter to <code>true</code> and obtain a strongly consistent result. Global secondary indexes support eventually consistent reads only, so do not specify <code>ConsistentRead</code> when querying a global secondary index.</p>
  ## 
  let valid = call_773537.validator(path, query, header, formData, body)
  let scheme = call_773537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773537.url(scheme.get, call_773537.host, call_773537.base,
                         call_773537.route, valid.getOrDefault("path"))
  result = hook(call_773537, url, valid)

proc call*(call_773538: Call_Query_773523; body: JsonNode; Limit: string = "";
          ExclusiveStartKey: string = ""): Recallable =
  ## query
  ## <p>The <code>Query</code> operation finds items based on primary key values. You can query any table or secondary index that has a composite primary key (a partition key and a sort key). </p> <p>Use the <code>KeyConditionExpression</code> parameter to provide a specific value for the partition key. The <code>Query</code> operation will return all of the items from the table or index with that partition key value. You can optionally narrow the scope of the <code>Query</code> operation by specifying a sort key value and a comparison operator in <code>KeyConditionExpression</code>. To further refine the <code>Query</code> results, you can optionally provide a <code>FilterExpression</code>. A <code>FilterExpression</code> determines which items within the results should be returned to you. All of the other results are discarded. </p> <p> A <code>Query</code> operation always returns a result set. If no matching items are found, the result set will be empty. Queries that do not return results consume the minimum number of read capacity units for that type of read operation. </p> <note> <p> DynamoDB calculates the number of read capacity units consumed based on item size, not on the amount of data that is returned to an application. The number of capacity units consumed will be the same whether you request all of the attributes (the default behavior) or just some of them (using a projection expression). The number will also be the same whether or not you use a <code>FilterExpression</code>. </p> </note> <p> <code>Query</code> results are always sorted by the sort key value. If the data type of the sort key is Number, the results are returned in numeric order; otherwise, the results are returned in order of UTF-8 bytes. By default, the sort order is ascending. To reverse the order, set the <code>ScanIndexForward</code> parameter to false. </p> <p> A single <code>Query</code> operation will read up to the maximum number of items set (if using the <code>Limit</code> parameter) or a maximum of 1 MB of data and then apply any filtering to the results using <code>FilterExpression</code>. If <code>LastEvaluatedKey</code> is present in the response, you will need to paginate the result set. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Query.html#Query.Pagination">Paginating the Results</a> in the <i>Amazon DynamoDB Developer Guide</i>. </p> <p> <code>FilterExpression</code> is applied after a <code>Query</code> finishes, but before the results are returned. A <code>FilterExpression</code> cannot contain partition key or sort key attributes. You need to specify those attributes in the <code>KeyConditionExpression</code>. </p> <note> <p> A <code>Query</code> operation can return an empty result set and a <code>LastEvaluatedKey</code> if all the items read for the page of results are filtered out. </p> </note> <p>You can query a table, a local secondary index, or a global secondary index. For a query on a table or on a local secondary index, you can set the <code>ConsistentRead</code> parameter to <code>true</code> and obtain a strongly consistent result. Global secondary indexes support eventually consistent reads only, so do not specify <code>ConsistentRead</code> when querying a global secondary index.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  ##   ExclusiveStartKey: string
  ##                    : Pagination token
  var query_773539 = newJObject()
  var body_773540 = newJObject()
  add(query_773539, "Limit", newJString(Limit))
  if body != nil:
    body_773540 = body
  add(query_773539, "ExclusiveStartKey", newJString(ExclusiveStartKey))
  result = call_773538.call(nil, query_773539, nil, nil, body_773540)

var query* = Call_Query_773523(name: "query", meth: HttpMethod.HttpPost,
                            host: "dynamodb.amazonaws.com",
                            route: "/#X-Amz-Target=DynamoDB_20120810.Query",
                            validator: validate_Query_773524, base: "/",
                            url: url_Query_773525,
                            schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreTableFromBackup_773541 = ref object of OpenApiRestCall_772597
proc url_RestoreTableFromBackup_773543(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RestoreTableFromBackup_773542(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773544 = header.getOrDefault("X-Amz-Date")
  valid_773544 = validateParameter(valid_773544, JString, required = false,
                                 default = nil)
  if valid_773544 != nil:
    section.add "X-Amz-Date", valid_773544
  var valid_773545 = header.getOrDefault("X-Amz-Security-Token")
  valid_773545 = validateParameter(valid_773545, JString, required = false,
                                 default = nil)
  if valid_773545 != nil:
    section.add "X-Amz-Security-Token", valid_773545
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773546 = header.getOrDefault("X-Amz-Target")
  valid_773546 = validateParameter(valid_773546, JString, required = true, default = newJString(
      "DynamoDB_20120810.RestoreTableFromBackup"))
  if valid_773546 != nil:
    section.add "X-Amz-Target", valid_773546
  var valid_773547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773547 = validateParameter(valid_773547, JString, required = false,
                                 default = nil)
  if valid_773547 != nil:
    section.add "X-Amz-Content-Sha256", valid_773547
  var valid_773548 = header.getOrDefault("X-Amz-Algorithm")
  valid_773548 = validateParameter(valid_773548, JString, required = false,
                                 default = nil)
  if valid_773548 != nil:
    section.add "X-Amz-Algorithm", valid_773548
  var valid_773549 = header.getOrDefault("X-Amz-Signature")
  valid_773549 = validateParameter(valid_773549, JString, required = false,
                                 default = nil)
  if valid_773549 != nil:
    section.add "X-Amz-Signature", valid_773549
  var valid_773550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773550 = validateParameter(valid_773550, JString, required = false,
                                 default = nil)
  if valid_773550 != nil:
    section.add "X-Amz-SignedHeaders", valid_773550
  var valid_773551 = header.getOrDefault("X-Amz-Credential")
  valid_773551 = validateParameter(valid_773551, JString, required = false,
                                 default = nil)
  if valid_773551 != nil:
    section.add "X-Amz-Credential", valid_773551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773553: Call_RestoreTableFromBackup_773541; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new table from an existing backup. Any number of users can execute up to 4 concurrent restores (any type of restore) in a given account. </p> <p>You can call <code>RestoreTableFromBackup</code> at a maximum rate of 10 times per second.</p> <p>You must manually set up the following on the restored table:</p> <ul> <li> <p>Auto scaling policies</p> </li> <li> <p>IAM policies</p> </li> <li> <p>Amazon CloudWatch metrics and alarms</p> </li> <li> <p>Tags</p> </li> <li> <p>Stream settings</p> </li> <li> <p>Time to Live (TTL) settings</p> </li> </ul>
  ## 
  let valid = call_773553.validator(path, query, header, formData, body)
  let scheme = call_773553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773553.url(scheme.get, call_773553.host, call_773553.base,
                         call_773553.route, valid.getOrDefault("path"))
  result = hook(call_773553, url, valid)

proc call*(call_773554: Call_RestoreTableFromBackup_773541; body: JsonNode): Recallable =
  ## restoreTableFromBackup
  ## <p>Creates a new table from an existing backup. Any number of users can execute up to 4 concurrent restores (any type of restore) in a given account. </p> <p>You can call <code>RestoreTableFromBackup</code> at a maximum rate of 10 times per second.</p> <p>You must manually set up the following on the restored table:</p> <ul> <li> <p>Auto scaling policies</p> </li> <li> <p>IAM policies</p> </li> <li> <p>Amazon CloudWatch metrics and alarms</p> </li> <li> <p>Tags</p> </li> <li> <p>Stream settings</p> </li> <li> <p>Time to Live (TTL) settings</p> </li> </ul>
  ##   body: JObject (required)
  var body_773555 = newJObject()
  if body != nil:
    body_773555 = body
  result = call_773554.call(nil, nil, nil, nil, body_773555)

var restoreTableFromBackup* = Call_RestoreTableFromBackup_773541(
    name: "restoreTableFromBackup", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.RestoreTableFromBackup",
    validator: validate_RestoreTableFromBackup_773542, base: "/",
    url: url_RestoreTableFromBackup_773543, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreTableToPointInTime_773556 = ref object of OpenApiRestCall_772597
proc url_RestoreTableToPointInTime_773558(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RestoreTableToPointInTime_773557(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773559 = header.getOrDefault("X-Amz-Date")
  valid_773559 = validateParameter(valid_773559, JString, required = false,
                                 default = nil)
  if valid_773559 != nil:
    section.add "X-Amz-Date", valid_773559
  var valid_773560 = header.getOrDefault("X-Amz-Security-Token")
  valid_773560 = validateParameter(valid_773560, JString, required = false,
                                 default = nil)
  if valid_773560 != nil:
    section.add "X-Amz-Security-Token", valid_773560
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773561 = header.getOrDefault("X-Amz-Target")
  valid_773561 = validateParameter(valid_773561, JString, required = true, default = newJString(
      "DynamoDB_20120810.RestoreTableToPointInTime"))
  if valid_773561 != nil:
    section.add "X-Amz-Target", valid_773561
  var valid_773562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773562 = validateParameter(valid_773562, JString, required = false,
                                 default = nil)
  if valid_773562 != nil:
    section.add "X-Amz-Content-Sha256", valid_773562
  var valid_773563 = header.getOrDefault("X-Amz-Algorithm")
  valid_773563 = validateParameter(valid_773563, JString, required = false,
                                 default = nil)
  if valid_773563 != nil:
    section.add "X-Amz-Algorithm", valid_773563
  var valid_773564 = header.getOrDefault("X-Amz-Signature")
  valid_773564 = validateParameter(valid_773564, JString, required = false,
                                 default = nil)
  if valid_773564 != nil:
    section.add "X-Amz-Signature", valid_773564
  var valid_773565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773565 = validateParameter(valid_773565, JString, required = false,
                                 default = nil)
  if valid_773565 != nil:
    section.add "X-Amz-SignedHeaders", valid_773565
  var valid_773566 = header.getOrDefault("X-Amz-Credential")
  valid_773566 = validateParameter(valid_773566, JString, required = false,
                                 default = nil)
  if valid_773566 != nil:
    section.add "X-Amz-Credential", valid_773566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773568: Call_RestoreTableToPointInTime_773556; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Restores the specified table to the specified point in time within <code>EarliestRestorableDateTime</code> and <code>LatestRestorableDateTime</code>. You can restore your table to any point in time during the last 35 days. Any number of users can execute up to 4 concurrent restores (any type of restore) in a given account. </p> <p> When you restore using point in time recovery, DynamoDB restores your table data to the state based on the selected date and time (day:hour:minute:second) to a new table. </p> <p> Along with data, the following are also included on the new restored table using point in time recovery: </p> <ul> <li> <p>Global secondary indexes (GSIs)</p> </li> <li> <p>Local secondary indexes (LSIs)</p> </li> <li> <p>Provisioned read and write capacity</p> </li> <li> <p>Encryption settings</p> <important> <p> All these settings come from the current settings of the source table at the time of restore. </p> </important> </li> </ul> <p>You must manually set up the following on the restored table:</p> <ul> <li> <p>Auto scaling policies</p> </li> <li> <p>IAM policies</p> </li> <li> <p>Amazon CloudWatch metrics and alarms</p> </li> <li> <p>Tags</p> </li> <li> <p>Stream settings</p> </li> <li> <p>Time to Live (TTL) settings</p> </li> <li> <p>Point in time recovery settings</p> </li> </ul>
  ## 
  let valid = call_773568.validator(path, query, header, formData, body)
  let scheme = call_773568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773568.url(scheme.get, call_773568.host, call_773568.base,
                         call_773568.route, valid.getOrDefault("path"))
  result = hook(call_773568, url, valid)

proc call*(call_773569: Call_RestoreTableToPointInTime_773556; body: JsonNode): Recallable =
  ## restoreTableToPointInTime
  ## <p>Restores the specified table to the specified point in time within <code>EarliestRestorableDateTime</code> and <code>LatestRestorableDateTime</code>. You can restore your table to any point in time during the last 35 days. Any number of users can execute up to 4 concurrent restores (any type of restore) in a given account. </p> <p> When you restore using point in time recovery, DynamoDB restores your table data to the state based on the selected date and time (day:hour:minute:second) to a new table. </p> <p> Along with data, the following are also included on the new restored table using point in time recovery: </p> <ul> <li> <p>Global secondary indexes (GSIs)</p> </li> <li> <p>Local secondary indexes (LSIs)</p> </li> <li> <p>Provisioned read and write capacity</p> </li> <li> <p>Encryption settings</p> <important> <p> All these settings come from the current settings of the source table at the time of restore. </p> </important> </li> </ul> <p>You must manually set up the following on the restored table:</p> <ul> <li> <p>Auto scaling policies</p> </li> <li> <p>IAM policies</p> </li> <li> <p>Amazon CloudWatch metrics and alarms</p> </li> <li> <p>Tags</p> </li> <li> <p>Stream settings</p> </li> <li> <p>Time to Live (TTL) settings</p> </li> <li> <p>Point in time recovery settings</p> </li> </ul>
  ##   body: JObject (required)
  var body_773570 = newJObject()
  if body != nil:
    body_773570 = body
  result = call_773569.call(nil, nil, nil, nil, body_773570)

var restoreTableToPointInTime* = Call_RestoreTableToPointInTime_773556(
    name: "restoreTableToPointInTime", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.RestoreTableToPointInTime",
    validator: validate_RestoreTableToPointInTime_773557, base: "/",
    url: url_RestoreTableToPointInTime_773558,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_Scan_773571 = ref object of OpenApiRestCall_772597
proc url_Scan_773573(protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_Scan_773572(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773574 = query.getOrDefault("Limit")
  valid_773574 = validateParameter(valid_773574, JString, required = false,
                                 default = nil)
  if valid_773574 != nil:
    section.add "Limit", valid_773574
  var valid_773575 = query.getOrDefault("ExclusiveStartKey")
  valid_773575 = validateParameter(valid_773575, JString, required = false,
                                 default = nil)
  if valid_773575 != nil:
    section.add "ExclusiveStartKey", valid_773575
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
  var valid_773576 = header.getOrDefault("X-Amz-Date")
  valid_773576 = validateParameter(valid_773576, JString, required = false,
                                 default = nil)
  if valid_773576 != nil:
    section.add "X-Amz-Date", valid_773576
  var valid_773577 = header.getOrDefault("X-Amz-Security-Token")
  valid_773577 = validateParameter(valid_773577, JString, required = false,
                                 default = nil)
  if valid_773577 != nil:
    section.add "X-Amz-Security-Token", valid_773577
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773578 = header.getOrDefault("X-Amz-Target")
  valid_773578 = validateParameter(valid_773578, JString, required = true,
                                 default = newJString("DynamoDB_20120810.Scan"))
  if valid_773578 != nil:
    section.add "X-Amz-Target", valid_773578
  var valid_773579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773579 = validateParameter(valid_773579, JString, required = false,
                                 default = nil)
  if valid_773579 != nil:
    section.add "X-Amz-Content-Sha256", valid_773579
  var valid_773580 = header.getOrDefault("X-Amz-Algorithm")
  valid_773580 = validateParameter(valid_773580, JString, required = false,
                                 default = nil)
  if valid_773580 != nil:
    section.add "X-Amz-Algorithm", valid_773580
  var valid_773581 = header.getOrDefault("X-Amz-Signature")
  valid_773581 = validateParameter(valid_773581, JString, required = false,
                                 default = nil)
  if valid_773581 != nil:
    section.add "X-Amz-Signature", valid_773581
  var valid_773582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773582 = validateParameter(valid_773582, JString, required = false,
                                 default = nil)
  if valid_773582 != nil:
    section.add "X-Amz-SignedHeaders", valid_773582
  var valid_773583 = header.getOrDefault("X-Amz-Credential")
  valid_773583 = validateParameter(valid_773583, JString, required = false,
                                 default = nil)
  if valid_773583 != nil:
    section.add "X-Amz-Credential", valid_773583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773585: Call_Scan_773571; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>Scan</code> operation returns one or more items and item attributes by accessing every item in a table or a secondary index. To have DynamoDB return fewer items, you can provide a <code>FilterExpression</code> operation.</p> <p>If the total number of scanned items exceeds the maximum dataset size limit of 1 MB, the scan stops and results are returned to the user as a <code>LastEvaluatedKey</code> value to continue the scan in a subsequent operation. The results also include the number of items exceeding the limit. A scan can result in no table data meeting the filter criteria. </p> <p>A single <code>Scan</code> operation reads up to the maximum number of items set (if using the <code>Limit</code> parameter) or a maximum of 1 MB of data and then apply any filtering to the results using <code>FilterExpression</code>. If <code>LastEvaluatedKey</code> is present in the response, you need to paginate the result set. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Scan.html#Scan.Pagination">Paginating the Results</a> in the <i>Amazon DynamoDB Developer Guide</i>. </p> <p> <code>Scan</code> operations proceed sequentially; however, for faster performance on a large table or secondary index, applications can request a parallel <code>Scan</code> operation by providing the <code>Segment</code> and <code>TotalSegments</code> parameters. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Scan.html#Scan.ParallelScan">Parallel Scan</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p> <p> <code>Scan</code> uses eventually consistent reads when accessing the data in a table; therefore, the result set might not include the changes to data in the table immediately before the operation began. If you need a consistent copy of the data, as of the time that the <code>Scan</code> begins, you can set the <code>ConsistentRead</code> parameter to <code>true</code>.</p>
  ## 
  let valid = call_773585.validator(path, query, header, formData, body)
  let scheme = call_773585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773585.url(scheme.get, call_773585.host, call_773585.base,
                         call_773585.route, valid.getOrDefault("path"))
  result = hook(call_773585, url, valid)

proc call*(call_773586: Call_Scan_773571; body: JsonNode; Limit: string = "";
          ExclusiveStartKey: string = ""): Recallable =
  ## scan
  ## <p>The <code>Scan</code> operation returns one or more items and item attributes by accessing every item in a table or a secondary index. To have DynamoDB return fewer items, you can provide a <code>FilterExpression</code> operation.</p> <p>If the total number of scanned items exceeds the maximum dataset size limit of 1 MB, the scan stops and results are returned to the user as a <code>LastEvaluatedKey</code> value to continue the scan in a subsequent operation. The results also include the number of items exceeding the limit. A scan can result in no table data meeting the filter criteria. </p> <p>A single <code>Scan</code> operation reads up to the maximum number of items set (if using the <code>Limit</code> parameter) or a maximum of 1 MB of data and then apply any filtering to the results using <code>FilterExpression</code>. If <code>LastEvaluatedKey</code> is present in the response, you need to paginate the result set. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Scan.html#Scan.Pagination">Paginating the Results</a> in the <i>Amazon DynamoDB Developer Guide</i>. </p> <p> <code>Scan</code> operations proceed sequentially; however, for faster performance on a large table or secondary index, applications can request a parallel <code>Scan</code> operation by providing the <code>Segment</code> and <code>TotalSegments</code> parameters. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Scan.html#Scan.ParallelScan">Parallel Scan</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p> <p> <code>Scan</code> uses eventually consistent reads when accessing the data in a table; therefore, the result set might not include the changes to data in the table immediately before the operation began. If you need a consistent copy of the data, as of the time that the <code>Scan</code> begins, you can set the <code>ConsistentRead</code> parameter to <code>true</code>.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  ##   ExclusiveStartKey: string
  ##                    : Pagination token
  var query_773587 = newJObject()
  var body_773588 = newJObject()
  add(query_773587, "Limit", newJString(Limit))
  if body != nil:
    body_773588 = body
  add(query_773587, "ExclusiveStartKey", newJString(ExclusiveStartKey))
  result = call_773586.call(nil, query_773587, nil, nil, body_773588)

var scan* = Call_Scan_773571(name: "scan", meth: HttpMethod.HttpPost,
                          host: "dynamodb.amazonaws.com",
                          route: "/#X-Amz-Target=DynamoDB_20120810.Scan",
                          validator: validate_Scan_773572, base: "/", url: url_Scan_773573,
                          schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_773589 = ref object of OpenApiRestCall_772597
proc url_TagResource_773591(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_773590(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773592 = header.getOrDefault("X-Amz-Date")
  valid_773592 = validateParameter(valid_773592, JString, required = false,
                                 default = nil)
  if valid_773592 != nil:
    section.add "X-Amz-Date", valid_773592
  var valid_773593 = header.getOrDefault("X-Amz-Security-Token")
  valid_773593 = validateParameter(valid_773593, JString, required = false,
                                 default = nil)
  if valid_773593 != nil:
    section.add "X-Amz-Security-Token", valid_773593
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773594 = header.getOrDefault("X-Amz-Target")
  valid_773594 = validateParameter(valid_773594, JString, required = true, default = newJString(
      "DynamoDB_20120810.TagResource"))
  if valid_773594 != nil:
    section.add "X-Amz-Target", valid_773594
  var valid_773595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773595 = validateParameter(valid_773595, JString, required = false,
                                 default = nil)
  if valid_773595 != nil:
    section.add "X-Amz-Content-Sha256", valid_773595
  var valid_773596 = header.getOrDefault("X-Amz-Algorithm")
  valid_773596 = validateParameter(valid_773596, JString, required = false,
                                 default = nil)
  if valid_773596 != nil:
    section.add "X-Amz-Algorithm", valid_773596
  var valid_773597 = header.getOrDefault("X-Amz-Signature")
  valid_773597 = validateParameter(valid_773597, JString, required = false,
                                 default = nil)
  if valid_773597 != nil:
    section.add "X-Amz-Signature", valid_773597
  var valid_773598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773598 = validateParameter(valid_773598, JString, required = false,
                                 default = nil)
  if valid_773598 != nil:
    section.add "X-Amz-SignedHeaders", valid_773598
  var valid_773599 = header.getOrDefault("X-Amz-Credential")
  valid_773599 = validateParameter(valid_773599, JString, required = false,
                                 default = nil)
  if valid_773599 != nil:
    section.add "X-Amz-Credential", valid_773599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773601: Call_TagResource_773589; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associate a set of tags with an Amazon DynamoDB resource. You can then activate these user-defined tags so that they appear on the Billing and Cost Management console for cost allocation tracking. You can call TagResource up to five times per second, per account. </p> <p>For an overview on tagging DynamoDB resources, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html">Tagging for DynamoDB</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
  ## 
  let valid = call_773601.validator(path, query, header, formData, body)
  let scheme = call_773601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773601.url(scheme.get, call_773601.host, call_773601.base,
                         call_773601.route, valid.getOrDefault("path"))
  result = hook(call_773601, url, valid)

proc call*(call_773602: Call_TagResource_773589; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Associate a set of tags with an Amazon DynamoDB resource. You can then activate these user-defined tags so that they appear on the Billing and Cost Management console for cost allocation tracking. You can call TagResource up to five times per second, per account. </p> <p>For an overview on tagging DynamoDB resources, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html">Tagging for DynamoDB</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_773603 = newJObject()
  if body != nil:
    body_773603 = body
  result = call_773602.call(nil, nil, nil, nil, body_773603)

var tagResource* = Call_TagResource_773589(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20120810.TagResource",
                                        validator: validate_TagResource_773590,
                                        base: "/", url: url_TagResource_773591,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TransactGetItems_773604 = ref object of OpenApiRestCall_772597
proc url_TransactGetItems_773606(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TransactGetItems_773605(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773607 = header.getOrDefault("X-Amz-Date")
  valid_773607 = validateParameter(valid_773607, JString, required = false,
                                 default = nil)
  if valid_773607 != nil:
    section.add "X-Amz-Date", valid_773607
  var valid_773608 = header.getOrDefault("X-Amz-Security-Token")
  valid_773608 = validateParameter(valid_773608, JString, required = false,
                                 default = nil)
  if valid_773608 != nil:
    section.add "X-Amz-Security-Token", valid_773608
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773609 = header.getOrDefault("X-Amz-Target")
  valid_773609 = validateParameter(valid_773609, JString, required = true, default = newJString(
      "DynamoDB_20120810.TransactGetItems"))
  if valid_773609 != nil:
    section.add "X-Amz-Target", valid_773609
  var valid_773610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773610 = validateParameter(valid_773610, JString, required = false,
                                 default = nil)
  if valid_773610 != nil:
    section.add "X-Amz-Content-Sha256", valid_773610
  var valid_773611 = header.getOrDefault("X-Amz-Algorithm")
  valid_773611 = validateParameter(valid_773611, JString, required = false,
                                 default = nil)
  if valid_773611 != nil:
    section.add "X-Amz-Algorithm", valid_773611
  var valid_773612 = header.getOrDefault("X-Amz-Signature")
  valid_773612 = validateParameter(valid_773612, JString, required = false,
                                 default = nil)
  if valid_773612 != nil:
    section.add "X-Amz-Signature", valid_773612
  var valid_773613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773613 = validateParameter(valid_773613, JString, required = false,
                                 default = nil)
  if valid_773613 != nil:
    section.add "X-Amz-SignedHeaders", valid_773613
  var valid_773614 = header.getOrDefault("X-Amz-Credential")
  valid_773614 = validateParameter(valid_773614, JString, required = false,
                                 default = nil)
  if valid_773614 != nil:
    section.add "X-Amz-Credential", valid_773614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773616: Call_TransactGetItems_773604; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>TransactGetItems</code> is a synchronous operation that atomically retrieves multiple items from one or more tables (but not from indexes) in a single account and Region. A <code>TransactGetItems</code> call can contain up to 25 <code>TransactGetItem</code> objects, each of which contains a <code>Get</code> structure that specifies an item to retrieve from a table in the account and Region. A call to <code>TransactGetItems</code> cannot retrieve items from tables in more than one AWS account or Region. The aggregate size of the items in the transaction cannot exceed 4 MB.</p> <note> <p>All AWS Regions and AWS GovCloud (US) support up to 25 items per transaction with up to 4 MB of data, except the following AWS Regions: </p> <ul> <li> <p>China (Beijing)</p> </li> <li> <p>China (Ningxia)</p> </li> </ul> <p>The China (Beijing) and China (Ningxia) Regions support up to 10 items per transaction with up to 4 MB of data. </p> </note> <p>DynamoDB rejects the entire <code>TransactGetItems</code> request if any of the following is true:</p> <ul> <li> <p>A conflicting operation is in the process of updating an item to be read.</p> </li> <li> <p>There is insufficient provisioned capacity for the transaction to be completed.</p> </li> <li> <p>There is a user error, such as an invalid data format.</p> </li> <li> <p>The aggregate size of the items in the transaction cannot exceed 4 MB.</p> </li> </ul>
  ## 
  let valid = call_773616.validator(path, query, header, formData, body)
  let scheme = call_773616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773616.url(scheme.get, call_773616.host, call_773616.base,
                         call_773616.route, valid.getOrDefault("path"))
  result = hook(call_773616, url, valid)

proc call*(call_773617: Call_TransactGetItems_773604; body: JsonNode): Recallable =
  ## transactGetItems
  ## <p> <code>TransactGetItems</code> is a synchronous operation that atomically retrieves multiple items from one or more tables (but not from indexes) in a single account and Region. A <code>TransactGetItems</code> call can contain up to 25 <code>TransactGetItem</code> objects, each of which contains a <code>Get</code> structure that specifies an item to retrieve from a table in the account and Region. A call to <code>TransactGetItems</code> cannot retrieve items from tables in more than one AWS account or Region. The aggregate size of the items in the transaction cannot exceed 4 MB.</p> <note> <p>All AWS Regions and AWS GovCloud (US) support up to 25 items per transaction with up to 4 MB of data, except the following AWS Regions: </p> <ul> <li> <p>China (Beijing)</p> </li> <li> <p>China (Ningxia)</p> </li> </ul> <p>The China (Beijing) and China (Ningxia) Regions support up to 10 items per transaction with up to 4 MB of data. </p> </note> <p>DynamoDB rejects the entire <code>TransactGetItems</code> request if any of the following is true:</p> <ul> <li> <p>A conflicting operation is in the process of updating an item to be read.</p> </li> <li> <p>There is insufficient provisioned capacity for the transaction to be completed.</p> </li> <li> <p>There is a user error, such as an invalid data format.</p> </li> <li> <p>The aggregate size of the items in the transaction cannot exceed 4 MB.</p> </li> </ul>
  ##   body: JObject (required)
  var body_773618 = newJObject()
  if body != nil:
    body_773618 = body
  result = call_773617.call(nil, nil, nil, nil, body_773618)

var transactGetItems* = Call_TransactGetItems_773604(name: "transactGetItems",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.TransactGetItems",
    validator: validate_TransactGetItems_773605, base: "/",
    url: url_TransactGetItems_773606, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TransactWriteItems_773619 = ref object of OpenApiRestCall_772597
proc url_TransactWriteItems_773621(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TransactWriteItems_773620(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773622 = header.getOrDefault("X-Amz-Date")
  valid_773622 = validateParameter(valid_773622, JString, required = false,
                                 default = nil)
  if valid_773622 != nil:
    section.add "X-Amz-Date", valid_773622
  var valid_773623 = header.getOrDefault("X-Amz-Security-Token")
  valid_773623 = validateParameter(valid_773623, JString, required = false,
                                 default = nil)
  if valid_773623 != nil:
    section.add "X-Amz-Security-Token", valid_773623
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773624 = header.getOrDefault("X-Amz-Target")
  valid_773624 = validateParameter(valid_773624, JString, required = true, default = newJString(
      "DynamoDB_20120810.TransactWriteItems"))
  if valid_773624 != nil:
    section.add "X-Amz-Target", valid_773624
  var valid_773625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773625 = validateParameter(valid_773625, JString, required = false,
                                 default = nil)
  if valid_773625 != nil:
    section.add "X-Amz-Content-Sha256", valid_773625
  var valid_773626 = header.getOrDefault("X-Amz-Algorithm")
  valid_773626 = validateParameter(valid_773626, JString, required = false,
                                 default = nil)
  if valid_773626 != nil:
    section.add "X-Amz-Algorithm", valid_773626
  var valid_773627 = header.getOrDefault("X-Amz-Signature")
  valid_773627 = validateParameter(valid_773627, JString, required = false,
                                 default = nil)
  if valid_773627 != nil:
    section.add "X-Amz-Signature", valid_773627
  var valid_773628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773628 = validateParameter(valid_773628, JString, required = false,
                                 default = nil)
  if valid_773628 != nil:
    section.add "X-Amz-SignedHeaders", valid_773628
  var valid_773629 = header.getOrDefault("X-Amz-Credential")
  valid_773629 = validateParameter(valid_773629, JString, required = false,
                                 default = nil)
  if valid_773629 != nil:
    section.add "X-Amz-Credential", valid_773629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773631: Call_TransactWriteItems_773619; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>TransactWriteItems</code> is a synchronous write operation that groups up to 25 action requests. These actions can target items in different tables, but not in different AWS accounts or Regions, and no two actions can target the same item. For example, you cannot both <code>ConditionCheck</code> and <code>Update</code> the same item. The aggregate size of the items in the transaction cannot exceed 4 MB.</p> <note> <p>All AWS Regions and AWS GovCloud (US) support up to 25 items per transaction with up to 4 MB of data, except the following AWS Regions: </p> <ul> <li> <p>China (Beijing)</p> </li> <li> <p>China (Ningxia)</p> </li> </ul> <p>The China (Beijing) and China (Ningxia) Regions support up to 10 items per transaction with up to 4 MB of data. </p> </note> <p>The actions are completed atomically so that either all of them succeed, or all of them fail. They are defined by the following objects:</p> <ul> <li> <p> <code>Put</code>  &#x97;   Initiates a <code>PutItem</code> operation to write a new item. This structure specifies the primary key of the item to be written, the name of the table to write it in, an optional condition expression that must be satisfied for the write to succeed, a list of the item's attributes, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> <li> <p> <code>Update</code>  &#x97;   Initiates an <code>UpdateItem</code> operation to update an existing item. This structure specifies the primary key of the item to be updated, the name of the table where it resides, an optional condition expression that must be satisfied for the update to succeed, an expression that defines one or more attributes to be updated, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> <li> <p> <code>Delete</code>  &#x97;   Initiates a <code>DeleteItem</code> operation to delete an existing item. This structure specifies the primary key of the item to be deleted, the name of the table where it resides, an optional condition expression that must be satisfied for the deletion to succeed, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> <li> <p> <code>ConditionCheck</code>  &#x97;   Applies a condition to an item that is not being modified by the transaction. This structure specifies the primary key of the item to be checked, the name of the table where it resides, a condition expression that must be satisfied for the transaction to succeed, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> </ul> <p>DynamoDB rejects the entire <code>TransactWriteItems</code> request if any of the following is true:</p> <ul> <li> <p>A condition in one of the condition expressions is not met.</p> </li> <li> <p>An ongoing operation is in the process of updating the same item.</p> </li> <li> <p>There is insufficient provisioned capacity for the transaction to be completed.</p> </li> <li> <p>An item size becomes too large (bigger than 400 KB), a local secondary index (LSI) becomes too large, or a similar validation error occurs because of changes made by the transaction.</p> </li> <li> <p>The aggregate size of the items in the transaction exceeds 4 MB.</p> </li> <li> <p>There is a user error, such as an invalid data format.</p> </li> </ul>
  ## 
  let valid = call_773631.validator(path, query, header, formData, body)
  let scheme = call_773631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773631.url(scheme.get, call_773631.host, call_773631.base,
                         call_773631.route, valid.getOrDefault("path"))
  result = hook(call_773631, url, valid)

proc call*(call_773632: Call_TransactWriteItems_773619; body: JsonNode): Recallable =
  ## transactWriteItems
  ## <p> <code>TransactWriteItems</code> is a synchronous write operation that groups up to 25 action requests. These actions can target items in different tables, but not in different AWS accounts or Regions, and no two actions can target the same item. For example, you cannot both <code>ConditionCheck</code> and <code>Update</code> the same item. The aggregate size of the items in the transaction cannot exceed 4 MB.</p> <note> <p>All AWS Regions and AWS GovCloud (US) support up to 25 items per transaction with up to 4 MB of data, except the following AWS Regions: </p> <ul> <li> <p>China (Beijing)</p> </li> <li> <p>China (Ningxia)</p> </li> </ul> <p>The China (Beijing) and China (Ningxia) Regions support up to 10 items per transaction with up to 4 MB of data. </p> </note> <p>The actions are completed atomically so that either all of them succeed, or all of them fail. They are defined by the following objects:</p> <ul> <li> <p> <code>Put</code>  &#x97;   Initiates a <code>PutItem</code> operation to write a new item. This structure specifies the primary key of the item to be written, the name of the table to write it in, an optional condition expression that must be satisfied for the write to succeed, a list of the item's attributes, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> <li> <p> <code>Update</code>  &#x97;   Initiates an <code>UpdateItem</code> operation to update an existing item. This structure specifies the primary key of the item to be updated, the name of the table where it resides, an optional condition expression that must be satisfied for the update to succeed, an expression that defines one or more attributes to be updated, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> <li> <p> <code>Delete</code>  &#x97;   Initiates a <code>DeleteItem</code> operation to delete an existing item. This structure specifies the primary key of the item to be deleted, the name of the table where it resides, an optional condition expression that must be satisfied for the deletion to succeed, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> <li> <p> <code>ConditionCheck</code>  &#x97;   Applies a condition to an item that is not being modified by the transaction. This structure specifies the primary key of the item to be checked, the name of the table where it resides, a condition expression that must be satisfied for the transaction to succeed, and a field indicating whether to retrieve the item's attributes if the condition is not met.</p> </li> </ul> <p>DynamoDB rejects the entire <code>TransactWriteItems</code> request if any of the following is true:</p> <ul> <li> <p>A condition in one of the condition expressions is not met.</p> </li> <li> <p>An ongoing operation is in the process of updating the same item.</p> </li> <li> <p>There is insufficient provisioned capacity for the transaction to be completed.</p> </li> <li> <p>An item size becomes too large (bigger than 400 KB), a local secondary index (LSI) becomes too large, or a similar validation error occurs because of changes made by the transaction.</p> </li> <li> <p>The aggregate size of the items in the transaction exceeds 4 MB.</p> </li> <li> <p>There is a user error, such as an invalid data format.</p> </li> </ul>
  ##   body: JObject (required)
  var body_773633 = newJObject()
  if body != nil:
    body_773633 = body
  result = call_773632.call(nil, nil, nil, nil, body_773633)

var transactWriteItems* = Call_TransactWriteItems_773619(
    name: "transactWriteItems", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.TransactWriteItems",
    validator: validate_TransactWriteItems_773620, base: "/",
    url: url_TransactWriteItems_773621, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_773634 = ref object of OpenApiRestCall_772597
proc url_UntagResource_773636(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_773635(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773637 = header.getOrDefault("X-Amz-Date")
  valid_773637 = validateParameter(valid_773637, JString, required = false,
                                 default = nil)
  if valid_773637 != nil:
    section.add "X-Amz-Date", valid_773637
  var valid_773638 = header.getOrDefault("X-Amz-Security-Token")
  valid_773638 = validateParameter(valid_773638, JString, required = false,
                                 default = nil)
  if valid_773638 != nil:
    section.add "X-Amz-Security-Token", valid_773638
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773639 = header.getOrDefault("X-Amz-Target")
  valid_773639 = validateParameter(valid_773639, JString, required = true, default = newJString(
      "DynamoDB_20120810.UntagResource"))
  if valid_773639 != nil:
    section.add "X-Amz-Target", valid_773639
  var valid_773640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773640 = validateParameter(valid_773640, JString, required = false,
                                 default = nil)
  if valid_773640 != nil:
    section.add "X-Amz-Content-Sha256", valid_773640
  var valid_773641 = header.getOrDefault("X-Amz-Algorithm")
  valid_773641 = validateParameter(valid_773641, JString, required = false,
                                 default = nil)
  if valid_773641 != nil:
    section.add "X-Amz-Algorithm", valid_773641
  var valid_773642 = header.getOrDefault("X-Amz-Signature")
  valid_773642 = validateParameter(valid_773642, JString, required = false,
                                 default = nil)
  if valid_773642 != nil:
    section.add "X-Amz-Signature", valid_773642
  var valid_773643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773643 = validateParameter(valid_773643, JString, required = false,
                                 default = nil)
  if valid_773643 != nil:
    section.add "X-Amz-SignedHeaders", valid_773643
  var valid_773644 = header.getOrDefault("X-Amz-Credential")
  valid_773644 = validateParameter(valid_773644, JString, required = false,
                                 default = nil)
  if valid_773644 != nil:
    section.add "X-Amz-Credential", valid_773644
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773646: Call_UntagResource_773634; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the association of tags from an Amazon DynamoDB resource. You can call <code>UntagResource</code> up to five times per second, per account. </p> <p>For an overview on tagging DynamoDB resources, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html">Tagging for DynamoDB</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
  ## 
  let valid = call_773646.validator(path, query, header, formData, body)
  let scheme = call_773646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773646.url(scheme.get, call_773646.host, call_773646.base,
                         call_773646.route, valid.getOrDefault("path"))
  result = hook(call_773646, url, valid)

proc call*(call_773647: Call_UntagResource_773634; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Removes the association of tags from an Amazon DynamoDB resource. You can call <code>UntagResource</code> up to five times per second, per account. </p> <p>For an overview on tagging DynamoDB resources, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html">Tagging for DynamoDB</a> in the <i>Amazon DynamoDB Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_773648 = newJObject()
  if body != nil:
    body_773648 = body
  result = call_773647.call(nil, nil, nil, nil, body_773648)

var untagResource* = Call_UntagResource_773634(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.UntagResource",
    validator: validate_UntagResource_773635, base: "/", url: url_UntagResource_773636,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContinuousBackups_773649 = ref object of OpenApiRestCall_772597
proc url_UpdateContinuousBackups_773651(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateContinuousBackups_773650(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773652 = header.getOrDefault("X-Amz-Date")
  valid_773652 = validateParameter(valid_773652, JString, required = false,
                                 default = nil)
  if valid_773652 != nil:
    section.add "X-Amz-Date", valid_773652
  var valid_773653 = header.getOrDefault("X-Amz-Security-Token")
  valid_773653 = validateParameter(valid_773653, JString, required = false,
                                 default = nil)
  if valid_773653 != nil:
    section.add "X-Amz-Security-Token", valid_773653
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773654 = header.getOrDefault("X-Amz-Target")
  valid_773654 = validateParameter(valid_773654, JString, required = true, default = newJString(
      "DynamoDB_20120810.UpdateContinuousBackups"))
  if valid_773654 != nil:
    section.add "X-Amz-Target", valid_773654
  var valid_773655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773655 = validateParameter(valid_773655, JString, required = false,
                                 default = nil)
  if valid_773655 != nil:
    section.add "X-Amz-Content-Sha256", valid_773655
  var valid_773656 = header.getOrDefault("X-Amz-Algorithm")
  valid_773656 = validateParameter(valid_773656, JString, required = false,
                                 default = nil)
  if valid_773656 != nil:
    section.add "X-Amz-Algorithm", valid_773656
  var valid_773657 = header.getOrDefault("X-Amz-Signature")
  valid_773657 = validateParameter(valid_773657, JString, required = false,
                                 default = nil)
  if valid_773657 != nil:
    section.add "X-Amz-Signature", valid_773657
  var valid_773658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773658 = validateParameter(valid_773658, JString, required = false,
                                 default = nil)
  if valid_773658 != nil:
    section.add "X-Amz-SignedHeaders", valid_773658
  var valid_773659 = header.getOrDefault("X-Amz-Credential")
  valid_773659 = validateParameter(valid_773659, JString, required = false,
                                 default = nil)
  if valid_773659 != nil:
    section.add "X-Amz-Credential", valid_773659
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773661: Call_UpdateContinuousBackups_773649; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>UpdateContinuousBackups</code> enables or disables point in time recovery for the specified table. A successful <code>UpdateContinuousBackups</code> call returns the current <code>ContinuousBackupsDescription</code>. Continuous backups are <code>ENABLED</code> on all tables at table creation. If point in time recovery is enabled, <code>PointInTimeRecoveryStatus</code> will be set to ENABLED.</p> <p> Once continuous backups and point in time recovery are enabled, you can restore to any point in time within <code>EarliestRestorableDateTime</code> and <code>LatestRestorableDateTime</code>. </p> <p> <code>LatestRestorableDateTime</code> is typically 5 minutes before the current time. You can restore your table to any point in time during the last 35 days. </p>
  ## 
  let valid = call_773661.validator(path, query, header, formData, body)
  let scheme = call_773661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773661.url(scheme.get, call_773661.host, call_773661.base,
                         call_773661.route, valid.getOrDefault("path"))
  result = hook(call_773661, url, valid)

proc call*(call_773662: Call_UpdateContinuousBackups_773649; body: JsonNode): Recallable =
  ## updateContinuousBackups
  ## <p> <code>UpdateContinuousBackups</code> enables or disables point in time recovery for the specified table. A successful <code>UpdateContinuousBackups</code> call returns the current <code>ContinuousBackupsDescription</code>. Continuous backups are <code>ENABLED</code> on all tables at table creation. If point in time recovery is enabled, <code>PointInTimeRecoveryStatus</code> will be set to ENABLED.</p> <p> Once continuous backups and point in time recovery are enabled, you can restore to any point in time within <code>EarliestRestorableDateTime</code> and <code>LatestRestorableDateTime</code>. </p> <p> <code>LatestRestorableDateTime</code> is typically 5 minutes before the current time. You can restore your table to any point in time during the last 35 days. </p>
  ##   body: JObject (required)
  var body_773663 = newJObject()
  if body != nil:
    body_773663 = body
  result = call_773662.call(nil, nil, nil, nil, body_773663)

var updateContinuousBackups* = Call_UpdateContinuousBackups_773649(
    name: "updateContinuousBackups", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.UpdateContinuousBackups",
    validator: validate_UpdateContinuousBackups_773650, base: "/",
    url: url_UpdateContinuousBackups_773651, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGlobalTable_773664 = ref object of OpenApiRestCall_772597
proc url_UpdateGlobalTable_773666(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateGlobalTable_773665(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773667 = header.getOrDefault("X-Amz-Date")
  valid_773667 = validateParameter(valid_773667, JString, required = false,
                                 default = nil)
  if valid_773667 != nil:
    section.add "X-Amz-Date", valid_773667
  var valid_773668 = header.getOrDefault("X-Amz-Security-Token")
  valid_773668 = validateParameter(valid_773668, JString, required = false,
                                 default = nil)
  if valid_773668 != nil:
    section.add "X-Amz-Security-Token", valid_773668
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773669 = header.getOrDefault("X-Amz-Target")
  valid_773669 = validateParameter(valid_773669, JString, required = true, default = newJString(
      "DynamoDB_20120810.UpdateGlobalTable"))
  if valid_773669 != nil:
    section.add "X-Amz-Target", valid_773669
  var valid_773670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773670 = validateParameter(valid_773670, JString, required = false,
                                 default = nil)
  if valid_773670 != nil:
    section.add "X-Amz-Content-Sha256", valid_773670
  var valid_773671 = header.getOrDefault("X-Amz-Algorithm")
  valid_773671 = validateParameter(valid_773671, JString, required = false,
                                 default = nil)
  if valid_773671 != nil:
    section.add "X-Amz-Algorithm", valid_773671
  var valid_773672 = header.getOrDefault("X-Amz-Signature")
  valid_773672 = validateParameter(valid_773672, JString, required = false,
                                 default = nil)
  if valid_773672 != nil:
    section.add "X-Amz-Signature", valid_773672
  var valid_773673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773673 = validateParameter(valid_773673, JString, required = false,
                                 default = nil)
  if valid_773673 != nil:
    section.add "X-Amz-SignedHeaders", valid_773673
  var valid_773674 = header.getOrDefault("X-Amz-Credential")
  valid_773674 = validateParameter(valid_773674, JString, required = false,
                                 default = nil)
  if valid_773674 != nil:
    section.add "X-Amz-Credential", valid_773674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773676: Call_UpdateGlobalTable_773664; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or removes replicas in the specified global table. The global table must already exist to be able to use this operation. Any replica to be added must be empty, have the same name as the global table, have the same key schema, have DynamoDB Streams enabled, and have the same provisioned and maximum write capacity units.</p> <note> <p>Although you can use <code>UpdateGlobalTable</code> to add replicas and remove replicas in a single request, for simplicity we recommend that you issue separate requests for adding or removing replicas.</p> </note> <p> If global secondary indexes are specified, then the following conditions must also be met: </p> <ul> <li> <p> The global secondary indexes must have the same name. </p> </li> <li> <p> The global secondary indexes must have the same hash key and sort key (if present). </p> </li> <li> <p> The global secondary indexes must have the same provisioned and maximum write capacity units. </p> </li> </ul>
  ## 
  let valid = call_773676.validator(path, query, header, formData, body)
  let scheme = call_773676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773676.url(scheme.get, call_773676.host, call_773676.base,
                         call_773676.route, valid.getOrDefault("path"))
  result = hook(call_773676, url, valid)

proc call*(call_773677: Call_UpdateGlobalTable_773664; body: JsonNode): Recallable =
  ## updateGlobalTable
  ## <p>Adds or removes replicas in the specified global table. The global table must already exist to be able to use this operation. Any replica to be added must be empty, have the same name as the global table, have the same key schema, have DynamoDB Streams enabled, and have the same provisioned and maximum write capacity units.</p> <note> <p>Although you can use <code>UpdateGlobalTable</code> to add replicas and remove replicas in a single request, for simplicity we recommend that you issue separate requests for adding or removing replicas.</p> </note> <p> If global secondary indexes are specified, then the following conditions must also be met: </p> <ul> <li> <p> The global secondary indexes must have the same name. </p> </li> <li> <p> The global secondary indexes must have the same hash key and sort key (if present). </p> </li> <li> <p> The global secondary indexes must have the same provisioned and maximum write capacity units. </p> </li> </ul>
  ##   body: JObject (required)
  var body_773678 = newJObject()
  if body != nil:
    body_773678 = body
  result = call_773677.call(nil, nil, nil, nil, body_773678)

var updateGlobalTable* = Call_UpdateGlobalTable_773664(name: "updateGlobalTable",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.UpdateGlobalTable",
    validator: validate_UpdateGlobalTable_773665, base: "/",
    url: url_UpdateGlobalTable_773666, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGlobalTableSettings_773679 = ref object of OpenApiRestCall_772597
proc url_UpdateGlobalTableSettings_773681(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateGlobalTableSettings_773680(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773682 = header.getOrDefault("X-Amz-Date")
  valid_773682 = validateParameter(valid_773682, JString, required = false,
                                 default = nil)
  if valid_773682 != nil:
    section.add "X-Amz-Date", valid_773682
  var valid_773683 = header.getOrDefault("X-Amz-Security-Token")
  valid_773683 = validateParameter(valid_773683, JString, required = false,
                                 default = nil)
  if valid_773683 != nil:
    section.add "X-Amz-Security-Token", valid_773683
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773684 = header.getOrDefault("X-Amz-Target")
  valid_773684 = validateParameter(valid_773684, JString, required = true, default = newJString(
      "DynamoDB_20120810.UpdateGlobalTableSettings"))
  if valid_773684 != nil:
    section.add "X-Amz-Target", valid_773684
  var valid_773685 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773685 = validateParameter(valid_773685, JString, required = false,
                                 default = nil)
  if valid_773685 != nil:
    section.add "X-Amz-Content-Sha256", valid_773685
  var valid_773686 = header.getOrDefault("X-Amz-Algorithm")
  valid_773686 = validateParameter(valid_773686, JString, required = false,
                                 default = nil)
  if valid_773686 != nil:
    section.add "X-Amz-Algorithm", valid_773686
  var valid_773687 = header.getOrDefault("X-Amz-Signature")
  valid_773687 = validateParameter(valid_773687, JString, required = false,
                                 default = nil)
  if valid_773687 != nil:
    section.add "X-Amz-Signature", valid_773687
  var valid_773688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773688 = validateParameter(valid_773688, JString, required = false,
                                 default = nil)
  if valid_773688 != nil:
    section.add "X-Amz-SignedHeaders", valid_773688
  var valid_773689 = header.getOrDefault("X-Amz-Credential")
  valid_773689 = validateParameter(valid_773689, JString, required = false,
                                 default = nil)
  if valid_773689 != nil:
    section.add "X-Amz-Credential", valid_773689
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773691: Call_UpdateGlobalTableSettings_773679; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates settings for a global table.
  ## 
  let valid = call_773691.validator(path, query, header, formData, body)
  let scheme = call_773691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773691.url(scheme.get, call_773691.host, call_773691.base,
                         call_773691.route, valid.getOrDefault("path"))
  result = hook(call_773691, url, valid)

proc call*(call_773692: Call_UpdateGlobalTableSettings_773679; body: JsonNode): Recallable =
  ## updateGlobalTableSettings
  ## Updates settings for a global table.
  ##   body: JObject (required)
  var body_773693 = newJObject()
  if body != nil:
    body_773693 = body
  result = call_773692.call(nil, nil, nil, nil, body_773693)

var updateGlobalTableSettings* = Call_UpdateGlobalTableSettings_773679(
    name: "updateGlobalTableSettings", meth: HttpMethod.HttpPost,
    host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.UpdateGlobalTableSettings",
    validator: validate_UpdateGlobalTableSettings_773680, base: "/",
    url: url_UpdateGlobalTableSettings_773681,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateItem_773694 = ref object of OpenApiRestCall_772597
proc url_UpdateItem_773696(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateItem_773695(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773697 = header.getOrDefault("X-Amz-Date")
  valid_773697 = validateParameter(valid_773697, JString, required = false,
                                 default = nil)
  if valid_773697 != nil:
    section.add "X-Amz-Date", valid_773697
  var valid_773698 = header.getOrDefault("X-Amz-Security-Token")
  valid_773698 = validateParameter(valid_773698, JString, required = false,
                                 default = nil)
  if valid_773698 != nil:
    section.add "X-Amz-Security-Token", valid_773698
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773699 = header.getOrDefault("X-Amz-Target")
  valid_773699 = validateParameter(valid_773699, JString, required = true, default = newJString(
      "DynamoDB_20120810.UpdateItem"))
  if valid_773699 != nil:
    section.add "X-Amz-Target", valid_773699
  var valid_773700 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773700 = validateParameter(valid_773700, JString, required = false,
                                 default = nil)
  if valid_773700 != nil:
    section.add "X-Amz-Content-Sha256", valid_773700
  var valid_773701 = header.getOrDefault("X-Amz-Algorithm")
  valid_773701 = validateParameter(valid_773701, JString, required = false,
                                 default = nil)
  if valid_773701 != nil:
    section.add "X-Amz-Algorithm", valid_773701
  var valid_773702 = header.getOrDefault("X-Amz-Signature")
  valid_773702 = validateParameter(valid_773702, JString, required = false,
                                 default = nil)
  if valid_773702 != nil:
    section.add "X-Amz-Signature", valid_773702
  var valid_773703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773703 = validateParameter(valid_773703, JString, required = false,
                                 default = nil)
  if valid_773703 != nil:
    section.add "X-Amz-SignedHeaders", valid_773703
  var valid_773704 = header.getOrDefault("X-Amz-Credential")
  valid_773704 = validateParameter(valid_773704, JString, required = false,
                                 default = nil)
  if valid_773704 != nil:
    section.add "X-Amz-Credential", valid_773704
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773706: Call_UpdateItem_773694; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Edits an existing item's attributes, or adds a new item to the table if it does not already exist. You can put, delete, or add attribute values. You can also perform a conditional update on an existing item (insert a new attribute name-value pair if it doesn't exist, or replace an existing name-value pair if it has certain expected attribute values).</p> <p>You can also return the item's attribute values in the same <code>UpdateItem</code> operation using the <code>ReturnValues</code> parameter.</p>
  ## 
  let valid = call_773706.validator(path, query, header, formData, body)
  let scheme = call_773706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773706.url(scheme.get, call_773706.host, call_773706.base,
                         call_773706.route, valid.getOrDefault("path"))
  result = hook(call_773706, url, valid)

proc call*(call_773707: Call_UpdateItem_773694; body: JsonNode): Recallable =
  ## updateItem
  ## <p>Edits an existing item's attributes, or adds a new item to the table if it does not already exist. You can put, delete, or add attribute values. You can also perform a conditional update on an existing item (insert a new attribute name-value pair if it doesn't exist, or replace an existing name-value pair if it has certain expected attribute values).</p> <p>You can also return the item's attribute values in the same <code>UpdateItem</code> operation using the <code>ReturnValues</code> parameter.</p>
  ##   body: JObject (required)
  var body_773708 = newJObject()
  if body != nil:
    body_773708 = body
  result = call_773707.call(nil, nil, nil, nil, body_773708)

var updateItem* = Call_UpdateItem_773694(name: "updateItem",
                                      meth: HttpMethod.HttpPost,
                                      host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20120810.UpdateItem",
                                      validator: validate_UpdateItem_773695,
                                      base: "/", url: url_UpdateItem_773696,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTable_773709 = ref object of OpenApiRestCall_772597
proc url_UpdateTable_773711(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateTable_773710(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773712 = header.getOrDefault("X-Amz-Date")
  valid_773712 = validateParameter(valid_773712, JString, required = false,
                                 default = nil)
  if valid_773712 != nil:
    section.add "X-Amz-Date", valid_773712
  var valid_773713 = header.getOrDefault("X-Amz-Security-Token")
  valid_773713 = validateParameter(valid_773713, JString, required = false,
                                 default = nil)
  if valid_773713 != nil:
    section.add "X-Amz-Security-Token", valid_773713
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773714 = header.getOrDefault("X-Amz-Target")
  valid_773714 = validateParameter(valid_773714, JString, required = true, default = newJString(
      "DynamoDB_20120810.UpdateTable"))
  if valid_773714 != nil:
    section.add "X-Amz-Target", valid_773714
  var valid_773715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773715 = validateParameter(valid_773715, JString, required = false,
                                 default = nil)
  if valid_773715 != nil:
    section.add "X-Amz-Content-Sha256", valid_773715
  var valid_773716 = header.getOrDefault("X-Amz-Algorithm")
  valid_773716 = validateParameter(valid_773716, JString, required = false,
                                 default = nil)
  if valid_773716 != nil:
    section.add "X-Amz-Algorithm", valid_773716
  var valid_773717 = header.getOrDefault("X-Amz-Signature")
  valid_773717 = validateParameter(valid_773717, JString, required = false,
                                 default = nil)
  if valid_773717 != nil:
    section.add "X-Amz-Signature", valid_773717
  var valid_773718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773718 = validateParameter(valid_773718, JString, required = false,
                                 default = nil)
  if valid_773718 != nil:
    section.add "X-Amz-SignedHeaders", valid_773718
  var valid_773719 = header.getOrDefault("X-Amz-Credential")
  valid_773719 = validateParameter(valid_773719, JString, required = false,
                                 default = nil)
  if valid_773719 != nil:
    section.add "X-Amz-Credential", valid_773719
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773721: Call_UpdateTable_773709; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the provisioned throughput settings, global secondary indexes, or DynamoDB Streams settings for a given table.</p> <p>You can only perform one of the following operations at once:</p> <ul> <li> <p>Modify the provisioned throughput settings of the table.</p> </li> <li> <p>Enable or disable DynamoDB Streams on the table.</p> </li> <li> <p>Remove a global secondary index from the table.</p> </li> <li> <p>Create a new global secondary index on the table. After the index begins backfilling, you can use <code>UpdateTable</code> to perform other operations.</p> </li> </ul> <p> <code>UpdateTable</code> is an asynchronous operation; while it is executing, the table status changes from <code>ACTIVE</code> to <code>UPDATING</code>. While it is <code>UPDATING</code>, you cannot issue another <code>UpdateTable</code> request. When the table returns to the <code>ACTIVE</code> state, the <code>UpdateTable</code> operation is complete.</p>
  ## 
  let valid = call_773721.validator(path, query, header, formData, body)
  let scheme = call_773721.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773721.url(scheme.get, call_773721.host, call_773721.base,
                         call_773721.route, valid.getOrDefault("path"))
  result = hook(call_773721, url, valid)

proc call*(call_773722: Call_UpdateTable_773709; body: JsonNode): Recallable =
  ## updateTable
  ## <p>Modifies the provisioned throughput settings, global secondary indexes, or DynamoDB Streams settings for a given table.</p> <p>You can only perform one of the following operations at once:</p> <ul> <li> <p>Modify the provisioned throughput settings of the table.</p> </li> <li> <p>Enable or disable DynamoDB Streams on the table.</p> </li> <li> <p>Remove a global secondary index from the table.</p> </li> <li> <p>Create a new global secondary index on the table. After the index begins backfilling, you can use <code>UpdateTable</code> to perform other operations.</p> </li> </ul> <p> <code>UpdateTable</code> is an asynchronous operation; while it is executing, the table status changes from <code>ACTIVE</code> to <code>UPDATING</code>. While it is <code>UPDATING</code>, you cannot issue another <code>UpdateTable</code> request. When the table returns to the <code>ACTIVE</code> state, the <code>UpdateTable</code> operation is complete.</p>
  ##   body: JObject (required)
  var body_773723 = newJObject()
  if body != nil:
    body_773723 = body
  result = call_773722.call(nil, nil, nil, nil, body_773723)

var updateTable* = Call_UpdateTable_773709(name: "updateTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "dynamodb.amazonaws.com", route: "/#X-Amz-Target=DynamoDB_20120810.UpdateTable",
                                        validator: validate_UpdateTable_773710,
                                        base: "/", url: url_UpdateTable_773711,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTimeToLive_773724 = ref object of OpenApiRestCall_772597
proc url_UpdateTimeToLive_773726(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateTimeToLive_773725(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773727 = header.getOrDefault("X-Amz-Date")
  valid_773727 = validateParameter(valid_773727, JString, required = false,
                                 default = nil)
  if valid_773727 != nil:
    section.add "X-Amz-Date", valid_773727
  var valid_773728 = header.getOrDefault("X-Amz-Security-Token")
  valid_773728 = validateParameter(valid_773728, JString, required = false,
                                 default = nil)
  if valid_773728 != nil:
    section.add "X-Amz-Security-Token", valid_773728
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773729 = header.getOrDefault("X-Amz-Target")
  valid_773729 = validateParameter(valid_773729, JString, required = true, default = newJString(
      "DynamoDB_20120810.UpdateTimeToLive"))
  if valid_773729 != nil:
    section.add "X-Amz-Target", valid_773729
  var valid_773730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773730 = validateParameter(valid_773730, JString, required = false,
                                 default = nil)
  if valid_773730 != nil:
    section.add "X-Amz-Content-Sha256", valid_773730
  var valid_773731 = header.getOrDefault("X-Amz-Algorithm")
  valid_773731 = validateParameter(valid_773731, JString, required = false,
                                 default = nil)
  if valid_773731 != nil:
    section.add "X-Amz-Algorithm", valid_773731
  var valid_773732 = header.getOrDefault("X-Amz-Signature")
  valid_773732 = validateParameter(valid_773732, JString, required = false,
                                 default = nil)
  if valid_773732 != nil:
    section.add "X-Amz-Signature", valid_773732
  var valid_773733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773733 = validateParameter(valid_773733, JString, required = false,
                                 default = nil)
  if valid_773733 != nil:
    section.add "X-Amz-SignedHeaders", valid_773733
  var valid_773734 = header.getOrDefault("X-Amz-Credential")
  valid_773734 = validateParameter(valid_773734, JString, required = false,
                                 default = nil)
  if valid_773734 != nil:
    section.add "X-Amz-Credential", valid_773734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773736: Call_UpdateTimeToLive_773724; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>UpdateTimeToLive</code> method enables or disables Time to Live (TTL) for the specified table. A successful <code>UpdateTimeToLive</code> call returns the current <code>TimeToLiveSpecification</code>. It can take up to one hour for the change to fully process. Any additional <code>UpdateTimeToLive</code> calls for the same table during this one hour duration result in a <code>ValidationException</code>. </p> <p>TTL compares the current time in epoch time format to the time stored in the TTL attribute of an item. If the epoch time value stored in the attribute is less than the current time, the item is marked as expired and subsequently deleted.</p> <note> <p> The epoch time format is the number of seconds elapsed since 12:00:00 AM January 1, 1970 UTC. </p> </note> <p>DynamoDB deletes expired items on a best-effort basis to ensure availability of throughput for other data operations. </p> <important> <p>DynamoDB typically deletes expired items within two days of expiration. The exact duration within which an item gets deleted after expiration is specific to the nature of the workload. Items that have expired and not been deleted will still show up in reads, queries, and scans.</p> </important> <p>As items are deleted, they are removed from any local secondary index and global secondary index immediately in the same eventually consistent way as a standard delete operation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/TTL.html">Time To Live</a> in the Amazon DynamoDB Developer Guide. </p>
  ## 
  let valid = call_773736.validator(path, query, header, formData, body)
  let scheme = call_773736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773736.url(scheme.get, call_773736.host, call_773736.base,
                         call_773736.route, valid.getOrDefault("path"))
  result = hook(call_773736, url, valid)

proc call*(call_773737: Call_UpdateTimeToLive_773724; body: JsonNode): Recallable =
  ## updateTimeToLive
  ## <p>The <code>UpdateTimeToLive</code> method enables or disables Time to Live (TTL) for the specified table. A successful <code>UpdateTimeToLive</code> call returns the current <code>TimeToLiveSpecification</code>. It can take up to one hour for the change to fully process. Any additional <code>UpdateTimeToLive</code> calls for the same table during this one hour duration result in a <code>ValidationException</code>. </p> <p>TTL compares the current time in epoch time format to the time stored in the TTL attribute of an item. If the epoch time value stored in the attribute is less than the current time, the item is marked as expired and subsequently deleted.</p> <note> <p> The epoch time format is the number of seconds elapsed since 12:00:00 AM January 1, 1970 UTC. </p> </note> <p>DynamoDB deletes expired items on a best-effort basis to ensure availability of throughput for other data operations. </p> <important> <p>DynamoDB typically deletes expired items within two days of expiration. The exact duration within which an item gets deleted after expiration is specific to the nature of the workload. Items that have expired and not been deleted will still show up in reads, queries, and scans.</p> </important> <p>As items are deleted, they are removed from any local secondary index and global secondary index immediately in the same eventually consistent way as a standard delete operation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/TTL.html">Time To Live</a> in the Amazon DynamoDB Developer Guide. </p>
  ##   body: JObject (required)
  var body_773738 = newJObject()
  if body != nil:
    body_773738 = body
  result = call_773737.call(nil, nil, nil, nil, body_773738)

var updateTimeToLive* = Call_UpdateTimeToLive_773724(name: "updateTimeToLive",
    meth: HttpMethod.HttpPost, host: "dynamodb.amazonaws.com",
    route: "/#X-Amz-Target=DynamoDB_20120810.UpdateTimeToLive",
    validator: validate_UpdateTimeToLive_773725, base: "/",
    url: url_UpdateTimeToLive_773726, schemes: {Scheme.Https, Scheme.Http})
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
