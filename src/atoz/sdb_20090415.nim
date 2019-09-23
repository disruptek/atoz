
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon SimpleDB
## version: 2009-04-15
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Amazon SimpleDB is a web service providing the core database functions of data indexing and querying in the cloud. By offloading the time and effort associated with building and operating a web-scale database, SimpleDB provides developers the freedom to focus on application development. <p> A traditional, clustered relational database requires a sizable upfront capital outlay, is complex to design, and often requires extensive and repetitive database administration. Amazon SimpleDB is dramatically simpler, requiring no schema, automatically indexing your data and providing a simple API for storage and access. This approach eliminates the administrative burden of data modeling, index maintenance, and performance tuning. Developers gain access to this functionality within Amazon's proven computing environment, are able to scale instantly, and pay only for what they use. </p> <p> Visit <a href="http://aws.amazon.com/simpledb/">http://aws.amazon.com/simpledb/</a> for more information. </p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/sdb/
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

  OpenApiRestCall_600421 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600421](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600421): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

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
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "sdb.ap-northeast-1.amazonaws.com", "ap-southeast-1": "sdb.ap-southeast-1.amazonaws.com",
                           "us-west-2": "sdb.us-west-2.amazonaws.com",
                           "eu-west-2": "sdb.eu-west-2.amazonaws.com", "ap-northeast-3": "sdb.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "sdb.eu-central-1.amazonaws.com",
                           "us-east-2": "sdb.us-east-2.amazonaws.com", "cn-northwest-1": "sdb.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "sdb.ap-south-1.amazonaws.com",
                           "eu-north-1": "sdb.eu-north-1.amazonaws.com", "ap-northeast-2": "sdb.ap-northeast-2.amazonaws.com",
                           "us-west-1": "sdb.us-west-1.amazonaws.com",
                           "us-gov-east-1": "sdb.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "sdb.eu-west-3.amazonaws.com",
                           "cn-north-1": "sdb.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "sdb.sa-east-1.amazonaws.com",
                           "eu-west-1": "sdb.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "sdb.us-gov-west-1.amazonaws.com", "ap-southeast-2": "sdb.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "sdb.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "sdb.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "sdb.ap-southeast-1.amazonaws.com",
      "us-west-2": "sdb.us-west-2.amazonaws.com",
      "eu-west-2": "sdb.eu-west-2.amazonaws.com",
      "ap-northeast-3": "sdb.ap-northeast-3.amazonaws.com",
      "eu-central-1": "sdb.eu-central-1.amazonaws.com",
      "us-east-2": "sdb.us-east-2.amazonaws.com",
      "cn-northwest-1": "sdb.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "sdb.ap-south-1.amazonaws.com",
      "eu-north-1": "sdb.eu-north-1.amazonaws.com",
      "ap-northeast-2": "sdb.ap-northeast-2.amazonaws.com",
      "us-west-1": "sdb.us-west-1.amazonaws.com",
      "us-gov-east-1": "sdb.us-gov-east-1.amazonaws.com",
      "eu-west-3": "sdb.eu-west-3.amazonaws.com",
      "cn-north-1": "sdb.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "sdb.sa-east-1.amazonaws.com",
      "eu-west-1": "sdb.eu-west-1.amazonaws.com",
      "us-gov-west-1": "sdb.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "sdb.ap-southeast-2.amazonaws.com",
      "ca-central-1": "sdb.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "sdb"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostBatchDeleteAttributes_601028 = ref object of OpenApiRestCall_600421
proc url_PostBatchDeleteAttributes_601030(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostBatchDeleteAttributes_601029(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_601031 = query.getOrDefault("SignatureMethod")
  valid_601031 = validateParameter(valid_601031, JString, required = true,
                                 default = nil)
  if valid_601031 != nil:
    section.add "SignatureMethod", valid_601031
  var valid_601032 = query.getOrDefault("Signature")
  valid_601032 = validateParameter(valid_601032, JString, required = true,
                                 default = nil)
  if valid_601032 != nil:
    section.add "Signature", valid_601032
  var valid_601033 = query.getOrDefault("Action")
  valid_601033 = validateParameter(valid_601033, JString, required = true,
                                 default = newJString("BatchDeleteAttributes"))
  if valid_601033 != nil:
    section.add "Action", valid_601033
  var valid_601034 = query.getOrDefault("Timestamp")
  valid_601034 = validateParameter(valid_601034, JString, required = true,
                                 default = nil)
  if valid_601034 != nil:
    section.add "Timestamp", valid_601034
  var valid_601035 = query.getOrDefault("SignatureVersion")
  valid_601035 = validateParameter(valid_601035, JString, required = true,
                                 default = nil)
  if valid_601035 != nil:
    section.add "SignatureVersion", valid_601035
  var valid_601036 = query.getOrDefault("AWSAccessKeyId")
  valid_601036 = validateParameter(valid_601036, JString, required = true,
                                 default = nil)
  if valid_601036 != nil:
    section.add "AWSAccessKeyId", valid_601036
  var valid_601037 = query.getOrDefault("Version")
  valid_601037 = validateParameter(valid_601037, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601037 != nil:
    section.add "Version", valid_601037
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain in which the attributes are being deleted.
  ##   Items: JArray (required)
  ##        : A list of items on which to perform the operation.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601038 = formData.getOrDefault("DomainName")
  valid_601038 = validateParameter(valid_601038, JString, required = true,
                                 default = nil)
  if valid_601038 != nil:
    section.add "DomainName", valid_601038
  var valid_601039 = formData.getOrDefault("Items")
  valid_601039 = validateParameter(valid_601039, JArray, required = true, default = nil)
  if valid_601039 != nil:
    section.add "Items", valid_601039
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601040: Call_PostBatchDeleteAttributes_601028; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  let valid = call_601040.validator(path, query, header, formData, body)
  let scheme = call_601040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601040.url(scheme.get, call_601040.host, call_601040.base,
                         call_601040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601040, url, valid)

proc call*(call_601041: Call_PostBatchDeleteAttributes_601028;
          SignatureMethod: string; DomainName: string; Signature: string;
          Timestamp: string; Items: JsonNode; SignatureVersion: string;
          AWSAccessKeyId: string; Action: string = "BatchDeleteAttributes";
          Version: string = "2009-04-15"): Recallable =
  ## postBatchDeleteAttributes
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain in which the attributes are being deleted.
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   Items: JArray (required)
  ##        : A list of items on which to perform the operation.
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_601042 = newJObject()
  var formData_601043 = newJObject()
  add(query_601042, "SignatureMethod", newJString(SignatureMethod))
  add(formData_601043, "DomainName", newJString(DomainName))
  add(query_601042, "Signature", newJString(Signature))
  add(query_601042, "Action", newJString(Action))
  add(query_601042, "Timestamp", newJString(Timestamp))
  if Items != nil:
    formData_601043.add "Items", Items
  add(query_601042, "SignatureVersion", newJString(SignatureVersion))
  add(query_601042, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601042, "Version", newJString(Version))
  result = call_601041.call(nil, query_601042, nil, formData_601043, nil)

var postBatchDeleteAttributes* = Call_PostBatchDeleteAttributes_601028(
    name: "postBatchDeleteAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=BatchDeleteAttributes",
    validator: validate_PostBatchDeleteAttributes_601029, base: "/",
    url: url_PostBatchDeleteAttributes_601030,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBatchDeleteAttributes_600758 = ref object of OpenApiRestCall_600421
proc url_GetBatchDeleteAttributes_600760(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBatchDeleteAttributes_600759(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   Items: JArray (required)
  ##        : A list of items on which to perform the operation.
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   DomainName: JString (required)
  ##             : The name of the domain in which the attributes are being deleted.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_600872 = query.getOrDefault("SignatureMethod")
  valid_600872 = validateParameter(valid_600872, JString, required = true,
                                 default = nil)
  if valid_600872 != nil:
    section.add "SignatureMethod", valid_600872
  var valid_600873 = query.getOrDefault("Signature")
  valid_600873 = validateParameter(valid_600873, JString, required = true,
                                 default = nil)
  if valid_600873 != nil:
    section.add "Signature", valid_600873
  var valid_600887 = query.getOrDefault("Action")
  valid_600887 = validateParameter(valid_600887, JString, required = true,
                                 default = newJString("BatchDeleteAttributes"))
  if valid_600887 != nil:
    section.add "Action", valid_600887
  var valid_600888 = query.getOrDefault("Timestamp")
  valid_600888 = validateParameter(valid_600888, JString, required = true,
                                 default = nil)
  if valid_600888 != nil:
    section.add "Timestamp", valid_600888
  var valid_600889 = query.getOrDefault("Items")
  valid_600889 = validateParameter(valid_600889, JArray, required = true, default = nil)
  if valid_600889 != nil:
    section.add "Items", valid_600889
  var valid_600890 = query.getOrDefault("SignatureVersion")
  valid_600890 = validateParameter(valid_600890, JString, required = true,
                                 default = nil)
  if valid_600890 != nil:
    section.add "SignatureVersion", valid_600890
  var valid_600891 = query.getOrDefault("AWSAccessKeyId")
  valid_600891 = validateParameter(valid_600891, JString, required = true,
                                 default = nil)
  if valid_600891 != nil:
    section.add "AWSAccessKeyId", valid_600891
  var valid_600892 = query.getOrDefault("DomainName")
  valid_600892 = validateParameter(valid_600892, JString, required = true,
                                 default = nil)
  if valid_600892 != nil:
    section.add "DomainName", valid_600892
  var valid_600893 = query.getOrDefault("Version")
  valid_600893 = validateParameter(valid_600893, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_600893 != nil:
    section.add "Version", valid_600893
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600916: Call_GetBatchDeleteAttributes_600758; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  let valid = call_600916.validator(path, query, header, formData, body)
  let scheme = call_600916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600916.url(scheme.get, call_600916.host, call_600916.base,
                         call_600916.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600916, url, valid)

proc call*(call_600987: Call_GetBatchDeleteAttributes_600758;
          SignatureMethod: string; Signature: string; Timestamp: string;
          Items: JsonNode; SignatureVersion: string; AWSAccessKeyId: string;
          DomainName: string; Action: string = "BatchDeleteAttributes";
          Version: string = "2009-04-15"): Recallable =
  ## getBatchDeleteAttributes
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ##   SignatureMethod: string (required)
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   Items: JArray (required)
  ##        : A list of items on which to perform the operation.
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain in which the attributes are being deleted.
  ##   Version: string (required)
  var query_600988 = newJObject()
  add(query_600988, "SignatureMethod", newJString(SignatureMethod))
  add(query_600988, "Signature", newJString(Signature))
  add(query_600988, "Action", newJString(Action))
  add(query_600988, "Timestamp", newJString(Timestamp))
  if Items != nil:
    query_600988.add "Items", Items
  add(query_600988, "SignatureVersion", newJString(SignatureVersion))
  add(query_600988, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600988, "DomainName", newJString(DomainName))
  add(query_600988, "Version", newJString(Version))
  result = call_600987.call(nil, query_600988, nil, nil, nil)

var getBatchDeleteAttributes* = Call_GetBatchDeleteAttributes_600758(
    name: "getBatchDeleteAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=BatchDeleteAttributes",
    validator: validate_GetBatchDeleteAttributes_600759, base: "/",
    url: url_GetBatchDeleteAttributes_600760, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostBatchPutAttributes_601059 = ref object of OpenApiRestCall_600421
proc url_PostBatchPutAttributes_601061(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostBatchPutAttributes_601060(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_601062 = query.getOrDefault("SignatureMethod")
  valid_601062 = validateParameter(valid_601062, JString, required = true,
                                 default = nil)
  if valid_601062 != nil:
    section.add "SignatureMethod", valid_601062
  var valid_601063 = query.getOrDefault("Signature")
  valid_601063 = validateParameter(valid_601063, JString, required = true,
                                 default = nil)
  if valid_601063 != nil:
    section.add "Signature", valid_601063
  var valid_601064 = query.getOrDefault("Action")
  valid_601064 = validateParameter(valid_601064, JString, required = true,
                                 default = newJString("BatchPutAttributes"))
  if valid_601064 != nil:
    section.add "Action", valid_601064
  var valid_601065 = query.getOrDefault("Timestamp")
  valid_601065 = validateParameter(valid_601065, JString, required = true,
                                 default = nil)
  if valid_601065 != nil:
    section.add "Timestamp", valid_601065
  var valid_601066 = query.getOrDefault("SignatureVersion")
  valid_601066 = validateParameter(valid_601066, JString, required = true,
                                 default = nil)
  if valid_601066 != nil:
    section.add "SignatureVersion", valid_601066
  var valid_601067 = query.getOrDefault("AWSAccessKeyId")
  valid_601067 = validateParameter(valid_601067, JString, required = true,
                                 default = nil)
  if valid_601067 != nil:
    section.add "AWSAccessKeyId", valid_601067
  var valid_601068 = query.getOrDefault("Version")
  valid_601068 = validateParameter(valid_601068, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601068 != nil:
    section.add "Version", valid_601068
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain in which the attributes are being stored.
  ##   Items: JArray (required)
  ##        : A list of items on which to perform the operation.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601069 = formData.getOrDefault("DomainName")
  valid_601069 = validateParameter(valid_601069, JString, required = true,
                                 default = nil)
  if valid_601069 != nil:
    section.add "DomainName", valid_601069
  var valid_601070 = formData.getOrDefault("Items")
  valid_601070 = validateParameter(valid_601070, JArray, required = true, default = nil)
  if valid_601070 != nil:
    section.add "Items", valid_601070
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601071: Call_PostBatchPutAttributes_601059; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  let valid = call_601071.validator(path, query, header, formData, body)
  let scheme = call_601071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601071.url(scheme.get, call_601071.host, call_601071.base,
                         call_601071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601071, url, valid)

proc call*(call_601072: Call_PostBatchPutAttributes_601059;
          SignatureMethod: string; DomainName: string; Signature: string;
          Timestamp: string; Items: JsonNode; SignatureVersion: string;
          AWSAccessKeyId: string; Action: string = "BatchPutAttributes";
          Version: string = "2009-04-15"): Recallable =
  ## postBatchPutAttributes
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain in which the attributes are being stored.
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   Items: JArray (required)
  ##        : A list of items on which to perform the operation.
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_601073 = newJObject()
  var formData_601074 = newJObject()
  add(query_601073, "SignatureMethod", newJString(SignatureMethod))
  add(formData_601074, "DomainName", newJString(DomainName))
  add(query_601073, "Signature", newJString(Signature))
  add(query_601073, "Action", newJString(Action))
  add(query_601073, "Timestamp", newJString(Timestamp))
  if Items != nil:
    formData_601074.add "Items", Items
  add(query_601073, "SignatureVersion", newJString(SignatureVersion))
  add(query_601073, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601073, "Version", newJString(Version))
  result = call_601072.call(nil, query_601073, nil, formData_601074, nil)

var postBatchPutAttributes* = Call_PostBatchPutAttributes_601059(
    name: "postBatchPutAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=BatchPutAttributes",
    validator: validate_PostBatchPutAttributes_601060, base: "/",
    url: url_PostBatchPutAttributes_601061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBatchPutAttributes_601044 = ref object of OpenApiRestCall_600421
proc url_GetBatchPutAttributes_601046(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBatchPutAttributes_601045(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   Items: JArray (required)
  ##        : A list of items on which to perform the operation.
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   DomainName: JString (required)
  ##             : The name of the domain in which the attributes are being stored.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_601047 = query.getOrDefault("SignatureMethod")
  valid_601047 = validateParameter(valid_601047, JString, required = true,
                                 default = nil)
  if valid_601047 != nil:
    section.add "SignatureMethod", valid_601047
  var valid_601048 = query.getOrDefault("Signature")
  valid_601048 = validateParameter(valid_601048, JString, required = true,
                                 default = nil)
  if valid_601048 != nil:
    section.add "Signature", valid_601048
  var valid_601049 = query.getOrDefault("Action")
  valid_601049 = validateParameter(valid_601049, JString, required = true,
                                 default = newJString("BatchPutAttributes"))
  if valid_601049 != nil:
    section.add "Action", valid_601049
  var valid_601050 = query.getOrDefault("Timestamp")
  valid_601050 = validateParameter(valid_601050, JString, required = true,
                                 default = nil)
  if valid_601050 != nil:
    section.add "Timestamp", valid_601050
  var valid_601051 = query.getOrDefault("Items")
  valid_601051 = validateParameter(valid_601051, JArray, required = true, default = nil)
  if valid_601051 != nil:
    section.add "Items", valid_601051
  var valid_601052 = query.getOrDefault("SignatureVersion")
  valid_601052 = validateParameter(valid_601052, JString, required = true,
                                 default = nil)
  if valid_601052 != nil:
    section.add "SignatureVersion", valid_601052
  var valid_601053 = query.getOrDefault("AWSAccessKeyId")
  valid_601053 = validateParameter(valid_601053, JString, required = true,
                                 default = nil)
  if valid_601053 != nil:
    section.add "AWSAccessKeyId", valid_601053
  var valid_601054 = query.getOrDefault("DomainName")
  valid_601054 = validateParameter(valid_601054, JString, required = true,
                                 default = nil)
  if valid_601054 != nil:
    section.add "DomainName", valid_601054
  var valid_601055 = query.getOrDefault("Version")
  valid_601055 = validateParameter(valid_601055, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601055 != nil:
    section.add "Version", valid_601055
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601056: Call_GetBatchPutAttributes_601044; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  let valid = call_601056.validator(path, query, header, formData, body)
  let scheme = call_601056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601056.url(scheme.get, call_601056.host, call_601056.base,
                         call_601056.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601056, url, valid)

proc call*(call_601057: Call_GetBatchPutAttributes_601044; SignatureMethod: string;
          Signature: string; Timestamp: string; Items: JsonNode;
          SignatureVersion: string; AWSAccessKeyId: string; DomainName: string;
          Action: string = "BatchPutAttributes"; Version: string = "2009-04-15"): Recallable =
  ## getBatchPutAttributes
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ##   SignatureMethod: string (required)
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   Items: JArray (required)
  ##        : A list of items on which to perform the operation.
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain in which the attributes are being stored.
  ##   Version: string (required)
  var query_601058 = newJObject()
  add(query_601058, "SignatureMethod", newJString(SignatureMethod))
  add(query_601058, "Signature", newJString(Signature))
  add(query_601058, "Action", newJString(Action))
  add(query_601058, "Timestamp", newJString(Timestamp))
  if Items != nil:
    query_601058.add "Items", Items
  add(query_601058, "SignatureVersion", newJString(SignatureVersion))
  add(query_601058, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601058, "DomainName", newJString(DomainName))
  add(query_601058, "Version", newJString(Version))
  result = call_601057.call(nil, query_601058, nil, nil, nil)

var getBatchPutAttributes* = Call_GetBatchPutAttributes_601044(
    name: "getBatchPutAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=BatchPutAttributes",
    validator: validate_GetBatchPutAttributes_601045, base: "/",
    url: url_GetBatchPutAttributes_601046, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDomain_601089 = ref object of OpenApiRestCall_600421
proc url_PostCreateDomain_601091(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDomain_601090(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_601092 = query.getOrDefault("SignatureMethod")
  valid_601092 = validateParameter(valid_601092, JString, required = true,
                                 default = nil)
  if valid_601092 != nil:
    section.add "SignatureMethod", valid_601092
  var valid_601093 = query.getOrDefault("Signature")
  valid_601093 = validateParameter(valid_601093, JString, required = true,
                                 default = nil)
  if valid_601093 != nil:
    section.add "Signature", valid_601093
  var valid_601094 = query.getOrDefault("Action")
  valid_601094 = validateParameter(valid_601094, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_601094 != nil:
    section.add "Action", valid_601094
  var valid_601095 = query.getOrDefault("Timestamp")
  valid_601095 = validateParameter(valid_601095, JString, required = true,
                                 default = nil)
  if valid_601095 != nil:
    section.add "Timestamp", valid_601095
  var valid_601096 = query.getOrDefault("SignatureVersion")
  valid_601096 = validateParameter(valid_601096, JString, required = true,
                                 default = nil)
  if valid_601096 != nil:
    section.add "SignatureVersion", valid_601096
  var valid_601097 = query.getOrDefault("AWSAccessKeyId")
  valid_601097 = validateParameter(valid_601097, JString, required = true,
                                 default = nil)
  if valid_601097 != nil:
    section.add "AWSAccessKeyId", valid_601097
  var valid_601098 = query.getOrDefault("Version")
  valid_601098 = validateParameter(valid_601098, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601098 != nil:
    section.add "Version", valid_601098
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain to create. The name can range between 3 and 255 characters and can contain the following characters: a-z, A-Z, 0-9, '_', '-', and '.'.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601099 = formData.getOrDefault("DomainName")
  valid_601099 = validateParameter(valid_601099, JString, required = true,
                                 default = nil)
  if valid_601099 != nil:
    section.add "DomainName", valid_601099
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601100: Call_PostCreateDomain_601089; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  let valid = call_601100.validator(path, query, header, formData, body)
  let scheme = call_601100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601100.url(scheme.get, call_601100.host, call_601100.base,
                         call_601100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601100, url, valid)

proc call*(call_601101: Call_PostCreateDomain_601089; SignatureMethod: string;
          DomainName: string; Signature: string; Timestamp: string;
          SignatureVersion: string; AWSAccessKeyId: string;
          Action: string = "CreateDomain"; Version: string = "2009-04-15"): Recallable =
  ## postCreateDomain
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain to create. The name can range between 3 and 255 characters and can contain the following characters: a-z, A-Z, 0-9, '_', '-', and '.'.
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_601102 = newJObject()
  var formData_601103 = newJObject()
  add(query_601102, "SignatureMethod", newJString(SignatureMethod))
  add(formData_601103, "DomainName", newJString(DomainName))
  add(query_601102, "Signature", newJString(Signature))
  add(query_601102, "Action", newJString(Action))
  add(query_601102, "Timestamp", newJString(Timestamp))
  add(query_601102, "SignatureVersion", newJString(SignatureVersion))
  add(query_601102, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601102, "Version", newJString(Version))
  result = call_601101.call(nil, query_601102, nil, formData_601103, nil)

var postCreateDomain* = Call_PostCreateDomain_601089(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_601090,
    base: "/", url: url_PostCreateDomain_601091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_601075 = ref object of OpenApiRestCall_600421
proc url_GetCreateDomain_601077(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDomain_601076(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   DomainName: JString (required)
  ##             : The name of the domain to create. The name can range between 3 and 255 characters and can contain the following characters: a-z, A-Z, 0-9, '_', '-', and '.'.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_601078 = query.getOrDefault("SignatureMethod")
  valid_601078 = validateParameter(valid_601078, JString, required = true,
                                 default = nil)
  if valid_601078 != nil:
    section.add "SignatureMethod", valid_601078
  var valid_601079 = query.getOrDefault("Signature")
  valid_601079 = validateParameter(valid_601079, JString, required = true,
                                 default = nil)
  if valid_601079 != nil:
    section.add "Signature", valid_601079
  var valid_601080 = query.getOrDefault("Action")
  valid_601080 = validateParameter(valid_601080, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_601080 != nil:
    section.add "Action", valid_601080
  var valid_601081 = query.getOrDefault("Timestamp")
  valid_601081 = validateParameter(valid_601081, JString, required = true,
                                 default = nil)
  if valid_601081 != nil:
    section.add "Timestamp", valid_601081
  var valid_601082 = query.getOrDefault("SignatureVersion")
  valid_601082 = validateParameter(valid_601082, JString, required = true,
                                 default = nil)
  if valid_601082 != nil:
    section.add "SignatureVersion", valid_601082
  var valid_601083 = query.getOrDefault("AWSAccessKeyId")
  valid_601083 = validateParameter(valid_601083, JString, required = true,
                                 default = nil)
  if valid_601083 != nil:
    section.add "AWSAccessKeyId", valid_601083
  var valid_601084 = query.getOrDefault("DomainName")
  valid_601084 = validateParameter(valid_601084, JString, required = true,
                                 default = nil)
  if valid_601084 != nil:
    section.add "DomainName", valid_601084
  var valid_601085 = query.getOrDefault("Version")
  valid_601085 = validateParameter(valid_601085, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601085 != nil:
    section.add "Version", valid_601085
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601086: Call_GetCreateDomain_601075; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  let valid = call_601086.validator(path, query, header, formData, body)
  let scheme = call_601086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601086.url(scheme.get, call_601086.host, call_601086.base,
                         call_601086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601086, url, valid)

proc call*(call_601087: Call_GetCreateDomain_601075; SignatureMethod: string;
          Signature: string; Timestamp: string; SignatureVersion: string;
          AWSAccessKeyId: string; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2009-04-15"): Recallable =
  ## getCreateDomain
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ##   SignatureMethod: string (required)
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain to create. The name can range between 3 and 255 characters and can contain the following characters: a-z, A-Z, 0-9, '_', '-', and '.'.
  ##   Version: string (required)
  var query_601088 = newJObject()
  add(query_601088, "SignatureMethod", newJString(SignatureMethod))
  add(query_601088, "Signature", newJString(Signature))
  add(query_601088, "Action", newJString(Action))
  add(query_601088, "Timestamp", newJString(Timestamp))
  add(query_601088, "SignatureVersion", newJString(SignatureVersion))
  add(query_601088, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601088, "DomainName", newJString(DomainName))
  add(query_601088, "Version", newJString(Version))
  result = call_601087.call(nil, query_601088, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_601075(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_601076,
    base: "/", url: url_GetCreateDomain_601077, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAttributes_601123 = ref object of OpenApiRestCall_600421
proc url_PostDeleteAttributes_601125(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteAttributes_601124(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_601126 = query.getOrDefault("SignatureMethod")
  valid_601126 = validateParameter(valid_601126, JString, required = true,
                                 default = nil)
  if valid_601126 != nil:
    section.add "SignatureMethod", valid_601126
  var valid_601127 = query.getOrDefault("Signature")
  valid_601127 = validateParameter(valid_601127, JString, required = true,
                                 default = nil)
  if valid_601127 != nil:
    section.add "Signature", valid_601127
  var valid_601128 = query.getOrDefault("Action")
  valid_601128 = validateParameter(valid_601128, JString, required = true,
                                 default = newJString("DeleteAttributes"))
  if valid_601128 != nil:
    section.add "Action", valid_601128
  var valid_601129 = query.getOrDefault("Timestamp")
  valid_601129 = validateParameter(valid_601129, JString, required = true,
                                 default = nil)
  if valid_601129 != nil:
    section.add "Timestamp", valid_601129
  var valid_601130 = query.getOrDefault("SignatureVersion")
  valid_601130 = validateParameter(valid_601130, JString, required = true,
                                 default = nil)
  if valid_601130 != nil:
    section.add "SignatureVersion", valid_601130
  var valid_601131 = query.getOrDefault("AWSAccessKeyId")
  valid_601131 = validateParameter(valid_601131, JString, required = true,
                                 default = nil)
  if valid_601131 != nil:
    section.add "AWSAccessKeyId", valid_601131
  var valid_601132 = query.getOrDefault("Version")
  valid_601132 = validateParameter(valid_601132, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601132 != nil:
    section.add "Version", valid_601132
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain in which to perform the operation.
  ##   ItemName: JString (required)
  ##           : The name of the item. Similar to rows on a spreadsheet, items represent individual objects that contain one or more value-attribute pairs.
  ##   Expected.Exists: JString
  ##                  :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## A value specifying whether or not the specified attribute must exist with the specified value in order for the update condition to be satisfied. Specify <code>true</code> if the attribute must exist for the update condition to be satisfied. Specify <code>false</code> if the attribute should not exist in order for the update condition to be satisfied.
  ##   Attributes: JArray
  ##             : A list of Attributes. Similar to columns on a spreadsheet, attributes represent categories of data that can be assigned to items.
  ##   Expected.Value: JString
  ##                 :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The value of an attribute. This value can only be specified when the <code>Exists</code> parameter is equal to <code>true</code>.
  ##   Expected.Name: JString
  ##                :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The name of the attribute involved in the condition.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601133 = formData.getOrDefault("DomainName")
  valid_601133 = validateParameter(valid_601133, JString, required = true,
                                 default = nil)
  if valid_601133 != nil:
    section.add "DomainName", valid_601133
  var valid_601134 = formData.getOrDefault("ItemName")
  valid_601134 = validateParameter(valid_601134, JString, required = true,
                                 default = nil)
  if valid_601134 != nil:
    section.add "ItemName", valid_601134
  var valid_601135 = formData.getOrDefault("Expected.Exists")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "Expected.Exists", valid_601135
  var valid_601136 = formData.getOrDefault("Attributes")
  valid_601136 = validateParameter(valid_601136, JArray, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "Attributes", valid_601136
  var valid_601137 = formData.getOrDefault("Expected.Value")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "Expected.Value", valid_601137
  var valid_601138 = formData.getOrDefault("Expected.Name")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "Expected.Name", valid_601138
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601139: Call_PostDeleteAttributes_601123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  let valid = call_601139.validator(path, query, header, formData, body)
  let scheme = call_601139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601139.url(scheme.get, call_601139.host, call_601139.base,
                         call_601139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601139, url, valid)

proc call*(call_601140: Call_PostDeleteAttributes_601123; SignatureMethod: string;
          DomainName: string; ItemName: string; Signature: string; Timestamp: string;
          SignatureVersion: string; AWSAccessKeyId: string;
          ExpectedExists: string = ""; Attributes: JsonNode = nil;
          Action: string = "DeleteAttributes"; ExpectedValue: string = "";
          ExpectedName: string = ""; Version: string = "2009-04-15"): Recallable =
  ## postDeleteAttributes
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain in which to perform the operation.
  ##   ItemName: string (required)
  ##           : The name of the item. Similar to rows on a spreadsheet, items represent individual objects that contain one or more value-attribute pairs.
  ##   ExpectedExists: string
  ##                 :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## A value specifying whether or not the specified attribute must exist with the specified value in order for the update condition to be satisfied. Specify <code>true</code> if the attribute must exist for the update condition to be satisfied. Specify <code>false</code> if the attribute should not exist in order for the update condition to be satisfied.
  ##   Signature: string (required)
  ##   Attributes: JArray
  ##             : A list of Attributes. Similar to columns on a spreadsheet, attributes represent categories of data that can be assigned to items.
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   ExpectedValue: string
  ##                :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The value of an attribute. This value can only be specified when the <code>Exists</code> parameter is equal to <code>true</code>.
  ##   ExpectedName: string
  ##               :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The name of the attribute involved in the condition.
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_601141 = newJObject()
  var formData_601142 = newJObject()
  add(query_601141, "SignatureMethod", newJString(SignatureMethod))
  add(formData_601142, "DomainName", newJString(DomainName))
  add(formData_601142, "ItemName", newJString(ItemName))
  add(formData_601142, "Expected.Exists", newJString(ExpectedExists))
  add(query_601141, "Signature", newJString(Signature))
  if Attributes != nil:
    formData_601142.add "Attributes", Attributes
  add(query_601141, "Action", newJString(Action))
  add(query_601141, "Timestamp", newJString(Timestamp))
  add(formData_601142, "Expected.Value", newJString(ExpectedValue))
  add(formData_601142, "Expected.Name", newJString(ExpectedName))
  add(query_601141, "SignatureVersion", newJString(SignatureVersion))
  add(query_601141, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601141, "Version", newJString(Version))
  result = call_601140.call(nil, query_601141, nil, formData_601142, nil)

var postDeleteAttributes* = Call_PostDeleteAttributes_601123(
    name: "postDeleteAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=DeleteAttributes",
    validator: validate_PostDeleteAttributes_601124, base: "/",
    url: url_PostDeleteAttributes_601125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAttributes_601104 = ref object of OpenApiRestCall_600421
proc url_GetDeleteAttributes_601106(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteAttributes_601105(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Expected.Exists: JString
  ##                  :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## A value specifying whether or not the specified attribute must exist with the specified value in order for the update condition to be satisfied. Specify <code>true</code> if the attribute must exist for the update condition to be satisfied. Specify <code>false</code> if the attribute should not exist in order for the update condition to be satisfied.
  ##   Attributes: JArray
  ##             : A list of Attributes. Similar to columns on a spreadsheet, attributes represent categories of data that can be assigned to items.
  ##   Signature: JString (required)
  ##   ItemName: JString (required)
  ##           : The name of the item. Similar to rows on a spreadsheet, items represent individual objects that contain one or more value-attribute pairs.
  ##   Action: JString (required)
  ##   Expected.Value: JString
  ##                 :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The value of an attribute. This value can only be specified when the <code>Exists</code> parameter is equal to <code>true</code>.
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Expected.Name: JString
  ##                :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The name of the attribute involved in the condition.
  ##   DomainName: JString (required)
  ##             : The name of the domain in which to perform the operation.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_601107 = query.getOrDefault("SignatureMethod")
  valid_601107 = validateParameter(valid_601107, JString, required = true,
                                 default = nil)
  if valid_601107 != nil:
    section.add "SignatureMethod", valid_601107
  var valid_601108 = query.getOrDefault("Expected.Exists")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "Expected.Exists", valid_601108
  var valid_601109 = query.getOrDefault("Attributes")
  valid_601109 = validateParameter(valid_601109, JArray, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "Attributes", valid_601109
  var valid_601110 = query.getOrDefault("Signature")
  valid_601110 = validateParameter(valid_601110, JString, required = true,
                                 default = nil)
  if valid_601110 != nil:
    section.add "Signature", valid_601110
  var valid_601111 = query.getOrDefault("ItemName")
  valid_601111 = validateParameter(valid_601111, JString, required = true,
                                 default = nil)
  if valid_601111 != nil:
    section.add "ItemName", valid_601111
  var valid_601112 = query.getOrDefault("Action")
  valid_601112 = validateParameter(valid_601112, JString, required = true,
                                 default = newJString("DeleteAttributes"))
  if valid_601112 != nil:
    section.add "Action", valid_601112
  var valid_601113 = query.getOrDefault("Expected.Value")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "Expected.Value", valid_601113
  var valid_601114 = query.getOrDefault("Timestamp")
  valid_601114 = validateParameter(valid_601114, JString, required = true,
                                 default = nil)
  if valid_601114 != nil:
    section.add "Timestamp", valid_601114
  var valid_601115 = query.getOrDefault("SignatureVersion")
  valid_601115 = validateParameter(valid_601115, JString, required = true,
                                 default = nil)
  if valid_601115 != nil:
    section.add "SignatureVersion", valid_601115
  var valid_601116 = query.getOrDefault("AWSAccessKeyId")
  valid_601116 = validateParameter(valid_601116, JString, required = true,
                                 default = nil)
  if valid_601116 != nil:
    section.add "AWSAccessKeyId", valid_601116
  var valid_601117 = query.getOrDefault("Expected.Name")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "Expected.Name", valid_601117
  var valid_601118 = query.getOrDefault("DomainName")
  valid_601118 = validateParameter(valid_601118, JString, required = true,
                                 default = nil)
  if valid_601118 != nil:
    section.add "DomainName", valid_601118
  var valid_601119 = query.getOrDefault("Version")
  valid_601119 = validateParameter(valid_601119, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601119 != nil:
    section.add "Version", valid_601119
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601120: Call_GetDeleteAttributes_601104; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  let valid = call_601120.validator(path, query, header, formData, body)
  let scheme = call_601120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601120.url(scheme.get, call_601120.host, call_601120.base,
                         call_601120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601120, url, valid)

proc call*(call_601121: Call_GetDeleteAttributes_601104; SignatureMethod: string;
          Signature: string; ItemName: string; Timestamp: string;
          SignatureVersion: string; AWSAccessKeyId: string; DomainName: string;
          ExpectedExists: string = ""; Attributes: JsonNode = nil;
          Action: string = "DeleteAttributes"; ExpectedValue: string = "";
          ExpectedName: string = ""; Version: string = "2009-04-15"): Recallable =
  ## getDeleteAttributes
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ##   SignatureMethod: string (required)
  ##   ExpectedExists: string
  ##                 :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## A value specifying whether or not the specified attribute must exist with the specified value in order for the update condition to be satisfied. Specify <code>true</code> if the attribute must exist for the update condition to be satisfied. Specify <code>false</code> if the attribute should not exist in order for the update condition to be satisfied.
  ##   Attributes: JArray
  ##             : A list of Attributes. Similar to columns on a spreadsheet, attributes represent categories of data that can be assigned to items.
  ##   Signature: string (required)
  ##   ItemName: string (required)
  ##           : The name of the item. Similar to rows on a spreadsheet, items represent individual objects that contain one or more value-attribute pairs.
  ##   Action: string (required)
  ##   ExpectedValue: string
  ##                :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The value of an attribute. This value can only be specified when the <code>Exists</code> parameter is equal to <code>true</code>.
  ##   Timestamp: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   ExpectedName: string
  ##               :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The name of the attribute involved in the condition.
  ##   DomainName: string (required)
  ##             : The name of the domain in which to perform the operation.
  ##   Version: string (required)
  var query_601122 = newJObject()
  add(query_601122, "SignatureMethod", newJString(SignatureMethod))
  add(query_601122, "Expected.Exists", newJString(ExpectedExists))
  if Attributes != nil:
    query_601122.add "Attributes", Attributes
  add(query_601122, "Signature", newJString(Signature))
  add(query_601122, "ItemName", newJString(ItemName))
  add(query_601122, "Action", newJString(Action))
  add(query_601122, "Expected.Value", newJString(ExpectedValue))
  add(query_601122, "Timestamp", newJString(Timestamp))
  add(query_601122, "SignatureVersion", newJString(SignatureVersion))
  add(query_601122, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601122, "Expected.Name", newJString(ExpectedName))
  add(query_601122, "DomainName", newJString(DomainName))
  add(query_601122, "Version", newJString(Version))
  result = call_601121.call(nil, query_601122, nil, nil, nil)

var getDeleteAttributes* = Call_GetDeleteAttributes_601104(
    name: "getDeleteAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=DeleteAttributes",
    validator: validate_GetDeleteAttributes_601105, base: "/",
    url: url_GetDeleteAttributes_601106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_601157 = ref object of OpenApiRestCall_600421
proc url_PostDeleteDomain_601159(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDomain_601158(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_601160 = query.getOrDefault("SignatureMethod")
  valid_601160 = validateParameter(valid_601160, JString, required = true,
                                 default = nil)
  if valid_601160 != nil:
    section.add "SignatureMethod", valid_601160
  var valid_601161 = query.getOrDefault("Signature")
  valid_601161 = validateParameter(valid_601161, JString, required = true,
                                 default = nil)
  if valid_601161 != nil:
    section.add "Signature", valid_601161
  var valid_601162 = query.getOrDefault("Action")
  valid_601162 = validateParameter(valid_601162, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_601162 != nil:
    section.add "Action", valid_601162
  var valid_601163 = query.getOrDefault("Timestamp")
  valid_601163 = validateParameter(valid_601163, JString, required = true,
                                 default = nil)
  if valid_601163 != nil:
    section.add "Timestamp", valid_601163
  var valid_601164 = query.getOrDefault("SignatureVersion")
  valid_601164 = validateParameter(valid_601164, JString, required = true,
                                 default = nil)
  if valid_601164 != nil:
    section.add "SignatureVersion", valid_601164
  var valid_601165 = query.getOrDefault("AWSAccessKeyId")
  valid_601165 = validateParameter(valid_601165, JString, required = true,
                                 default = nil)
  if valid_601165 != nil:
    section.add "AWSAccessKeyId", valid_601165
  var valid_601166 = query.getOrDefault("Version")
  valid_601166 = validateParameter(valid_601166, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601166 != nil:
    section.add "Version", valid_601166
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601167 = formData.getOrDefault("DomainName")
  valid_601167 = validateParameter(valid_601167, JString, required = true,
                                 default = nil)
  if valid_601167 != nil:
    section.add "DomainName", valid_601167
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601168: Call_PostDeleteDomain_601157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  let valid = call_601168.validator(path, query, header, formData, body)
  let scheme = call_601168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601168.url(scheme.get, call_601168.host, call_601168.base,
                         call_601168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601168, url, valid)

proc call*(call_601169: Call_PostDeleteDomain_601157; SignatureMethod: string;
          DomainName: string; Signature: string; Timestamp: string;
          SignatureVersion: string; AWSAccessKeyId: string;
          Action: string = "DeleteDomain"; Version: string = "2009-04-15"): Recallable =
  ## postDeleteDomain
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain to delete.
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_601170 = newJObject()
  var formData_601171 = newJObject()
  add(query_601170, "SignatureMethod", newJString(SignatureMethod))
  add(formData_601171, "DomainName", newJString(DomainName))
  add(query_601170, "Signature", newJString(Signature))
  add(query_601170, "Action", newJString(Action))
  add(query_601170, "Timestamp", newJString(Timestamp))
  add(query_601170, "SignatureVersion", newJString(SignatureVersion))
  add(query_601170, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601170, "Version", newJString(Version))
  result = call_601169.call(nil, query_601170, nil, formData_601171, nil)

var postDeleteDomain* = Call_PostDeleteDomain_601157(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_601158,
    base: "/", url: url_PostDeleteDomain_601159,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_601143 = ref object of OpenApiRestCall_600421
proc url_GetDeleteDomain_601145(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDomain_601144(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   DomainName: JString (required)
  ##             : The name of the domain to delete.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_601146 = query.getOrDefault("SignatureMethod")
  valid_601146 = validateParameter(valid_601146, JString, required = true,
                                 default = nil)
  if valid_601146 != nil:
    section.add "SignatureMethod", valid_601146
  var valid_601147 = query.getOrDefault("Signature")
  valid_601147 = validateParameter(valid_601147, JString, required = true,
                                 default = nil)
  if valid_601147 != nil:
    section.add "Signature", valid_601147
  var valid_601148 = query.getOrDefault("Action")
  valid_601148 = validateParameter(valid_601148, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_601148 != nil:
    section.add "Action", valid_601148
  var valid_601149 = query.getOrDefault("Timestamp")
  valid_601149 = validateParameter(valid_601149, JString, required = true,
                                 default = nil)
  if valid_601149 != nil:
    section.add "Timestamp", valid_601149
  var valid_601150 = query.getOrDefault("SignatureVersion")
  valid_601150 = validateParameter(valid_601150, JString, required = true,
                                 default = nil)
  if valid_601150 != nil:
    section.add "SignatureVersion", valid_601150
  var valid_601151 = query.getOrDefault("AWSAccessKeyId")
  valid_601151 = validateParameter(valid_601151, JString, required = true,
                                 default = nil)
  if valid_601151 != nil:
    section.add "AWSAccessKeyId", valid_601151
  var valid_601152 = query.getOrDefault("DomainName")
  valid_601152 = validateParameter(valid_601152, JString, required = true,
                                 default = nil)
  if valid_601152 != nil:
    section.add "DomainName", valid_601152
  var valid_601153 = query.getOrDefault("Version")
  valid_601153 = validateParameter(valid_601153, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601153 != nil:
    section.add "Version", valid_601153
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601154: Call_GetDeleteDomain_601143; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  let valid = call_601154.validator(path, query, header, formData, body)
  let scheme = call_601154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601154.url(scheme.get, call_601154.host, call_601154.base,
                         call_601154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601154, url, valid)

proc call*(call_601155: Call_GetDeleteDomain_601143; SignatureMethod: string;
          Signature: string; Timestamp: string; SignatureVersion: string;
          AWSAccessKeyId: string; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2009-04-15"): Recallable =
  ## getDeleteDomain
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ##   SignatureMethod: string (required)
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain to delete.
  ##   Version: string (required)
  var query_601156 = newJObject()
  add(query_601156, "SignatureMethod", newJString(SignatureMethod))
  add(query_601156, "Signature", newJString(Signature))
  add(query_601156, "Action", newJString(Action))
  add(query_601156, "Timestamp", newJString(Timestamp))
  add(query_601156, "SignatureVersion", newJString(SignatureVersion))
  add(query_601156, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601156, "DomainName", newJString(DomainName))
  add(query_601156, "Version", newJString(Version))
  result = call_601155.call(nil, query_601156, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_601143(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_601144,
    base: "/", url: url_GetDeleteDomain_601145, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDomainMetadata_601186 = ref object of OpenApiRestCall_600421
proc url_PostDomainMetadata_601188(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDomainMetadata_601187(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_601189 = query.getOrDefault("SignatureMethod")
  valid_601189 = validateParameter(valid_601189, JString, required = true,
                                 default = nil)
  if valid_601189 != nil:
    section.add "SignatureMethod", valid_601189
  var valid_601190 = query.getOrDefault("Signature")
  valid_601190 = validateParameter(valid_601190, JString, required = true,
                                 default = nil)
  if valid_601190 != nil:
    section.add "Signature", valid_601190
  var valid_601191 = query.getOrDefault("Action")
  valid_601191 = validateParameter(valid_601191, JString, required = true,
                                 default = newJString("DomainMetadata"))
  if valid_601191 != nil:
    section.add "Action", valid_601191
  var valid_601192 = query.getOrDefault("Timestamp")
  valid_601192 = validateParameter(valid_601192, JString, required = true,
                                 default = nil)
  if valid_601192 != nil:
    section.add "Timestamp", valid_601192
  var valid_601193 = query.getOrDefault("SignatureVersion")
  valid_601193 = validateParameter(valid_601193, JString, required = true,
                                 default = nil)
  if valid_601193 != nil:
    section.add "SignatureVersion", valid_601193
  var valid_601194 = query.getOrDefault("AWSAccessKeyId")
  valid_601194 = validateParameter(valid_601194, JString, required = true,
                                 default = nil)
  if valid_601194 != nil:
    section.add "AWSAccessKeyId", valid_601194
  var valid_601195 = query.getOrDefault("Version")
  valid_601195 = validateParameter(valid_601195, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601195 != nil:
    section.add "Version", valid_601195
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain for which to display the metadata of.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601196 = formData.getOrDefault("DomainName")
  valid_601196 = validateParameter(valid_601196, JString, required = true,
                                 default = nil)
  if valid_601196 != nil:
    section.add "DomainName", valid_601196
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601197: Call_PostDomainMetadata_601186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  let valid = call_601197.validator(path, query, header, formData, body)
  let scheme = call_601197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601197.url(scheme.get, call_601197.host, call_601197.base,
                         call_601197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601197, url, valid)

proc call*(call_601198: Call_PostDomainMetadata_601186; SignatureMethod: string;
          DomainName: string; Signature: string; Timestamp: string;
          SignatureVersion: string; AWSAccessKeyId: string;
          Action: string = "DomainMetadata"; Version: string = "2009-04-15"): Recallable =
  ## postDomainMetadata
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain for which to display the metadata of.
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_601199 = newJObject()
  var formData_601200 = newJObject()
  add(query_601199, "SignatureMethod", newJString(SignatureMethod))
  add(formData_601200, "DomainName", newJString(DomainName))
  add(query_601199, "Signature", newJString(Signature))
  add(query_601199, "Action", newJString(Action))
  add(query_601199, "Timestamp", newJString(Timestamp))
  add(query_601199, "SignatureVersion", newJString(SignatureVersion))
  add(query_601199, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601199, "Version", newJString(Version))
  result = call_601198.call(nil, query_601199, nil, formData_601200, nil)

var postDomainMetadata* = Call_PostDomainMetadata_601186(
    name: "postDomainMetadata", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=DomainMetadata",
    validator: validate_PostDomainMetadata_601187, base: "/",
    url: url_PostDomainMetadata_601188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainMetadata_601172 = ref object of OpenApiRestCall_600421
proc url_GetDomainMetadata_601174(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDomainMetadata_601173(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   DomainName: JString (required)
  ##             : The name of the domain for which to display the metadata of.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_601175 = query.getOrDefault("SignatureMethod")
  valid_601175 = validateParameter(valid_601175, JString, required = true,
                                 default = nil)
  if valid_601175 != nil:
    section.add "SignatureMethod", valid_601175
  var valid_601176 = query.getOrDefault("Signature")
  valid_601176 = validateParameter(valid_601176, JString, required = true,
                                 default = nil)
  if valid_601176 != nil:
    section.add "Signature", valid_601176
  var valid_601177 = query.getOrDefault("Action")
  valid_601177 = validateParameter(valid_601177, JString, required = true,
                                 default = newJString("DomainMetadata"))
  if valid_601177 != nil:
    section.add "Action", valid_601177
  var valid_601178 = query.getOrDefault("Timestamp")
  valid_601178 = validateParameter(valid_601178, JString, required = true,
                                 default = nil)
  if valid_601178 != nil:
    section.add "Timestamp", valid_601178
  var valid_601179 = query.getOrDefault("SignatureVersion")
  valid_601179 = validateParameter(valid_601179, JString, required = true,
                                 default = nil)
  if valid_601179 != nil:
    section.add "SignatureVersion", valid_601179
  var valid_601180 = query.getOrDefault("AWSAccessKeyId")
  valid_601180 = validateParameter(valid_601180, JString, required = true,
                                 default = nil)
  if valid_601180 != nil:
    section.add "AWSAccessKeyId", valid_601180
  var valid_601181 = query.getOrDefault("DomainName")
  valid_601181 = validateParameter(valid_601181, JString, required = true,
                                 default = nil)
  if valid_601181 != nil:
    section.add "DomainName", valid_601181
  var valid_601182 = query.getOrDefault("Version")
  valid_601182 = validateParameter(valid_601182, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601182 != nil:
    section.add "Version", valid_601182
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601183: Call_GetDomainMetadata_601172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  let valid = call_601183.validator(path, query, header, formData, body)
  let scheme = call_601183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601183.url(scheme.get, call_601183.host, call_601183.base,
                         call_601183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601183, url, valid)

proc call*(call_601184: Call_GetDomainMetadata_601172; SignatureMethod: string;
          Signature: string; Timestamp: string; SignatureVersion: string;
          AWSAccessKeyId: string; DomainName: string;
          Action: string = "DomainMetadata"; Version: string = "2009-04-15"): Recallable =
  ## getDomainMetadata
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ##   SignatureMethod: string (required)
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain for which to display the metadata of.
  ##   Version: string (required)
  var query_601185 = newJObject()
  add(query_601185, "SignatureMethod", newJString(SignatureMethod))
  add(query_601185, "Signature", newJString(Signature))
  add(query_601185, "Action", newJString(Action))
  add(query_601185, "Timestamp", newJString(Timestamp))
  add(query_601185, "SignatureVersion", newJString(SignatureVersion))
  add(query_601185, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601185, "DomainName", newJString(DomainName))
  add(query_601185, "Version", newJString(Version))
  result = call_601184.call(nil, query_601185, nil, nil, nil)

var getDomainMetadata* = Call_GetDomainMetadata_601172(name: "getDomainMetadata",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=DomainMetadata", validator: validate_GetDomainMetadata_601173,
    base: "/", url: url_GetDomainMetadata_601174,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetAttributes_601218 = ref object of OpenApiRestCall_600421
proc url_PostGetAttributes_601220(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetAttributes_601219(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_601221 = query.getOrDefault("SignatureMethod")
  valid_601221 = validateParameter(valid_601221, JString, required = true,
                                 default = nil)
  if valid_601221 != nil:
    section.add "SignatureMethod", valid_601221
  var valid_601222 = query.getOrDefault("Signature")
  valid_601222 = validateParameter(valid_601222, JString, required = true,
                                 default = nil)
  if valid_601222 != nil:
    section.add "Signature", valid_601222
  var valid_601223 = query.getOrDefault("Action")
  valid_601223 = validateParameter(valid_601223, JString, required = true,
                                 default = newJString("GetAttributes"))
  if valid_601223 != nil:
    section.add "Action", valid_601223
  var valid_601224 = query.getOrDefault("Timestamp")
  valid_601224 = validateParameter(valid_601224, JString, required = true,
                                 default = nil)
  if valid_601224 != nil:
    section.add "Timestamp", valid_601224
  var valid_601225 = query.getOrDefault("SignatureVersion")
  valid_601225 = validateParameter(valid_601225, JString, required = true,
                                 default = nil)
  if valid_601225 != nil:
    section.add "SignatureVersion", valid_601225
  var valid_601226 = query.getOrDefault("AWSAccessKeyId")
  valid_601226 = validateParameter(valid_601226, JString, required = true,
                                 default = nil)
  if valid_601226 != nil:
    section.add "AWSAccessKeyId", valid_601226
  var valid_601227 = query.getOrDefault("Version")
  valid_601227 = validateParameter(valid_601227, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601227 != nil:
    section.add "Version", valid_601227
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain in which to perform the operation.
  ##   ItemName: JString (required)
  ##           : The name of the item.
  ##   ConsistentRead: JBool
  ##                 : Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If <code>true</code>, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  ##   AttributeNames: JArray
  ##                 : The names of the attributes.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601228 = formData.getOrDefault("DomainName")
  valid_601228 = validateParameter(valid_601228, JString, required = true,
                                 default = nil)
  if valid_601228 != nil:
    section.add "DomainName", valid_601228
  var valid_601229 = formData.getOrDefault("ItemName")
  valid_601229 = validateParameter(valid_601229, JString, required = true,
                                 default = nil)
  if valid_601229 != nil:
    section.add "ItemName", valid_601229
  var valid_601230 = formData.getOrDefault("ConsistentRead")
  valid_601230 = validateParameter(valid_601230, JBool, required = false, default = nil)
  if valid_601230 != nil:
    section.add "ConsistentRead", valid_601230
  var valid_601231 = formData.getOrDefault("AttributeNames")
  valid_601231 = validateParameter(valid_601231, JArray, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "AttributeNames", valid_601231
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601232: Call_PostGetAttributes_601218; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  let valid = call_601232.validator(path, query, header, formData, body)
  let scheme = call_601232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601232.url(scheme.get, call_601232.host, call_601232.base,
                         call_601232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601232, url, valid)

proc call*(call_601233: Call_PostGetAttributes_601218; SignatureMethod: string;
          DomainName: string; ItemName: string; Signature: string; Timestamp: string;
          SignatureVersion: string; AWSAccessKeyId: string;
          ConsistentRead: bool = false; Action: string = "GetAttributes";
          AttributeNames: JsonNode = nil; Version: string = "2009-04-15"): Recallable =
  ## postGetAttributes
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain in which to perform the operation.
  ##   ItemName: string (required)
  ##           : The name of the item.
  ##   ConsistentRead: bool
  ##                 : Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If <code>true</code>, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   AttributeNames: JArray
  ##                 : The names of the attributes.
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_601234 = newJObject()
  var formData_601235 = newJObject()
  add(query_601234, "SignatureMethod", newJString(SignatureMethod))
  add(formData_601235, "DomainName", newJString(DomainName))
  add(formData_601235, "ItemName", newJString(ItemName))
  add(formData_601235, "ConsistentRead", newJBool(ConsistentRead))
  add(query_601234, "Signature", newJString(Signature))
  add(query_601234, "Action", newJString(Action))
  add(query_601234, "Timestamp", newJString(Timestamp))
  if AttributeNames != nil:
    formData_601235.add "AttributeNames", AttributeNames
  add(query_601234, "SignatureVersion", newJString(SignatureVersion))
  add(query_601234, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601234, "Version", newJString(Version))
  result = call_601233.call(nil, query_601234, nil, formData_601235, nil)

var postGetAttributes* = Call_PostGetAttributes_601218(name: "postGetAttributes",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=GetAttributes", validator: validate_PostGetAttributes_601219,
    base: "/", url: url_PostGetAttributes_601220,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetAttributes_601201 = ref object of OpenApiRestCall_600421
proc url_GetGetAttributes_601203(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetAttributes_601202(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   AttributeNames: JArray
  ##                 : The names of the attributes.
  ##   Signature: JString (required)
  ##   ItemName: JString (required)
  ##           : The name of the item.
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   ConsistentRead: JBool
  ##                 : Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If <code>true</code>, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   DomainName: JString (required)
  ##             : The name of the domain in which to perform the operation.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_601204 = query.getOrDefault("SignatureMethod")
  valid_601204 = validateParameter(valid_601204, JString, required = true,
                                 default = nil)
  if valid_601204 != nil:
    section.add "SignatureMethod", valid_601204
  var valid_601205 = query.getOrDefault("AttributeNames")
  valid_601205 = validateParameter(valid_601205, JArray, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "AttributeNames", valid_601205
  var valid_601206 = query.getOrDefault("Signature")
  valid_601206 = validateParameter(valid_601206, JString, required = true,
                                 default = nil)
  if valid_601206 != nil:
    section.add "Signature", valid_601206
  var valid_601207 = query.getOrDefault("ItemName")
  valid_601207 = validateParameter(valid_601207, JString, required = true,
                                 default = nil)
  if valid_601207 != nil:
    section.add "ItemName", valid_601207
  var valid_601208 = query.getOrDefault("Action")
  valid_601208 = validateParameter(valid_601208, JString, required = true,
                                 default = newJString("GetAttributes"))
  if valid_601208 != nil:
    section.add "Action", valid_601208
  var valid_601209 = query.getOrDefault("Timestamp")
  valid_601209 = validateParameter(valid_601209, JString, required = true,
                                 default = nil)
  if valid_601209 != nil:
    section.add "Timestamp", valid_601209
  var valid_601210 = query.getOrDefault("ConsistentRead")
  valid_601210 = validateParameter(valid_601210, JBool, required = false, default = nil)
  if valid_601210 != nil:
    section.add "ConsistentRead", valid_601210
  var valid_601211 = query.getOrDefault("SignatureVersion")
  valid_601211 = validateParameter(valid_601211, JString, required = true,
                                 default = nil)
  if valid_601211 != nil:
    section.add "SignatureVersion", valid_601211
  var valid_601212 = query.getOrDefault("AWSAccessKeyId")
  valid_601212 = validateParameter(valid_601212, JString, required = true,
                                 default = nil)
  if valid_601212 != nil:
    section.add "AWSAccessKeyId", valid_601212
  var valid_601213 = query.getOrDefault("DomainName")
  valid_601213 = validateParameter(valid_601213, JString, required = true,
                                 default = nil)
  if valid_601213 != nil:
    section.add "DomainName", valid_601213
  var valid_601214 = query.getOrDefault("Version")
  valid_601214 = validateParameter(valid_601214, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601214 != nil:
    section.add "Version", valid_601214
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601215: Call_GetGetAttributes_601201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  let valid = call_601215.validator(path, query, header, formData, body)
  let scheme = call_601215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601215.url(scheme.get, call_601215.host, call_601215.base,
                         call_601215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601215, url, valid)

proc call*(call_601216: Call_GetGetAttributes_601201; SignatureMethod: string;
          Signature: string; ItemName: string; Timestamp: string;
          SignatureVersion: string; AWSAccessKeyId: string; DomainName: string;
          AttributeNames: JsonNode = nil; Action: string = "GetAttributes";
          ConsistentRead: bool = false; Version: string = "2009-04-15"): Recallable =
  ## getGetAttributes
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ##   SignatureMethod: string (required)
  ##   AttributeNames: JArray
  ##                 : The names of the attributes.
  ##   Signature: string (required)
  ##   ItemName: string (required)
  ##           : The name of the item.
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   ConsistentRead: bool
  ##                 : Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If <code>true</code>, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain in which to perform the operation.
  ##   Version: string (required)
  var query_601217 = newJObject()
  add(query_601217, "SignatureMethod", newJString(SignatureMethod))
  if AttributeNames != nil:
    query_601217.add "AttributeNames", AttributeNames
  add(query_601217, "Signature", newJString(Signature))
  add(query_601217, "ItemName", newJString(ItemName))
  add(query_601217, "Action", newJString(Action))
  add(query_601217, "Timestamp", newJString(Timestamp))
  add(query_601217, "ConsistentRead", newJBool(ConsistentRead))
  add(query_601217, "SignatureVersion", newJString(SignatureVersion))
  add(query_601217, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601217, "DomainName", newJString(DomainName))
  add(query_601217, "Version", newJString(Version))
  result = call_601216.call(nil, query_601217, nil, nil, nil)

var getGetAttributes* = Call_GetGetAttributes_601201(name: "getGetAttributes",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=GetAttributes", validator: validate_GetGetAttributes_601202,
    base: "/", url: url_GetGetAttributes_601203,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDomains_601251 = ref object of OpenApiRestCall_600421
proc url_PostListDomains_601253(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListDomains_601252(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_601254 = query.getOrDefault("SignatureMethod")
  valid_601254 = validateParameter(valid_601254, JString, required = true,
                                 default = nil)
  if valid_601254 != nil:
    section.add "SignatureMethod", valid_601254
  var valid_601255 = query.getOrDefault("Signature")
  valid_601255 = validateParameter(valid_601255, JString, required = true,
                                 default = nil)
  if valid_601255 != nil:
    section.add "Signature", valid_601255
  var valid_601256 = query.getOrDefault("Action")
  valid_601256 = validateParameter(valid_601256, JString, required = true,
                                 default = newJString("ListDomains"))
  if valid_601256 != nil:
    section.add "Action", valid_601256
  var valid_601257 = query.getOrDefault("Timestamp")
  valid_601257 = validateParameter(valid_601257, JString, required = true,
                                 default = nil)
  if valid_601257 != nil:
    section.add "Timestamp", valid_601257
  var valid_601258 = query.getOrDefault("SignatureVersion")
  valid_601258 = validateParameter(valid_601258, JString, required = true,
                                 default = nil)
  if valid_601258 != nil:
    section.add "SignatureVersion", valid_601258
  var valid_601259 = query.getOrDefault("AWSAccessKeyId")
  valid_601259 = validateParameter(valid_601259, JString, required = true,
                                 default = nil)
  if valid_601259 != nil:
    section.add "AWSAccessKeyId", valid_601259
  var valid_601260 = query.getOrDefault("Version")
  valid_601260 = validateParameter(valid_601260, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601260 != nil:
    section.add "Version", valid_601260
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : A string informing Amazon SimpleDB where to start the next list of domain names.
  ##   MaxNumberOfDomains: JInt
  ##                     : The maximum number of domain names you want returned. The range is 1 to 100. The default setting is 100.
  section = newJObject()
  var valid_601261 = formData.getOrDefault("NextToken")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "NextToken", valid_601261
  var valid_601262 = formData.getOrDefault("MaxNumberOfDomains")
  valid_601262 = validateParameter(valid_601262, JInt, required = false, default = nil)
  if valid_601262 != nil:
    section.add "MaxNumberOfDomains", valid_601262
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601263: Call_PostListDomains_601251; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  let valid = call_601263.validator(path, query, header, formData, body)
  let scheme = call_601263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601263.url(scheme.get, call_601263.host, call_601263.base,
                         call_601263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601263, url, valid)

proc call*(call_601264: Call_PostListDomains_601251; SignatureMethod: string;
          Signature: string; Timestamp: string; SignatureVersion: string;
          AWSAccessKeyId: string; NextToken: string = "";
          Action: string = "ListDomains"; MaxNumberOfDomains: int = 0;
          Version: string = "2009-04-15"): Recallable =
  ## postListDomains
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ##   NextToken: string
  ##            : A string informing Amazon SimpleDB where to start the next list of domain names.
  ##   SignatureMethod: string (required)
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   MaxNumberOfDomains: int
  ##                     : The maximum number of domain names you want returned. The range is 1 to 100. The default setting is 100.
  ##   Version: string (required)
  var query_601265 = newJObject()
  var formData_601266 = newJObject()
  add(formData_601266, "NextToken", newJString(NextToken))
  add(query_601265, "SignatureMethod", newJString(SignatureMethod))
  add(query_601265, "Signature", newJString(Signature))
  add(query_601265, "Action", newJString(Action))
  add(query_601265, "Timestamp", newJString(Timestamp))
  add(query_601265, "SignatureVersion", newJString(SignatureVersion))
  add(query_601265, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_601266, "MaxNumberOfDomains", newJInt(MaxNumberOfDomains))
  add(query_601265, "Version", newJString(Version))
  result = call_601264.call(nil, query_601265, nil, formData_601266, nil)

var postListDomains* = Call_PostListDomains_601251(name: "postListDomains",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=ListDomains", validator: validate_PostListDomains_601252,
    base: "/", url: url_PostListDomains_601253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDomains_601236 = ref object of OpenApiRestCall_600421
proc url_GetListDomains_601238(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListDomains_601237(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   NextToken: JString
  ##            : A string informing Amazon SimpleDB where to start the next list of domain names.
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  ##   MaxNumberOfDomains: JInt
  ##                     : The maximum number of domain names you want returned. The range is 1 to 100. The default setting is 100.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_601239 = query.getOrDefault("SignatureMethod")
  valid_601239 = validateParameter(valid_601239, JString, required = true,
                                 default = nil)
  if valid_601239 != nil:
    section.add "SignatureMethod", valid_601239
  var valid_601240 = query.getOrDefault("Signature")
  valid_601240 = validateParameter(valid_601240, JString, required = true,
                                 default = nil)
  if valid_601240 != nil:
    section.add "Signature", valid_601240
  var valid_601241 = query.getOrDefault("NextToken")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "NextToken", valid_601241
  var valid_601242 = query.getOrDefault("Action")
  valid_601242 = validateParameter(valid_601242, JString, required = true,
                                 default = newJString("ListDomains"))
  if valid_601242 != nil:
    section.add "Action", valid_601242
  var valid_601243 = query.getOrDefault("Timestamp")
  valid_601243 = validateParameter(valid_601243, JString, required = true,
                                 default = nil)
  if valid_601243 != nil:
    section.add "Timestamp", valid_601243
  var valid_601244 = query.getOrDefault("SignatureVersion")
  valid_601244 = validateParameter(valid_601244, JString, required = true,
                                 default = nil)
  if valid_601244 != nil:
    section.add "SignatureVersion", valid_601244
  var valid_601245 = query.getOrDefault("AWSAccessKeyId")
  valid_601245 = validateParameter(valid_601245, JString, required = true,
                                 default = nil)
  if valid_601245 != nil:
    section.add "AWSAccessKeyId", valid_601245
  var valid_601246 = query.getOrDefault("Version")
  valid_601246 = validateParameter(valid_601246, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601246 != nil:
    section.add "Version", valid_601246
  var valid_601247 = query.getOrDefault("MaxNumberOfDomains")
  valid_601247 = validateParameter(valid_601247, JInt, required = false, default = nil)
  if valid_601247 != nil:
    section.add "MaxNumberOfDomains", valid_601247
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601248: Call_GetListDomains_601236; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  let valid = call_601248.validator(path, query, header, formData, body)
  let scheme = call_601248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601248.url(scheme.get, call_601248.host, call_601248.base,
                         call_601248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601248, url, valid)

proc call*(call_601249: Call_GetListDomains_601236; SignatureMethod: string;
          Signature: string; Timestamp: string; SignatureVersion: string;
          AWSAccessKeyId: string; NextToken: string = "";
          Action: string = "ListDomains"; Version: string = "2009-04-15";
          MaxNumberOfDomains: int = 0): Recallable =
  ## getListDomains
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ##   SignatureMethod: string (required)
  ##   Signature: string (required)
  ##   NextToken: string
  ##            : A string informing Amazon SimpleDB where to start the next list of domain names.
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  ##   MaxNumberOfDomains: int
  ##                     : The maximum number of domain names you want returned. The range is 1 to 100. The default setting is 100.
  var query_601250 = newJObject()
  add(query_601250, "SignatureMethod", newJString(SignatureMethod))
  add(query_601250, "Signature", newJString(Signature))
  add(query_601250, "NextToken", newJString(NextToken))
  add(query_601250, "Action", newJString(Action))
  add(query_601250, "Timestamp", newJString(Timestamp))
  add(query_601250, "SignatureVersion", newJString(SignatureVersion))
  add(query_601250, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601250, "Version", newJString(Version))
  add(query_601250, "MaxNumberOfDomains", newJInt(MaxNumberOfDomains))
  result = call_601249.call(nil, query_601250, nil, nil, nil)

var getListDomains* = Call_GetListDomains_601236(name: "getListDomains",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=ListDomains", validator: validate_GetListDomains_601237,
    base: "/", url: url_GetListDomains_601238, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutAttributes_601286 = ref object of OpenApiRestCall_600421
proc url_PostPutAttributes_601288(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPutAttributes_601287(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_601289 = query.getOrDefault("SignatureMethod")
  valid_601289 = validateParameter(valid_601289, JString, required = true,
                                 default = nil)
  if valid_601289 != nil:
    section.add "SignatureMethod", valid_601289
  var valid_601290 = query.getOrDefault("Signature")
  valid_601290 = validateParameter(valid_601290, JString, required = true,
                                 default = nil)
  if valid_601290 != nil:
    section.add "Signature", valid_601290
  var valid_601291 = query.getOrDefault("Action")
  valid_601291 = validateParameter(valid_601291, JString, required = true,
                                 default = newJString("PutAttributes"))
  if valid_601291 != nil:
    section.add "Action", valid_601291
  var valid_601292 = query.getOrDefault("Timestamp")
  valid_601292 = validateParameter(valid_601292, JString, required = true,
                                 default = nil)
  if valid_601292 != nil:
    section.add "Timestamp", valid_601292
  var valid_601293 = query.getOrDefault("SignatureVersion")
  valid_601293 = validateParameter(valid_601293, JString, required = true,
                                 default = nil)
  if valid_601293 != nil:
    section.add "SignatureVersion", valid_601293
  var valid_601294 = query.getOrDefault("AWSAccessKeyId")
  valid_601294 = validateParameter(valid_601294, JString, required = true,
                                 default = nil)
  if valid_601294 != nil:
    section.add "AWSAccessKeyId", valid_601294
  var valid_601295 = query.getOrDefault("Version")
  valid_601295 = validateParameter(valid_601295, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601295 != nil:
    section.add "Version", valid_601295
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain in which to perform the operation.
  ##   ItemName: JString (required)
  ##           : The name of the item.
  ##   Expected.Exists: JString
  ##                  :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## A value specifying whether or not the specified attribute must exist with the specified value in order for the update condition to be satisfied. Specify <code>true</code> if the attribute must exist for the update condition to be satisfied. Specify <code>false</code> if the attribute should not exist in order for the update condition to be satisfied.
  ##   Attributes: JArray (required)
  ##             : The list of attributes.
  ##   Expected.Value: JString
  ##                 :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The value of an attribute. This value can only be specified when the <code>Exists</code> parameter is equal to <code>true</code>.
  ##   Expected.Name: JString
  ##                :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The name of the attribute involved in the condition.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601296 = formData.getOrDefault("DomainName")
  valid_601296 = validateParameter(valid_601296, JString, required = true,
                                 default = nil)
  if valid_601296 != nil:
    section.add "DomainName", valid_601296
  var valid_601297 = formData.getOrDefault("ItemName")
  valid_601297 = validateParameter(valid_601297, JString, required = true,
                                 default = nil)
  if valid_601297 != nil:
    section.add "ItemName", valid_601297
  var valid_601298 = formData.getOrDefault("Expected.Exists")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "Expected.Exists", valid_601298
  var valid_601299 = formData.getOrDefault("Attributes")
  valid_601299 = validateParameter(valid_601299, JArray, required = true, default = nil)
  if valid_601299 != nil:
    section.add "Attributes", valid_601299
  var valid_601300 = formData.getOrDefault("Expected.Value")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "Expected.Value", valid_601300
  var valid_601301 = formData.getOrDefault("Expected.Name")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "Expected.Name", valid_601301
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601302: Call_PostPutAttributes_601286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  let valid = call_601302.validator(path, query, header, formData, body)
  let scheme = call_601302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601302.url(scheme.get, call_601302.host, call_601302.base,
                         call_601302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601302, url, valid)

proc call*(call_601303: Call_PostPutAttributes_601286; SignatureMethod: string;
          DomainName: string; ItemName: string; Signature: string;
          Attributes: JsonNode; Timestamp: string; SignatureVersion: string;
          AWSAccessKeyId: string; ExpectedExists: string = "";
          Action: string = "PutAttributes"; ExpectedValue: string = "";
          ExpectedName: string = ""; Version: string = "2009-04-15"): Recallable =
  ## postPutAttributes
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain in which to perform the operation.
  ##   ItemName: string (required)
  ##           : The name of the item.
  ##   ExpectedExists: string
  ##                 :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## A value specifying whether or not the specified attribute must exist with the specified value in order for the update condition to be satisfied. Specify <code>true</code> if the attribute must exist for the update condition to be satisfied. Specify <code>false</code> if the attribute should not exist in order for the update condition to be satisfied.
  ##   Signature: string (required)
  ##   Attributes: JArray (required)
  ##             : The list of attributes.
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   ExpectedValue: string
  ##                :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The value of an attribute. This value can only be specified when the <code>Exists</code> parameter is equal to <code>true</code>.
  ##   ExpectedName: string
  ##               :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The name of the attribute involved in the condition.
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_601304 = newJObject()
  var formData_601305 = newJObject()
  add(query_601304, "SignatureMethod", newJString(SignatureMethod))
  add(formData_601305, "DomainName", newJString(DomainName))
  add(formData_601305, "ItemName", newJString(ItemName))
  add(formData_601305, "Expected.Exists", newJString(ExpectedExists))
  add(query_601304, "Signature", newJString(Signature))
  if Attributes != nil:
    formData_601305.add "Attributes", Attributes
  add(query_601304, "Action", newJString(Action))
  add(query_601304, "Timestamp", newJString(Timestamp))
  add(formData_601305, "Expected.Value", newJString(ExpectedValue))
  add(formData_601305, "Expected.Name", newJString(ExpectedName))
  add(query_601304, "SignatureVersion", newJString(SignatureVersion))
  add(query_601304, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601304, "Version", newJString(Version))
  result = call_601303.call(nil, query_601304, nil, formData_601305, nil)

var postPutAttributes* = Call_PostPutAttributes_601286(name: "postPutAttributes",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=PutAttributes", validator: validate_PostPutAttributes_601287,
    base: "/", url: url_PostPutAttributes_601288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutAttributes_601267 = ref object of OpenApiRestCall_600421
proc url_GetPutAttributes_601269(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPutAttributes_601268(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Expected.Exists: JString
  ##                  :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## A value specifying whether or not the specified attribute must exist with the specified value in order for the update condition to be satisfied. Specify <code>true</code> if the attribute must exist for the update condition to be satisfied. Specify <code>false</code> if the attribute should not exist in order for the update condition to be satisfied.
  ##   Attributes: JArray (required)
  ##             : The list of attributes.
  ##   Signature: JString (required)
  ##   ItemName: JString (required)
  ##           : The name of the item.
  ##   Action: JString (required)
  ##   Expected.Value: JString
  ##                 :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The value of an attribute. This value can only be specified when the <code>Exists</code> parameter is equal to <code>true</code>.
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Expected.Name: JString
  ##                :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The name of the attribute involved in the condition.
  ##   DomainName: JString (required)
  ##             : The name of the domain in which to perform the operation.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_601270 = query.getOrDefault("SignatureMethod")
  valid_601270 = validateParameter(valid_601270, JString, required = true,
                                 default = nil)
  if valid_601270 != nil:
    section.add "SignatureMethod", valid_601270
  var valid_601271 = query.getOrDefault("Expected.Exists")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "Expected.Exists", valid_601271
  var valid_601272 = query.getOrDefault("Attributes")
  valid_601272 = validateParameter(valid_601272, JArray, required = true, default = nil)
  if valid_601272 != nil:
    section.add "Attributes", valid_601272
  var valid_601273 = query.getOrDefault("Signature")
  valid_601273 = validateParameter(valid_601273, JString, required = true,
                                 default = nil)
  if valid_601273 != nil:
    section.add "Signature", valid_601273
  var valid_601274 = query.getOrDefault("ItemName")
  valid_601274 = validateParameter(valid_601274, JString, required = true,
                                 default = nil)
  if valid_601274 != nil:
    section.add "ItemName", valid_601274
  var valid_601275 = query.getOrDefault("Action")
  valid_601275 = validateParameter(valid_601275, JString, required = true,
                                 default = newJString("PutAttributes"))
  if valid_601275 != nil:
    section.add "Action", valid_601275
  var valid_601276 = query.getOrDefault("Expected.Value")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "Expected.Value", valid_601276
  var valid_601277 = query.getOrDefault("Timestamp")
  valid_601277 = validateParameter(valid_601277, JString, required = true,
                                 default = nil)
  if valid_601277 != nil:
    section.add "Timestamp", valid_601277
  var valid_601278 = query.getOrDefault("SignatureVersion")
  valid_601278 = validateParameter(valid_601278, JString, required = true,
                                 default = nil)
  if valid_601278 != nil:
    section.add "SignatureVersion", valid_601278
  var valid_601279 = query.getOrDefault("AWSAccessKeyId")
  valid_601279 = validateParameter(valid_601279, JString, required = true,
                                 default = nil)
  if valid_601279 != nil:
    section.add "AWSAccessKeyId", valid_601279
  var valid_601280 = query.getOrDefault("Expected.Name")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "Expected.Name", valid_601280
  var valid_601281 = query.getOrDefault("DomainName")
  valid_601281 = validateParameter(valid_601281, JString, required = true,
                                 default = nil)
  if valid_601281 != nil:
    section.add "DomainName", valid_601281
  var valid_601282 = query.getOrDefault("Version")
  valid_601282 = validateParameter(valid_601282, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601282 != nil:
    section.add "Version", valid_601282
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601283: Call_GetPutAttributes_601267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  let valid = call_601283.validator(path, query, header, formData, body)
  let scheme = call_601283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601283.url(scheme.get, call_601283.host, call_601283.base,
                         call_601283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601283, url, valid)

proc call*(call_601284: Call_GetPutAttributes_601267; SignatureMethod: string;
          Attributes: JsonNode; Signature: string; ItemName: string;
          Timestamp: string; SignatureVersion: string; AWSAccessKeyId: string;
          DomainName: string; ExpectedExists: string = "";
          Action: string = "PutAttributes"; ExpectedValue: string = "";
          ExpectedName: string = ""; Version: string = "2009-04-15"): Recallable =
  ## getPutAttributes
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ##   SignatureMethod: string (required)
  ##   ExpectedExists: string
  ##                 :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## A value specifying whether or not the specified attribute must exist with the specified value in order for the update condition to be satisfied. Specify <code>true</code> if the attribute must exist for the update condition to be satisfied. Specify <code>false</code> if the attribute should not exist in order for the update condition to be satisfied.
  ##   Attributes: JArray (required)
  ##             : The list of attributes.
  ##   Signature: string (required)
  ##   ItemName: string (required)
  ##           : The name of the item.
  ##   Action: string (required)
  ##   ExpectedValue: string
  ##                :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The value of an attribute. This value can only be specified when the <code>Exists</code> parameter is equal to <code>true</code>.
  ##   Timestamp: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   ExpectedName: string
  ##               :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The name of the attribute involved in the condition.
  ##   DomainName: string (required)
  ##             : The name of the domain in which to perform the operation.
  ##   Version: string (required)
  var query_601285 = newJObject()
  add(query_601285, "SignatureMethod", newJString(SignatureMethod))
  add(query_601285, "Expected.Exists", newJString(ExpectedExists))
  if Attributes != nil:
    query_601285.add "Attributes", Attributes
  add(query_601285, "Signature", newJString(Signature))
  add(query_601285, "ItemName", newJString(ItemName))
  add(query_601285, "Action", newJString(Action))
  add(query_601285, "Expected.Value", newJString(ExpectedValue))
  add(query_601285, "Timestamp", newJString(Timestamp))
  add(query_601285, "SignatureVersion", newJString(SignatureVersion))
  add(query_601285, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601285, "Expected.Name", newJString(ExpectedName))
  add(query_601285, "DomainName", newJString(DomainName))
  add(query_601285, "Version", newJString(Version))
  result = call_601284.call(nil, query_601285, nil, nil, nil)

var getPutAttributes* = Call_GetPutAttributes_601267(name: "getPutAttributes",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=PutAttributes", validator: validate_GetPutAttributes_601268,
    base: "/", url: url_GetPutAttributes_601269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSelect_601322 = ref object of OpenApiRestCall_600421
proc url_PostSelect_601324(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSelect_601323(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_601325 = query.getOrDefault("SignatureMethod")
  valid_601325 = validateParameter(valid_601325, JString, required = true,
                                 default = nil)
  if valid_601325 != nil:
    section.add "SignatureMethod", valid_601325
  var valid_601326 = query.getOrDefault("Signature")
  valid_601326 = validateParameter(valid_601326, JString, required = true,
                                 default = nil)
  if valid_601326 != nil:
    section.add "Signature", valid_601326
  var valid_601327 = query.getOrDefault("Action")
  valid_601327 = validateParameter(valid_601327, JString, required = true,
                                 default = newJString("Select"))
  if valid_601327 != nil:
    section.add "Action", valid_601327
  var valid_601328 = query.getOrDefault("Timestamp")
  valid_601328 = validateParameter(valid_601328, JString, required = true,
                                 default = nil)
  if valid_601328 != nil:
    section.add "Timestamp", valid_601328
  var valid_601329 = query.getOrDefault("SignatureVersion")
  valid_601329 = validateParameter(valid_601329, JString, required = true,
                                 default = nil)
  if valid_601329 != nil:
    section.add "SignatureVersion", valid_601329
  var valid_601330 = query.getOrDefault("AWSAccessKeyId")
  valid_601330 = validateParameter(valid_601330, JString, required = true,
                                 default = nil)
  if valid_601330 != nil:
    section.add "AWSAccessKeyId", valid_601330
  var valid_601331 = query.getOrDefault("Version")
  valid_601331 = validateParameter(valid_601331, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601331 != nil:
    section.add "Version", valid_601331
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : A string informing Amazon SimpleDB where to start the next list of <code>ItemNames</code>.
  ##   ConsistentRead: JBool
  ##                 : Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If <code>true</code>, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  ##   SelectExpression: JString (required)
  ##                   : The expression used to query the domain.
  section = newJObject()
  var valid_601332 = formData.getOrDefault("NextToken")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "NextToken", valid_601332
  var valid_601333 = formData.getOrDefault("ConsistentRead")
  valid_601333 = validateParameter(valid_601333, JBool, required = false, default = nil)
  if valid_601333 != nil:
    section.add "ConsistentRead", valid_601333
  assert formData != nil, "formData argument is necessary due to required `SelectExpression` field"
  var valid_601334 = formData.getOrDefault("SelectExpression")
  valid_601334 = validateParameter(valid_601334, JString, required = true,
                                 default = nil)
  if valid_601334 != nil:
    section.add "SelectExpression", valid_601334
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601335: Call_PostSelect_601322; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  let valid = call_601335.validator(path, query, header, formData, body)
  let scheme = call_601335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601335.url(scheme.get, call_601335.host, call_601335.base,
                         call_601335.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601335, url, valid)

proc call*(call_601336: Call_PostSelect_601322; SignatureMethod: string;
          Signature: string; Timestamp: string; SignatureVersion: string;
          AWSAccessKeyId: string; SelectExpression: string; NextToken: string = "";
          ConsistentRead: bool = false; Action: string = "Select";
          Version: string = "2009-04-15"): Recallable =
  ## postSelect
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ##   NextToken: string
  ##            : A string informing Amazon SimpleDB where to start the next list of <code>ItemNames</code>.
  ##   SignatureMethod: string (required)
  ##   ConsistentRead: bool
  ##                 : Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If <code>true</code>, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   SelectExpression: string (required)
  ##                   : The expression used to query the domain.
  ##   Version: string (required)
  var query_601337 = newJObject()
  var formData_601338 = newJObject()
  add(formData_601338, "NextToken", newJString(NextToken))
  add(query_601337, "SignatureMethod", newJString(SignatureMethod))
  add(formData_601338, "ConsistentRead", newJBool(ConsistentRead))
  add(query_601337, "Signature", newJString(Signature))
  add(query_601337, "Action", newJString(Action))
  add(query_601337, "Timestamp", newJString(Timestamp))
  add(query_601337, "SignatureVersion", newJString(SignatureVersion))
  add(query_601337, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_601338, "SelectExpression", newJString(SelectExpression))
  add(query_601337, "Version", newJString(Version))
  result = call_601336.call(nil, query_601337, nil, formData_601338, nil)

var postSelect* = Call_PostSelect_601322(name: "postSelect",
                                      meth: HttpMethod.HttpPost,
                                      host: "sdb.amazonaws.com",
                                      route: "/#Action=Select",
                                      validator: validate_PostSelect_601323,
                                      base: "/", url: url_PostSelect_601324,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSelect_601306 = ref object of OpenApiRestCall_600421
proc url_GetSelect_601308(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSelect_601307(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   NextToken: JString
  ##            : A string informing Amazon SimpleDB where to start the next list of <code>ItemNames</code>.
  ##   SelectExpression: JString (required)
  ##                   : The expression used to query the domain.
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   ConsistentRead: JBool
  ##                 : Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If <code>true</code>, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_601309 = query.getOrDefault("SignatureMethod")
  valid_601309 = validateParameter(valid_601309, JString, required = true,
                                 default = nil)
  if valid_601309 != nil:
    section.add "SignatureMethod", valid_601309
  var valid_601310 = query.getOrDefault("Signature")
  valid_601310 = validateParameter(valid_601310, JString, required = true,
                                 default = nil)
  if valid_601310 != nil:
    section.add "Signature", valid_601310
  var valid_601311 = query.getOrDefault("NextToken")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "NextToken", valid_601311
  var valid_601312 = query.getOrDefault("SelectExpression")
  valid_601312 = validateParameter(valid_601312, JString, required = true,
                                 default = nil)
  if valid_601312 != nil:
    section.add "SelectExpression", valid_601312
  var valid_601313 = query.getOrDefault("Action")
  valid_601313 = validateParameter(valid_601313, JString, required = true,
                                 default = newJString("Select"))
  if valid_601313 != nil:
    section.add "Action", valid_601313
  var valid_601314 = query.getOrDefault("Timestamp")
  valid_601314 = validateParameter(valid_601314, JString, required = true,
                                 default = nil)
  if valid_601314 != nil:
    section.add "Timestamp", valid_601314
  var valid_601315 = query.getOrDefault("ConsistentRead")
  valid_601315 = validateParameter(valid_601315, JBool, required = false, default = nil)
  if valid_601315 != nil:
    section.add "ConsistentRead", valid_601315
  var valid_601316 = query.getOrDefault("SignatureVersion")
  valid_601316 = validateParameter(valid_601316, JString, required = true,
                                 default = nil)
  if valid_601316 != nil:
    section.add "SignatureVersion", valid_601316
  var valid_601317 = query.getOrDefault("AWSAccessKeyId")
  valid_601317 = validateParameter(valid_601317, JString, required = true,
                                 default = nil)
  if valid_601317 != nil:
    section.add "AWSAccessKeyId", valid_601317
  var valid_601318 = query.getOrDefault("Version")
  valid_601318 = validateParameter(valid_601318, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601318 != nil:
    section.add "Version", valid_601318
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601319: Call_GetSelect_601306; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  let valid = call_601319.validator(path, query, header, formData, body)
  let scheme = call_601319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601319.url(scheme.get, call_601319.host, call_601319.base,
                         call_601319.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601319, url, valid)

proc call*(call_601320: Call_GetSelect_601306; SignatureMethod: string;
          Signature: string; SelectExpression: string; Timestamp: string;
          SignatureVersion: string; AWSAccessKeyId: string; NextToken: string = "";
          Action: string = "Select"; ConsistentRead: bool = false;
          Version: string = "2009-04-15"): Recallable =
  ## getSelect
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ##   SignatureMethod: string (required)
  ##   Signature: string (required)
  ##   NextToken: string
  ##            : A string informing Amazon SimpleDB where to start the next list of <code>ItemNames</code>.
  ##   SelectExpression: string (required)
  ##                   : The expression used to query the domain.
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   ConsistentRead: bool
  ##                 : Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If <code>true</code>, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_601321 = newJObject()
  add(query_601321, "SignatureMethod", newJString(SignatureMethod))
  add(query_601321, "Signature", newJString(Signature))
  add(query_601321, "NextToken", newJString(NextToken))
  add(query_601321, "SelectExpression", newJString(SelectExpression))
  add(query_601321, "Action", newJString(Action))
  add(query_601321, "Timestamp", newJString(Timestamp))
  add(query_601321, "ConsistentRead", newJBool(ConsistentRead))
  add(query_601321, "SignatureVersion", newJString(SignatureVersion))
  add(query_601321, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601321, "Version", newJString(Version))
  result = call_601320.call(nil, query_601321, nil, nil, nil)

var getSelect* = Call_GetSelect_601306(name: "getSelect", meth: HttpMethod.HttpGet,
                                    host: "sdb.amazonaws.com",
                                    route: "/#Action=Select",
                                    validator: validate_GetSelect_601307,
                                    base: "/", url: url_GetSelect_601308,
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
