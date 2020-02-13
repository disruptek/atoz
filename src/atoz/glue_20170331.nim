
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Glue
## version: 2017-03-31
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Glue</fullname> <p>Defines the public endpoint for the AWS Glue service.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/glue/
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "glue.ap-northeast-1.amazonaws.com", "ap-southeast-1": "glue.ap-southeast-1.amazonaws.com",
                           "us-west-2": "glue.us-west-2.amazonaws.com",
                           "eu-west-2": "glue.eu-west-2.amazonaws.com", "ap-northeast-3": "glue.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "glue.eu-central-1.amazonaws.com",
                           "us-east-2": "glue.us-east-2.amazonaws.com",
                           "us-east-1": "glue.us-east-1.amazonaws.com", "cn-northwest-1": "glue.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "glue.ap-south-1.amazonaws.com",
                           "eu-north-1": "glue.eu-north-1.amazonaws.com", "ap-northeast-2": "glue.ap-northeast-2.amazonaws.com",
                           "us-west-1": "glue.us-west-1.amazonaws.com",
                           "us-gov-east-1": "glue.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "glue.eu-west-3.amazonaws.com",
                           "cn-north-1": "glue.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "glue.sa-east-1.amazonaws.com",
                           "eu-west-1": "glue.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "glue.us-gov-west-1.amazonaws.com", "ap-southeast-2": "glue.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "glue.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "glue.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "glue.ap-southeast-1.amazonaws.com",
      "us-west-2": "glue.us-west-2.amazonaws.com",
      "eu-west-2": "glue.eu-west-2.amazonaws.com",
      "ap-northeast-3": "glue.ap-northeast-3.amazonaws.com",
      "eu-central-1": "glue.eu-central-1.amazonaws.com",
      "us-east-2": "glue.us-east-2.amazonaws.com",
      "us-east-1": "glue.us-east-1.amazonaws.com",
      "cn-northwest-1": "glue.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "glue.ap-south-1.amazonaws.com",
      "eu-north-1": "glue.eu-north-1.amazonaws.com",
      "ap-northeast-2": "glue.ap-northeast-2.amazonaws.com",
      "us-west-1": "glue.us-west-1.amazonaws.com",
      "us-gov-east-1": "glue.us-gov-east-1.amazonaws.com",
      "eu-west-3": "glue.eu-west-3.amazonaws.com",
      "cn-north-1": "glue.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "glue.sa-east-1.amazonaws.com",
      "eu-west-1": "glue.eu-west-1.amazonaws.com",
      "us-gov-west-1": "glue.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "glue.ap-southeast-2.amazonaws.com",
      "ca-central-1": "glue.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "glue"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchCreatePartition_610996 = ref object of OpenApiRestCall_610658
proc url_BatchCreatePartition_610998(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchCreatePartition_610997(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates one or more partitions in a batch operation.
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
  var valid_611123 = header.getOrDefault("X-Amz-Target")
  valid_611123 = validateParameter(valid_611123, JString, required = true, default = newJString(
      "AWSGlue.BatchCreatePartition"))
  if valid_611123 != nil:
    section.add "X-Amz-Target", valid_611123
  var valid_611124 = header.getOrDefault("X-Amz-Signature")
  valid_611124 = validateParameter(valid_611124, JString, required = false,
                                 default = nil)
  if valid_611124 != nil:
    section.add "X-Amz-Signature", valid_611124
  var valid_611125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611125 = validateParameter(valid_611125, JString, required = false,
                                 default = nil)
  if valid_611125 != nil:
    section.add "X-Amz-Content-Sha256", valid_611125
  var valid_611126 = header.getOrDefault("X-Amz-Date")
  valid_611126 = validateParameter(valid_611126, JString, required = false,
                                 default = nil)
  if valid_611126 != nil:
    section.add "X-Amz-Date", valid_611126
  var valid_611127 = header.getOrDefault("X-Amz-Credential")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "X-Amz-Credential", valid_611127
  var valid_611128 = header.getOrDefault("X-Amz-Security-Token")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Security-Token", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Algorithm")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Algorithm", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-SignedHeaders", valid_611130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611154: Call_BatchCreatePartition_610996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates one or more partitions in a batch operation.
  ## 
  let valid = call_611154.validator(path, query, header, formData, body)
  let scheme = call_611154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611154.url(scheme.get, call_611154.host, call_611154.base,
                         call_611154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611154, url, valid)

proc call*(call_611225: Call_BatchCreatePartition_610996; body: JsonNode): Recallable =
  ## batchCreatePartition
  ## Creates one or more partitions in a batch operation.
  ##   body: JObject (required)
  var body_611226 = newJObject()
  if body != nil:
    body_611226 = body
  result = call_611225.call(nil, nil, nil, nil, body_611226)

var batchCreatePartition* = Call_BatchCreatePartition_610996(
    name: "batchCreatePartition", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchCreatePartition",
    validator: validate_BatchCreatePartition_610997, base: "/",
    url: url_BatchCreatePartition_610998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteConnection_611265 = ref object of OpenApiRestCall_610658
proc url_BatchDeleteConnection_611267(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDeleteConnection_611266(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a list of connection definitions from the Data Catalog.
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
  var valid_611268 = header.getOrDefault("X-Amz-Target")
  valid_611268 = validateParameter(valid_611268, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteConnection"))
  if valid_611268 != nil:
    section.add "X-Amz-Target", valid_611268
  var valid_611269 = header.getOrDefault("X-Amz-Signature")
  valid_611269 = validateParameter(valid_611269, JString, required = false,
                                 default = nil)
  if valid_611269 != nil:
    section.add "X-Amz-Signature", valid_611269
  var valid_611270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Content-Sha256", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Date")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Date", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Credential")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Credential", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Security-Token")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Security-Token", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Algorithm")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Algorithm", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-SignedHeaders", valid_611275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611277: Call_BatchDeleteConnection_611265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a list of connection definitions from the Data Catalog.
  ## 
  let valid = call_611277.validator(path, query, header, formData, body)
  let scheme = call_611277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611277.url(scheme.get, call_611277.host, call_611277.base,
                         call_611277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611277, url, valid)

proc call*(call_611278: Call_BatchDeleteConnection_611265; body: JsonNode): Recallable =
  ## batchDeleteConnection
  ## Deletes a list of connection definitions from the Data Catalog.
  ##   body: JObject (required)
  var body_611279 = newJObject()
  if body != nil:
    body_611279 = body
  result = call_611278.call(nil, nil, nil, nil, body_611279)

var batchDeleteConnection* = Call_BatchDeleteConnection_611265(
    name: "batchDeleteConnection", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteConnection",
    validator: validate_BatchDeleteConnection_611266, base: "/",
    url: url_BatchDeleteConnection_611267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeletePartition_611280 = ref object of OpenApiRestCall_610658
proc url_BatchDeletePartition_611282(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDeletePartition_611281(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes one or more partitions in a batch operation.
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
  var valid_611283 = header.getOrDefault("X-Amz-Target")
  valid_611283 = validateParameter(valid_611283, JString, required = true, default = newJString(
      "AWSGlue.BatchDeletePartition"))
  if valid_611283 != nil:
    section.add "X-Amz-Target", valid_611283
  var valid_611284 = header.getOrDefault("X-Amz-Signature")
  valid_611284 = validateParameter(valid_611284, JString, required = false,
                                 default = nil)
  if valid_611284 != nil:
    section.add "X-Amz-Signature", valid_611284
  var valid_611285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "X-Amz-Content-Sha256", valid_611285
  var valid_611286 = header.getOrDefault("X-Amz-Date")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Date", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Credential")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Credential", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Security-Token")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Security-Token", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Algorithm")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Algorithm", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-SignedHeaders", valid_611290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611292: Call_BatchDeletePartition_611280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes one or more partitions in a batch operation.
  ## 
  let valid = call_611292.validator(path, query, header, formData, body)
  let scheme = call_611292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611292.url(scheme.get, call_611292.host, call_611292.base,
                         call_611292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611292, url, valid)

proc call*(call_611293: Call_BatchDeletePartition_611280; body: JsonNode): Recallable =
  ## batchDeletePartition
  ## Deletes one or more partitions in a batch operation.
  ##   body: JObject (required)
  var body_611294 = newJObject()
  if body != nil:
    body_611294 = body
  result = call_611293.call(nil, nil, nil, nil, body_611294)

var batchDeletePartition* = Call_BatchDeletePartition_611280(
    name: "batchDeletePartition", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeletePartition",
    validator: validate_BatchDeletePartition_611281, base: "/",
    url: url_BatchDeletePartition_611282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteTable_611295 = ref object of OpenApiRestCall_610658
proc url_BatchDeleteTable_611297(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDeleteTable_611296(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
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
  var valid_611298 = header.getOrDefault("X-Amz-Target")
  valid_611298 = validateParameter(valid_611298, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteTable"))
  if valid_611298 != nil:
    section.add "X-Amz-Target", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-Signature")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-Signature", valid_611299
  var valid_611300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Content-Sha256", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-Date")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Date", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-Credential")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-Credential", valid_611302
  var valid_611303 = header.getOrDefault("X-Amz-Security-Token")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Security-Token", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-Algorithm")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Algorithm", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-SignedHeaders", valid_611305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611307: Call_BatchDeleteTable_611295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ## 
  let valid = call_611307.validator(path, query, header, formData, body)
  let scheme = call_611307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611307.url(scheme.get, call_611307.host, call_611307.base,
                         call_611307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611307, url, valid)

proc call*(call_611308: Call_BatchDeleteTable_611295; body: JsonNode): Recallable =
  ## batchDeleteTable
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ##   body: JObject (required)
  var body_611309 = newJObject()
  if body != nil:
    body_611309 = body
  result = call_611308.call(nil, nil, nil, nil, body_611309)

var batchDeleteTable* = Call_BatchDeleteTable_611295(name: "batchDeleteTable",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteTable",
    validator: validate_BatchDeleteTable_611296, base: "/",
    url: url_BatchDeleteTable_611297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteTableVersion_611310 = ref object of OpenApiRestCall_610658
proc url_BatchDeleteTableVersion_611312(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDeleteTableVersion_611311(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified batch of versions of a table.
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
  var valid_611313 = header.getOrDefault("X-Amz-Target")
  valid_611313 = validateParameter(valid_611313, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteTableVersion"))
  if valid_611313 != nil:
    section.add "X-Amz-Target", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-Signature")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Signature", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Content-Sha256", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-Date")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Date", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Credential")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Credential", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Security-Token")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Security-Token", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Algorithm")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Algorithm", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-SignedHeaders", valid_611320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611322: Call_BatchDeleteTableVersion_611310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified batch of versions of a table.
  ## 
  let valid = call_611322.validator(path, query, header, formData, body)
  let scheme = call_611322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611322.url(scheme.get, call_611322.host, call_611322.base,
                         call_611322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611322, url, valid)

proc call*(call_611323: Call_BatchDeleteTableVersion_611310; body: JsonNode): Recallable =
  ## batchDeleteTableVersion
  ## Deletes a specified batch of versions of a table.
  ##   body: JObject (required)
  var body_611324 = newJObject()
  if body != nil:
    body_611324 = body
  result = call_611323.call(nil, nil, nil, nil, body_611324)

var batchDeleteTableVersion* = Call_BatchDeleteTableVersion_611310(
    name: "batchDeleteTableVersion", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteTableVersion",
    validator: validate_BatchDeleteTableVersion_611311, base: "/",
    url: url_BatchDeleteTableVersion_611312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetCrawlers_611325 = ref object of OpenApiRestCall_610658
proc url_BatchGetCrawlers_611327(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetCrawlers_611326(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
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
  var valid_611328 = header.getOrDefault("X-Amz-Target")
  valid_611328 = validateParameter(valid_611328, JString, required = true, default = newJString(
      "AWSGlue.BatchGetCrawlers"))
  if valid_611328 != nil:
    section.add "X-Amz-Target", valid_611328
  var valid_611329 = header.getOrDefault("X-Amz-Signature")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-Signature", valid_611329
  var valid_611330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-Content-Sha256", valid_611330
  var valid_611331 = header.getOrDefault("X-Amz-Date")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-Date", valid_611331
  var valid_611332 = header.getOrDefault("X-Amz-Credential")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-Credential", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-Security-Token")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-Security-Token", valid_611333
  var valid_611334 = header.getOrDefault("X-Amz-Algorithm")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "X-Amz-Algorithm", valid_611334
  var valid_611335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-SignedHeaders", valid_611335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611337: Call_BatchGetCrawlers_611325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_611337.validator(path, query, header, formData, body)
  let scheme = call_611337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611337.url(scheme.get, call_611337.host, call_611337.base,
                         call_611337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611337, url, valid)

proc call*(call_611338: Call_BatchGetCrawlers_611325; body: JsonNode): Recallable =
  ## batchGetCrawlers
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_611339 = newJObject()
  if body != nil:
    body_611339 = body
  result = call_611338.call(nil, nil, nil, nil, body_611339)

var batchGetCrawlers* = Call_BatchGetCrawlers_611325(name: "batchGetCrawlers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetCrawlers",
    validator: validate_BatchGetCrawlers_611326, base: "/",
    url: url_BatchGetCrawlers_611327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDevEndpoints_611340 = ref object of OpenApiRestCall_610658
proc url_BatchGetDevEndpoints_611342(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetDevEndpoints_611341(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
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
  var valid_611343 = header.getOrDefault("X-Amz-Target")
  valid_611343 = validateParameter(valid_611343, JString, required = true, default = newJString(
      "AWSGlue.BatchGetDevEndpoints"))
  if valid_611343 != nil:
    section.add "X-Amz-Target", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-Signature")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-Signature", valid_611344
  var valid_611345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "X-Amz-Content-Sha256", valid_611345
  var valid_611346 = header.getOrDefault("X-Amz-Date")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "X-Amz-Date", valid_611346
  var valid_611347 = header.getOrDefault("X-Amz-Credential")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Credential", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Security-Token")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Security-Token", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-Algorithm")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-Algorithm", valid_611349
  var valid_611350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-SignedHeaders", valid_611350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611352: Call_BatchGetDevEndpoints_611340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_611352.validator(path, query, header, formData, body)
  let scheme = call_611352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611352.url(scheme.get, call_611352.host, call_611352.base,
                         call_611352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611352, url, valid)

proc call*(call_611353: Call_BatchGetDevEndpoints_611340; body: JsonNode): Recallable =
  ## batchGetDevEndpoints
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_611354 = newJObject()
  if body != nil:
    body_611354 = body
  result = call_611353.call(nil, nil, nil, nil, body_611354)

var batchGetDevEndpoints* = Call_BatchGetDevEndpoints_611340(
    name: "batchGetDevEndpoints", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetDevEndpoints",
    validator: validate_BatchGetDevEndpoints_611341, base: "/",
    url: url_BatchGetDevEndpoints_611342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetJobs_611355 = ref object of OpenApiRestCall_610658
proc url_BatchGetJobs_611357(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetJobs_611356(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
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
  var valid_611358 = header.getOrDefault("X-Amz-Target")
  valid_611358 = validateParameter(valid_611358, JString, required = true,
                                 default = newJString("AWSGlue.BatchGetJobs"))
  if valid_611358 != nil:
    section.add "X-Amz-Target", valid_611358
  var valid_611359 = header.getOrDefault("X-Amz-Signature")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-Signature", valid_611359
  var valid_611360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "X-Amz-Content-Sha256", valid_611360
  var valid_611361 = header.getOrDefault("X-Amz-Date")
  valid_611361 = validateParameter(valid_611361, JString, required = false,
                                 default = nil)
  if valid_611361 != nil:
    section.add "X-Amz-Date", valid_611361
  var valid_611362 = header.getOrDefault("X-Amz-Credential")
  valid_611362 = validateParameter(valid_611362, JString, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "X-Amz-Credential", valid_611362
  var valid_611363 = header.getOrDefault("X-Amz-Security-Token")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "X-Amz-Security-Token", valid_611363
  var valid_611364 = header.getOrDefault("X-Amz-Algorithm")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "X-Amz-Algorithm", valid_611364
  var valid_611365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "X-Amz-SignedHeaders", valid_611365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611367: Call_BatchGetJobs_611355; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
  ## 
  let valid = call_611367.validator(path, query, header, formData, body)
  let scheme = call_611367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611367.url(scheme.get, call_611367.host, call_611367.base,
                         call_611367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611367, url, valid)

proc call*(call_611368: Call_BatchGetJobs_611355; body: JsonNode): Recallable =
  ## batchGetJobs
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
  ##   body: JObject (required)
  var body_611369 = newJObject()
  if body != nil:
    body_611369 = body
  result = call_611368.call(nil, nil, nil, nil, body_611369)

var batchGetJobs* = Call_BatchGetJobs_611355(name: "batchGetJobs",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetJobs",
    validator: validate_BatchGetJobs_611356, base: "/", url: url_BatchGetJobs_611357,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetPartition_611370 = ref object of OpenApiRestCall_610658
proc url_BatchGetPartition_611372(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetPartition_611371(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves partitions in a batch request.
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
  var valid_611373 = header.getOrDefault("X-Amz-Target")
  valid_611373 = validateParameter(valid_611373, JString, required = true, default = newJString(
      "AWSGlue.BatchGetPartition"))
  if valid_611373 != nil:
    section.add "X-Amz-Target", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-Signature")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Signature", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Content-Sha256", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-Date")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-Date", valid_611376
  var valid_611377 = header.getOrDefault("X-Amz-Credential")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-Credential", valid_611377
  var valid_611378 = header.getOrDefault("X-Amz-Security-Token")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-Security-Token", valid_611378
  var valid_611379 = header.getOrDefault("X-Amz-Algorithm")
  valid_611379 = validateParameter(valid_611379, JString, required = false,
                                 default = nil)
  if valid_611379 != nil:
    section.add "X-Amz-Algorithm", valid_611379
  var valid_611380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-SignedHeaders", valid_611380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611382: Call_BatchGetPartition_611370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves partitions in a batch request.
  ## 
  let valid = call_611382.validator(path, query, header, formData, body)
  let scheme = call_611382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611382.url(scheme.get, call_611382.host, call_611382.base,
                         call_611382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611382, url, valid)

proc call*(call_611383: Call_BatchGetPartition_611370; body: JsonNode): Recallable =
  ## batchGetPartition
  ## Retrieves partitions in a batch request.
  ##   body: JObject (required)
  var body_611384 = newJObject()
  if body != nil:
    body_611384 = body
  result = call_611383.call(nil, nil, nil, nil, body_611384)

var batchGetPartition* = Call_BatchGetPartition_611370(name: "batchGetPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetPartition",
    validator: validate_BatchGetPartition_611371, base: "/",
    url: url_BatchGetPartition_611372, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetTriggers_611385 = ref object of OpenApiRestCall_610658
proc url_BatchGetTriggers_611387(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetTriggers_611386(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
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
  var valid_611388 = header.getOrDefault("X-Amz-Target")
  valid_611388 = validateParameter(valid_611388, JString, required = true, default = newJString(
      "AWSGlue.BatchGetTriggers"))
  if valid_611388 != nil:
    section.add "X-Amz-Target", valid_611388
  var valid_611389 = header.getOrDefault("X-Amz-Signature")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "X-Amz-Signature", valid_611389
  var valid_611390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "X-Amz-Content-Sha256", valid_611390
  var valid_611391 = header.getOrDefault("X-Amz-Date")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "X-Amz-Date", valid_611391
  var valid_611392 = header.getOrDefault("X-Amz-Credential")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-Credential", valid_611392
  var valid_611393 = header.getOrDefault("X-Amz-Security-Token")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-Security-Token", valid_611393
  var valid_611394 = header.getOrDefault("X-Amz-Algorithm")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "X-Amz-Algorithm", valid_611394
  var valid_611395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "X-Amz-SignedHeaders", valid_611395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611397: Call_BatchGetTriggers_611385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_611397.validator(path, query, header, formData, body)
  let scheme = call_611397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611397.url(scheme.get, call_611397.host, call_611397.base,
                         call_611397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611397, url, valid)

proc call*(call_611398: Call_BatchGetTriggers_611385; body: JsonNode): Recallable =
  ## batchGetTriggers
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_611399 = newJObject()
  if body != nil:
    body_611399 = body
  result = call_611398.call(nil, nil, nil, nil, body_611399)

var batchGetTriggers* = Call_BatchGetTriggers_611385(name: "batchGetTriggers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetTriggers",
    validator: validate_BatchGetTriggers_611386, base: "/",
    url: url_BatchGetTriggers_611387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetWorkflows_611400 = ref object of OpenApiRestCall_610658
proc url_BatchGetWorkflows_611402(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetWorkflows_611401(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
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
  var valid_611403 = header.getOrDefault("X-Amz-Target")
  valid_611403 = validateParameter(valid_611403, JString, required = true, default = newJString(
      "AWSGlue.BatchGetWorkflows"))
  if valid_611403 != nil:
    section.add "X-Amz-Target", valid_611403
  var valid_611404 = header.getOrDefault("X-Amz-Signature")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "X-Amz-Signature", valid_611404
  var valid_611405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "X-Amz-Content-Sha256", valid_611405
  var valid_611406 = header.getOrDefault("X-Amz-Date")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-Date", valid_611406
  var valid_611407 = header.getOrDefault("X-Amz-Credential")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "X-Amz-Credential", valid_611407
  var valid_611408 = header.getOrDefault("X-Amz-Security-Token")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Security-Token", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-Algorithm")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Algorithm", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-SignedHeaders", valid_611410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611412: Call_BatchGetWorkflows_611400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_611412.validator(path, query, header, formData, body)
  let scheme = call_611412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611412.url(scheme.get, call_611412.host, call_611412.base,
                         call_611412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611412, url, valid)

proc call*(call_611413: Call_BatchGetWorkflows_611400; body: JsonNode): Recallable =
  ## batchGetWorkflows
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_611414 = newJObject()
  if body != nil:
    body_611414 = body
  result = call_611413.call(nil, nil, nil, nil, body_611414)

var batchGetWorkflows* = Call_BatchGetWorkflows_611400(name: "batchGetWorkflows",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetWorkflows",
    validator: validate_BatchGetWorkflows_611401, base: "/",
    url: url_BatchGetWorkflows_611402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchStopJobRun_611415 = ref object of OpenApiRestCall_610658
proc url_BatchStopJobRun_611417(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchStopJobRun_611416(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Stops one or more job runs for a specified job definition.
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
  var valid_611418 = header.getOrDefault("X-Amz-Target")
  valid_611418 = validateParameter(valid_611418, JString, required = true, default = newJString(
      "AWSGlue.BatchStopJobRun"))
  if valid_611418 != nil:
    section.add "X-Amz-Target", valid_611418
  var valid_611419 = header.getOrDefault("X-Amz-Signature")
  valid_611419 = validateParameter(valid_611419, JString, required = false,
                                 default = nil)
  if valid_611419 != nil:
    section.add "X-Amz-Signature", valid_611419
  var valid_611420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "X-Amz-Content-Sha256", valid_611420
  var valid_611421 = header.getOrDefault("X-Amz-Date")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "X-Amz-Date", valid_611421
  var valid_611422 = header.getOrDefault("X-Amz-Credential")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-Credential", valid_611422
  var valid_611423 = header.getOrDefault("X-Amz-Security-Token")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "X-Amz-Security-Token", valid_611423
  var valid_611424 = header.getOrDefault("X-Amz-Algorithm")
  valid_611424 = validateParameter(valid_611424, JString, required = false,
                                 default = nil)
  if valid_611424 != nil:
    section.add "X-Amz-Algorithm", valid_611424
  var valid_611425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-SignedHeaders", valid_611425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611427: Call_BatchStopJobRun_611415; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops one or more job runs for a specified job definition.
  ## 
  let valid = call_611427.validator(path, query, header, formData, body)
  let scheme = call_611427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611427.url(scheme.get, call_611427.host, call_611427.base,
                         call_611427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611427, url, valid)

proc call*(call_611428: Call_BatchStopJobRun_611415; body: JsonNode): Recallable =
  ## batchStopJobRun
  ## Stops one or more job runs for a specified job definition.
  ##   body: JObject (required)
  var body_611429 = newJObject()
  if body != nil:
    body_611429 = body
  result = call_611428.call(nil, nil, nil, nil, body_611429)

var batchStopJobRun* = Call_BatchStopJobRun_611415(name: "batchStopJobRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchStopJobRun",
    validator: validate_BatchStopJobRun_611416, base: "/", url: url_BatchStopJobRun_611417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelMLTaskRun_611430 = ref object of OpenApiRestCall_610658
proc url_CancelMLTaskRun_611432(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelMLTaskRun_611431(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
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
  var valid_611433 = header.getOrDefault("X-Amz-Target")
  valid_611433 = validateParameter(valid_611433, JString, required = true, default = newJString(
      "AWSGlue.CancelMLTaskRun"))
  if valid_611433 != nil:
    section.add "X-Amz-Target", valid_611433
  var valid_611434 = header.getOrDefault("X-Amz-Signature")
  valid_611434 = validateParameter(valid_611434, JString, required = false,
                                 default = nil)
  if valid_611434 != nil:
    section.add "X-Amz-Signature", valid_611434
  var valid_611435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-Content-Sha256", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-Date")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Date", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-Credential")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-Credential", valid_611437
  var valid_611438 = header.getOrDefault("X-Amz-Security-Token")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "X-Amz-Security-Token", valid_611438
  var valid_611439 = header.getOrDefault("X-Amz-Algorithm")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "X-Amz-Algorithm", valid_611439
  var valid_611440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "X-Amz-SignedHeaders", valid_611440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611442: Call_CancelMLTaskRun_611430; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
  ## 
  let valid = call_611442.validator(path, query, header, formData, body)
  let scheme = call_611442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611442.url(scheme.get, call_611442.host, call_611442.base,
                         call_611442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611442, url, valid)

proc call*(call_611443: Call_CancelMLTaskRun_611430; body: JsonNode): Recallable =
  ## cancelMLTaskRun
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
  ##   body: JObject (required)
  var body_611444 = newJObject()
  if body != nil:
    body_611444 = body
  result = call_611443.call(nil, nil, nil, nil, body_611444)

var cancelMLTaskRun* = Call_CancelMLTaskRun_611430(name: "cancelMLTaskRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CancelMLTaskRun",
    validator: validate_CancelMLTaskRun_611431, base: "/", url: url_CancelMLTaskRun_611432,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateClassifier_611445 = ref object of OpenApiRestCall_610658
proc url_CreateClassifier_611447(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateClassifier_611446(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
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
  var valid_611448 = header.getOrDefault("X-Amz-Target")
  valid_611448 = validateParameter(valid_611448, JString, required = true, default = newJString(
      "AWSGlue.CreateClassifier"))
  if valid_611448 != nil:
    section.add "X-Amz-Target", valid_611448
  var valid_611449 = header.getOrDefault("X-Amz-Signature")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "X-Amz-Signature", valid_611449
  var valid_611450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-Content-Sha256", valid_611450
  var valid_611451 = header.getOrDefault("X-Amz-Date")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "X-Amz-Date", valid_611451
  var valid_611452 = header.getOrDefault("X-Amz-Credential")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-Credential", valid_611452
  var valid_611453 = header.getOrDefault("X-Amz-Security-Token")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "X-Amz-Security-Token", valid_611453
  var valid_611454 = header.getOrDefault("X-Amz-Algorithm")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "X-Amz-Algorithm", valid_611454
  var valid_611455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "X-Amz-SignedHeaders", valid_611455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611457: Call_CreateClassifier_611445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
  ## 
  let valid = call_611457.validator(path, query, header, formData, body)
  let scheme = call_611457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611457.url(scheme.get, call_611457.host, call_611457.base,
                         call_611457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611457, url, valid)

proc call*(call_611458: Call_CreateClassifier_611445; body: JsonNode): Recallable =
  ## createClassifier
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
  ##   body: JObject (required)
  var body_611459 = newJObject()
  if body != nil:
    body_611459 = body
  result = call_611458.call(nil, nil, nil, nil, body_611459)

var createClassifier* = Call_CreateClassifier_611445(name: "createClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateClassifier",
    validator: validate_CreateClassifier_611446, base: "/",
    url: url_CreateClassifier_611447, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnection_611460 = ref object of OpenApiRestCall_610658
proc url_CreateConnection_611462(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConnection_611461(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a connection definition in the Data Catalog.
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
  var valid_611463 = header.getOrDefault("X-Amz-Target")
  valid_611463 = validateParameter(valid_611463, JString, required = true, default = newJString(
      "AWSGlue.CreateConnection"))
  if valid_611463 != nil:
    section.add "X-Amz-Target", valid_611463
  var valid_611464 = header.getOrDefault("X-Amz-Signature")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "X-Amz-Signature", valid_611464
  var valid_611465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "X-Amz-Content-Sha256", valid_611465
  var valid_611466 = header.getOrDefault("X-Amz-Date")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-Date", valid_611466
  var valid_611467 = header.getOrDefault("X-Amz-Credential")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "X-Amz-Credential", valid_611467
  var valid_611468 = header.getOrDefault("X-Amz-Security-Token")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-Security-Token", valid_611468
  var valid_611469 = header.getOrDefault("X-Amz-Algorithm")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-Algorithm", valid_611469
  var valid_611470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "X-Amz-SignedHeaders", valid_611470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611472: Call_CreateConnection_611460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a connection definition in the Data Catalog.
  ## 
  let valid = call_611472.validator(path, query, header, formData, body)
  let scheme = call_611472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611472.url(scheme.get, call_611472.host, call_611472.base,
                         call_611472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611472, url, valid)

proc call*(call_611473: Call_CreateConnection_611460; body: JsonNode): Recallable =
  ## createConnection
  ## Creates a connection definition in the Data Catalog.
  ##   body: JObject (required)
  var body_611474 = newJObject()
  if body != nil:
    body_611474 = body
  result = call_611473.call(nil, nil, nil, nil, body_611474)

var createConnection* = Call_CreateConnection_611460(name: "createConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateConnection",
    validator: validate_CreateConnection_611461, base: "/",
    url: url_CreateConnection_611462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCrawler_611475 = ref object of OpenApiRestCall_610658
proc url_CreateCrawler_611477(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCrawler_611476(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
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
  var valid_611478 = header.getOrDefault("X-Amz-Target")
  valid_611478 = validateParameter(valid_611478, JString, required = true,
                                 default = newJString("AWSGlue.CreateCrawler"))
  if valid_611478 != nil:
    section.add "X-Amz-Target", valid_611478
  var valid_611479 = header.getOrDefault("X-Amz-Signature")
  valid_611479 = validateParameter(valid_611479, JString, required = false,
                                 default = nil)
  if valid_611479 != nil:
    section.add "X-Amz-Signature", valid_611479
  var valid_611480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-Content-Sha256", valid_611480
  var valid_611481 = header.getOrDefault("X-Amz-Date")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "X-Amz-Date", valid_611481
  var valid_611482 = header.getOrDefault("X-Amz-Credential")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "X-Amz-Credential", valid_611482
  var valid_611483 = header.getOrDefault("X-Amz-Security-Token")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "X-Amz-Security-Token", valid_611483
  var valid_611484 = header.getOrDefault("X-Amz-Algorithm")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "X-Amz-Algorithm", valid_611484
  var valid_611485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-SignedHeaders", valid_611485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611487: Call_CreateCrawler_611475; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
  ## 
  let valid = call_611487.validator(path, query, header, formData, body)
  let scheme = call_611487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611487.url(scheme.get, call_611487.host, call_611487.base,
                         call_611487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611487, url, valid)

proc call*(call_611488: Call_CreateCrawler_611475; body: JsonNode): Recallable =
  ## createCrawler
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
  ##   body: JObject (required)
  var body_611489 = newJObject()
  if body != nil:
    body_611489 = body
  result = call_611488.call(nil, nil, nil, nil, body_611489)

var createCrawler* = Call_CreateCrawler_611475(name: "createCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateCrawler",
    validator: validate_CreateCrawler_611476, base: "/", url: url_CreateCrawler_611477,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatabase_611490 = ref object of OpenApiRestCall_610658
proc url_CreateDatabase_611492(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDatabase_611491(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a new database in a Data Catalog.
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
  var valid_611493 = header.getOrDefault("X-Amz-Target")
  valid_611493 = validateParameter(valid_611493, JString, required = true,
                                 default = newJString("AWSGlue.CreateDatabase"))
  if valid_611493 != nil:
    section.add "X-Amz-Target", valid_611493
  var valid_611494 = header.getOrDefault("X-Amz-Signature")
  valid_611494 = validateParameter(valid_611494, JString, required = false,
                                 default = nil)
  if valid_611494 != nil:
    section.add "X-Amz-Signature", valid_611494
  var valid_611495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611495 = validateParameter(valid_611495, JString, required = false,
                                 default = nil)
  if valid_611495 != nil:
    section.add "X-Amz-Content-Sha256", valid_611495
  var valid_611496 = header.getOrDefault("X-Amz-Date")
  valid_611496 = validateParameter(valid_611496, JString, required = false,
                                 default = nil)
  if valid_611496 != nil:
    section.add "X-Amz-Date", valid_611496
  var valid_611497 = header.getOrDefault("X-Amz-Credential")
  valid_611497 = validateParameter(valid_611497, JString, required = false,
                                 default = nil)
  if valid_611497 != nil:
    section.add "X-Amz-Credential", valid_611497
  var valid_611498 = header.getOrDefault("X-Amz-Security-Token")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "X-Amz-Security-Token", valid_611498
  var valid_611499 = header.getOrDefault("X-Amz-Algorithm")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "X-Amz-Algorithm", valid_611499
  var valid_611500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "X-Amz-SignedHeaders", valid_611500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611502: Call_CreateDatabase_611490; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new database in a Data Catalog.
  ## 
  let valid = call_611502.validator(path, query, header, formData, body)
  let scheme = call_611502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611502.url(scheme.get, call_611502.host, call_611502.base,
                         call_611502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611502, url, valid)

proc call*(call_611503: Call_CreateDatabase_611490; body: JsonNode): Recallable =
  ## createDatabase
  ## Creates a new database in a Data Catalog.
  ##   body: JObject (required)
  var body_611504 = newJObject()
  if body != nil:
    body_611504 = body
  result = call_611503.call(nil, nil, nil, nil, body_611504)

var createDatabase* = Call_CreateDatabase_611490(name: "createDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateDatabase",
    validator: validate_CreateDatabase_611491, base: "/", url: url_CreateDatabase_611492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDevEndpoint_611505 = ref object of OpenApiRestCall_610658
proc url_CreateDevEndpoint_611507(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDevEndpoint_611506(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates a new development endpoint.
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
  var valid_611508 = header.getOrDefault("X-Amz-Target")
  valid_611508 = validateParameter(valid_611508, JString, required = true, default = newJString(
      "AWSGlue.CreateDevEndpoint"))
  if valid_611508 != nil:
    section.add "X-Amz-Target", valid_611508
  var valid_611509 = header.getOrDefault("X-Amz-Signature")
  valid_611509 = validateParameter(valid_611509, JString, required = false,
                                 default = nil)
  if valid_611509 != nil:
    section.add "X-Amz-Signature", valid_611509
  var valid_611510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611510 = validateParameter(valid_611510, JString, required = false,
                                 default = nil)
  if valid_611510 != nil:
    section.add "X-Amz-Content-Sha256", valid_611510
  var valid_611511 = header.getOrDefault("X-Amz-Date")
  valid_611511 = validateParameter(valid_611511, JString, required = false,
                                 default = nil)
  if valid_611511 != nil:
    section.add "X-Amz-Date", valid_611511
  var valid_611512 = header.getOrDefault("X-Amz-Credential")
  valid_611512 = validateParameter(valid_611512, JString, required = false,
                                 default = nil)
  if valid_611512 != nil:
    section.add "X-Amz-Credential", valid_611512
  var valid_611513 = header.getOrDefault("X-Amz-Security-Token")
  valid_611513 = validateParameter(valid_611513, JString, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "X-Amz-Security-Token", valid_611513
  var valid_611514 = header.getOrDefault("X-Amz-Algorithm")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "X-Amz-Algorithm", valid_611514
  var valid_611515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "X-Amz-SignedHeaders", valid_611515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611517: Call_CreateDevEndpoint_611505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new development endpoint.
  ## 
  let valid = call_611517.validator(path, query, header, formData, body)
  let scheme = call_611517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611517.url(scheme.get, call_611517.host, call_611517.base,
                         call_611517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611517, url, valid)

proc call*(call_611518: Call_CreateDevEndpoint_611505; body: JsonNode): Recallable =
  ## createDevEndpoint
  ## Creates a new development endpoint.
  ##   body: JObject (required)
  var body_611519 = newJObject()
  if body != nil:
    body_611519 = body
  result = call_611518.call(nil, nil, nil, nil, body_611519)

var createDevEndpoint* = Call_CreateDevEndpoint_611505(name: "createDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateDevEndpoint",
    validator: validate_CreateDevEndpoint_611506, base: "/",
    url: url_CreateDevEndpoint_611507, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_611520 = ref object of OpenApiRestCall_610658
proc url_CreateJob_611522(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateJob_611521(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new job definition.
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
  var valid_611523 = header.getOrDefault("X-Amz-Target")
  valid_611523 = validateParameter(valid_611523, JString, required = true,
                                 default = newJString("AWSGlue.CreateJob"))
  if valid_611523 != nil:
    section.add "X-Amz-Target", valid_611523
  var valid_611524 = header.getOrDefault("X-Amz-Signature")
  valid_611524 = validateParameter(valid_611524, JString, required = false,
                                 default = nil)
  if valid_611524 != nil:
    section.add "X-Amz-Signature", valid_611524
  var valid_611525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611525 = validateParameter(valid_611525, JString, required = false,
                                 default = nil)
  if valid_611525 != nil:
    section.add "X-Amz-Content-Sha256", valid_611525
  var valid_611526 = header.getOrDefault("X-Amz-Date")
  valid_611526 = validateParameter(valid_611526, JString, required = false,
                                 default = nil)
  if valid_611526 != nil:
    section.add "X-Amz-Date", valid_611526
  var valid_611527 = header.getOrDefault("X-Amz-Credential")
  valid_611527 = validateParameter(valid_611527, JString, required = false,
                                 default = nil)
  if valid_611527 != nil:
    section.add "X-Amz-Credential", valid_611527
  var valid_611528 = header.getOrDefault("X-Amz-Security-Token")
  valid_611528 = validateParameter(valid_611528, JString, required = false,
                                 default = nil)
  if valid_611528 != nil:
    section.add "X-Amz-Security-Token", valid_611528
  var valid_611529 = header.getOrDefault("X-Amz-Algorithm")
  valid_611529 = validateParameter(valid_611529, JString, required = false,
                                 default = nil)
  if valid_611529 != nil:
    section.add "X-Amz-Algorithm", valid_611529
  var valid_611530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611530 = validateParameter(valid_611530, JString, required = false,
                                 default = nil)
  if valid_611530 != nil:
    section.add "X-Amz-SignedHeaders", valid_611530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611532: Call_CreateJob_611520; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new job definition.
  ## 
  let valid = call_611532.validator(path, query, header, formData, body)
  let scheme = call_611532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611532.url(scheme.get, call_611532.host, call_611532.base,
                         call_611532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611532, url, valid)

proc call*(call_611533: Call_CreateJob_611520; body: JsonNode): Recallable =
  ## createJob
  ## Creates a new job definition.
  ##   body: JObject (required)
  var body_611534 = newJObject()
  if body != nil:
    body_611534 = body
  result = call_611533.call(nil, nil, nil, nil, body_611534)

var createJob* = Call_CreateJob_611520(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.CreateJob",
                                    validator: validate_CreateJob_611521,
                                    base: "/", url: url_CreateJob_611522,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMLTransform_611535 = ref object of OpenApiRestCall_610658
proc url_CreateMLTransform_611537(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMLTransform_611536(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
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
  var valid_611538 = header.getOrDefault("X-Amz-Target")
  valid_611538 = validateParameter(valid_611538, JString, required = true, default = newJString(
      "AWSGlue.CreateMLTransform"))
  if valid_611538 != nil:
    section.add "X-Amz-Target", valid_611538
  var valid_611539 = header.getOrDefault("X-Amz-Signature")
  valid_611539 = validateParameter(valid_611539, JString, required = false,
                                 default = nil)
  if valid_611539 != nil:
    section.add "X-Amz-Signature", valid_611539
  var valid_611540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611540 = validateParameter(valid_611540, JString, required = false,
                                 default = nil)
  if valid_611540 != nil:
    section.add "X-Amz-Content-Sha256", valid_611540
  var valid_611541 = header.getOrDefault("X-Amz-Date")
  valid_611541 = validateParameter(valid_611541, JString, required = false,
                                 default = nil)
  if valid_611541 != nil:
    section.add "X-Amz-Date", valid_611541
  var valid_611542 = header.getOrDefault("X-Amz-Credential")
  valid_611542 = validateParameter(valid_611542, JString, required = false,
                                 default = nil)
  if valid_611542 != nil:
    section.add "X-Amz-Credential", valid_611542
  var valid_611543 = header.getOrDefault("X-Amz-Security-Token")
  valid_611543 = validateParameter(valid_611543, JString, required = false,
                                 default = nil)
  if valid_611543 != nil:
    section.add "X-Amz-Security-Token", valid_611543
  var valid_611544 = header.getOrDefault("X-Amz-Algorithm")
  valid_611544 = validateParameter(valid_611544, JString, required = false,
                                 default = nil)
  if valid_611544 != nil:
    section.add "X-Amz-Algorithm", valid_611544
  var valid_611545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611545 = validateParameter(valid_611545, JString, required = false,
                                 default = nil)
  if valid_611545 != nil:
    section.add "X-Amz-SignedHeaders", valid_611545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611547: Call_CreateMLTransform_611535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
  ## 
  let valid = call_611547.validator(path, query, header, formData, body)
  let scheme = call_611547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611547.url(scheme.get, call_611547.host, call_611547.base,
                         call_611547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611547, url, valid)

proc call*(call_611548: Call_CreateMLTransform_611535; body: JsonNode): Recallable =
  ## createMLTransform
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
  ##   body: JObject (required)
  var body_611549 = newJObject()
  if body != nil:
    body_611549 = body
  result = call_611548.call(nil, nil, nil, nil, body_611549)

var createMLTransform* = Call_CreateMLTransform_611535(name: "createMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateMLTransform",
    validator: validate_CreateMLTransform_611536, base: "/",
    url: url_CreateMLTransform_611537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePartition_611550 = ref object of OpenApiRestCall_610658
proc url_CreatePartition_611552(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePartition_611551(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a new partition.
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
  var valid_611553 = header.getOrDefault("X-Amz-Target")
  valid_611553 = validateParameter(valid_611553, JString, required = true, default = newJString(
      "AWSGlue.CreatePartition"))
  if valid_611553 != nil:
    section.add "X-Amz-Target", valid_611553
  var valid_611554 = header.getOrDefault("X-Amz-Signature")
  valid_611554 = validateParameter(valid_611554, JString, required = false,
                                 default = nil)
  if valid_611554 != nil:
    section.add "X-Amz-Signature", valid_611554
  var valid_611555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611555 = validateParameter(valid_611555, JString, required = false,
                                 default = nil)
  if valid_611555 != nil:
    section.add "X-Amz-Content-Sha256", valid_611555
  var valid_611556 = header.getOrDefault("X-Amz-Date")
  valid_611556 = validateParameter(valid_611556, JString, required = false,
                                 default = nil)
  if valid_611556 != nil:
    section.add "X-Amz-Date", valid_611556
  var valid_611557 = header.getOrDefault("X-Amz-Credential")
  valid_611557 = validateParameter(valid_611557, JString, required = false,
                                 default = nil)
  if valid_611557 != nil:
    section.add "X-Amz-Credential", valid_611557
  var valid_611558 = header.getOrDefault("X-Amz-Security-Token")
  valid_611558 = validateParameter(valid_611558, JString, required = false,
                                 default = nil)
  if valid_611558 != nil:
    section.add "X-Amz-Security-Token", valid_611558
  var valid_611559 = header.getOrDefault("X-Amz-Algorithm")
  valid_611559 = validateParameter(valid_611559, JString, required = false,
                                 default = nil)
  if valid_611559 != nil:
    section.add "X-Amz-Algorithm", valid_611559
  var valid_611560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611560 = validateParameter(valid_611560, JString, required = false,
                                 default = nil)
  if valid_611560 != nil:
    section.add "X-Amz-SignedHeaders", valid_611560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611562: Call_CreatePartition_611550; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new partition.
  ## 
  let valid = call_611562.validator(path, query, header, formData, body)
  let scheme = call_611562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611562.url(scheme.get, call_611562.host, call_611562.base,
                         call_611562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611562, url, valid)

proc call*(call_611563: Call_CreatePartition_611550; body: JsonNode): Recallable =
  ## createPartition
  ## Creates a new partition.
  ##   body: JObject (required)
  var body_611564 = newJObject()
  if body != nil:
    body_611564 = body
  result = call_611563.call(nil, nil, nil, nil, body_611564)

var createPartition* = Call_CreatePartition_611550(name: "createPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreatePartition",
    validator: validate_CreatePartition_611551, base: "/", url: url_CreatePartition_611552,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateScript_611565 = ref object of OpenApiRestCall_610658
proc url_CreateScript_611567(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateScript_611566(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Transforms a directed acyclic graph (DAG) into code.
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
  var valid_611568 = header.getOrDefault("X-Amz-Target")
  valid_611568 = validateParameter(valid_611568, JString, required = true,
                                 default = newJString("AWSGlue.CreateScript"))
  if valid_611568 != nil:
    section.add "X-Amz-Target", valid_611568
  var valid_611569 = header.getOrDefault("X-Amz-Signature")
  valid_611569 = validateParameter(valid_611569, JString, required = false,
                                 default = nil)
  if valid_611569 != nil:
    section.add "X-Amz-Signature", valid_611569
  var valid_611570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611570 = validateParameter(valid_611570, JString, required = false,
                                 default = nil)
  if valid_611570 != nil:
    section.add "X-Amz-Content-Sha256", valid_611570
  var valid_611571 = header.getOrDefault("X-Amz-Date")
  valid_611571 = validateParameter(valid_611571, JString, required = false,
                                 default = nil)
  if valid_611571 != nil:
    section.add "X-Amz-Date", valid_611571
  var valid_611572 = header.getOrDefault("X-Amz-Credential")
  valid_611572 = validateParameter(valid_611572, JString, required = false,
                                 default = nil)
  if valid_611572 != nil:
    section.add "X-Amz-Credential", valid_611572
  var valid_611573 = header.getOrDefault("X-Amz-Security-Token")
  valid_611573 = validateParameter(valid_611573, JString, required = false,
                                 default = nil)
  if valid_611573 != nil:
    section.add "X-Amz-Security-Token", valid_611573
  var valid_611574 = header.getOrDefault("X-Amz-Algorithm")
  valid_611574 = validateParameter(valid_611574, JString, required = false,
                                 default = nil)
  if valid_611574 != nil:
    section.add "X-Amz-Algorithm", valid_611574
  var valid_611575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611575 = validateParameter(valid_611575, JString, required = false,
                                 default = nil)
  if valid_611575 != nil:
    section.add "X-Amz-SignedHeaders", valid_611575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611577: Call_CreateScript_611565; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Transforms a directed acyclic graph (DAG) into code.
  ## 
  let valid = call_611577.validator(path, query, header, formData, body)
  let scheme = call_611577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611577.url(scheme.get, call_611577.host, call_611577.base,
                         call_611577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611577, url, valid)

proc call*(call_611578: Call_CreateScript_611565; body: JsonNode): Recallable =
  ## createScript
  ## Transforms a directed acyclic graph (DAG) into code.
  ##   body: JObject (required)
  var body_611579 = newJObject()
  if body != nil:
    body_611579 = body
  result = call_611578.call(nil, nil, nil, nil, body_611579)

var createScript* = Call_CreateScript_611565(name: "createScript",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateScript",
    validator: validate_CreateScript_611566, base: "/", url: url_CreateScript_611567,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSecurityConfiguration_611580 = ref object of OpenApiRestCall_610658
proc url_CreateSecurityConfiguration_611582(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSecurityConfiguration_611581(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
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
  var valid_611583 = header.getOrDefault("X-Amz-Target")
  valid_611583 = validateParameter(valid_611583, JString, required = true, default = newJString(
      "AWSGlue.CreateSecurityConfiguration"))
  if valid_611583 != nil:
    section.add "X-Amz-Target", valid_611583
  var valid_611584 = header.getOrDefault("X-Amz-Signature")
  valid_611584 = validateParameter(valid_611584, JString, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "X-Amz-Signature", valid_611584
  var valid_611585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611585 = validateParameter(valid_611585, JString, required = false,
                                 default = nil)
  if valid_611585 != nil:
    section.add "X-Amz-Content-Sha256", valid_611585
  var valid_611586 = header.getOrDefault("X-Amz-Date")
  valid_611586 = validateParameter(valid_611586, JString, required = false,
                                 default = nil)
  if valid_611586 != nil:
    section.add "X-Amz-Date", valid_611586
  var valid_611587 = header.getOrDefault("X-Amz-Credential")
  valid_611587 = validateParameter(valid_611587, JString, required = false,
                                 default = nil)
  if valid_611587 != nil:
    section.add "X-Amz-Credential", valid_611587
  var valid_611588 = header.getOrDefault("X-Amz-Security-Token")
  valid_611588 = validateParameter(valid_611588, JString, required = false,
                                 default = nil)
  if valid_611588 != nil:
    section.add "X-Amz-Security-Token", valid_611588
  var valid_611589 = header.getOrDefault("X-Amz-Algorithm")
  valid_611589 = validateParameter(valid_611589, JString, required = false,
                                 default = nil)
  if valid_611589 != nil:
    section.add "X-Amz-Algorithm", valid_611589
  var valid_611590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611590 = validateParameter(valid_611590, JString, required = false,
                                 default = nil)
  if valid_611590 != nil:
    section.add "X-Amz-SignedHeaders", valid_611590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611592: Call_CreateSecurityConfiguration_611580; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
  ## 
  let valid = call_611592.validator(path, query, header, formData, body)
  let scheme = call_611592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611592.url(scheme.get, call_611592.host, call_611592.base,
                         call_611592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611592, url, valid)

proc call*(call_611593: Call_CreateSecurityConfiguration_611580; body: JsonNode): Recallable =
  ## createSecurityConfiguration
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
  ##   body: JObject (required)
  var body_611594 = newJObject()
  if body != nil:
    body_611594 = body
  result = call_611593.call(nil, nil, nil, nil, body_611594)

var createSecurityConfiguration* = Call_CreateSecurityConfiguration_611580(
    name: "createSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateSecurityConfiguration",
    validator: validate_CreateSecurityConfiguration_611581, base: "/",
    url: url_CreateSecurityConfiguration_611582,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTable_611595 = ref object of OpenApiRestCall_610658
proc url_CreateTable_611597(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTable_611596(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new table definition in the Data Catalog.
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
  var valid_611598 = header.getOrDefault("X-Amz-Target")
  valid_611598 = validateParameter(valid_611598, JString, required = true,
                                 default = newJString("AWSGlue.CreateTable"))
  if valid_611598 != nil:
    section.add "X-Amz-Target", valid_611598
  var valid_611599 = header.getOrDefault("X-Amz-Signature")
  valid_611599 = validateParameter(valid_611599, JString, required = false,
                                 default = nil)
  if valid_611599 != nil:
    section.add "X-Amz-Signature", valid_611599
  var valid_611600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611600 = validateParameter(valid_611600, JString, required = false,
                                 default = nil)
  if valid_611600 != nil:
    section.add "X-Amz-Content-Sha256", valid_611600
  var valid_611601 = header.getOrDefault("X-Amz-Date")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "X-Amz-Date", valid_611601
  var valid_611602 = header.getOrDefault("X-Amz-Credential")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "X-Amz-Credential", valid_611602
  var valid_611603 = header.getOrDefault("X-Amz-Security-Token")
  valid_611603 = validateParameter(valid_611603, JString, required = false,
                                 default = nil)
  if valid_611603 != nil:
    section.add "X-Amz-Security-Token", valid_611603
  var valid_611604 = header.getOrDefault("X-Amz-Algorithm")
  valid_611604 = validateParameter(valid_611604, JString, required = false,
                                 default = nil)
  if valid_611604 != nil:
    section.add "X-Amz-Algorithm", valid_611604
  var valid_611605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611605 = validateParameter(valid_611605, JString, required = false,
                                 default = nil)
  if valid_611605 != nil:
    section.add "X-Amz-SignedHeaders", valid_611605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611607: Call_CreateTable_611595; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new table definition in the Data Catalog.
  ## 
  let valid = call_611607.validator(path, query, header, formData, body)
  let scheme = call_611607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611607.url(scheme.get, call_611607.host, call_611607.base,
                         call_611607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611607, url, valid)

proc call*(call_611608: Call_CreateTable_611595; body: JsonNode): Recallable =
  ## createTable
  ## Creates a new table definition in the Data Catalog.
  ##   body: JObject (required)
  var body_611609 = newJObject()
  if body != nil:
    body_611609 = body
  result = call_611608.call(nil, nil, nil, nil, body_611609)

var createTable* = Call_CreateTable_611595(name: "createTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.CreateTable",
                                        validator: validate_CreateTable_611596,
                                        base: "/", url: url_CreateTable_611597,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrigger_611610 = ref object of OpenApiRestCall_610658
proc url_CreateTrigger_611612(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTrigger_611611(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new trigger.
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
  var valid_611613 = header.getOrDefault("X-Amz-Target")
  valid_611613 = validateParameter(valid_611613, JString, required = true,
                                 default = newJString("AWSGlue.CreateTrigger"))
  if valid_611613 != nil:
    section.add "X-Amz-Target", valid_611613
  var valid_611614 = header.getOrDefault("X-Amz-Signature")
  valid_611614 = validateParameter(valid_611614, JString, required = false,
                                 default = nil)
  if valid_611614 != nil:
    section.add "X-Amz-Signature", valid_611614
  var valid_611615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611615 = validateParameter(valid_611615, JString, required = false,
                                 default = nil)
  if valid_611615 != nil:
    section.add "X-Amz-Content-Sha256", valid_611615
  var valid_611616 = header.getOrDefault("X-Amz-Date")
  valid_611616 = validateParameter(valid_611616, JString, required = false,
                                 default = nil)
  if valid_611616 != nil:
    section.add "X-Amz-Date", valid_611616
  var valid_611617 = header.getOrDefault("X-Amz-Credential")
  valid_611617 = validateParameter(valid_611617, JString, required = false,
                                 default = nil)
  if valid_611617 != nil:
    section.add "X-Amz-Credential", valid_611617
  var valid_611618 = header.getOrDefault("X-Amz-Security-Token")
  valid_611618 = validateParameter(valid_611618, JString, required = false,
                                 default = nil)
  if valid_611618 != nil:
    section.add "X-Amz-Security-Token", valid_611618
  var valid_611619 = header.getOrDefault("X-Amz-Algorithm")
  valid_611619 = validateParameter(valid_611619, JString, required = false,
                                 default = nil)
  if valid_611619 != nil:
    section.add "X-Amz-Algorithm", valid_611619
  var valid_611620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611620 = validateParameter(valid_611620, JString, required = false,
                                 default = nil)
  if valid_611620 != nil:
    section.add "X-Amz-SignedHeaders", valid_611620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611622: Call_CreateTrigger_611610; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new trigger.
  ## 
  let valid = call_611622.validator(path, query, header, formData, body)
  let scheme = call_611622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611622.url(scheme.get, call_611622.host, call_611622.base,
                         call_611622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611622, url, valid)

proc call*(call_611623: Call_CreateTrigger_611610; body: JsonNode): Recallable =
  ## createTrigger
  ## Creates a new trigger.
  ##   body: JObject (required)
  var body_611624 = newJObject()
  if body != nil:
    body_611624 = body
  result = call_611623.call(nil, nil, nil, nil, body_611624)

var createTrigger* = Call_CreateTrigger_611610(name: "createTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateTrigger",
    validator: validate_CreateTrigger_611611, base: "/", url: url_CreateTrigger_611612,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserDefinedFunction_611625 = ref object of OpenApiRestCall_610658
proc url_CreateUserDefinedFunction_611627(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUserDefinedFunction_611626(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new function definition in the Data Catalog.
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
  var valid_611628 = header.getOrDefault("X-Amz-Target")
  valid_611628 = validateParameter(valid_611628, JString, required = true, default = newJString(
      "AWSGlue.CreateUserDefinedFunction"))
  if valid_611628 != nil:
    section.add "X-Amz-Target", valid_611628
  var valid_611629 = header.getOrDefault("X-Amz-Signature")
  valid_611629 = validateParameter(valid_611629, JString, required = false,
                                 default = nil)
  if valid_611629 != nil:
    section.add "X-Amz-Signature", valid_611629
  var valid_611630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611630 = validateParameter(valid_611630, JString, required = false,
                                 default = nil)
  if valid_611630 != nil:
    section.add "X-Amz-Content-Sha256", valid_611630
  var valid_611631 = header.getOrDefault("X-Amz-Date")
  valid_611631 = validateParameter(valid_611631, JString, required = false,
                                 default = nil)
  if valid_611631 != nil:
    section.add "X-Amz-Date", valid_611631
  var valid_611632 = header.getOrDefault("X-Amz-Credential")
  valid_611632 = validateParameter(valid_611632, JString, required = false,
                                 default = nil)
  if valid_611632 != nil:
    section.add "X-Amz-Credential", valid_611632
  var valid_611633 = header.getOrDefault("X-Amz-Security-Token")
  valid_611633 = validateParameter(valid_611633, JString, required = false,
                                 default = nil)
  if valid_611633 != nil:
    section.add "X-Amz-Security-Token", valid_611633
  var valid_611634 = header.getOrDefault("X-Amz-Algorithm")
  valid_611634 = validateParameter(valid_611634, JString, required = false,
                                 default = nil)
  if valid_611634 != nil:
    section.add "X-Amz-Algorithm", valid_611634
  var valid_611635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611635 = validateParameter(valid_611635, JString, required = false,
                                 default = nil)
  if valid_611635 != nil:
    section.add "X-Amz-SignedHeaders", valid_611635
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611637: Call_CreateUserDefinedFunction_611625; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new function definition in the Data Catalog.
  ## 
  let valid = call_611637.validator(path, query, header, formData, body)
  let scheme = call_611637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611637.url(scheme.get, call_611637.host, call_611637.base,
                         call_611637.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611637, url, valid)

proc call*(call_611638: Call_CreateUserDefinedFunction_611625; body: JsonNode): Recallable =
  ## createUserDefinedFunction
  ## Creates a new function definition in the Data Catalog.
  ##   body: JObject (required)
  var body_611639 = newJObject()
  if body != nil:
    body_611639 = body
  result = call_611638.call(nil, nil, nil, nil, body_611639)

var createUserDefinedFunction* = Call_CreateUserDefinedFunction_611625(
    name: "createUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateUserDefinedFunction",
    validator: validate_CreateUserDefinedFunction_611626, base: "/",
    url: url_CreateUserDefinedFunction_611627,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkflow_611640 = ref object of OpenApiRestCall_610658
proc url_CreateWorkflow_611642(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateWorkflow_611641(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a new workflow.
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
  var valid_611643 = header.getOrDefault("X-Amz-Target")
  valid_611643 = validateParameter(valid_611643, JString, required = true,
                                 default = newJString("AWSGlue.CreateWorkflow"))
  if valid_611643 != nil:
    section.add "X-Amz-Target", valid_611643
  var valid_611644 = header.getOrDefault("X-Amz-Signature")
  valid_611644 = validateParameter(valid_611644, JString, required = false,
                                 default = nil)
  if valid_611644 != nil:
    section.add "X-Amz-Signature", valid_611644
  var valid_611645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611645 = validateParameter(valid_611645, JString, required = false,
                                 default = nil)
  if valid_611645 != nil:
    section.add "X-Amz-Content-Sha256", valid_611645
  var valid_611646 = header.getOrDefault("X-Amz-Date")
  valid_611646 = validateParameter(valid_611646, JString, required = false,
                                 default = nil)
  if valid_611646 != nil:
    section.add "X-Amz-Date", valid_611646
  var valid_611647 = header.getOrDefault("X-Amz-Credential")
  valid_611647 = validateParameter(valid_611647, JString, required = false,
                                 default = nil)
  if valid_611647 != nil:
    section.add "X-Amz-Credential", valid_611647
  var valid_611648 = header.getOrDefault("X-Amz-Security-Token")
  valid_611648 = validateParameter(valid_611648, JString, required = false,
                                 default = nil)
  if valid_611648 != nil:
    section.add "X-Amz-Security-Token", valid_611648
  var valid_611649 = header.getOrDefault("X-Amz-Algorithm")
  valid_611649 = validateParameter(valid_611649, JString, required = false,
                                 default = nil)
  if valid_611649 != nil:
    section.add "X-Amz-Algorithm", valid_611649
  var valid_611650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611650 = validateParameter(valid_611650, JString, required = false,
                                 default = nil)
  if valid_611650 != nil:
    section.add "X-Amz-SignedHeaders", valid_611650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611652: Call_CreateWorkflow_611640; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new workflow.
  ## 
  let valid = call_611652.validator(path, query, header, formData, body)
  let scheme = call_611652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611652.url(scheme.get, call_611652.host, call_611652.base,
                         call_611652.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611652, url, valid)

proc call*(call_611653: Call_CreateWorkflow_611640; body: JsonNode): Recallable =
  ## createWorkflow
  ## Creates a new workflow.
  ##   body: JObject (required)
  var body_611654 = newJObject()
  if body != nil:
    body_611654 = body
  result = call_611653.call(nil, nil, nil, nil, body_611654)

var createWorkflow* = Call_CreateWorkflow_611640(name: "createWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateWorkflow",
    validator: validate_CreateWorkflow_611641, base: "/", url: url_CreateWorkflow_611642,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteClassifier_611655 = ref object of OpenApiRestCall_610658
proc url_DeleteClassifier_611657(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteClassifier_611656(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Removes a classifier from the Data Catalog.
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
  var valid_611658 = header.getOrDefault("X-Amz-Target")
  valid_611658 = validateParameter(valid_611658, JString, required = true, default = newJString(
      "AWSGlue.DeleteClassifier"))
  if valid_611658 != nil:
    section.add "X-Amz-Target", valid_611658
  var valid_611659 = header.getOrDefault("X-Amz-Signature")
  valid_611659 = validateParameter(valid_611659, JString, required = false,
                                 default = nil)
  if valid_611659 != nil:
    section.add "X-Amz-Signature", valid_611659
  var valid_611660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611660 = validateParameter(valid_611660, JString, required = false,
                                 default = nil)
  if valid_611660 != nil:
    section.add "X-Amz-Content-Sha256", valid_611660
  var valid_611661 = header.getOrDefault("X-Amz-Date")
  valid_611661 = validateParameter(valid_611661, JString, required = false,
                                 default = nil)
  if valid_611661 != nil:
    section.add "X-Amz-Date", valid_611661
  var valid_611662 = header.getOrDefault("X-Amz-Credential")
  valid_611662 = validateParameter(valid_611662, JString, required = false,
                                 default = nil)
  if valid_611662 != nil:
    section.add "X-Amz-Credential", valid_611662
  var valid_611663 = header.getOrDefault("X-Amz-Security-Token")
  valid_611663 = validateParameter(valid_611663, JString, required = false,
                                 default = nil)
  if valid_611663 != nil:
    section.add "X-Amz-Security-Token", valid_611663
  var valid_611664 = header.getOrDefault("X-Amz-Algorithm")
  valid_611664 = validateParameter(valid_611664, JString, required = false,
                                 default = nil)
  if valid_611664 != nil:
    section.add "X-Amz-Algorithm", valid_611664
  var valid_611665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611665 = validateParameter(valid_611665, JString, required = false,
                                 default = nil)
  if valid_611665 != nil:
    section.add "X-Amz-SignedHeaders", valid_611665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611667: Call_DeleteClassifier_611655; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a classifier from the Data Catalog.
  ## 
  let valid = call_611667.validator(path, query, header, formData, body)
  let scheme = call_611667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611667.url(scheme.get, call_611667.host, call_611667.base,
                         call_611667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611667, url, valid)

proc call*(call_611668: Call_DeleteClassifier_611655; body: JsonNode): Recallable =
  ## deleteClassifier
  ## Removes a classifier from the Data Catalog.
  ##   body: JObject (required)
  var body_611669 = newJObject()
  if body != nil:
    body_611669 = body
  result = call_611668.call(nil, nil, nil, nil, body_611669)

var deleteClassifier* = Call_DeleteClassifier_611655(name: "deleteClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteClassifier",
    validator: validate_DeleteClassifier_611656, base: "/",
    url: url_DeleteClassifier_611657, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnection_611670 = ref object of OpenApiRestCall_610658
proc url_DeleteConnection_611672(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteConnection_611671(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes a connection from the Data Catalog.
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
  var valid_611673 = header.getOrDefault("X-Amz-Target")
  valid_611673 = validateParameter(valid_611673, JString, required = true, default = newJString(
      "AWSGlue.DeleteConnection"))
  if valid_611673 != nil:
    section.add "X-Amz-Target", valid_611673
  var valid_611674 = header.getOrDefault("X-Amz-Signature")
  valid_611674 = validateParameter(valid_611674, JString, required = false,
                                 default = nil)
  if valid_611674 != nil:
    section.add "X-Amz-Signature", valid_611674
  var valid_611675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611675 = validateParameter(valid_611675, JString, required = false,
                                 default = nil)
  if valid_611675 != nil:
    section.add "X-Amz-Content-Sha256", valid_611675
  var valid_611676 = header.getOrDefault("X-Amz-Date")
  valid_611676 = validateParameter(valid_611676, JString, required = false,
                                 default = nil)
  if valid_611676 != nil:
    section.add "X-Amz-Date", valid_611676
  var valid_611677 = header.getOrDefault("X-Amz-Credential")
  valid_611677 = validateParameter(valid_611677, JString, required = false,
                                 default = nil)
  if valid_611677 != nil:
    section.add "X-Amz-Credential", valid_611677
  var valid_611678 = header.getOrDefault("X-Amz-Security-Token")
  valid_611678 = validateParameter(valid_611678, JString, required = false,
                                 default = nil)
  if valid_611678 != nil:
    section.add "X-Amz-Security-Token", valid_611678
  var valid_611679 = header.getOrDefault("X-Amz-Algorithm")
  valid_611679 = validateParameter(valid_611679, JString, required = false,
                                 default = nil)
  if valid_611679 != nil:
    section.add "X-Amz-Algorithm", valid_611679
  var valid_611680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611680 = validateParameter(valid_611680, JString, required = false,
                                 default = nil)
  if valid_611680 != nil:
    section.add "X-Amz-SignedHeaders", valid_611680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611682: Call_DeleteConnection_611670; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a connection from the Data Catalog.
  ## 
  let valid = call_611682.validator(path, query, header, formData, body)
  let scheme = call_611682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611682.url(scheme.get, call_611682.host, call_611682.base,
                         call_611682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611682, url, valid)

proc call*(call_611683: Call_DeleteConnection_611670; body: JsonNode): Recallable =
  ## deleteConnection
  ## Deletes a connection from the Data Catalog.
  ##   body: JObject (required)
  var body_611684 = newJObject()
  if body != nil:
    body_611684 = body
  result = call_611683.call(nil, nil, nil, nil, body_611684)

var deleteConnection* = Call_DeleteConnection_611670(name: "deleteConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteConnection",
    validator: validate_DeleteConnection_611671, base: "/",
    url: url_DeleteConnection_611672, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCrawler_611685 = ref object of OpenApiRestCall_610658
proc url_DeleteCrawler_611687(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteCrawler_611686(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
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
  var valid_611688 = header.getOrDefault("X-Amz-Target")
  valid_611688 = validateParameter(valid_611688, JString, required = true,
                                 default = newJString("AWSGlue.DeleteCrawler"))
  if valid_611688 != nil:
    section.add "X-Amz-Target", valid_611688
  var valid_611689 = header.getOrDefault("X-Amz-Signature")
  valid_611689 = validateParameter(valid_611689, JString, required = false,
                                 default = nil)
  if valid_611689 != nil:
    section.add "X-Amz-Signature", valid_611689
  var valid_611690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611690 = validateParameter(valid_611690, JString, required = false,
                                 default = nil)
  if valid_611690 != nil:
    section.add "X-Amz-Content-Sha256", valid_611690
  var valid_611691 = header.getOrDefault("X-Amz-Date")
  valid_611691 = validateParameter(valid_611691, JString, required = false,
                                 default = nil)
  if valid_611691 != nil:
    section.add "X-Amz-Date", valid_611691
  var valid_611692 = header.getOrDefault("X-Amz-Credential")
  valid_611692 = validateParameter(valid_611692, JString, required = false,
                                 default = nil)
  if valid_611692 != nil:
    section.add "X-Amz-Credential", valid_611692
  var valid_611693 = header.getOrDefault("X-Amz-Security-Token")
  valid_611693 = validateParameter(valid_611693, JString, required = false,
                                 default = nil)
  if valid_611693 != nil:
    section.add "X-Amz-Security-Token", valid_611693
  var valid_611694 = header.getOrDefault("X-Amz-Algorithm")
  valid_611694 = validateParameter(valid_611694, JString, required = false,
                                 default = nil)
  if valid_611694 != nil:
    section.add "X-Amz-Algorithm", valid_611694
  var valid_611695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611695 = validateParameter(valid_611695, JString, required = false,
                                 default = nil)
  if valid_611695 != nil:
    section.add "X-Amz-SignedHeaders", valid_611695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611697: Call_DeleteCrawler_611685; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
  ## 
  let valid = call_611697.validator(path, query, header, formData, body)
  let scheme = call_611697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611697.url(scheme.get, call_611697.host, call_611697.base,
                         call_611697.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611697, url, valid)

proc call*(call_611698: Call_DeleteCrawler_611685; body: JsonNode): Recallable =
  ## deleteCrawler
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
  ##   body: JObject (required)
  var body_611699 = newJObject()
  if body != nil:
    body_611699 = body
  result = call_611698.call(nil, nil, nil, nil, body_611699)

var deleteCrawler* = Call_DeleteCrawler_611685(name: "deleteCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteCrawler",
    validator: validate_DeleteCrawler_611686, base: "/", url: url_DeleteCrawler_611687,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatabase_611700 = ref object of OpenApiRestCall_610658
proc url_DeleteDatabase_611702(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDatabase_611701(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
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
  var valid_611703 = header.getOrDefault("X-Amz-Target")
  valid_611703 = validateParameter(valid_611703, JString, required = true,
                                 default = newJString("AWSGlue.DeleteDatabase"))
  if valid_611703 != nil:
    section.add "X-Amz-Target", valid_611703
  var valid_611704 = header.getOrDefault("X-Amz-Signature")
  valid_611704 = validateParameter(valid_611704, JString, required = false,
                                 default = nil)
  if valid_611704 != nil:
    section.add "X-Amz-Signature", valid_611704
  var valid_611705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611705 = validateParameter(valid_611705, JString, required = false,
                                 default = nil)
  if valid_611705 != nil:
    section.add "X-Amz-Content-Sha256", valid_611705
  var valid_611706 = header.getOrDefault("X-Amz-Date")
  valid_611706 = validateParameter(valid_611706, JString, required = false,
                                 default = nil)
  if valid_611706 != nil:
    section.add "X-Amz-Date", valid_611706
  var valid_611707 = header.getOrDefault("X-Amz-Credential")
  valid_611707 = validateParameter(valid_611707, JString, required = false,
                                 default = nil)
  if valid_611707 != nil:
    section.add "X-Amz-Credential", valid_611707
  var valid_611708 = header.getOrDefault("X-Amz-Security-Token")
  valid_611708 = validateParameter(valid_611708, JString, required = false,
                                 default = nil)
  if valid_611708 != nil:
    section.add "X-Amz-Security-Token", valid_611708
  var valid_611709 = header.getOrDefault("X-Amz-Algorithm")
  valid_611709 = validateParameter(valid_611709, JString, required = false,
                                 default = nil)
  if valid_611709 != nil:
    section.add "X-Amz-Algorithm", valid_611709
  var valid_611710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611710 = validateParameter(valid_611710, JString, required = false,
                                 default = nil)
  if valid_611710 != nil:
    section.add "X-Amz-SignedHeaders", valid_611710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611712: Call_DeleteDatabase_611700; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
  ## 
  let valid = call_611712.validator(path, query, header, formData, body)
  let scheme = call_611712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611712.url(scheme.get, call_611712.host, call_611712.base,
                         call_611712.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611712, url, valid)

proc call*(call_611713: Call_DeleteDatabase_611700; body: JsonNode): Recallable =
  ## deleteDatabase
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
  ##   body: JObject (required)
  var body_611714 = newJObject()
  if body != nil:
    body_611714 = body
  result = call_611713.call(nil, nil, nil, nil, body_611714)

var deleteDatabase* = Call_DeleteDatabase_611700(name: "deleteDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteDatabase",
    validator: validate_DeleteDatabase_611701, base: "/", url: url_DeleteDatabase_611702,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevEndpoint_611715 = ref object of OpenApiRestCall_610658
proc url_DeleteDevEndpoint_611717(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDevEndpoint_611716(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes a specified development endpoint.
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
  var valid_611718 = header.getOrDefault("X-Amz-Target")
  valid_611718 = validateParameter(valid_611718, JString, required = true, default = newJString(
      "AWSGlue.DeleteDevEndpoint"))
  if valid_611718 != nil:
    section.add "X-Amz-Target", valid_611718
  var valid_611719 = header.getOrDefault("X-Amz-Signature")
  valid_611719 = validateParameter(valid_611719, JString, required = false,
                                 default = nil)
  if valid_611719 != nil:
    section.add "X-Amz-Signature", valid_611719
  var valid_611720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611720 = validateParameter(valid_611720, JString, required = false,
                                 default = nil)
  if valid_611720 != nil:
    section.add "X-Amz-Content-Sha256", valid_611720
  var valid_611721 = header.getOrDefault("X-Amz-Date")
  valid_611721 = validateParameter(valid_611721, JString, required = false,
                                 default = nil)
  if valid_611721 != nil:
    section.add "X-Amz-Date", valid_611721
  var valid_611722 = header.getOrDefault("X-Amz-Credential")
  valid_611722 = validateParameter(valid_611722, JString, required = false,
                                 default = nil)
  if valid_611722 != nil:
    section.add "X-Amz-Credential", valid_611722
  var valid_611723 = header.getOrDefault("X-Amz-Security-Token")
  valid_611723 = validateParameter(valid_611723, JString, required = false,
                                 default = nil)
  if valid_611723 != nil:
    section.add "X-Amz-Security-Token", valid_611723
  var valid_611724 = header.getOrDefault("X-Amz-Algorithm")
  valid_611724 = validateParameter(valid_611724, JString, required = false,
                                 default = nil)
  if valid_611724 != nil:
    section.add "X-Amz-Algorithm", valid_611724
  var valid_611725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611725 = validateParameter(valid_611725, JString, required = false,
                                 default = nil)
  if valid_611725 != nil:
    section.add "X-Amz-SignedHeaders", valid_611725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611727: Call_DeleteDevEndpoint_611715; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified development endpoint.
  ## 
  let valid = call_611727.validator(path, query, header, formData, body)
  let scheme = call_611727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611727.url(scheme.get, call_611727.host, call_611727.base,
                         call_611727.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611727, url, valid)

proc call*(call_611728: Call_DeleteDevEndpoint_611715; body: JsonNode): Recallable =
  ## deleteDevEndpoint
  ## Deletes a specified development endpoint.
  ##   body: JObject (required)
  var body_611729 = newJObject()
  if body != nil:
    body_611729 = body
  result = call_611728.call(nil, nil, nil, nil, body_611729)

var deleteDevEndpoint* = Call_DeleteDevEndpoint_611715(name: "deleteDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteDevEndpoint",
    validator: validate_DeleteDevEndpoint_611716, base: "/",
    url: url_DeleteDevEndpoint_611717, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJob_611730 = ref object of OpenApiRestCall_610658
proc url_DeleteJob_611732(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteJob_611731(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
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
  var valid_611733 = header.getOrDefault("X-Amz-Target")
  valid_611733 = validateParameter(valid_611733, JString, required = true,
                                 default = newJString("AWSGlue.DeleteJob"))
  if valid_611733 != nil:
    section.add "X-Amz-Target", valid_611733
  var valid_611734 = header.getOrDefault("X-Amz-Signature")
  valid_611734 = validateParameter(valid_611734, JString, required = false,
                                 default = nil)
  if valid_611734 != nil:
    section.add "X-Amz-Signature", valid_611734
  var valid_611735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611735 = validateParameter(valid_611735, JString, required = false,
                                 default = nil)
  if valid_611735 != nil:
    section.add "X-Amz-Content-Sha256", valid_611735
  var valid_611736 = header.getOrDefault("X-Amz-Date")
  valid_611736 = validateParameter(valid_611736, JString, required = false,
                                 default = nil)
  if valid_611736 != nil:
    section.add "X-Amz-Date", valid_611736
  var valid_611737 = header.getOrDefault("X-Amz-Credential")
  valid_611737 = validateParameter(valid_611737, JString, required = false,
                                 default = nil)
  if valid_611737 != nil:
    section.add "X-Amz-Credential", valid_611737
  var valid_611738 = header.getOrDefault("X-Amz-Security-Token")
  valid_611738 = validateParameter(valid_611738, JString, required = false,
                                 default = nil)
  if valid_611738 != nil:
    section.add "X-Amz-Security-Token", valid_611738
  var valid_611739 = header.getOrDefault("X-Amz-Algorithm")
  valid_611739 = validateParameter(valid_611739, JString, required = false,
                                 default = nil)
  if valid_611739 != nil:
    section.add "X-Amz-Algorithm", valid_611739
  var valid_611740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611740 = validateParameter(valid_611740, JString, required = false,
                                 default = nil)
  if valid_611740 != nil:
    section.add "X-Amz-SignedHeaders", valid_611740
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611742: Call_DeleteJob_611730; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
  ## 
  let valid = call_611742.validator(path, query, header, formData, body)
  let scheme = call_611742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611742.url(scheme.get, call_611742.host, call_611742.base,
                         call_611742.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611742, url, valid)

proc call*(call_611743: Call_DeleteJob_611730; body: JsonNode): Recallable =
  ## deleteJob
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
  ##   body: JObject (required)
  var body_611744 = newJObject()
  if body != nil:
    body_611744 = body
  result = call_611743.call(nil, nil, nil, nil, body_611744)

var deleteJob* = Call_DeleteJob_611730(name: "deleteJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.DeleteJob",
                                    validator: validate_DeleteJob_611731,
                                    base: "/", url: url_DeleteJob_611732,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMLTransform_611745 = ref object of OpenApiRestCall_610658
proc url_DeleteMLTransform_611747(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteMLTransform_611746(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
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
  var valid_611748 = header.getOrDefault("X-Amz-Target")
  valid_611748 = validateParameter(valid_611748, JString, required = true, default = newJString(
      "AWSGlue.DeleteMLTransform"))
  if valid_611748 != nil:
    section.add "X-Amz-Target", valid_611748
  var valid_611749 = header.getOrDefault("X-Amz-Signature")
  valid_611749 = validateParameter(valid_611749, JString, required = false,
                                 default = nil)
  if valid_611749 != nil:
    section.add "X-Amz-Signature", valid_611749
  var valid_611750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611750 = validateParameter(valid_611750, JString, required = false,
                                 default = nil)
  if valid_611750 != nil:
    section.add "X-Amz-Content-Sha256", valid_611750
  var valid_611751 = header.getOrDefault("X-Amz-Date")
  valid_611751 = validateParameter(valid_611751, JString, required = false,
                                 default = nil)
  if valid_611751 != nil:
    section.add "X-Amz-Date", valid_611751
  var valid_611752 = header.getOrDefault("X-Amz-Credential")
  valid_611752 = validateParameter(valid_611752, JString, required = false,
                                 default = nil)
  if valid_611752 != nil:
    section.add "X-Amz-Credential", valid_611752
  var valid_611753 = header.getOrDefault("X-Amz-Security-Token")
  valid_611753 = validateParameter(valid_611753, JString, required = false,
                                 default = nil)
  if valid_611753 != nil:
    section.add "X-Amz-Security-Token", valid_611753
  var valid_611754 = header.getOrDefault("X-Amz-Algorithm")
  valid_611754 = validateParameter(valid_611754, JString, required = false,
                                 default = nil)
  if valid_611754 != nil:
    section.add "X-Amz-Algorithm", valid_611754
  var valid_611755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611755 = validateParameter(valid_611755, JString, required = false,
                                 default = nil)
  if valid_611755 != nil:
    section.add "X-Amz-SignedHeaders", valid_611755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611757: Call_DeleteMLTransform_611745; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
  ## 
  let valid = call_611757.validator(path, query, header, formData, body)
  let scheme = call_611757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611757.url(scheme.get, call_611757.host, call_611757.base,
                         call_611757.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611757, url, valid)

proc call*(call_611758: Call_DeleteMLTransform_611745; body: JsonNode): Recallable =
  ## deleteMLTransform
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
  ##   body: JObject (required)
  var body_611759 = newJObject()
  if body != nil:
    body_611759 = body
  result = call_611758.call(nil, nil, nil, nil, body_611759)

var deleteMLTransform* = Call_DeleteMLTransform_611745(name: "deleteMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteMLTransform",
    validator: validate_DeleteMLTransform_611746, base: "/",
    url: url_DeleteMLTransform_611747, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePartition_611760 = ref object of OpenApiRestCall_610658
proc url_DeletePartition_611762(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePartition_611761(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Deletes a specified partition.
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
  var valid_611763 = header.getOrDefault("X-Amz-Target")
  valid_611763 = validateParameter(valid_611763, JString, required = true, default = newJString(
      "AWSGlue.DeletePartition"))
  if valid_611763 != nil:
    section.add "X-Amz-Target", valid_611763
  var valid_611764 = header.getOrDefault("X-Amz-Signature")
  valid_611764 = validateParameter(valid_611764, JString, required = false,
                                 default = nil)
  if valid_611764 != nil:
    section.add "X-Amz-Signature", valid_611764
  var valid_611765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611765 = validateParameter(valid_611765, JString, required = false,
                                 default = nil)
  if valid_611765 != nil:
    section.add "X-Amz-Content-Sha256", valid_611765
  var valid_611766 = header.getOrDefault("X-Amz-Date")
  valid_611766 = validateParameter(valid_611766, JString, required = false,
                                 default = nil)
  if valid_611766 != nil:
    section.add "X-Amz-Date", valid_611766
  var valid_611767 = header.getOrDefault("X-Amz-Credential")
  valid_611767 = validateParameter(valid_611767, JString, required = false,
                                 default = nil)
  if valid_611767 != nil:
    section.add "X-Amz-Credential", valid_611767
  var valid_611768 = header.getOrDefault("X-Amz-Security-Token")
  valid_611768 = validateParameter(valid_611768, JString, required = false,
                                 default = nil)
  if valid_611768 != nil:
    section.add "X-Amz-Security-Token", valid_611768
  var valid_611769 = header.getOrDefault("X-Amz-Algorithm")
  valid_611769 = validateParameter(valid_611769, JString, required = false,
                                 default = nil)
  if valid_611769 != nil:
    section.add "X-Amz-Algorithm", valid_611769
  var valid_611770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611770 = validateParameter(valid_611770, JString, required = false,
                                 default = nil)
  if valid_611770 != nil:
    section.add "X-Amz-SignedHeaders", valid_611770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611772: Call_DeletePartition_611760; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified partition.
  ## 
  let valid = call_611772.validator(path, query, header, formData, body)
  let scheme = call_611772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611772.url(scheme.get, call_611772.host, call_611772.base,
                         call_611772.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611772, url, valid)

proc call*(call_611773: Call_DeletePartition_611760; body: JsonNode): Recallable =
  ## deletePartition
  ## Deletes a specified partition.
  ##   body: JObject (required)
  var body_611774 = newJObject()
  if body != nil:
    body_611774 = body
  result = call_611773.call(nil, nil, nil, nil, body_611774)

var deletePartition* = Call_DeletePartition_611760(name: "deletePartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeletePartition",
    validator: validate_DeletePartition_611761, base: "/", url: url_DeletePartition_611762,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourcePolicy_611775 = ref object of OpenApiRestCall_610658
proc url_DeleteResourcePolicy_611777(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteResourcePolicy_611776(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified policy.
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
  var valid_611778 = header.getOrDefault("X-Amz-Target")
  valid_611778 = validateParameter(valid_611778, JString, required = true, default = newJString(
      "AWSGlue.DeleteResourcePolicy"))
  if valid_611778 != nil:
    section.add "X-Amz-Target", valid_611778
  var valid_611779 = header.getOrDefault("X-Amz-Signature")
  valid_611779 = validateParameter(valid_611779, JString, required = false,
                                 default = nil)
  if valid_611779 != nil:
    section.add "X-Amz-Signature", valid_611779
  var valid_611780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611780 = validateParameter(valid_611780, JString, required = false,
                                 default = nil)
  if valid_611780 != nil:
    section.add "X-Amz-Content-Sha256", valid_611780
  var valid_611781 = header.getOrDefault("X-Amz-Date")
  valid_611781 = validateParameter(valid_611781, JString, required = false,
                                 default = nil)
  if valid_611781 != nil:
    section.add "X-Amz-Date", valid_611781
  var valid_611782 = header.getOrDefault("X-Amz-Credential")
  valid_611782 = validateParameter(valid_611782, JString, required = false,
                                 default = nil)
  if valid_611782 != nil:
    section.add "X-Amz-Credential", valid_611782
  var valid_611783 = header.getOrDefault("X-Amz-Security-Token")
  valid_611783 = validateParameter(valid_611783, JString, required = false,
                                 default = nil)
  if valid_611783 != nil:
    section.add "X-Amz-Security-Token", valid_611783
  var valid_611784 = header.getOrDefault("X-Amz-Algorithm")
  valid_611784 = validateParameter(valid_611784, JString, required = false,
                                 default = nil)
  if valid_611784 != nil:
    section.add "X-Amz-Algorithm", valid_611784
  var valid_611785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611785 = validateParameter(valid_611785, JString, required = false,
                                 default = nil)
  if valid_611785 != nil:
    section.add "X-Amz-SignedHeaders", valid_611785
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611787: Call_DeleteResourcePolicy_611775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified policy.
  ## 
  let valid = call_611787.validator(path, query, header, formData, body)
  let scheme = call_611787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611787.url(scheme.get, call_611787.host, call_611787.base,
                         call_611787.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611787, url, valid)

proc call*(call_611788: Call_DeleteResourcePolicy_611775; body: JsonNode): Recallable =
  ## deleteResourcePolicy
  ## Deletes a specified policy.
  ##   body: JObject (required)
  var body_611789 = newJObject()
  if body != nil:
    body_611789 = body
  result = call_611788.call(nil, nil, nil, nil, body_611789)

var deleteResourcePolicy* = Call_DeleteResourcePolicy_611775(
    name: "deleteResourcePolicy", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteResourcePolicy",
    validator: validate_DeleteResourcePolicy_611776, base: "/",
    url: url_DeleteResourcePolicy_611777, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSecurityConfiguration_611790 = ref object of OpenApiRestCall_610658
proc url_DeleteSecurityConfiguration_611792(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSecurityConfiguration_611791(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified security configuration.
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
  var valid_611793 = header.getOrDefault("X-Amz-Target")
  valid_611793 = validateParameter(valid_611793, JString, required = true, default = newJString(
      "AWSGlue.DeleteSecurityConfiguration"))
  if valid_611793 != nil:
    section.add "X-Amz-Target", valid_611793
  var valid_611794 = header.getOrDefault("X-Amz-Signature")
  valid_611794 = validateParameter(valid_611794, JString, required = false,
                                 default = nil)
  if valid_611794 != nil:
    section.add "X-Amz-Signature", valid_611794
  var valid_611795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611795 = validateParameter(valid_611795, JString, required = false,
                                 default = nil)
  if valid_611795 != nil:
    section.add "X-Amz-Content-Sha256", valid_611795
  var valid_611796 = header.getOrDefault("X-Amz-Date")
  valid_611796 = validateParameter(valid_611796, JString, required = false,
                                 default = nil)
  if valid_611796 != nil:
    section.add "X-Amz-Date", valid_611796
  var valid_611797 = header.getOrDefault("X-Amz-Credential")
  valid_611797 = validateParameter(valid_611797, JString, required = false,
                                 default = nil)
  if valid_611797 != nil:
    section.add "X-Amz-Credential", valid_611797
  var valid_611798 = header.getOrDefault("X-Amz-Security-Token")
  valid_611798 = validateParameter(valid_611798, JString, required = false,
                                 default = nil)
  if valid_611798 != nil:
    section.add "X-Amz-Security-Token", valid_611798
  var valid_611799 = header.getOrDefault("X-Amz-Algorithm")
  valid_611799 = validateParameter(valid_611799, JString, required = false,
                                 default = nil)
  if valid_611799 != nil:
    section.add "X-Amz-Algorithm", valid_611799
  var valid_611800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611800 = validateParameter(valid_611800, JString, required = false,
                                 default = nil)
  if valid_611800 != nil:
    section.add "X-Amz-SignedHeaders", valid_611800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611802: Call_DeleteSecurityConfiguration_611790; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified security configuration.
  ## 
  let valid = call_611802.validator(path, query, header, formData, body)
  let scheme = call_611802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611802.url(scheme.get, call_611802.host, call_611802.base,
                         call_611802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611802, url, valid)

proc call*(call_611803: Call_DeleteSecurityConfiguration_611790; body: JsonNode): Recallable =
  ## deleteSecurityConfiguration
  ## Deletes a specified security configuration.
  ##   body: JObject (required)
  var body_611804 = newJObject()
  if body != nil:
    body_611804 = body
  result = call_611803.call(nil, nil, nil, nil, body_611804)

var deleteSecurityConfiguration* = Call_DeleteSecurityConfiguration_611790(
    name: "deleteSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteSecurityConfiguration",
    validator: validate_DeleteSecurityConfiguration_611791, base: "/",
    url: url_DeleteSecurityConfiguration_611792,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTable_611805 = ref object of OpenApiRestCall_610658
proc url_DeleteTable_611807(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTable_611806(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
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
  var valid_611808 = header.getOrDefault("X-Amz-Target")
  valid_611808 = validateParameter(valid_611808, JString, required = true,
                                 default = newJString("AWSGlue.DeleteTable"))
  if valid_611808 != nil:
    section.add "X-Amz-Target", valid_611808
  var valid_611809 = header.getOrDefault("X-Amz-Signature")
  valid_611809 = validateParameter(valid_611809, JString, required = false,
                                 default = nil)
  if valid_611809 != nil:
    section.add "X-Amz-Signature", valid_611809
  var valid_611810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611810 = validateParameter(valid_611810, JString, required = false,
                                 default = nil)
  if valid_611810 != nil:
    section.add "X-Amz-Content-Sha256", valid_611810
  var valid_611811 = header.getOrDefault("X-Amz-Date")
  valid_611811 = validateParameter(valid_611811, JString, required = false,
                                 default = nil)
  if valid_611811 != nil:
    section.add "X-Amz-Date", valid_611811
  var valid_611812 = header.getOrDefault("X-Amz-Credential")
  valid_611812 = validateParameter(valid_611812, JString, required = false,
                                 default = nil)
  if valid_611812 != nil:
    section.add "X-Amz-Credential", valid_611812
  var valid_611813 = header.getOrDefault("X-Amz-Security-Token")
  valid_611813 = validateParameter(valid_611813, JString, required = false,
                                 default = nil)
  if valid_611813 != nil:
    section.add "X-Amz-Security-Token", valid_611813
  var valid_611814 = header.getOrDefault("X-Amz-Algorithm")
  valid_611814 = validateParameter(valid_611814, JString, required = false,
                                 default = nil)
  if valid_611814 != nil:
    section.add "X-Amz-Algorithm", valid_611814
  var valid_611815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611815 = validateParameter(valid_611815, JString, required = false,
                                 default = nil)
  if valid_611815 != nil:
    section.add "X-Amz-SignedHeaders", valid_611815
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611817: Call_DeleteTable_611805; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ## 
  let valid = call_611817.validator(path, query, header, formData, body)
  let scheme = call_611817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611817.url(scheme.get, call_611817.host, call_611817.base,
                         call_611817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611817, url, valid)

proc call*(call_611818: Call_DeleteTable_611805; body: JsonNode): Recallable =
  ## deleteTable
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ##   body: JObject (required)
  var body_611819 = newJObject()
  if body != nil:
    body_611819 = body
  result = call_611818.call(nil, nil, nil, nil, body_611819)

var deleteTable* = Call_DeleteTable_611805(name: "deleteTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.DeleteTable",
                                        validator: validate_DeleteTable_611806,
                                        base: "/", url: url_DeleteTable_611807,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTableVersion_611820 = ref object of OpenApiRestCall_610658
proc url_DeleteTableVersion_611822(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTableVersion_611821(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes a specified version of a table.
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
  var valid_611823 = header.getOrDefault("X-Amz-Target")
  valid_611823 = validateParameter(valid_611823, JString, required = true, default = newJString(
      "AWSGlue.DeleteTableVersion"))
  if valid_611823 != nil:
    section.add "X-Amz-Target", valid_611823
  var valid_611824 = header.getOrDefault("X-Amz-Signature")
  valid_611824 = validateParameter(valid_611824, JString, required = false,
                                 default = nil)
  if valid_611824 != nil:
    section.add "X-Amz-Signature", valid_611824
  var valid_611825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611825 = validateParameter(valid_611825, JString, required = false,
                                 default = nil)
  if valid_611825 != nil:
    section.add "X-Amz-Content-Sha256", valid_611825
  var valid_611826 = header.getOrDefault("X-Amz-Date")
  valid_611826 = validateParameter(valid_611826, JString, required = false,
                                 default = nil)
  if valid_611826 != nil:
    section.add "X-Amz-Date", valid_611826
  var valid_611827 = header.getOrDefault("X-Amz-Credential")
  valid_611827 = validateParameter(valid_611827, JString, required = false,
                                 default = nil)
  if valid_611827 != nil:
    section.add "X-Amz-Credential", valid_611827
  var valid_611828 = header.getOrDefault("X-Amz-Security-Token")
  valid_611828 = validateParameter(valid_611828, JString, required = false,
                                 default = nil)
  if valid_611828 != nil:
    section.add "X-Amz-Security-Token", valid_611828
  var valid_611829 = header.getOrDefault("X-Amz-Algorithm")
  valid_611829 = validateParameter(valid_611829, JString, required = false,
                                 default = nil)
  if valid_611829 != nil:
    section.add "X-Amz-Algorithm", valid_611829
  var valid_611830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611830 = validateParameter(valid_611830, JString, required = false,
                                 default = nil)
  if valid_611830 != nil:
    section.add "X-Amz-SignedHeaders", valid_611830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611832: Call_DeleteTableVersion_611820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified version of a table.
  ## 
  let valid = call_611832.validator(path, query, header, formData, body)
  let scheme = call_611832.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611832.url(scheme.get, call_611832.host, call_611832.base,
                         call_611832.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611832, url, valid)

proc call*(call_611833: Call_DeleteTableVersion_611820; body: JsonNode): Recallable =
  ## deleteTableVersion
  ## Deletes a specified version of a table.
  ##   body: JObject (required)
  var body_611834 = newJObject()
  if body != nil:
    body_611834 = body
  result = call_611833.call(nil, nil, nil, nil, body_611834)

var deleteTableVersion* = Call_DeleteTableVersion_611820(
    name: "deleteTableVersion", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteTableVersion",
    validator: validate_DeleteTableVersion_611821, base: "/",
    url: url_DeleteTableVersion_611822, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrigger_611835 = ref object of OpenApiRestCall_610658
proc url_DeleteTrigger_611837(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTrigger_611836(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
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
  var valid_611838 = header.getOrDefault("X-Amz-Target")
  valid_611838 = validateParameter(valid_611838, JString, required = true,
                                 default = newJString("AWSGlue.DeleteTrigger"))
  if valid_611838 != nil:
    section.add "X-Amz-Target", valid_611838
  var valid_611839 = header.getOrDefault("X-Amz-Signature")
  valid_611839 = validateParameter(valid_611839, JString, required = false,
                                 default = nil)
  if valid_611839 != nil:
    section.add "X-Amz-Signature", valid_611839
  var valid_611840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611840 = validateParameter(valid_611840, JString, required = false,
                                 default = nil)
  if valid_611840 != nil:
    section.add "X-Amz-Content-Sha256", valid_611840
  var valid_611841 = header.getOrDefault("X-Amz-Date")
  valid_611841 = validateParameter(valid_611841, JString, required = false,
                                 default = nil)
  if valid_611841 != nil:
    section.add "X-Amz-Date", valid_611841
  var valid_611842 = header.getOrDefault("X-Amz-Credential")
  valid_611842 = validateParameter(valid_611842, JString, required = false,
                                 default = nil)
  if valid_611842 != nil:
    section.add "X-Amz-Credential", valid_611842
  var valid_611843 = header.getOrDefault("X-Amz-Security-Token")
  valid_611843 = validateParameter(valid_611843, JString, required = false,
                                 default = nil)
  if valid_611843 != nil:
    section.add "X-Amz-Security-Token", valid_611843
  var valid_611844 = header.getOrDefault("X-Amz-Algorithm")
  valid_611844 = validateParameter(valid_611844, JString, required = false,
                                 default = nil)
  if valid_611844 != nil:
    section.add "X-Amz-Algorithm", valid_611844
  var valid_611845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611845 = validateParameter(valid_611845, JString, required = false,
                                 default = nil)
  if valid_611845 != nil:
    section.add "X-Amz-SignedHeaders", valid_611845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611847: Call_DeleteTrigger_611835; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
  ## 
  let valid = call_611847.validator(path, query, header, formData, body)
  let scheme = call_611847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611847.url(scheme.get, call_611847.host, call_611847.base,
                         call_611847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611847, url, valid)

proc call*(call_611848: Call_DeleteTrigger_611835; body: JsonNode): Recallable =
  ## deleteTrigger
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
  ##   body: JObject (required)
  var body_611849 = newJObject()
  if body != nil:
    body_611849 = body
  result = call_611848.call(nil, nil, nil, nil, body_611849)

var deleteTrigger* = Call_DeleteTrigger_611835(name: "deleteTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteTrigger",
    validator: validate_DeleteTrigger_611836, base: "/", url: url_DeleteTrigger_611837,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserDefinedFunction_611850 = ref object of OpenApiRestCall_610658
proc url_DeleteUserDefinedFunction_611852(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUserDefinedFunction_611851(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing function definition from the Data Catalog.
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
  var valid_611853 = header.getOrDefault("X-Amz-Target")
  valid_611853 = validateParameter(valid_611853, JString, required = true, default = newJString(
      "AWSGlue.DeleteUserDefinedFunction"))
  if valid_611853 != nil:
    section.add "X-Amz-Target", valid_611853
  var valid_611854 = header.getOrDefault("X-Amz-Signature")
  valid_611854 = validateParameter(valid_611854, JString, required = false,
                                 default = nil)
  if valid_611854 != nil:
    section.add "X-Amz-Signature", valid_611854
  var valid_611855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611855 = validateParameter(valid_611855, JString, required = false,
                                 default = nil)
  if valid_611855 != nil:
    section.add "X-Amz-Content-Sha256", valid_611855
  var valid_611856 = header.getOrDefault("X-Amz-Date")
  valid_611856 = validateParameter(valid_611856, JString, required = false,
                                 default = nil)
  if valid_611856 != nil:
    section.add "X-Amz-Date", valid_611856
  var valid_611857 = header.getOrDefault("X-Amz-Credential")
  valid_611857 = validateParameter(valid_611857, JString, required = false,
                                 default = nil)
  if valid_611857 != nil:
    section.add "X-Amz-Credential", valid_611857
  var valid_611858 = header.getOrDefault("X-Amz-Security-Token")
  valid_611858 = validateParameter(valid_611858, JString, required = false,
                                 default = nil)
  if valid_611858 != nil:
    section.add "X-Amz-Security-Token", valid_611858
  var valid_611859 = header.getOrDefault("X-Amz-Algorithm")
  valid_611859 = validateParameter(valid_611859, JString, required = false,
                                 default = nil)
  if valid_611859 != nil:
    section.add "X-Amz-Algorithm", valid_611859
  var valid_611860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611860 = validateParameter(valid_611860, JString, required = false,
                                 default = nil)
  if valid_611860 != nil:
    section.add "X-Amz-SignedHeaders", valid_611860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611862: Call_DeleteUserDefinedFunction_611850; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing function definition from the Data Catalog.
  ## 
  let valid = call_611862.validator(path, query, header, formData, body)
  let scheme = call_611862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611862.url(scheme.get, call_611862.host, call_611862.base,
                         call_611862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611862, url, valid)

proc call*(call_611863: Call_DeleteUserDefinedFunction_611850; body: JsonNode): Recallable =
  ## deleteUserDefinedFunction
  ## Deletes an existing function definition from the Data Catalog.
  ##   body: JObject (required)
  var body_611864 = newJObject()
  if body != nil:
    body_611864 = body
  result = call_611863.call(nil, nil, nil, nil, body_611864)

var deleteUserDefinedFunction* = Call_DeleteUserDefinedFunction_611850(
    name: "deleteUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteUserDefinedFunction",
    validator: validate_DeleteUserDefinedFunction_611851, base: "/",
    url: url_DeleteUserDefinedFunction_611852,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkflow_611865 = ref object of OpenApiRestCall_610658
proc url_DeleteWorkflow_611867(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteWorkflow_611866(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes a workflow.
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
  var valid_611868 = header.getOrDefault("X-Amz-Target")
  valid_611868 = validateParameter(valid_611868, JString, required = true,
                                 default = newJString("AWSGlue.DeleteWorkflow"))
  if valid_611868 != nil:
    section.add "X-Amz-Target", valid_611868
  var valid_611869 = header.getOrDefault("X-Amz-Signature")
  valid_611869 = validateParameter(valid_611869, JString, required = false,
                                 default = nil)
  if valid_611869 != nil:
    section.add "X-Amz-Signature", valid_611869
  var valid_611870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611870 = validateParameter(valid_611870, JString, required = false,
                                 default = nil)
  if valid_611870 != nil:
    section.add "X-Amz-Content-Sha256", valid_611870
  var valid_611871 = header.getOrDefault("X-Amz-Date")
  valid_611871 = validateParameter(valid_611871, JString, required = false,
                                 default = nil)
  if valid_611871 != nil:
    section.add "X-Amz-Date", valid_611871
  var valid_611872 = header.getOrDefault("X-Amz-Credential")
  valid_611872 = validateParameter(valid_611872, JString, required = false,
                                 default = nil)
  if valid_611872 != nil:
    section.add "X-Amz-Credential", valid_611872
  var valid_611873 = header.getOrDefault("X-Amz-Security-Token")
  valid_611873 = validateParameter(valid_611873, JString, required = false,
                                 default = nil)
  if valid_611873 != nil:
    section.add "X-Amz-Security-Token", valid_611873
  var valid_611874 = header.getOrDefault("X-Amz-Algorithm")
  valid_611874 = validateParameter(valid_611874, JString, required = false,
                                 default = nil)
  if valid_611874 != nil:
    section.add "X-Amz-Algorithm", valid_611874
  var valid_611875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611875 = validateParameter(valid_611875, JString, required = false,
                                 default = nil)
  if valid_611875 != nil:
    section.add "X-Amz-SignedHeaders", valid_611875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611877: Call_DeleteWorkflow_611865; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a workflow.
  ## 
  let valid = call_611877.validator(path, query, header, formData, body)
  let scheme = call_611877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611877.url(scheme.get, call_611877.host, call_611877.base,
                         call_611877.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611877, url, valid)

proc call*(call_611878: Call_DeleteWorkflow_611865; body: JsonNode): Recallable =
  ## deleteWorkflow
  ## Deletes a workflow.
  ##   body: JObject (required)
  var body_611879 = newJObject()
  if body != nil:
    body_611879 = body
  result = call_611878.call(nil, nil, nil, nil, body_611879)

var deleteWorkflow* = Call_DeleteWorkflow_611865(name: "deleteWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteWorkflow",
    validator: validate_DeleteWorkflow_611866, base: "/", url: url_DeleteWorkflow_611867,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCatalogImportStatus_611880 = ref object of OpenApiRestCall_610658
proc url_GetCatalogImportStatus_611882(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCatalogImportStatus_611881(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the status of a migration operation.
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
  var valid_611883 = header.getOrDefault("X-Amz-Target")
  valid_611883 = validateParameter(valid_611883, JString, required = true, default = newJString(
      "AWSGlue.GetCatalogImportStatus"))
  if valid_611883 != nil:
    section.add "X-Amz-Target", valid_611883
  var valid_611884 = header.getOrDefault("X-Amz-Signature")
  valid_611884 = validateParameter(valid_611884, JString, required = false,
                                 default = nil)
  if valid_611884 != nil:
    section.add "X-Amz-Signature", valid_611884
  var valid_611885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611885 = validateParameter(valid_611885, JString, required = false,
                                 default = nil)
  if valid_611885 != nil:
    section.add "X-Amz-Content-Sha256", valid_611885
  var valid_611886 = header.getOrDefault("X-Amz-Date")
  valid_611886 = validateParameter(valid_611886, JString, required = false,
                                 default = nil)
  if valid_611886 != nil:
    section.add "X-Amz-Date", valid_611886
  var valid_611887 = header.getOrDefault("X-Amz-Credential")
  valid_611887 = validateParameter(valid_611887, JString, required = false,
                                 default = nil)
  if valid_611887 != nil:
    section.add "X-Amz-Credential", valid_611887
  var valid_611888 = header.getOrDefault("X-Amz-Security-Token")
  valid_611888 = validateParameter(valid_611888, JString, required = false,
                                 default = nil)
  if valid_611888 != nil:
    section.add "X-Amz-Security-Token", valid_611888
  var valid_611889 = header.getOrDefault("X-Amz-Algorithm")
  valid_611889 = validateParameter(valid_611889, JString, required = false,
                                 default = nil)
  if valid_611889 != nil:
    section.add "X-Amz-Algorithm", valid_611889
  var valid_611890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611890 = validateParameter(valid_611890, JString, required = false,
                                 default = nil)
  if valid_611890 != nil:
    section.add "X-Amz-SignedHeaders", valid_611890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611892: Call_GetCatalogImportStatus_611880; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the status of a migration operation.
  ## 
  let valid = call_611892.validator(path, query, header, formData, body)
  let scheme = call_611892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611892.url(scheme.get, call_611892.host, call_611892.base,
                         call_611892.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611892, url, valid)

proc call*(call_611893: Call_GetCatalogImportStatus_611880; body: JsonNode): Recallable =
  ## getCatalogImportStatus
  ## Retrieves the status of a migration operation.
  ##   body: JObject (required)
  var body_611894 = newJObject()
  if body != nil:
    body_611894 = body
  result = call_611893.call(nil, nil, nil, nil, body_611894)

var getCatalogImportStatus* = Call_GetCatalogImportStatus_611880(
    name: "getCatalogImportStatus", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetCatalogImportStatus",
    validator: validate_GetCatalogImportStatus_611881, base: "/",
    url: url_GetCatalogImportStatus_611882, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClassifier_611895 = ref object of OpenApiRestCall_610658
proc url_GetClassifier_611897(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetClassifier_611896(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve a classifier by name.
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
  var valid_611898 = header.getOrDefault("X-Amz-Target")
  valid_611898 = validateParameter(valid_611898, JString, required = true,
                                 default = newJString("AWSGlue.GetClassifier"))
  if valid_611898 != nil:
    section.add "X-Amz-Target", valid_611898
  var valid_611899 = header.getOrDefault("X-Amz-Signature")
  valid_611899 = validateParameter(valid_611899, JString, required = false,
                                 default = nil)
  if valid_611899 != nil:
    section.add "X-Amz-Signature", valid_611899
  var valid_611900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611900 = validateParameter(valid_611900, JString, required = false,
                                 default = nil)
  if valid_611900 != nil:
    section.add "X-Amz-Content-Sha256", valid_611900
  var valid_611901 = header.getOrDefault("X-Amz-Date")
  valid_611901 = validateParameter(valid_611901, JString, required = false,
                                 default = nil)
  if valid_611901 != nil:
    section.add "X-Amz-Date", valid_611901
  var valid_611902 = header.getOrDefault("X-Amz-Credential")
  valid_611902 = validateParameter(valid_611902, JString, required = false,
                                 default = nil)
  if valid_611902 != nil:
    section.add "X-Amz-Credential", valid_611902
  var valid_611903 = header.getOrDefault("X-Amz-Security-Token")
  valid_611903 = validateParameter(valid_611903, JString, required = false,
                                 default = nil)
  if valid_611903 != nil:
    section.add "X-Amz-Security-Token", valid_611903
  var valid_611904 = header.getOrDefault("X-Amz-Algorithm")
  valid_611904 = validateParameter(valid_611904, JString, required = false,
                                 default = nil)
  if valid_611904 != nil:
    section.add "X-Amz-Algorithm", valid_611904
  var valid_611905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611905 = validateParameter(valid_611905, JString, required = false,
                                 default = nil)
  if valid_611905 != nil:
    section.add "X-Amz-SignedHeaders", valid_611905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611907: Call_GetClassifier_611895; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a classifier by name.
  ## 
  let valid = call_611907.validator(path, query, header, formData, body)
  let scheme = call_611907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611907.url(scheme.get, call_611907.host, call_611907.base,
                         call_611907.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611907, url, valid)

proc call*(call_611908: Call_GetClassifier_611895; body: JsonNode): Recallable =
  ## getClassifier
  ## Retrieve a classifier by name.
  ##   body: JObject (required)
  var body_611909 = newJObject()
  if body != nil:
    body_611909 = body
  result = call_611908.call(nil, nil, nil, nil, body_611909)

var getClassifier* = Call_GetClassifier_611895(name: "getClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetClassifier",
    validator: validate_GetClassifier_611896, base: "/", url: url_GetClassifier_611897,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClassifiers_611910 = ref object of OpenApiRestCall_610658
proc url_GetClassifiers_611912(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetClassifiers_611911(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists all classifier objects in the Data Catalog.
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
  var valid_611913 = query.getOrDefault("MaxResults")
  valid_611913 = validateParameter(valid_611913, JString, required = false,
                                 default = nil)
  if valid_611913 != nil:
    section.add "MaxResults", valid_611913
  var valid_611914 = query.getOrDefault("NextToken")
  valid_611914 = validateParameter(valid_611914, JString, required = false,
                                 default = nil)
  if valid_611914 != nil:
    section.add "NextToken", valid_611914
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
  var valid_611915 = header.getOrDefault("X-Amz-Target")
  valid_611915 = validateParameter(valid_611915, JString, required = true,
                                 default = newJString("AWSGlue.GetClassifiers"))
  if valid_611915 != nil:
    section.add "X-Amz-Target", valid_611915
  var valid_611916 = header.getOrDefault("X-Amz-Signature")
  valid_611916 = validateParameter(valid_611916, JString, required = false,
                                 default = nil)
  if valid_611916 != nil:
    section.add "X-Amz-Signature", valid_611916
  var valid_611917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611917 = validateParameter(valid_611917, JString, required = false,
                                 default = nil)
  if valid_611917 != nil:
    section.add "X-Amz-Content-Sha256", valid_611917
  var valid_611918 = header.getOrDefault("X-Amz-Date")
  valid_611918 = validateParameter(valid_611918, JString, required = false,
                                 default = nil)
  if valid_611918 != nil:
    section.add "X-Amz-Date", valid_611918
  var valid_611919 = header.getOrDefault("X-Amz-Credential")
  valid_611919 = validateParameter(valid_611919, JString, required = false,
                                 default = nil)
  if valid_611919 != nil:
    section.add "X-Amz-Credential", valid_611919
  var valid_611920 = header.getOrDefault("X-Amz-Security-Token")
  valid_611920 = validateParameter(valid_611920, JString, required = false,
                                 default = nil)
  if valid_611920 != nil:
    section.add "X-Amz-Security-Token", valid_611920
  var valid_611921 = header.getOrDefault("X-Amz-Algorithm")
  valid_611921 = validateParameter(valid_611921, JString, required = false,
                                 default = nil)
  if valid_611921 != nil:
    section.add "X-Amz-Algorithm", valid_611921
  var valid_611922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611922 = validateParameter(valid_611922, JString, required = false,
                                 default = nil)
  if valid_611922 != nil:
    section.add "X-Amz-SignedHeaders", valid_611922
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611924: Call_GetClassifiers_611910; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all classifier objects in the Data Catalog.
  ## 
  let valid = call_611924.validator(path, query, header, formData, body)
  let scheme = call_611924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611924.url(scheme.get, call_611924.host, call_611924.base,
                         call_611924.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611924, url, valid)

proc call*(call_611925: Call_GetClassifiers_611910; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getClassifiers
  ## Lists all classifier objects in the Data Catalog.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611926 = newJObject()
  var body_611927 = newJObject()
  add(query_611926, "MaxResults", newJString(MaxResults))
  add(query_611926, "NextToken", newJString(NextToken))
  if body != nil:
    body_611927 = body
  result = call_611925.call(nil, query_611926, nil, nil, body_611927)

var getClassifiers* = Call_GetClassifiers_611910(name: "getClassifiers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetClassifiers",
    validator: validate_GetClassifiers_611911, base: "/", url: url_GetClassifiers_611912,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnection_611929 = ref object of OpenApiRestCall_610658
proc url_GetConnection_611931(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConnection_611930(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a connection definition from the Data Catalog.
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
  var valid_611932 = header.getOrDefault("X-Amz-Target")
  valid_611932 = validateParameter(valid_611932, JString, required = true,
                                 default = newJString("AWSGlue.GetConnection"))
  if valid_611932 != nil:
    section.add "X-Amz-Target", valid_611932
  var valid_611933 = header.getOrDefault("X-Amz-Signature")
  valid_611933 = validateParameter(valid_611933, JString, required = false,
                                 default = nil)
  if valid_611933 != nil:
    section.add "X-Amz-Signature", valid_611933
  var valid_611934 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611934 = validateParameter(valid_611934, JString, required = false,
                                 default = nil)
  if valid_611934 != nil:
    section.add "X-Amz-Content-Sha256", valid_611934
  var valid_611935 = header.getOrDefault("X-Amz-Date")
  valid_611935 = validateParameter(valid_611935, JString, required = false,
                                 default = nil)
  if valid_611935 != nil:
    section.add "X-Amz-Date", valid_611935
  var valid_611936 = header.getOrDefault("X-Amz-Credential")
  valid_611936 = validateParameter(valid_611936, JString, required = false,
                                 default = nil)
  if valid_611936 != nil:
    section.add "X-Amz-Credential", valid_611936
  var valid_611937 = header.getOrDefault("X-Amz-Security-Token")
  valid_611937 = validateParameter(valid_611937, JString, required = false,
                                 default = nil)
  if valid_611937 != nil:
    section.add "X-Amz-Security-Token", valid_611937
  var valid_611938 = header.getOrDefault("X-Amz-Algorithm")
  valid_611938 = validateParameter(valid_611938, JString, required = false,
                                 default = nil)
  if valid_611938 != nil:
    section.add "X-Amz-Algorithm", valid_611938
  var valid_611939 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611939 = validateParameter(valid_611939, JString, required = false,
                                 default = nil)
  if valid_611939 != nil:
    section.add "X-Amz-SignedHeaders", valid_611939
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611941: Call_GetConnection_611929; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a connection definition from the Data Catalog.
  ## 
  let valid = call_611941.validator(path, query, header, formData, body)
  let scheme = call_611941.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611941.url(scheme.get, call_611941.host, call_611941.base,
                         call_611941.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611941, url, valid)

proc call*(call_611942: Call_GetConnection_611929; body: JsonNode): Recallable =
  ## getConnection
  ## Retrieves a connection definition from the Data Catalog.
  ##   body: JObject (required)
  var body_611943 = newJObject()
  if body != nil:
    body_611943 = body
  result = call_611942.call(nil, nil, nil, nil, body_611943)

var getConnection* = Call_GetConnection_611929(name: "getConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetConnection",
    validator: validate_GetConnection_611930, base: "/", url: url_GetConnection_611931,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnections_611944 = ref object of OpenApiRestCall_610658
proc url_GetConnections_611946(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConnections_611945(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves a list of connection definitions from the Data Catalog.
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
  var valid_611947 = query.getOrDefault("MaxResults")
  valid_611947 = validateParameter(valid_611947, JString, required = false,
                                 default = nil)
  if valid_611947 != nil:
    section.add "MaxResults", valid_611947
  var valid_611948 = query.getOrDefault("NextToken")
  valid_611948 = validateParameter(valid_611948, JString, required = false,
                                 default = nil)
  if valid_611948 != nil:
    section.add "NextToken", valid_611948
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
  var valid_611949 = header.getOrDefault("X-Amz-Target")
  valid_611949 = validateParameter(valid_611949, JString, required = true,
                                 default = newJString("AWSGlue.GetConnections"))
  if valid_611949 != nil:
    section.add "X-Amz-Target", valid_611949
  var valid_611950 = header.getOrDefault("X-Amz-Signature")
  valid_611950 = validateParameter(valid_611950, JString, required = false,
                                 default = nil)
  if valid_611950 != nil:
    section.add "X-Amz-Signature", valid_611950
  var valid_611951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611951 = validateParameter(valid_611951, JString, required = false,
                                 default = nil)
  if valid_611951 != nil:
    section.add "X-Amz-Content-Sha256", valid_611951
  var valid_611952 = header.getOrDefault("X-Amz-Date")
  valid_611952 = validateParameter(valid_611952, JString, required = false,
                                 default = nil)
  if valid_611952 != nil:
    section.add "X-Amz-Date", valid_611952
  var valid_611953 = header.getOrDefault("X-Amz-Credential")
  valid_611953 = validateParameter(valid_611953, JString, required = false,
                                 default = nil)
  if valid_611953 != nil:
    section.add "X-Amz-Credential", valid_611953
  var valid_611954 = header.getOrDefault("X-Amz-Security-Token")
  valid_611954 = validateParameter(valid_611954, JString, required = false,
                                 default = nil)
  if valid_611954 != nil:
    section.add "X-Amz-Security-Token", valid_611954
  var valid_611955 = header.getOrDefault("X-Amz-Algorithm")
  valid_611955 = validateParameter(valid_611955, JString, required = false,
                                 default = nil)
  if valid_611955 != nil:
    section.add "X-Amz-Algorithm", valid_611955
  var valid_611956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611956 = validateParameter(valid_611956, JString, required = false,
                                 default = nil)
  if valid_611956 != nil:
    section.add "X-Amz-SignedHeaders", valid_611956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611958: Call_GetConnections_611944; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of connection definitions from the Data Catalog.
  ## 
  let valid = call_611958.validator(path, query, header, formData, body)
  let scheme = call_611958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611958.url(scheme.get, call_611958.host, call_611958.base,
                         call_611958.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611958, url, valid)

proc call*(call_611959: Call_GetConnections_611944; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getConnections
  ## Retrieves a list of connection definitions from the Data Catalog.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611960 = newJObject()
  var body_611961 = newJObject()
  add(query_611960, "MaxResults", newJString(MaxResults))
  add(query_611960, "NextToken", newJString(NextToken))
  if body != nil:
    body_611961 = body
  result = call_611959.call(nil, query_611960, nil, nil, body_611961)

var getConnections* = Call_GetConnections_611944(name: "getConnections",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetConnections",
    validator: validate_GetConnections_611945, base: "/", url: url_GetConnections_611946,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawler_611962 = ref object of OpenApiRestCall_610658
proc url_GetCrawler_611964(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCrawler_611963(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves metadata for a specified crawler.
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
  var valid_611965 = header.getOrDefault("X-Amz-Target")
  valid_611965 = validateParameter(valid_611965, JString, required = true,
                                 default = newJString("AWSGlue.GetCrawler"))
  if valid_611965 != nil:
    section.add "X-Amz-Target", valid_611965
  var valid_611966 = header.getOrDefault("X-Amz-Signature")
  valid_611966 = validateParameter(valid_611966, JString, required = false,
                                 default = nil)
  if valid_611966 != nil:
    section.add "X-Amz-Signature", valid_611966
  var valid_611967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611967 = validateParameter(valid_611967, JString, required = false,
                                 default = nil)
  if valid_611967 != nil:
    section.add "X-Amz-Content-Sha256", valid_611967
  var valid_611968 = header.getOrDefault("X-Amz-Date")
  valid_611968 = validateParameter(valid_611968, JString, required = false,
                                 default = nil)
  if valid_611968 != nil:
    section.add "X-Amz-Date", valid_611968
  var valid_611969 = header.getOrDefault("X-Amz-Credential")
  valid_611969 = validateParameter(valid_611969, JString, required = false,
                                 default = nil)
  if valid_611969 != nil:
    section.add "X-Amz-Credential", valid_611969
  var valid_611970 = header.getOrDefault("X-Amz-Security-Token")
  valid_611970 = validateParameter(valid_611970, JString, required = false,
                                 default = nil)
  if valid_611970 != nil:
    section.add "X-Amz-Security-Token", valid_611970
  var valid_611971 = header.getOrDefault("X-Amz-Algorithm")
  valid_611971 = validateParameter(valid_611971, JString, required = false,
                                 default = nil)
  if valid_611971 != nil:
    section.add "X-Amz-Algorithm", valid_611971
  var valid_611972 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611972 = validateParameter(valid_611972, JString, required = false,
                                 default = nil)
  if valid_611972 != nil:
    section.add "X-Amz-SignedHeaders", valid_611972
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611974: Call_GetCrawler_611962; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for a specified crawler.
  ## 
  let valid = call_611974.validator(path, query, header, formData, body)
  let scheme = call_611974.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611974.url(scheme.get, call_611974.host, call_611974.base,
                         call_611974.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611974, url, valid)

proc call*(call_611975: Call_GetCrawler_611962; body: JsonNode): Recallable =
  ## getCrawler
  ## Retrieves metadata for a specified crawler.
  ##   body: JObject (required)
  var body_611976 = newJObject()
  if body != nil:
    body_611976 = body
  result = call_611975.call(nil, nil, nil, nil, body_611976)

var getCrawler* = Call_GetCrawler_611962(name: "getCrawler",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetCrawler",
                                      validator: validate_GetCrawler_611963,
                                      base: "/", url: url_GetCrawler_611964,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawlerMetrics_611977 = ref object of OpenApiRestCall_610658
proc url_GetCrawlerMetrics_611979(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCrawlerMetrics_611978(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves metrics about specified crawlers.
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
  var valid_611980 = query.getOrDefault("MaxResults")
  valid_611980 = validateParameter(valid_611980, JString, required = false,
                                 default = nil)
  if valid_611980 != nil:
    section.add "MaxResults", valid_611980
  var valid_611981 = query.getOrDefault("NextToken")
  valid_611981 = validateParameter(valid_611981, JString, required = false,
                                 default = nil)
  if valid_611981 != nil:
    section.add "NextToken", valid_611981
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
  var valid_611982 = header.getOrDefault("X-Amz-Target")
  valid_611982 = validateParameter(valid_611982, JString, required = true, default = newJString(
      "AWSGlue.GetCrawlerMetrics"))
  if valid_611982 != nil:
    section.add "X-Amz-Target", valid_611982
  var valid_611983 = header.getOrDefault("X-Amz-Signature")
  valid_611983 = validateParameter(valid_611983, JString, required = false,
                                 default = nil)
  if valid_611983 != nil:
    section.add "X-Amz-Signature", valid_611983
  var valid_611984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611984 = validateParameter(valid_611984, JString, required = false,
                                 default = nil)
  if valid_611984 != nil:
    section.add "X-Amz-Content-Sha256", valid_611984
  var valid_611985 = header.getOrDefault("X-Amz-Date")
  valid_611985 = validateParameter(valid_611985, JString, required = false,
                                 default = nil)
  if valid_611985 != nil:
    section.add "X-Amz-Date", valid_611985
  var valid_611986 = header.getOrDefault("X-Amz-Credential")
  valid_611986 = validateParameter(valid_611986, JString, required = false,
                                 default = nil)
  if valid_611986 != nil:
    section.add "X-Amz-Credential", valid_611986
  var valid_611987 = header.getOrDefault("X-Amz-Security-Token")
  valid_611987 = validateParameter(valid_611987, JString, required = false,
                                 default = nil)
  if valid_611987 != nil:
    section.add "X-Amz-Security-Token", valid_611987
  var valid_611988 = header.getOrDefault("X-Amz-Algorithm")
  valid_611988 = validateParameter(valid_611988, JString, required = false,
                                 default = nil)
  if valid_611988 != nil:
    section.add "X-Amz-Algorithm", valid_611988
  var valid_611989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611989 = validateParameter(valid_611989, JString, required = false,
                                 default = nil)
  if valid_611989 != nil:
    section.add "X-Amz-SignedHeaders", valid_611989
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611991: Call_GetCrawlerMetrics_611977; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metrics about specified crawlers.
  ## 
  let valid = call_611991.validator(path, query, header, formData, body)
  let scheme = call_611991.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611991.url(scheme.get, call_611991.host, call_611991.base,
                         call_611991.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611991, url, valid)

proc call*(call_611992: Call_GetCrawlerMetrics_611977; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getCrawlerMetrics
  ## Retrieves metrics about specified crawlers.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611993 = newJObject()
  var body_611994 = newJObject()
  add(query_611993, "MaxResults", newJString(MaxResults))
  add(query_611993, "NextToken", newJString(NextToken))
  if body != nil:
    body_611994 = body
  result = call_611992.call(nil, query_611993, nil, nil, body_611994)

var getCrawlerMetrics* = Call_GetCrawlerMetrics_611977(name: "getCrawlerMetrics",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetCrawlerMetrics",
    validator: validate_GetCrawlerMetrics_611978, base: "/",
    url: url_GetCrawlerMetrics_611979, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawlers_611995 = ref object of OpenApiRestCall_610658
proc url_GetCrawlers_611997(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCrawlers_611996(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves metadata for all crawlers defined in the customer account.
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
  var valid_611998 = query.getOrDefault("MaxResults")
  valid_611998 = validateParameter(valid_611998, JString, required = false,
                                 default = nil)
  if valid_611998 != nil:
    section.add "MaxResults", valid_611998
  var valid_611999 = query.getOrDefault("NextToken")
  valid_611999 = validateParameter(valid_611999, JString, required = false,
                                 default = nil)
  if valid_611999 != nil:
    section.add "NextToken", valid_611999
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
  var valid_612000 = header.getOrDefault("X-Amz-Target")
  valid_612000 = validateParameter(valid_612000, JString, required = true,
                                 default = newJString("AWSGlue.GetCrawlers"))
  if valid_612000 != nil:
    section.add "X-Amz-Target", valid_612000
  var valid_612001 = header.getOrDefault("X-Amz-Signature")
  valid_612001 = validateParameter(valid_612001, JString, required = false,
                                 default = nil)
  if valid_612001 != nil:
    section.add "X-Amz-Signature", valid_612001
  var valid_612002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612002 = validateParameter(valid_612002, JString, required = false,
                                 default = nil)
  if valid_612002 != nil:
    section.add "X-Amz-Content-Sha256", valid_612002
  var valid_612003 = header.getOrDefault("X-Amz-Date")
  valid_612003 = validateParameter(valid_612003, JString, required = false,
                                 default = nil)
  if valid_612003 != nil:
    section.add "X-Amz-Date", valid_612003
  var valid_612004 = header.getOrDefault("X-Amz-Credential")
  valid_612004 = validateParameter(valid_612004, JString, required = false,
                                 default = nil)
  if valid_612004 != nil:
    section.add "X-Amz-Credential", valid_612004
  var valid_612005 = header.getOrDefault("X-Amz-Security-Token")
  valid_612005 = validateParameter(valid_612005, JString, required = false,
                                 default = nil)
  if valid_612005 != nil:
    section.add "X-Amz-Security-Token", valid_612005
  var valid_612006 = header.getOrDefault("X-Amz-Algorithm")
  valid_612006 = validateParameter(valid_612006, JString, required = false,
                                 default = nil)
  if valid_612006 != nil:
    section.add "X-Amz-Algorithm", valid_612006
  var valid_612007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612007 = validateParameter(valid_612007, JString, required = false,
                                 default = nil)
  if valid_612007 != nil:
    section.add "X-Amz-SignedHeaders", valid_612007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612009: Call_GetCrawlers_611995; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all crawlers defined in the customer account.
  ## 
  let valid = call_612009.validator(path, query, header, formData, body)
  let scheme = call_612009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612009.url(scheme.get, call_612009.host, call_612009.base,
                         call_612009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612009, url, valid)

proc call*(call_612010: Call_GetCrawlers_611995; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getCrawlers
  ## Retrieves metadata for all crawlers defined in the customer account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612011 = newJObject()
  var body_612012 = newJObject()
  add(query_612011, "MaxResults", newJString(MaxResults))
  add(query_612011, "NextToken", newJString(NextToken))
  if body != nil:
    body_612012 = body
  result = call_612010.call(nil, query_612011, nil, nil, body_612012)

var getCrawlers* = Call_GetCrawlers_611995(name: "getCrawlers",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetCrawlers",
                                        validator: validate_GetCrawlers_611996,
                                        base: "/", url: url_GetCrawlers_611997,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataCatalogEncryptionSettings_612013 = ref object of OpenApiRestCall_610658
proc url_GetDataCatalogEncryptionSettings_612015(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDataCatalogEncryptionSettings_612014(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the security configuration for a specified catalog.
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
  var valid_612016 = header.getOrDefault("X-Amz-Target")
  valid_612016 = validateParameter(valid_612016, JString, required = true, default = newJString(
      "AWSGlue.GetDataCatalogEncryptionSettings"))
  if valid_612016 != nil:
    section.add "X-Amz-Target", valid_612016
  var valid_612017 = header.getOrDefault("X-Amz-Signature")
  valid_612017 = validateParameter(valid_612017, JString, required = false,
                                 default = nil)
  if valid_612017 != nil:
    section.add "X-Amz-Signature", valid_612017
  var valid_612018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612018 = validateParameter(valid_612018, JString, required = false,
                                 default = nil)
  if valid_612018 != nil:
    section.add "X-Amz-Content-Sha256", valid_612018
  var valid_612019 = header.getOrDefault("X-Amz-Date")
  valid_612019 = validateParameter(valid_612019, JString, required = false,
                                 default = nil)
  if valid_612019 != nil:
    section.add "X-Amz-Date", valid_612019
  var valid_612020 = header.getOrDefault("X-Amz-Credential")
  valid_612020 = validateParameter(valid_612020, JString, required = false,
                                 default = nil)
  if valid_612020 != nil:
    section.add "X-Amz-Credential", valid_612020
  var valid_612021 = header.getOrDefault("X-Amz-Security-Token")
  valid_612021 = validateParameter(valid_612021, JString, required = false,
                                 default = nil)
  if valid_612021 != nil:
    section.add "X-Amz-Security-Token", valid_612021
  var valid_612022 = header.getOrDefault("X-Amz-Algorithm")
  valid_612022 = validateParameter(valid_612022, JString, required = false,
                                 default = nil)
  if valid_612022 != nil:
    section.add "X-Amz-Algorithm", valid_612022
  var valid_612023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612023 = validateParameter(valid_612023, JString, required = false,
                                 default = nil)
  if valid_612023 != nil:
    section.add "X-Amz-SignedHeaders", valid_612023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612025: Call_GetDataCatalogEncryptionSettings_612013;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the security configuration for a specified catalog.
  ## 
  let valid = call_612025.validator(path, query, header, formData, body)
  let scheme = call_612025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612025.url(scheme.get, call_612025.host, call_612025.base,
                         call_612025.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612025, url, valid)

proc call*(call_612026: Call_GetDataCatalogEncryptionSettings_612013;
          body: JsonNode): Recallable =
  ## getDataCatalogEncryptionSettings
  ## Retrieves the security configuration for a specified catalog.
  ##   body: JObject (required)
  var body_612027 = newJObject()
  if body != nil:
    body_612027 = body
  result = call_612026.call(nil, nil, nil, nil, body_612027)

var getDataCatalogEncryptionSettings* = Call_GetDataCatalogEncryptionSettings_612013(
    name: "getDataCatalogEncryptionSettings", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDataCatalogEncryptionSettings",
    validator: validate_GetDataCatalogEncryptionSettings_612014, base: "/",
    url: url_GetDataCatalogEncryptionSettings_612015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatabase_612028 = ref object of OpenApiRestCall_610658
proc url_GetDatabase_612030(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDatabase_612029(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the definition of a specified database.
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
  var valid_612031 = header.getOrDefault("X-Amz-Target")
  valid_612031 = validateParameter(valid_612031, JString, required = true,
                                 default = newJString("AWSGlue.GetDatabase"))
  if valid_612031 != nil:
    section.add "X-Amz-Target", valid_612031
  var valid_612032 = header.getOrDefault("X-Amz-Signature")
  valid_612032 = validateParameter(valid_612032, JString, required = false,
                                 default = nil)
  if valid_612032 != nil:
    section.add "X-Amz-Signature", valid_612032
  var valid_612033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612033 = validateParameter(valid_612033, JString, required = false,
                                 default = nil)
  if valid_612033 != nil:
    section.add "X-Amz-Content-Sha256", valid_612033
  var valid_612034 = header.getOrDefault("X-Amz-Date")
  valid_612034 = validateParameter(valid_612034, JString, required = false,
                                 default = nil)
  if valid_612034 != nil:
    section.add "X-Amz-Date", valid_612034
  var valid_612035 = header.getOrDefault("X-Amz-Credential")
  valid_612035 = validateParameter(valid_612035, JString, required = false,
                                 default = nil)
  if valid_612035 != nil:
    section.add "X-Amz-Credential", valid_612035
  var valid_612036 = header.getOrDefault("X-Amz-Security-Token")
  valid_612036 = validateParameter(valid_612036, JString, required = false,
                                 default = nil)
  if valid_612036 != nil:
    section.add "X-Amz-Security-Token", valid_612036
  var valid_612037 = header.getOrDefault("X-Amz-Algorithm")
  valid_612037 = validateParameter(valid_612037, JString, required = false,
                                 default = nil)
  if valid_612037 != nil:
    section.add "X-Amz-Algorithm", valid_612037
  var valid_612038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612038 = validateParameter(valid_612038, JString, required = false,
                                 default = nil)
  if valid_612038 != nil:
    section.add "X-Amz-SignedHeaders", valid_612038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612040: Call_GetDatabase_612028; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definition of a specified database.
  ## 
  let valid = call_612040.validator(path, query, header, formData, body)
  let scheme = call_612040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612040.url(scheme.get, call_612040.host, call_612040.base,
                         call_612040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612040, url, valid)

proc call*(call_612041: Call_GetDatabase_612028; body: JsonNode): Recallable =
  ## getDatabase
  ## Retrieves the definition of a specified database.
  ##   body: JObject (required)
  var body_612042 = newJObject()
  if body != nil:
    body_612042 = body
  result = call_612041.call(nil, nil, nil, nil, body_612042)

var getDatabase* = Call_GetDatabase_612028(name: "getDatabase",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetDatabase",
                                        validator: validate_GetDatabase_612029,
                                        base: "/", url: url_GetDatabase_612030,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatabases_612043 = ref object of OpenApiRestCall_610658
proc url_GetDatabases_612045(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDatabases_612044(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves all databases defined in a given Data Catalog.
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
  var valid_612046 = query.getOrDefault("MaxResults")
  valid_612046 = validateParameter(valid_612046, JString, required = false,
                                 default = nil)
  if valid_612046 != nil:
    section.add "MaxResults", valid_612046
  var valid_612047 = query.getOrDefault("NextToken")
  valid_612047 = validateParameter(valid_612047, JString, required = false,
                                 default = nil)
  if valid_612047 != nil:
    section.add "NextToken", valid_612047
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
  var valid_612048 = header.getOrDefault("X-Amz-Target")
  valid_612048 = validateParameter(valid_612048, JString, required = true,
                                 default = newJString("AWSGlue.GetDatabases"))
  if valid_612048 != nil:
    section.add "X-Amz-Target", valid_612048
  var valid_612049 = header.getOrDefault("X-Amz-Signature")
  valid_612049 = validateParameter(valid_612049, JString, required = false,
                                 default = nil)
  if valid_612049 != nil:
    section.add "X-Amz-Signature", valid_612049
  var valid_612050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612050 = validateParameter(valid_612050, JString, required = false,
                                 default = nil)
  if valid_612050 != nil:
    section.add "X-Amz-Content-Sha256", valid_612050
  var valid_612051 = header.getOrDefault("X-Amz-Date")
  valid_612051 = validateParameter(valid_612051, JString, required = false,
                                 default = nil)
  if valid_612051 != nil:
    section.add "X-Amz-Date", valid_612051
  var valid_612052 = header.getOrDefault("X-Amz-Credential")
  valid_612052 = validateParameter(valid_612052, JString, required = false,
                                 default = nil)
  if valid_612052 != nil:
    section.add "X-Amz-Credential", valid_612052
  var valid_612053 = header.getOrDefault("X-Amz-Security-Token")
  valid_612053 = validateParameter(valid_612053, JString, required = false,
                                 default = nil)
  if valid_612053 != nil:
    section.add "X-Amz-Security-Token", valid_612053
  var valid_612054 = header.getOrDefault("X-Amz-Algorithm")
  valid_612054 = validateParameter(valid_612054, JString, required = false,
                                 default = nil)
  if valid_612054 != nil:
    section.add "X-Amz-Algorithm", valid_612054
  var valid_612055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612055 = validateParameter(valid_612055, JString, required = false,
                                 default = nil)
  if valid_612055 != nil:
    section.add "X-Amz-SignedHeaders", valid_612055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612057: Call_GetDatabases_612043; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all databases defined in a given Data Catalog.
  ## 
  let valid = call_612057.validator(path, query, header, formData, body)
  let scheme = call_612057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612057.url(scheme.get, call_612057.host, call_612057.base,
                         call_612057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612057, url, valid)

proc call*(call_612058: Call_GetDatabases_612043; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getDatabases
  ## Retrieves all databases defined in a given Data Catalog.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612059 = newJObject()
  var body_612060 = newJObject()
  add(query_612059, "MaxResults", newJString(MaxResults))
  add(query_612059, "NextToken", newJString(NextToken))
  if body != nil:
    body_612060 = body
  result = call_612058.call(nil, query_612059, nil, nil, body_612060)

var getDatabases* = Call_GetDatabases_612043(name: "getDatabases",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDatabases",
    validator: validate_GetDatabases_612044, base: "/", url: url_GetDatabases_612045,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataflowGraph_612061 = ref object of OpenApiRestCall_610658
proc url_GetDataflowGraph_612063(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDataflowGraph_612062(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Transforms a Python script into a directed acyclic graph (DAG). 
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
  var valid_612064 = header.getOrDefault("X-Amz-Target")
  valid_612064 = validateParameter(valid_612064, JString, required = true, default = newJString(
      "AWSGlue.GetDataflowGraph"))
  if valid_612064 != nil:
    section.add "X-Amz-Target", valid_612064
  var valid_612065 = header.getOrDefault("X-Amz-Signature")
  valid_612065 = validateParameter(valid_612065, JString, required = false,
                                 default = nil)
  if valid_612065 != nil:
    section.add "X-Amz-Signature", valid_612065
  var valid_612066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612066 = validateParameter(valid_612066, JString, required = false,
                                 default = nil)
  if valid_612066 != nil:
    section.add "X-Amz-Content-Sha256", valid_612066
  var valid_612067 = header.getOrDefault("X-Amz-Date")
  valid_612067 = validateParameter(valid_612067, JString, required = false,
                                 default = nil)
  if valid_612067 != nil:
    section.add "X-Amz-Date", valid_612067
  var valid_612068 = header.getOrDefault("X-Amz-Credential")
  valid_612068 = validateParameter(valid_612068, JString, required = false,
                                 default = nil)
  if valid_612068 != nil:
    section.add "X-Amz-Credential", valid_612068
  var valid_612069 = header.getOrDefault("X-Amz-Security-Token")
  valid_612069 = validateParameter(valid_612069, JString, required = false,
                                 default = nil)
  if valid_612069 != nil:
    section.add "X-Amz-Security-Token", valid_612069
  var valid_612070 = header.getOrDefault("X-Amz-Algorithm")
  valid_612070 = validateParameter(valid_612070, JString, required = false,
                                 default = nil)
  if valid_612070 != nil:
    section.add "X-Amz-Algorithm", valid_612070
  var valid_612071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612071 = validateParameter(valid_612071, JString, required = false,
                                 default = nil)
  if valid_612071 != nil:
    section.add "X-Amz-SignedHeaders", valid_612071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612073: Call_GetDataflowGraph_612061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Transforms a Python script into a directed acyclic graph (DAG). 
  ## 
  let valid = call_612073.validator(path, query, header, formData, body)
  let scheme = call_612073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612073.url(scheme.get, call_612073.host, call_612073.base,
                         call_612073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612073, url, valid)

proc call*(call_612074: Call_GetDataflowGraph_612061; body: JsonNode): Recallable =
  ## getDataflowGraph
  ## Transforms a Python script into a directed acyclic graph (DAG). 
  ##   body: JObject (required)
  var body_612075 = newJObject()
  if body != nil:
    body_612075 = body
  result = call_612074.call(nil, nil, nil, nil, body_612075)

var getDataflowGraph* = Call_GetDataflowGraph_612061(name: "getDataflowGraph",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDataflowGraph",
    validator: validate_GetDataflowGraph_612062, base: "/",
    url: url_GetDataflowGraph_612063, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevEndpoint_612076 = ref object of OpenApiRestCall_610658
proc url_GetDevEndpoint_612078(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevEndpoint_612077(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
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
  var valid_612079 = header.getOrDefault("X-Amz-Target")
  valid_612079 = validateParameter(valid_612079, JString, required = true,
                                 default = newJString("AWSGlue.GetDevEndpoint"))
  if valid_612079 != nil:
    section.add "X-Amz-Target", valid_612079
  var valid_612080 = header.getOrDefault("X-Amz-Signature")
  valid_612080 = validateParameter(valid_612080, JString, required = false,
                                 default = nil)
  if valid_612080 != nil:
    section.add "X-Amz-Signature", valid_612080
  var valid_612081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612081 = validateParameter(valid_612081, JString, required = false,
                                 default = nil)
  if valid_612081 != nil:
    section.add "X-Amz-Content-Sha256", valid_612081
  var valid_612082 = header.getOrDefault("X-Amz-Date")
  valid_612082 = validateParameter(valid_612082, JString, required = false,
                                 default = nil)
  if valid_612082 != nil:
    section.add "X-Amz-Date", valid_612082
  var valid_612083 = header.getOrDefault("X-Amz-Credential")
  valid_612083 = validateParameter(valid_612083, JString, required = false,
                                 default = nil)
  if valid_612083 != nil:
    section.add "X-Amz-Credential", valid_612083
  var valid_612084 = header.getOrDefault("X-Amz-Security-Token")
  valid_612084 = validateParameter(valid_612084, JString, required = false,
                                 default = nil)
  if valid_612084 != nil:
    section.add "X-Amz-Security-Token", valid_612084
  var valid_612085 = header.getOrDefault("X-Amz-Algorithm")
  valid_612085 = validateParameter(valid_612085, JString, required = false,
                                 default = nil)
  if valid_612085 != nil:
    section.add "X-Amz-Algorithm", valid_612085
  var valid_612086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612086 = validateParameter(valid_612086, JString, required = false,
                                 default = nil)
  if valid_612086 != nil:
    section.add "X-Amz-SignedHeaders", valid_612086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612088: Call_GetDevEndpoint_612076; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ## 
  let valid = call_612088.validator(path, query, header, formData, body)
  let scheme = call_612088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612088.url(scheme.get, call_612088.host, call_612088.base,
                         call_612088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612088, url, valid)

proc call*(call_612089: Call_GetDevEndpoint_612076; body: JsonNode): Recallable =
  ## getDevEndpoint
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ##   body: JObject (required)
  var body_612090 = newJObject()
  if body != nil:
    body_612090 = body
  result = call_612089.call(nil, nil, nil, nil, body_612090)

var getDevEndpoint* = Call_GetDevEndpoint_612076(name: "getDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDevEndpoint",
    validator: validate_GetDevEndpoint_612077, base: "/", url: url_GetDevEndpoint_612078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevEndpoints_612091 = ref object of OpenApiRestCall_610658
proc url_GetDevEndpoints_612093(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevEndpoints_612092(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
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
  var valid_612094 = query.getOrDefault("MaxResults")
  valid_612094 = validateParameter(valid_612094, JString, required = false,
                                 default = nil)
  if valid_612094 != nil:
    section.add "MaxResults", valid_612094
  var valid_612095 = query.getOrDefault("NextToken")
  valid_612095 = validateParameter(valid_612095, JString, required = false,
                                 default = nil)
  if valid_612095 != nil:
    section.add "NextToken", valid_612095
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
  var valid_612096 = header.getOrDefault("X-Amz-Target")
  valid_612096 = validateParameter(valid_612096, JString, required = true, default = newJString(
      "AWSGlue.GetDevEndpoints"))
  if valid_612096 != nil:
    section.add "X-Amz-Target", valid_612096
  var valid_612097 = header.getOrDefault("X-Amz-Signature")
  valid_612097 = validateParameter(valid_612097, JString, required = false,
                                 default = nil)
  if valid_612097 != nil:
    section.add "X-Amz-Signature", valid_612097
  var valid_612098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612098 = validateParameter(valid_612098, JString, required = false,
                                 default = nil)
  if valid_612098 != nil:
    section.add "X-Amz-Content-Sha256", valid_612098
  var valid_612099 = header.getOrDefault("X-Amz-Date")
  valid_612099 = validateParameter(valid_612099, JString, required = false,
                                 default = nil)
  if valid_612099 != nil:
    section.add "X-Amz-Date", valid_612099
  var valid_612100 = header.getOrDefault("X-Amz-Credential")
  valid_612100 = validateParameter(valid_612100, JString, required = false,
                                 default = nil)
  if valid_612100 != nil:
    section.add "X-Amz-Credential", valid_612100
  var valid_612101 = header.getOrDefault("X-Amz-Security-Token")
  valid_612101 = validateParameter(valid_612101, JString, required = false,
                                 default = nil)
  if valid_612101 != nil:
    section.add "X-Amz-Security-Token", valid_612101
  var valid_612102 = header.getOrDefault("X-Amz-Algorithm")
  valid_612102 = validateParameter(valid_612102, JString, required = false,
                                 default = nil)
  if valid_612102 != nil:
    section.add "X-Amz-Algorithm", valid_612102
  var valid_612103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612103 = validateParameter(valid_612103, JString, required = false,
                                 default = nil)
  if valid_612103 != nil:
    section.add "X-Amz-SignedHeaders", valid_612103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612105: Call_GetDevEndpoints_612091; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ## 
  let valid = call_612105.validator(path, query, header, formData, body)
  let scheme = call_612105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612105.url(scheme.get, call_612105.host, call_612105.base,
                         call_612105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612105, url, valid)

proc call*(call_612106: Call_GetDevEndpoints_612091; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getDevEndpoints
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612107 = newJObject()
  var body_612108 = newJObject()
  add(query_612107, "MaxResults", newJString(MaxResults))
  add(query_612107, "NextToken", newJString(NextToken))
  if body != nil:
    body_612108 = body
  result = call_612106.call(nil, query_612107, nil, nil, body_612108)

var getDevEndpoints* = Call_GetDevEndpoints_612091(name: "getDevEndpoints",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDevEndpoints",
    validator: validate_GetDevEndpoints_612092, base: "/", url: url_GetDevEndpoints_612093,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_612109 = ref object of OpenApiRestCall_610658
proc url_GetJob_612111(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetJob_612110(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves an existing job definition.
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
  var valid_612112 = header.getOrDefault("X-Amz-Target")
  valid_612112 = validateParameter(valid_612112, JString, required = true,
                                 default = newJString("AWSGlue.GetJob"))
  if valid_612112 != nil:
    section.add "X-Amz-Target", valid_612112
  var valid_612113 = header.getOrDefault("X-Amz-Signature")
  valid_612113 = validateParameter(valid_612113, JString, required = false,
                                 default = nil)
  if valid_612113 != nil:
    section.add "X-Amz-Signature", valid_612113
  var valid_612114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612114 = validateParameter(valid_612114, JString, required = false,
                                 default = nil)
  if valid_612114 != nil:
    section.add "X-Amz-Content-Sha256", valid_612114
  var valid_612115 = header.getOrDefault("X-Amz-Date")
  valid_612115 = validateParameter(valid_612115, JString, required = false,
                                 default = nil)
  if valid_612115 != nil:
    section.add "X-Amz-Date", valid_612115
  var valid_612116 = header.getOrDefault("X-Amz-Credential")
  valid_612116 = validateParameter(valid_612116, JString, required = false,
                                 default = nil)
  if valid_612116 != nil:
    section.add "X-Amz-Credential", valid_612116
  var valid_612117 = header.getOrDefault("X-Amz-Security-Token")
  valid_612117 = validateParameter(valid_612117, JString, required = false,
                                 default = nil)
  if valid_612117 != nil:
    section.add "X-Amz-Security-Token", valid_612117
  var valid_612118 = header.getOrDefault("X-Amz-Algorithm")
  valid_612118 = validateParameter(valid_612118, JString, required = false,
                                 default = nil)
  if valid_612118 != nil:
    section.add "X-Amz-Algorithm", valid_612118
  var valid_612119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612119 = validateParameter(valid_612119, JString, required = false,
                                 default = nil)
  if valid_612119 != nil:
    section.add "X-Amz-SignedHeaders", valid_612119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612121: Call_GetJob_612109; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an existing job definition.
  ## 
  let valid = call_612121.validator(path, query, header, formData, body)
  let scheme = call_612121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612121.url(scheme.get, call_612121.host, call_612121.base,
                         call_612121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612121, url, valid)

proc call*(call_612122: Call_GetJob_612109; body: JsonNode): Recallable =
  ## getJob
  ## Retrieves an existing job definition.
  ##   body: JObject (required)
  var body_612123 = newJObject()
  if body != nil:
    body_612123 = body
  result = call_612122.call(nil, nil, nil, nil, body_612123)

var getJob* = Call_GetJob_612109(name: "getJob", meth: HttpMethod.HttpPost,
                              host: "glue.amazonaws.com",
                              route: "/#X-Amz-Target=AWSGlue.GetJob",
                              validator: validate_GetJob_612110, base: "/",
                              url: url_GetJob_612111,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobBookmark_612124 = ref object of OpenApiRestCall_610658
proc url_GetJobBookmark_612126(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetJobBookmark_612125(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns information on a job bookmark entry.
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
  var valid_612127 = header.getOrDefault("X-Amz-Target")
  valid_612127 = validateParameter(valid_612127, JString, required = true,
                                 default = newJString("AWSGlue.GetJobBookmark"))
  if valid_612127 != nil:
    section.add "X-Amz-Target", valid_612127
  var valid_612128 = header.getOrDefault("X-Amz-Signature")
  valid_612128 = validateParameter(valid_612128, JString, required = false,
                                 default = nil)
  if valid_612128 != nil:
    section.add "X-Amz-Signature", valid_612128
  var valid_612129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612129 = validateParameter(valid_612129, JString, required = false,
                                 default = nil)
  if valid_612129 != nil:
    section.add "X-Amz-Content-Sha256", valid_612129
  var valid_612130 = header.getOrDefault("X-Amz-Date")
  valid_612130 = validateParameter(valid_612130, JString, required = false,
                                 default = nil)
  if valid_612130 != nil:
    section.add "X-Amz-Date", valid_612130
  var valid_612131 = header.getOrDefault("X-Amz-Credential")
  valid_612131 = validateParameter(valid_612131, JString, required = false,
                                 default = nil)
  if valid_612131 != nil:
    section.add "X-Amz-Credential", valid_612131
  var valid_612132 = header.getOrDefault("X-Amz-Security-Token")
  valid_612132 = validateParameter(valid_612132, JString, required = false,
                                 default = nil)
  if valid_612132 != nil:
    section.add "X-Amz-Security-Token", valid_612132
  var valid_612133 = header.getOrDefault("X-Amz-Algorithm")
  valid_612133 = validateParameter(valid_612133, JString, required = false,
                                 default = nil)
  if valid_612133 != nil:
    section.add "X-Amz-Algorithm", valid_612133
  var valid_612134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612134 = validateParameter(valid_612134, JString, required = false,
                                 default = nil)
  if valid_612134 != nil:
    section.add "X-Amz-SignedHeaders", valid_612134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612136: Call_GetJobBookmark_612124; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information on a job bookmark entry.
  ## 
  let valid = call_612136.validator(path, query, header, formData, body)
  let scheme = call_612136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612136.url(scheme.get, call_612136.host, call_612136.base,
                         call_612136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612136, url, valid)

proc call*(call_612137: Call_GetJobBookmark_612124; body: JsonNode): Recallable =
  ## getJobBookmark
  ## Returns information on a job bookmark entry.
  ##   body: JObject (required)
  var body_612138 = newJObject()
  if body != nil:
    body_612138 = body
  result = call_612137.call(nil, nil, nil, nil, body_612138)

var getJobBookmark* = Call_GetJobBookmark_612124(name: "getJobBookmark",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetJobBookmark",
    validator: validate_GetJobBookmark_612125, base: "/", url: url_GetJobBookmark_612126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobRun_612139 = ref object of OpenApiRestCall_610658
proc url_GetJobRun_612141(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetJobRun_612140(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the metadata for a given job run.
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
  var valid_612142 = header.getOrDefault("X-Amz-Target")
  valid_612142 = validateParameter(valid_612142, JString, required = true,
                                 default = newJString("AWSGlue.GetJobRun"))
  if valid_612142 != nil:
    section.add "X-Amz-Target", valid_612142
  var valid_612143 = header.getOrDefault("X-Amz-Signature")
  valid_612143 = validateParameter(valid_612143, JString, required = false,
                                 default = nil)
  if valid_612143 != nil:
    section.add "X-Amz-Signature", valid_612143
  var valid_612144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612144 = validateParameter(valid_612144, JString, required = false,
                                 default = nil)
  if valid_612144 != nil:
    section.add "X-Amz-Content-Sha256", valid_612144
  var valid_612145 = header.getOrDefault("X-Amz-Date")
  valid_612145 = validateParameter(valid_612145, JString, required = false,
                                 default = nil)
  if valid_612145 != nil:
    section.add "X-Amz-Date", valid_612145
  var valid_612146 = header.getOrDefault("X-Amz-Credential")
  valid_612146 = validateParameter(valid_612146, JString, required = false,
                                 default = nil)
  if valid_612146 != nil:
    section.add "X-Amz-Credential", valid_612146
  var valid_612147 = header.getOrDefault("X-Amz-Security-Token")
  valid_612147 = validateParameter(valid_612147, JString, required = false,
                                 default = nil)
  if valid_612147 != nil:
    section.add "X-Amz-Security-Token", valid_612147
  var valid_612148 = header.getOrDefault("X-Amz-Algorithm")
  valid_612148 = validateParameter(valid_612148, JString, required = false,
                                 default = nil)
  if valid_612148 != nil:
    section.add "X-Amz-Algorithm", valid_612148
  var valid_612149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612149 = validateParameter(valid_612149, JString, required = false,
                                 default = nil)
  if valid_612149 != nil:
    section.add "X-Amz-SignedHeaders", valid_612149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612151: Call_GetJobRun_612139; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the metadata for a given job run.
  ## 
  let valid = call_612151.validator(path, query, header, formData, body)
  let scheme = call_612151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612151.url(scheme.get, call_612151.host, call_612151.base,
                         call_612151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612151, url, valid)

proc call*(call_612152: Call_GetJobRun_612139; body: JsonNode): Recallable =
  ## getJobRun
  ## Retrieves the metadata for a given job run.
  ##   body: JObject (required)
  var body_612153 = newJObject()
  if body != nil:
    body_612153 = body
  result = call_612152.call(nil, nil, nil, nil, body_612153)

var getJobRun* = Call_GetJobRun_612139(name: "getJobRun", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.GetJobRun",
                                    validator: validate_GetJobRun_612140,
                                    base: "/", url: url_GetJobRun_612141,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobRuns_612154 = ref object of OpenApiRestCall_610658
proc url_GetJobRuns_612156(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetJobRuns_612155(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves metadata for all runs of a given job definition.
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
  var valid_612157 = query.getOrDefault("MaxResults")
  valid_612157 = validateParameter(valid_612157, JString, required = false,
                                 default = nil)
  if valid_612157 != nil:
    section.add "MaxResults", valid_612157
  var valid_612158 = query.getOrDefault("NextToken")
  valid_612158 = validateParameter(valid_612158, JString, required = false,
                                 default = nil)
  if valid_612158 != nil:
    section.add "NextToken", valid_612158
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
  var valid_612159 = header.getOrDefault("X-Amz-Target")
  valid_612159 = validateParameter(valid_612159, JString, required = true,
                                 default = newJString("AWSGlue.GetJobRuns"))
  if valid_612159 != nil:
    section.add "X-Amz-Target", valid_612159
  var valid_612160 = header.getOrDefault("X-Amz-Signature")
  valid_612160 = validateParameter(valid_612160, JString, required = false,
                                 default = nil)
  if valid_612160 != nil:
    section.add "X-Amz-Signature", valid_612160
  var valid_612161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612161 = validateParameter(valid_612161, JString, required = false,
                                 default = nil)
  if valid_612161 != nil:
    section.add "X-Amz-Content-Sha256", valid_612161
  var valid_612162 = header.getOrDefault("X-Amz-Date")
  valid_612162 = validateParameter(valid_612162, JString, required = false,
                                 default = nil)
  if valid_612162 != nil:
    section.add "X-Amz-Date", valid_612162
  var valid_612163 = header.getOrDefault("X-Amz-Credential")
  valid_612163 = validateParameter(valid_612163, JString, required = false,
                                 default = nil)
  if valid_612163 != nil:
    section.add "X-Amz-Credential", valid_612163
  var valid_612164 = header.getOrDefault("X-Amz-Security-Token")
  valid_612164 = validateParameter(valid_612164, JString, required = false,
                                 default = nil)
  if valid_612164 != nil:
    section.add "X-Amz-Security-Token", valid_612164
  var valid_612165 = header.getOrDefault("X-Amz-Algorithm")
  valid_612165 = validateParameter(valid_612165, JString, required = false,
                                 default = nil)
  if valid_612165 != nil:
    section.add "X-Amz-Algorithm", valid_612165
  var valid_612166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612166 = validateParameter(valid_612166, JString, required = false,
                                 default = nil)
  if valid_612166 != nil:
    section.add "X-Amz-SignedHeaders", valid_612166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612168: Call_GetJobRuns_612154; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all runs of a given job definition.
  ## 
  let valid = call_612168.validator(path, query, header, formData, body)
  let scheme = call_612168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612168.url(scheme.get, call_612168.host, call_612168.base,
                         call_612168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612168, url, valid)

proc call*(call_612169: Call_GetJobRuns_612154; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getJobRuns
  ## Retrieves metadata for all runs of a given job definition.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612170 = newJObject()
  var body_612171 = newJObject()
  add(query_612170, "MaxResults", newJString(MaxResults))
  add(query_612170, "NextToken", newJString(NextToken))
  if body != nil:
    body_612171 = body
  result = call_612169.call(nil, query_612170, nil, nil, body_612171)

var getJobRuns* = Call_GetJobRuns_612154(name: "getJobRuns",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetJobRuns",
                                      validator: validate_GetJobRuns_612155,
                                      base: "/", url: url_GetJobRuns_612156,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobs_612172 = ref object of OpenApiRestCall_610658
proc url_GetJobs_612174(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetJobs_612173(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves all current job definitions.
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
  var valid_612175 = query.getOrDefault("MaxResults")
  valid_612175 = validateParameter(valid_612175, JString, required = false,
                                 default = nil)
  if valid_612175 != nil:
    section.add "MaxResults", valid_612175
  var valid_612176 = query.getOrDefault("NextToken")
  valid_612176 = validateParameter(valid_612176, JString, required = false,
                                 default = nil)
  if valid_612176 != nil:
    section.add "NextToken", valid_612176
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
  var valid_612177 = header.getOrDefault("X-Amz-Target")
  valid_612177 = validateParameter(valid_612177, JString, required = true,
                                 default = newJString("AWSGlue.GetJobs"))
  if valid_612177 != nil:
    section.add "X-Amz-Target", valid_612177
  var valid_612178 = header.getOrDefault("X-Amz-Signature")
  valid_612178 = validateParameter(valid_612178, JString, required = false,
                                 default = nil)
  if valid_612178 != nil:
    section.add "X-Amz-Signature", valid_612178
  var valid_612179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612179 = validateParameter(valid_612179, JString, required = false,
                                 default = nil)
  if valid_612179 != nil:
    section.add "X-Amz-Content-Sha256", valid_612179
  var valid_612180 = header.getOrDefault("X-Amz-Date")
  valid_612180 = validateParameter(valid_612180, JString, required = false,
                                 default = nil)
  if valid_612180 != nil:
    section.add "X-Amz-Date", valid_612180
  var valid_612181 = header.getOrDefault("X-Amz-Credential")
  valid_612181 = validateParameter(valid_612181, JString, required = false,
                                 default = nil)
  if valid_612181 != nil:
    section.add "X-Amz-Credential", valid_612181
  var valid_612182 = header.getOrDefault("X-Amz-Security-Token")
  valid_612182 = validateParameter(valid_612182, JString, required = false,
                                 default = nil)
  if valid_612182 != nil:
    section.add "X-Amz-Security-Token", valid_612182
  var valid_612183 = header.getOrDefault("X-Amz-Algorithm")
  valid_612183 = validateParameter(valid_612183, JString, required = false,
                                 default = nil)
  if valid_612183 != nil:
    section.add "X-Amz-Algorithm", valid_612183
  var valid_612184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612184 = validateParameter(valid_612184, JString, required = false,
                                 default = nil)
  if valid_612184 != nil:
    section.add "X-Amz-SignedHeaders", valid_612184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612186: Call_GetJobs_612172; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all current job definitions.
  ## 
  let valid = call_612186.validator(path, query, header, formData, body)
  let scheme = call_612186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612186.url(scheme.get, call_612186.host, call_612186.base,
                         call_612186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612186, url, valid)

proc call*(call_612187: Call_GetJobs_612172; body: JsonNode; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## getJobs
  ## Retrieves all current job definitions.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612188 = newJObject()
  var body_612189 = newJObject()
  add(query_612188, "MaxResults", newJString(MaxResults))
  add(query_612188, "NextToken", newJString(NextToken))
  if body != nil:
    body_612189 = body
  result = call_612187.call(nil, query_612188, nil, nil, body_612189)

var getJobs* = Call_GetJobs_612172(name: "getJobs", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetJobs",
                                validator: validate_GetJobs_612173, base: "/",
                                url: url_GetJobs_612174,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTaskRun_612190 = ref object of OpenApiRestCall_610658
proc url_GetMLTaskRun_612192(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMLTaskRun_612191(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
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
  var valid_612193 = header.getOrDefault("X-Amz-Target")
  valid_612193 = validateParameter(valid_612193, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTaskRun"))
  if valid_612193 != nil:
    section.add "X-Amz-Target", valid_612193
  var valid_612194 = header.getOrDefault("X-Amz-Signature")
  valid_612194 = validateParameter(valid_612194, JString, required = false,
                                 default = nil)
  if valid_612194 != nil:
    section.add "X-Amz-Signature", valid_612194
  var valid_612195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612195 = validateParameter(valid_612195, JString, required = false,
                                 default = nil)
  if valid_612195 != nil:
    section.add "X-Amz-Content-Sha256", valid_612195
  var valid_612196 = header.getOrDefault("X-Amz-Date")
  valid_612196 = validateParameter(valid_612196, JString, required = false,
                                 default = nil)
  if valid_612196 != nil:
    section.add "X-Amz-Date", valid_612196
  var valid_612197 = header.getOrDefault("X-Amz-Credential")
  valid_612197 = validateParameter(valid_612197, JString, required = false,
                                 default = nil)
  if valid_612197 != nil:
    section.add "X-Amz-Credential", valid_612197
  var valid_612198 = header.getOrDefault("X-Amz-Security-Token")
  valid_612198 = validateParameter(valid_612198, JString, required = false,
                                 default = nil)
  if valid_612198 != nil:
    section.add "X-Amz-Security-Token", valid_612198
  var valid_612199 = header.getOrDefault("X-Amz-Algorithm")
  valid_612199 = validateParameter(valid_612199, JString, required = false,
                                 default = nil)
  if valid_612199 != nil:
    section.add "X-Amz-Algorithm", valid_612199
  var valid_612200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612200 = validateParameter(valid_612200, JString, required = false,
                                 default = nil)
  if valid_612200 != nil:
    section.add "X-Amz-SignedHeaders", valid_612200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612202: Call_GetMLTaskRun_612190; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
  ## 
  let valid = call_612202.validator(path, query, header, formData, body)
  let scheme = call_612202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612202.url(scheme.get, call_612202.host, call_612202.base,
                         call_612202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612202, url, valid)

proc call*(call_612203: Call_GetMLTaskRun_612190; body: JsonNode): Recallable =
  ## getMLTaskRun
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
  ##   body: JObject (required)
  var body_612204 = newJObject()
  if body != nil:
    body_612204 = body
  result = call_612203.call(nil, nil, nil, nil, body_612204)

var getMLTaskRun* = Call_GetMLTaskRun_612190(name: "getMLTaskRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTaskRun",
    validator: validate_GetMLTaskRun_612191, base: "/", url: url_GetMLTaskRun_612192,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTaskRuns_612205 = ref object of OpenApiRestCall_610658
proc url_GetMLTaskRuns_612207(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMLTaskRuns_612206(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
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
  var valid_612208 = query.getOrDefault("MaxResults")
  valid_612208 = validateParameter(valid_612208, JString, required = false,
                                 default = nil)
  if valid_612208 != nil:
    section.add "MaxResults", valid_612208
  var valid_612209 = query.getOrDefault("NextToken")
  valid_612209 = validateParameter(valid_612209, JString, required = false,
                                 default = nil)
  if valid_612209 != nil:
    section.add "NextToken", valid_612209
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
  var valid_612210 = header.getOrDefault("X-Amz-Target")
  valid_612210 = validateParameter(valid_612210, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTaskRuns"))
  if valid_612210 != nil:
    section.add "X-Amz-Target", valid_612210
  var valid_612211 = header.getOrDefault("X-Amz-Signature")
  valid_612211 = validateParameter(valid_612211, JString, required = false,
                                 default = nil)
  if valid_612211 != nil:
    section.add "X-Amz-Signature", valid_612211
  var valid_612212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612212 = validateParameter(valid_612212, JString, required = false,
                                 default = nil)
  if valid_612212 != nil:
    section.add "X-Amz-Content-Sha256", valid_612212
  var valid_612213 = header.getOrDefault("X-Amz-Date")
  valid_612213 = validateParameter(valid_612213, JString, required = false,
                                 default = nil)
  if valid_612213 != nil:
    section.add "X-Amz-Date", valid_612213
  var valid_612214 = header.getOrDefault("X-Amz-Credential")
  valid_612214 = validateParameter(valid_612214, JString, required = false,
                                 default = nil)
  if valid_612214 != nil:
    section.add "X-Amz-Credential", valid_612214
  var valid_612215 = header.getOrDefault("X-Amz-Security-Token")
  valid_612215 = validateParameter(valid_612215, JString, required = false,
                                 default = nil)
  if valid_612215 != nil:
    section.add "X-Amz-Security-Token", valid_612215
  var valid_612216 = header.getOrDefault("X-Amz-Algorithm")
  valid_612216 = validateParameter(valid_612216, JString, required = false,
                                 default = nil)
  if valid_612216 != nil:
    section.add "X-Amz-Algorithm", valid_612216
  var valid_612217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612217 = validateParameter(valid_612217, JString, required = false,
                                 default = nil)
  if valid_612217 != nil:
    section.add "X-Amz-SignedHeaders", valid_612217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612219: Call_GetMLTaskRuns_612205; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
  ## 
  let valid = call_612219.validator(path, query, header, formData, body)
  let scheme = call_612219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612219.url(scheme.get, call_612219.host, call_612219.base,
                         call_612219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612219, url, valid)

proc call*(call_612220: Call_GetMLTaskRuns_612205; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getMLTaskRuns
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612221 = newJObject()
  var body_612222 = newJObject()
  add(query_612221, "MaxResults", newJString(MaxResults))
  add(query_612221, "NextToken", newJString(NextToken))
  if body != nil:
    body_612222 = body
  result = call_612220.call(nil, query_612221, nil, nil, body_612222)

var getMLTaskRuns* = Call_GetMLTaskRuns_612205(name: "getMLTaskRuns",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTaskRuns",
    validator: validate_GetMLTaskRuns_612206, base: "/", url: url_GetMLTaskRuns_612207,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTransform_612223 = ref object of OpenApiRestCall_610658
proc url_GetMLTransform_612225(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMLTransform_612224(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
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
  var valid_612226 = header.getOrDefault("X-Amz-Target")
  valid_612226 = validateParameter(valid_612226, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTransform"))
  if valid_612226 != nil:
    section.add "X-Amz-Target", valid_612226
  var valid_612227 = header.getOrDefault("X-Amz-Signature")
  valid_612227 = validateParameter(valid_612227, JString, required = false,
                                 default = nil)
  if valid_612227 != nil:
    section.add "X-Amz-Signature", valid_612227
  var valid_612228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612228 = validateParameter(valid_612228, JString, required = false,
                                 default = nil)
  if valid_612228 != nil:
    section.add "X-Amz-Content-Sha256", valid_612228
  var valid_612229 = header.getOrDefault("X-Amz-Date")
  valid_612229 = validateParameter(valid_612229, JString, required = false,
                                 default = nil)
  if valid_612229 != nil:
    section.add "X-Amz-Date", valid_612229
  var valid_612230 = header.getOrDefault("X-Amz-Credential")
  valid_612230 = validateParameter(valid_612230, JString, required = false,
                                 default = nil)
  if valid_612230 != nil:
    section.add "X-Amz-Credential", valid_612230
  var valid_612231 = header.getOrDefault("X-Amz-Security-Token")
  valid_612231 = validateParameter(valid_612231, JString, required = false,
                                 default = nil)
  if valid_612231 != nil:
    section.add "X-Amz-Security-Token", valid_612231
  var valid_612232 = header.getOrDefault("X-Amz-Algorithm")
  valid_612232 = validateParameter(valid_612232, JString, required = false,
                                 default = nil)
  if valid_612232 != nil:
    section.add "X-Amz-Algorithm", valid_612232
  var valid_612233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612233 = validateParameter(valid_612233, JString, required = false,
                                 default = nil)
  if valid_612233 != nil:
    section.add "X-Amz-SignedHeaders", valid_612233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612235: Call_GetMLTransform_612223; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
  ## 
  let valid = call_612235.validator(path, query, header, formData, body)
  let scheme = call_612235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612235.url(scheme.get, call_612235.host, call_612235.base,
                         call_612235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612235, url, valid)

proc call*(call_612236: Call_GetMLTransform_612223; body: JsonNode): Recallable =
  ## getMLTransform
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
  ##   body: JObject (required)
  var body_612237 = newJObject()
  if body != nil:
    body_612237 = body
  result = call_612236.call(nil, nil, nil, nil, body_612237)

var getMLTransform* = Call_GetMLTransform_612223(name: "getMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTransform",
    validator: validate_GetMLTransform_612224, base: "/", url: url_GetMLTransform_612225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTransforms_612238 = ref object of OpenApiRestCall_610658
proc url_GetMLTransforms_612240(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMLTransforms_612239(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
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
  var valid_612241 = query.getOrDefault("MaxResults")
  valid_612241 = validateParameter(valid_612241, JString, required = false,
                                 default = nil)
  if valid_612241 != nil:
    section.add "MaxResults", valid_612241
  var valid_612242 = query.getOrDefault("NextToken")
  valid_612242 = validateParameter(valid_612242, JString, required = false,
                                 default = nil)
  if valid_612242 != nil:
    section.add "NextToken", valid_612242
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
  var valid_612243 = header.getOrDefault("X-Amz-Target")
  valid_612243 = validateParameter(valid_612243, JString, required = true, default = newJString(
      "AWSGlue.GetMLTransforms"))
  if valid_612243 != nil:
    section.add "X-Amz-Target", valid_612243
  var valid_612244 = header.getOrDefault("X-Amz-Signature")
  valid_612244 = validateParameter(valid_612244, JString, required = false,
                                 default = nil)
  if valid_612244 != nil:
    section.add "X-Amz-Signature", valid_612244
  var valid_612245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612245 = validateParameter(valid_612245, JString, required = false,
                                 default = nil)
  if valid_612245 != nil:
    section.add "X-Amz-Content-Sha256", valid_612245
  var valid_612246 = header.getOrDefault("X-Amz-Date")
  valid_612246 = validateParameter(valid_612246, JString, required = false,
                                 default = nil)
  if valid_612246 != nil:
    section.add "X-Amz-Date", valid_612246
  var valid_612247 = header.getOrDefault("X-Amz-Credential")
  valid_612247 = validateParameter(valid_612247, JString, required = false,
                                 default = nil)
  if valid_612247 != nil:
    section.add "X-Amz-Credential", valid_612247
  var valid_612248 = header.getOrDefault("X-Amz-Security-Token")
  valid_612248 = validateParameter(valid_612248, JString, required = false,
                                 default = nil)
  if valid_612248 != nil:
    section.add "X-Amz-Security-Token", valid_612248
  var valid_612249 = header.getOrDefault("X-Amz-Algorithm")
  valid_612249 = validateParameter(valid_612249, JString, required = false,
                                 default = nil)
  if valid_612249 != nil:
    section.add "X-Amz-Algorithm", valid_612249
  var valid_612250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612250 = validateParameter(valid_612250, JString, required = false,
                                 default = nil)
  if valid_612250 != nil:
    section.add "X-Amz-SignedHeaders", valid_612250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612252: Call_GetMLTransforms_612238; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
  ## 
  let valid = call_612252.validator(path, query, header, formData, body)
  let scheme = call_612252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612252.url(scheme.get, call_612252.host, call_612252.base,
                         call_612252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612252, url, valid)

proc call*(call_612253: Call_GetMLTransforms_612238; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getMLTransforms
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612254 = newJObject()
  var body_612255 = newJObject()
  add(query_612254, "MaxResults", newJString(MaxResults))
  add(query_612254, "NextToken", newJString(NextToken))
  if body != nil:
    body_612255 = body
  result = call_612253.call(nil, query_612254, nil, nil, body_612255)

var getMLTransforms* = Call_GetMLTransforms_612238(name: "getMLTransforms",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTransforms",
    validator: validate_GetMLTransforms_612239, base: "/", url: url_GetMLTransforms_612240,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMapping_612256 = ref object of OpenApiRestCall_610658
proc url_GetMapping_612258(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMapping_612257(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates mappings.
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
  var valid_612259 = header.getOrDefault("X-Amz-Target")
  valid_612259 = validateParameter(valid_612259, JString, required = true,
                                 default = newJString("AWSGlue.GetMapping"))
  if valid_612259 != nil:
    section.add "X-Amz-Target", valid_612259
  var valid_612260 = header.getOrDefault("X-Amz-Signature")
  valid_612260 = validateParameter(valid_612260, JString, required = false,
                                 default = nil)
  if valid_612260 != nil:
    section.add "X-Amz-Signature", valid_612260
  var valid_612261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612261 = validateParameter(valid_612261, JString, required = false,
                                 default = nil)
  if valid_612261 != nil:
    section.add "X-Amz-Content-Sha256", valid_612261
  var valid_612262 = header.getOrDefault("X-Amz-Date")
  valid_612262 = validateParameter(valid_612262, JString, required = false,
                                 default = nil)
  if valid_612262 != nil:
    section.add "X-Amz-Date", valid_612262
  var valid_612263 = header.getOrDefault("X-Amz-Credential")
  valid_612263 = validateParameter(valid_612263, JString, required = false,
                                 default = nil)
  if valid_612263 != nil:
    section.add "X-Amz-Credential", valid_612263
  var valid_612264 = header.getOrDefault("X-Amz-Security-Token")
  valid_612264 = validateParameter(valid_612264, JString, required = false,
                                 default = nil)
  if valid_612264 != nil:
    section.add "X-Amz-Security-Token", valid_612264
  var valid_612265 = header.getOrDefault("X-Amz-Algorithm")
  valid_612265 = validateParameter(valid_612265, JString, required = false,
                                 default = nil)
  if valid_612265 != nil:
    section.add "X-Amz-Algorithm", valid_612265
  var valid_612266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612266 = validateParameter(valid_612266, JString, required = false,
                                 default = nil)
  if valid_612266 != nil:
    section.add "X-Amz-SignedHeaders", valid_612266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612268: Call_GetMapping_612256; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates mappings.
  ## 
  let valid = call_612268.validator(path, query, header, formData, body)
  let scheme = call_612268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612268.url(scheme.get, call_612268.host, call_612268.base,
                         call_612268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612268, url, valid)

proc call*(call_612269: Call_GetMapping_612256; body: JsonNode): Recallable =
  ## getMapping
  ## Creates mappings.
  ##   body: JObject (required)
  var body_612270 = newJObject()
  if body != nil:
    body_612270 = body
  result = call_612269.call(nil, nil, nil, nil, body_612270)

var getMapping* = Call_GetMapping_612256(name: "getMapping",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetMapping",
                                      validator: validate_GetMapping_612257,
                                      base: "/", url: url_GetMapping_612258,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPartition_612271 = ref object of OpenApiRestCall_610658
proc url_GetPartition_612273(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPartition_612272(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about a specified partition.
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
  var valid_612274 = header.getOrDefault("X-Amz-Target")
  valid_612274 = validateParameter(valid_612274, JString, required = true,
                                 default = newJString("AWSGlue.GetPartition"))
  if valid_612274 != nil:
    section.add "X-Amz-Target", valid_612274
  var valid_612275 = header.getOrDefault("X-Amz-Signature")
  valid_612275 = validateParameter(valid_612275, JString, required = false,
                                 default = nil)
  if valid_612275 != nil:
    section.add "X-Amz-Signature", valid_612275
  var valid_612276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612276 = validateParameter(valid_612276, JString, required = false,
                                 default = nil)
  if valid_612276 != nil:
    section.add "X-Amz-Content-Sha256", valid_612276
  var valid_612277 = header.getOrDefault("X-Amz-Date")
  valid_612277 = validateParameter(valid_612277, JString, required = false,
                                 default = nil)
  if valid_612277 != nil:
    section.add "X-Amz-Date", valid_612277
  var valid_612278 = header.getOrDefault("X-Amz-Credential")
  valid_612278 = validateParameter(valid_612278, JString, required = false,
                                 default = nil)
  if valid_612278 != nil:
    section.add "X-Amz-Credential", valid_612278
  var valid_612279 = header.getOrDefault("X-Amz-Security-Token")
  valid_612279 = validateParameter(valid_612279, JString, required = false,
                                 default = nil)
  if valid_612279 != nil:
    section.add "X-Amz-Security-Token", valid_612279
  var valid_612280 = header.getOrDefault("X-Amz-Algorithm")
  valid_612280 = validateParameter(valid_612280, JString, required = false,
                                 default = nil)
  if valid_612280 != nil:
    section.add "X-Amz-Algorithm", valid_612280
  var valid_612281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612281 = validateParameter(valid_612281, JString, required = false,
                                 default = nil)
  if valid_612281 != nil:
    section.add "X-Amz-SignedHeaders", valid_612281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612283: Call_GetPartition_612271; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a specified partition.
  ## 
  let valid = call_612283.validator(path, query, header, formData, body)
  let scheme = call_612283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612283.url(scheme.get, call_612283.host, call_612283.base,
                         call_612283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612283, url, valid)

proc call*(call_612284: Call_GetPartition_612271; body: JsonNode): Recallable =
  ## getPartition
  ## Retrieves information about a specified partition.
  ##   body: JObject (required)
  var body_612285 = newJObject()
  if body != nil:
    body_612285 = body
  result = call_612284.call(nil, nil, nil, nil, body_612285)

var getPartition* = Call_GetPartition_612271(name: "getPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetPartition",
    validator: validate_GetPartition_612272, base: "/", url: url_GetPartition_612273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPartitions_612286 = ref object of OpenApiRestCall_610658
proc url_GetPartitions_612288(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPartitions_612287(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about the partitions in a table.
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
  var valid_612289 = query.getOrDefault("MaxResults")
  valid_612289 = validateParameter(valid_612289, JString, required = false,
                                 default = nil)
  if valid_612289 != nil:
    section.add "MaxResults", valid_612289
  var valid_612290 = query.getOrDefault("NextToken")
  valid_612290 = validateParameter(valid_612290, JString, required = false,
                                 default = nil)
  if valid_612290 != nil:
    section.add "NextToken", valid_612290
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
  var valid_612291 = header.getOrDefault("X-Amz-Target")
  valid_612291 = validateParameter(valid_612291, JString, required = true,
                                 default = newJString("AWSGlue.GetPartitions"))
  if valid_612291 != nil:
    section.add "X-Amz-Target", valid_612291
  var valid_612292 = header.getOrDefault("X-Amz-Signature")
  valid_612292 = validateParameter(valid_612292, JString, required = false,
                                 default = nil)
  if valid_612292 != nil:
    section.add "X-Amz-Signature", valid_612292
  var valid_612293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612293 = validateParameter(valid_612293, JString, required = false,
                                 default = nil)
  if valid_612293 != nil:
    section.add "X-Amz-Content-Sha256", valid_612293
  var valid_612294 = header.getOrDefault("X-Amz-Date")
  valid_612294 = validateParameter(valid_612294, JString, required = false,
                                 default = nil)
  if valid_612294 != nil:
    section.add "X-Amz-Date", valid_612294
  var valid_612295 = header.getOrDefault("X-Amz-Credential")
  valid_612295 = validateParameter(valid_612295, JString, required = false,
                                 default = nil)
  if valid_612295 != nil:
    section.add "X-Amz-Credential", valid_612295
  var valid_612296 = header.getOrDefault("X-Amz-Security-Token")
  valid_612296 = validateParameter(valid_612296, JString, required = false,
                                 default = nil)
  if valid_612296 != nil:
    section.add "X-Amz-Security-Token", valid_612296
  var valid_612297 = header.getOrDefault("X-Amz-Algorithm")
  valid_612297 = validateParameter(valid_612297, JString, required = false,
                                 default = nil)
  if valid_612297 != nil:
    section.add "X-Amz-Algorithm", valid_612297
  var valid_612298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612298 = validateParameter(valid_612298, JString, required = false,
                                 default = nil)
  if valid_612298 != nil:
    section.add "X-Amz-SignedHeaders", valid_612298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612300: Call_GetPartitions_612286; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the partitions in a table.
  ## 
  let valid = call_612300.validator(path, query, header, formData, body)
  let scheme = call_612300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612300.url(scheme.get, call_612300.host, call_612300.base,
                         call_612300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612300, url, valid)

proc call*(call_612301: Call_GetPartitions_612286; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getPartitions
  ## Retrieves information about the partitions in a table.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612302 = newJObject()
  var body_612303 = newJObject()
  add(query_612302, "MaxResults", newJString(MaxResults))
  add(query_612302, "NextToken", newJString(NextToken))
  if body != nil:
    body_612303 = body
  result = call_612301.call(nil, query_612302, nil, nil, body_612303)

var getPartitions* = Call_GetPartitions_612286(name: "getPartitions",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetPartitions",
    validator: validate_GetPartitions_612287, base: "/", url: url_GetPartitions_612288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPlan_612304 = ref object of OpenApiRestCall_610658
proc url_GetPlan_612306(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPlan_612305(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets code to perform a specified mapping.
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
  var valid_612307 = header.getOrDefault("X-Amz-Target")
  valid_612307 = validateParameter(valid_612307, JString, required = true,
                                 default = newJString("AWSGlue.GetPlan"))
  if valid_612307 != nil:
    section.add "X-Amz-Target", valid_612307
  var valid_612308 = header.getOrDefault("X-Amz-Signature")
  valid_612308 = validateParameter(valid_612308, JString, required = false,
                                 default = nil)
  if valid_612308 != nil:
    section.add "X-Amz-Signature", valid_612308
  var valid_612309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612309 = validateParameter(valid_612309, JString, required = false,
                                 default = nil)
  if valid_612309 != nil:
    section.add "X-Amz-Content-Sha256", valid_612309
  var valid_612310 = header.getOrDefault("X-Amz-Date")
  valid_612310 = validateParameter(valid_612310, JString, required = false,
                                 default = nil)
  if valid_612310 != nil:
    section.add "X-Amz-Date", valid_612310
  var valid_612311 = header.getOrDefault("X-Amz-Credential")
  valid_612311 = validateParameter(valid_612311, JString, required = false,
                                 default = nil)
  if valid_612311 != nil:
    section.add "X-Amz-Credential", valid_612311
  var valid_612312 = header.getOrDefault("X-Amz-Security-Token")
  valid_612312 = validateParameter(valid_612312, JString, required = false,
                                 default = nil)
  if valid_612312 != nil:
    section.add "X-Amz-Security-Token", valid_612312
  var valid_612313 = header.getOrDefault("X-Amz-Algorithm")
  valid_612313 = validateParameter(valid_612313, JString, required = false,
                                 default = nil)
  if valid_612313 != nil:
    section.add "X-Amz-Algorithm", valid_612313
  var valid_612314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612314 = validateParameter(valid_612314, JString, required = false,
                                 default = nil)
  if valid_612314 != nil:
    section.add "X-Amz-SignedHeaders", valid_612314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612316: Call_GetPlan_612304; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets code to perform a specified mapping.
  ## 
  let valid = call_612316.validator(path, query, header, formData, body)
  let scheme = call_612316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612316.url(scheme.get, call_612316.host, call_612316.base,
                         call_612316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612316, url, valid)

proc call*(call_612317: Call_GetPlan_612304; body: JsonNode): Recallable =
  ## getPlan
  ## Gets code to perform a specified mapping.
  ##   body: JObject (required)
  var body_612318 = newJObject()
  if body != nil:
    body_612318 = body
  result = call_612317.call(nil, nil, nil, nil, body_612318)

var getPlan* = Call_GetPlan_612304(name: "getPlan", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetPlan",
                                validator: validate_GetPlan_612305, base: "/",
                                url: url_GetPlan_612306,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourcePolicy_612319 = ref object of OpenApiRestCall_610658
proc url_GetResourcePolicy_612321(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResourcePolicy_612320(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves a specified resource policy.
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
  var valid_612322 = header.getOrDefault("X-Amz-Target")
  valid_612322 = validateParameter(valid_612322, JString, required = true, default = newJString(
      "AWSGlue.GetResourcePolicy"))
  if valid_612322 != nil:
    section.add "X-Amz-Target", valid_612322
  var valid_612323 = header.getOrDefault("X-Amz-Signature")
  valid_612323 = validateParameter(valid_612323, JString, required = false,
                                 default = nil)
  if valid_612323 != nil:
    section.add "X-Amz-Signature", valid_612323
  var valid_612324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612324 = validateParameter(valid_612324, JString, required = false,
                                 default = nil)
  if valid_612324 != nil:
    section.add "X-Amz-Content-Sha256", valid_612324
  var valid_612325 = header.getOrDefault("X-Amz-Date")
  valid_612325 = validateParameter(valid_612325, JString, required = false,
                                 default = nil)
  if valid_612325 != nil:
    section.add "X-Amz-Date", valid_612325
  var valid_612326 = header.getOrDefault("X-Amz-Credential")
  valid_612326 = validateParameter(valid_612326, JString, required = false,
                                 default = nil)
  if valid_612326 != nil:
    section.add "X-Amz-Credential", valid_612326
  var valid_612327 = header.getOrDefault("X-Amz-Security-Token")
  valid_612327 = validateParameter(valid_612327, JString, required = false,
                                 default = nil)
  if valid_612327 != nil:
    section.add "X-Amz-Security-Token", valid_612327
  var valid_612328 = header.getOrDefault("X-Amz-Algorithm")
  valid_612328 = validateParameter(valid_612328, JString, required = false,
                                 default = nil)
  if valid_612328 != nil:
    section.add "X-Amz-Algorithm", valid_612328
  var valid_612329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612329 = validateParameter(valid_612329, JString, required = false,
                                 default = nil)
  if valid_612329 != nil:
    section.add "X-Amz-SignedHeaders", valid_612329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612331: Call_GetResourcePolicy_612319; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified resource policy.
  ## 
  let valid = call_612331.validator(path, query, header, formData, body)
  let scheme = call_612331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612331.url(scheme.get, call_612331.host, call_612331.base,
                         call_612331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612331, url, valid)

proc call*(call_612332: Call_GetResourcePolicy_612319; body: JsonNode): Recallable =
  ## getResourcePolicy
  ## Retrieves a specified resource policy.
  ##   body: JObject (required)
  var body_612333 = newJObject()
  if body != nil:
    body_612333 = body
  result = call_612332.call(nil, nil, nil, nil, body_612333)

var getResourcePolicy* = Call_GetResourcePolicy_612319(name: "getResourcePolicy",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetResourcePolicy",
    validator: validate_GetResourcePolicy_612320, base: "/",
    url: url_GetResourcePolicy_612321, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSecurityConfiguration_612334 = ref object of OpenApiRestCall_610658
proc url_GetSecurityConfiguration_612336(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSecurityConfiguration_612335(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a specified security configuration.
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
  var valid_612337 = header.getOrDefault("X-Amz-Target")
  valid_612337 = validateParameter(valid_612337, JString, required = true, default = newJString(
      "AWSGlue.GetSecurityConfiguration"))
  if valid_612337 != nil:
    section.add "X-Amz-Target", valid_612337
  var valid_612338 = header.getOrDefault("X-Amz-Signature")
  valid_612338 = validateParameter(valid_612338, JString, required = false,
                                 default = nil)
  if valid_612338 != nil:
    section.add "X-Amz-Signature", valid_612338
  var valid_612339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612339 = validateParameter(valid_612339, JString, required = false,
                                 default = nil)
  if valid_612339 != nil:
    section.add "X-Amz-Content-Sha256", valid_612339
  var valid_612340 = header.getOrDefault("X-Amz-Date")
  valid_612340 = validateParameter(valid_612340, JString, required = false,
                                 default = nil)
  if valid_612340 != nil:
    section.add "X-Amz-Date", valid_612340
  var valid_612341 = header.getOrDefault("X-Amz-Credential")
  valid_612341 = validateParameter(valid_612341, JString, required = false,
                                 default = nil)
  if valid_612341 != nil:
    section.add "X-Amz-Credential", valid_612341
  var valid_612342 = header.getOrDefault("X-Amz-Security-Token")
  valid_612342 = validateParameter(valid_612342, JString, required = false,
                                 default = nil)
  if valid_612342 != nil:
    section.add "X-Amz-Security-Token", valid_612342
  var valid_612343 = header.getOrDefault("X-Amz-Algorithm")
  valid_612343 = validateParameter(valid_612343, JString, required = false,
                                 default = nil)
  if valid_612343 != nil:
    section.add "X-Amz-Algorithm", valid_612343
  var valid_612344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612344 = validateParameter(valid_612344, JString, required = false,
                                 default = nil)
  if valid_612344 != nil:
    section.add "X-Amz-SignedHeaders", valid_612344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612346: Call_GetSecurityConfiguration_612334; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified security configuration.
  ## 
  let valid = call_612346.validator(path, query, header, formData, body)
  let scheme = call_612346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612346.url(scheme.get, call_612346.host, call_612346.base,
                         call_612346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612346, url, valid)

proc call*(call_612347: Call_GetSecurityConfiguration_612334; body: JsonNode): Recallable =
  ## getSecurityConfiguration
  ## Retrieves a specified security configuration.
  ##   body: JObject (required)
  var body_612348 = newJObject()
  if body != nil:
    body_612348 = body
  result = call_612347.call(nil, nil, nil, nil, body_612348)

var getSecurityConfiguration* = Call_GetSecurityConfiguration_612334(
    name: "getSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetSecurityConfiguration",
    validator: validate_GetSecurityConfiguration_612335, base: "/",
    url: url_GetSecurityConfiguration_612336, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSecurityConfigurations_612349 = ref object of OpenApiRestCall_610658
proc url_GetSecurityConfigurations_612351(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSecurityConfigurations_612350(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of all security configurations.
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
  var valid_612352 = query.getOrDefault("MaxResults")
  valid_612352 = validateParameter(valid_612352, JString, required = false,
                                 default = nil)
  if valid_612352 != nil:
    section.add "MaxResults", valid_612352
  var valid_612353 = query.getOrDefault("NextToken")
  valid_612353 = validateParameter(valid_612353, JString, required = false,
                                 default = nil)
  if valid_612353 != nil:
    section.add "NextToken", valid_612353
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
  var valid_612354 = header.getOrDefault("X-Amz-Target")
  valid_612354 = validateParameter(valid_612354, JString, required = true, default = newJString(
      "AWSGlue.GetSecurityConfigurations"))
  if valid_612354 != nil:
    section.add "X-Amz-Target", valid_612354
  var valid_612355 = header.getOrDefault("X-Amz-Signature")
  valid_612355 = validateParameter(valid_612355, JString, required = false,
                                 default = nil)
  if valid_612355 != nil:
    section.add "X-Amz-Signature", valid_612355
  var valid_612356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612356 = validateParameter(valid_612356, JString, required = false,
                                 default = nil)
  if valid_612356 != nil:
    section.add "X-Amz-Content-Sha256", valid_612356
  var valid_612357 = header.getOrDefault("X-Amz-Date")
  valid_612357 = validateParameter(valid_612357, JString, required = false,
                                 default = nil)
  if valid_612357 != nil:
    section.add "X-Amz-Date", valid_612357
  var valid_612358 = header.getOrDefault("X-Amz-Credential")
  valid_612358 = validateParameter(valid_612358, JString, required = false,
                                 default = nil)
  if valid_612358 != nil:
    section.add "X-Amz-Credential", valid_612358
  var valid_612359 = header.getOrDefault("X-Amz-Security-Token")
  valid_612359 = validateParameter(valid_612359, JString, required = false,
                                 default = nil)
  if valid_612359 != nil:
    section.add "X-Amz-Security-Token", valid_612359
  var valid_612360 = header.getOrDefault("X-Amz-Algorithm")
  valid_612360 = validateParameter(valid_612360, JString, required = false,
                                 default = nil)
  if valid_612360 != nil:
    section.add "X-Amz-Algorithm", valid_612360
  var valid_612361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612361 = validateParameter(valid_612361, JString, required = false,
                                 default = nil)
  if valid_612361 != nil:
    section.add "X-Amz-SignedHeaders", valid_612361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612363: Call_GetSecurityConfigurations_612349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of all security configurations.
  ## 
  let valid = call_612363.validator(path, query, header, formData, body)
  let scheme = call_612363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612363.url(scheme.get, call_612363.host, call_612363.base,
                         call_612363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612363, url, valid)

proc call*(call_612364: Call_GetSecurityConfigurations_612349; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getSecurityConfigurations
  ## Retrieves a list of all security configurations.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612365 = newJObject()
  var body_612366 = newJObject()
  add(query_612365, "MaxResults", newJString(MaxResults))
  add(query_612365, "NextToken", newJString(NextToken))
  if body != nil:
    body_612366 = body
  result = call_612364.call(nil, query_612365, nil, nil, body_612366)

var getSecurityConfigurations* = Call_GetSecurityConfigurations_612349(
    name: "getSecurityConfigurations", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetSecurityConfigurations",
    validator: validate_GetSecurityConfigurations_612350, base: "/",
    url: url_GetSecurityConfigurations_612351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTable_612367 = ref object of OpenApiRestCall_610658
proc url_GetTable_612369(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTable_612368(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
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
  var valid_612370 = header.getOrDefault("X-Amz-Target")
  valid_612370 = validateParameter(valid_612370, JString, required = true,
                                 default = newJString("AWSGlue.GetTable"))
  if valid_612370 != nil:
    section.add "X-Amz-Target", valid_612370
  var valid_612371 = header.getOrDefault("X-Amz-Signature")
  valid_612371 = validateParameter(valid_612371, JString, required = false,
                                 default = nil)
  if valid_612371 != nil:
    section.add "X-Amz-Signature", valid_612371
  var valid_612372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612372 = validateParameter(valid_612372, JString, required = false,
                                 default = nil)
  if valid_612372 != nil:
    section.add "X-Amz-Content-Sha256", valid_612372
  var valid_612373 = header.getOrDefault("X-Amz-Date")
  valid_612373 = validateParameter(valid_612373, JString, required = false,
                                 default = nil)
  if valid_612373 != nil:
    section.add "X-Amz-Date", valid_612373
  var valid_612374 = header.getOrDefault("X-Amz-Credential")
  valid_612374 = validateParameter(valid_612374, JString, required = false,
                                 default = nil)
  if valid_612374 != nil:
    section.add "X-Amz-Credential", valid_612374
  var valid_612375 = header.getOrDefault("X-Amz-Security-Token")
  valid_612375 = validateParameter(valid_612375, JString, required = false,
                                 default = nil)
  if valid_612375 != nil:
    section.add "X-Amz-Security-Token", valid_612375
  var valid_612376 = header.getOrDefault("X-Amz-Algorithm")
  valid_612376 = validateParameter(valid_612376, JString, required = false,
                                 default = nil)
  if valid_612376 != nil:
    section.add "X-Amz-Algorithm", valid_612376
  var valid_612377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612377 = validateParameter(valid_612377, JString, required = false,
                                 default = nil)
  if valid_612377 != nil:
    section.add "X-Amz-SignedHeaders", valid_612377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612379: Call_GetTable_612367; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
  ## 
  let valid = call_612379.validator(path, query, header, formData, body)
  let scheme = call_612379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612379.url(scheme.get, call_612379.host, call_612379.base,
                         call_612379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612379, url, valid)

proc call*(call_612380: Call_GetTable_612367; body: JsonNode): Recallable =
  ## getTable
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
  ##   body: JObject (required)
  var body_612381 = newJObject()
  if body != nil:
    body_612381 = body
  result = call_612380.call(nil, nil, nil, nil, body_612381)

var getTable* = Call_GetTable_612367(name: "getTable", meth: HttpMethod.HttpPost,
                                  host: "glue.amazonaws.com",
                                  route: "/#X-Amz-Target=AWSGlue.GetTable",
                                  validator: validate_GetTable_612368, base: "/",
                                  url: url_GetTable_612369,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTableVersion_612382 = ref object of OpenApiRestCall_610658
proc url_GetTableVersion_612384(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTableVersion_612383(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Retrieves a specified version of a table.
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
  var valid_612385 = header.getOrDefault("X-Amz-Target")
  valid_612385 = validateParameter(valid_612385, JString, required = true, default = newJString(
      "AWSGlue.GetTableVersion"))
  if valid_612385 != nil:
    section.add "X-Amz-Target", valid_612385
  var valid_612386 = header.getOrDefault("X-Amz-Signature")
  valid_612386 = validateParameter(valid_612386, JString, required = false,
                                 default = nil)
  if valid_612386 != nil:
    section.add "X-Amz-Signature", valid_612386
  var valid_612387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612387 = validateParameter(valid_612387, JString, required = false,
                                 default = nil)
  if valid_612387 != nil:
    section.add "X-Amz-Content-Sha256", valid_612387
  var valid_612388 = header.getOrDefault("X-Amz-Date")
  valid_612388 = validateParameter(valid_612388, JString, required = false,
                                 default = nil)
  if valid_612388 != nil:
    section.add "X-Amz-Date", valid_612388
  var valid_612389 = header.getOrDefault("X-Amz-Credential")
  valid_612389 = validateParameter(valid_612389, JString, required = false,
                                 default = nil)
  if valid_612389 != nil:
    section.add "X-Amz-Credential", valid_612389
  var valid_612390 = header.getOrDefault("X-Amz-Security-Token")
  valid_612390 = validateParameter(valid_612390, JString, required = false,
                                 default = nil)
  if valid_612390 != nil:
    section.add "X-Amz-Security-Token", valid_612390
  var valid_612391 = header.getOrDefault("X-Amz-Algorithm")
  valid_612391 = validateParameter(valid_612391, JString, required = false,
                                 default = nil)
  if valid_612391 != nil:
    section.add "X-Amz-Algorithm", valid_612391
  var valid_612392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612392 = validateParameter(valid_612392, JString, required = false,
                                 default = nil)
  if valid_612392 != nil:
    section.add "X-Amz-SignedHeaders", valid_612392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612394: Call_GetTableVersion_612382; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified version of a table.
  ## 
  let valid = call_612394.validator(path, query, header, formData, body)
  let scheme = call_612394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612394.url(scheme.get, call_612394.host, call_612394.base,
                         call_612394.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612394, url, valid)

proc call*(call_612395: Call_GetTableVersion_612382; body: JsonNode): Recallable =
  ## getTableVersion
  ## Retrieves a specified version of a table.
  ##   body: JObject (required)
  var body_612396 = newJObject()
  if body != nil:
    body_612396 = body
  result = call_612395.call(nil, nil, nil, nil, body_612396)

var getTableVersion* = Call_GetTableVersion_612382(name: "getTableVersion",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetTableVersion",
    validator: validate_GetTableVersion_612383, base: "/", url: url_GetTableVersion_612384,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTableVersions_612397 = ref object of OpenApiRestCall_610658
proc url_GetTableVersions_612399(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTableVersions_612398(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieves a list of strings that identify available versions of a specified table.
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
  var valid_612400 = query.getOrDefault("MaxResults")
  valid_612400 = validateParameter(valid_612400, JString, required = false,
                                 default = nil)
  if valid_612400 != nil:
    section.add "MaxResults", valid_612400
  var valid_612401 = query.getOrDefault("NextToken")
  valid_612401 = validateParameter(valid_612401, JString, required = false,
                                 default = nil)
  if valid_612401 != nil:
    section.add "NextToken", valid_612401
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
  var valid_612402 = header.getOrDefault("X-Amz-Target")
  valid_612402 = validateParameter(valid_612402, JString, required = true, default = newJString(
      "AWSGlue.GetTableVersions"))
  if valid_612402 != nil:
    section.add "X-Amz-Target", valid_612402
  var valid_612403 = header.getOrDefault("X-Amz-Signature")
  valid_612403 = validateParameter(valid_612403, JString, required = false,
                                 default = nil)
  if valid_612403 != nil:
    section.add "X-Amz-Signature", valid_612403
  var valid_612404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612404 = validateParameter(valid_612404, JString, required = false,
                                 default = nil)
  if valid_612404 != nil:
    section.add "X-Amz-Content-Sha256", valid_612404
  var valid_612405 = header.getOrDefault("X-Amz-Date")
  valid_612405 = validateParameter(valid_612405, JString, required = false,
                                 default = nil)
  if valid_612405 != nil:
    section.add "X-Amz-Date", valid_612405
  var valid_612406 = header.getOrDefault("X-Amz-Credential")
  valid_612406 = validateParameter(valid_612406, JString, required = false,
                                 default = nil)
  if valid_612406 != nil:
    section.add "X-Amz-Credential", valid_612406
  var valid_612407 = header.getOrDefault("X-Amz-Security-Token")
  valid_612407 = validateParameter(valid_612407, JString, required = false,
                                 default = nil)
  if valid_612407 != nil:
    section.add "X-Amz-Security-Token", valid_612407
  var valid_612408 = header.getOrDefault("X-Amz-Algorithm")
  valid_612408 = validateParameter(valid_612408, JString, required = false,
                                 default = nil)
  if valid_612408 != nil:
    section.add "X-Amz-Algorithm", valid_612408
  var valid_612409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612409 = validateParameter(valid_612409, JString, required = false,
                                 default = nil)
  if valid_612409 != nil:
    section.add "X-Amz-SignedHeaders", valid_612409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612411: Call_GetTableVersions_612397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of strings that identify available versions of a specified table.
  ## 
  let valid = call_612411.validator(path, query, header, formData, body)
  let scheme = call_612411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612411.url(scheme.get, call_612411.host, call_612411.base,
                         call_612411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612411, url, valid)

proc call*(call_612412: Call_GetTableVersions_612397; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getTableVersions
  ## Retrieves a list of strings that identify available versions of a specified table.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612413 = newJObject()
  var body_612414 = newJObject()
  add(query_612413, "MaxResults", newJString(MaxResults))
  add(query_612413, "NextToken", newJString(NextToken))
  if body != nil:
    body_612414 = body
  result = call_612412.call(nil, query_612413, nil, nil, body_612414)

var getTableVersions* = Call_GetTableVersions_612397(name: "getTableVersions",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetTableVersions",
    validator: validate_GetTableVersions_612398, base: "/",
    url: url_GetTableVersions_612399, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTables_612415 = ref object of OpenApiRestCall_610658
proc url_GetTables_612417(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTables_612416(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
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
  var valid_612418 = query.getOrDefault("MaxResults")
  valid_612418 = validateParameter(valid_612418, JString, required = false,
                                 default = nil)
  if valid_612418 != nil:
    section.add "MaxResults", valid_612418
  var valid_612419 = query.getOrDefault("NextToken")
  valid_612419 = validateParameter(valid_612419, JString, required = false,
                                 default = nil)
  if valid_612419 != nil:
    section.add "NextToken", valid_612419
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
  var valid_612420 = header.getOrDefault("X-Amz-Target")
  valid_612420 = validateParameter(valid_612420, JString, required = true,
                                 default = newJString("AWSGlue.GetTables"))
  if valid_612420 != nil:
    section.add "X-Amz-Target", valid_612420
  var valid_612421 = header.getOrDefault("X-Amz-Signature")
  valid_612421 = validateParameter(valid_612421, JString, required = false,
                                 default = nil)
  if valid_612421 != nil:
    section.add "X-Amz-Signature", valid_612421
  var valid_612422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612422 = validateParameter(valid_612422, JString, required = false,
                                 default = nil)
  if valid_612422 != nil:
    section.add "X-Amz-Content-Sha256", valid_612422
  var valid_612423 = header.getOrDefault("X-Amz-Date")
  valid_612423 = validateParameter(valid_612423, JString, required = false,
                                 default = nil)
  if valid_612423 != nil:
    section.add "X-Amz-Date", valid_612423
  var valid_612424 = header.getOrDefault("X-Amz-Credential")
  valid_612424 = validateParameter(valid_612424, JString, required = false,
                                 default = nil)
  if valid_612424 != nil:
    section.add "X-Amz-Credential", valid_612424
  var valid_612425 = header.getOrDefault("X-Amz-Security-Token")
  valid_612425 = validateParameter(valid_612425, JString, required = false,
                                 default = nil)
  if valid_612425 != nil:
    section.add "X-Amz-Security-Token", valid_612425
  var valid_612426 = header.getOrDefault("X-Amz-Algorithm")
  valid_612426 = validateParameter(valid_612426, JString, required = false,
                                 default = nil)
  if valid_612426 != nil:
    section.add "X-Amz-Algorithm", valid_612426
  var valid_612427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612427 = validateParameter(valid_612427, JString, required = false,
                                 default = nil)
  if valid_612427 != nil:
    section.add "X-Amz-SignedHeaders", valid_612427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612429: Call_GetTables_612415; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
  ## 
  let valid = call_612429.validator(path, query, header, formData, body)
  let scheme = call_612429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612429.url(scheme.get, call_612429.host, call_612429.base,
                         call_612429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612429, url, valid)

proc call*(call_612430: Call_GetTables_612415; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getTables
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612431 = newJObject()
  var body_612432 = newJObject()
  add(query_612431, "MaxResults", newJString(MaxResults))
  add(query_612431, "NextToken", newJString(NextToken))
  if body != nil:
    body_612432 = body
  result = call_612430.call(nil, query_612431, nil, nil, body_612432)

var getTables* = Call_GetTables_612415(name: "getTables", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.GetTables",
                                    validator: validate_GetTables_612416,
                                    base: "/", url: url_GetTables_612417,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_612433 = ref object of OpenApiRestCall_610658
proc url_GetTags_612435(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTags_612434(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of tags associated with a resource.
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
  var valid_612436 = header.getOrDefault("X-Amz-Target")
  valid_612436 = validateParameter(valid_612436, JString, required = true,
                                 default = newJString("AWSGlue.GetTags"))
  if valid_612436 != nil:
    section.add "X-Amz-Target", valid_612436
  var valid_612437 = header.getOrDefault("X-Amz-Signature")
  valid_612437 = validateParameter(valid_612437, JString, required = false,
                                 default = nil)
  if valid_612437 != nil:
    section.add "X-Amz-Signature", valid_612437
  var valid_612438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612438 = validateParameter(valid_612438, JString, required = false,
                                 default = nil)
  if valid_612438 != nil:
    section.add "X-Amz-Content-Sha256", valid_612438
  var valid_612439 = header.getOrDefault("X-Amz-Date")
  valid_612439 = validateParameter(valid_612439, JString, required = false,
                                 default = nil)
  if valid_612439 != nil:
    section.add "X-Amz-Date", valid_612439
  var valid_612440 = header.getOrDefault("X-Amz-Credential")
  valid_612440 = validateParameter(valid_612440, JString, required = false,
                                 default = nil)
  if valid_612440 != nil:
    section.add "X-Amz-Credential", valid_612440
  var valid_612441 = header.getOrDefault("X-Amz-Security-Token")
  valid_612441 = validateParameter(valid_612441, JString, required = false,
                                 default = nil)
  if valid_612441 != nil:
    section.add "X-Amz-Security-Token", valid_612441
  var valid_612442 = header.getOrDefault("X-Amz-Algorithm")
  valid_612442 = validateParameter(valid_612442, JString, required = false,
                                 default = nil)
  if valid_612442 != nil:
    section.add "X-Amz-Algorithm", valid_612442
  var valid_612443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612443 = validateParameter(valid_612443, JString, required = false,
                                 default = nil)
  if valid_612443 != nil:
    section.add "X-Amz-SignedHeaders", valid_612443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612445: Call_GetTags_612433; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of tags associated with a resource.
  ## 
  let valid = call_612445.validator(path, query, header, formData, body)
  let scheme = call_612445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612445.url(scheme.get, call_612445.host, call_612445.base,
                         call_612445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612445, url, valid)

proc call*(call_612446: Call_GetTags_612433; body: JsonNode): Recallable =
  ## getTags
  ## Retrieves a list of tags associated with a resource.
  ##   body: JObject (required)
  var body_612447 = newJObject()
  if body != nil:
    body_612447 = body
  result = call_612446.call(nil, nil, nil, nil, body_612447)

var getTags* = Call_GetTags_612433(name: "getTags", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetTags",
                                validator: validate_GetTags_612434, base: "/",
                                url: url_GetTags_612435,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrigger_612448 = ref object of OpenApiRestCall_610658
proc url_GetTrigger_612450(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTrigger_612449(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the definition of a trigger.
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
  var valid_612451 = header.getOrDefault("X-Amz-Target")
  valid_612451 = validateParameter(valid_612451, JString, required = true,
                                 default = newJString("AWSGlue.GetTrigger"))
  if valid_612451 != nil:
    section.add "X-Amz-Target", valid_612451
  var valid_612452 = header.getOrDefault("X-Amz-Signature")
  valid_612452 = validateParameter(valid_612452, JString, required = false,
                                 default = nil)
  if valid_612452 != nil:
    section.add "X-Amz-Signature", valid_612452
  var valid_612453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612453 = validateParameter(valid_612453, JString, required = false,
                                 default = nil)
  if valid_612453 != nil:
    section.add "X-Amz-Content-Sha256", valid_612453
  var valid_612454 = header.getOrDefault("X-Amz-Date")
  valid_612454 = validateParameter(valid_612454, JString, required = false,
                                 default = nil)
  if valid_612454 != nil:
    section.add "X-Amz-Date", valid_612454
  var valid_612455 = header.getOrDefault("X-Amz-Credential")
  valid_612455 = validateParameter(valid_612455, JString, required = false,
                                 default = nil)
  if valid_612455 != nil:
    section.add "X-Amz-Credential", valid_612455
  var valid_612456 = header.getOrDefault("X-Amz-Security-Token")
  valid_612456 = validateParameter(valid_612456, JString, required = false,
                                 default = nil)
  if valid_612456 != nil:
    section.add "X-Amz-Security-Token", valid_612456
  var valid_612457 = header.getOrDefault("X-Amz-Algorithm")
  valid_612457 = validateParameter(valid_612457, JString, required = false,
                                 default = nil)
  if valid_612457 != nil:
    section.add "X-Amz-Algorithm", valid_612457
  var valid_612458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612458 = validateParameter(valid_612458, JString, required = false,
                                 default = nil)
  if valid_612458 != nil:
    section.add "X-Amz-SignedHeaders", valid_612458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612460: Call_GetTrigger_612448; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definition of a trigger.
  ## 
  let valid = call_612460.validator(path, query, header, formData, body)
  let scheme = call_612460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612460.url(scheme.get, call_612460.host, call_612460.base,
                         call_612460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612460, url, valid)

proc call*(call_612461: Call_GetTrigger_612448; body: JsonNode): Recallable =
  ## getTrigger
  ## Retrieves the definition of a trigger.
  ##   body: JObject (required)
  var body_612462 = newJObject()
  if body != nil:
    body_612462 = body
  result = call_612461.call(nil, nil, nil, nil, body_612462)

var getTrigger* = Call_GetTrigger_612448(name: "getTrigger",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetTrigger",
                                      validator: validate_GetTrigger_612449,
                                      base: "/", url: url_GetTrigger_612450,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTriggers_612463 = ref object of OpenApiRestCall_610658
proc url_GetTriggers_612465(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTriggers_612464(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets all the triggers associated with a job.
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
  var valid_612466 = query.getOrDefault("MaxResults")
  valid_612466 = validateParameter(valid_612466, JString, required = false,
                                 default = nil)
  if valid_612466 != nil:
    section.add "MaxResults", valid_612466
  var valid_612467 = query.getOrDefault("NextToken")
  valid_612467 = validateParameter(valid_612467, JString, required = false,
                                 default = nil)
  if valid_612467 != nil:
    section.add "NextToken", valid_612467
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
  var valid_612468 = header.getOrDefault("X-Amz-Target")
  valid_612468 = validateParameter(valid_612468, JString, required = true,
                                 default = newJString("AWSGlue.GetTriggers"))
  if valid_612468 != nil:
    section.add "X-Amz-Target", valid_612468
  var valid_612469 = header.getOrDefault("X-Amz-Signature")
  valid_612469 = validateParameter(valid_612469, JString, required = false,
                                 default = nil)
  if valid_612469 != nil:
    section.add "X-Amz-Signature", valid_612469
  var valid_612470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612470 = validateParameter(valid_612470, JString, required = false,
                                 default = nil)
  if valid_612470 != nil:
    section.add "X-Amz-Content-Sha256", valid_612470
  var valid_612471 = header.getOrDefault("X-Amz-Date")
  valid_612471 = validateParameter(valid_612471, JString, required = false,
                                 default = nil)
  if valid_612471 != nil:
    section.add "X-Amz-Date", valid_612471
  var valid_612472 = header.getOrDefault("X-Amz-Credential")
  valid_612472 = validateParameter(valid_612472, JString, required = false,
                                 default = nil)
  if valid_612472 != nil:
    section.add "X-Amz-Credential", valid_612472
  var valid_612473 = header.getOrDefault("X-Amz-Security-Token")
  valid_612473 = validateParameter(valid_612473, JString, required = false,
                                 default = nil)
  if valid_612473 != nil:
    section.add "X-Amz-Security-Token", valid_612473
  var valid_612474 = header.getOrDefault("X-Amz-Algorithm")
  valid_612474 = validateParameter(valid_612474, JString, required = false,
                                 default = nil)
  if valid_612474 != nil:
    section.add "X-Amz-Algorithm", valid_612474
  var valid_612475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612475 = validateParameter(valid_612475, JString, required = false,
                                 default = nil)
  if valid_612475 != nil:
    section.add "X-Amz-SignedHeaders", valid_612475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612477: Call_GetTriggers_612463; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the triggers associated with a job.
  ## 
  let valid = call_612477.validator(path, query, header, formData, body)
  let scheme = call_612477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612477.url(scheme.get, call_612477.host, call_612477.base,
                         call_612477.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612477, url, valid)

proc call*(call_612478: Call_GetTriggers_612463; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getTriggers
  ## Gets all the triggers associated with a job.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612479 = newJObject()
  var body_612480 = newJObject()
  add(query_612479, "MaxResults", newJString(MaxResults))
  add(query_612479, "NextToken", newJString(NextToken))
  if body != nil:
    body_612480 = body
  result = call_612478.call(nil, query_612479, nil, nil, body_612480)

var getTriggers* = Call_GetTriggers_612463(name: "getTriggers",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetTriggers",
                                        validator: validate_GetTriggers_612464,
                                        base: "/", url: url_GetTriggers_612465,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserDefinedFunction_612481 = ref object of OpenApiRestCall_610658
proc url_GetUserDefinedFunction_612483(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUserDefinedFunction_612482(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a specified function definition from the Data Catalog.
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
  var valid_612484 = header.getOrDefault("X-Amz-Target")
  valid_612484 = validateParameter(valid_612484, JString, required = true, default = newJString(
      "AWSGlue.GetUserDefinedFunction"))
  if valid_612484 != nil:
    section.add "X-Amz-Target", valid_612484
  var valid_612485 = header.getOrDefault("X-Amz-Signature")
  valid_612485 = validateParameter(valid_612485, JString, required = false,
                                 default = nil)
  if valid_612485 != nil:
    section.add "X-Amz-Signature", valid_612485
  var valid_612486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612486 = validateParameter(valid_612486, JString, required = false,
                                 default = nil)
  if valid_612486 != nil:
    section.add "X-Amz-Content-Sha256", valid_612486
  var valid_612487 = header.getOrDefault("X-Amz-Date")
  valid_612487 = validateParameter(valid_612487, JString, required = false,
                                 default = nil)
  if valid_612487 != nil:
    section.add "X-Amz-Date", valid_612487
  var valid_612488 = header.getOrDefault("X-Amz-Credential")
  valid_612488 = validateParameter(valid_612488, JString, required = false,
                                 default = nil)
  if valid_612488 != nil:
    section.add "X-Amz-Credential", valid_612488
  var valid_612489 = header.getOrDefault("X-Amz-Security-Token")
  valid_612489 = validateParameter(valid_612489, JString, required = false,
                                 default = nil)
  if valid_612489 != nil:
    section.add "X-Amz-Security-Token", valid_612489
  var valid_612490 = header.getOrDefault("X-Amz-Algorithm")
  valid_612490 = validateParameter(valid_612490, JString, required = false,
                                 default = nil)
  if valid_612490 != nil:
    section.add "X-Amz-Algorithm", valid_612490
  var valid_612491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612491 = validateParameter(valid_612491, JString, required = false,
                                 default = nil)
  if valid_612491 != nil:
    section.add "X-Amz-SignedHeaders", valid_612491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612493: Call_GetUserDefinedFunction_612481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified function definition from the Data Catalog.
  ## 
  let valid = call_612493.validator(path, query, header, formData, body)
  let scheme = call_612493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612493.url(scheme.get, call_612493.host, call_612493.base,
                         call_612493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612493, url, valid)

proc call*(call_612494: Call_GetUserDefinedFunction_612481; body: JsonNode): Recallable =
  ## getUserDefinedFunction
  ## Retrieves a specified function definition from the Data Catalog.
  ##   body: JObject (required)
  var body_612495 = newJObject()
  if body != nil:
    body_612495 = body
  result = call_612494.call(nil, nil, nil, nil, body_612495)

var getUserDefinedFunction* = Call_GetUserDefinedFunction_612481(
    name: "getUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetUserDefinedFunction",
    validator: validate_GetUserDefinedFunction_612482, base: "/",
    url: url_GetUserDefinedFunction_612483, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserDefinedFunctions_612496 = ref object of OpenApiRestCall_610658
proc url_GetUserDefinedFunctions_612498(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUserDefinedFunctions_612497(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves multiple function definitions from the Data Catalog.
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
  var valid_612499 = query.getOrDefault("MaxResults")
  valid_612499 = validateParameter(valid_612499, JString, required = false,
                                 default = nil)
  if valid_612499 != nil:
    section.add "MaxResults", valid_612499
  var valid_612500 = query.getOrDefault("NextToken")
  valid_612500 = validateParameter(valid_612500, JString, required = false,
                                 default = nil)
  if valid_612500 != nil:
    section.add "NextToken", valid_612500
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
  var valid_612501 = header.getOrDefault("X-Amz-Target")
  valid_612501 = validateParameter(valid_612501, JString, required = true, default = newJString(
      "AWSGlue.GetUserDefinedFunctions"))
  if valid_612501 != nil:
    section.add "X-Amz-Target", valid_612501
  var valid_612502 = header.getOrDefault("X-Amz-Signature")
  valid_612502 = validateParameter(valid_612502, JString, required = false,
                                 default = nil)
  if valid_612502 != nil:
    section.add "X-Amz-Signature", valid_612502
  var valid_612503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612503 = validateParameter(valid_612503, JString, required = false,
                                 default = nil)
  if valid_612503 != nil:
    section.add "X-Amz-Content-Sha256", valid_612503
  var valid_612504 = header.getOrDefault("X-Amz-Date")
  valid_612504 = validateParameter(valid_612504, JString, required = false,
                                 default = nil)
  if valid_612504 != nil:
    section.add "X-Amz-Date", valid_612504
  var valid_612505 = header.getOrDefault("X-Amz-Credential")
  valid_612505 = validateParameter(valid_612505, JString, required = false,
                                 default = nil)
  if valid_612505 != nil:
    section.add "X-Amz-Credential", valid_612505
  var valid_612506 = header.getOrDefault("X-Amz-Security-Token")
  valid_612506 = validateParameter(valid_612506, JString, required = false,
                                 default = nil)
  if valid_612506 != nil:
    section.add "X-Amz-Security-Token", valid_612506
  var valid_612507 = header.getOrDefault("X-Amz-Algorithm")
  valid_612507 = validateParameter(valid_612507, JString, required = false,
                                 default = nil)
  if valid_612507 != nil:
    section.add "X-Amz-Algorithm", valid_612507
  var valid_612508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612508 = validateParameter(valid_612508, JString, required = false,
                                 default = nil)
  if valid_612508 != nil:
    section.add "X-Amz-SignedHeaders", valid_612508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612510: Call_GetUserDefinedFunctions_612496; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves multiple function definitions from the Data Catalog.
  ## 
  let valid = call_612510.validator(path, query, header, formData, body)
  let scheme = call_612510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612510.url(scheme.get, call_612510.host, call_612510.base,
                         call_612510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612510, url, valid)

proc call*(call_612511: Call_GetUserDefinedFunctions_612496; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getUserDefinedFunctions
  ## Retrieves multiple function definitions from the Data Catalog.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612512 = newJObject()
  var body_612513 = newJObject()
  add(query_612512, "MaxResults", newJString(MaxResults))
  add(query_612512, "NextToken", newJString(NextToken))
  if body != nil:
    body_612513 = body
  result = call_612511.call(nil, query_612512, nil, nil, body_612513)

var getUserDefinedFunctions* = Call_GetUserDefinedFunctions_612496(
    name: "getUserDefinedFunctions", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetUserDefinedFunctions",
    validator: validate_GetUserDefinedFunctions_612497, base: "/",
    url: url_GetUserDefinedFunctions_612498, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflow_612514 = ref object of OpenApiRestCall_610658
proc url_GetWorkflow_612516(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetWorkflow_612515(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves resource metadata for a workflow.
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
  var valid_612517 = header.getOrDefault("X-Amz-Target")
  valid_612517 = validateParameter(valid_612517, JString, required = true,
                                 default = newJString("AWSGlue.GetWorkflow"))
  if valid_612517 != nil:
    section.add "X-Amz-Target", valid_612517
  var valid_612518 = header.getOrDefault("X-Amz-Signature")
  valid_612518 = validateParameter(valid_612518, JString, required = false,
                                 default = nil)
  if valid_612518 != nil:
    section.add "X-Amz-Signature", valid_612518
  var valid_612519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612519 = validateParameter(valid_612519, JString, required = false,
                                 default = nil)
  if valid_612519 != nil:
    section.add "X-Amz-Content-Sha256", valid_612519
  var valid_612520 = header.getOrDefault("X-Amz-Date")
  valid_612520 = validateParameter(valid_612520, JString, required = false,
                                 default = nil)
  if valid_612520 != nil:
    section.add "X-Amz-Date", valid_612520
  var valid_612521 = header.getOrDefault("X-Amz-Credential")
  valid_612521 = validateParameter(valid_612521, JString, required = false,
                                 default = nil)
  if valid_612521 != nil:
    section.add "X-Amz-Credential", valid_612521
  var valid_612522 = header.getOrDefault("X-Amz-Security-Token")
  valid_612522 = validateParameter(valid_612522, JString, required = false,
                                 default = nil)
  if valid_612522 != nil:
    section.add "X-Amz-Security-Token", valid_612522
  var valid_612523 = header.getOrDefault("X-Amz-Algorithm")
  valid_612523 = validateParameter(valid_612523, JString, required = false,
                                 default = nil)
  if valid_612523 != nil:
    section.add "X-Amz-Algorithm", valid_612523
  var valid_612524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612524 = validateParameter(valid_612524, JString, required = false,
                                 default = nil)
  if valid_612524 != nil:
    section.add "X-Amz-SignedHeaders", valid_612524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612526: Call_GetWorkflow_612514; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves resource metadata for a workflow.
  ## 
  let valid = call_612526.validator(path, query, header, formData, body)
  let scheme = call_612526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612526.url(scheme.get, call_612526.host, call_612526.base,
                         call_612526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612526, url, valid)

proc call*(call_612527: Call_GetWorkflow_612514; body: JsonNode): Recallable =
  ## getWorkflow
  ## Retrieves resource metadata for a workflow.
  ##   body: JObject (required)
  var body_612528 = newJObject()
  if body != nil:
    body_612528 = body
  result = call_612527.call(nil, nil, nil, nil, body_612528)

var getWorkflow* = Call_GetWorkflow_612514(name: "getWorkflow",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetWorkflow",
                                        validator: validate_GetWorkflow_612515,
                                        base: "/", url: url_GetWorkflow_612516,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRun_612529 = ref object of OpenApiRestCall_610658
proc url_GetWorkflowRun_612531(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetWorkflowRun_612530(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves the metadata for a given workflow run. 
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
  var valid_612532 = header.getOrDefault("X-Amz-Target")
  valid_612532 = validateParameter(valid_612532, JString, required = true,
                                 default = newJString("AWSGlue.GetWorkflowRun"))
  if valid_612532 != nil:
    section.add "X-Amz-Target", valid_612532
  var valid_612533 = header.getOrDefault("X-Amz-Signature")
  valid_612533 = validateParameter(valid_612533, JString, required = false,
                                 default = nil)
  if valid_612533 != nil:
    section.add "X-Amz-Signature", valid_612533
  var valid_612534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612534 = validateParameter(valid_612534, JString, required = false,
                                 default = nil)
  if valid_612534 != nil:
    section.add "X-Amz-Content-Sha256", valid_612534
  var valid_612535 = header.getOrDefault("X-Amz-Date")
  valid_612535 = validateParameter(valid_612535, JString, required = false,
                                 default = nil)
  if valid_612535 != nil:
    section.add "X-Amz-Date", valid_612535
  var valid_612536 = header.getOrDefault("X-Amz-Credential")
  valid_612536 = validateParameter(valid_612536, JString, required = false,
                                 default = nil)
  if valid_612536 != nil:
    section.add "X-Amz-Credential", valid_612536
  var valid_612537 = header.getOrDefault("X-Amz-Security-Token")
  valid_612537 = validateParameter(valid_612537, JString, required = false,
                                 default = nil)
  if valid_612537 != nil:
    section.add "X-Amz-Security-Token", valid_612537
  var valid_612538 = header.getOrDefault("X-Amz-Algorithm")
  valid_612538 = validateParameter(valid_612538, JString, required = false,
                                 default = nil)
  if valid_612538 != nil:
    section.add "X-Amz-Algorithm", valid_612538
  var valid_612539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612539 = validateParameter(valid_612539, JString, required = false,
                                 default = nil)
  if valid_612539 != nil:
    section.add "X-Amz-SignedHeaders", valid_612539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612541: Call_GetWorkflowRun_612529; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the metadata for a given workflow run. 
  ## 
  let valid = call_612541.validator(path, query, header, formData, body)
  let scheme = call_612541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612541.url(scheme.get, call_612541.host, call_612541.base,
                         call_612541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612541, url, valid)

proc call*(call_612542: Call_GetWorkflowRun_612529; body: JsonNode): Recallable =
  ## getWorkflowRun
  ## Retrieves the metadata for a given workflow run. 
  ##   body: JObject (required)
  var body_612543 = newJObject()
  if body != nil:
    body_612543 = body
  result = call_612542.call(nil, nil, nil, nil, body_612543)

var getWorkflowRun* = Call_GetWorkflowRun_612529(name: "getWorkflowRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRun",
    validator: validate_GetWorkflowRun_612530, base: "/", url: url_GetWorkflowRun_612531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRunProperties_612544 = ref object of OpenApiRestCall_610658
proc url_GetWorkflowRunProperties_612546(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetWorkflowRunProperties_612545(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the workflow run properties which were set during the run.
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
  var valid_612547 = header.getOrDefault("X-Amz-Target")
  valid_612547 = validateParameter(valid_612547, JString, required = true, default = newJString(
      "AWSGlue.GetWorkflowRunProperties"))
  if valid_612547 != nil:
    section.add "X-Amz-Target", valid_612547
  var valid_612548 = header.getOrDefault("X-Amz-Signature")
  valid_612548 = validateParameter(valid_612548, JString, required = false,
                                 default = nil)
  if valid_612548 != nil:
    section.add "X-Amz-Signature", valid_612548
  var valid_612549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612549 = validateParameter(valid_612549, JString, required = false,
                                 default = nil)
  if valid_612549 != nil:
    section.add "X-Amz-Content-Sha256", valid_612549
  var valid_612550 = header.getOrDefault("X-Amz-Date")
  valid_612550 = validateParameter(valid_612550, JString, required = false,
                                 default = nil)
  if valid_612550 != nil:
    section.add "X-Amz-Date", valid_612550
  var valid_612551 = header.getOrDefault("X-Amz-Credential")
  valid_612551 = validateParameter(valid_612551, JString, required = false,
                                 default = nil)
  if valid_612551 != nil:
    section.add "X-Amz-Credential", valid_612551
  var valid_612552 = header.getOrDefault("X-Amz-Security-Token")
  valid_612552 = validateParameter(valid_612552, JString, required = false,
                                 default = nil)
  if valid_612552 != nil:
    section.add "X-Amz-Security-Token", valid_612552
  var valid_612553 = header.getOrDefault("X-Amz-Algorithm")
  valid_612553 = validateParameter(valid_612553, JString, required = false,
                                 default = nil)
  if valid_612553 != nil:
    section.add "X-Amz-Algorithm", valid_612553
  var valid_612554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612554 = validateParameter(valid_612554, JString, required = false,
                                 default = nil)
  if valid_612554 != nil:
    section.add "X-Amz-SignedHeaders", valid_612554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612556: Call_GetWorkflowRunProperties_612544; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the workflow run properties which were set during the run.
  ## 
  let valid = call_612556.validator(path, query, header, formData, body)
  let scheme = call_612556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612556.url(scheme.get, call_612556.host, call_612556.base,
                         call_612556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612556, url, valid)

proc call*(call_612557: Call_GetWorkflowRunProperties_612544; body: JsonNode): Recallable =
  ## getWorkflowRunProperties
  ## Retrieves the workflow run properties which were set during the run.
  ##   body: JObject (required)
  var body_612558 = newJObject()
  if body != nil:
    body_612558 = body
  result = call_612557.call(nil, nil, nil, nil, body_612558)

var getWorkflowRunProperties* = Call_GetWorkflowRunProperties_612544(
    name: "getWorkflowRunProperties", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRunProperties",
    validator: validate_GetWorkflowRunProperties_612545, base: "/",
    url: url_GetWorkflowRunProperties_612546, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRuns_612559 = ref object of OpenApiRestCall_610658
proc url_GetWorkflowRuns_612561(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetWorkflowRuns_612560(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Retrieves metadata for all runs of a given workflow.
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
  var valid_612562 = query.getOrDefault("MaxResults")
  valid_612562 = validateParameter(valid_612562, JString, required = false,
                                 default = nil)
  if valid_612562 != nil:
    section.add "MaxResults", valid_612562
  var valid_612563 = query.getOrDefault("NextToken")
  valid_612563 = validateParameter(valid_612563, JString, required = false,
                                 default = nil)
  if valid_612563 != nil:
    section.add "NextToken", valid_612563
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
  var valid_612564 = header.getOrDefault("X-Amz-Target")
  valid_612564 = validateParameter(valid_612564, JString, required = true, default = newJString(
      "AWSGlue.GetWorkflowRuns"))
  if valid_612564 != nil:
    section.add "X-Amz-Target", valid_612564
  var valid_612565 = header.getOrDefault("X-Amz-Signature")
  valid_612565 = validateParameter(valid_612565, JString, required = false,
                                 default = nil)
  if valid_612565 != nil:
    section.add "X-Amz-Signature", valid_612565
  var valid_612566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612566 = validateParameter(valid_612566, JString, required = false,
                                 default = nil)
  if valid_612566 != nil:
    section.add "X-Amz-Content-Sha256", valid_612566
  var valid_612567 = header.getOrDefault("X-Amz-Date")
  valid_612567 = validateParameter(valid_612567, JString, required = false,
                                 default = nil)
  if valid_612567 != nil:
    section.add "X-Amz-Date", valid_612567
  var valid_612568 = header.getOrDefault("X-Amz-Credential")
  valid_612568 = validateParameter(valid_612568, JString, required = false,
                                 default = nil)
  if valid_612568 != nil:
    section.add "X-Amz-Credential", valid_612568
  var valid_612569 = header.getOrDefault("X-Amz-Security-Token")
  valid_612569 = validateParameter(valid_612569, JString, required = false,
                                 default = nil)
  if valid_612569 != nil:
    section.add "X-Amz-Security-Token", valid_612569
  var valid_612570 = header.getOrDefault("X-Amz-Algorithm")
  valid_612570 = validateParameter(valid_612570, JString, required = false,
                                 default = nil)
  if valid_612570 != nil:
    section.add "X-Amz-Algorithm", valid_612570
  var valid_612571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612571 = validateParameter(valid_612571, JString, required = false,
                                 default = nil)
  if valid_612571 != nil:
    section.add "X-Amz-SignedHeaders", valid_612571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612573: Call_GetWorkflowRuns_612559; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all runs of a given workflow.
  ## 
  let valid = call_612573.validator(path, query, header, formData, body)
  let scheme = call_612573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612573.url(scheme.get, call_612573.host, call_612573.base,
                         call_612573.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612573, url, valid)

proc call*(call_612574: Call_GetWorkflowRuns_612559; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getWorkflowRuns
  ## Retrieves metadata for all runs of a given workflow.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612575 = newJObject()
  var body_612576 = newJObject()
  add(query_612575, "MaxResults", newJString(MaxResults))
  add(query_612575, "NextToken", newJString(NextToken))
  if body != nil:
    body_612576 = body
  result = call_612574.call(nil, query_612575, nil, nil, body_612576)

var getWorkflowRuns* = Call_GetWorkflowRuns_612559(name: "getWorkflowRuns",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRuns",
    validator: validate_GetWorkflowRuns_612560, base: "/", url: url_GetWorkflowRuns_612561,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportCatalogToGlue_612577 = ref object of OpenApiRestCall_610658
proc url_ImportCatalogToGlue_612579(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportCatalogToGlue_612578(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
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
  var valid_612580 = header.getOrDefault("X-Amz-Target")
  valid_612580 = validateParameter(valid_612580, JString, required = true, default = newJString(
      "AWSGlue.ImportCatalogToGlue"))
  if valid_612580 != nil:
    section.add "X-Amz-Target", valid_612580
  var valid_612581 = header.getOrDefault("X-Amz-Signature")
  valid_612581 = validateParameter(valid_612581, JString, required = false,
                                 default = nil)
  if valid_612581 != nil:
    section.add "X-Amz-Signature", valid_612581
  var valid_612582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612582 = validateParameter(valid_612582, JString, required = false,
                                 default = nil)
  if valid_612582 != nil:
    section.add "X-Amz-Content-Sha256", valid_612582
  var valid_612583 = header.getOrDefault("X-Amz-Date")
  valid_612583 = validateParameter(valid_612583, JString, required = false,
                                 default = nil)
  if valid_612583 != nil:
    section.add "X-Amz-Date", valid_612583
  var valid_612584 = header.getOrDefault("X-Amz-Credential")
  valid_612584 = validateParameter(valid_612584, JString, required = false,
                                 default = nil)
  if valid_612584 != nil:
    section.add "X-Amz-Credential", valid_612584
  var valid_612585 = header.getOrDefault("X-Amz-Security-Token")
  valid_612585 = validateParameter(valid_612585, JString, required = false,
                                 default = nil)
  if valid_612585 != nil:
    section.add "X-Amz-Security-Token", valid_612585
  var valid_612586 = header.getOrDefault("X-Amz-Algorithm")
  valid_612586 = validateParameter(valid_612586, JString, required = false,
                                 default = nil)
  if valid_612586 != nil:
    section.add "X-Amz-Algorithm", valid_612586
  var valid_612587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612587 = validateParameter(valid_612587, JString, required = false,
                                 default = nil)
  if valid_612587 != nil:
    section.add "X-Amz-SignedHeaders", valid_612587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612589: Call_ImportCatalogToGlue_612577; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
  ## 
  let valid = call_612589.validator(path, query, header, formData, body)
  let scheme = call_612589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612589.url(scheme.get, call_612589.host, call_612589.base,
                         call_612589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612589, url, valid)

proc call*(call_612590: Call_ImportCatalogToGlue_612577; body: JsonNode): Recallable =
  ## importCatalogToGlue
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
  ##   body: JObject (required)
  var body_612591 = newJObject()
  if body != nil:
    body_612591 = body
  result = call_612590.call(nil, nil, nil, nil, body_612591)

var importCatalogToGlue* = Call_ImportCatalogToGlue_612577(
    name: "importCatalogToGlue", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ImportCatalogToGlue",
    validator: validate_ImportCatalogToGlue_612578, base: "/",
    url: url_ImportCatalogToGlue_612579, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCrawlers_612592 = ref object of OpenApiRestCall_610658
proc url_ListCrawlers_612594(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCrawlers_612593(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
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
  var valid_612595 = query.getOrDefault("MaxResults")
  valid_612595 = validateParameter(valid_612595, JString, required = false,
                                 default = nil)
  if valid_612595 != nil:
    section.add "MaxResults", valid_612595
  var valid_612596 = query.getOrDefault("NextToken")
  valid_612596 = validateParameter(valid_612596, JString, required = false,
                                 default = nil)
  if valid_612596 != nil:
    section.add "NextToken", valid_612596
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
  var valid_612597 = header.getOrDefault("X-Amz-Target")
  valid_612597 = validateParameter(valid_612597, JString, required = true,
                                 default = newJString("AWSGlue.ListCrawlers"))
  if valid_612597 != nil:
    section.add "X-Amz-Target", valid_612597
  var valid_612598 = header.getOrDefault("X-Amz-Signature")
  valid_612598 = validateParameter(valid_612598, JString, required = false,
                                 default = nil)
  if valid_612598 != nil:
    section.add "X-Amz-Signature", valid_612598
  var valid_612599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612599 = validateParameter(valid_612599, JString, required = false,
                                 default = nil)
  if valid_612599 != nil:
    section.add "X-Amz-Content-Sha256", valid_612599
  var valid_612600 = header.getOrDefault("X-Amz-Date")
  valid_612600 = validateParameter(valid_612600, JString, required = false,
                                 default = nil)
  if valid_612600 != nil:
    section.add "X-Amz-Date", valid_612600
  var valid_612601 = header.getOrDefault("X-Amz-Credential")
  valid_612601 = validateParameter(valid_612601, JString, required = false,
                                 default = nil)
  if valid_612601 != nil:
    section.add "X-Amz-Credential", valid_612601
  var valid_612602 = header.getOrDefault("X-Amz-Security-Token")
  valid_612602 = validateParameter(valid_612602, JString, required = false,
                                 default = nil)
  if valid_612602 != nil:
    section.add "X-Amz-Security-Token", valid_612602
  var valid_612603 = header.getOrDefault("X-Amz-Algorithm")
  valid_612603 = validateParameter(valid_612603, JString, required = false,
                                 default = nil)
  if valid_612603 != nil:
    section.add "X-Amz-Algorithm", valid_612603
  var valid_612604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612604 = validateParameter(valid_612604, JString, required = false,
                                 default = nil)
  if valid_612604 != nil:
    section.add "X-Amz-SignedHeaders", valid_612604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612606: Call_ListCrawlers_612592; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_612606.validator(path, query, header, formData, body)
  let scheme = call_612606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612606.url(scheme.get, call_612606.host, call_612606.base,
                         call_612606.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612606, url, valid)

proc call*(call_612607: Call_ListCrawlers_612592; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCrawlers
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612608 = newJObject()
  var body_612609 = newJObject()
  add(query_612608, "MaxResults", newJString(MaxResults))
  add(query_612608, "NextToken", newJString(NextToken))
  if body != nil:
    body_612609 = body
  result = call_612607.call(nil, query_612608, nil, nil, body_612609)

var listCrawlers* = Call_ListCrawlers_612592(name: "listCrawlers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListCrawlers",
    validator: validate_ListCrawlers_612593, base: "/", url: url_ListCrawlers_612594,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevEndpoints_612610 = ref object of OpenApiRestCall_610658
proc url_ListDevEndpoints_612612(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDevEndpoints_612611(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
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
  var valid_612613 = query.getOrDefault("MaxResults")
  valid_612613 = validateParameter(valid_612613, JString, required = false,
                                 default = nil)
  if valid_612613 != nil:
    section.add "MaxResults", valid_612613
  var valid_612614 = query.getOrDefault("NextToken")
  valid_612614 = validateParameter(valid_612614, JString, required = false,
                                 default = nil)
  if valid_612614 != nil:
    section.add "NextToken", valid_612614
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
  var valid_612615 = header.getOrDefault("X-Amz-Target")
  valid_612615 = validateParameter(valid_612615, JString, required = true, default = newJString(
      "AWSGlue.ListDevEndpoints"))
  if valid_612615 != nil:
    section.add "X-Amz-Target", valid_612615
  var valid_612616 = header.getOrDefault("X-Amz-Signature")
  valid_612616 = validateParameter(valid_612616, JString, required = false,
                                 default = nil)
  if valid_612616 != nil:
    section.add "X-Amz-Signature", valid_612616
  var valid_612617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612617 = validateParameter(valid_612617, JString, required = false,
                                 default = nil)
  if valid_612617 != nil:
    section.add "X-Amz-Content-Sha256", valid_612617
  var valid_612618 = header.getOrDefault("X-Amz-Date")
  valid_612618 = validateParameter(valid_612618, JString, required = false,
                                 default = nil)
  if valid_612618 != nil:
    section.add "X-Amz-Date", valid_612618
  var valid_612619 = header.getOrDefault("X-Amz-Credential")
  valid_612619 = validateParameter(valid_612619, JString, required = false,
                                 default = nil)
  if valid_612619 != nil:
    section.add "X-Amz-Credential", valid_612619
  var valid_612620 = header.getOrDefault("X-Amz-Security-Token")
  valid_612620 = validateParameter(valid_612620, JString, required = false,
                                 default = nil)
  if valid_612620 != nil:
    section.add "X-Amz-Security-Token", valid_612620
  var valid_612621 = header.getOrDefault("X-Amz-Algorithm")
  valid_612621 = validateParameter(valid_612621, JString, required = false,
                                 default = nil)
  if valid_612621 != nil:
    section.add "X-Amz-Algorithm", valid_612621
  var valid_612622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612622 = validateParameter(valid_612622, JString, required = false,
                                 default = nil)
  if valid_612622 != nil:
    section.add "X-Amz-SignedHeaders", valid_612622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612624: Call_ListDevEndpoints_612610; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_612624.validator(path, query, header, formData, body)
  let scheme = call_612624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612624.url(scheme.get, call_612624.host, call_612624.base,
                         call_612624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612624, url, valid)

proc call*(call_612625: Call_ListDevEndpoints_612610; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDevEndpoints
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612626 = newJObject()
  var body_612627 = newJObject()
  add(query_612626, "MaxResults", newJString(MaxResults))
  add(query_612626, "NextToken", newJString(NextToken))
  if body != nil:
    body_612627 = body
  result = call_612625.call(nil, query_612626, nil, nil, body_612627)

var listDevEndpoints* = Call_ListDevEndpoints_612610(name: "listDevEndpoints",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListDevEndpoints",
    validator: validate_ListDevEndpoints_612611, base: "/",
    url: url_ListDevEndpoints_612612, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_612628 = ref object of OpenApiRestCall_610658
proc url_ListJobs_612630(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJobs_612629(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
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
  var valid_612631 = query.getOrDefault("MaxResults")
  valid_612631 = validateParameter(valid_612631, JString, required = false,
                                 default = nil)
  if valid_612631 != nil:
    section.add "MaxResults", valid_612631
  var valid_612632 = query.getOrDefault("NextToken")
  valid_612632 = validateParameter(valid_612632, JString, required = false,
                                 default = nil)
  if valid_612632 != nil:
    section.add "NextToken", valid_612632
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
  var valid_612633 = header.getOrDefault("X-Amz-Target")
  valid_612633 = validateParameter(valid_612633, JString, required = true,
                                 default = newJString("AWSGlue.ListJobs"))
  if valid_612633 != nil:
    section.add "X-Amz-Target", valid_612633
  var valid_612634 = header.getOrDefault("X-Amz-Signature")
  valid_612634 = validateParameter(valid_612634, JString, required = false,
                                 default = nil)
  if valid_612634 != nil:
    section.add "X-Amz-Signature", valid_612634
  var valid_612635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612635 = validateParameter(valid_612635, JString, required = false,
                                 default = nil)
  if valid_612635 != nil:
    section.add "X-Amz-Content-Sha256", valid_612635
  var valid_612636 = header.getOrDefault("X-Amz-Date")
  valid_612636 = validateParameter(valid_612636, JString, required = false,
                                 default = nil)
  if valid_612636 != nil:
    section.add "X-Amz-Date", valid_612636
  var valid_612637 = header.getOrDefault("X-Amz-Credential")
  valid_612637 = validateParameter(valid_612637, JString, required = false,
                                 default = nil)
  if valid_612637 != nil:
    section.add "X-Amz-Credential", valid_612637
  var valid_612638 = header.getOrDefault("X-Amz-Security-Token")
  valid_612638 = validateParameter(valid_612638, JString, required = false,
                                 default = nil)
  if valid_612638 != nil:
    section.add "X-Amz-Security-Token", valid_612638
  var valid_612639 = header.getOrDefault("X-Amz-Algorithm")
  valid_612639 = validateParameter(valid_612639, JString, required = false,
                                 default = nil)
  if valid_612639 != nil:
    section.add "X-Amz-Algorithm", valid_612639
  var valid_612640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612640 = validateParameter(valid_612640, JString, required = false,
                                 default = nil)
  if valid_612640 != nil:
    section.add "X-Amz-SignedHeaders", valid_612640
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612642: Call_ListJobs_612628; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_612642.validator(path, query, header, formData, body)
  let scheme = call_612642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612642.url(scheme.get, call_612642.host, call_612642.base,
                         call_612642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612642, url, valid)

proc call*(call_612643: Call_ListJobs_612628; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listJobs
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612644 = newJObject()
  var body_612645 = newJObject()
  add(query_612644, "MaxResults", newJString(MaxResults))
  add(query_612644, "NextToken", newJString(NextToken))
  if body != nil:
    body_612645 = body
  result = call_612643.call(nil, query_612644, nil, nil, body_612645)

var listJobs* = Call_ListJobs_612628(name: "listJobs", meth: HttpMethod.HttpPost,
                                  host: "glue.amazonaws.com",
                                  route: "/#X-Amz-Target=AWSGlue.ListJobs",
                                  validator: validate_ListJobs_612629, base: "/",
                                  url: url_ListJobs_612630,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTriggers_612646 = ref object of OpenApiRestCall_610658
proc url_ListTriggers_612648(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTriggers_612647(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
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
  var valid_612649 = query.getOrDefault("MaxResults")
  valid_612649 = validateParameter(valid_612649, JString, required = false,
                                 default = nil)
  if valid_612649 != nil:
    section.add "MaxResults", valid_612649
  var valid_612650 = query.getOrDefault("NextToken")
  valid_612650 = validateParameter(valid_612650, JString, required = false,
                                 default = nil)
  if valid_612650 != nil:
    section.add "NextToken", valid_612650
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
  var valid_612651 = header.getOrDefault("X-Amz-Target")
  valid_612651 = validateParameter(valid_612651, JString, required = true,
                                 default = newJString("AWSGlue.ListTriggers"))
  if valid_612651 != nil:
    section.add "X-Amz-Target", valid_612651
  var valid_612652 = header.getOrDefault("X-Amz-Signature")
  valid_612652 = validateParameter(valid_612652, JString, required = false,
                                 default = nil)
  if valid_612652 != nil:
    section.add "X-Amz-Signature", valid_612652
  var valid_612653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612653 = validateParameter(valid_612653, JString, required = false,
                                 default = nil)
  if valid_612653 != nil:
    section.add "X-Amz-Content-Sha256", valid_612653
  var valid_612654 = header.getOrDefault("X-Amz-Date")
  valid_612654 = validateParameter(valid_612654, JString, required = false,
                                 default = nil)
  if valid_612654 != nil:
    section.add "X-Amz-Date", valid_612654
  var valid_612655 = header.getOrDefault("X-Amz-Credential")
  valid_612655 = validateParameter(valid_612655, JString, required = false,
                                 default = nil)
  if valid_612655 != nil:
    section.add "X-Amz-Credential", valid_612655
  var valid_612656 = header.getOrDefault("X-Amz-Security-Token")
  valid_612656 = validateParameter(valid_612656, JString, required = false,
                                 default = nil)
  if valid_612656 != nil:
    section.add "X-Amz-Security-Token", valid_612656
  var valid_612657 = header.getOrDefault("X-Amz-Algorithm")
  valid_612657 = validateParameter(valid_612657, JString, required = false,
                                 default = nil)
  if valid_612657 != nil:
    section.add "X-Amz-Algorithm", valid_612657
  var valid_612658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612658 = validateParameter(valid_612658, JString, required = false,
                                 default = nil)
  if valid_612658 != nil:
    section.add "X-Amz-SignedHeaders", valid_612658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612660: Call_ListTriggers_612646; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_612660.validator(path, query, header, formData, body)
  let scheme = call_612660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612660.url(scheme.get, call_612660.host, call_612660.base,
                         call_612660.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612660, url, valid)

proc call*(call_612661: Call_ListTriggers_612646; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTriggers
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612662 = newJObject()
  var body_612663 = newJObject()
  add(query_612662, "MaxResults", newJString(MaxResults))
  add(query_612662, "NextToken", newJString(NextToken))
  if body != nil:
    body_612663 = body
  result = call_612661.call(nil, query_612662, nil, nil, body_612663)

var listTriggers* = Call_ListTriggers_612646(name: "listTriggers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListTriggers",
    validator: validate_ListTriggers_612647, base: "/", url: url_ListTriggers_612648,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkflows_612664 = ref object of OpenApiRestCall_610658
proc url_ListWorkflows_612666(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListWorkflows_612665(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists names of workflows created in the account.
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
  var valid_612667 = query.getOrDefault("MaxResults")
  valid_612667 = validateParameter(valid_612667, JString, required = false,
                                 default = nil)
  if valid_612667 != nil:
    section.add "MaxResults", valid_612667
  var valid_612668 = query.getOrDefault("NextToken")
  valid_612668 = validateParameter(valid_612668, JString, required = false,
                                 default = nil)
  if valid_612668 != nil:
    section.add "NextToken", valid_612668
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
  var valid_612669 = header.getOrDefault("X-Amz-Target")
  valid_612669 = validateParameter(valid_612669, JString, required = true,
                                 default = newJString("AWSGlue.ListWorkflows"))
  if valid_612669 != nil:
    section.add "X-Amz-Target", valid_612669
  var valid_612670 = header.getOrDefault("X-Amz-Signature")
  valid_612670 = validateParameter(valid_612670, JString, required = false,
                                 default = nil)
  if valid_612670 != nil:
    section.add "X-Amz-Signature", valid_612670
  var valid_612671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612671 = validateParameter(valid_612671, JString, required = false,
                                 default = nil)
  if valid_612671 != nil:
    section.add "X-Amz-Content-Sha256", valid_612671
  var valid_612672 = header.getOrDefault("X-Amz-Date")
  valid_612672 = validateParameter(valid_612672, JString, required = false,
                                 default = nil)
  if valid_612672 != nil:
    section.add "X-Amz-Date", valid_612672
  var valid_612673 = header.getOrDefault("X-Amz-Credential")
  valid_612673 = validateParameter(valid_612673, JString, required = false,
                                 default = nil)
  if valid_612673 != nil:
    section.add "X-Amz-Credential", valid_612673
  var valid_612674 = header.getOrDefault("X-Amz-Security-Token")
  valid_612674 = validateParameter(valid_612674, JString, required = false,
                                 default = nil)
  if valid_612674 != nil:
    section.add "X-Amz-Security-Token", valid_612674
  var valid_612675 = header.getOrDefault("X-Amz-Algorithm")
  valid_612675 = validateParameter(valid_612675, JString, required = false,
                                 default = nil)
  if valid_612675 != nil:
    section.add "X-Amz-Algorithm", valid_612675
  var valid_612676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612676 = validateParameter(valid_612676, JString, required = false,
                                 default = nil)
  if valid_612676 != nil:
    section.add "X-Amz-SignedHeaders", valid_612676
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612678: Call_ListWorkflows_612664; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists names of workflows created in the account.
  ## 
  let valid = call_612678.validator(path, query, header, formData, body)
  let scheme = call_612678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612678.url(scheme.get, call_612678.host, call_612678.base,
                         call_612678.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612678, url, valid)

proc call*(call_612679: Call_ListWorkflows_612664; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listWorkflows
  ## Lists names of workflows created in the account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612680 = newJObject()
  var body_612681 = newJObject()
  add(query_612680, "MaxResults", newJString(MaxResults))
  add(query_612680, "NextToken", newJString(NextToken))
  if body != nil:
    body_612681 = body
  result = call_612679.call(nil, query_612680, nil, nil, body_612681)

var listWorkflows* = Call_ListWorkflows_612664(name: "listWorkflows",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListWorkflows",
    validator: validate_ListWorkflows_612665, base: "/", url: url_ListWorkflows_612666,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDataCatalogEncryptionSettings_612682 = ref object of OpenApiRestCall_610658
proc url_PutDataCatalogEncryptionSettings_612684(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutDataCatalogEncryptionSettings_612683(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
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
  var valid_612685 = header.getOrDefault("X-Amz-Target")
  valid_612685 = validateParameter(valid_612685, JString, required = true, default = newJString(
      "AWSGlue.PutDataCatalogEncryptionSettings"))
  if valid_612685 != nil:
    section.add "X-Amz-Target", valid_612685
  var valid_612686 = header.getOrDefault("X-Amz-Signature")
  valid_612686 = validateParameter(valid_612686, JString, required = false,
                                 default = nil)
  if valid_612686 != nil:
    section.add "X-Amz-Signature", valid_612686
  var valid_612687 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612687 = validateParameter(valid_612687, JString, required = false,
                                 default = nil)
  if valid_612687 != nil:
    section.add "X-Amz-Content-Sha256", valid_612687
  var valid_612688 = header.getOrDefault("X-Amz-Date")
  valid_612688 = validateParameter(valid_612688, JString, required = false,
                                 default = nil)
  if valid_612688 != nil:
    section.add "X-Amz-Date", valid_612688
  var valid_612689 = header.getOrDefault("X-Amz-Credential")
  valid_612689 = validateParameter(valid_612689, JString, required = false,
                                 default = nil)
  if valid_612689 != nil:
    section.add "X-Amz-Credential", valid_612689
  var valid_612690 = header.getOrDefault("X-Amz-Security-Token")
  valid_612690 = validateParameter(valid_612690, JString, required = false,
                                 default = nil)
  if valid_612690 != nil:
    section.add "X-Amz-Security-Token", valid_612690
  var valid_612691 = header.getOrDefault("X-Amz-Algorithm")
  valid_612691 = validateParameter(valid_612691, JString, required = false,
                                 default = nil)
  if valid_612691 != nil:
    section.add "X-Amz-Algorithm", valid_612691
  var valid_612692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612692 = validateParameter(valid_612692, JString, required = false,
                                 default = nil)
  if valid_612692 != nil:
    section.add "X-Amz-SignedHeaders", valid_612692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612694: Call_PutDataCatalogEncryptionSettings_612682;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
  ## 
  let valid = call_612694.validator(path, query, header, formData, body)
  let scheme = call_612694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612694.url(scheme.get, call_612694.host, call_612694.base,
                         call_612694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612694, url, valid)

proc call*(call_612695: Call_PutDataCatalogEncryptionSettings_612682;
          body: JsonNode): Recallable =
  ## putDataCatalogEncryptionSettings
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
  ##   body: JObject (required)
  var body_612696 = newJObject()
  if body != nil:
    body_612696 = body
  result = call_612695.call(nil, nil, nil, nil, body_612696)

var putDataCatalogEncryptionSettings* = Call_PutDataCatalogEncryptionSettings_612682(
    name: "putDataCatalogEncryptionSettings", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutDataCatalogEncryptionSettings",
    validator: validate_PutDataCatalogEncryptionSettings_612683, base: "/",
    url: url_PutDataCatalogEncryptionSettings_612684,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResourcePolicy_612697 = ref object of OpenApiRestCall_610658
proc url_PutResourcePolicy_612699(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutResourcePolicy_612698(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Sets the Data Catalog resource policy for access control.
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
  var valid_612700 = header.getOrDefault("X-Amz-Target")
  valid_612700 = validateParameter(valid_612700, JString, required = true, default = newJString(
      "AWSGlue.PutResourcePolicy"))
  if valid_612700 != nil:
    section.add "X-Amz-Target", valid_612700
  var valid_612701 = header.getOrDefault("X-Amz-Signature")
  valid_612701 = validateParameter(valid_612701, JString, required = false,
                                 default = nil)
  if valid_612701 != nil:
    section.add "X-Amz-Signature", valid_612701
  var valid_612702 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612702 = validateParameter(valid_612702, JString, required = false,
                                 default = nil)
  if valid_612702 != nil:
    section.add "X-Amz-Content-Sha256", valid_612702
  var valid_612703 = header.getOrDefault("X-Amz-Date")
  valid_612703 = validateParameter(valid_612703, JString, required = false,
                                 default = nil)
  if valid_612703 != nil:
    section.add "X-Amz-Date", valid_612703
  var valid_612704 = header.getOrDefault("X-Amz-Credential")
  valid_612704 = validateParameter(valid_612704, JString, required = false,
                                 default = nil)
  if valid_612704 != nil:
    section.add "X-Amz-Credential", valid_612704
  var valid_612705 = header.getOrDefault("X-Amz-Security-Token")
  valid_612705 = validateParameter(valid_612705, JString, required = false,
                                 default = nil)
  if valid_612705 != nil:
    section.add "X-Amz-Security-Token", valid_612705
  var valid_612706 = header.getOrDefault("X-Amz-Algorithm")
  valid_612706 = validateParameter(valid_612706, JString, required = false,
                                 default = nil)
  if valid_612706 != nil:
    section.add "X-Amz-Algorithm", valid_612706
  var valid_612707 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612707 = validateParameter(valid_612707, JString, required = false,
                                 default = nil)
  if valid_612707 != nil:
    section.add "X-Amz-SignedHeaders", valid_612707
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612709: Call_PutResourcePolicy_612697; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the Data Catalog resource policy for access control.
  ## 
  let valid = call_612709.validator(path, query, header, formData, body)
  let scheme = call_612709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612709.url(scheme.get, call_612709.host, call_612709.base,
                         call_612709.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612709, url, valid)

proc call*(call_612710: Call_PutResourcePolicy_612697; body: JsonNode): Recallable =
  ## putResourcePolicy
  ## Sets the Data Catalog resource policy for access control.
  ##   body: JObject (required)
  var body_612711 = newJObject()
  if body != nil:
    body_612711 = body
  result = call_612710.call(nil, nil, nil, nil, body_612711)

var putResourcePolicy* = Call_PutResourcePolicy_612697(name: "putResourcePolicy",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutResourcePolicy",
    validator: validate_PutResourcePolicy_612698, base: "/",
    url: url_PutResourcePolicy_612699, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutWorkflowRunProperties_612712 = ref object of OpenApiRestCall_610658
proc url_PutWorkflowRunProperties_612714(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutWorkflowRunProperties_612713(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
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
  var valid_612715 = header.getOrDefault("X-Amz-Target")
  valid_612715 = validateParameter(valid_612715, JString, required = true, default = newJString(
      "AWSGlue.PutWorkflowRunProperties"))
  if valid_612715 != nil:
    section.add "X-Amz-Target", valid_612715
  var valid_612716 = header.getOrDefault("X-Amz-Signature")
  valid_612716 = validateParameter(valid_612716, JString, required = false,
                                 default = nil)
  if valid_612716 != nil:
    section.add "X-Amz-Signature", valid_612716
  var valid_612717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612717 = validateParameter(valid_612717, JString, required = false,
                                 default = nil)
  if valid_612717 != nil:
    section.add "X-Amz-Content-Sha256", valid_612717
  var valid_612718 = header.getOrDefault("X-Amz-Date")
  valid_612718 = validateParameter(valid_612718, JString, required = false,
                                 default = nil)
  if valid_612718 != nil:
    section.add "X-Amz-Date", valid_612718
  var valid_612719 = header.getOrDefault("X-Amz-Credential")
  valid_612719 = validateParameter(valid_612719, JString, required = false,
                                 default = nil)
  if valid_612719 != nil:
    section.add "X-Amz-Credential", valid_612719
  var valid_612720 = header.getOrDefault("X-Amz-Security-Token")
  valid_612720 = validateParameter(valid_612720, JString, required = false,
                                 default = nil)
  if valid_612720 != nil:
    section.add "X-Amz-Security-Token", valid_612720
  var valid_612721 = header.getOrDefault("X-Amz-Algorithm")
  valid_612721 = validateParameter(valid_612721, JString, required = false,
                                 default = nil)
  if valid_612721 != nil:
    section.add "X-Amz-Algorithm", valid_612721
  var valid_612722 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612722 = validateParameter(valid_612722, JString, required = false,
                                 default = nil)
  if valid_612722 != nil:
    section.add "X-Amz-SignedHeaders", valid_612722
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612724: Call_PutWorkflowRunProperties_612712; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
  ## 
  let valid = call_612724.validator(path, query, header, formData, body)
  let scheme = call_612724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612724.url(scheme.get, call_612724.host, call_612724.base,
                         call_612724.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612724, url, valid)

proc call*(call_612725: Call_PutWorkflowRunProperties_612712; body: JsonNode): Recallable =
  ## putWorkflowRunProperties
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
  ##   body: JObject (required)
  var body_612726 = newJObject()
  if body != nil:
    body_612726 = body
  result = call_612725.call(nil, nil, nil, nil, body_612726)

var putWorkflowRunProperties* = Call_PutWorkflowRunProperties_612712(
    name: "putWorkflowRunProperties", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutWorkflowRunProperties",
    validator: validate_PutWorkflowRunProperties_612713, base: "/",
    url: url_PutWorkflowRunProperties_612714, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetJobBookmark_612727 = ref object of OpenApiRestCall_610658
proc url_ResetJobBookmark_612729(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ResetJobBookmark_612728(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Resets a bookmark entry.
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
  var valid_612730 = header.getOrDefault("X-Amz-Target")
  valid_612730 = validateParameter(valid_612730, JString, required = true, default = newJString(
      "AWSGlue.ResetJobBookmark"))
  if valid_612730 != nil:
    section.add "X-Amz-Target", valid_612730
  var valid_612731 = header.getOrDefault("X-Amz-Signature")
  valid_612731 = validateParameter(valid_612731, JString, required = false,
                                 default = nil)
  if valid_612731 != nil:
    section.add "X-Amz-Signature", valid_612731
  var valid_612732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612732 = validateParameter(valid_612732, JString, required = false,
                                 default = nil)
  if valid_612732 != nil:
    section.add "X-Amz-Content-Sha256", valid_612732
  var valid_612733 = header.getOrDefault("X-Amz-Date")
  valid_612733 = validateParameter(valid_612733, JString, required = false,
                                 default = nil)
  if valid_612733 != nil:
    section.add "X-Amz-Date", valid_612733
  var valid_612734 = header.getOrDefault("X-Amz-Credential")
  valid_612734 = validateParameter(valid_612734, JString, required = false,
                                 default = nil)
  if valid_612734 != nil:
    section.add "X-Amz-Credential", valid_612734
  var valid_612735 = header.getOrDefault("X-Amz-Security-Token")
  valid_612735 = validateParameter(valid_612735, JString, required = false,
                                 default = nil)
  if valid_612735 != nil:
    section.add "X-Amz-Security-Token", valid_612735
  var valid_612736 = header.getOrDefault("X-Amz-Algorithm")
  valid_612736 = validateParameter(valid_612736, JString, required = false,
                                 default = nil)
  if valid_612736 != nil:
    section.add "X-Amz-Algorithm", valid_612736
  var valid_612737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612737 = validateParameter(valid_612737, JString, required = false,
                                 default = nil)
  if valid_612737 != nil:
    section.add "X-Amz-SignedHeaders", valid_612737
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612739: Call_ResetJobBookmark_612727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets a bookmark entry.
  ## 
  let valid = call_612739.validator(path, query, header, formData, body)
  let scheme = call_612739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612739.url(scheme.get, call_612739.host, call_612739.base,
                         call_612739.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612739, url, valid)

proc call*(call_612740: Call_ResetJobBookmark_612727; body: JsonNode): Recallable =
  ## resetJobBookmark
  ## Resets a bookmark entry.
  ##   body: JObject (required)
  var body_612741 = newJObject()
  if body != nil:
    body_612741 = body
  result = call_612740.call(nil, nil, nil, nil, body_612741)

var resetJobBookmark* = Call_ResetJobBookmark_612727(name: "resetJobBookmark",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ResetJobBookmark",
    validator: validate_ResetJobBookmark_612728, base: "/",
    url: url_ResetJobBookmark_612729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchTables_612742 = ref object of OpenApiRestCall_610658
proc url_SearchTables_612744(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchTables_612743(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
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
  var valid_612745 = query.getOrDefault("MaxResults")
  valid_612745 = validateParameter(valid_612745, JString, required = false,
                                 default = nil)
  if valid_612745 != nil:
    section.add "MaxResults", valid_612745
  var valid_612746 = query.getOrDefault("NextToken")
  valid_612746 = validateParameter(valid_612746, JString, required = false,
                                 default = nil)
  if valid_612746 != nil:
    section.add "NextToken", valid_612746
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
  var valid_612747 = header.getOrDefault("X-Amz-Target")
  valid_612747 = validateParameter(valid_612747, JString, required = true,
                                 default = newJString("AWSGlue.SearchTables"))
  if valid_612747 != nil:
    section.add "X-Amz-Target", valid_612747
  var valid_612748 = header.getOrDefault("X-Amz-Signature")
  valid_612748 = validateParameter(valid_612748, JString, required = false,
                                 default = nil)
  if valid_612748 != nil:
    section.add "X-Amz-Signature", valid_612748
  var valid_612749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612749 = validateParameter(valid_612749, JString, required = false,
                                 default = nil)
  if valid_612749 != nil:
    section.add "X-Amz-Content-Sha256", valid_612749
  var valid_612750 = header.getOrDefault("X-Amz-Date")
  valid_612750 = validateParameter(valid_612750, JString, required = false,
                                 default = nil)
  if valid_612750 != nil:
    section.add "X-Amz-Date", valid_612750
  var valid_612751 = header.getOrDefault("X-Amz-Credential")
  valid_612751 = validateParameter(valid_612751, JString, required = false,
                                 default = nil)
  if valid_612751 != nil:
    section.add "X-Amz-Credential", valid_612751
  var valid_612752 = header.getOrDefault("X-Amz-Security-Token")
  valid_612752 = validateParameter(valid_612752, JString, required = false,
                                 default = nil)
  if valid_612752 != nil:
    section.add "X-Amz-Security-Token", valid_612752
  var valid_612753 = header.getOrDefault("X-Amz-Algorithm")
  valid_612753 = validateParameter(valid_612753, JString, required = false,
                                 default = nil)
  if valid_612753 != nil:
    section.add "X-Amz-Algorithm", valid_612753
  var valid_612754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612754 = validateParameter(valid_612754, JString, required = false,
                                 default = nil)
  if valid_612754 != nil:
    section.add "X-Amz-SignedHeaders", valid_612754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612756: Call_SearchTables_612742; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
  ## 
  let valid = call_612756.validator(path, query, header, formData, body)
  let scheme = call_612756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612756.url(scheme.get, call_612756.host, call_612756.base,
                         call_612756.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612756, url, valid)

proc call*(call_612757: Call_SearchTables_612742; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchTables
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612758 = newJObject()
  var body_612759 = newJObject()
  add(query_612758, "MaxResults", newJString(MaxResults))
  add(query_612758, "NextToken", newJString(NextToken))
  if body != nil:
    body_612759 = body
  result = call_612757.call(nil, query_612758, nil, nil, body_612759)

var searchTables* = Call_SearchTables_612742(name: "searchTables",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.SearchTables",
    validator: validate_SearchTables_612743, base: "/", url: url_SearchTables_612744,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCrawler_612760 = ref object of OpenApiRestCall_610658
proc url_StartCrawler_612762(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartCrawler_612761(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
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
  var valid_612763 = header.getOrDefault("X-Amz-Target")
  valid_612763 = validateParameter(valid_612763, JString, required = true,
                                 default = newJString("AWSGlue.StartCrawler"))
  if valid_612763 != nil:
    section.add "X-Amz-Target", valid_612763
  var valid_612764 = header.getOrDefault("X-Amz-Signature")
  valid_612764 = validateParameter(valid_612764, JString, required = false,
                                 default = nil)
  if valid_612764 != nil:
    section.add "X-Amz-Signature", valid_612764
  var valid_612765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612765 = validateParameter(valid_612765, JString, required = false,
                                 default = nil)
  if valid_612765 != nil:
    section.add "X-Amz-Content-Sha256", valid_612765
  var valid_612766 = header.getOrDefault("X-Amz-Date")
  valid_612766 = validateParameter(valid_612766, JString, required = false,
                                 default = nil)
  if valid_612766 != nil:
    section.add "X-Amz-Date", valid_612766
  var valid_612767 = header.getOrDefault("X-Amz-Credential")
  valid_612767 = validateParameter(valid_612767, JString, required = false,
                                 default = nil)
  if valid_612767 != nil:
    section.add "X-Amz-Credential", valid_612767
  var valid_612768 = header.getOrDefault("X-Amz-Security-Token")
  valid_612768 = validateParameter(valid_612768, JString, required = false,
                                 default = nil)
  if valid_612768 != nil:
    section.add "X-Amz-Security-Token", valid_612768
  var valid_612769 = header.getOrDefault("X-Amz-Algorithm")
  valid_612769 = validateParameter(valid_612769, JString, required = false,
                                 default = nil)
  if valid_612769 != nil:
    section.add "X-Amz-Algorithm", valid_612769
  var valid_612770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612770 = validateParameter(valid_612770, JString, required = false,
                                 default = nil)
  if valid_612770 != nil:
    section.add "X-Amz-SignedHeaders", valid_612770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612772: Call_StartCrawler_612760; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
  ## 
  let valid = call_612772.validator(path, query, header, formData, body)
  let scheme = call_612772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612772.url(scheme.get, call_612772.host, call_612772.base,
                         call_612772.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612772, url, valid)

proc call*(call_612773: Call_StartCrawler_612760; body: JsonNode): Recallable =
  ## startCrawler
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
  ##   body: JObject (required)
  var body_612774 = newJObject()
  if body != nil:
    body_612774 = body
  result = call_612773.call(nil, nil, nil, nil, body_612774)

var startCrawler* = Call_StartCrawler_612760(name: "startCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartCrawler",
    validator: validate_StartCrawler_612761, base: "/", url: url_StartCrawler_612762,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCrawlerSchedule_612775 = ref object of OpenApiRestCall_610658
proc url_StartCrawlerSchedule_612777(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartCrawlerSchedule_612776(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
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
  var valid_612778 = header.getOrDefault("X-Amz-Target")
  valid_612778 = validateParameter(valid_612778, JString, required = true, default = newJString(
      "AWSGlue.StartCrawlerSchedule"))
  if valid_612778 != nil:
    section.add "X-Amz-Target", valid_612778
  var valid_612779 = header.getOrDefault("X-Amz-Signature")
  valid_612779 = validateParameter(valid_612779, JString, required = false,
                                 default = nil)
  if valid_612779 != nil:
    section.add "X-Amz-Signature", valid_612779
  var valid_612780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612780 = validateParameter(valid_612780, JString, required = false,
                                 default = nil)
  if valid_612780 != nil:
    section.add "X-Amz-Content-Sha256", valid_612780
  var valid_612781 = header.getOrDefault("X-Amz-Date")
  valid_612781 = validateParameter(valid_612781, JString, required = false,
                                 default = nil)
  if valid_612781 != nil:
    section.add "X-Amz-Date", valid_612781
  var valid_612782 = header.getOrDefault("X-Amz-Credential")
  valid_612782 = validateParameter(valid_612782, JString, required = false,
                                 default = nil)
  if valid_612782 != nil:
    section.add "X-Amz-Credential", valid_612782
  var valid_612783 = header.getOrDefault("X-Amz-Security-Token")
  valid_612783 = validateParameter(valid_612783, JString, required = false,
                                 default = nil)
  if valid_612783 != nil:
    section.add "X-Amz-Security-Token", valid_612783
  var valid_612784 = header.getOrDefault("X-Amz-Algorithm")
  valid_612784 = validateParameter(valid_612784, JString, required = false,
                                 default = nil)
  if valid_612784 != nil:
    section.add "X-Amz-Algorithm", valid_612784
  var valid_612785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612785 = validateParameter(valid_612785, JString, required = false,
                                 default = nil)
  if valid_612785 != nil:
    section.add "X-Amz-SignedHeaders", valid_612785
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612787: Call_StartCrawlerSchedule_612775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
  ## 
  let valid = call_612787.validator(path, query, header, formData, body)
  let scheme = call_612787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612787.url(scheme.get, call_612787.host, call_612787.base,
                         call_612787.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612787, url, valid)

proc call*(call_612788: Call_StartCrawlerSchedule_612775; body: JsonNode): Recallable =
  ## startCrawlerSchedule
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
  ##   body: JObject (required)
  var body_612789 = newJObject()
  if body != nil:
    body_612789 = body
  result = call_612788.call(nil, nil, nil, nil, body_612789)

var startCrawlerSchedule* = Call_StartCrawlerSchedule_612775(
    name: "startCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartCrawlerSchedule",
    validator: validate_StartCrawlerSchedule_612776, base: "/",
    url: url_StartCrawlerSchedule_612777, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartExportLabelsTaskRun_612790 = ref object of OpenApiRestCall_610658
proc url_StartExportLabelsTaskRun_612792(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartExportLabelsTaskRun_612791(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
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
  var valid_612793 = header.getOrDefault("X-Amz-Target")
  valid_612793 = validateParameter(valid_612793, JString, required = true, default = newJString(
      "AWSGlue.StartExportLabelsTaskRun"))
  if valid_612793 != nil:
    section.add "X-Amz-Target", valid_612793
  var valid_612794 = header.getOrDefault("X-Amz-Signature")
  valid_612794 = validateParameter(valid_612794, JString, required = false,
                                 default = nil)
  if valid_612794 != nil:
    section.add "X-Amz-Signature", valid_612794
  var valid_612795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612795 = validateParameter(valid_612795, JString, required = false,
                                 default = nil)
  if valid_612795 != nil:
    section.add "X-Amz-Content-Sha256", valid_612795
  var valid_612796 = header.getOrDefault("X-Amz-Date")
  valid_612796 = validateParameter(valid_612796, JString, required = false,
                                 default = nil)
  if valid_612796 != nil:
    section.add "X-Amz-Date", valid_612796
  var valid_612797 = header.getOrDefault("X-Amz-Credential")
  valid_612797 = validateParameter(valid_612797, JString, required = false,
                                 default = nil)
  if valid_612797 != nil:
    section.add "X-Amz-Credential", valid_612797
  var valid_612798 = header.getOrDefault("X-Amz-Security-Token")
  valid_612798 = validateParameter(valid_612798, JString, required = false,
                                 default = nil)
  if valid_612798 != nil:
    section.add "X-Amz-Security-Token", valid_612798
  var valid_612799 = header.getOrDefault("X-Amz-Algorithm")
  valid_612799 = validateParameter(valid_612799, JString, required = false,
                                 default = nil)
  if valid_612799 != nil:
    section.add "X-Amz-Algorithm", valid_612799
  var valid_612800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612800 = validateParameter(valid_612800, JString, required = false,
                                 default = nil)
  if valid_612800 != nil:
    section.add "X-Amz-SignedHeaders", valid_612800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612802: Call_StartExportLabelsTaskRun_612790; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
  ## 
  let valid = call_612802.validator(path, query, header, formData, body)
  let scheme = call_612802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612802.url(scheme.get, call_612802.host, call_612802.base,
                         call_612802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612802, url, valid)

proc call*(call_612803: Call_StartExportLabelsTaskRun_612790; body: JsonNode): Recallable =
  ## startExportLabelsTaskRun
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
  ##   body: JObject (required)
  var body_612804 = newJObject()
  if body != nil:
    body_612804 = body
  result = call_612803.call(nil, nil, nil, nil, body_612804)

var startExportLabelsTaskRun* = Call_StartExportLabelsTaskRun_612790(
    name: "startExportLabelsTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartExportLabelsTaskRun",
    validator: validate_StartExportLabelsTaskRun_612791, base: "/",
    url: url_StartExportLabelsTaskRun_612792, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImportLabelsTaskRun_612805 = ref object of OpenApiRestCall_610658
proc url_StartImportLabelsTaskRun_612807(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartImportLabelsTaskRun_612806(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
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
  var valid_612808 = header.getOrDefault("X-Amz-Target")
  valid_612808 = validateParameter(valid_612808, JString, required = true, default = newJString(
      "AWSGlue.StartImportLabelsTaskRun"))
  if valid_612808 != nil:
    section.add "X-Amz-Target", valid_612808
  var valid_612809 = header.getOrDefault("X-Amz-Signature")
  valid_612809 = validateParameter(valid_612809, JString, required = false,
                                 default = nil)
  if valid_612809 != nil:
    section.add "X-Amz-Signature", valid_612809
  var valid_612810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612810 = validateParameter(valid_612810, JString, required = false,
                                 default = nil)
  if valid_612810 != nil:
    section.add "X-Amz-Content-Sha256", valid_612810
  var valid_612811 = header.getOrDefault("X-Amz-Date")
  valid_612811 = validateParameter(valid_612811, JString, required = false,
                                 default = nil)
  if valid_612811 != nil:
    section.add "X-Amz-Date", valid_612811
  var valid_612812 = header.getOrDefault("X-Amz-Credential")
  valid_612812 = validateParameter(valid_612812, JString, required = false,
                                 default = nil)
  if valid_612812 != nil:
    section.add "X-Amz-Credential", valid_612812
  var valid_612813 = header.getOrDefault("X-Amz-Security-Token")
  valid_612813 = validateParameter(valid_612813, JString, required = false,
                                 default = nil)
  if valid_612813 != nil:
    section.add "X-Amz-Security-Token", valid_612813
  var valid_612814 = header.getOrDefault("X-Amz-Algorithm")
  valid_612814 = validateParameter(valid_612814, JString, required = false,
                                 default = nil)
  if valid_612814 != nil:
    section.add "X-Amz-Algorithm", valid_612814
  var valid_612815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612815 = validateParameter(valid_612815, JString, required = false,
                                 default = nil)
  if valid_612815 != nil:
    section.add "X-Amz-SignedHeaders", valid_612815
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612817: Call_StartImportLabelsTaskRun_612805; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
  ## 
  let valid = call_612817.validator(path, query, header, formData, body)
  let scheme = call_612817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612817.url(scheme.get, call_612817.host, call_612817.base,
                         call_612817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612817, url, valid)

proc call*(call_612818: Call_StartImportLabelsTaskRun_612805; body: JsonNode): Recallable =
  ## startImportLabelsTaskRun
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
  ##   body: JObject (required)
  var body_612819 = newJObject()
  if body != nil:
    body_612819 = body
  result = call_612818.call(nil, nil, nil, nil, body_612819)

var startImportLabelsTaskRun* = Call_StartImportLabelsTaskRun_612805(
    name: "startImportLabelsTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartImportLabelsTaskRun",
    validator: validate_StartImportLabelsTaskRun_612806, base: "/",
    url: url_StartImportLabelsTaskRun_612807, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartJobRun_612820 = ref object of OpenApiRestCall_610658
proc url_StartJobRun_612822(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartJobRun_612821(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts a job run using a job definition.
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
  var valid_612823 = header.getOrDefault("X-Amz-Target")
  valid_612823 = validateParameter(valid_612823, JString, required = true,
                                 default = newJString("AWSGlue.StartJobRun"))
  if valid_612823 != nil:
    section.add "X-Amz-Target", valid_612823
  var valid_612824 = header.getOrDefault("X-Amz-Signature")
  valid_612824 = validateParameter(valid_612824, JString, required = false,
                                 default = nil)
  if valid_612824 != nil:
    section.add "X-Amz-Signature", valid_612824
  var valid_612825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612825 = validateParameter(valid_612825, JString, required = false,
                                 default = nil)
  if valid_612825 != nil:
    section.add "X-Amz-Content-Sha256", valid_612825
  var valid_612826 = header.getOrDefault("X-Amz-Date")
  valid_612826 = validateParameter(valid_612826, JString, required = false,
                                 default = nil)
  if valid_612826 != nil:
    section.add "X-Amz-Date", valid_612826
  var valid_612827 = header.getOrDefault("X-Amz-Credential")
  valid_612827 = validateParameter(valid_612827, JString, required = false,
                                 default = nil)
  if valid_612827 != nil:
    section.add "X-Amz-Credential", valid_612827
  var valid_612828 = header.getOrDefault("X-Amz-Security-Token")
  valid_612828 = validateParameter(valid_612828, JString, required = false,
                                 default = nil)
  if valid_612828 != nil:
    section.add "X-Amz-Security-Token", valid_612828
  var valid_612829 = header.getOrDefault("X-Amz-Algorithm")
  valid_612829 = validateParameter(valid_612829, JString, required = false,
                                 default = nil)
  if valid_612829 != nil:
    section.add "X-Amz-Algorithm", valid_612829
  var valid_612830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612830 = validateParameter(valid_612830, JString, required = false,
                                 default = nil)
  if valid_612830 != nil:
    section.add "X-Amz-SignedHeaders", valid_612830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612832: Call_StartJobRun_612820; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a job run using a job definition.
  ## 
  let valid = call_612832.validator(path, query, header, formData, body)
  let scheme = call_612832.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612832.url(scheme.get, call_612832.host, call_612832.base,
                         call_612832.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612832, url, valid)

proc call*(call_612833: Call_StartJobRun_612820; body: JsonNode): Recallable =
  ## startJobRun
  ## Starts a job run using a job definition.
  ##   body: JObject (required)
  var body_612834 = newJObject()
  if body != nil:
    body_612834 = body
  result = call_612833.call(nil, nil, nil, nil, body_612834)

var startJobRun* = Call_StartJobRun_612820(name: "startJobRun",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StartJobRun",
                                        validator: validate_StartJobRun_612821,
                                        base: "/", url: url_StartJobRun_612822,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMLEvaluationTaskRun_612835 = ref object of OpenApiRestCall_610658
proc url_StartMLEvaluationTaskRun_612837(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartMLEvaluationTaskRun_612836(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
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
  var valid_612838 = header.getOrDefault("X-Amz-Target")
  valid_612838 = validateParameter(valid_612838, JString, required = true, default = newJString(
      "AWSGlue.StartMLEvaluationTaskRun"))
  if valid_612838 != nil:
    section.add "X-Amz-Target", valid_612838
  var valid_612839 = header.getOrDefault("X-Amz-Signature")
  valid_612839 = validateParameter(valid_612839, JString, required = false,
                                 default = nil)
  if valid_612839 != nil:
    section.add "X-Amz-Signature", valid_612839
  var valid_612840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612840 = validateParameter(valid_612840, JString, required = false,
                                 default = nil)
  if valid_612840 != nil:
    section.add "X-Amz-Content-Sha256", valid_612840
  var valid_612841 = header.getOrDefault("X-Amz-Date")
  valid_612841 = validateParameter(valid_612841, JString, required = false,
                                 default = nil)
  if valid_612841 != nil:
    section.add "X-Amz-Date", valid_612841
  var valid_612842 = header.getOrDefault("X-Amz-Credential")
  valid_612842 = validateParameter(valid_612842, JString, required = false,
                                 default = nil)
  if valid_612842 != nil:
    section.add "X-Amz-Credential", valid_612842
  var valid_612843 = header.getOrDefault("X-Amz-Security-Token")
  valid_612843 = validateParameter(valid_612843, JString, required = false,
                                 default = nil)
  if valid_612843 != nil:
    section.add "X-Amz-Security-Token", valid_612843
  var valid_612844 = header.getOrDefault("X-Amz-Algorithm")
  valid_612844 = validateParameter(valid_612844, JString, required = false,
                                 default = nil)
  if valid_612844 != nil:
    section.add "X-Amz-Algorithm", valid_612844
  var valid_612845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612845 = validateParameter(valid_612845, JString, required = false,
                                 default = nil)
  if valid_612845 != nil:
    section.add "X-Amz-SignedHeaders", valid_612845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612847: Call_StartMLEvaluationTaskRun_612835; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
  ## 
  let valid = call_612847.validator(path, query, header, formData, body)
  let scheme = call_612847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612847.url(scheme.get, call_612847.host, call_612847.base,
                         call_612847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612847, url, valid)

proc call*(call_612848: Call_StartMLEvaluationTaskRun_612835; body: JsonNode): Recallable =
  ## startMLEvaluationTaskRun
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
  ##   body: JObject (required)
  var body_612849 = newJObject()
  if body != nil:
    body_612849 = body
  result = call_612848.call(nil, nil, nil, nil, body_612849)

var startMLEvaluationTaskRun* = Call_StartMLEvaluationTaskRun_612835(
    name: "startMLEvaluationTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartMLEvaluationTaskRun",
    validator: validate_StartMLEvaluationTaskRun_612836, base: "/",
    url: url_StartMLEvaluationTaskRun_612837, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMLLabelingSetGenerationTaskRun_612850 = ref object of OpenApiRestCall_610658
proc url_StartMLLabelingSetGenerationTaskRun_612852(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartMLLabelingSetGenerationTaskRun_612851(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
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
  var valid_612853 = header.getOrDefault("X-Amz-Target")
  valid_612853 = validateParameter(valid_612853, JString, required = true, default = newJString(
      "AWSGlue.StartMLLabelingSetGenerationTaskRun"))
  if valid_612853 != nil:
    section.add "X-Amz-Target", valid_612853
  var valid_612854 = header.getOrDefault("X-Amz-Signature")
  valid_612854 = validateParameter(valid_612854, JString, required = false,
                                 default = nil)
  if valid_612854 != nil:
    section.add "X-Amz-Signature", valid_612854
  var valid_612855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612855 = validateParameter(valid_612855, JString, required = false,
                                 default = nil)
  if valid_612855 != nil:
    section.add "X-Amz-Content-Sha256", valid_612855
  var valid_612856 = header.getOrDefault("X-Amz-Date")
  valid_612856 = validateParameter(valid_612856, JString, required = false,
                                 default = nil)
  if valid_612856 != nil:
    section.add "X-Amz-Date", valid_612856
  var valid_612857 = header.getOrDefault("X-Amz-Credential")
  valid_612857 = validateParameter(valid_612857, JString, required = false,
                                 default = nil)
  if valid_612857 != nil:
    section.add "X-Amz-Credential", valid_612857
  var valid_612858 = header.getOrDefault("X-Amz-Security-Token")
  valid_612858 = validateParameter(valid_612858, JString, required = false,
                                 default = nil)
  if valid_612858 != nil:
    section.add "X-Amz-Security-Token", valid_612858
  var valid_612859 = header.getOrDefault("X-Amz-Algorithm")
  valid_612859 = validateParameter(valid_612859, JString, required = false,
                                 default = nil)
  if valid_612859 != nil:
    section.add "X-Amz-Algorithm", valid_612859
  var valid_612860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612860 = validateParameter(valid_612860, JString, required = false,
                                 default = nil)
  if valid_612860 != nil:
    section.add "X-Amz-SignedHeaders", valid_612860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612862: Call_StartMLLabelingSetGenerationTaskRun_612850;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
  ## 
  let valid = call_612862.validator(path, query, header, formData, body)
  let scheme = call_612862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612862.url(scheme.get, call_612862.host, call_612862.base,
                         call_612862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612862, url, valid)

proc call*(call_612863: Call_StartMLLabelingSetGenerationTaskRun_612850;
          body: JsonNode): Recallable =
  ## startMLLabelingSetGenerationTaskRun
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
  ##   body: JObject (required)
  var body_612864 = newJObject()
  if body != nil:
    body_612864 = body
  result = call_612863.call(nil, nil, nil, nil, body_612864)

var startMLLabelingSetGenerationTaskRun* = Call_StartMLLabelingSetGenerationTaskRun_612850(
    name: "startMLLabelingSetGenerationTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartMLLabelingSetGenerationTaskRun",
    validator: validate_StartMLLabelingSetGenerationTaskRun_612851, base: "/",
    url: url_StartMLLabelingSetGenerationTaskRun_612852,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTrigger_612865 = ref object of OpenApiRestCall_610658
proc url_StartTrigger_612867(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartTrigger_612866(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
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
  var valid_612868 = header.getOrDefault("X-Amz-Target")
  valid_612868 = validateParameter(valid_612868, JString, required = true,
                                 default = newJString("AWSGlue.StartTrigger"))
  if valid_612868 != nil:
    section.add "X-Amz-Target", valid_612868
  var valid_612869 = header.getOrDefault("X-Amz-Signature")
  valid_612869 = validateParameter(valid_612869, JString, required = false,
                                 default = nil)
  if valid_612869 != nil:
    section.add "X-Amz-Signature", valid_612869
  var valid_612870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612870 = validateParameter(valid_612870, JString, required = false,
                                 default = nil)
  if valid_612870 != nil:
    section.add "X-Amz-Content-Sha256", valid_612870
  var valid_612871 = header.getOrDefault("X-Amz-Date")
  valid_612871 = validateParameter(valid_612871, JString, required = false,
                                 default = nil)
  if valid_612871 != nil:
    section.add "X-Amz-Date", valid_612871
  var valid_612872 = header.getOrDefault("X-Amz-Credential")
  valid_612872 = validateParameter(valid_612872, JString, required = false,
                                 default = nil)
  if valid_612872 != nil:
    section.add "X-Amz-Credential", valid_612872
  var valid_612873 = header.getOrDefault("X-Amz-Security-Token")
  valid_612873 = validateParameter(valid_612873, JString, required = false,
                                 default = nil)
  if valid_612873 != nil:
    section.add "X-Amz-Security-Token", valid_612873
  var valid_612874 = header.getOrDefault("X-Amz-Algorithm")
  valid_612874 = validateParameter(valid_612874, JString, required = false,
                                 default = nil)
  if valid_612874 != nil:
    section.add "X-Amz-Algorithm", valid_612874
  var valid_612875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612875 = validateParameter(valid_612875, JString, required = false,
                                 default = nil)
  if valid_612875 != nil:
    section.add "X-Amz-SignedHeaders", valid_612875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612877: Call_StartTrigger_612865; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
  ## 
  let valid = call_612877.validator(path, query, header, formData, body)
  let scheme = call_612877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612877.url(scheme.get, call_612877.host, call_612877.base,
                         call_612877.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612877, url, valid)

proc call*(call_612878: Call_StartTrigger_612865; body: JsonNode): Recallable =
  ## startTrigger
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
  ##   body: JObject (required)
  var body_612879 = newJObject()
  if body != nil:
    body_612879 = body
  result = call_612878.call(nil, nil, nil, nil, body_612879)

var startTrigger* = Call_StartTrigger_612865(name: "startTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartTrigger",
    validator: validate_StartTrigger_612866, base: "/", url: url_StartTrigger_612867,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartWorkflowRun_612880 = ref object of OpenApiRestCall_610658
proc url_StartWorkflowRun_612882(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartWorkflowRun_612881(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Starts a new run of the specified workflow.
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
  var valid_612883 = header.getOrDefault("X-Amz-Target")
  valid_612883 = validateParameter(valid_612883, JString, required = true, default = newJString(
      "AWSGlue.StartWorkflowRun"))
  if valid_612883 != nil:
    section.add "X-Amz-Target", valid_612883
  var valid_612884 = header.getOrDefault("X-Amz-Signature")
  valid_612884 = validateParameter(valid_612884, JString, required = false,
                                 default = nil)
  if valid_612884 != nil:
    section.add "X-Amz-Signature", valid_612884
  var valid_612885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612885 = validateParameter(valid_612885, JString, required = false,
                                 default = nil)
  if valid_612885 != nil:
    section.add "X-Amz-Content-Sha256", valid_612885
  var valid_612886 = header.getOrDefault("X-Amz-Date")
  valid_612886 = validateParameter(valid_612886, JString, required = false,
                                 default = nil)
  if valid_612886 != nil:
    section.add "X-Amz-Date", valid_612886
  var valid_612887 = header.getOrDefault("X-Amz-Credential")
  valid_612887 = validateParameter(valid_612887, JString, required = false,
                                 default = nil)
  if valid_612887 != nil:
    section.add "X-Amz-Credential", valid_612887
  var valid_612888 = header.getOrDefault("X-Amz-Security-Token")
  valid_612888 = validateParameter(valid_612888, JString, required = false,
                                 default = nil)
  if valid_612888 != nil:
    section.add "X-Amz-Security-Token", valid_612888
  var valid_612889 = header.getOrDefault("X-Amz-Algorithm")
  valid_612889 = validateParameter(valid_612889, JString, required = false,
                                 default = nil)
  if valid_612889 != nil:
    section.add "X-Amz-Algorithm", valid_612889
  var valid_612890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612890 = validateParameter(valid_612890, JString, required = false,
                                 default = nil)
  if valid_612890 != nil:
    section.add "X-Amz-SignedHeaders", valid_612890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612892: Call_StartWorkflowRun_612880; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a new run of the specified workflow.
  ## 
  let valid = call_612892.validator(path, query, header, formData, body)
  let scheme = call_612892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612892.url(scheme.get, call_612892.host, call_612892.base,
                         call_612892.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612892, url, valid)

proc call*(call_612893: Call_StartWorkflowRun_612880; body: JsonNode): Recallable =
  ## startWorkflowRun
  ## Starts a new run of the specified workflow.
  ##   body: JObject (required)
  var body_612894 = newJObject()
  if body != nil:
    body_612894 = body
  result = call_612893.call(nil, nil, nil, nil, body_612894)

var startWorkflowRun* = Call_StartWorkflowRun_612880(name: "startWorkflowRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartWorkflowRun",
    validator: validate_StartWorkflowRun_612881, base: "/",
    url: url_StartWorkflowRun_612882, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCrawler_612895 = ref object of OpenApiRestCall_610658
proc url_StopCrawler_612897(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopCrawler_612896(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## If the specified crawler is running, stops the crawl.
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
  var valid_612898 = header.getOrDefault("X-Amz-Target")
  valid_612898 = validateParameter(valid_612898, JString, required = true,
                                 default = newJString("AWSGlue.StopCrawler"))
  if valid_612898 != nil:
    section.add "X-Amz-Target", valid_612898
  var valid_612899 = header.getOrDefault("X-Amz-Signature")
  valid_612899 = validateParameter(valid_612899, JString, required = false,
                                 default = nil)
  if valid_612899 != nil:
    section.add "X-Amz-Signature", valid_612899
  var valid_612900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612900 = validateParameter(valid_612900, JString, required = false,
                                 default = nil)
  if valid_612900 != nil:
    section.add "X-Amz-Content-Sha256", valid_612900
  var valid_612901 = header.getOrDefault("X-Amz-Date")
  valid_612901 = validateParameter(valid_612901, JString, required = false,
                                 default = nil)
  if valid_612901 != nil:
    section.add "X-Amz-Date", valid_612901
  var valid_612902 = header.getOrDefault("X-Amz-Credential")
  valid_612902 = validateParameter(valid_612902, JString, required = false,
                                 default = nil)
  if valid_612902 != nil:
    section.add "X-Amz-Credential", valid_612902
  var valid_612903 = header.getOrDefault("X-Amz-Security-Token")
  valid_612903 = validateParameter(valid_612903, JString, required = false,
                                 default = nil)
  if valid_612903 != nil:
    section.add "X-Amz-Security-Token", valid_612903
  var valid_612904 = header.getOrDefault("X-Amz-Algorithm")
  valid_612904 = validateParameter(valid_612904, JString, required = false,
                                 default = nil)
  if valid_612904 != nil:
    section.add "X-Amz-Algorithm", valid_612904
  var valid_612905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612905 = validateParameter(valid_612905, JString, required = false,
                                 default = nil)
  if valid_612905 != nil:
    section.add "X-Amz-SignedHeaders", valid_612905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612907: Call_StopCrawler_612895; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## If the specified crawler is running, stops the crawl.
  ## 
  let valid = call_612907.validator(path, query, header, formData, body)
  let scheme = call_612907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612907.url(scheme.get, call_612907.host, call_612907.base,
                         call_612907.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612907, url, valid)

proc call*(call_612908: Call_StopCrawler_612895; body: JsonNode): Recallable =
  ## stopCrawler
  ## If the specified crawler is running, stops the crawl.
  ##   body: JObject (required)
  var body_612909 = newJObject()
  if body != nil:
    body_612909 = body
  result = call_612908.call(nil, nil, nil, nil, body_612909)

var stopCrawler* = Call_StopCrawler_612895(name: "stopCrawler",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StopCrawler",
                                        validator: validate_StopCrawler_612896,
                                        base: "/", url: url_StopCrawler_612897,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCrawlerSchedule_612910 = ref object of OpenApiRestCall_610658
proc url_StopCrawlerSchedule_612912(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopCrawlerSchedule_612911(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
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
  var valid_612913 = header.getOrDefault("X-Amz-Target")
  valid_612913 = validateParameter(valid_612913, JString, required = true, default = newJString(
      "AWSGlue.StopCrawlerSchedule"))
  if valid_612913 != nil:
    section.add "X-Amz-Target", valid_612913
  var valid_612914 = header.getOrDefault("X-Amz-Signature")
  valid_612914 = validateParameter(valid_612914, JString, required = false,
                                 default = nil)
  if valid_612914 != nil:
    section.add "X-Amz-Signature", valid_612914
  var valid_612915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612915 = validateParameter(valid_612915, JString, required = false,
                                 default = nil)
  if valid_612915 != nil:
    section.add "X-Amz-Content-Sha256", valid_612915
  var valid_612916 = header.getOrDefault("X-Amz-Date")
  valid_612916 = validateParameter(valid_612916, JString, required = false,
                                 default = nil)
  if valid_612916 != nil:
    section.add "X-Amz-Date", valid_612916
  var valid_612917 = header.getOrDefault("X-Amz-Credential")
  valid_612917 = validateParameter(valid_612917, JString, required = false,
                                 default = nil)
  if valid_612917 != nil:
    section.add "X-Amz-Credential", valid_612917
  var valid_612918 = header.getOrDefault("X-Amz-Security-Token")
  valid_612918 = validateParameter(valid_612918, JString, required = false,
                                 default = nil)
  if valid_612918 != nil:
    section.add "X-Amz-Security-Token", valid_612918
  var valid_612919 = header.getOrDefault("X-Amz-Algorithm")
  valid_612919 = validateParameter(valid_612919, JString, required = false,
                                 default = nil)
  if valid_612919 != nil:
    section.add "X-Amz-Algorithm", valid_612919
  var valid_612920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612920 = validateParameter(valid_612920, JString, required = false,
                                 default = nil)
  if valid_612920 != nil:
    section.add "X-Amz-SignedHeaders", valid_612920
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612922: Call_StopCrawlerSchedule_612910; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
  ## 
  let valid = call_612922.validator(path, query, header, formData, body)
  let scheme = call_612922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612922.url(scheme.get, call_612922.host, call_612922.base,
                         call_612922.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612922, url, valid)

proc call*(call_612923: Call_StopCrawlerSchedule_612910; body: JsonNode): Recallable =
  ## stopCrawlerSchedule
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
  ##   body: JObject (required)
  var body_612924 = newJObject()
  if body != nil:
    body_612924 = body
  result = call_612923.call(nil, nil, nil, nil, body_612924)

var stopCrawlerSchedule* = Call_StopCrawlerSchedule_612910(
    name: "stopCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StopCrawlerSchedule",
    validator: validate_StopCrawlerSchedule_612911, base: "/",
    url: url_StopCrawlerSchedule_612912, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrigger_612925 = ref object of OpenApiRestCall_610658
proc url_StopTrigger_612927(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopTrigger_612926(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Stops a specified trigger.
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
  var valid_612928 = header.getOrDefault("X-Amz-Target")
  valid_612928 = validateParameter(valid_612928, JString, required = true,
                                 default = newJString("AWSGlue.StopTrigger"))
  if valid_612928 != nil:
    section.add "X-Amz-Target", valid_612928
  var valid_612929 = header.getOrDefault("X-Amz-Signature")
  valid_612929 = validateParameter(valid_612929, JString, required = false,
                                 default = nil)
  if valid_612929 != nil:
    section.add "X-Amz-Signature", valid_612929
  var valid_612930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612930 = validateParameter(valid_612930, JString, required = false,
                                 default = nil)
  if valid_612930 != nil:
    section.add "X-Amz-Content-Sha256", valid_612930
  var valid_612931 = header.getOrDefault("X-Amz-Date")
  valid_612931 = validateParameter(valid_612931, JString, required = false,
                                 default = nil)
  if valid_612931 != nil:
    section.add "X-Amz-Date", valid_612931
  var valid_612932 = header.getOrDefault("X-Amz-Credential")
  valid_612932 = validateParameter(valid_612932, JString, required = false,
                                 default = nil)
  if valid_612932 != nil:
    section.add "X-Amz-Credential", valid_612932
  var valid_612933 = header.getOrDefault("X-Amz-Security-Token")
  valid_612933 = validateParameter(valid_612933, JString, required = false,
                                 default = nil)
  if valid_612933 != nil:
    section.add "X-Amz-Security-Token", valid_612933
  var valid_612934 = header.getOrDefault("X-Amz-Algorithm")
  valid_612934 = validateParameter(valid_612934, JString, required = false,
                                 default = nil)
  if valid_612934 != nil:
    section.add "X-Amz-Algorithm", valid_612934
  var valid_612935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612935 = validateParameter(valid_612935, JString, required = false,
                                 default = nil)
  if valid_612935 != nil:
    section.add "X-Amz-SignedHeaders", valid_612935
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612937: Call_StopTrigger_612925; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a specified trigger.
  ## 
  let valid = call_612937.validator(path, query, header, formData, body)
  let scheme = call_612937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612937.url(scheme.get, call_612937.host, call_612937.base,
                         call_612937.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612937, url, valid)

proc call*(call_612938: Call_StopTrigger_612925; body: JsonNode): Recallable =
  ## stopTrigger
  ## Stops a specified trigger.
  ##   body: JObject (required)
  var body_612939 = newJObject()
  if body != nil:
    body_612939 = body
  result = call_612938.call(nil, nil, nil, nil, body_612939)

var stopTrigger* = Call_StopTrigger_612925(name: "stopTrigger",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StopTrigger",
                                        validator: validate_StopTrigger_612926,
                                        base: "/", url: url_StopTrigger_612927,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_612940 = ref object of OpenApiRestCall_610658
proc url_TagResource_612942(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_612941(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
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
  var valid_612943 = header.getOrDefault("X-Amz-Target")
  valid_612943 = validateParameter(valid_612943, JString, required = true,
                                 default = newJString("AWSGlue.TagResource"))
  if valid_612943 != nil:
    section.add "X-Amz-Target", valid_612943
  var valid_612944 = header.getOrDefault("X-Amz-Signature")
  valid_612944 = validateParameter(valid_612944, JString, required = false,
                                 default = nil)
  if valid_612944 != nil:
    section.add "X-Amz-Signature", valid_612944
  var valid_612945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612945 = validateParameter(valid_612945, JString, required = false,
                                 default = nil)
  if valid_612945 != nil:
    section.add "X-Amz-Content-Sha256", valid_612945
  var valid_612946 = header.getOrDefault("X-Amz-Date")
  valid_612946 = validateParameter(valid_612946, JString, required = false,
                                 default = nil)
  if valid_612946 != nil:
    section.add "X-Amz-Date", valid_612946
  var valid_612947 = header.getOrDefault("X-Amz-Credential")
  valid_612947 = validateParameter(valid_612947, JString, required = false,
                                 default = nil)
  if valid_612947 != nil:
    section.add "X-Amz-Credential", valid_612947
  var valid_612948 = header.getOrDefault("X-Amz-Security-Token")
  valid_612948 = validateParameter(valid_612948, JString, required = false,
                                 default = nil)
  if valid_612948 != nil:
    section.add "X-Amz-Security-Token", valid_612948
  var valid_612949 = header.getOrDefault("X-Amz-Algorithm")
  valid_612949 = validateParameter(valid_612949, JString, required = false,
                                 default = nil)
  if valid_612949 != nil:
    section.add "X-Amz-Algorithm", valid_612949
  var valid_612950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612950 = validateParameter(valid_612950, JString, required = false,
                                 default = nil)
  if valid_612950 != nil:
    section.add "X-Amz-SignedHeaders", valid_612950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612952: Call_TagResource_612940; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
  ## 
  let valid = call_612952.validator(path, query, header, formData, body)
  let scheme = call_612952.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612952.url(scheme.get, call_612952.host, call_612952.base,
                         call_612952.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612952, url, valid)

proc call*(call_612953: Call_TagResource_612940; body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
  ##   body: JObject (required)
  var body_612954 = newJObject()
  if body != nil:
    body_612954 = body
  result = call_612953.call(nil, nil, nil, nil, body_612954)

var tagResource* = Call_TagResource_612940(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.TagResource",
                                        validator: validate_TagResource_612941,
                                        base: "/", url: url_TagResource_612942,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_612955 = ref object of OpenApiRestCall_610658
proc url_UntagResource_612957(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_612956(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes tags from a resource.
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
  var valid_612958 = header.getOrDefault("X-Amz-Target")
  valid_612958 = validateParameter(valid_612958, JString, required = true,
                                 default = newJString("AWSGlue.UntagResource"))
  if valid_612958 != nil:
    section.add "X-Amz-Target", valid_612958
  var valid_612959 = header.getOrDefault("X-Amz-Signature")
  valid_612959 = validateParameter(valid_612959, JString, required = false,
                                 default = nil)
  if valid_612959 != nil:
    section.add "X-Amz-Signature", valid_612959
  var valid_612960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612960 = validateParameter(valid_612960, JString, required = false,
                                 default = nil)
  if valid_612960 != nil:
    section.add "X-Amz-Content-Sha256", valid_612960
  var valid_612961 = header.getOrDefault("X-Amz-Date")
  valid_612961 = validateParameter(valid_612961, JString, required = false,
                                 default = nil)
  if valid_612961 != nil:
    section.add "X-Amz-Date", valid_612961
  var valid_612962 = header.getOrDefault("X-Amz-Credential")
  valid_612962 = validateParameter(valid_612962, JString, required = false,
                                 default = nil)
  if valid_612962 != nil:
    section.add "X-Amz-Credential", valid_612962
  var valid_612963 = header.getOrDefault("X-Amz-Security-Token")
  valid_612963 = validateParameter(valid_612963, JString, required = false,
                                 default = nil)
  if valid_612963 != nil:
    section.add "X-Amz-Security-Token", valid_612963
  var valid_612964 = header.getOrDefault("X-Amz-Algorithm")
  valid_612964 = validateParameter(valid_612964, JString, required = false,
                                 default = nil)
  if valid_612964 != nil:
    section.add "X-Amz-Algorithm", valid_612964
  var valid_612965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612965 = validateParameter(valid_612965, JString, required = false,
                                 default = nil)
  if valid_612965 != nil:
    section.add "X-Amz-SignedHeaders", valid_612965
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612967: Call_UntagResource_612955; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a resource.
  ## 
  let valid = call_612967.validator(path, query, header, formData, body)
  let scheme = call_612967.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612967.url(scheme.get, call_612967.host, call_612967.base,
                         call_612967.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612967, url, valid)

proc call*(call_612968: Call_UntagResource_612955; body: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from a resource.
  ##   body: JObject (required)
  var body_612969 = newJObject()
  if body != nil:
    body_612969 = body
  result = call_612968.call(nil, nil, nil, nil, body_612969)

var untagResource* = Call_UntagResource_612955(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UntagResource",
    validator: validate_UntagResource_612956, base: "/", url: url_UntagResource_612957,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClassifier_612970 = ref object of OpenApiRestCall_610658
proc url_UpdateClassifier_612972(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateClassifier_612971(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
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
  var valid_612973 = header.getOrDefault("X-Amz-Target")
  valid_612973 = validateParameter(valid_612973, JString, required = true, default = newJString(
      "AWSGlue.UpdateClassifier"))
  if valid_612973 != nil:
    section.add "X-Amz-Target", valid_612973
  var valid_612974 = header.getOrDefault("X-Amz-Signature")
  valid_612974 = validateParameter(valid_612974, JString, required = false,
                                 default = nil)
  if valid_612974 != nil:
    section.add "X-Amz-Signature", valid_612974
  var valid_612975 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612975 = validateParameter(valid_612975, JString, required = false,
                                 default = nil)
  if valid_612975 != nil:
    section.add "X-Amz-Content-Sha256", valid_612975
  var valid_612976 = header.getOrDefault("X-Amz-Date")
  valid_612976 = validateParameter(valid_612976, JString, required = false,
                                 default = nil)
  if valid_612976 != nil:
    section.add "X-Amz-Date", valid_612976
  var valid_612977 = header.getOrDefault("X-Amz-Credential")
  valid_612977 = validateParameter(valid_612977, JString, required = false,
                                 default = nil)
  if valid_612977 != nil:
    section.add "X-Amz-Credential", valid_612977
  var valid_612978 = header.getOrDefault("X-Amz-Security-Token")
  valid_612978 = validateParameter(valid_612978, JString, required = false,
                                 default = nil)
  if valid_612978 != nil:
    section.add "X-Amz-Security-Token", valid_612978
  var valid_612979 = header.getOrDefault("X-Amz-Algorithm")
  valid_612979 = validateParameter(valid_612979, JString, required = false,
                                 default = nil)
  if valid_612979 != nil:
    section.add "X-Amz-Algorithm", valid_612979
  var valid_612980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612980 = validateParameter(valid_612980, JString, required = false,
                                 default = nil)
  if valid_612980 != nil:
    section.add "X-Amz-SignedHeaders", valid_612980
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612982: Call_UpdateClassifier_612970; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
  ## 
  let valid = call_612982.validator(path, query, header, formData, body)
  let scheme = call_612982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612982.url(scheme.get, call_612982.host, call_612982.base,
                         call_612982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612982, url, valid)

proc call*(call_612983: Call_UpdateClassifier_612970; body: JsonNode): Recallable =
  ## updateClassifier
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
  ##   body: JObject (required)
  var body_612984 = newJObject()
  if body != nil:
    body_612984 = body
  result = call_612983.call(nil, nil, nil, nil, body_612984)

var updateClassifier* = Call_UpdateClassifier_612970(name: "updateClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateClassifier",
    validator: validate_UpdateClassifier_612971, base: "/",
    url: url_UpdateClassifier_612972, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnection_612985 = ref object of OpenApiRestCall_610658
proc url_UpdateConnection_612987(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateConnection_612986(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates a connection definition in the Data Catalog.
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
  var valid_612988 = header.getOrDefault("X-Amz-Target")
  valid_612988 = validateParameter(valid_612988, JString, required = true, default = newJString(
      "AWSGlue.UpdateConnection"))
  if valid_612988 != nil:
    section.add "X-Amz-Target", valid_612988
  var valid_612989 = header.getOrDefault("X-Amz-Signature")
  valid_612989 = validateParameter(valid_612989, JString, required = false,
                                 default = nil)
  if valid_612989 != nil:
    section.add "X-Amz-Signature", valid_612989
  var valid_612990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612990 = validateParameter(valid_612990, JString, required = false,
                                 default = nil)
  if valid_612990 != nil:
    section.add "X-Amz-Content-Sha256", valid_612990
  var valid_612991 = header.getOrDefault("X-Amz-Date")
  valid_612991 = validateParameter(valid_612991, JString, required = false,
                                 default = nil)
  if valid_612991 != nil:
    section.add "X-Amz-Date", valid_612991
  var valid_612992 = header.getOrDefault("X-Amz-Credential")
  valid_612992 = validateParameter(valid_612992, JString, required = false,
                                 default = nil)
  if valid_612992 != nil:
    section.add "X-Amz-Credential", valid_612992
  var valid_612993 = header.getOrDefault("X-Amz-Security-Token")
  valid_612993 = validateParameter(valid_612993, JString, required = false,
                                 default = nil)
  if valid_612993 != nil:
    section.add "X-Amz-Security-Token", valid_612993
  var valid_612994 = header.getOrDefault("X-Amz-Algorithm")
  valid_612994 = validateParameter(valid_612994, JString, required = false,
                                 default = nil)
  if valid_612994 != nil:
    section.add "X-Amz-Algorithm", valid_612994
  var valid_612995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612995 = validateParameter(valid_612995, JString, required = false,
                                 default = nil)
  if valid_612995 != nil:
    section.add "X-Amz-SignedHeaders", valid_612995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612997: Call_UpdateConnection_612985; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a connection definition in the Data Catalog.
  ## 
  let valid = call_612997.validator(path, query, header, formData, body)
  let scheme = call_612997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612997.url(scheme.get, call_612997.host, call_612997.base,
                         call_612997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612997, url, valid)

proc call*(call_612998: Call_UpdateConnection_612985; body: JsonNode): Recallable =
  ## updateConnection
  ## Updates a connection definition in the Data Catalog.
  ##   body: JObject (required)
  var body_612999 = newJObject()
  if body != nil:
    body_612999 = body
  result = call_612998.call(nil, nil, nil, nil, body_612999)

var updateConnection* = Call_UpdateConnection_612985(name: "updateConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateConnection",
    validator: validate_UpdateConnection_612986, base: "/",
    url: url_UpdateConnection_612987, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCrawler_613000 = ref object of OpenApiRestCall_610658
proc url_UpdateCrawler_613002(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateCrawler_613001(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
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
  var valid_613003 = header.getOrDefault("X-Amz-Target")
  valid_613003 = validateParameter(valid_613003, JString, required = true,
                                 default = newJString("AWSGlue.UpdateCrawler"))
  if valid_613003 != nil:
    section.add "X-Amz-Target", valid_613003
  var valid_613004 = header.getOrDefault("X-Amz-Signature")
  valid_613004 = validateParameter(valid_613004, JString, required = false,
                                 default = nil)
  if valid_613004 != nil:
    section.add "X-Amz-Signature", valid_613004
  var valid_613005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613005 = validateParameter(valid_613005, JString, required = false,
                                 default = nil)
  if valid_613005 != nil:
    section.add "X-Amz-Content-Sha256", valid_613005
  var valid_613006 = header.getOrDefault("X-Amz-Date")
  valid_613006 = validateParameter(valid_613006, JString, required = false,
                                 default = nil)
  if valid_613006 != nil:
    section.add "X-Amz-Date", valid_613006
  var valid_613007 = header.getOrDefault("X-Amz-Credential")
  valid_613007 = validateParameter(valid_613007, JString, required = false,
                                 default = nil)
  if valid_613007 != nil:
    section.add "X-Amz-Credential", valid_613007
  var valid_613008 = header.getOrDefault("X-Amz-Security-Token")
  valid_613008 = validateParameter(valid_613008, JString, required = false,
                                 default = nil)
  if valid_613008 != nil:
    section.add "X-Amz-Security-Token", valid_613008
  var valid_613009 = header.getOrDefault("X-Amz-Algorithm")
  valid_613009 = validateParameter(valid_613009, JString, required = false,
                                 default = nil)
  if valid_613009 != nil:
    section.add "X-Amz-Algorithm", valid_613009
  var valid_613010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613010 = validateParameter(valid_613010, JString, required = false,
                                 default = nil)
  if valid_613010 != nil:
    section.add "X-Amz-SignedHeaders", valid_613010
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613012: Call_UpdateCrawler_613000; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
  ## 
  let valid = call_613012.validator(path, query, header, formData, body)
  let scheme = call_613012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613012.url(scheme.get, call_613012.host, call_613012.base,
                         call_613012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613012, url, valid)

proc call*(call_613013: Call_UpdateCrawler_613000; body: JsonNode): Recallable =
  ## updateCrawler
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
  ##   body: JObject (required)
  var body_613014 = newJObject()
  if body != nil:
    body_613014 = body
  result = call_613013.call(nil, nil, nil, nil, body_613014)

var updateCrawler* = Call_UpdateCrawler_613000(name: "updateCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateCrawler",
    validator: validate_UpdateCrawler_613001, base: "/", url: url_UpdateCrawler_613002,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCrawlerSchedule_613015 = ref object of OpenApiRestCall_610658
proc url_UpdateCrawlerSchedule_613017(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateCrawlerSchedule_613016(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
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
  var valid_613018 = header.getOrDefault("X-Amz-Target")
  valid_613018 = validateParameter(valid_613018, JString, required = true, default = newJString(
      "AWSGlue.UpdateCrawlerSchedule"))
  if valid_613018 != nil:
    section.add "X-Amz-Target", valid_613018
  var valid_613019 = header.getOrDefault("X-Amz-Signature")
  valid_613019 = validateParameter(valid_613019, JString, required = false,
                                 default = nil)
  if valid_613019 != nil:
    section.add "X-Amz-Signature", valid_613019
  var valid_613020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613020 = validateParameter(valid_613020, JString, required = false,
                                 default = nil)
  if valid_613020 != nil:
    section.add "X-Amz-Content-Sha256", valid_613020
  var valid_613021 = header.getOrDefault("X-Amz-Date")
  valid_613021 = validateParameter(valid_613021, JString, required = false,
                                 default = nil)
  if valid_613021 != nil:
    section.add "X-Amz-Date", valid_613021
  var valid_613022 = header.getOrDefault("X-Amz-Credential")
  valid_613022 = validateParameter(valid_613022, JString, required = false,
                                 default = nil)
  if valid_613022 != nil:
    section.add "X-Amz-Credential", valid_613022
  var valid_613023 = header.getOrDefault("X-Amz-Security-Token")
  valid_613023 = validateParameter(valid_613023, JString, required = false,
                                 default = nil)
  if valid_613023 != nil:
    section.add "X-Amz-Security-Token", valid_613023
  var valid_613024 = header.getOrDefault("X-Amz-Algorithm")
  valid_613024 = validateParameter(valid_613024, JString, required = false,
                                 default = nil)
  if valid_613024 != nil:
    section.add "X-Amz-Algorithm", valid_613024
  var valid_613025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613025 = validateParameter(valid_613025, JString, required = false,
                                 default = nil)
  if valid_613025 != nil:
    section.add "X-Amz-SignedHeaders", valid_613025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613027: Call_UpdateCrawlerSchedule_613015; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
  ## 
  let valid = call_613027.validator(path, query, header, formData, body)
  let scheme = call_613027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613027.url(scheme.get, call_613027.host, call_613027.base,
                         call_613027.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613027, url, valid)

proc call*(call_613028: Call_UpdateCrawlerSchedule_613015; body: JsonNode): Recallable =
  ## updateCrawlerSchedule
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
  ##   body: JObject (required)
  var body_613029 = newJObject()
  if body != nil:
    body_613029 = body
  result = call_613028.call(nil, nil, nil, nil, body_613029)

var updateCrawlerSchedule* = Call_UpdateCrawlerSchedule_613015(
    name: "updateCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateCrawlerSchedule",
    validator: validate_UpdateCrawlerSchedule_613016, base: "/",
    url: url_UpdateCrawlerSchedule_613017, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDatabase_613030 = ref object of OpenApiRestCall_610658
proc url_UpdateDatabase_613032(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDatabase_613031(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates an existing database definition in a Data Catalog.
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
  var valid_613033 = header.getOrDefault("X-Amz-Target")
  valid_613033 = validateParameter(valid_613033, JString, required = true,
                                 default = newJString("AWSGlue.UpdateDatabase"))
  if valid_613033 != nil:
    section.add "X-Amz-Target", valid_613033
  var valid_613034 = header.getOrDefault("X-Amz-Signature")
  valid_613034 = validateParameter(valid_613034, JString, required = false,
                                 default = nil)
  if valid_613034 != nil:
    section.add "X-Amz-Signature", valid_613034
  var valid_613035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613035 = validateParameter(valid_613035, JString, required = false,
                                 default = nil)
  if valid_613035 != nil:
    section.add "X-Amz-Content-Sha256", valid_613035
  var valid_613036 = header.getOrDefault("X-Amz-Date")
  valid_613036 = validateParameter(valid_613036, JString, required = false,
                                 default = nil)
  if valid_613036 != nil:
    section.add "X-Amz-Date", valid_613036
  var valid_613037 = header.getOrDefault("X-Amz-Credential")
  valid_613037 = validateParameter(valid_613037, JString, required = false,
                                 default = nil)
  if valid_613037 != nil:
    section.add "X-Amz-Credential", valid_613037
  var valid_613038 = header.getOrDefault("X-Amz-Security-Token")
  valid_613038 = validateParameter(valid_613038, JString, required = false,
                                 default = nil)
  if valid_613038 != nil:
    section.add "X-Amz-Security-Token", valid_613038
  var valid_613039 = header.getOrDefault("X-Amz-Algorithm")
  valid_613039 = validateParameter(valid_613039, JString, required = false,
                                 default = nil)
  if valid_613039 != nil:
    section.add "X-Amz-Algorithm", valid_613039
  var valid_613040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613040 = validateParameter(valid_613040, JString, required = false,
                                 default = nil)
  if valid_613040 != nil:
    section.add "X-Amz-SignedHeaders", valid_613040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613042: Call_UpdateDatabase_613030; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing database definition in a Data Catalog.
  ## 
  let valid = call_613042.validator(path, query, header, formData, body)
  let scheme = call_613042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613042.url(scheme.get, call_613042.host, call_613042.base,
                         call_613042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613042, url, valid)

proc call*(call_613043: Call_UpdateDatabase_613030; body: JsonNode): Recallable =
  ## updateDatabase
  ## Updates an existing database definition in a Data Catalog.
  ##   body: JObject (required)
  var body_613044 = newJObject()
  if body != nil:
    body_613044 = body
  result = call_613043.call(nil, nil, nil, nil, body_613044)

var updateDatabase* = Call_UpdateDatabase_613030(name: "updateDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateDatabase",
    validator: validate_UpdateDatabase_613031, base: "/", url: url_UpdateDatabase_613032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevEndpoint_613045 = ref object of OpenApiRestCall_610658
proc url_UpdateDevEndpoint_613047(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDevEndpoint_613046(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates a specified development endpoint.
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
  var valid_613048 = header.getOrDefault("X-Amz-Target")
  valid_613048 = validateParameter(valid_613048, JString, required = true, default = newJString(
      "AWSGlue.UpdateDevEndpoint"))
  if valid_613048 != nil:
    section.add "X-Amz-Target", valid_613048
  var valid_613049 = header.getOrDefault("X-Amz-Signature")
  valid_613049 = validateParameter(valid_613049, JString, required = false,
                                 default = nil)
  if valid_613049 != nil:
    section.add "X-Amz-Signature", valid_613049
  var valid_613050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613050 = validateParameter(valid_613050, JString, required = false,
                                 default = nil)
  if valid_613050 != nil:
    section.add "X-Amz-Content-Sha256", valid_613050
  var valid_613051 = header.getOrDefault("X-Amz-Date")
  valid_613051 = validateParameter(valid_613051, JString, required = false,
                                 default = nil)
  if valid_613051 != nil:
    section.add "X-Amz-Date", valid_613051
  var valid_613052 = header.getOrDefault("X-Amz-Credential")
  valid_613052 = validateParameter(valid_613052, JString, required = false,
                                 default = nil)
  if valid_613052 != nil:
    section.add "X-Amz-Credential", valid_613052
  var valid_613053 = header.getOrDefault("X-Amz-Security-Token")
  valid_613053 = validateParameter(valid_613053, JString, required = false,
                                 default = nil)
  if valid_613053 != nil:
    section.add "X-Amz-Security-Token", valid_613053
  var valid_613054 = header.getOrDefault("X-Amz-Algorithm")
  valid_613054 = validateParameter(valid_613054, JString, required = false,
                                 default = nil)
  if valid_613054 != nil:
    section.add "X-Amz-Algorithm", valid_613054
  var valid_613055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613055 = validateParameter(valid_613055, JString, required = false,
                                 default = nil)
  if valid_613055 != nil:
    section.add "X-Amz-SignedHeaders", valid_613055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613057: Call_UpdateDevEndpoint_613045; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a specified development endpoint.
  ## 
  let valid = call_613057.validator(path, query, header, formData, body)
  let scheme = call_613057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613057.url(scheme.get, call_613057.host, call_613057.base,
                         call_613057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613057, url, valid)

proc call*(call_613058: Call_UpdateDevEndpoint_613045; body: JsonNode): Recallable =
  ## updateDevEndpoint
  ## Updates a specified development endpoint.
  ##   body: JObject (required)
  var body_613059 = newJObject()
  if body != nil:
    body_613059 = body
  result = call_613058.call(nil, nil, nil, nil, body_613059)

var updateDevEndpoint* = Call_UpdateDevEndpoint_613045(name: "updateDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateDevEndpoint",
    validator: validate_UpdateDevEndpoint_613046, base: "/",
    url: url_UpdateDevEndpoint_613047, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJob_613060 = ref object of OpenApiRestCall_610658
proc url_UpdateJob_613062(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateJob_613061(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing job definition.
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
  var valid_613063 = header.getOrDefault("X-Amz-Target")
  valid_613063 = validateParameter(valid_613063, JString, required = true,
                                 default = newJString("AWSGlue.UpdateJob"))
  if valid_613063 != nil:
    section.add "X-Amz-Target", valid_613063
  var valid_613064 = header.getOrDefault("X-Amz-Signature")
  valid_613064 = validateParameter(valid_613064, JString, required = false,
                                 default = nil)
  if valid_613064 != nil:
    section.add "X-Amz-Signature", valid_613064
  var valid_613065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613065 = validateParameter(valid_613065, JString, required = false,
                                 default = nil)
  if valid_613065 != nil:
    section.add "X-Amz-Content-Sha256", valid_613065
  var valid_613066 = header.getOrDefault("X-Amz-Date")
  valid_613066 = validateParameter(valid_613066, JString, required = false,
                                 default = nil)
  if valid_613066 != nil:
    section.add "X-Amz-Date", valid_613066
  var valid_613067 = header.getOrDefault("X-Amz-Credential")
  valid_613067 = validateParameter(valid_613067, JString, required = false,
                                 default = nil)
  if valid_613067 != nil:
    section.add "X-Amz-Credential", valid_613067
  var valid_613068 = header.getOrDefault("X-Amz-Security-Token")
  valid_613068 = validateParameter(valid_613068, JString, required = false,
                                 default = nil)
  if valid_613068 != nil:
    section.add "X-Amz-Security-Token", valid_613068
  var valid_613069 = header.getOrDefault("X-Amz-Algorithm")
  valid_613069 = validateParameter(valid_613069, JString, required = false,
                                 default = nil)
  if valid_613069 != nil:
    section.add "X-Amz-Algorithm", valid_613069
  var valid_613070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613070 = validateParameter(valid_613070, JString, required = false,
                                 default = nil)
  if valid_613070 != nil:
    section.add "X-Amz-SignedHeaders", valid_613070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613072: Call_UpdateJob_613060; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing job definition.
  ## 
  let valid = call_613072.validator(path, query, header, formData, body)
  let scheme = call_613072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613072.url(scheme.get, call_613072.host, call_613072.base,
                         call_613072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613072, url, valid)

proc call*(call_613073: Call_UpdateJob_613060; body: JsonNode): Recallable =
  ## updateJob
  ## Updates an existing job definition.
  ##   body: JObject (required)
  var body_613074 = newJObject()
  if body != nil:
    body_613074 = body
  result = call_613073.call(nil, nil, nil, nil, body_613074)

var updateJob* = Call_UpdateJob_613060(name: "updateJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.UpdateJob",
                                    validator: validate_UpdateJob_613061,
                                    base: "/", url: url_UpdateJob_613062,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMLTransform_613075 = ref object of OpenApiRestCall_610658
proc url_UpdateMLTransform_613077(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateMLTransform_613076(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
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
  var valid_613078 = header.getOrDefault("X-Amz-Target")
  valid_613078 = validateParameter(valid_613078, JString, required = true, default = newJString(
      "AWSGlue.UpdateMLTransform"))
  if valid_613078 != nil:
    section.add "X-Amz-Target", valid_613078
  var valid_613079 = header.getOrDefault("X-Amz-Signature")
  valid_613079 = validateParameter(valid_613079, JString, required = false,
                                 default = nil)
  if valid_613079 != nil:
    section.add "X-Amz-Signature", valid_613079
  var valid_613080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613080 = validateParameter(valid_613080, JString, required = false,
                                 default = nil)
  if valid_613080 != nil:
    section.add "X-Amz-Content-Sha256", valid_613080
  var valid_613081 = header.getOrDefault("X-Amz-Date")
  valid_613081 = validateParameter(valid_613081, JString, required = false,
                                 default = nil)
  if valid_613081 != nil:
    section.add "X-Amz-Date", valid_613081
  var valid_613082 = header.getOrDefault("X-Amz-Credential")
  valid_613082 = validateParameter(valid_613082, JString, required = false,
                                 default = nil)
  if valid_613082 != nil:
    section.add "X-Amz-Credential", valid_613082
  var valid_613083 = header.getOrDefault("X-Amz-Security-Token")
  valid_613083 = validateParameter(valid_613083, JString, required = false,
                                 default = nil)
  if valid_613083 != nil:
    section.add "X-Amz-Security-Token", valid_613083
  var valid_613084 = header.getOrDefault("X-Amz-Algorithm")
  valid_613084 = validateParameter(valid_613084, JString, required = false,
                                 default = nil)
  if valid_613084 != nil:
    section.add "X-Amz-Algorithm", valid_613084
  var valid_613085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613085 = validateParameter(valid_613085, JString, required = false,
                                 default = nil)
  if valid_613085 != nil:
    section.add "X-Amz-SignedHeaders", valid_613085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613087: Call_UpdateMLTransform_613075; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
  ## 
  let valid = call_613087.validator(path, query, header, formData, body)
  let scheme = call_613087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613087.url(scheme.get, call_613087.host, call_613087.base,
                         call_613087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613087, url, valid)

proc call*(call_613088: Call_UpdateMLTransform_613075; body: JsonNode): Recallable =
  ## updateMLTransform
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
  ##   body: JObject (required)
  var body_613089 = newJObject()
  if body != nil:
    body_613089 = body
  result = call_613088.call(nil, nil, nil, nil, body_613089)

var updateMLTransform* = Call_UpdateMLTransform_613075(name: "updateMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateMLTransform",
    validator: validate_UpdateMLTransform_613076, base: "/",
    url: url_UpdateMLTransform_613077, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePartition_613090 = ref object of OpenApiRestCall_610658
proc url_UpdatePartition_613092(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePartition_613091(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Updates a partition.
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
  var valid_613093 = header.getOrDefault("X-Amz-Target")
  valid_613093 = validateParameter(valid_613093, JString, required = true, default = newJString(
      "AWSGlue.UpdatePartition"))
  if valid_613093 != nil:
    section.add "X-Amz-Target", valid_613093
  var valid_613094 = header.getOrDefault("X-Amz-Signature")
  valid_613094 = validateParameter(valid_613094, JString, required = false,
                                 default = nil)
  if valid_613094 != nil:
    section.add "X-Amz-Signature", valid_613094
  var valid_613095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613095 = validateParameter(valid_613095, JString, required = false,
                                 default = nil)
  if valid_613095 != nil:
    section.add "X-Amz-Content-Sha256", valid_613095
  var valid_613096 = header.getOrDefault("X-Amz-Date")
  valid_613096 = validateParameter(valid_613096, JString, required = false,
                                 default = nil)
  if valid_613096 != nil:
    section.add "X-Amz-Date", valid_613096
  var valid_613097 = header.getOrDefault("X-Amz-Credential")
  valid_613097 = validateParameter(valid_613097, JString, required = false,
                                 default = nil)
  if valid_613097 != nil:
    section.add "X-Amz-Credential", valid_613097
  var valid_613098 = header.getOrDefault("X-Amz-Security-Token")
  valid_613098 = validateParameter(valid_613098, JString, required = false,
                                 default = nil)
  if valid_613098 != nil:
    section.add "X-Amz-Security-Token", valid_613098
  var valid_613099 = header.getOrDefault("X-Amz-Algorithm")
  valid_613099 = validateParameter(valid_613099, JString, required = false,
                                 default = nil)
  if valid_613099 != nil:
    section.add "X-Amz-Algorithm", valid_613099
  var valid_613100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613100 = validateParameter(valid_613100, JString, required = false,
                                 default = nil)
  if valid_613100 != nil:
    section.add "X-Amz-SignedHeaders", valid_613100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613102: Call_UpdatePartition_613090; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a partition.
  ## 
  let valid = call_613102.validator(path, query, header, formData, body)
  let scheme = call_613102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613102.url(scheme.get, call_613102.host, call_613102.base,
                         call_613102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613102, url, valid)

proc call*(call_613103: Call_UpdatePartition_613090; body: JsonNode): Recallable =
  ## updatePartition
  ## Updates a partition.
  ##   body: JObject (required)
  var body_613104 = newJObject()
  if body != nil:
    body_613104 = body
  result = call_613103.call(nil, nil, nil, nil, body_613104)

var updatePartition* = Call_UpdatePartition_613090(name: "updatePartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdatePartition",
    validator: validate_UpdatePartition_613091, base: "/", url: url_UpdatePartition_613092,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTable_613105 = ref object of OpenApiRestCall_610658
proc url_UpdateTable_613107(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTable_613106(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a metadata table in the Data Catalog.
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
  var valid_613108 = header.getOrDefault("X-Amz-Target")
  valid_613108 = validateParameter(valid_613108, JString, required = true,
                                 default = newJString("AWSGlue.UpdateTable"))
  if valid_613108 != nil:
    section.add "X-Amz-Target", valid_613108
  var valid_613109 = header.getOrDefault("X-Amz-Signature")
  valid_613109 = validateParameter(valid_613109, JString, required = false,
                                 default = nil)
  if valid_613109 != nil:
    section.add "X-Amz-Signature", valid_613109
  var valid_613110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "X-Amz-Content-Sha256", valid_613110
  var valid_613111 = header.getOrDefault("X-Amz-Date")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "X-Amz-Date", valid_613111
  var valid_613112 = header.getOrDefault("X-Amz-Credential")
  valid_613112 = validateParameter(valid_613112, JString, required = false,
                                 default = nil)
  if valid_613112 != nil:
    section.add "X-Amz-Credential", valid_613112
  var valid_613113 = header.getOrDefault("X-Amz-Security-Token")
  valid_613113 = validateParameter(valid_613113, JString, required = false,
                                 default = nil)
  if valid_613113 != nil:
    section.add "X-Amz-Security-Token", valid_613113
  var valid_613114 = header.getOrDefault("X-Amz-Algorithm")
  valid_613114 = validateParameter(valid_613114, JString, required = false,
                                 default = nil)
  if valid_613114 != nil:
    section.add "X-Amz-Algorithm", valid_613114
  var valid_613115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613115 = validateParameter(valid_613115, JString, required = false,
                                 default = nil)
  if valid_613115 != nil:
    section.add "X-Amz-SignedHeaders", valid_613115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613117: Call_UpdateTable_613105; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a metadata table in the Data Catalog.
  ## 
  let valid = call_613117.validator(path, query, header, formData, body)
  let scheme = call_613117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613117.url(scheme.get, call_613117.host, call_613117.base,
                         call_613117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613117, url, valid)

proc call*(call_613118: Call_UpdateTable_613105; body: JsonNode): Recallable =
  ## updateTable
  ## Updates a metadata table in the Data Catalog.
  ##   body: JObject (required)
  var body_613119 = newJObject()
  if body != nil:
    body_613119 = body
  result = call_613118.call(nil, nil, nil, nil, body_613119)

var updateTable* = Call_UpdateTable_613105(name: "updateTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.UpdateTable",
                                        validator: validate_UpdateTable_613106,
                                        base: "/", url: url_UpdateTable_613107,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrigger_613120 = ref object of OpenApiRestCall_610658
proc url_UpdateTrigger_613122(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTrigger_613121(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a trigger definition.
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
  var valid_613123 = header.getOrDefault("X-Amz-Target")
  valid_613123 = validateParameter(valid_613123, JString, required = true,
                                 default = newJString("AWSGlue.UpdateTrigger"))
  if valid_613123 != nil:
    section.add "X-Amz-Target", valid_613123
  var valid_613124 = header.getOrDefault("X-Amz-Signature")
  valid_613124 = validateParameter(valid_613124, JString, required = false,
                                 default = nil)
  if valid_613124 != nil:
    section.add "X-Amz-Signature", valid_613124
  var valid_613125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-Content-Sha256", valid_613125
  var valid_613126 = header.getOrDefault("X-Amz-Date")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Date", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Credential")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Credential", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Security-Token")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Security-Token", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Algorithm")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Algorithm", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-SignedHeaders", valid_613130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613132: Call_UpdateTrigger_613120; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a trigger definition.
  ## 
  let valid = call_613132.validator(path, query, header, formData, body)
  let scheme = call_613132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613132.url(scheme.get, call_613132.host, call_613132.base,
                         call_613132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613132, url, valid)

proc call*(call_613133: Call_UpdateTrigger_613120; body: JsonNode): Recallable =
  ## updateTrigger
  ## Updates a trigger definition.
  ##   body: JObject (required)
  var body_613134 = newJObject()
  if body != nil:
    body_613134 = body
  result = call_613133.call(nil, nil, nil, nil, body_613134)

var updateTrigger* = Call_UpdateTrigger_613120(name: "updateTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateTrigger",
    validator: validate_UpdateTrigger_613121, base: "/", url: url_UpdateTrigger_613122,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserDefinedFunction_613135 = ref object of OpenApiRestCall_610658
proc url_UpdateUserDefinedFunction_613137(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUserDefinedFunction_613136(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing function definition in the Data Catalog.
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
  var valid_613138 = header.getOrDefault("X-Amz-Target")
  valid_613138 = validateParameter(valid_613138, JString, required = true, default = newJString(
      "AWSGlue.UpdateUserDefinedFunction"))
  if valid_613138 != nil:
    section.add "X-Amz-Target", valid_613138
  var valid_613139 = header.getOrDefault("X-Amz-Signature")
  valid_613139 = validateParameter(valid_613139, JString, required = false,
                                 default = nil)
  if valid_613139 != nil:
    section.add "X-Amz-Signature", valid_613139
  var valid_613140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613140 = validateParameter(valid_613140, JString, required = false,
                                 default = nil)
  if valid_613140 != nil:
    section.add "X-Amz-Content-Sha256", valid_613140
  var valid_613141 = header.getOrDefault("X-Amz-Date")
  valid_613141 = validateParameter(valid_613141, JString, required = false,
                                 default = nil)
  if valid_613141 != nil:
    section.add "X-Amz-Date", valid_613141
  var valid_613142 = header.getOrDefault("X-Amz-Credential")
  valid_613142 = validateParameter(valid_613142, JString, required = false,
                                 default = nil)
  if valid_613142 != nil:
    section.add "X-Amz-Credential", valid_613142
  var valid_613143 = header.getOrDefault("X-Amz-Security-Token")
  valid_613143 = validateParameter(valid_613143, JString, required = false,
                                 default = nil)
  if valid_613143 != nil:
    section.add "X-Amz-Security-Token", valid_613143
  var valid_613144 = header.getOrDefault("X-Amz-Algorithm")
  valid_613144 = validateParameter(valid_613144, JString, required = false,
                                 default = nil)
  if valid_613144 != nil:
    section.add "X-Amz-Algorithm", valid_613144
  var valid_613145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613145 = validateParameter(valid_613145, JString, required = false,
                                 default = nil)
  if valid_613145 != nil:
    section.add "X-Amz-SignedHeaders", valid_613145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613147: Call_UpdateUserDefinedFunction_613135; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing function definition in the Data Catalog.
  ## 
  let valid = call_613147.validator(path, query, header, formData, body)
  let scheme = call_613147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613147.url(scheme.get, call_613147.host, call_613147.base,
                         call_613147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613147, url, valid)

proc call*(call_613148: Call_UpdateUserDefinedFunction_613135; body: JsonNode): Recallable =
  ## updateUserDefinedFunction
  ## Updates an existing function definition in the Data Catalog.
  ##   body: JObject (required)
  var body_613149 = newJObject()
  if body != nil:
    body_613149 = body
  result = call_613148.call(nil, nil, nil, nil, body_613149)

var updateUserDefinedFunction* = Call_UpdateUserDefinedFunction_613135(
    name: "updateUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateUserDefinedFunction",
    validator: validate_UpdateUserDefinedFunction_613136, base: "/",
    url: url_UpdateUserDefinedFunction_613137,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkflow_613150 = ref object of OpenApiRestCall_610658
proc url_UpdateWorkflow_613152(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateWorkflow_613151(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates an existing workflow.
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
  var valid_613153 = header.getOrDefault("X-Amz-Target")
  valid_613153 = validateParameter(valid_613153, JString, required = true,
                                 default = newJString("AWSGlue.UpdateWorkflow"))
  if valid_613153 != nil:
    section.add "X-Amz-Target", valid_613153
  var valid_613154 = header.getOrDefault("X-Amz-Signature")
  valid_613154 = validateParameter(valid_613154, JString, required = false,
                                 default = nil)
  if valid_613154 != nil:
    section.add "X-Amz-Signature", valid_613154
  var valid_613155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613155 = validateParameter(valid_613155, JString, required = false,
                                 default = nil)
  if valid_613155 != nil:
    section.add "X-Amz-Content-Sha256", valid_613155
  var valid_613156 = header.getOrDefault("X-Amz-Date")
  valid_613156 = validateParameter(valid_613156, JString, required = false,
                                 default = nil)
  if valid_613156 != nil:
    section.add "X-Amz-Date", valid_613156
  var valid_613157 = header.getOrDefault("X-Amz-Credential")
  valid_613157 = validateParameter(valid_613157, JString, required = false,
                                 default = nil)
  if valid_613157 != nil:
    section.add "X-Amz-Credential", valid_613157
  var valid_613158 = header.getOrDefault("X-Amz-Security-Token")
  valid_613158 = validateParameter(valid_613158, JString, required = false,
                                 default = nil)
  if valid_613158 != nil:
    section.add "X-Amz-Security-Token", valid_613158
  var valid_613159 = header.getOrDefault("X-Amz-Algorithm")
  valid_613159 = validateParameter(valid_613159, JString, required = false,
                                 default = nil)
  if valid_613159 != nil:
    section.add "X-Amz-Algorithm", valid_613159
  var valid_613160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613160 = validateParameter(valid_613160, JString, required = false,
                                 default = nil)
  if valid_613160 != nil:
    section.add "X-Amz-SignedHeaders", valid_613160
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613162: Call_UpdateWorkflow_613150; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing workflow.
  ## 
  let valid = call_613162.validator(path, query, header, formData, body)
  let scheme = call_613162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613162.url(scheme.get, call_613162.host, call_613162.base,
                         call_613162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613162, url, valid)

proc call*(call_613163: Call_UpdateWorkflow_613150; body: JsonNode): Recallable =
  ## updateWorkflow
  ## Updates an existing workflow.
  ##   body: JObject (required)
  var body_613164 = newJObject()
  if body != nil:
    body_613164 = body
  result = call_613163.call(nil, nil, nil, nil, body_613164)

var updateWorkflow* = Call_UpdateWorkflow_613150(name: "updateWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateWorkflow",
    validator: validate_UpdateWorkflow_613151, base: "/", url: url_UpdateWorkflow_613152,
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
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
