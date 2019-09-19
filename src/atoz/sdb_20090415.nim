
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_600410 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600410](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600410): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_PostBatchDeleteAttributes_601022 = ref object of OpenApiRestCall_600410
proc url_PostBatchDeleteAttributes_601024(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostBatchDeleteAttributes_601023(path: JsonNode; query: JsonNode;
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
  var valid_601025 = query.getOrDefault("SignatureMethod")
  valid_601025 = validateParameter(valid_601025, JString, required = true,
                                 default = nil)
  if valid_601025 != nil:
    section.add "SignatureMethod", valid_601025
  var valid_601026 = query.getOrDefault("Signature")
  valid_601026 = validateParameter(valid_601026, JString, required = true,
                                 default = nil)
  if valid_601026 != nil:
    section.add "Signature", valid_601026
  var valid_601027 = query.getOrDefault("Action")
  valid_601027 = validateParameter(valid_601027, JString, required = true,
                                 default = newJString("BatchDeleteAttributes"))
  if valid_601027 != nil:
    section.add "Action", valid_601027
  var valid_601028 = query.getOrDefault("Timestamp")
  valid_601028 = validateParameter(valid_601028, JString, required = true,
                                 default = nil)
  if valid_601028 != nil:
    section.add "Timestamp", valid_601028
  var valid_601029 = query.getOrDefault("SignatureVersion")
  valid_601029 = validateParameter(valid_601029, JString, required = true,
                                 default = nil)
  if valid_601029 != nil:
    section.add "SignatureVersion", valid_601029
  var valid_601030 = query.getOrDefault("AWSAccessKeyId")
  valid_601030 = validateParameter(valid_601030, JString, required = true,
                                 default = nil)
  if valid_601030 != nil:
    section.add "AWSAccessKeyId", valid_601030
  var valid_601031 = query.getOrDefault("Version")
  valid_601031 = validateParameter(valid_601031, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601031 != nil:
    section.add "Version", valid_601031
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
  var valid_601032 = formData.getOrDefault("DomainName")
  valid_601032 = validateParameter(valid_601032, JString, required = true,
                                 default = nil)
  if valid_601032 != nil:
    section.add "DomainName", valid_601032
  var valid_601033 = formData.getOrDefault("Items")
  valid_601033 = validateParameter(valid_601033, JArray, required = true, default = nil)
  if valid_601033 != nil:
    section.add "Items", valid_601033
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601034: Call_PostBatchDeleteAttributes_601022; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  let valid = call_601034.validator(path, query, header, formData, body)
  let scheme = call_601034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601034.url(scheme.get, call_601034.host, call_601034.base,
                         call_601034.route, valid.getOrDefault("path"))
  result = hook(call_601034, url, valid)

proc call*(call_601035: Call_PostBatchDeleteAttributes_601022;
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
  var query_601036 = newJObject()
  var formData_601037 = newJObject()
  add(query_601036, "SignatureMethod", newJString(SignatureMethod))
  add(formData_601037, "DomainName", newJString(DomainName))
  add(query_601036, "Signature", newJString(Signature))
  add(query_601036, "Action", newJString(Action))
  add(query_601036, "Timestamp", newJString(Timestamp))
  if Items != nil:
    formData_601037.add "Items", Items
  add(query_601036, "SignatureVersion", newJString(SignatureVersion))
  add(query_601036, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601036, "Version", newJString(Version))
  result = call_601035.call(nil, query_601036, nil, formData_601037, nil)

var postBatchDeleteAttributes* = Call_PostBatchDeleteAttributes_601022(
    name: "postBatchDeleteAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=BatchDeleteAttributes",
    validator: validate_PostBatchDeleteAttributes_601023, base: "/",
    url: url_PostBatchDeleteAttributes_601024,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBatchDeleteAttributes_600752 = ref object of OpenApiRestCall_600410
proc url_GetBatchDeleteAttributes_600754(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetBatchDeleteAttributes_600753(path: JsonNode; query: JsonNode;
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
  var valid_600866 = query.getOrDefault("SignatureMethod")
  valid_600866 = validateParameter(valid_600866, JString, required = true,
                                 default = nil)
  if valid_600866 != nil:
    section.add "SignatureMethod", valid_600866
  var valid_600867 = query.getOrDefault("Signature")
  valid_600867 = validateParameter(valid_600867, JString, required = true,
                                 default = nil)
  if valid_600867 != nil:
    section.add "Signature", valid_600867
  var valid_600881 = query.getOrDefault("Action")
  valid_600881 = validateParameter(valid_600881, JString, required = true,
                                 default = newJString("BatchDeleteAttributes"))
  if valid_600881 != nil:
    section.add "Action", valid_600881
  var valid_600882 = query.getOrDefault("Timestamp")
  valid_600882 = validateParameter(valid_600882, JString, required = true,
                                 default = nil)
  if valid_600882 != nil:
    section.add "Timestamp", valid_600882
  var valid_600883 = query.getOrDefault("Items")
  valid_600883 = validateParameter(valid_600883, JArray, required = true, default = nil)
  if valid_600883 != nil:
    section.add "Items", valid_600883
  var valid_600884 = query.getOrDefault("SignatureVersion")
  valid_600884 = validateParameter(valid_600884, JString, required = true,
                                 default = nil)
  if valid_600884 != nil:
    section.add "SignatureVersion", valid_600884
  var valid_600885 = query.getOrDefault("AWSAccessKeyId")
  valid_600885 = validateParameter(valid_600885, JString, required = true,
                                 default = nil)
  if valid_600885 != nil:
    section.add "AWSAccessKeyId", valid_600885
  var valid_600886 = query.getOrDefault("DomainName")
  valid_600886 = validateParameter(valid_600886, JString, required = true,
                                 default = nil)
  if valid_600886 != nil:
    section.add "DomainName", valid_600886
  var valid_600887 = query.getOrDefault("Version")
  valid_600887 = validateParameter(valid_600887, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_600887 != nil:
    section.add "Version", valid_600887
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600910: Call_GetBatchDeleteAttributes_600752; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  let valid = call_600910.validator(path, query, header, formData, body)
  let scheme = call_600910.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600910.url(scheme.get, call_600910.host, call_600910.base,
                         call_600910.route, valid.getOrDefault("path"))
  result = hook(call_600910, url, valid)

proc call*(call_600981: Call_GetBatchDeleteAttributes_600752;
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
  var query_600982 = newJObject()
  add(query_600982, "SignatureMethod", newJString(SignatureMethod))
  add(query_600982, "Signature", newJString(Signature))
  add(query_600982, "Action", newJString(Action))
  add(query_600982, "Timestamp", newJString(Timestamp))
  if Items != nil:
    query_600982.add "Items", Items
  add(query_600982, "SignatureVersion", newJString(SignatureVersion))
  add(query_600982, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600982, "DomainName", newJString(DomainName))
  add(query_600982, "Version", newJString(Version))
  result = call_600981.call(nil, query_600982, nil, nil, nil)

var getBatchDeleteAttributes* = Call_GetBatchDeleteAttributes_600752(
    name: "getBatchDeleteAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=BatchDeleteAttributes",
    validator: validate_GetBatchDeleteAttributes_600753, base: "/",
    url: url_GetBatchDeleteAttributes_600754, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostBatchPutAttributes_601053 = ref object of OpenApiRestCall_600410
proc url_PostBatchPutAttributes_601055(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostBatchPutAttributes_601054(path: JsonNode; query: JsonNode;
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
  var valid_601056 = query.getOrDefault("SignatureMethod")
  valid_601056 = validateParameter(valid_601056, JString, required = true,
                                 default = nil)
  if valid_601056 != nil:
    section.add "SignatureMethod", valid_601056
  var valid_601057 = query.getOrDefault("Signature")
  valid_601057 = validateParameter(valid_601057, JString, required = true,
                                 default = nil)
  if valid_601057 != nil:
    section.add "Signature", valid_601057
  var valid_601058 = query.getOrDefault("Action")
  valid_601058 = validateParameter(valid_601058, JString, required = true,
                                 default = newJString("BatchPutAttributes"))
  if valid_601058 != nil:
    section.add "Action", valid_601058
  var valid_601059 = query.getOrDefault("Timestamp")
  valid_601059 = validateParameter(valid_601059, JString, required = true,
                                 default = nil)
  if valid_601059 != nil:
    section.add "Timestamp", valid_601059
  var valid_601060 = query.getOrDefault("SignatureVersion")
  valid_601060 = validateParameter(valid_601060, JString, required = true,
                                 default = nil)
  if valid_601060 != nil:
    section.add "SignatureVersion", valid_601060
  var valid_601061 = query.getOrDefault("AWSAccessKeyId")
  valid_601061 = validateParameter(valid_601061, JString, required = true,
                                 default = nil)
  if valid_601061 != nil:
    section.add "AWSAccessKeyId", valid_601061
  var valid_601062 = query.getOrDefault("Version")
  valid_601062 = validateParameter(valid_601062, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601062 != nil:
    section.add "Version", valid_601062
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
  var valid_601063 = formData.getOrDefault("DomainName")
  valid_601063 = validateParameter(valid_601063, JString, required = true,
                                 default = nil)
  if valid_601063 != nil:
    section.add "DomainName", valid_601063
  var valid_601064 = formData.getOrDefault("Items")
  valid_601064 = validateParameter(valid_601064, JArray, required = true, default = nil)
  if valid_601064 != nil:
    section.add "Items", valid_601064
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601065: Call_PostBatchPutAttributes_601053; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  let valid = call_601065.validator(path, query, header, formData, body)
  let scheme = call_601065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601065.url(scheme.get, call_601065.host, call_601065.base,
                         call_601065.route, valid.getOrDefault("path"))
  result = hook(call_601065, url, valid)

proc call*(call_601066: Call_PostBatchPutAttributes_601053;
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
  var query_601067 = newJObject()
  var formData_601068 = newJObject()
  add(query_601067, "SignatureMethod", newJString(SignatureMethod))
  add(formData_601068, "DomainName", newJString(DomainName))
  add(query_601067, "Signature", newJString(Signature))
  add(query_601067, "Action", newJString(Action))
  add(query_601067, "Timestamp", newJString(Timestamp))
  if Items != nil:
    formData_601068.add "Items", Items
  add(query_601067, "SignatureVersion", newJString(SignatureVersion))
  add(query_601067, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601067, "Version", newJString(Version))
  result = call_601066.call(nil, query_601067, nil, formData_601068, nil)

var postBatchPutAttributes* = Call_PostBatchPutAttributes_601053(
    name: "postBatchPutAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=BatchPutAttributes",
    validator: validate_PostBatchPutAttributes_601054, base: "/",
    url: url_PostBatchPutAttributes_601055, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBatchPutAttributes_601038 = ref object of OpenApiRestCall_600410
proc url_GetBatchPutAttributes_601040(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetBatchPutAttributes_601039(path: JsonNode; query: JsonNode;
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
  var valid_601041 = query.getOrDefault("SignatureMethod")
  valid_601041 = validateParameter(valid_601041, JString, required = true,
                                 default = nil)
  if valid_601041 != nil:
    section.add "SignatureMethod", valid_601041
  var valid_601042 = query.getOrDefault("Signature")
  valid_601042 = validateParameter(valid_601042, JString, required = true,
                                 default = nil)
  if valid_601042 != nil:
    section.add "Signature", valid_601042
  var valid_601043 = query.getOrDefault("Action")
  valid_601043 = validateParameter(valid_601043, JString, required = true,
                                 default = newJString("BatchPutAttributes"))
  if valid_601043 != nil:
    section.add "Action", valid_601043
  var valid_601044 = query.getOrDefault("Timestamp")
  valid_601044 = validateParameter(valid_601044, JString, required = true,
                                 default = nil)
  if valid_601044 != nil:
    section.add "Timestamp", valid_601044
  var valid_601045 = query.getOrDefault("Items")
  valid_601045 = validateParameter(valid_601045, JArray, required = true, default = nil)
  if valid_601045 != nil:
    section.add "Items", valid_601045
  var valid_601046 = query.getOrDefault("SignatureVersion")
  valid_601046 = validateParameter(valid_601046, JString, required = true,
                                 default = nil)
  if valid_601046 != nil:
    section.add "SignatureVersion", valid_601046
  var valid_601047 = query.getOrDefault("AWSAccessKeyId")
  valid_601047 = validateParameter(valid_601047, JString, required = true,
                                 default = nil)
  if valid_601047 != nil:
    section.add "AWSAccessKeyId", valid_601047
  var valid_601048 = query.getOrDefault("DomainName")
  valid_601048 = validateParameter(valid_601048, JString, required = true,
                                 default = nil)
  if valid_601048 != nil:
    section.add "DomainName", valid_601048
  var valid_601049 = query.getOrDefault("Version")
  valid_601049 = validateParameter(valid_601049, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601049 != nil:
    section.add "Version", valid_601049
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601050: Call_GetBatchPutAttributes_601038; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  let valid = call_601050.validator(path, query, header, formData, body)
  let scheme = call_601050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601050.url(scheme.get, call_601050.host, call_601050.base,
                         call_601050.route, valid.getOrDefault("path"))
  result = hook(call_601050, url, valid)

proc call*(call_601051: Call_GetBatchPutAttributes_601038; SignatureMethod: string;
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
  var query_601052 = newJObject()
  add(query_601052, "SignatureMethod", newJString(SignatureMethod))
  add(query_601052, "Signature", newJString(Signature))
  add(query_601052, "Action", newJString(Action))
  add(query_601052, "Timestamp", newJString(Timestamp))
  if Items != nil:
    query_601052.add "Items", Items
  add(query_601052, "SignatureVersion", newJString(SignatureVersion))
  add(query_601052, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601052, "DomainName", newJString(DomainName))
  add(query_601052, "Version", newJString(Version))
  result = call_601051.call(nil, query_601052, nil, nil, nil)

var getBatchPutAttributes* = Call_GetBatchPutAttributes_601038(
    name: "getBatchPutAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=BatchPutAttributes",
    validator: validate_GetBatchPutAttributes_601039, base: "/",
    url: url_GetBatchPutAttributes_601040, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDomain_601083 = ref object of OpenApiRestCall_600410
proc url_PostCreateDomain_601085(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDomain_601084(path: JsonNode; query: JsonNode;
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
  var valid_601086 = query.getOrDefault("SignatureMethod")
  valid_601086 = validateParameter(valid_601086, JString, required = true,
                                 default = nil)
  if valid_601086 != nil:
    section.add "SignatureMethod", valid_601086
  var valid_601087 = query.getOrDefault("Signature")
  valid_601087 = validateParameter(valid_601087, JString, required = true,
                                 default = nil)
  if valid_601087 != nil:
    section.add "Signature", valid_601087
  var valid_601088 = query.getOrDefault("Action")
  valid_601088 = validateParameter(valid_601088, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_601088 != nil:
    section.add "Action", valid_601088
  var valid_601089 = query.getOrDefault("Timestamp")
  valid_601089 = validateParameter(valid_601089, JString, required = true,
                                 default = nil)
  if valid_601089 != nil:
    section.add "Timestamp", valid_601089
  var valid_601090 = query.getOrDefault("SignatureVersion")
  valid_601090 = validateParameter(valid_601090, JString, required = true,
                                 default = nil)
  if valid_601090 != nil:
    section.add "SignatureVersion", valid_601090
  var valid_601091 = query.getOrDefault("AWSAccessKeyId")
  valid_601091 = validateParameter(valid_601091, JString, required = true,
                                 default = nil)
  if valid_601091 != nil:
    section.add "AWSAccessKeyId", valid_601091
  var valid_601092 = query.getOrDefault("Version")
  valid_601092 = validateParameter(valid_601092, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601092 != nil:
    section.add "Version", valid_601092
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain to create. The name can range between 3 and 255 characters and can contain the following characters: a-z, A-Z, 0-9, '_', '-', and '.'.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601093 = formData.getOrDefault("DomainName")
  valid_601093 = validateParameter(valid_601093, JString, required = true,
                                 default = nil)
  if valid_601093 != nil:
    section.add "DomainName", valid_601093
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601094: Call_PostCreateDomain_601083; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  let valid = call_601094.validator(path, query, header, formData, body)
  let scheme = call_601094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601094.url(scheme.get, call_601094.host, call_601094.base,
                         call_601094.route, valid.getOrDefault("path"))
  result = hook(call_601094, url, valid)

proc call*(call_601095: Call_PostCreateDomain_601083; SignatureMethod: string;
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
  var query_601096 = newJObject()
  var formData_601097 = newJObject()
  add(query_601096, "SignatureMethod", newJString(SignatureMethod))
  add(formData_601097, "DomainName", newJString(DomainName))
  add(query_601096, "Signature", newJString(Signature))
  add(query_601096, "Action", newJString(Action))
  add(query_601096, "Timestamp", newJString(Timestamp))
  add(query_601096, "SignatureVersion", newJString(SignatureVersion))
  add(query_601096, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601096, "Version", newJString(Version))
  result = call_601095.call(nil, query_601096, nil, formData_601097, nil)

var postCreateDomain* = Call_PostCreateDomain_601083(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_601084,
    base: "/", url: url_PostCreateDomain_601085,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_601069 = ref object of OpenApiRestCall_600410
proc url_GetCreateDomain_601071(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDomain_601070(path: JsonNode; query: JsonNode;
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
  var valid_601072 = query.getOrDefault("SignatureMethod")
  valid_601072 = validateParameter(valid_601072, JString, required = true,
                                 default = nil)
  if valid_601072 != nil:
    section.add "SignatureMethod", valid_601072
  var valid_601073 = query.getOrDefault("Signature")
  valid_601073 = validateParameter(valid_601073, JString, required = true,
                                 default = nil)
  if valid_601073 != nil:
    section.add "Signature", valid_601073
  var valid_601074 = query.getOrDefault("Action")
  valid_601074 = validateParameter(valid_601074, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_601074 != nil:
    section.add "Action", valid_601074
  var valid_601075 = query.getOrDefault("Timestamp")
  valid_601075 = validateParameter(valid_601075, JString, required = true,
                                 default = nil)
  if valid_601075 != nil:
    section.add "Timestamp", valid_601075
  var valid_601076 = query.getOrDefault("SignatureVersion")
  valid_601076 = validateParameter(valid_601076, JString, required = true,
                                 default = nil)
  if valid_601076 != nil:
    section.add "SignatureVersion", valid_601076
  var valid_601077 = query.getOrDefault("AWSAccessKeyId")
  valid_601077 = validateParameter(valid_601077, JString, required = true,
                                 default = nil)
  if valid_601077 != nil:
    section.add "AWSAccessKeyId", valid_601077
  var valid_601078 = query.getOrDefault("DomainName")
  valid_601078 = validateParameter(valid_601078, JString, required = true,
                                 default = nil)
  if valid_601078 != nil:
    section.add "DomainName", valid_601078
  var valid_601079 = query.getOrDefault("Version")
  valid_601079 = validateParameter(valid_601079, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601079 != nil:
    section.add "Version", valid_601079
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601080: Call_GetCreateDomain_601069; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  let valid = call_601080.validator(path, query, header, formData, body)
  let scheme = call_601080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601080.url(scheme.get, call_601080.host, call_601080.base,
                         call_601080.route, valid.getOrDefault("path"))
  result = hook(call_601080, url, valid)

proc call*(call_601081: Call_GetCreateDomain_601069; SignatureMethod: string;
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
  var query_601082 = newJObject()
  add(query_601082, "SignatureMethod", newJString(SignatureMethod))
  add(query_601082, "Signature", newJString(Signature))
  add(query_601082, "Action", newJString(Action))
  add(query_601082, "Timestamp", newJString(Timestamp))
  add(query_601082, "SignatureVersion", newJString(SignatureVersion))
  add(query_601082, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601082, "DomainName", newJString(DomainName))
  add(query_601082, "Version", newJString(Version))
  result = call_601081.call(nil, query_601082, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_601069(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_601070,
    base: "/", url: url_GetCreateDomain_601071, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAttributes_601117 = ref object of OpenApiRestCall_600410
proc url_PostDeleteAttributes_601119(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteAttributes_601118(path: JsonNode; query: JsonNode;
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
  var valid_601120 = query.getOrDefault("SignatureMethod")
  valid_601120 = validateParameter(valid_601120, JString, required = true,
                                 default = nil)
  if valid_601120 != nil:
    section.add "SignatureMethod", valid_601120
  var valid_601121 = query.getOrDefault("Signature")
  valid_601121 = validateParameter(valid_601121, JString, required = true,
                                 default = nil)
  if valid_601121 != nil:
    section.add "Signature", valid_601121
  var valid_601122 = query.getOrDefault("Action")
  valid_601122 = validateParameter(valid_601122, JString, required = true,
                                 default = newJString("DeleteAttributes"))
  if valid_601122 != nil:
    section.add "Action", valid_601122
  var valid_601123 = query.getOrDefault("Timestamp")
  valid_601123 = validateParameter(valid_601123, JString, required = true,
                                 default = nil)
  if valid_601123 != nil:
    section.add "Timestamp", valid_601123
  var valid_601124 = query.getOrDefault("SignatureVersion")
  valid_601124 = validateParameter(valid_601124, JString, required = true,
                                 default = nil)
  if valid_601124 != nil:
    section.add "SignatureVersion", valid_601124
  var valid_601125 = query.getOrDefault("AWSAccessKeyId")
  valid_601125 = validateParameter(valid_601125, JString, required = true,
                                 default = nil)
  if valid_601125 != nil:
    section.add "AWSAccessKeyId", valid_601125
  var valid_601126 = query.getOrDefault("Version")
  valid_601126 = validateParameter(valid_601126, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601126 != nil:
    section.add "Version", valid_601126
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
  var valid_601127 = formData.getOrDefault("DomainName")
  valid_601127 = validateParameter(valid_601127, JString, required = true,
                                 default = nil)
  if valid_601127 != nil:
    section.add "DomainName", valid_601127
  var valid_601128 = formData.getOrDefault("ItemName")
  valid_601128 = validateParameter(valid_601128, JString, required = true,
                                 default = nil)
  if valid_601128 != nil:
    section.add "ItemName", valid_601128
  var valid_601129 = formData.getOrDefault("Expected.Exists")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "Expected.Exists", valid_601129
  var valid_601130 = formData.getOrDefault("Attributes")
  valid_601130 = validateParameter(valid_601130, JArray, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "Attributes", valid_601130
  var valid_601131 = formData.getOrDefault("Expected.Value")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "Expected.Value", valid_601131
  var valid_601132 = formData.getOrDefault("Expected.Name")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "Expected.Name", valid_601132
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601133: Call_PostDeleteAttributes_601117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  let valid = call_601133.validator(path, query, header, formData, body)
  let scheme = call_601133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601133.url(scheme.get, call_601133.host, call_601133.base,
                         call_601133.route, valid.getOrDefault("path"))
  result = hook(call_601133, url, valid)

proc call*(call_601134: Call_PostDeleteAttributes_601117; SignatureMethod: string;
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
  var query_601135 = newJObject()
  var formData_601136 = newJObject()
  add(query_601135, "SignatureMethod", newJString(SignatureMethod))
  add(formData_601136, "DomainName", newJString(DomainName))
  add(formData_601136, "ItemName", newJString(ItemName))
  add(formData_601136, "Expected.Exists", newJString(ExpectedExists))
  add(query_601135, "Signature", newJString(Signature))
  if Attributes != nil:
    formData_601136.add "Attributes", Attributes
  add(query_601135, "Action", newJString(Action))
  add(query_601135, "Timestamp", newJString(Timestamp))
  add(formData_601136, "Expected.Value", newJString(ExpectedValue))
  add(formData_601136, "Expected.Name", newJString(ExpectedName))
  add(query_601135, "SignatureVersion", newJString(SignatureVersion))
  add(query_601135, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601135, "Version", newJString(Version))
  result = call_601134.call(nil, query_601135, nil, formData_601136, nil)

var postDeleteAttributes* = Call_PostDeleteAttributes_601117(
    name: "postDeleteAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=DeleteAttributes",
    validator: validate_PostDeleteAttributes_601118, base: "/",
    url: url_PostDeleteAttributes_601119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAttributes_601098 = ref object of OpenApiRestCall_600410
proc url_GetDeleteAttributes_601100(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteAttributes_601099(path: JsonNode; query: JsonNode;
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
  var valid_601101 = query.getOrDefault("SignatureMethod")
  valid_601101 = validateParameter(valid_601101, JString, required = true,
                                 default = nil)
  if valid_601101 != nil:
    section.add "SignatureMethod", valid_601101
  var valid_601102 = query.getOrDefault("Expected.Exists")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "Expected.Exists", valid_601102
  var valid_601103 = query.getOrDefault("Attributes")
  valid_601103 = validateParameter(valid_601103, JArray, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "Attributes", valid_601103
  var valid_601104 = query.getOrDefault("Signature")
  valid_601104 = validateParameter(valid_601104, JString, required = true,
                                 default = nil)
  if valid_601104 != nil:
    section.add "Signature", valid_601104
  var valid_601105 = query.getOrDefault("ItemName")
  valid_601105 = validateParameter(valid_601105, JString, required = true,
                                 default = nil)
  if valid_601105 != nil:
    section.add "ItemName", valid_601105
  var valid_601106 = query.getOrDefault("Action")
  valid_601106 = validateParameter(valid_601106, JString, required = true,
                                 default = newJString("DeleteAttributes"))
  if valid_601106 != nil:
    section.add "Action", valid_601106
  var valid_601107 = query.getOrDefault("Expected.Value")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "Expected.Value", valid_601107
  var valid_601108 = query.getOrDefault("Timestamp")
  valid_601108 = validateParameter(valid_601108, JString, required = true,
                                 default = nil)
  if valid_601108 != nil:
    section.add "Timestamp", valid_601108
  var valid_601109 = query.getOrDefault("SignatureVersion")
  valid_601109 = validateParameter(valid_601109, JString, required = true,
                                 default = nil)
  if valid_601109 != nil:
    section.add "SignatureVersion", valid_601109
  var valid_601110 = query.getOrDefault("AWSAccessKeyId")
  valid_601110 = validateParameter(valid_601110, JString, required = true,
                                 default = nil)
  if valid_601110 != nil:
    section.add "AWSAccessKeyId", valid_601110
  var valid_601111 = query.getOrDefault("Expected.Name")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "Expected.Name", valid_601111
  var valid_601112 = query.getOrDefault("DomainName")
  valid_601112 = validateParameter(valid_601112, JString, required = true,
                                 default = nil)
  if valid_601112 != nil:
    section.add "DomainName", valid_601112
  var valid_601113 = query.getOrDefault("Version")
  valid_601113 = validateParameter(valid_601113, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601113 != nil:
    section.add "Version", valid_601113
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601114: Call_GetDeleteAttributes_601098; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  let valid = call_601114.validator(path, query, header, formData, body)
  let scheme = call_601114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601114.url(scheme.get, call_601114.host, call_601114.base,
                         call_601114.route, valid.getOrDefault("path"))
  result = hook(call_601114, url, valid)

proc call*(call_601115: Call_GetDeleteAttributes_601098; SignatureMethod: string;
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
  var query_601116 = newJObject()
  add(query_601116, "SignatureMethod", newJString(SignatureMethod))
  add(query_601116, "Expected.Exists", newJString(ExpectedExists))
  if Attributes != nil:
    query_601116.add "Attributes", Attributes
  add(query_601116, "Signature", newJString(Signature))
  add(query_601116, "ItemName", newJString(ItemName))
  add(query_601116, "Action", newJString(Action))
  add(query_601116, "Expected.Value", newJString(ExpectedValue))
  add(query_601116, "Timestamp", newJString(Timestamp))
  add(query_601116, "SignatureVersion", newJString(SignatureVersion))
  add(query_601116, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601116, "Expected.Name", newJString(ExpectedName))
  add(query_601116, "DomainName", newJString(DomainName))
  add(query_601116, "Version", newJString(Version))
  result = call_601115.call(nil, query_601116, nil, nil, nil)

var getDeleteAttributes* = Call_GetDeleteAttributes_601098(
    name: "getDeleteAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=DeleteAttributes",
    validator: validate_GetDeleteAttributes_601099, base: "/",
    url: url_GetDeleteAttributes_601100, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_601151 = ref object of OpenApiRestCall_600410
proc url_PostDeleteDomain_601153(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDomain_601152(path: JsonNode; query: JsonNode;
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
  var valid_601154 = query.getOrDefault("SignatureMethod")
  valid_601154 = validateParameter(valid_601154, JString, required = true,
                                 default = nil)
  if valid_601154 != nil:
    section.add "SignatureMethod", valid_601154
  var valid_601155 = query.getOrDefault("Signature")
  valid_601155 = validateParameter(valid_601155, JString, required = true,
                                 default = nil)
  if valid_601155 != nil:
    section.add "Signature", valid_601155
  var valid_601156 = query.getOrDefault("Action")
  valid_601156 = validateParameter(valid_601156, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_601156 != nil:
    section.add "Action", valid_601156
  var valid_601157 = query.getOrDefault("Timestamp")
  valid_601157 = validateParameter(valid_601157, JString, required = true,
                                 default = nil)
  if valid_601157 != nil:
    section.add "Timestamp", valid_601157
  var valid_601158 = query.getOrDefault("SignatureVersion")
  valid_601158 = validateParameter(valid_601158, JString, required = true,
                                 default = nil)
  if valid_601158 != nil:
    section.add "SignatureVersion", valid_601158
  var valid_601159 = query.getOrDefault("AWSAccessKeyId")
  valid_601159 = validateParameter(valid_601159, JString, required = true,
                                 default = nil)
  if valid_601159 != nil:
    section.add "AWSAccessKeyId", valid_601159
  var valid_601160 = query.getOrDefault("Version")
  valid_601160 = validateParameter(valid_601160, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601160 != nil:
    section.add "Version", valid_601160
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601161 = formData.getOrDefault("DomainName")
  valid_601161 = validateParameter(valid_601161, JString, required = true,
                                 default = nil)
  if valid_601161 != nil:
    section.add "DomainName", valid_601161
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601162: Call_PostDeleteDomain_601151; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  let valid = call_601162.validator(path, query, header, formData, body)
  let scheme = call_601162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601162.url(scheme.get, call_601162.host, call_601162.base,
                         call_601162.route, valid.getOrDefault("path"))
  result = hook(call_601162, url, valid)

proc call*(call_601163: Call_PostDeleteDomain_601151; SignatureMethod: string;
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
  var query_601164 = newJObject()
  var formData_601165 = newJObject()
  add(query_601164, "SignatureMethod", newJString(SignatureMethod))
  add(formData_601165, "DomainName", newJString(DomainName))
  add(query_601164, "Signature", newJString(Signature))
  add(query_601164, "Action", newJString(Action))
  add(query_601164, "Timestamp", newJString(Timestamp))
  add(query_601164, "SignatureVersion", newJString(SignatureVersion))
  add(query_601164, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601164, "Version", newJString(Version))
  result = call_601163.call(nil, query_601164, nil, formData_601165, nil)

var postDeleteDomain* = Call_PostDeleteDomain_601151(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_601152,
    base: "/", url: url_PostDeleteDomain_601153,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_601137 = ref object of OpenApiRestCall_600410
proc url_GetDeleteDomain_601139(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDomain_601138(path: JsonNode; query: JsonNode;
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
  var valid_601140 = query.getOrDefault("SignatureMethod")
  valid_601140 = validateParameter(valid_601140, JString, required = true,
                                 default = nil)
  if valid_601140 != nil:
    section.add "SignatureMethod", valid_601140
  var valid_601141 = query.getOrDefault("Signature")
  valid_601141 = validateParameter(valid_601141, JString, required = true,
                                 default = nil)
  if valid_601141 != nil:
    section.add "Signature", valid_601141
  var valid_601142 = query.getOrDefault("Action")
  valid_601142 = validateParameter(valid_601142, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_601142 != nil:
    section.add "Action", valid_601142
  var valid_601143 = query.getOrDefault("Timestamp")
  valid_601143 = validateParameter(valid_601143, JString, required = true,
                                 default = nil)
  if valid_601143 != nil:
    section.add "Timestamp", valid_601143
  var valid_601144 = query.getOrDefault("SignatureVersion")
  valid_601144 = validateParameter(valid_601144, JString, required = true,
                                 default = nil)
  if valid_601144 != nil:
    section.add "SignatureVersion", valid_601144
  var valid_601145 = query.getOrDefault("AWSAccessKeyId")
  valid_601145 = validateParameter(valid_601145, JString, required = true,
                                 default = nil)
  if valid_601145 != nil:
    section.add "AWSAccessKeyId", valid_601145
  var valid_601146 = query.getOrDefault("DomainName")
  valid_601146 = validateParameter(valid_601146, JString, required = true,
                                 default = nil)
  if valid_601146 != nil:
    section.add "DomainName", valid_601146
  var valid_601147 = query.getOrDefault("Version")
  valid_601147 = validateParameter(valid_601147, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601147 != nil:
    section.add "Version", valid_601147
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601148: Call_GetDeleteDomain_601137; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  let valid = call_601148.validator(path, query, header, formData, body)
  let scheme = call_601148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601148.url(scheme.get, call_601148.host, call_601148.base,
                         call_601148.route, valid.getOrDefault("path"))
  result = hook(call_601148, url, valid)

proc call*(call_601149: Call_GetDeleteDomain_601137; SignatureMethod: string;
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
  var query_601150 = newJObject()
  add(query_601150, "SignatureMethod", newJString(SignatureMethod))
  add(query_601150, "Signature", newJString(Signature))
  add(query_601150, "Action", newJString(Action))
  add(query_601150, "Timestamp", newJString(Timestamp))
  add(query_601150, "SignatureVersion", newJString(SignatureVersion))
  add(query_601150, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601150, "DomainName", newJString(DomainName))
  add(query_601150, "Version", newJString(Version))
  result = call_601149.call(nil, query_601150, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_601137(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_601138,
    base: "/", url: url_GetDeleteDomain_601139, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDomainMetadata_601180 = ref object of OpenApiRestCall_600410
proc url_PostDomainMetadata_601182(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDomainMetadata_601181(path: JsonNode; query: JsonNode;
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
  var valid_601183 = query.getOrDefault("SignatureMethod")
  valid_601183 = validateParameter(valid_601183, JString, required = true,
                                 default = nil)
  if valid_601183 != nil:
    section.add "SignatureMethod", valid_601183
  var valid_601184 = query.getOrDefault("Signature")
  valid_601184 = validateParameter(valid_601184, JString, required = true,
                                 default = nil)
  if valid_601184 != nil:
    section.add "Signature", valid_601184
  var valid_601185 = query.getOrDefault("Action")
  valid_601185 = validateParameter(valid_601185, JString, required = true,
                                 default = newJString("DomainMetadata"))
  if valid_601185 != nil:
    section.add "Action", valid_601185
  var valid_601186 = query.getOrDefault("Timestamp")
  valid_601186 = validateParameter(valid_601186, JString, required = true,
                                 default = nil)
  if valid_601186 != nil:
    section.add "Timestamp", valid_601186
  var valid_601187 = query.getOrDefault("SignatureVersion")
  valid_601187 = validateParameter(valid_601187, JString, required = true,
                                 default = nil)
  if valid_601187 != nil:
    section.add "SignatureVersion", valid_601187
  var valid_601188 = query.getOrDefault("AWSAccessKeyId")
  valid_601188 = validateParameter(valid_601188, JString, required = true,
                                 default = nil)
  if valid_601188 != nil:
    section.add "AWSAccessKeyId", valid_601188
  var valid_601189 = query.getOrDefault("Version")
  valid_601189 = validateParameter(valid_601189, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601189 != nil:
    section.add "Version", valid_601189
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain for which to display the metadata of.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601190 = formData.getOrDefault("DomainName")
  valid_601190 = validateParameter(valid_601190, JString, required = true,
                                 default = nil)
  if valid_601190 != nil:
    section.add "DomainName", valid_601190
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601191: Call_PostDomainMetadata_601180; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  let valid = call_601191.validator(path, query, header, formData, body)
  let scheme = call_601191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601191.url(scheme.get, call_601191.host, call_601191.base,
                         call_601191.route, valid.getOrDefault("path"))
  result = hook(call_601191, url, valid)

proc call*(call_601192: Call_PostDomainMetadata_601180; SignatureMethod: string;
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
  var query_601193 = newJObject()
  var formData_601194 = newJObject()
  add(query_601193, "SignatureMethod", newJString(SignatureMethod))
  add(formData_601194, "DomainName", newJString(DomainName))
  add(query_601193, "Signature", newJString(Signature))
  add(query_601193, "Action", newJString(Action))
  add(query_601193, "Timestamp", newJString(Timestamp))
  add(query_601193, "SignatureVersion", newJString(SignatureVersion))
  add(query_601193, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601193, "Version", newJString(Version))
  result = call_601192.call(nil, query_601193, nil, formData_601194, nil)

var postDomainMetadata* = Call_PostDomainMetadata_601180(
    name: "postDomainMetadata", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=DomainMetadata",
    validator: validate_PostDomainMetadata_601181, base: "/",
    url: url_PostDomainMetadata_601182, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainMetadata_601166 = ref object of OpenApiRestCall_600410
proc url_GetDomainMetadata_601168(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDomainMetadata_601167(path: JsonNode; query: JsonNode;
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
  var valid_601169 = query.getOrDefault("SignatureMethod")
  valid_601169 = validateParameter(valid_601169, JString, required = true,
                                 default = nil)
  if valid_601169 != nil:
    section.add "SignatureMethod", valid_601169
  var valid_601170 = query.getOrDefault("Signature")
  valid_601170 = validateParameter(valid_601170, JString, required = true,
                                 default = nil)
  if valid_601170 != nil:
    section.add "Signature", valid_601170
  var valid_601171 = query.getOrDefault("Action")
  valid_601171 = validateParameter(valid_601171, JString, required = true,
                                 default = newJString("DomainMetadata"))
  if valid_601171 != nil:
    section.add "Action", valid_601171
  var valid_601172 = query.getOrDefault("Timestamp")
  valid_601172 = validateParameter(valid_601172, JString, required = true,
                                 default = nil)
  if valid_601172 != nil:
    section.add "Timestamp", valid_601172
  var valid_601173 = query.getOrDefault("SignatureVersion")
  valid_601173 = validateParameter(valid_601173, JString, required = true,
                                 default = nil)
  if valid_601173 != nil:
    section.add "SignatureVersion", valid_601173
  var valid_601174 = query.getOrDefault("AWSAccessKeyId")
  valid_601174 = validateParameter(valid_601174, JString, required = true,
                                 default = nil)
  if valid_601174 != nil:
    section.add "AWSAccessKeyId", valid_601174
  var valid_601175 = query.getOrDefault("DomainName")
  valid_601175 = validateParameter(valid_601175, JString, required = true,
                                 default = nil)
  if valid_601175 != nil:
    section.add "DomainName", valid_601175
  var valid_601176 = query.getOrDefault("Version")
  valid_601176 = validateParameter(valid_601176, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601176 != nil:
    section.add "Version", valid_601176
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601177: Call_GetDomainMetadata_601166; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  let valid = call_601177.validator(path, query, header, formData, body)
  let scheme = call_601177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601177.url(scheme.get, call_601177.host, call_601177.base,
                         call_601177.route, valid.getOrDefault("path"))
  result = hook(call_601177, url, valid)

proc call*(call_601178: Call_GetDomainMetadata_601166; SignatureMethod: string;
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
  var query_601179 = newJObject()
  add(query_601179, "SignatureMethod", newJString(SignatureMethod))
  add(query_601179, "Signature", newJString(Signature))
  add(query_601179, "Action", newJString(Action))
  add(query_601179, "Timestamp", newJString(Timestamp))
  add(query_601179, "SignatureVersion", newJString(SignatureVersion))
  add(query_601179, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601179, "DomainName", newJString(DomainName))
  add(query_601179, "Version", newJString(Version))
  result = call_601178.call(nil, query_601179, nil, nil, nil)

var getDomainMetadata* = Call_GetDomainMetadata_601166(name: "getDomainMetadata",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=DomainMetadata", validator: validate_GetDomainMetadata_601167,
    base: "/", url: url_GetDomainMetadata_601168,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetAttributes_601212 = ref object of OpenApiRestCall_600410
proc url_PostGetAttributes_601214(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetAttributes_601213(path: JsonNode; query: JsonNode;
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
  var valid_601215 = query.getOrDefault("SignatureMethod")
  valid_601215 = validateParameter(valid_601215, JString, required = true,
                                 default = nil)
  if valid_601215 != nil:
    section.add "SignatureMethod", valid_601215
  var valid_601216 = query.getOrDefault("Signature")
  valid_601216 = validateParameter(valid_601216, JString, required = true,
                                 default = nil)
  if valid_601216 != nil:
    section.add "Signature", valid_601216
  var valid_601217 = query.getOrDefault("Action")
  valid_601217 = validateParameter(valid_601217, JString, required = true,
                                 default = newJString("GetAttributes"))
  if valid_601217 != nil:
    section.add "Action", valid_601217
  var valid_601218 = query.getOrDefault("Timestamp")
  valid_601218 = validateParameter(valid_601218, JString, required = true,
                                 default = nil)
  if valid_601218 != nil:
    section.add "Timestamp", valid_601218
  var valid_601219 = query.getOrDefault("SignatureVersion")
  valid_601219 = validateParameter(valid_601219, JString, required = true,
                                 default = nil)
  if valid_601219 != nil:
    section.add "SignatureVersion", valid_601219
  var valid_601220 = query.getOrDefault("AWSAccessKeyId")
  valid_601220 = validateParameter(valid_601220, JString, required = true,
                                 default = nil)
  if valid_601220 != nil:
    section.add "AWSAccessKeyId", valid_601220
  var valid_601221 = query.getOrDefault("Version")
  valid_601221 = validateParameter(valid_601221, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601221 != nil:
    section.add "Version", valid_601221
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
  var valid_601222 = formData.getOrDefault("DomainName")
  valid_601222 = validateParameter(valid_601222, JString, required = true,
                                 default = nil)
  if valid_601222 != nil:
    section.add "DomainName", valid_601222
  var valid_601223 = formData.getOrDefault("ItemName")
  valid_601223 = validateParameter(valid_601223, JString, required = true,
                                 default = nil)
  if valid_601223 != nil:
    section.add "ItemName", valid_601223
  var valid_601224 = formData.getOrDefault("ConsistentRead")
  valid_601224 = validateParameter(valid_601224, JBool, required = false, default = nil)
  if valid_601224 != nil:
    section.add "ConsistentRead", valid_601224
  var valid_601225 = formData.getOrDefault("AttributeNames")
  valid_601225 = validateParameter(valid_601225, JArray, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "AttributeNames", valid_601225
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601226: Call_PostGetAttributes_601212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  let valid = call_601226.validator(path, query, header, formData, body)
  let scheme = call_601226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601226.url(scheme.get, call_601226.host, call_601226.base,
                         call_601226.route, valid.getOrDefault("path"))
  result = hook(call_601226, url, valid)

proc call*(call_601227: Call_PostGetAttributes_601212; SignatureMethod: string;
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
  var query_601228 = newJObject()
  var formData_601229 = newJObject()
  add(query_601228, "SignatureMethod", newJString(SignatureMethod))
  add(formData_601229, "DomainName", newJString(DomainName))
  add(formData_601229, "ItemName", newJString(ItemName))
  add(formData_601229, "ConsistentRead", newJBool(ConsistentRead))
  add(query_601228, "Signature", newJString(Signature))
  add(query_601228, "Action", newJString(Action))
  add(query_601228, "Timestamp", newJString(Timestamp))
  if AttributeNames != nil:
    formData_601229.add "AttributeNames", AttributeNames
  add(query_601228, "SignatureVersion", newJString(SignatureVersion))
  add(query_601228, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601228, "Version", newJString(Version))
  result = call_601227.call(nil, query_601228, nil, formData_601229, nil)

var postGetAttributes* = Call_PostGetAttributes_601212(name: "postGetAttributes",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=GetAttributes", validator: validate_PostGetAttributes_601213,
    base: "/", url: url_PostGetAttributes_601214,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetAttributes_601195 = ref object of OpenApiRestCall_600410
proc url_GetGetAttributes_601197(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetAttributes_601196(path: JsonNode; query: JsonNode;
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
  var valid_601198 = query.getOrDefault("SignatureMethod")
  valid_601198 = validateParameter(valid_601198, JString, required = true,
                                 default = nil)
  if valid_601198 != nil:
    section.add "SignatureMethod", valid_601198
  var valid_601199 = query.getOrDefault("AttributeNames")
  valid_601199 = validateParameter(valid_601199, JArray, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "AttributeNames", valid_601199
  var valid_601200 = query.getOrDefault("Signature")
  valid_601200 = validateParameter(valid_601200, JString, required = true,
                                 default = nil)
  if valid_601200 != nil:
    section.add "Signature", valid_601200
  var valid_601201 = query.getOrDefault("ItemName")
  valid_601201 = validateParameter(valid_601201, JString, required = true,
                                 default = nil)
  if valid_601201 != nil:
    section.add "ItemName", valid_601201
  var valid_601202 = query.getOrDefault("Action")
  valid_601202 = validateParameter(valid_601202, JString, required = true,
                                 default = newJString("GetAttributes"))
  if valid_601202 != nil:
    section.add "Action", valid_601202
  var valid_601203 = query.getOrDefault("Timestamp")
  valid_601203 = validateParameter(valid_601203, JString, required = true,
                                 default = nil)
  if valid_601203 != nil:
    section.add "Timestamp", valid_601203
  var valid_601204 = query.getOrDefault("ConsistentRead")
  valid_601204 = validateParameter(valid_601204, JBool, required = false, default = nil)
  if valid_601204 != nil:
    section.add "ConsistentRead", valid_601204
  var valid_601205 = query.getOrDefault("SignatureVersion")
  valid_601205 = validateParameter(valid_601205, JString, required = true,
                                 default = nil)
  if valid_601205 != nil:
    section.add "SignatureVersion", valid_601205
  var valid_601206 = query.getOrDefault("AWSAccessKeyId")
  valid_601206 = validateParameter(valid_601206, JString, required = true,
                                 default = nil)
  if valid_601206 != nil:
    section.add "AWSAccessKeyId", valid_601206
  var valid_601207 = query.getOrDefault("DomainName")
  valid_601207 = validateParameter(valid_601207, JString, required = true,
                                 default = nil)
  if valid_601207 != nil:
    section.add "DomainName", valid_601207
  var valid_601208 = query.getOrDefault("Version")
  valid_601208 = validateParameter(valid_601208, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601208 != nil:
    section.add "Version", valid_601208
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601209: Call_GetGetAttributes_601195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  let valid = call_601209.validator(path, query, header, formData, body)
  let scheme = call_601209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601209.url(scheme.get, call_601209.host, call_601209.base,
                         call_601209.route, valid.getOrDefault("path"))
  result = hook(call_601209, url, valid)

proc call*(call_601210: Call_GetGetAttributes_601195; SignatureMethod: string;
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
  var query_601211 = newJObject()
  add(query_601211, "SignatureMethod", newJString(SignatureMethod))
  if AttributeNames != nil:
    query_601211.add "AttributeNames", AttributeNames
  add(query_601211, "Signature", newJString(Signature))
  add(query_601211, "ItemName", newJString(ItemName))
  add(query_601211, "Action", newJString(Action))
  add(query_601211, "Timestamp", newJString(Timestamp))
  add(query_601211, "ConsistentRead", newJBool(ConsistentRead))
  add(query_601211, "SignatureVersion", newJString(SignatureVersion))
  add(query_601211, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601211, "DomainName", newJString(DomainName))
  add(query_601211, "Version", newJString(Version))
  result = call_601210.call(nil, query_601211, nil, nil, nil)

var getGetAttributes* = Call_GetGetAttributes_601195(name: "getGetAttributes",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=GetAttributes", validator: validate_GetGetAttributes_601196,
    base: "/", url: url_GetGetAttributes_601197,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDomains_601245 = ref object of OpenApiRestCall_600410
proc url_PostListDomains_601247(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListDomains_601246(path: JsonNode; query: JsonNode;
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
  var valid_601248 = query.getOrDefault("SignatureMethod")
  valid_601248 = validateParameter(valid_601248, JString, required = true,
                                 default = nil)
  if valid_601248 != nil:
    section.add "SignatureMethod", valid_601248
  var valid_601249 = query.getOrDefault("Signature")
  valid_601249 = validateParameter(valid_601249, JString, required = true,
                                 default = nil)
  if valid_601249 != nil:
    section.add "Signature", valid_601249
  var valid_601250 = query.getOrDefault("Action")
  valid_601250 = validateParameter(valid_601250, JString, required = true,
                                 default = newJString("ListDomains"))
  if valid_601250 != nil:
    section.add "Action", valid_601250
  var valid_601251 = query.getOrDefault("Timestamp")
  valid_601251 = validateParameter(valid_601251, JString, required = true,
                                 default = nil)
  if valid_601251 != nil:
    section.add "Timestamp", valid_601251
  var valid_601252 = query.getOrDefault("SignatureVersion")
  valid_601252 = validateParameter(valid_601252, JString, required = true,
                                 default = nil)
  if valid_601252 != nil:
    section.add "SignatureVersion", valid_601252
  var valid_601253 = query.getOrDefault("AWSAccessKeyId")
  valid_601253 = validateParameter(valid_601253, JString, required = true,
                                 default = nil)
  if valid_601253 != nil:
    section.add "AWSAccessKeyId", valid_601253
  var valid_601254 = query.getOrDefault("Version")
  valid_601254 = validateParameter(valid_601254, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601254 != nil:
    section.add "Version", valid_601254
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : A string informing Amazon SimpleDB where to start the next list of domain names.
  ##   MaxNumberOfDomains: JInt
  ##                     : The maximum number of domain names you want returned. The range is 1 to 100. The default setting is 100.
  section = newJObject()
  var valid_601255 = formData.getOrDefault("NextToken")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "NextToken", valid_601255
  var valid_601256 = formData.getOrDefault("MaxNumberOfDomains")
  valid_601256 = validateParameter(valid_601256, JInt, required = false, default = nil)
  if valid_601256 != nil:
    section.add "MaxNumberOfDomains", valid_601256
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601257: Call_PostListDomains_601245; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  let valid = call_601257.validator(path, query, header, formData, body)
  let scheme = call_601257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601257.url(scheme.get, call_601257.host, call_601257.base,
                         call_601257.route, valid.getOrDefault("path"))
  result = hook(call_601257, url, valid)

proc call*(call_601258: Call_PostListDomains_601245; SignatureMethod: string;
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
  var query_601259 = newJObject()
  var formData_601260 = newJObject()
  add(formData_601260, "NextToken", newJString(NextToken))
  add(query_601259, "SignatureMethod", newJString(SignatureMethod))
  add(query_601259, "Signature", newJString(Signature))
  add(query_601259, "Action", newJString(Action))
  add(query_601259, "Timestamp", newJString(Timestamp))
  add(query_601259, "SignatureVersion", newJString(SignatureVersion))
  add(query_601259, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_601260, "MaxNumberOfDomains", newJInt(MaxNumberOfDomains))
  add(query_601259, "Version", newJString(Version))
  result = call_601258.call(nil, query_601259, nil, formData_601260, nil)

var postListDomains* = Call_PostListDomains_601245(name: "postListDomains",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=ListDomains", validator: validate_PostListDomains_601246,
    base: "/", url: url_PostListDomains_601247, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDomains_601230 = ref object of OpenApiRestCall_600410
proc url_GetListDomains_601232(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListDomains_601231(path: JsonNode; query: JsonNode;
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
  var valid_601233 = query.getOrDefault("SignatureMethod")
  valid_601233 = validateParameter(valid_601233, JString, required = true,
                                 default = nil)
  if valid_601233 != nil:
    section.add "SignatureMethod", valid_601233
  var valid_601234 = query.getOrDefault("Signature")
  valid_601234 = validateParameter(valid_601234, JString, required = true,
                                 default = nil)
  if valid_601234 != nil:
    section.add "Signature", valid_601234
  var valid_601235 = query.getOrDefault("NextToken")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "NextToken", valid_601235
  var valid_601236 = query.getOrDefault("Action")
  valid_601236 = validateParameter(valid_601236, JString, required = true,
                                 default = newJString("ListDomains"))
  if valid_601236 != nil:
    section.add "Action", valid_601236
  var valid_601237 = query.getOrDefault("Timestamp")
  valid_601237 = validateParameter(valid_601237, JString, required = true,
                                 default = nil)
  if valid_601237 != nil:
    section.add "Timestamp", valid_601237
  var valid_601238 = query.getOrDefault("SignatureVersion")
  valid_601238 = validateParameter(valid_601238, JString, required = true,
                                 default = nil)
  if valid_601238 != nil:
    section.add "SignatureVersion", valid_601238
  var valid_601239 = query.getOrDefault("AWSAccessKeyId")
  valid_601239 = validateParameter(valid_601239, JString, required = true,
                                 default = nil)
  if valid_601239 != nil:
    section.add "AWSAccessKeyId", valid_601239
  var valid_601240 = query.getOrDefault("Version")
  valid_601240 = validateParameter(valid_601240, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601240 != nil:
    section.add "Version", valid_601240
  var valid_601241 = query.getOrDefault("MaxNumberOfDomains")
  valid_601241 = validateParameter(valid_601241, JInt, required = false, default = nil)
  if valid_601241 != nil:
    section.add "MaxNumberOfDomains", valid_601241
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601242: Call_GetListDomains_601230; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  let valid = call_601242.validator(path, query, header, formData, body)
  let scheme = call_601242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601242.url(scheme.get, call_601242.host, call_601242.base,
                         call_601242.route, valid.getOrDefault("path"))
  result = hook(call_601242, url, valid)

proc call*(call_601243: Call_GetListDomains_601230; SignatureMethod: string;
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
  var query_601244 = newJObject()
  add(query_601244, "SignatureMethod", newJString(SignatureMethod))
  add(query_601244, "Signature", newJString(Signature))
  add(query_601244, "NextToken", newJString(NextToken))
  add(query_601244, "Action", newJString(Action))
  add(query_601244, "Timestamp", newJString(Timestamp))
  add(query_601244, "SignatureVersion", newJString(SignatureVersion))
  add(query_601244, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601244, "Version", newJString(Version))
  add(query_601244, "MaxNumberOfDomains", newJInt(MaxNumberOfDomains))
  result = call_601243.call(nil, query_601244, nil, nil, nil)

var getListDomains* = Call_GetListDomains_601230(name: "getListDomains",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=ListDomains", validator: validate_GetListDomains_601231,
    base: "/", url: url_GetListDomains_601232, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutAttributes_601280 = ref object of OpenApiRestCall_600410
proc url_PostPutAttributes_601282(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPutAttributes_601281(path: JsonNode; query: JsonNode;
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
  var valid_601283 = query.getOrDefault("SignatureMethod")
  valid_601283 = validateParameter(valid_601283, JString, required = true,
                                 default = nil)
  if valid_601283 != nil:
    section.add "SignatureMethod", valid_601283
  var valid_601284 = query.getOrDefault("Signature")
  valid_601284 = validateParameter(valid_601284, JString, required = true,
                                 default = nil)
  if valid_601284 != nil:
    section.add "Signature", valid_601284
  var valid_601285 = query.getOrDefault("Action")
  valid_601285 = validateParameter(valid_601285, JString, required = true,
                                 default = newJString("PutAttributes"))
  if valid_601285 != nil:
    section.add "Action", valid_601285
  var valid_601286 = query.getOrDefault("Timestamp")
  valid_601286 = validateParameter(valid_601286, JString, required = true,
                                 default = nil)
  if valid_601286 != nil:
    section.add "Timestamp", valid_601286
  var valid_601287 = query.getOrDefault("SignatureVersion")
  valid_601287 = validateParameter(valid_601287, JString, required = true,
                                 default = nil)
  if valid_601287 != nil:
    section.add "SignatureVersion", valid_601287
  var valid_601288 = query.getOrDefault("AWSAccessKeyId")
  valid_601288 = validateParameter(valid_601288, JString, required = true,
                                 default = nil)
  if valid_601288 != nil:
    section.add "AWSAccessKeyId", valid_601288
  var valid_601289 = query.getOrDefault("Version")
  valid_601289 = validateParameter(valid_601289, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601289 != nil:
    section.add "Version", valid_601289
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
  var valid_601290 = formData.getOrDefault("DomainName")
  valid_601290 = validateParameter(valid_601290, JString, required = true,
                                 default = nil)
  if valid_601290 != nil:
    section.add "DomainName", valid_601290
  var valid_601291 = formData.getOrDefault("ItemName")
  valid_601291 = validateParameter(valid_601291, JString, required = true,
                                 default = nil)
  if valid_601291 != nil:
    section.add "ItemName", valid_601291
  var valid_601292 = formData.getOrDefault("Expected.Exists")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "Expected.Exists", valid_601292
  var valid_601293 = formData.getOrDefault("Attributes")
  valid_601293 = validateParameter(valid_601293, JArray, required = true, default = nil)
  if valid_601293 != nil:
    section.add "Attributes", valid_601293
  var valid_601294 = formData.getOrDefault("Expected.Value")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "Expected.Value", valid_601294
  var valid_601295 = formData.getOrDefault("Expected.Name")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "Expected.Name", valid_601295
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601296: Call_PostPutAttributes_601280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  let valid = call_601296.validator(path, query, header, formData, body)
  let scheme = call_601296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601296.url(scheme.get, call_601296.host, call_601296.base,
                         call_601296.route, valid.getOrDefault("path"))
  result = hook(call_601296, url, valid)

proc call*(call_601297: Call_PostPutAttributes_601280; SignatureMethod: string;
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
  var query_601298 = newJObject()
  var formData_601299 = newJObject()
  add(query_601298, "SignatureMethod", newJString(SignatureMethod))
  add(formData_601299, "DomainName", newJString(DomainName))
  add(formData_601299, "ItemName", newJString(ItemName))
  add(formData_601299, "Expected.Exists", newJString(ExpectedExists))
  add(query_601298, "Signature", newJString(Signature))
  if Attributes != nil:
    formData_601299.add "Attributes", Attributes
  add(query_601298, "Action", newJString(Action))
  add(query_601298, "Timestamp", newJString(Timestamp))
  add(formData_601299, "Expected.Value", newJString(ExpectedValue))
  add(formData_601299, "Expected.Name", newJString(ExpectedName))
  add(query_601298, "SignatureVersion", newJString(SignatureVersion))
  add(query_601298, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601298, "Version", newJString(Version))
  result = call_601297.call(nil, query_601298, nil, formData_601299, nil)

var postPutAttributes* = Call_PostPutAttributes_601280(name: "postPutAttributes",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=PutAttributes", validator: validate_PostPutAttributes_601281,
    base: "/", url: url_PostPutAttributes_601282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutAttributes_601261 = ref object of OpenApiRestCall_600410
proc url_GetPutAttributes_601263(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPutAttributes_601262(path: JsonNode; query: JsonNode;
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
  var valid_601264 = query.getOrDefault("SignatureMethod")
  valid_601264 = validateParameter(valid_601264, JString, required = true,
                                 default = nil)
  if valid_601264 != nil:
    section.add "SignatureMethod", valid_601264
  var valid_601265 = query.getOrDefault("Expected.Exists")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "Expected.Exists", valid_601265
  var valid_601266 = query.getOrDefault("Attributes")
  valid_601266 = validateParameter(valid_601266, JArray, required = true, default = nil)
  if valid_601266 != nil:
    section.add "Attributes", valid_601266
  var valid_601267 = query.getOrDefault("Signature")
  valid_601267 = validateParameter(valid_601267, JString, required = true,
                                 default = nil)
  if valid_601267 != nil:
    section.add "Signature", valid_601267
  var valid_601268 = query.getOrDefault("ItemName")
  valid_601268 = validateParameter(valid_601268, JString, required = true,
                                 default = nil)
  if valid_601268 != nil:
    section.add "ItemName", valid_601268
  var valid_601269 = query.getOrDefault("Action")
  valid_601269 = validateParameter(valid_601269, JString, required = true,
                                 default = newJString("PutAttributes"))
  if valid_601269 != nil:
    section.add "Action", valid_601269
  var valid_601270 = query.getOrDefault("Expected.Value")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "Expected.Value", valid_601270
  var valid_601271 = query.getOrDefault("Timestamp")
  valid_601271 = validateParameter(valid_601271, JString, required = true,
                                 default = nil)
  if valid_601271 != nil:
    section.add "Timestamp", valid_601271
  var valid_601272 = query.getOrDefault("SignatureVersion")
  valid_601272 = validateParameter(valid_601272, JString, required = true,
                                 default = nil)
  if valid_601272 != nil:
    section.add "SignatureVersion", valid_601272
  var valid_601273 = query.getOrDefault("AWSAccessKeyId")
  valid_601273 = validateParameter(valid_601273, JString, required = true,
                                 default = nil)
  if valid_601273 != nil:
    section.add "AWSAccessKeyId", valid_601273
  var valid_601274 = query.getOrDefault("Expected.Name")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = nil)
  if valid_601274 != nil:
    section.add "Expected.Name", valid_601274
  var valid_601275 = query.getOrDefault("DomainName")
  valid_601275 = validateParameter(valid_601275, JString, required = true,
                                 default = nil)
  if valid_601275 != nil:
    section.add "DomainName", valid_601275
  var valid_601276 = query.getOrDefault("Version")
  valid_601276 = validateParameter(valid_601276, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601276 != nil:
    section.add "Version", valid_601276
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601277: Call_GetPutAttributes_601261; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  let valid = call_601277.validator(path, query, header, formData, body)
  let scheme = call_601277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601277.url(scheme.get, call_601277.host, call_601277.base,
                         call_601277.route, valid.getOrDefault("path"))
  result = hook(call_601277, url, valid)

proc call*(call_601278: Call_GetPutAttributes_601261; SignatureMethod: string;
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
  var query_601279 = newJObject()
  add(query_601279, "SignatureMethod", newJString(SignatureMethod))
  add(query_601279, "Expected.Exists", newJString(ExpectedExists))
  if Attributes != nil:
    query_601279.add "Attributes", Attributes
  add(query_601279, "Signature", newJString(Signature))
  add(query_601279, "ItemName", newJString(ItemName))
  add(query_601279, "Action", newJString(Action))
  add(query_601279, "Expected.Value", newJString(ExpectedValue))
  add(query_601279, "Timestamp", newJString(Timestamp))
  add(query_601279, "SignatureVersion", newJString(SignatureVersion))
  add(query_601279, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601279, "Expected.Name", newJString(ExpectedName))
  add(query_601279, "DomainName", newJString(DomainName))
  add(query_601279, "Version", newJString(Version))
  result = call_601278.call(nil, query_601279, nil, nil, nil)

var getPutAttributes* = Call_GetPutAttributes_601261(name: "getPutAttributes",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=PutAttributes", validator: validate_GetPutAttributes_601262,
    base: "/", url: url_GetPutAttributes_601263,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSelect_601316 = ref object of OpenApiRestCall_600410
proc url_PostSelect_601318(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSelect_601317(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601319 = query.getOrDefault("SignatureMethod")
  valid_601319 = validateParameter(valid_601319, JString, required = true,
                                 default = nil)
  if valid_601319 != nil:
    section.add "SignatureMethod", valid_601319
  var valid_601320 = query.getOrDefault("Signature")
  valid_601320 = validateParameter(valid_601320, JString, required = true,
                                 default = nil)
  if valid_601320 != nil:
    section.add "Signature", valid_601320
  var valid_601321 = query.getOrDefault("Action")
  valid_601321 = validateParameter(valid_601321, JString, required = true,
                                 default = newJString("Select"))
  if valid_601321 != nil:
    section.add "Action", valid_601321
  var valid_601322 = query.getOrDefault("Timestamp")
  valid_601322 = validateParameter(valid_601322, JString, required = true,
                                 default = nil)
  if valid_601322 != nil:
    section.add "Timestamp", valid_601322
  var valid_601323 = query.getOrDefault("SignatureVersion")
  valid_601323 = validateParameter(valid_601323, JString, required = true,
                                 default = nil)
  if valid_601323 != nil:
    section.add "SignatureVersion", valid_601323
  var valid_601324 = query.getOrDefault("AWSAccessKeyId")
  valid_601324 = validateParameter(valid_601324, JString, required = true,
                                 default = nil)
  if valid_601324 != nil:
    section.add "AWSAccessKeyId", valid_601324
  var valid_601325 = query.getOrDefault("Version")
  valid_601325 = validateParameter(valid_601325, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601325 != nil:
    section.add "Version", valid_601325
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
  var valid_601326 = formData.getOrDefault("NextToken")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "NextToken", valid_601326
  var valid_601327 = formData.getOrDefault("ConsistentRead")
  valid_601327 = validateParameter(valid_601327, JBool, required = false, default = nil)
  if valid_601327 != nil:
    section.add "ConsistentRead", valid_601327
  assert formData != nil, "formData argument is necessary due to required `SelectExpression` field"
  var valid_601328 = formData.getOrDefault("SelectExpression")
  valid_601328 = validateParameter(valid_601328, JString, required = true,
                                 default = nil)
  if valid_601328 != nil:
    section.add "SelectExpression", valid_601328
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601329: Call_PostSelect_601316; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  let valid = call_601329.validator(path, query, header, formData, body)
  let scheme = call_601329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601329.url(scheme.get, call_601329.host, call_601329.base,
                         call_601329.route, valid.getOrDefault("path"))
  result = hook(call_601329, url, valid)

proc call*(call_601330: Call_PostSelect_601316; SignatureMethod: string;
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
  var query_601331 = newJObject()
  var formData_601332 = newJObject()
  add(formData_601332, "NextToken", newJString(NextToken))
  add(query_601331, "SignatureMethod", newJString(SignatureMethod))
  add(formData_601332, "ConsistentRead", newJBool(ConsistentRead))
  add(query_601331, "Signature", newJString(Signature))
  add(query_601331, "Action", newJString(Action))
  add(query_601331, "Timestamp", newJString(Timestamp))
  add(query_601331, "SignatureVersion", newJString(SignatureVersion))
  add(query_601331, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_601332, "SelectExpression", newJString(SelectExpression))
  add(query_601331, "Version", newJString(Version))
  result = call_601330.call(nil, query_601331, nil, formData_601332, nil)

var postSelect* = Call_PostSelect_601316(name: "postSelect",
                                      meth: HttpMethod.HttpPost,
                                      host: "sdb.amazonaws.com",
                                      route: "/#Action=Select",
                                      validator: validate_PostSelect_601317,
                                      base: "/", url: url_PostSelect_601318,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSelect_601300 = ref object of OpenApiRestCall_600410
proc url_GetSelect_601302(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSelect_601301(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601303 = query.getOrDefault("SignatureMethod")
  valid_601303 = validateParameter(valid_601303, JString, required = true,
                                 default = nil)
  if valid_601303 != nil:
    section.add "SignatureMethod", valid_601303
  var valid_601304 = query.getOrDefault("Signature")
  valid_601304 = validateParameter(valid_601304, JString, required = true,
                                 default = nil)
  if valid_601304 != nil:
    section.add "Signature", valid_601304
  var valid_601305 = query.getOrDefault("NextToken")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "NextToken", valid_601305
  var valid_601306 = query.getOrDefault("SelectExpression")
  valid_601306 = validateParameter(valid_601306, JString, required = true,
                                 default = nil)
  if valid_601306 != nil:
    section.add "SelectExpression", valid_601306
  var valid_601307 = query.getOrDefault("Action")
  valid_601307 = validateParameter(valid_601307, JString, required = true,
                                 default = newJString("Select"))
  if valid_601307 != nil:
    section.add "Action", valid_601307
  var valid_601308 = query.getOrDefault("Timestamp")
  valid_601308 = validateParameter(valid_601308, JString, required = true,
                                 default = nil)
  if valid_601308 != nil:
    section.add "Timestamp", valid_601308
  var valid_601309 = query.getOrDefault("ConsistentRead")
  valid_601309 = validateParameter(valid_601309, JBool, required = false, default = nil)
  if valid_601309 != nil:
    section.add "ConsistentRead", valid_601309
  var valid_601310 = query.getOrDefault("SignatureVersion")
  valid_601310 = validateParameter(valid_601310, JString, required = true,
                                 default = nil)
  if valid_601310 != nil:
    section.add "SignatureVersion", valid_601310
  var valid_601311 = query.getOrDefault("AWSAccessKeyId")
  valid_601311 = validateParameter(valid_601311, JString, required = true,
                                 default = nil)
  if valid_601311 != nil:
    section.add "AWSAccessKeyId", valid_601311
  var valid_601312 = query.getOrDefault("Version")
  valid_601312 = validateParameter(valid_601312, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601312 != nil:
    section.add "Version", valid_601312
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601313: Call_GetSelect_601300; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  let valid = call_601313.validator(path, query, header, formData, body)
  let scheme = call_601313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601313.url(scheme.get, call_601313.host, call_601313.base,
                         call_601313.route, valid.getOrDefault("path"))
  result = hook(call_601313, url, valid)

proc call*(call_601314: Call_GetSelect_601300; SignatureMethod: string;
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
  var query_601315 = newJObject()
  add(query_601315, "SignatureMethod", newJString(SignatureMethod))
  add(query_601315, "Signature", newJString(Signature))
  add(query_601315, "NextToken", newJString(NextToken))
  add(query_601315, "SelectExpression", newJString(SelectExpression))
  add(query_601315, "Action", newJString(Action))
  add(query_601315, "Timestamp", newJString(Timestamp))
  add(query_601315, "ConsistentRead", newJBool(ConsistentRead))
  add(query_601315, "SignatureVersion", newJString(SignatureVersion))
  add(query_601315, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601315, "Version", newJString(Version))
  result = call_601314.call(nil, query_601315, nil, nil, nil)

var getSelect* = Call_GetSelect_601300(name: "getSelect", meth: HttpMethod.HttpGet,
                                    host: "sdb.amazonaws.com",
                                    route: "/#Action=Select",
                                    validator: validate_GetSelect_601301,
                                    base: "/", url: url_GetSelect_601302,
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
