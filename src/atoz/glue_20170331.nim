
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  Call_BatchCreatePartition_612996 = ref object of OpenApiRestCall_612658
proc url_BatchCreatePartition_612998(protocol: Scheme; host: string; base: string;
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

proc validate_BatchCreatePartition_612997(path: JsonNode; query: JsonNode;
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
  var valid_613123 = header.getOrDefault("X-Amz-Target")
  valid_613123 = validateParameter(valid_613123, JString, required = true, default = newJString(
      "AWSGlue.BatchCreatePartition"))
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

proc call*(call_613154: Call_BatchCreatePartition_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates one or more partitions in a batch operation.
  ## 
  let valid = call_613154.validator(path, query, header, formData, body)
  let scheme = call_613154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613154.url(scheme.get, call_613154.host, call_613154.base,
                         call_613154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613154, url, valid)

proc call*(call_613225: Call_BatchCreatePartition_612996; body: JsonNode): Recallable =
  ## batchCreatePartition
  ## Creates one or more partitions in a batch operation.
  ##   body: JObject (required)
  var body_613226 = newJObject()
  if body != nil:
    body_613226 = body
  result = call_613225.call(nil, nil, nil, nil, body_613226)

var batchCreatePartition* = Call_BatchCreatePartition_612996(
    name: "batchCreatePartition", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchCreatePartition",
    validator: validate_BatchCreatePartition_612997, base: "/",
    url: url_BatchCreatePartition_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteConnection_613265 = ref object of OpenApiRestCall_612658
proc url_BatchDeleteConnection_613267(protocol: Scheme; host: string; base: string;
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

proc validate_BatchDeleteConnection_613266(path: JsonNode; query: JsonNode;
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
  var valid_613268 = header.getOrDefault("X-Amz-Target")
  valid_613268 = validateParameter(valid_613268, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteConnection"))
  if valid_613268 != nil:
    section.add "X-Amz-Target", valid_613268
  var valid_613269 = header.getOrDefault("X-Amz-Signature")
  valid_613269 = validateParameter(valid_613269, JString, required = false,
                                 default = nil)
  if valid_613269 != nil:
    section.add "X-Amz-Signature", valid_613269
  var valid_613270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Content-Sha256", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Date")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Date", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Credential")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Credential", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Security-Token")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Security-Token", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Algorithm")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Algorithm", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-SignedHeaders", valid_613275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613277: Call_BatchDeleteConnection_613265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a list of connection definitions from the Data Catalog.
  ## 
  let valid = call_613277.validator(path, query, header, formData, body)
  let scheme = call_613277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613277.url(scheme.get, call_613277.host, call_613277.base,
                         call_613277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613277, url, valid)

proc call*(call_613278: Call_BatchDeleteConnection_613265; body: JsonNode): Recallable =
  ## batchDeleteConnection
  ## Deletes a list of connection definitions from the Data Catalog.
  ##   body: JObject (required)
  var body_613279 = newJObject()
  if body != nil:
    body_613279 = body
  result = call_613278.call(nil, nil, nil, nil, body_613279)

var batchDeleteConnection* = Call_BatchDeleteConnection_613265(
    name: "batchDeleteConnection", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteConnection",
    validator: validate_BatchDeleteConnection_613266, base: "/",
    url: url_BatchDeleteConnection_613267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeletePartition_613280 = ref object of OpenApiRestCall_612658
proc url_BatchDeletePartition_613282(protocol: Scheme; host: string; base: string;
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

proc validate_BatchDeletePartition_613281(path: JsonNode; query: JsonNode;
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
  var valid_613283 = header.getOrDefault("X-Amz-Target")
  valid_613283 = validateParameter(valid_613283, JString, required = true, default = newJString(
      "AWSGlue.BatchDeletePartition"))
  if valid_613283 != nil:
    section.add "X-Amz-Target", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-Signature")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-Signature", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Content-Sha256", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Date")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Date", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Credential")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Credential", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Security-Token")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Security-Token", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Algorithm")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Algorithm", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-SignedHeaders", valid_613290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613292: Call_BatchDeletePartition_613280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes one or more partitions in a batch operation.
  ## 
  let valid = call_613292.validator(path, query, header, formData, body)
  let scheme = call_613292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613292.url(scheme.get, call_613292.host, call_613292.base,
                         call_613292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613292, url, valid)

proc call*(call_613293: Call_BatchDeletePartition_613280; body: JsonNode): Recallable =
  ## batchDeletePartition
  ## Deletes one or more partitions in a batch operation.
  ##   body: JObject (required)
  var body_613294 = newJObject()
  if body != nil:
    body_613294 = body
  result = call_613293.call(nil, nil, nil, nil, body_613294)

var batchDeletePartition* = Call_BatchDeletePartition_613280(
    name: "batchDeletePartition", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeletePartition",
    validator: validate_BatchDeletePartition_613281, base: "/",
    url: url_BatchDeletePartition_613282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteTable_613295 = ref object of OpenApiRestCall_612658
proc url_BatchDeleteTable_613297(protocol: Scheme; host: string; base: string;
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

proc validate_BatchDeleteTable_613296(path: JsonNode; query: JsonNode;
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
  var valid_613298 = header.getOrDefault("X-Amz-Target")
  valid_613298 = validateParameter(valid_613298, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteTable"))
  if valid_613298 != nil:
    section.add "X-Amz-Target", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Signature")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Signature", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Content-Sha256", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Date")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Date", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Credential")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Credential", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Security-Token")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Security-Token", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Algorithm")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Algorithm", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-SignedHeaders", valid_613305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613307: Call_BatchDeleteTable_613295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ## 
  let valid = call_613307.validator(path, query, header, formData, body)
  let scheme = call_613307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613307.url(scheme.get, call_613307.host, call_613307.base,
                         call_613307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613307, url, valid)

proc call*(call_613308: Call_BatchDeleteTable_613295; body: JsonNode): Recallable =
  ## batchDeleteTable
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ##   body: JObject (required)
  var body_613309 = newJObject()
  if body != nil:
    body_613309 = body
  result = call_613308.call(nil, nil, nil, nil, body_613309)

var batchDeleteTable* = Call_BatchDeleteTable_613295(name: "batchDeleteTable",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteTable",
    validator: validate_BatchDeleteTable_613296, base: "/",
    url: url_BatchDeleteTable_613297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteTableVersion_613310 = ref object of OpenApiRestCall_612658
proc url_BatchDeleteTableVersion_613312(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDeleteTableVersion_613311(path: JsonNode; query: JsonNode;
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
  var valid_613313 = header.getOrDefault("X-Amz-Target")
  valid_613313 = validateParameter(valid_613313, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteTableVersion"))
  if valid_613313 != nil:
    section.add "X-Amz-Target", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Signature")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Signature", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Content-Sha256", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Date")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Date", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Credential")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Credential", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Security-Token")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Security-Token", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Algorithm")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Algorithm", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-SignedHeaders", valid_613320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613322: Call_BatchDeleteTableVersion_613310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified batch of versions of a table.
  ## 
  let valid = call_613322.validator(path, query, header, formData, body)
  let scheme = call_613322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613322.url(scheme.get, call_613322.host, call_613322.base,
                         call_613322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613322, url, valid)

proc call*(call_613323: Call_BatchDeleteTableVersion_613310; body: JsonNode): Recallable =
  ## batchDeleteTableVersion
  ## Deletes a specified batch of versions of a table.
  ##   body: JObject (required)
  var body_613324 = newJObject()
  if body != nil:
    body_613324 = body
  result = call_613323.call(nil, nil, nil, nil, body_613324)

var batchDeleteTableVersion* = Call_BatchDeleteTableVersion_613310(
    name: "batchDeleteTableVersion", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteTableVersion",
    validator: validate_BatchDeleteTableVersion_613311, base: "/",
    url: url_BatchDeleteTableVersion_613312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetCrawlers_613325 = ref object of OpenApiRestCall_612658
proc url_BatchGetCrawlers_613327(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetCrawlers_613326(path: JsonNode; query: JsonNode;
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
  var valid_613328 = header.getOrDefault("X-Amz-Target")
  valid_613328 = validateParameter(valid_613328, JString, required = true, default = newJString(
      "AWSGlue.BatchGetCrawlers"))
  if valid_613328 != nil:
    section.add "X-Amz-Target", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Signature")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Signature", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Content-Sha256", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Date")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Date", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Credential")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Credential", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Security-Token")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Security-Token", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Algorithm")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Algorithm", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-SignedHeaders", valid_613335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613337: Call_BatchGetCrawlers_613325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_613337.validator(path, query, header, formData, body)
  let scheme = call_613337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613337.url(scheme.get, call_613337.host, call_613337.base,
                         call_613337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613337, url, valid)

proc call*(call_613338: Call_BatchGetCrawlers_613325; body: JsonNode): Recallable =
  ## batchGetCrawlers
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_613339 = newJObject()
  if body != nil:
    body_613339 = body
  result = call_613338.call(nil, nil, nil, nil, body_613339)

var batchGetCrawlers* = Call_BatchGetCrawlers_613325(name: "batchGetCrawlers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetCrawlers",
    validator: validate_BatchGetCrawlers_613326, base: "/",
    url: url_BatchGetCrawlers_613327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDevEndpoints_613340 = ref object of OpenApiRestCall_612658
proc url_BatchGetDevEndpoints_613342(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetDevEndpoints_613341(path: JsonNode; query: JsonNode;
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
  var valid_613343 = header.getOrDefault("X-Amz-Target")
  valid_613343 = validateParameter(valid_613343, JString, required = true, default = newJString(
      "AWSGlue.BatchGetDevEndpoints"))
  if valid_613343 != nil:
    section.add "X-Amz-Target", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Signature")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Signature", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Content-Sha256", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Date")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Date", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Credential")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Credential", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Security-Token")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Security-Token", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Algorithm")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Algorithm", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-SignedHeaders", valid_613350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613352: Call_BatchGetDevEndpoints_613340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_613352.validator(path, query, header, formData, body)
  let scheme = call_613352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613352.url(scheme.get, call_613352.host, call_613352.base,
                         call_613352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613352, url, valid)

proc call*(call_613353: Call_BatchGetDevEndpoints_613340; body: JsonNode): Recallable =
  ## batchGetDevEndpoints
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_613354 = newJObject()
  if body != nil:
    body_613354 = body
  result = call_613353.call(nil, nil, nil, nil, body_613354)

var batchGetDevEndpoints* = Call_BatchGetDevEndpoints_613340(
    name: "batchGetDevEndpoints", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetDevEndpoints",
    validator: validate_BatchGetDevEndpoints_613341, base: "/",
    url: url_BatchGetDevEndpoints_613342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetJobs_613355 = ref object of OpenApiRestCall_612658
proc url_BatchGetJobs_613357(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetJobs_613356(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613358 = header.getOrDefault("X-Amz-Target")
  valid_613358 = validateParameter(valid_613358, JString, required = true,
                                 default = newJString("AWSGlue.BatchGetJobs"))
  if valid_613358 != nil:
    section.add "X-Amz-Target", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Signature")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Signature", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Content-Sha256", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Date")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Date", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Credential")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Credential", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Security-Token")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Security-Token", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Algorithm")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Algorithm", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-SignedHeaders", valid_613365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613367: Call_BatchGetJobs_613355; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
  ## 
  let valid = call_613367.validator(path, query, header, formData, body)
  let scheme = call_613367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613367.url(scheme.get, call_613367.host, call_613367.base,
                         call_613367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613367, url, valid)

proc call*(call_613368: Call_BatchGetJobs_613355; body: JsonNode): Recallable =
  ## batchGetJobs
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
  ##   body: JObject (required)
  var body_613369 = newJObject()
  if body != nil:
    body_613369 = body
  result = call_613368.call(nil, nil, nil, nil, body_613369)

var batchGetJobs* = Call_BatchGetJobs_613355(name: "batchGetJobs",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetJobs",
    validator: validate_BatchGetJobs_613356, base: "/", url: url_BatchGetJobs_613357,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetPartition_613370 = ref object of OpenApiRestCall_612658
proc url_BatchGetPartition_613372(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetPartition_613371(path: JsonNode; query: JsonNode;
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
  var valid_613373 = header.getOrDefault("X-Amz-Target")
  valid_613373 = validateParameter(valid_613373, JString, required = true, default = newJString(
      "AWSGlue.BatchGetPartition"))
  if valid_613373 != nil:
    section.add "X-Amz-Target", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Signature")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Signature", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Content-Sha256", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Date")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Date", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Credential")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Credential", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Security-Token")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Security-Token", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Algorithm")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Algorithm", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-SignedHeaders", valid_613380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613382: Call_BatchGetPartition_613370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves partitions in a batch request.
  ## 
  let valid = call_613382.validator(path, query, header, formData, body)
  let scheme = call_613382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613382.url(scheme.get, call_613382.host, call_613382.base,
                         call_613382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613382, url, valid)

proc call*(call_613383: Call_BatchGetPartition_613370; body: JsonNode): Recallable =
  ## batchGetPartition
  ## Retrieves partitions in a batch request.
  ##   body: JObject (required)
  var body_613384 = newJObject()
  if body != nil:
    body_613384 = body
  result = call_613383.call(nil, nil, nil, nil, body_613384)

var batchGetPartition* = Call_BatchGetPartition_613370(name: "batchGetPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetPartition",
    validator: validate_BatchGetPartition_613371, base: "/",
    url: url_BatchGetPartition_613372, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetTriggers_613385 = ref object of OpenApiRestCall_612658
proc url_BatchGetTriggers_613387(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetTriggers_613386(path: JsonNode; query: JsonNode;
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
  var valid_613388 = header.getOrDefault("X-Amz-Target")
  valid_613388 = validateParameter(valid_613388, JString, required = true, default = newJString(
      "AWSGlue.BatchGetTriggers"))
  if valid_613388 != nil:
    section.add "X-Amz-Target", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Signature")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Signature", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Content-Sha256", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Date")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Date", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Credential")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Credential", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Security-Token")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Security-Token", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Algorithm")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Algorithm", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-SignedHeaders", valid_613395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613397: Call_BatchGetTriggers_613385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_613397.validator(path, query, header, formData, body)
  let scheme = call_613397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613397.url(scheme.get, call_613397.host, call_613397.base,
                         call_613397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613397, url, valid)

proc call*(call_613398: Call_BatchGetTriggers_613385; body: JsonNode): Recallable =
  ## batchGetTriggers
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_613399 = newJObject()
  if body != nil:
    body_613399 = body
  result = call_613398.call(nil, nil, nil, nil, body_613399)

var batchGetTriggers* = Call_BatchGetTriggers_613385(name: "batchGetTriggers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetTriggers",
    validator: validate_BatchGetTriggers_613386, base: "/",
    url: url_BatchGetTriggers_613387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetWorkflows_613400 = ref object of OpenApiRestCall_612658
proc url_BatchGetWorkflows_613402(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetWorkflows_613401(path: JsonNode; query: JsonNode;
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
  var valid_613403 = header.getOrDefault("X-Amz-Target")
  valid_613403 = validateParameter(valid_613403, JString, required = true, default = newJString(
      "AWSGlue.BatchGetWorkflows"))
  if valid_613403 != nil:
    section.add "X-Amz-Target", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Signature")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Signature", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Content-Sha256", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Date")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Date", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Credential")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Credential", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Security-Token")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Security-Token", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Algorithm")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Algorithm", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-SignedHeaders", valid_613410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613412: Call_BatchGetWorkflows_613400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_613412.validator(path, query, header, formData, body)
  let scheme = call_613412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613412.url(scheme.get, call_613412.host, call_613412.base,
                         call_613412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613412, url, valid)

proc call*(call_613413: Call_BatchGetWorkflows_613400; body: JsonNode): Recallable =
  ## batchGetWorkflows
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_613414 = newJObject()
  if body != nil:
    body_613414 = body
  result = call_613413.call(nil, nil, nil, nil, body_613414)

var batchGetWorkflows* = Call_BatchGetWorkflows_613400(name: "batchGetWorkflows",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetWorkflows",
    validator: validate_BatchGetWorkflows_613401, base: "/",
    url: url_BatchGetWorkflows_613402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchStopJobRun_613415 = ref object of OpenApiRestCall_612658
proc url_BatchStopJobRun_613417(protocol: Scheme; host: string; base: string;
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

proc validate_BatchStopJobRun_613416(path: JsonNode; query: JsonNode;
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
  var valid_613418 = header.getOrDefault("X-Amz-Target")
  valid_613418 = validateParameter(valid_613418, JString, required = true, default = newJString(
      "AWSGlue.BatchStopJobRun"))
  if valid_613418 != nil:
    section.add "X-Amz-Target", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Signature")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Signature", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Content-Sha256", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-Date")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Date", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Credential")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Credential", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Security-Token")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Security-Token", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-Algorithm")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Algorithm", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-SignedHeaders", valid_613425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613427: Call_BatchStopJobRun_613415; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops one or more job runs for a specified job definition.
  ## 
  let valid = call_613427.validator(path, query, header, formData, body)
  let scheme = call_613427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613427.url(scheme.get, call_613427.host, call_613427.base,
                         call_613427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613427, url, valid)

proc call*(call_613428: Call_BatchStopJobRun_613415; body: JsonNode): Recallable =
  ## batchStopJobRun
  ## Stops one or more job runs for a specified job definition.
  ##   body: JObject (required)
  var body_613429 = newJObject()
  if body != nil:
    body_613429 = body
  result = call_613428.call(nil, nil, nil, nil, body_613429)

var batchStopJobRun* = Call_BatchStopJobRun_613415(name: "batchStopJobRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchStopJobRun",
    validator: validate_BatchStopJobRun_613416, base: "/", url: url_BatchStopJobRun_613417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelMLTaskRun_613430 = ref object of OpenApiRestCall_612658
proc url_CancelMLTaskRun_613432(protocol: Scheme; host: string; base: string;
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

proc validate_CancelMLTaskRun_613431(path: JsonNode; query: JsonNode;
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
  var valid_613433 = header.getOrDefault("X-Amz-Target")
  valid_613433 = validateParameter(valid_613433, JString, required = true, default = newJString(
      "AWSGlue.CancelMLTaskRun"))
  if valid_613433 != nil:
    section.add "X-Amz-Target", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Signature")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Signature", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Content-Sha256", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Date")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Date", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Credential")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Credential", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-Security-Token")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-Security-Token", valid_613438
  var valid_613439 = header.getOrDefault("X-Amz-Algorithm")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-Algorithm", valid_613439
  var valid_613440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "X-Amz-SignedHeaders", valid_613440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613442: Call_CancelMLTaskRun_613430; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
  ## 
  let valid = call_613442.validator(path, query, header, formData, body)
  let scheme = call_613442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613442.url(scheme.get, call_613442.host, call_613442.base,
                         call_613442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613442, url, valid)

proc call*(call_613443: Call_CancelMLTaskRun_613430; body: JsonNode): Recallable =
  ## cancelMLTaskRun
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
  ##   body: JObject (required)
  var body_613444 = newJObject()
  if body != nil:
    body_613444 = body
  result = call_613443.call(nil, nil, nil, nil, body_613444)

var cancelMLTaskRun* = Call_CancelMLTaskRun_613430(name: "cancelMLTaskRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CancelMLTaskRun",
    validator: validate_CancelMLTaskRun_613431, base: "/", url: url_CancelMLTaskRun_613432,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateClassifier_613445 = ref object of OpenApiRestCall_612658
proc url_CreateClassifier_613447(protocol: Scheme; host: string; base: string;
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

proc validate_CreateClassifier_613446(path: JsonNode; query: JsonNode;
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
  var valid_613448 = header.getOrDefault("X-Amz-Target")
  valid_613448 = validateParameter(valid_613448, JString, required = true, default = newJString(
      "AWSGlue.CreateClassifier"))
  if valid_613448 != nil:
    section.add "X-Amz-Target", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Signature")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Signature", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Content-Sha256", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Date")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Date", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Credential")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Credential", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-Security-Token")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-Security-Token", valid_613453
  var valid_613454 = header.getOrDefault("X-Amz-Algorithm")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "X-Amz-Algorithm", valid_613454
  var valid_613455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613455 = validateParameter(valid_613455, JString, required = false,
                                 default = nil)
  if valid_613455 != nil:
    section.add "X-Amz-SignedHeaders", valid_613455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613457: Call_CreateClassifier_613445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
  ## 
  let valid = call_613457.validator(path, query, header, formData, body)
  let scheme = call_613457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613457.url(scheme.get, call_613457.host, call_613457.base,
                         call_613457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613457, url, valid)

proc call*(call_613458: Call_CreateClassifier_613445; body: JsonNode): Recallable =
  ## createClassifier
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
  ##   body: JObject (required)
  var body_613459 = newJObject()
  if body != nil:
    body_613459 = body
  result = call_613458.call(nil, nil, nil, nil, body_613459)

var createClassifier* = Call_CreateClassifier_613445(name: "createClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateClassifier",
    validator: validate_CreateClassifier_613446, base: "/",
    url: url_CreateClassifier_613447, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnection_613460 = ref object of OpenApiRestCall_612658
proc url_CreateConnection_613462(protocol: Scheme; host: string; base: string;
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

proc validate_CreateConnection_613461(path: JsonNode; query: JsonNode;
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
  var valid_613463 = header.getOrDefault("X-Amz-Target")
  valid_613463 = validateParameter(valid_613463, JString, required = true, default = newJString(
      "AWSGlue.CreateConnection"))
  if valid_613463 != nil:
    section.add "X-Amz-Target", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Signature")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Signature", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Content-Sha256", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Date")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Date", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Credential")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Credential", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Security-Token")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Security-Token", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-Algorithm")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Algorithm", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-SignedHeaders", valid_613470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613472: Call_CreateConnection_613460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a connection definition in the Data Catalog.
  ## 
  let valid = call_613472.validator(path, query, header, formData, body)
  let scheme = call_613472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613472.url(scheme.get, call_613472.host, call_613472.base,
                         call_613472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613472, url, valid)

proc call*(call_613473: Call_CreateConnection_613460; body: JsonNode): Recallable =
  ## createConnection
  ## Creates a connection definition in the Data Catalog.
  ##   body: JObject (required)
  var body_613474 = newJObject()
  if body != nil:
    body_613474 = body
  result = call_613473.call(nil, nil, nil, nil, body_613474)

var createConnection* = Call_CreateConnection_613460(name: "createConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateConnection",
    validator: validate_CreateConnection_613461, base: "/",
    url: url_CreateConnection_613462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCrawler_613475 = ref object of OpenApiRestCall_612658
proc url_CreateCrawler_613477(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCrawler_613476(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613478 = header.getOrDefault("X-Amz-Target")
  valid_613478 = validateParameter(valid_613478, JString, required = true,
                                 default = newJString("AWSGlue.CreateCrawler"))
  if valid_613478 != nil:
    section.add "X-Amz-Target", valid_613478
  var valid_613479 = header.getOrDefault("X-Amz-Signature")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Signature", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Content-Sha256", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Date")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Date", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Credential")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Credential", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Security-Token")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Security-Token", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Algorithm")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Algorithm", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-SignedHeaders", valid_613485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613487: Call_CreateCrawler_613475; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
  ## 
  let valid = call_613487.validator(path, query, header, formData, body)
  let scheme = call_613487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613487.url(scheme.get, call_613487.host, call_613487.base,
                         call_613487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613487, url, valid)

proc call*(call_613488: Call_CreateCrawler_613475; body: JsonNode): Recallable =
  ## createCrawler
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
  ##   body: JObject (required)
  var body_613489 = newJObject()
  if body != nil:
    body_613489 = body
  result = call_613488.call(nil, nil, nil, nil, body_613489)

var createCrawler* = Call_CreateCrawler_613475(name: "createCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateCrawler",
    validator: validate_CreateCrawler_613476, base: "/", url: url_CreateCrawler_613477,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatabase_613490 = ref object of OpenApiRestCall_612658
proc url_CreateDatabase_613492(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDatabase_613491(path: JsonNode; query: JsonNode;
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
  var valid_613493 = header.getOrDefault("X-Amz-Target")
  valid_613493 = validateParameter(valid_613493, JString, required = true,
                                 default = newJString("AWSGlue.CreateDatabase"))
  if valid_613493 != nil:
    section.add "X-Amz-Target", valid_613493
  var valid_613494 = header.getOrDefault("X-Amz-Signature")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "X-Amz-Signature", valid_613494
  var valid_613495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-Content-Sha256", valid_613495
  var valid_613496 = header.getOrDefault("X-Amz-Date")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-Date", valid_613496
  var valid_613497 = header.getOrDefault("X-Amz-Credential")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-Credential", valid_613497
  var valid_613498 = header.getOrDefault("X-Amz-Security-Token")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Security-Token", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-Algorithm")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-Algorithm", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-SignedHeaders", valid_613500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613502: Call_CreateDatabase_613490; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new database in a Data Catalog.
  ## 
  let valid = call_613502.validator(path, query, header, formData, body)
  let scheme = call_613502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613502.url(scheme.get, call_613502.host, call_613502.base,
                         call_613502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613502, url, valid)

proc call*(call_613503: Call_CreateDatabase_613490; body: JsonNode): Recallable =
  ## createDatabase
  ## Creates a new database in a Data Catalog.
  ##   body: JObject (required)
  var body_613504 = newJObject()
  if body != nil:
    body_613504 = body
  result = call_613503.call(nil, nil, nil, nil, body_613504)

var createDatabase* = Call_CreateDatabase_613490(name: "createDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateDatabase",
    validator: validate_CreateDatabase_613491, base: "/", url: url_CreateDatabase_613492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDevEndpoint_613505 = ref object of OpenApiRestCall_612658
proc url_CreateDevEndpoint_613507(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDevEndpoint_613506(path: JsonNode; query: JsonNode;
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
  var valid_613508 = header.getOrDefault("X-Amz-Target")
  valid_613508 = validateParameter(valid_613508, JString, required = true, default = newJString(
      "AWSGlue.CreateDevEndpoint"))
  if valid_613508 != nil:
    section.add "X-Amz-Target", valid_613508
  var valid_613509 = header.getOrDefault("X-Amz-Signature")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "X-Amz-Signature", valid_613509
  var valid_613510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613510 = validateParameter(valid_613510, JString, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "X-Amz-Content-Sha256", valid_613510
  var valid_613511 = header.getOrDefault("X-Amz-Date")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-Date", valid_613511
  var valid_613512 = header.getOrDefault("X-Amz-Credential")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-Credential", valid_613512
  var valid_613513 = header.getOrDefault("X-Amz-Security-Token")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-Security-Token", valid_613513
  var valid_613514 = header.getOrDefault("X-Amz-Algorithm")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-Algorithm", valid_613514
  var valid_613515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-SignedHeaders", valid_613515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613517: Call_CreateDevEndpoint_613505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new development endpoint.
  ## 
  let valid = call_613517.validator(path, query, header, formData, body)
  let scheme = call_613517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613517.url(scheme.get, call_613517.host, call_613517.base,
                         call_613517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613517, url, valid)

proc call*(call_613518: Call_CreateDevEndpoint_613505; body: JsonNode): Recallable =
  ## createDevEndpoint
  ## Creates a new development endpoint.
  ##   body: JObject (required)
  var body_613519 = newJObject()
  if body != nil:
    body_613519 = body
  result = call_613518.call(nil, nil, nil, nil, body_613519)

var createDevEndpoint* = Call_CreateDevEndpoint_613505(name: "createDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateDevEndpoint",
    validator: validate_CreateDevEndpoint_613506, base: "/",
    url: url_CreateDevEndpoint_613507, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_613520 = ref object of OpenApiRestCall_612658
proc url_CreateJob_613522(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateJob_613521(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613523 = header.getOrDefault("X-Amz-Target")
  valid_613523 = validateParameter(valid_613523, JString, required = true,
                                 default = newJString("AWSGlue.CreateJob"))
  if valid_613523 != nil:
    section.add "X-Amz-Target", valid_613523
  var valid_613524 = header.getOrDefault("X-Amz-Signature")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "X-Amz-Signature", valid_613524
  var valid_613525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "X-Amz-Content-Sha256", valid_613525
  var valid_613526 = header.getOrDefault("X-Amz-Date")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Date", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-Credential")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Credential", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-Security-Token")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Security-Token", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Algorithm")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Algorithm", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-SignedHeaders", valid_613530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613532: Call_CreateJob_613520; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new job definition.
  ## 
  let valid = call_613532.validator(path, query, header, formData, body)
  let scheme = call_613532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613532.url(scheme.get, call_613532.host, call_613532.base,
                         call_613532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613532, url, valid)

proc call*(call_613533: Call_CreateJob_613520; body: JsonNode): Recallable =
  ## createJob
  ## Creates a new job definition.
  ##   body: JObject (required)
  var body_613534 = newJObject()
  if body != nil:
    body_613534 = body
  result = call_613533.call(nil, nil, nil, nil, body_613534)

var createJob* = Call_CreateJob_613520(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.CreateJob",
                                    validator: validate_CreateJob_613521,
                                    base: "/", url: url_CreateJob_613522,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMLTransform_613535 = ref object of OpenApiRestCall_612658
proc url_CreateMLTransform_613537(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMLTransform_613536(path: JsonNode; query: JsonNode;
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
  var valid_613538 = header.getOrDefault("X-Amz-Target")
  valid_613538 = validateParameter(valid_613538, JString, required = true, default = newJString(
      "AWSGlue.CreateMLTransform"))
  if valid_613538 != nil:
    section.add "X-Amz-Target", valid_613538
  var valid_613539 = header.getOrDefault("X-Amz-Signature")
  valid_613539 = validateParameter(valid_613539, JString, required = false,
                                 default = nil)
  if valid_613539 != nil:
    section.add "X-Amz-Signature", valid_613539
  var valid_613540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "X-Amz-Content-Sha256", valid_613540
  var valid_613541 = header.getOrDefault("X-Amz-Date")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Date", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-Credential")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Credential", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-Security-Token")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-Security-Token", valid_613543
  var valid_613544 = header.getOrDefault("X-Amz-Algorithm")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-Algorithm", valid_613544
  var valid_613545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-SignedHeaders", valid_613545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613547: Call_CreateMLTransform_613535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
  ## 
  let valid = call_613547.validator(path, query, header, formData, body)
  let scheme = call_613547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613547.url(scheme.get, call_613547.host, call_613547.base,
                         call_613547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613547, url, valid)

proc call*(call_613548: Call_CreateMLTransform_613535; body: JsonNode): Recallable =
  ## createMLTransform
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
  ##   body: JObject (required)
  var body_613549 = newJObject()
  if body != nil:
    body_613549 = body
  result = call_613548.call(nil, nil, nil, nil, body_613549)

var createMLTransform* = Call_CreateMLTransform_613535(name: "createMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateMLTransform",
    validator: validate_CreateMLTransform_613536, base: "/",
    url: url_CreateMLTransform_613537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePartition_613550 = ref object of OpenApiRestCall_612658
proc url_CreatePartition_613552(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePartition_613551(path: JsonNode; query: JsonNode;
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
  var valid_613553 = header.getOrDefault("X-Amz-Target")
  valid_613553 = validateParameter(valid_613553, JString, required = true, default = newJString(
      "AWSGlue.CreatePartition"))
  if valid_613553 != nil:
    section.add "X-Amz-Target", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-Signature")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-Signature", valid_613554
  var valid_613555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "X-Amz-Content-Sha256", valid_613555
  var valid_613556 = header.getOrDefault("X-Amz-Date")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-Date", valid_613556
  var valid_613557 = header.getOrDefault("X-Amz-Credential")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-Credential", valid_613557
  var valid_613558 = header.getOrDefault("X-Amz-Security-Token")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-Security-Token", valid_613558
  var valid_613559 = header.getOrDefault("X-Amz-Algorithm")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "X-Amz-Algorithm", valid_613559
  var valid_613560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613560 = validateParameter(valid_613560, JString, required = false,
                                 default = nil)
  if valid_613560 != nil:
    section.add "X-Amz-SignedHeaders", valid_613560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613562: Call_CreatePartition_613550; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new partition.
  ## 
  let valid = call_613562.validator(path, query, header, formData, body)
  let scheme = call_613562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613562.url(scheme.get, call_613562.host, call_613562.base,
                         call_613562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613562, url, valid)

proc call*(call_613563: Call_CreatePartition_613550; body: JsonNode): Recallable =
  ## createPartition
  ## Creates a new partition.
  ##   body: JObject (required)
  var body_613564 = newJObject()
  if body != nil:
    body_613564 = body
  result = call_613563.call(nil, nil, nil, nil, body_613564)

var createPartition* = Call_CreatePartition_613550(name: "createPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreatePartition",
    validator: validate_CreatePartition_613551, base: "/", url: url_CreatePartition_613552,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateScript_613565 = ref object of OpenApiRestCall_612658
proc url_CreateScript_613567(protocol: Scheme; host: string; base: string;
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

proc validate_CreateScript_613566(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613568 = header.getOrDefault("X-Amz-Target")
  valid_613568 = validateParameter(valid_613568, JString, required = true,
                                 default = newJString("AWSGlue.CreateScript"))
  if valid_613568 != nil:
    section.add "X-Amz-Target", valid_613568
  var valid_613569 = header.getOrDefault("X-Amz-Signature")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Signature", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Content-Sha256", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-Date")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Date", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-Credential")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Credential", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-Security-Token")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Security-Token", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-Algorithm")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-Algorithm", valid_613574
  var valid_613575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-SignedHeaders", valid_613575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613577: Call_CreateScript_613565; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Transforms a directed acyclic graph (DAG) into code.
  ## 
  let valid = call_613577.validator(path, query, header, formData, body)
  let scheme = call_613577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613577.url(scheme.get, call_613577.host, call_613577.base,
                         call_613577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613577, url, valid)

proc call*(call_613578: Call_CreateScript_613565; body: JsonNode): Recallable =
  ## createScript
  ## Transforms a directed acyclic graph (DAG) into code.
  ##   body: JObject (required)
  var body_613579 = newJObject()
  if body != nil:
    body_613579 = body
  result = call_613578.call(nil, nil, nil, nil, body_613579)

var createScript* = Call_CreateScript_613565(name: "createScript",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateScript",
    validator: validate_CreateScript_613566, base: "/", url: url_CreateScript_613567,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSecurityConfiguration_613580 = ref object of OpenApiRestCall_612658
proc url_CreateSecurityConfiguration_613582(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSecurityConfiguration_613581(path: JsonNode; query: JsonNode;
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
  var valid_613583 = header.getOrDefault("X-Amz-Target")
  valid_613583 = validateParameter(valid_613583, JString, required = true, default = newJString(
      "AWSGlue.CreateSecurityConfiguration"))
  if valid_613583 != nil:
    section.add "X-Amz-Target", valid_613583
  var valid_613584 = header.getOrDefault("X-Amz-Signature")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "X-Amz-Signature", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-Content-Sha256", valid_613585
  var valid_613586 = header.getOrDefault("X-Amz-Date")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Date", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Credential")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Credential", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-Security-Token")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-Security-Token", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-Algorithm")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-Algorithm", valid_613589
  var valid_613590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-SignedHeaders", valid_613590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613592: Call_CreateSecurityConfiguration_613580; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
  ## 
  let valid = call_613592.validator(path, query, header, formData, body)
  let scheme = call_613592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613592.url(scheme.get, call_613592.host, call_613592.base,
                         call_613592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613592, url, valid)

proc call*(call_613593: Call_CreateSecurityConfiguration_613580; body: JsonNode): Recallable =
  ## createSecurityConfiguration
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
  ##   body: JObject (required)
  var body_613594 = newJObject()
  if body != nil:
    body_613594 = body
  result = call_613593.call(nil, nil, nil, nil, body_613594)

var createSecurityConfiguration* = Call_CreateSecurityConfiguration_613580(
    name: "createSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateSecurityConfiguration",
    validator: validate_CreateSecurityConfiguration_613581, base: "/",
    url: url_CreateSecurityConfiguration_613582,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTable_613595 = ref object of OpenApiRestCall_612658
proc url_CreateTable_613597(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTable_613596(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613598 = header.getOrDefault("X-Amz-Target")
  valid_613598 = validateParameter(valid_613598, JString, required = true,
                                 default = newJString("AWSGlue.CreateTable"))
  if valid_613598 != nil:
    section.add "X-Amz-Target", valid_613598
  var valid_613599 = header.getOrDefault("X-Amz-Signature")
  valid_613599 = validateParameter(valid_613599, JString, required = false,
                                 default = nil)
  if valid_613599 != nil:
    section.add "X-Amz-Signature", valid_613599
  var valid_613600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613600 = validateParameter(valid_613600, JString, required = false,
                                 default = nil)
  if valid_613600 != nil:
    section.add "X-Amz-Content-Sha256", valid_613600
  var valid_613601 = header.getOrDefault("X-Amz-Date")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "X-Amz-Date", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-Credential")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-Credential", valid_613602
  var valid_613603 = header.getOrDefault("X-Amz-Security-Token")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-Security-Token", valid_613603
  var valid_613604 = header.getOrDefault("X-Amz-Algorithm")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "X-Amz-Algorithm", valid_613604
  var valid_613605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-SignedHeaders", valid_613605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613607: Call_CreateTable_613595; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new table definition in the Data Catalog.
  ## 
  let valid = call_613607.validator(path, query, header, formData, body)
  let scheme = call_613607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613607.url(scheme.get, call_613607.host, call_613607.base,
                         call_613607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613607, url, valid)

proc call*(call_613608: Call_CreateTable_613595; body: JsonNode): Recallable =
  ## createTable
  ## Creates a new table definition in the Data Catalog.
  ##   body: JObject (required)
  var body_613609 = newJObject()
  if body != nil:
    body_613609 = body
  result = call_613608.call(nil, nil, nil, nil, body_613609)

var createTable* = Call_CreateTable_613595(name: "createTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.CreateTable",
                                        validator: validate_CreateTable_613596,
                                        base: "/", url: url_CreateTable_613597,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrigger_613610 = ref object of OpenApiRestCall_612658
proc url_CreateTrigger_613612(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTrigger_613611(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613613 = header.getOrDefault("X-Amz-Target")
  valid_613613 = validateParameter(valid_613613, JString, required = true,
                                 default = newJString("AWSGlue.CreateTrigger"))
  if valid_613613 != nil:
    section.add "X-Amz-Target", valid_613613
  var valid_613614 = header.getOrDefault("X-Amz-Signature")
  valid_613614 = validateParameter(valid_613614, JString, required = false,
                                 default = nil)
  if valid_613614 != nil:
    section.add "X-Amz-Signature", valid_613614
  var valid_613615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613615 = validateParameter(valid_613615, JString, required = false,
                                 default = nil)
  if valid_613615 != nil:
    section.add "X-Amz-Content-Sha256", valid_613615
  var valid_613616 = header.getOrDefault("X-Amz-Date")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Date", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-Credential")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-Credential", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-Security-Token")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-Security-Token", valid_613618
  var valid_613619 = header.getOrDefault("X-Amz-Algorithm")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-Algorithm", valid_613619
  var valid_613620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "X-Amz-SignedHeaders", valid_613620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613622: Call_CreateTrigger_613610; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new trigger.
  ## 
  let valid = call_613622.validator(path, query, header, formData, body)
  let scheme = call_613622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613622.url(scheme.get, call_613622.host, call_613622.base,
                         call_613622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613622, url, valid)

proc call*(call_613623: Call_CreateTrigger_613610; body: JsonNode): Recallable =
  ## createTrigger
  ## Creates a new trigger.
  ##   body: JObject (required)
  var body_613624 = newJObject()
  if body != nil:
    body_613624 = body
  result = call_613623.call(nil, nil, nil, nil, body_613624)

var createTrigger* = Call_CreateTrigger_613610(name: "createTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateTrigger",
    validator: validate_CreateTrigger_613611, base: "/", url: url_CreateTrigger_613612,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserDefinedFunction_613625 = ref object of OpenApiRestCall_612658
proc url_CreateUserDefinedFunction_613627(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUserDefinedFunction_613626(path: JsonNode; query: JsonNode;
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
  var valid_613628 = header.getOrDefault("X-Amz-Target")
  valid_613628 = validateParameter(valid_613628, JString, required = true, default = newJString(
      "AWSGlue.CreateUserDefinedFunction"))
  if valid_613628 != nil:
    section.add "X-Amz-Target", valid_613628
  var valid_613629 = header.getOrDefault("X-Amz-Signature")
  valid_613629 = validateParameter(valid_613629, JString, required = false,
                                 default = nil)
  if valid_613629 != nil:
    section.add "X-Amz-Signature", valid_613629
  var valid_613630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613630 = validateParameter(valid_613630, JString, required = false,
                                 default = nil)
  if valid_613630 != nil:
    section.add "X-Amz-Content-Sha256", valid_613630
  var valid_613631 = header.getOrDefault("X-Amz-Date")
  valid_613631 = validateParameter(valid_613631, JString, required = false,
                                 default = nil)
  if valid_613631 != nil:
    section.add "X-Amz-Date", valid_613631
  var valid_613632 = header.getOrDefault("X-Amz-Credential")
  valid_613632 = validateParameter(valid_613632, JString, required = false,
                                 default = nil)
  if valid_613632 != nil:
    section.add "X-Amz-Credential", valid_613632
  var valid_613633 = header.getOrDefault("X-Amz-Security-Token")
  valid_613633 = validateParameter(valid_613633, JString, required = false,
                                 default = nil)
  if valid_613633 != nil:
    section.add "X-Amz-Security-Token", valid_613633
  var valid_613634 = header.getOrDefault("X-Amz-Algorithm")
  valid_613634 = validateParameter(valid_613634, JString, required = false,
                                 default = nil)
  if valid_613634 != nil:
    section.add "X-Amz-Algorithm", valid_613634
  var valid_613635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "X-Amz-SignedHeaders", valid_613635
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613637: Call_CreateUserDefinedFunction_613625; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new function definition in the Data Catalog.
  ## 
  let valid = call_613637.validator(path, query, header, formData, body)
  let scheme = call_613637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613637.url(scheme.get, call_613637.host, call_613637.base,
                         call_613637.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613637, url, valid)

proc call*(call_613638: Call_CreateUserDefinedFunction_613625; body: JsonNode): Recallable =
  ## createUserDefinedFunction
  ## Creates a new function definition in the Data Catalog.
  ##   body: JObject (required)
  var body_613639 = newJObject()
  if body != nil:
    body_613639 = body
  result = call_613638.call(nil, nil, nil, nil, body_613639)

var createUserDefinedFunction* = Call_CreateUserDefinedFunction_613625(
    name: "createUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateUserDefinedFunction",
    validator: validate_CreateUserDefinedFunction_613626, base: "/",
    url: url_CreateUserDefinedFunction_613627,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkflow_613640 = ref object of OpenApiRestCall_612658
proc url_CreateWorkflow_613642(protocol: Scheme; host: string; base: string;
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

proc validate_CreateWorkflow_613641(path: JsonNode; query: JsonNode;
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
  var valid_613643 = header.getOrDefault("X-Amz-Target")
  valid_613643 = validateParameter(valid_613643, JString, required = true,
                                 default = newJString("AWSGlue.CreateWorkflow"))
  if valid_613643 != nil:
    section.add "X-Amz-Target", valid_613643
  var valid_613644 = header.getOrDefault("X-Amz-Signature")
  valid_613644 = validateParameter(valid_613644, JString, required = false,
                                 default = nil)
  if valid_613644 != nil:
    section.add "X-Amz-Signature", valid_613644
  var valid_613645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613645 = validateParameter(valid_613645, JString, required = false,
                                 default = nil)
  if valid_613645 != nil:
    section.add "X-Amz-Content-Sha256", valid_613645
  var valid_613646 = header.getOrDefault("X-Amz-Date")
  valid_613646 = validateParameter(valid_613646, JString, required = false,
                                 default = nil)
  if valid_613646 != nil:
    section.add "X-Amz-Date", valid_613646
  var valid_613647 = header.getOrDefault("X-Amz-Credential")
  valid_613647 = validateParameter(valid_613647, JString, required = false,
                                 default = nil)
  if valid_613647 != nil:
    section.add "X-Amz-Credential", valid_613647
  var valid_613648 = header.getOrDefault("X-Amz-Security-Token")
  valid_613648 = validateParameter(valid_613648, JString, required = false,
                                 default = nil)
  if valid_613648 != nil:
    section.add "X-Amz-Security-Token", valid_613648
  var valid_613649 = header.getOrDefault("X-Amz-Algorithm")
  valid_613649 = validateParameter(valid_613649, JString, required = false,
                                 default = nil)
  if valid_613649 != nil:
    section.add "X-Amz-Algorithm", valid_613649
  var valid_613650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613650 = validateParameter(valid_613650, JString, required = false,
                                 default = nil)
  if valid_613650 != nil:
    section.add "X-Amz-SignedHeaders", valid_613650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613652: Call_CreateWorkflow_613640; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new workflow.
  ## 
  let valid = call_613652.validator(path, query, header, formData, body)
  let scheme = call_613652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613652.url(scheme.get, call_613652.host, call_613652.base,
                         call_613652.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613652, url, valid)

proc call*(call_613653: Call_CreateWorkflow_613640; body: JsonNode): Recallable =
  ## createWorkflow
  ## Creates a new workflow.
  ##   body: JObject (required)
  var body_613654 = newJObject()
  if body != nil:
    body_613654 = body
  result = call_613653.call(nil, nil, nil, nil, body_613654)

var createWorkflow* = Call_CreateWorkflow_613640(name: "createWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateWorkflow",
    validator: validate_CreateWorkflow_613641, base: "/", url: url_CreateWorkflow_613642,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteClassifier_613655 = ref object of OpenApiRestCall_612658
proc url_DeleteClassifier_613657(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteClassifier_613656(path: JsonNode; query: JsonNode;
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
  var valid_613658 = header.getOrDefault("X-Amz-Target")
  valid_613658 = validateParameter(valid_613658, JString, required = true, default = newJString(
      "AWSGlue.DeleteClassifier"))
  if valid_613658 != nil:
    section.add "X-Amz-Target", valid_613658
  var valid_613659 = header.getOrDefault("X-Amz-Signature")
  valid_613659 = validateParameter(valid_613659, JString, required = false,
                                 default = nil)
  if valid_613659 != nil:
    section.add "X-Amz-Signature", valid_613659
  var valid_613660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613660 = validateParameter(valid_613660, JString, required = false,
                                 default = nil)
  if valid_613660 != nil:
    section.add "X-Amz-Content-Sha256", valid_613660
  var valid_613661 = header.getOrDefault("X-Amz-Date")
  valid_613661 = validateParameter(valid_613661, JString, required = false,
                                 default = nil)
  if valid_613661 != nil:
    section.add "X-Amz-Date", valid_613661
  var valid_613662 = header.getOrDefault("X-Amz-Credential")
  valid_613662 = validateParameter(valid_613662, JString, required = false,
                                 default = nil)
  if valid_613662 != nil:
    section.add "X-Amz-Credential", valid_613662
  var valid_613663 = header.getOrDefault("X-Amz-Security-Token")
  valid_613663 = validateParameter(valid_613663, JString, required = false,
                                 default = nil)
  if valid_613663 != nil:
    section.add "X-Amz-Security-Token", valid_613663
  var valid_613664 = header.getOrDefault("X-Amz-Algorithm")
  valid_613664 = validateParameter(valid_613664, JString, required = false,
                                 default = nil)
  if valid_613664 != nil:
    section.add "X-Amz-Algorithm", valid_613664
  var valid_613665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613665 = validateParameter(valid_613665, JString, required = false,
                                 default = nil)
  if valid_613665 != nil:
    section.add "X-Amz-SignedHeaders", valid_613665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613667: Call_DeleteClassifier_613655; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a classifier from the Data Catalog.
  ## 
  let valid = call_613667.validator(path, query, header, formData, body)
  let scheme = call_613667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613667.url(scheme.get, call_613667.host, call_613667.base,
                         call_613667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613667, url, valid)

proc call*(call_613668: Call_DeleteClassifier_613655; body: JsonNode): Recallable =
  ## deleteClassifier
  ## Removes a classifier from the Data Catalog.
  ##   body: JObject (required)
  var body_613669 = newJObject()
  if body != nil:
    body_613669 = body
  result = call_613668.call(nil, nil, nil, nil, body_613669)

var deleteClassifier* = Call_DeleteClassifier_613655(name: "deleteClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteClassifier",
    validator: validate_DeleteClassifier_613656, base: "/",
    url: url_DeleteClassifier_613657, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnection_613670 = ref object of OpenApiRestCall_612658
proc url_DeleteConnection_613672(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteConnection_613671(path: JsonNode; query: JsonNode;
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
  var valid_613673 = header.getOrDefault("X-Amz-Target")
  valid_613673 = validateParameter(valid_613673, JString, required = true, default = newJString(
      "AWSGlue.DeleteConnection"))
  if valid_613673 != nil:
    section.add "X-Amz-Target", valid_613673
  var valid_613674 = header.getOrDefault("X-Amz-Signature")
  valid_613674 = validateParameter(valid_613674, JString, required = false,
                                 default = nil)
  if valid_613674 != nil:
    section.add "X-Amz-Signature", valid_613674
  var valid_613675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613675 = validateParameter(valid_613675, JString, required = false,
                                 default = nil)
  if valid_613675 != nil:
    section.add "X-Amz-Content-Sha256", valid_613675
  var valid_613676 = header.getOrDefault("X-Amz-Date")
  valid_613676 = validateParameter(valid_613676, JString, required = false,
                                 default = nil)
  if valid_613676 != nil:
    section.add "X-Amz-Date", valid_613676
  var valid_613677 = header.getOrDefault("X-Amz-Credential")
  valid_613677 = validateParameter(valid_613677, JString, required = false,
                                 default = nil)
  if valid_613677 != nil:
    section.add "X-Amz-Credential", valid_613677
  var valid_613678 = header.getOrDefault("X-Amz-Security-Token")
  valid_613678 = validateParameter(valid_613678, JString, required = false,
                                 default = nil)
  if valid_613678 != nil:
    section.add "X-Amz-Security-Token", valid_613678
  var valid_613679 = header.getOrDefault("X-Amz-Algorithm")
  valid_613679 = validateParameter(valid_613679, JString, required = false,
                                 default = nil)
  if valid_613679 != nil:
    section.add "X-Amz-Algorithm", valid_613679
  var valid_613680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613680 = validateParameter(valid_613680, JString, required = false,
                                 default = nil)
  if valid_613680 != nil:
    section.add "X-Amz-SignedHeaders", valid_613680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613682: Call_DeleteConnection_613670; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a connection from the Data Catalog.
  ## 
  let valid = call_613682.validator(path, query, header, formData, body)
  let scheme = call_613682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613682.url(scheme.get, call_613682.host, call_613682.base,
                         call_613682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613682, url, valid)

proc call*(call_613683: Call_DeleteConnection_613670; body: JsonNode): Recallable =
  ## deleteConnection
  ## Deletes a connection from the Data Catalog.
  ##   body: JObject (required)
  var body_613684 = newJObject()
  if body != nil:
    body_613684 = body
  result = call_613683.call(nil, nil, nil, nil, body_613684)

var deleteConnection* = Call_DeleteConnection_613670(name: "deleteConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteConnection",
    validator: validate_DeleteConnection_613671, base: "/",
    url: url_DeleteConnection_613672, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCrawler_613685 = ref object of OpenApiRestCall_612658
proc url_DeleteCrawler_613687(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCrawler_613686(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613688 = header.getOrDefault("X-Amz-Target")
  valid_613688 = validateParameter(valid_613688, JString, required = true,
                                 default = newJString("AWSGlue.DeleteCrawler"))
  if valid_613688 != nil:
    section.add "X-Amz-Target", valid_613688
  var valid_613689 = header.getOrDefault("X-Amz-Signature")
  valid_613689 = validateParameter(valid_613689, JString, required = false,
                                 default = nil)
  if valid_613689 != nil:
    section.add "X-Amz-Signature", valid_613689
  var valid_613690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613690 = validateParameter(valid_613690, JString, required = false,
                                 default = nil)
  if valid_613690 != nil:
    section.add "X-Amz-Content-Sha256", valid_613690
  var valid_613691 = header.getOrDefault("X-Amz-Date")
  valid_613691 = validateParameter(valid_613691, JString, required = false,
                                 default = nil)
  if valid_613691 != nil:
    section.add "X-Amz-Date", valid_613691
  var valid_613692 = header.getOrDefault("X-Amz-Credential")
  valid_613692 = validateParameter(valid_613692, JString, required = false,
                                 default = nil)
  if valid_613692 != nil:
    section.add "X-Amz-Credential", valid_613692
  var valid_613693 = header.getOrDefault("X-Amz-Security-Token")
  valid_613693 = validateParameter(valid_613693, JString, required = false,
                                 default = nil)
  if valid_613693 != nil:
    section.add "X-Amz-Security-Token", valid_613693
  var valid_613694 = header.getOrDefault("X-Amz-Algorithm")
  valid_613694 = validateParameter(valid_613694, JString, required = false,
                                 default = nil)
  if valid_613694 != nil:
    section.add "X-Amz-Algorithm", valid_613694
  var valid_613695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613695 = validateParameter(valid_613695, JString, required = false,
                                 default = nil)
  if valid_613695 != nil:
    section.add "X-Amz-SignedHeaders", valid_613695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613697: Call_DeleteCrawler_613685; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
  ## 
  let valid = call_613697.validator(path, query, header, formData, body)
  let scheme = call_613697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613697.url(scheme.get, call_613697.host, call_613697.base,
                         call_613697.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613697, url, valid)

proc call*(call_613698: Call_DeleteCrawler_613685; body: JsonNode): Recallable =
  ## deleteCrawler
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
  ##   body: JObject (required)
  var body_613699 = newJObject()
  if body != nil:
    body_613699 = body
  result = call_613698.call(nil, nil, nil, nil, body_613699)

var deleteCrawler* = Call_DeleteCrawler_613685(name: "deleteCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteCrawler",
    validator: validate_DeleteCrawler_613686, base: "/", url: url_DeleteCrawler_613687,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatabase_613700 = ref object of OpenApiRestCall_612658
proc url_DeleteDatabase_613702(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDatabase_613701(path: JsonNode; query: JsonNode;
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
  var valid_613703 = header.getOrDefault("X-Amz-Target")
  valid_613703 = validateParameter(valid_613703, JString, required = true,
                                 default = newJString("AWSGlue.DeleteDatabase"))
  if valid_613703 != nil:
    section.add "X-Amz-Target", valid_613703
  var valid_613704 = header.getOrDefault("X-Amz-Signature")
  valid_613704 = validateParameter(valid_613704, JString, required = false,
                                 default = nil)
  if valid_613704 != nil:
    section.add "X-Amz-Signature", valid_613704
  var valid_613705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613705 = validateParameter(valid_613705, JString, required = false,
                                 default = nil)
  if valid_613705 != nil:
    section.add "X-Amz-Content-Sha256", valid_613705
  var valid_613706 = header.getOrDefault("X-Amz-Date")
  valid_613706 = validateParameter(valid_613706, JString, required = false,
                                 default = nil)
  if valid_613706 != nil:
    section.add "X-Amz-Date", valid_613706
  var valid_613707 = header.getOrDefault("X-Amz-Credential")
  valid_613707 = validateParameter(valid_613707, JString, required = false,
                                 default = nil)
  if valid_613707 != nil:
    section.add "X-Amz-Credential", valid_613707
  var valid_613708 = header.getOrDefault("X-Amz-Security-Token")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-Security-Token", valid_613708
  var valid_613709 = header.getOrDefault("X-Amz-Algorithm")
  valid_613709 = validateParameter(valid_613709, JString, required = false,
                                 default = nil)
  if valid_613709 != nil:
    section.add "X-Amz-Algorithm", valid_613709
  var valid_613710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613710 = validateParameter(valid_613710, JString, required = false,
                                 default = nil)
  if valid_613710 != nil:
    section.add "X-Amz-SignedHeaders", valid_613710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613712: Call_DeleteDatabase_613700; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
  ## 
  let valid = call_613712.validator(path, query, header, formData, body)
  let scheme = call_613712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613712.url(scheme.get, call_613712.host, call_613712.base,
                         call_613712.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613712, url, valid)

proc call*(call_613713: Call_DeleteDatabase_613700; body: JsonNode): Recallable =
  ## deleteDatabase
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
  ##   body: JObject (required)
  var body_613714 = newJObject()
  if body != nil:
    body_613714 = body
  result = call_613713.call(nil, nil, nil, nil, body_613714)

var deleteDatabase* = Call_DeleteDatabase_613700(name: "deleteDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteDatabase",
    validator: validate_DeleteDatabase_613701, base: "/", url: url_DeleteDatabase_613702,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevEndpoint_613715 = ref object of OpenApiRestCall_612658
proc url_DeleteDevEndpoint_613717(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDevEndpoint_613716(path: JsonNode; query: JsonNode;
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
  var valid_613718 = header.getOrDefault("X-Amz-Target")
  valid_613718 = validateParameter(valid_613718, JString, required = true, default = newJString(
      "AWSGlue.DeleteDevEndpoint"))
  if valid_613718 != nil:
    section.add "X-Amz-Target", valid_613718
  var valid_613719 = header.getOrDefault("X-Amz-Signature")
  valid_613719 = validateParameter(valid_613719, JString, required = false,
                                 default = nil)
  if valid_613719 != nil:
    section.add "X-Amz-Signature", valid_613719
  var valid_613720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613720 = validateParameter(valid_613720, JString, required = false,
                                 default = nil)
  if valid_613720 != nil:
    section.add "X-Amz-Content-Sha256", valid_613720
  var valid_613721 = header.getOrDefault("X-Amz-Date")
  valid_613721 = validateParameter(valid_613721, JString, required = false,
                                 default = nil)
  if valid_613721 != nil:
    section.add "X-Amz-Date", valid_613721
  var valid_613722 = header.getOrDefault("X-Amz-Credential")
  valid_613722 = validateParameter(valid_613722, JString, required = false,
                                 default = nil)
  if valid_613722 != nil:
    section.add "X-Amz-Credential", valid_613722
  var valid_613723 = header.getOrDefault("X-Amz-Security-Token")
  valid_613723 = validateParameter(valid_613723, JString, required = false,
                                 default = nil)
  if valid_613723 != nil:
    section.add "X-Amz-Security-Token", valid_613723
  var valid_613724 = header.getOrDefault("X-Amz-Algorithm")
  valid_613724 = validateParameter(valid_613724, JString, required = false,
                                 default = nil)
  if valid_613724 != nil:
    section.add "X-Amz-Algorithm", valid_613724
  var valid_613725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "X-Amz-SignedHeaders", valid_613725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613727: Call_DeleteDevEndpoint_613715; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified development endpoint.
  ## 
  let valid = call_613727.validator(path, query, header, formData, body)
  let scheme = call_613727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613727.url(scheme.get, call_613727.host, call_613727.base,
                         call_613727.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613727, url, valid)

proc call*(call_613728: Call_DeleteDevEndpoint_613715; body: JsonNode): Recallable =
  ## deleteDevEndpoint
  ## Deletes a specified development endpoint.
  ##   body: JObject (required)
  var body_613729 = newJObject()
  if body != nil:
    body_613729 = body
  result = call_613728.call(nil, nil, nil, nil, body_613729)

var deleteDevEndpoint* = Call_DeleteDevEndpoint_613715(name: "deleteDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteDevEndpoint",
    validator: validate_DeleteDevEndpoint_613716, base: "/",
    url: url_DeleteDevEndpoint_613717, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJob_613730 = ref object of OpenApiRestCall_612658
proc url_DeleteJob_613732(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteJob_613731(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613733 = header.getOrDefault("X-Amz-Target")
  valid_613733 = validateParameter(valid_613733, JString, required = true,
                                 default = newJString("AWSGlue.DeleteJob"))
  if valid_613733 != nil:
    section.add "X-Amz-Target", valid_613733
  var valid_613734 = header.getOrDefault("X-Amz-Signature")
  valid_613734 = validateParameter(valid_613734, JString, required = false,
                                 default = nil)
  if valid_613734 != nil:
    section.add "X-Amz-Signature", valid_613734
  var valid_613735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613735 = validateParameter(valid_613735, JString, required = false,
                                 default = nil)
  if valid_613735 != nil:
    section.add "X-Amz-Content-Sha256", valid_613735
  var valid_613736 = header.getOrDefault("X-Amz-Date")
  valid_613736 = validateParameter(valid_613736, JString, required = false,
                                 default = nil)
  if valid_613736 != nil:
    section.add "X-Amz-Date", valid_613736
  var valid_613737 = header.getOrDefault("X-Amz-Credential")
  valid_613737 = validateParameter(valid_613737, JString, required = false,
                                 default = nil)
  if valid_613737 != nil:
    section.add "X-Amz-Credential", valid_613737
  var valid_613738 = header.getOrDefault("X-Amz-Security-Token")
  valid_613738 = validateParameter(valid_613738, JString, required = false,
                                 default = nil)
  if valid_613738 != nil:
    section.add "X-Amz-Security-Token", valid_613738
  var valid_613739 = header.getOrDefault("X-Amz-Algorithm")
  valid_613739 = validateParameter(valid_613739, JString, required = false,
                                 default = nil)
  if valid_613739 != nil:
    section.add "X-Amz-Algorithm", valid_613739
  var valid_613740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613740 = validateParameter(valid_613740, JString, required = false,
                                 default = nil)
  if valid_613740 != nil:
    section.add "X-Amz-SignedHeaders", valid_613740
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613742: Call_DeleteJob_613730; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
  ## 
  let valid = call_613742.validator(path, query, header, formData, body)
  let scheme = call_613742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613742.url(scheme.get, call_613742.host, call_613742.base,
                         call_613742.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613742, url, valid)

proc call*(call_613743: Call_DeleteJob_613730; body: JsonNode): Recallable =
  ## deleteJob
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
  ##   body: JObject (required)
  var body_613744 = newJObject()
  if body != nil:
    body_613744 = body
  result = call_613743.call(nil, nil, nil, nil, body_613744)

var deleteJob* = Call_DeleteJob_613730(name: "deleteJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.DeleteJob",
                                    validator: validate_DeleteJob_613731,
                                    base: "/", url: url_DeleteJob_613732,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMLTransform_613745 = ref object of OpenApiRestCall_612658
proc url_DeleteMLTransform_613747(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMLTransform_613746(path: JsonNode; query: JsonNode;
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
  var valid_613748 = header.getOrDefault("X-Amz-Target")
  valid_613748 = validateParameter(valid_613748, JString, required = true, default = newJString(
      "AWSGlue.DeleteMLTransform"))
  if valid_613748 != nil:
    section.add "X-Amz-Target", valid_613748
  var valid_613749 = header.getOrDefault("X-Amz-Signature")
  valid_613749 = validateParameter(valid_613749, JString, required = false,
                                 default = nil)
  if valid_613749 != nil:
    section.add "X-Amz-Signature", valid_613749
  var valid_613750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613750 = validateParameter(valid_613750, JString, required = false,
                                 default = nil)
  if valid_613750 != nil:
    section.add "X-Amz-Content-Sha256", valid_613750
  var valid_613751 = header.getOrDefault("X-Amz-Date")
  valid_613751 = validateParameter(valid_613751, JString, required = false,
                                 default = nil)
  if valid_613751 != nil:
    section.add "X-Amz-Date", valid_613751
  var valid_613752 = header.getOrDefault("X-Amz-Credential")
  valid_613752 = validateParameter(valid_613752, JString, required = false,
                                 default = nil)
  if valid_613752 != nil:
    section.add "X-Amz-Credential", valid_613752
  var valid_613753 = header.getOrDefault("X-Amz-Security-Token")
  valid_613753 = validateParameter(valid_613753, JString, required = false,
                                 default = nil)
  if valid_613753 != nil:
    section.add "X-Amz-Security-Token", valid_613753
  var valid_613754 = header.getOrDefault("X-Amz-Algorithm")
  valid_613754 = validateParameter(valid_613754, JString, required = false,
                                 default = nil)
  if valid_613754 != nil:
    section.add "X-Amz-Algorithm", valid_613754
  var valid_613755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613755 = validateParameter(valid_613755, JString, required = false,
                                 default = nil)
  if valid_613755 != nil:
    section.add "X-Amz-SignedHeaders", valid_613755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613757: Call_DeleteMLTransform_613745; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
  ## 
  let valid = call_613757.validator(path, query, header, formData, body)
  let scheme = call_613757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613757.url(scheme.get, call_613757.host, call_613757.base,
                         call_613757.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613757, url, valid)

proc call*(call_613758: Call_DeleteMLTransform_613745; body: JsonNode): Recallable =
  ## deleteMLTransform
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
  ##   body: JObject (required)
  var body_613759 = newJObject()
  if body != nil:
    body_613759 = body
  result = call_613758.call(nil, nil, nil, nil, body_613759)

var deleteMLTransform* = Call_DeleteMLTransform_613745(name: "deleteMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteMLTransform",
    validator: validate_DeleteMLTransform_613746, base: "/",
    url: url_DeleteMLTransform_613747, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePartition_613760 = ref object of OpenApiRestCall_612658
proc url_DeletePartition_613762(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePartition_613761(path: JsonNode; query: JsonNode;
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
  var valid_613763 = header.getOrDefault("X-Amz-Target")
  valid_613763 = validateParameter(valid_613763, JString, required = true, default = newJString(
      "AWSGlue.DeletePartition"))
  if valid_613763 != nil:
    section.add "X-Amz-Target", valid_613763
  var valid_613764 = header.getOrDefault("X-Amz-Signature")
  valid_613764 = validateParameter(valid_613764, JString, required = false,
                                 default = nil)
  if valid_613764 != nil:
    section.add "X-Amz-Signature", valid_613764
  var valid_613765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613765 = validateParameter(valid_613765, JString, required = false,
                                 default = nil)
  if valid_613765 != nil:
    section.add "X-Amz-Content-Sha256", valid_613765
  var valid_613766 = header.getOrDefault("X-Amz-Date")
  valid_613766 = validateParameter(valid_613766, JString, required = false,
                                 default = nil)
  if valid_613766 != nil:
    section.add "X-Amz-Date", valid_613766
  var valid_613767 = header.getOrDefault("X-Amz-Credential")
  valid_613767 = validateParameter(valid_613767, JString, required = false,
                                 default = nil)
  if valid_613767 != nil:
    section.add "X-Amz-Credential", valid_613767
  var valid_613768 = header.getOrDefault("X-Amz-Security-Token")
  valid_613768 = validateParameter(valid_613768, JString, required = false,
                                 default = nil)
  if valid_613768 != nil:
    section.add "X-Amz-Security-Token", valid_613768
  var valid_613769 = header.getOrDefault("X-Amz-Algorithm")
  valid_613769 = validateParameter(valid_613769, JString, required = false,
                                 default = nil)
  if valid_613769 != nil:
    section.add "X-Amz-Algorithm", valid_613769
  var valid_613770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613770 = validateParameter(valid_613770, JString, required = false,
                                 default = nil)
  if valid_613770 != nil:
    section.add "X-Amz-SignedHeaders", valid_613770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613772: Call_DeletePartition_613760; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified partition.
  ## 
  let valid = call_613772.validator(path, query, header, formData, body)
  let scheme = call_613772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613772.url(scheme.get, call_613772.host, call_613772.base,
                         call_613772.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613772, url, valid)

proc call*(call_613773: Call_DeletePartition_613760; body: JsonNode): Recallable =
  ## deletePartition
  ## Deletes a specified partition.
  ##   body: JObject (required)
  var body_613774 = newJObject()
  if body != nil:
    body_613774 = body
  result = call_613773.call(nil, nil, nil, nil, body_613774)

var deletePartition* = Call_DeletePartition_613760(name: "deletePartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeletePartition",
    validator: validate_DeletePartition_613761, base: "/", url: url_DeletePartition_613762,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourcePolicy_613775 = ref object of OpenApiRestCall_612658
proc url_DeleteResourcePolicy_613777(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResourcePolicy_613776(path: JsonNode; query: JsonNode;
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
  var valid_613778 = header.getOrDefault("X-Amz-Target")
  valid_613778 = validateParameter(valid_613778, JString, required = true, default = newJString(
      "AWSGlue.DeleteResourcePolicy"))
  if valid_613778 != nil:
    section.add "X-Amz-Target", valid_613778
  var valid_613779 = header.getOrDefault("X-Amz-Signature")
  valid_613779 = validateParameter(valid_613779, JString, required = false,
                                 default = nil)
  if valid_613779 != nil:
    section.add "X-Amz-Signature", valid_613779
  var valid_613780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613780 = validateParameter(valid_613780, JString, required = false,
                                 default = nil)
  if valid_613780 != nil:
    section.add "X-Amz-Content-Sha256", valid_613780
  var valid_613781 = header.getOrDefault("X-Amz-Date")
  valid_613781 = validateParameter(valid_613781, JString, required = false,
                                 default = nil)
  if valid_613781 != nil:
    section.add "X-Amz-Date", valid_613781
  var valid_613782 = header.getOrDefault("X-Amz-Credential")
  valid_613782 = validateParameter(valid_613782, JString, required = false,
                                 default = nil)
  if valid_613782 != nil:
    section.add "X-Amz-Credential", valid_613782
  var valid_613783 = header.getOrDefault("X-Amz-Security-Token")
  valid_613783 = validateParameter(valid_613783, JString, required = false,
                                 default = nil)
  if valid_613783 != nil:
    section.add "X-Amz-Security-Token", valid_613783
  var valid_613784 = header.getOrDefault("X-Amz-Algorithm")
  valid_613784 = validateParameter(valid_613784, JString, required = false,
                                 default = nil)
  if valid_613784 != nil:
    section.add "X-Amz-Algorithm", valid_613784
  var valid_613785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613785 = validateParameter(valid_613785, JString, required = false,
                                 default = nil)
  if valid_613785 != nil:
    section.add "X-Amz-SignedHeaders", valid_613785
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613787: Call_DeleteResourcePolicy_613775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified policy.
  ## 
  let valid = call_613787.validator(path, query, header, formData, body)
  let scheme = call_613787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613787.url(scheme.get, call_613787.host, call_613787.base,
                         call_613787.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613787, url, valid)

proc call*(call_613788: Call_DeleteResourcePolicy_613775; body: JsonNode): Recallable =
  ## deleteResourcePolicy
  ## Deletes a specified policy.
  ##   body: JObject (required)
  var body_613789 = newJObject()
  if body != nil:
    body_613789 = body
  result = call_613788.call(nil, nil, nil, nil, body_613789)

var deleteResourcePolicy* = Call_DeleteResourcePolicy_613775(
    name: "deleteResourcePolicy", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteResourcePolicy",
    validator: validate_DeleteResourcePolicy_613776, base: "/",
    url: url_DeleteResourcePolicy_613777, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSecurityConfiguration_613790 = ref object of OpenApiRestCall_612658
proc url_DeleteSecurityConfiguration_613792(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSecurityConfiguration_613791(path: JsonNode; query: JsonNode;
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
  var valid_613793 = header.getOrDefault("X-Amz-Target")
  valid_613793 = validateParameter(valid_613793, JString, required = true, default = newJString(
      "AWSGlue.DeleteSecurityConfiguration"))
  if valid_613793 != nil:
    section.add "X-Amz-Target", valid_613793
  var valid_613794 = header.getOrDefault("X-Amz-Signature")
  valid_613794 = validateParameter(valid_613794, JString, required = false,
                                 default = nil)
  if valid_613794 != nil:
    section.add "X-Amz-Signature", valid_613794
  var valid_613795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613795 = validateParameter(valid_613795, JString, required = false,
                                 default = nil)
  if valid_613795 != nil:
    section.add "X-Amz-Content-Sha256", valid_613795
  var valid_613796 = header.getOrDefault("X-Amz-Date")
  valid_613796 = validateParameter(valid_613796, JString, required = false,
                                 default = nil)
  if valid_613796 != nil:
    section.add "X-Amz-Date", valid_613796
  var valid_613797 = header.getOrDefault("X-Amz-Credential")
  valid_613797 = validateParameter(valid_613797, JString, required = false,
                                 default = nil)
  if valid_613797 != nil:
    section.add "X-Amz-Credential", valid_613797
  var valid_613798 = header.getOrDefault("X-Amz-Security-Token")
  valid_613798 = validateParameter(valid_613798, JString, required = false,
                                 default = nil)
  if valid_613798 != nil:
    section.add "X-Amz-Security-Token", valid_613798
  var valid_613799 = header.getOrDefault("X-Amz-Algorithm")
  valid_613799 = validateParameter(valid_613799, JString, required = false,
                                 default = nil)
  if valid_613799 != nil:
    section.add "X-Amz-Algorithm", valid_613799
  var valid_613800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613800 = validateParameter(valid_613800, JString, required = false,
                                 default = nil)
  if valid_613800 != nil:
    section.add "X-Amz-SignedHeaders", valid_613800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613802: Call_DeleteSecurityConfiguration_613790; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified security configuration.
  ## 
  let valid = call_613802.validator(path, query, header, formData, body)
  let scheme = call_613802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613802.url(scheme.get, call_613802.host, call_613802.base,
                         call_613802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613802, url, valid)

proc call*(call_613803: Call_DeleteSecurityConfiguration_613790; body: JsonNode): Recallable =
  ## deleteSecurityConfiguration
  ## Deletes a specified security configuration.
  ##   body: JObject (required)
  var body_613804 = newJObject()
  if body != nil:
    body_613804 = body
  result = call_613803.call(nil, nil, nil, nil, body_613804)

var deleteSecurityConfiguration* = Call_DeleteSecurityConfiguration_613790(
    name: "deleteSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteSecurityConfiguration",
    validator: validate_DeleteSecurityConfiguration_613791, base: "/",
    url: url_DeleteSecurityConfiguration_613792,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTable_613805 = ref object of OpenApiRestCall_612658
proc url_DeleteTable_613807(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTable_613806(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613808 = header.getOrDefault("X-Amz-Target")
  valid_613808 = validateParameter(valid_613808, JString, required = true,
                                 default = newJString("AWSGlue.DeleteTable"))
  if valid_613808 != nil:
    section.add "X-Amz-Target", valid_613808
  var valid_613809 = header.getOrDefault("X-Amz-Signature")
  valid_613809 = validateParameter(valid_613809, JString, required = false,
                                 default = nil)
  if valid_613809 != nil:
    section.add "X-Amz-Signature", valid_613809
  var valid_613810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613810 = validateParameter(valid_613810, JString, required = false,
                                 default = nil)
  if valid_613810 != nil:
    section.add "X-Amz-Content-Sha256", valid_613810
  var valid_613811 = header.getOrDefault("X-Amz-Date")
  valid_613811 = validateParameter(valid_613811, JString, required = false,
                                 default = nil)
  if valid_613811 != nil:
    section.add "X-Amz-Date", valid_613811
  var valid_613812 = header.getOrDefault("X-Amz-Credential")
  valid_613812 = validateParameter(valid_613812, JString, required = false,
                                 default = nil)
  if valid_613812 != nil:
    section.add "X-Amz-Credential", valid_613812
  var valid_613813 = header.getOrDefault("X-Amz-Security-Token")
  valid_613813 = validateParameter(valid_613813, JString, required = false,
                                 default = nil)
  if valid_613813 != nil:
    section.add "X-Amz-Security-Token", valid_613813
  var valid_613814 = header.getOrDefault("X-Amz-Algorithm")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-Algorithm", valid_613814
  var valid_613815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613815 = validateParameter(valid_613815, JString, required = false,
                                 default = nil)
  if valid_613815 != nil:
    section.add "X-Amz-SignedHeaders", valid_613815
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613817: Call_DeleteTable_613805; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ## 
  let valid = call_613817.validator(path, query, header, formData, body)
  let scheme = call_613817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613817.url(scheme.get, call_613817.host, call_613817.base,
                         call_613817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613817, url, valid)

proc call*(call_613818: Call_DeleteTable_613805; body: JsonNode): Recallable =
  ## deleteTable
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ##   body: JObject (required)
  var body_613819 = newJObject()
  if body != nil:
    body_613819 = body
  result = call_613818.call(nil, nil, nil, nil, body_613819)

var deleteTable* = Call_DeleteTable_613805(name: "deleteTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.DeleteTable",
                                        validator: validate_DeleteTable_613806,
                                        base: "/", url: url_DeleteTable_613807,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTableVersion_613820 = ref object of OpenApiRestCall_612658
proc url_DeleteTableVersion_613822(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTableVersion_613821(path: JsonNode; query: JsonNode;
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
  var valid_613823 = header.getOrDefault("X-Amz-Target")
  valid_613823 = validateParameter(valid_613823, JString, required = true, default = newJString(
      "AWSGlue.DeleteTableVersion"))
  if valid_613823 != nil:
    section.add "X-Amz-Target", valid_613823
  var valid_613824 = header.getOrDefault("X-Amz-Signature")
  valid_613824 = validateParameter(valid_613824, JString, required = false,
                                 default = nil)
  if valid_613824 != nil:
    section.add "X-Amz-Signature", valid_613824
  var valid_613825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613825 = validateParameter(valid_613825, JString, required = false,
                                 default = nil)
  if valid_613825 != nil:
    section.add "X-Amz-Content-Sha256", valid_613825
  var valid_613826 = header.getOrDefault("X-Amz-Date")
  valid_613826 = validateParameter(valid_613826, JString, required = false,
                                 default = nil)
  if valid_613826 != nil:
    section.add "X-Amz-Date", valid_613826
  var valid_613827 = header.getOrDefault("X-Amz-Credential")
  valid_613827 = validateParameter(valid_613827, JString, required = false,
                                 default = nil)
  if valid_613827 != nil:
    section.add "X-Amz-Credential", valid_613827
  var valid_613828 = header.getOrDefault("X-Amz-Security-Token")
  valid_613828 = validateParameter(valid_613828, JString, required = false,
                                 default = nil)
  if valid_613828 != nil:
    section.add "X-Amz-Security-Token", valid_613828
  var valid_613829 = header.getOrDefault("X-Amz-Algorithm")
  valid_613829 = validateParameter(valid_613829, JString, required = false,
                                 default = nil)
  if valid_613829 != nil:
    section.add "X-Amz-Algorithm", valid_613829
  var valid_613830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613830 = validateParameter(valid_613830, JString, required = false,
                                 default = nil)
  if valid_613830 != nil:
    section.add "X-Amz-SignedHeaders", valid_613830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613832: Call_DeleteTableVersion_613820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified version of a table.
  ## 
  let valid = call_613832.validator(path, query, header, formData, body)
  let scheme = call_613832.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613832.url(scheme.get, call_613832.host, call_613832.base,
                         call_613832.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613832, url, valid)

proc call*(call_613833: Call_DeleteTableVersion_613820; body: JsonNode): Recallable =
  ## deleteTableVersion
  ## Deletes a specified version of a table.
  ##   body: JObject (required)
  var body_613834 = newJObject()
  if body != nil:
    body_613834 = body
  result = call_613833.call(nil, nil, nil, nil, body_613834)

var deleteTableVersion* = Call_DeleteTableVersion_613820(
    name: "deleteTableVersion", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteTableVersion",
    validator: validate_DeleteTableVersion_613821, base: "/",
    url: url_DeleteTableVersion_613822, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrigger_613835 = ref object of OpenApiRestCall_612658
proc url_DeleteTrigger_613837(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTrigger_613836(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613838 = header.getOrDefault("X-Amz-Target")
  valid_613838 = validateParameter(valid_613838, JString, required = true,
                                 default = newJString("AWSGlue.DeleteTrigger"))
  if valid_613838 != nil:
    section.add "X-Amz-Target", valid_613838
  var valid_613839 = header.getOrDefault("X-Amz-Signature")
  valid_613839 = validateParameter(valid_613839, JString, required = false,
                                 default = nil)
  if valid_613839 != nil:
    section.add "X-Amz-Signature", valid_613839
  var valid_613840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613840 = validateParameter(valid_613840, JString, required = false,
                                 default = nil)
  if valid_613840 != nil:
    section.add "X-Amz-Content-Sha256", valid_613840
  var valid_613841 = header.getOrDefault("X-Amz-Date")
  valid_613841 = validateParameter(valid_613841, JString, required = false,
                                 default = nil)
  if valid_613841 != nil:
    section.add "X-Amz-Date", valid_613841
  var valid_613842 = header.getOrDefault("X-Amz-Credential")
  valid_613842 = validateParameter(valid_613842, JString, required = false,
                                 default = nil)
  if valid_613842 != nil:
    section.add "X-Amz-Credential", valid_613842
  var valid_613843 = header.getOrDefault("X-Amz-Security-Token")
  valid_613843 = validateParameter(valid_613843, JString, required = false,
                                 default = nil)
  if valid_613843 != nil:
    section.add "X-Amz-Security-Token", valid_613843
  var valid_613844 = header.getOrDefault("X-Amz-Algorithm")
  valid_613844 = validateParameter(valid_613844, JString, required = false,
                                 default = nil)
  if valid_613844 != nil:
    section.add "X-Amz-Algorithm", valid_613844
  var valid_613845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613845 = validateParameter(valid_613845, JString, required = false,
                                 default = nil)
  if valid_613845 != nil:
    section.add "X-Amz-SignedHeaders", valid_613845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613847: Call_DeleteTrigger_613835; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
  ## 
  let valid = call_613847.validator(path, query, header, formData, body)
  let scheme = call_613847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613847.url(scheme.get, call_613847.host, call_613847.base,
                         call_613847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613847, url, valid)

proc call*(call_613848: Call_DeleteTrigger_613835; body: JsonNode): Recallable =
  ## deleteTrigger
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
  ##   body: JObject (required)
  var body_613849 = newJObject()
  if body != nil:
    body_613849 = body
  result = call_613848.call(nil, nil, nil, nil, body_613849)

var deleteTrigger* = Call_DeleteTrigger_613835(name: "deleteTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteTrigger",
    validator: validate_DeleteTrigger_613836, base: "/", url: url_DeleteTrigger_613837,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserDefinedFunction_613850 = ref object of OpenApiRestCall_612658
proc url_DeleteUserDefinedFunction_613852(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUserDefinedFunction_613851(path: JsonNode; query: JsonNode;
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
  var valid_613853 = header.getOrDefault("X-Amz-Target")
  valid_613853 = validateParameter(valid_613853, JString, required = true, default = newJString(
      "AWSGlue.DeleteUserDefinedFunction"))
  if valid_613853 != nil:
    section.add "X-Amz-Target", valid_613853
  var valid_613854 = header.getOrDefault("X-Amz-Signature")
  valid_613854 = validateParameter(valid_613854, JString, required = false,
                                 default = nil)
  if valid_613854 != nil:
    section.add "X-Amz-Signature", valid_613854
  var valid_613855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613855 = validateParameter(valid_613855, JString, required = false,
                                 default = nil)
  if valid_613855 != nil:
    section.add "X-Amz-Content-Sha256", valid_613855
  var valid_613856 = header.getOrDefault("X-Amz-Date")
  valid_613856 = validateParameter(valid_613856, JString, required = false,
                                 default = nil)
  if valid_613856 != nil:
    section.add "X-Amz-Date", valid_613856
  var valid_613857 = header.getOrDefault("X-Amz-Credential")
  valid_613857 = validateParameter(valid_613857, JString, required = false,
                                 default = nil)
  if valid_613857 != nil:
    section.add "X-Amz-Credential", valid_613857
  var valid_613858 = header.getOrDefault("X-Amz-Security-Token")
  valid_613858 = validateParameter(valid_613858, JString, required = false,
                                 default = nil)
  if valid_613858 != nil:
    section.add "X-Amz-Security-Token", valid_613858
  var valid_613859 = header.getOrDefault("X-Amz-Algorithm")
  valid_613859 = validateParameter(valid_613859, JString, required = false,
                                 default = nil)
  if valid_613859 != nil:
    section.add "X-Amz-Algorithm", valid_613859
  var valid_613860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613860 = validateParameter(valid_613860, JString, required = false,
                                 default = nil)
  if valid_613860 != nil:
    section.add "X-Amz-SignedHeaders", valid_613860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613862: Call_DeleteUserDefinedFunction_613850; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing function definition from the Data Catalog.
  ## 
  let valid = call_613862.validator(path, query, header, formData, body)
  let scheme = call_613862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613862.url(scheme.get, call_613862.host, call_613862.base,
                         call_613862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613862, url, valid)

proc call*(call_613863: Call_DeleteUserDefinedFunction_613850; body: JsonNode): Recallable =
  ## deleteUserDefinedFunction
  ## Deletes an existing function definition from the Data Catalog.
  ##   body: JObject (required)
  var body_613864 = newJObject()
  if body != nil:
    body_613864 = body
  result = call_613863.call(nil, nil, nil, nil, body_613864)

var deleteUserDefinedFunction* = Call_DeleteUserDefinedFunction_613850(
    name: "deleteUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteUserDefinedFunction",
    validator: validate_DeleteUserDefinedFunction_613851, base: "/",
    url: url_DeleteUserDefinedFunction_613852,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkflow_613865 = ref object of OpenApiRestCall_612658
proc url_DeleteWorkflow_613867(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteWorkflow_613866(path: JsonNode; query: JsonNode;
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
  var valid_613868 = header.getOrDefault("X-Amz-Target")
  valid_613868 = validateParameter(valid_613868, JString, required = true,
                                 default = newJString("AWSGlue.DeleteWorkflow"))
  if valid_613868 != nil:
    section.add "X-Amz-Target", valid_613868
  var valid_613869 = header.getOrDefault("X-Amz-Signature")
  valid_613869 = validateParameter(valid_613869, JString, required = false,
                                 default = nil)
  if valid_613869 != nil:
    section.add "X-Amz-Signature", valid_613869
  var valid_613870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613870 = validateParameter(valid_613870, JString, required = false,
                                 default = nil)
  if valid_613870 != nil:
    section.add "X-Amz-Content-Sha256", valid_613870
  var valid_613871 = header.getOrDefault("X-Amz-Date")
  valid_613871 = validateParameter(valid_613871, JString, required = false,
                                 default = nil)
  if valid_613871 != nil:
    section.add "X-Amz-Date", valid_613871
  var valid_613872 = header.getOrDefault("X-Amz-Credential")
  valid_613872 = validateParameter(valid_613872, JString, required = false,
                                 default = nil)
  if valid_613872 != nil:
    section.add "X-Amz-Credential", valid_613872
  var valid_613873 = header.getOrDefault("X-Amz-Security-Token")
  valid_613873 = validateParameter(valid_613873, JString, required = false,
                                 default = nil)
  if valid_613873 != nil:
    section.add "X-Amz-Security-Token", valid_613873
  var valid_613874 = header.getOrDefault("X-Amz-Algorithm")
  valid_613874 = validateParameter(valid_613874, JString, required = false,
                                 default = nil)
  if valid_613874 != nil:
    section.add "X-Amz-Algorithm", valid_613874
  var valid_613875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613875 = validateParameter(valid_613875, JString, required = false,
                                 default = nil)
  if valid_613875 != nil:
    section.add "X-Amz-SignedHeaders", valid_613875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613877: Call_DeleteWorkflow_613865; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a workflow.
  ## 
  let valid = call_613877.validator(path, query, header, formData, body)
  let scheme = call_613877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613877.url(scheme.get, call_613877.host, call_613877.base,
                         call_613877.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613877, url, valid)

proc call*(call_613878: Call_DeleteWorkflow_613865; body: JsonNode): Recallable =
  ## deleteWorkflow
  ## Deletes a workflow.
  ##   body: JObject (required)
  var body_613879 = newJObject()
  if body != nil:
    body_613879 = body
  result = call_613878.call(nil, nil, nil, nil, body_613879)

var deleteWorkflow* = Call_DeleteWorkflow_613865(name: "deleteWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteWorkflow",
    validator: validate_DeleteWorkflow_613866, base: "/", url: url_DeleteWorkflow_613867,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCatalogImportStatus_613880 = ref object of OpenApiRestCall_612658
proc url_GetCatalogImportStatus_613882(protocol: Scheme; host: string; base: string;
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

proc validate_GetCatalogImportStatus_613881(path: JsonNode; query: JsonNode;
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
  var valid_613883 = header.getOrDefault("X-Amz-Target")
  valid_613883 = validateParameter(valid_613883, JString, required = true, default = newJString(
      "AWSGlue.GetCatalogImportStatus"))
  if valid_613883 != nil:
    section.add "X-Amz-Target", valid_613883
  var valid_613884 = header.getOrDefault("X-Amz-Signature")
  valid_613884 = validateParameter(valid_613884, JString, required = false,
                                 default = nil)
  if valid_613884 != nil:
    section.add "X-Amz-Signature", valid_613884
  var valid_613885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613885 = validateParameter(valid_613885, JString, required = false,
                                 default = nil)
  if valid_613885 != nil:
    section.add "X-Amz-Content-Sha256", valid_613885
  var valid_613886 = header.getOrDefault("X-Amz-Date")
  valid_613886 = validateParameter(valid_613886, JString, required = false,
                                 default = nil)
  if valid_613886 != nil:
    section.add "X-Amz-Date", valid_613886
  var valid_613887 = header.getOrDefault("X-Amz-Credential")
  valid_613887 = validateParameter(valid_613887, JString, required = false,
                                 default = nil)
  if valid_613887 != nil:
    section.add "X-Amz-Credential", valid_613887
  var valid_613888 = header.getOrDefault("X-Amz-Security-Token")
  valid_613888 = validateParameter(valid_613888, JString, required = false,
                                 default = nil)
  if valid_613888 != nil:
    section.add "X-Amz-Security-Token", valid_613888
  var valid_613889 = header.getOrDefault("X-Amz-Algorithm")
  valid_613889 = validateParameter(valid_613889, JString, required = false,
                                 default = nil)
  if valid_613889 != nil:
    section.add "X-Amz-Algorithm", valid_613889
  var valid_613890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613890 = validateParameter(valid_613890, JString, required = false,
                                 default = nil)
  if valid_613890 != nil:
    section.add "X-Amz-SignedHeaders", valid_613890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613892: Call_GetCatalogImportStatus_613880; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the status of a migration operation.
  ## 
  let valid = call_613892.validator(path, query, header, formData, body)
  let scheme = call_613892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613892.url(scheme.get, call_613892.host, call_613892.base,
                         call_613892.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613892, url, valid)

proc call*(call_613893: Call_GetCatalogImportStatus_613880; body: JsonNode): Recallable =
  ## getCatalogImportStatus
  ## Retrieves the status of a migration operation.
  ##   body: JObject (required)
  var body_613894 = newJObject()
  if body != nil:
    body_613894 = body
  result = call_613893.call(nil, nil, nil, nil, body_613894)

var getCatalogImportStatus* = Call_GetCatalogImportStatus_613880(
    name: "getCatalogImportStatus", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetCatalogImportStatus",
    validator: validate_GetCatalogImportStatus_613881, base: "/",
    url: url_GetCatalogImportStatus_613882, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClassifier_613895 = ref object of OpenApiRestCall_612658
proc url_GetClassifier_613897(protocol: Scheme; host: string; base: string;
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

proc validate_GetClassifier_613896(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613898 = header.getOrDefault("X-Amz-Target")
  valid_613898 = validateParameter(valid_613898, JString, required = true,
                                 default = newJString("AWSGlue.GetClassifier"))
  if valid_613898 != nil:
    section.add "X-Amz-Target", valid_613898
  var valid_613899 = header.getOrDefault("X-Amz-Signature")
  valid_613899 = validateParameter(valid_613899, JString, required = false,
                                 default = nil)
  if valid_613899 != nil:
    section.add "X-Amz-Signature", valid_613899
  var valid_613900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613900 = validateParameter(valid_613900, JString, required = false,
                                 default = nil)
  if valid_613900 != nil:
    section.add "X-Amz-Content-Sha256", valid_613900
  var valid_613901 = header.getOrDefault("X-Amz-Date")
  valid_613901 = validateParameter(valid_613901, JString, required = false,
                                 default = nil)
  if valid_613901 != nil:
    section.add "X-Amz-Date", valid_613901
  var valid_613902 = header.getOrDefault("X-Amz-Credential")
  valid_613902 = validateParameter(valid_613902, JString, required = false,
                                 default = nil)
  if valid_613902 != nil:
    section.add "X-Amz-Credential", valid_613902
  var valid_613903 = header.getOrDefault("X-Amz-Security-Token")
  valid_613903 = validateParameter(valid_613903, JString, required = false,
                                 default = nil)
  if valid_613903 != nil:
    section.add "X-Amz-Security-Token", valid_613903
  var valid_613904 = header.getOrDefault("X-Amz-Algorithm")
  valid_613904 = validateParameter(valid_613904, JString, required = false,
                                 default = nil)
  if valid_613904 != nil:
    section.add "X-Amz-Algorithm", valid_613904
  var valid_613905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613905 = validateParameter(valid_613905, JString, required = false,
                                 default = nil)
  if valid_613905 != nil:
    section.add "X-Amz-SignedHeaders", valid_613905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613907: Call_GetClassifier_613895; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a classifier by name.
  ## 
  let valid = call_613907.validator(path, query, header, formData, body)
  let scheme = call_613907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613907.url(scheme.get, call_613907.host, call_613907.base,
                         call_613907.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613907, url, valid)

proc call*(call_613908: Call_GetClassifier_613895; body: JsonNode): Recallable =
  ## getClassifier
  ## Retrieve a classifier by name.
  ##   body: JObject (required)
  var body_613909 = newJObject()
  if body != nil:
    body_613909 = body
  result = call_613908.call(nil, nil, nil, nil, body_613909)

var getClassifier* = Call_GetClassifier_613895(name: "getClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetClassifier",
    validator: validate_GetClassifier_613896, base: "/", url: url_GetClassifier_613897,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClassifiers_613910 = ref object of OpenApiRestCall_612658
proc url_GetClassifiers_613912(protocol: Scheme; host: string; base: string;
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

proc validate_GetClassifiers_613911(path: JsonNode; query: JsonNode;
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
  var valid_613913 = query.getOrDefault("MaxResults")
  valid_613913 = validateParameter(valid_613913, JString, required = false,
                                 default = nil)
  if valid_613913 != nil:
    section.add "MaxResults", valid_613913
  var valid_613914 = query.getOrDefault("NextToken")
  valid_613914 = validateParameter(valid_613914, JString, required = false,
                                 default = nil)
  if valid_613914 != nil:
    section.add "NextToken", valid_613914
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
  var valid_613915 = header.getOrDefault("X-Amz-Target")
  valid_613915 = validateParameter(valid_613915, JString, required = true,
                                 default = newJString("AWSGlue.GetClassifiers"))
  if valid_613915 != nil:
    section.add "X-Amz-Target", valid_613915
  var valid_613916 = header.getOrDefault("X-Amz-Signature")
  valid_613916 = validateParameter(valid_613916, JString, required = false,
                                 default = nil)
  if valid_613916 != nil:
    section.add "X-Amz-Signature", valid_613916
  var valid_613917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613917 = validateParameter(valid_613917, JString, required = false,
                                 default = nil)
  if valid_613917 != nil:
    section.add "X-Amz-Content-Sha256", valid_613917
  var valid_613918 = header.getOrDefault("X-Amz-Date")
  valid_613918 = validateParameter(valid_613918, JString, required = false,
                                 default = nil)
  if valid_613918 != nil:
    section.add "X-Amz-Date", valid_613918
  var valid_613919 = header.getOrDefault("X-Amz-Credential")
  valid_613919 = validateParameter(valid_613919, JString, required = false,
                                 default = nil)
  if valid_613919 != nil:
    section.add "X-Amz-Credential", valid_613919
  var valid_613920 = header.getOrDefault("X-Amz-Security-Token")
  valid_613920 = validateParameter(valid_613920, JString, required = false,
                                 default = nil)
  if valid_613920 != nil:
    section.add "X-Amz-Security-Token", valid_613920
  var valid_613921 = header.getOrDefault("X-Amz-Algorithm")
  valid_613921 = validateParameter(valid_613921, JString, required = false,
                                 default = nil)
  if valid_613921 != nil:
    section.add "X-Amz-Algorithm", valid_613921
  var valid_613922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613922 = validateParameter(valid_613922, JString, required = false,
                                 default = nil)
  if valid_613922 != nil:
    section.add "X-Amz-SignedHeaders", valid_613922
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613924: Call_GetClassifiers_613910; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all classifier objects in the Data Catalog.
  ## 
  let valid = call_613924.validator(path, query, header, formData, body)
  let scheme = call_613924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613924.url(scheme.get, call_613924.host, call_613924.base,
                         call_613924.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613924, url, valid)

proc call*(call_613925: Call_GetClassifiers_613910; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getClassifiers
  ## Lists all classifier objects in the Data Catalog.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613926 = newJObject()
  var body_613927 = newJObject()
  add(query_613926, "MaxResults", newJString(MaxResults))
  add(query_613926, "NextToken", newJString(NextToken))
  if body != nil:
    body_613927 = body
  result = call_613925.call(nil, query_613926, nil, nil, body_613927)

var getClassifiers* = Call_GetClassifiers_613910(name: "getClassifiers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetClassifiers",
    validator: validate_GetClassifiers_613911, base: "/", url: url_GetClassifiers_613912,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnection_613929 = ref object of OpenApiRestCall_612658
proc url_GetConnection_613931(protocol: Scheme; host: string; base: string;
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

proc validate_GetConnection_613930(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613932 = header.getOrDefault("X-Amz-Target")
  valid_613932 = validateParameter(valid_613932, JString, required = true,
                                 default = newJString("AWSGlue.GetConnection"))
  if valid_613932 != nil:
    section.add "X-Amz-Target", valid_613932
  var valid_613933 = header.getOrDefault("X-Amz-Signature")
  valid_613933 = validateParameter(valid_613933, JString, required = false,
                                 default = nil)
  if valid_613933 != nil:
    section.add "X-Amz-Signature", valid_613933
  var valid_613934 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613934 = validateParameter(valid_613934, JString, required = false,
                                 default = nil)
  if valid_613934 != nil:
    section.add "X-Amz-Content-Sha256", valid_613934
  var valid_613935 = header.getOrDefault("X-Amz-Date")
  valid_613935 = validateParameter(valid_613935, JString, required = false,
                                 default = nil)
  if valid_613935 != nil:
    section.add "X-Amz-Date", valid_613935
  var valid_613936 = header.getOrDefault("X-Amz-Credential")
  valid_613936 = validateParameter(valid_613936, JString, required = false,
                                 default = nil)
  if valid_613936 != nil:
    section.add "X-Amz-Credential", valid_613936
  var valid_613937 = header.getOrDefault("X-Amz-Security-Token")
  valid_613937 = validateParameter(valid_613937, JString, required = false,
                                 default = nil)
  if valid_613937 != nil:
    section.add "X-Amz-Security-Token", valid_613937
  var valid_613938 = header.getOrDefault("X-Amz-Algorithm")
  valid_613938 = validateParameter(valid_613938, JString, required = false,
                                 default = nil)
  if valid_613938 != nil:
    section.add "X-Amz-Algorithm", valid_613938
  var valid_613939 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613939 = validateParameter(valid_613939, JString, required = false,
                                 default = nil)
  if valid_613939 != nil:
    section.add "X-Amz-SignedHeaders", valid_613939
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613941: Call_GetConnection_613929; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a connection definition from the Data Catalog.
  ## 
  let valid = call_613941.validator(path, query, header, formData, body)
  let scheme = call_613941.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613941.url(scheme.get, call_613941.host, call_613941.base,
                         call_613941.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613941, url, valid)

proc call*(call_613942: Call_GetConnection_613929; body: JsonNode): Recallable =
  ## getConnection
  ## Retrieves a connection definition from the Data Catalog.
  ##   body: JObject (required)
  var body_613943 = newJObject()
  if body != nil:
    body_613943 = body
  result = call_613942.call(nil, nil, nil, nil, body_613943)

var getConnection* = Call_GetConnection_613929(name: "getConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetConnection",
    validator: validate_GetConnection_613930, base: "/", url: url_GetConnection_613931,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnections_613944 = ref object of OpenApiRestCall_612658
proc url_GetConnections_613946(protocol: Scheme; host: string; base: string;
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

proc validate_GetConnections_613945(path: JsonNode; query: JsonNode;
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
  var valid_613947 = query.getOrDefault("MaxResults")
  valid_613947 = validateParameter(valid_613947, JString, required = false,
                                 default = nil)
  if valid_613947 != nil:
    section.add "MaxResults", valid_613947
  var valid_613948 = query.getOrDefault("NextToken")
  valid_613948 = validateParameter(valid_613948, JString, required = false,
                                 default = nil)
  if valid_613948 != nil:
    section.add "NextToken", valid_613948
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
  var valid_613949 = header.getOrDefault("X-Amz-Target")
  valid_613949 = validateParameter(valid_613949, JString, required = true,
                                 default = newJString("AWSGlue.GetConnections"))
  if valid_613949 != nil:
    section.add "X-Amz-Target", valid_613949
  var valid_613950 = header.getOrDefault("X-Amz-Signature")
  valid_613950 = validateParameter(valid_613950, JString, required = false,
                                 default = nil)
  if valid_613950 != nil:
    section.add "X-Amz-Signature", valid_613950
  var valid_613951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613951 = validateParameter(valid_613951, JString, required = false,
                                 default = nil)
  if valid_613951 != nil:
    section.add "X-Amz-Content-Sha256", valid_613951
  var valid_613952 = header.getOrDefault("X-Amz-Date")
  valid_613952 = validateParameter(valid_613952, JString, required = false,
                                 default = nil)
  if valid_613952 != nil:
    section.add "X-Amz-Date", valid_613952
  var valid_613953 = header.getOrDefault("X-Amz-Credential")
  valid_613953 = validateParameter(valid_613953, JString, required = false,
                                 default = nil)
  if valid_613953 != nil:
    section.add "X-Amz-Credential", valid_613953
  var valid_613954 = header.getOrDefault("X-Amz-Security-Token")
  valid_613954 = validateParameter(valid_613954, JString, required = false,
                                 default = nil)
  if valid_613954 != nil:
    section.add "X-Amz-Security-Token", valid_613954
  var valid_613955 = header.getOrDefault("X-Amz-Algorithm")
  valid_613955 = validateParameter(valid_613955, JString, required = false,
                                 default = nil)
  if valid_613955 != nil:
    section.add "X-Amz-Algorithm", valid_613955
  var valid_613956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613956 = validateParameter(valid_613956, JString, required = false,
                                 default = nil)
  if valid_613956 != nil:
    section.add "X-Amz-SignedHeaders", valid_613956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613958: Call_GetConnections_613944; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of connection definitions from the Data Catalog.
  ## 
  let valid = call_613958.validator(path, query, header, formData, body)
  let scheme = call_613958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613958.url(scheme.get, call_613958.host, call_613958.base,
                         call_613958.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613958, url, valid)

proc call*(call_613959: Call_GetConnections_613944; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getConnections
  ## Retrieves a list of connection definitions from the Data Catalog.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613960 = newJObject()
  var body_613961 = newJObject()
  add(query_613960, "MaxResults", newJString(MaxResults))
  add(query_613960, "NextToken", newJString(NextToken))
  if body != nil:
    body_613961 = body
  result = call_613959.call(nil, query_613960, nil, nil, body_613961)

var getConnections* = Call_GetConnections_613944(name: "getConnections",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetConnections",
    validator: validate_GetConnections_613945, base: "/", url: url_GetConnections_613946,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawler_613962 = ref object of OpenApiRestCall_612658
proc url_GetCrawler_613964(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetCrawler_613963(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613965 = header.getOrDefault("X-Amz-Target")
  valid_613965 = validateParameter(valid_613965, JString, required = true,
                                 default = newJString("AWSGlue.GetCrawler"))
  if valid_613965 != nil:
    section.add "X-Amz-Target", valid_613965
  var valid_613966 = header.getOrDefault("X-Amz-Signature")
  valid_613966 = validateParameter(valid_613966, JString, required = false,
                                 default = nil)
  if valid_613966 != nil:
    section.add "X-Amz-Signature", valid_613966
  var valid_613967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613967 = validateParameter(valid_613967, JString, required = false,
                                 default = nil)
  if valid_613967 != nil:
    section.add "X-Amz-Content-Sha256", valid_613967
  var valid_613968 = header.getOrDefault("X-Amz-Date")
  valid_613968 = validateParameter(valid_613968, JString, required = false,
                                 default = nil)
  if valid_613968 != nil:
    section.add "X-Amz-Date", valid_613968
  var valid_613969 = header.getOrDefault("X-Amz-Credential")
  valid_613969 = validateParameter(valid_613969, JString, required = false,
                                 default = nil)
  if valid_613969 != nil:
    section.add "X-Amz-Credential", valid_613969
  var valid_613970 = header.getOrDefault("X-Amz-Security-Token")
  valid_613970 = validateParameter(valid_613970, JString, required = false,
                                 default = nil)
  if valid_613970 != nil:
    section.add "X-Amz-Security-Token", valid_613970
  var valid_613971 = header.getOrDefault("X-Amz-Algorithm")
  valid_613971 = validateParameter(valid_613971, JString, required = false,
                                 default = nil)
  if valid_613971 != nil:
    section.add "X-Amz-Algorithm", valid_613971
  var valid_613972 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613972 = validateParameter(valid_613972, JString, required = false,
                                 default = nil)
  if valid_613972 != nil:
    section.add "X-Amz-SignedHeaders", valid_613972
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613974: Call_GetCrawler_613962; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for a specified crawler.
  ## 
  let valid = call_613974.validator(path, query, header, formData, body)
  let scheme = call_613974.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613974.url(scheme.get, call_613974.host, call_613974.base,
                         call_613974.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613974, url, valid)

proc call*(call_613975: Call_GetCrawler_613962; body: JsonNode): Recallable =
  ## getCrawler
  ## Retrieves metadata for a specified crawler.
  ##   body: JObject (required)
  var body_613976 = newJObject()
  if body != nil:
    body_613976 = body
  result = call_613975.call(nil, nil, nil, nil, body_613976)

var getCrawler* = Call_GetCrawler_613962(name: "getCrawler",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetCrawler",
                                      validator: validate_GetCrawler_613963,
                                      base: "/", url: url_GetCrawler_613964,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawlerMetrics_613977 = ref object of OpenApiRestCall_612658
proc url_GetCrawlerMetrics_613979(protocol: Scheme; host: string; base: string;
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

proc validate_GetCrawlerMetrics_613978(path: JsonNode; query: JsonNode;
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
  var valid_613980 = query.getOrDefault("MaxResults")
  valid_613980 = validateParameter(valid_613980, JString, required = false,
                                 default = nil)
  if valid_613980 != nil:
    section.add "MaxResults", valid_613980
  var valid_613981 = query.getOrDefault("NextToken")
  valid_613981 = validateParameter(valid_613981, JString, required = false,
                                 default = nil)
  if valid_613981 != nil:
    section.add "NextToken", valid_613981
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
  var valid_613982 = header.getOrDefault("X-Amz-Target")
  valid_613982 = validateParameter(valid_613982, JString, required = true, default = newJString(
      "AWSGlue.GetCrawlerMetrics"))
  if valid_613982 != nil:
    section.add "X-Amz-Target", valid_613982
  var valid_613983 = header.getOrDefault("X-Amz-Signature")
  valid_613983 = validateParameter(valid_613983, JString, required = false,
                                 default = nil)
  if valid_613983 != nil:
    section.add "X-Amz-Signature", valid_613983
  var valid_613984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613984 = validateParameter(valid_613984, JString, required = false,
                                 default = nil)
  if valid_613984 != nil:
    section.add "X-Amz-Content-Sha256", valid_613984
  var valid_613985 = header.getOrDefault("X-Amz-Date")
  valid_613985 = validateParameter(valid_613985, JString, required = false,
                                 default = nil)
  if valid_613985 != nil:
    section.add "X-Amz-Date", valid_613985
  var valid_613986 = header.getOrDefault("X-Amz-Credential")
  valid_613986 = validateParameter(valid_613986, JString, required = false,
                                 default = nil)
  if valid_613986 != nil:
    section.add "X-Amz-Credential", valid_613986
  var valid_613987 = header.getOrDefault("X-Amz-Security-Token")
  valid_613987 = validateParameter(valid_613987, JString, required = false,
                                 default = nil)
  if valid_613987 != nil:
    section.add "X-Amz-Security-Token", valid_613987
  var valid_613988 = header.getOrDefault("X-Amz-Algorithm")
  valid_613988 = validateParameter(valid_613988, JString, required = false,
                                 default = nil)
  if valid_613988 != nil:
    section.add "X-Amz-Algorithm", valid_613988
  var valid_613989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613989 = validateParameter(valid_613989, JString, required = false,
                                 default = nil)
  if valid_613989 != nil:
    section.add "X-Amz-SignedHeaders", valid_613989
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613991: Call_GetCrawlerMetrics_613977; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metrics about specified crawlers.
  ## 
  let valid = call_613991.validator(path, query, header, formData, body)
  let scheme = call_613991.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613991.url(scheme.get, call_613991.host, call_613991.base,
                         call_613991.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613991, url, valid)

proc call*(call_613992: Call_GetCrawlerMetrics_613977; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getCrawlerMetrics
  ## Retrieves metrics about specified crawlers.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613993 = newJObject()
  var body_613994 = newJObject()
  add(query_613993, "MaxResults", newJString(MaxResults))
  add(query_613993, "NextToken", newJString(NextToken))
  if body != nil:
    body_613994 = body
  result = call_613992.call(nil, query_613993, nil, nil, body_613994)

var getCrawlerMetrics* = Call_GetCrawlerMetrics_613977(name: "getCrawlerMetrics",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetCrawlerMetrics",
    validator: validate_GetCrawlerMetrics_613978, base: "/",
    url: url_GetCrawlerMetrics_613979, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawlers_613995 = ref object of OpenApiRestCall_612658
proc url_GetCrawlers_613997(protocol: Scheme; host: string; base: string;
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

proc validate_GetCrawlers_613996(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613998 = query.getOrDefault("MaxResults")
  valid_613998 = validateParameter(valid_613998, JString, required = false,
                                 default = nil)
  if valid_613998 != nil:
    section.add "MaxResults", valid_613998
  var valid_613999 = query.getOrDefault("NextToken")
  valid_613999 = validateParameter(valid_613999, JString, required = false,
                                 default = nil)
  if valid_613999 != nil:
    section.add "NextToken", valid_613999
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
  var valid_614000 = header.getOrDefault("X-Amz-Target")
  valid_614000 = validateParameter(valid_614000, JString, required = true,
                                 default = newJString("AWSGlue.GetCrawlers"))
  if valid_614000 != nil:
    section.add "X-Amz-Target", valid_614000
  var valid_614001 = header.getOrDefault("X-Amz-Signature")
  valid_614001 = validateParameter(valid_614001, JString, required = false,
                                 default = nil)
  if valid_614001 != nil:
    section.add "X-Amz-Signature", valid_614001
  var valid_614002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614002 = validateParameter(valid_614002, JString, required = false,
                                 default = nil)
  if valid_614002 != nil:
    section.add "X-Amz-Content-Sha256", valid_614002
  var valid_614003 = header.getOrDefault("X-Amz-Date")
  valid_614003 = validateParameter(valid_614003, JString, required = false,
                                 default = nil)
  if valid_614003 != nil:
    section.add "X-Amz-Date", valid_614003
  var valid_614004 = header.getOrDefault("X-Amz-Credential")
  valid_614004 = validateParameter(valid_614004, JString, required = false,
                                 default = nil)
  if valid_614004 != nil:
    section.add "X-Amz-Credential", valid_614004
  var valid_614005 = header.getOrDefault("X-Amz-Security-Token")
  valid_614005 = validateParameter(valid_614005, JString, required = false,
                                 default = nil)
  if valid_614005 != nil:
    section.add "X-Amz-Security-Token", valid_614005
  var valid_614006 = header.getOrDefault("X-Amz-Algorithm")
  valid_614006 = validateParameter(valid_614006, JString, required = false,
                                 default = nil)
  if valid_614006 != nil:
    section.add "X-Amz-Algorithm", valid_614006
  var valid_614007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614007 = validateParameter(valid_614007, JString, required = false,
                                 default = nil)
  if valid_614007 != nil:
    section.add "X-Amz-SignedHeaders", valid_614007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614009: Call_GetCrawlers_613995; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all crawlers defined in the customer account.
  ## 
  let valid = call_614009.validator(path, query, header, formData, body)
  let scheme = call_614009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614009.url(scheme.get, call_614009.host, call_614009.base,
                         call_614009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614009, url, valid)

proc call*(call_614010: Call_GetCrawlers_613995; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getCrawlers
  ## Retrieves metadata for all crawlers defined in the customer account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614011 = newJObject()
  var body_614012 = newJObject()
  add(query_614011, "MaxResults", newJString(MaxResults))
  add(query_614011, "NextToken", newJString(NextToken))
  if body != nil:
    body_614012 = body
  result = call_614010.call(nil, query_614011, nil, nil, body_614012)

var getCrawlers* = Call_GetCrawlers_613995(name: "getCrawlers",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetCrawlers",
                                        validator: validate_GetCrawlers_613996,
                                        base: "/", url: url_GetCrawlers_613997,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataCatalogEncryptionSettings_614013 = ref object of OpenApiRestCall_612658
proc url_GetDataCatalogEncryptionSettings_614015(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDataCatalogEncryptionSettings_614014(path: JsonNode;
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
  var valid_614016 = header.getOrDefault("X-Amz-Target")
  valid_614016 = validateParameter(valid_614016, JString, required = true, default = newJString(
      "AWSGlue.GetDataCatalogEncryptionSettings"))
  if valid_614016 != nil:
    section.add "X-Amz-Target", valid_614016
  var valid_614017 = header.getOrDefault("X-Amz-Signature")
  valid_614017 = validateParameter(valid_614017, JString, required = false,
                                 default = nil)
  if valid_614017 != nil:
    section.add "X-Amz-Signature", valid_614017
  var valid_614018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614018 = validateParameter(valid_614018, JString, required = false,
                                 default = nil)
  if valid_614018 != nil:
    section.add "X-Amz-Content-Sha256", valid_614018
  var valid_614019 = header.getOrDefault("X-Amz-Date")
  valid_614019 = validateParameter(valid_614019, JString, required = false,
                                 default = nil)
  if valid_614019 != nil:
    section.add "X-Amz-Date", valid_614019
  var valid_614020 = header.getOrDefault("X-Amz-Credential")
  valid_614020 = validateParameter(valid_614020, JString, required = false,
                                 default = nil)
  if valid_614020 != nil:
    section.add "X-Amz-Credential", valid_614020
  var valid_614021 = header.getOrDefault("X-Amz-Security-Token")
  valid_614021 = validateParameter(valid_614021, JString, required = false,
                                 default = nil)
  if valid_614021 != nil:
    section.add "X-Amz-Security-Token", valid_614021
  var valid_614022 = header.getOrDefault("X-Amz-Algorithm")
  valid_614022 = validateParameter(valid_614022, JString, required = false,
                                 default = nil)
  if valid_614022 != nil:
    section.add "X-Amz-Algorithm", valid_614022
  var valid_614023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614023 = validateParameter(valid_614023, JString, required = false,
                                 default = nil)
  if valid_614023 != nil:
    section.add "X-Amz-SignedHeaders", valid_614023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614025: Call_GetDataCatalogEncryptionSettings_614013;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the security configuration for a specified catalog.
  ## 
  let valid = call_614025.validator(path, query, header, formData, body)
  let scheme = call_614025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614025.url(scheme.get, call_614025.host, call_614025.base,
                         call_614025.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614025, url, valid)

proc call*(call_614026: Call_GetDataCatalogEncryptionSettings_614013;
          body: JsonNode): Recallable =
  ## getDataCatalogEncryptionSettings
  ## Retrieves the security configuration for a specified catalog.
  ##   body: JObject (required)
  var body_614027 = newJObject()
  if body != nil:
    body_614027 = body
  result = call_614026.call(nil, nil, nil, nil, body_614027)

var getDataCatalogEncryptionSettings* = Call_GetDataCatalogEncryptionSettings_614013(
    name: "getDataCatalogEncryptionSettings", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDataCatalogEncryptionSettings",
    validator: validate_GetDataCatalogEncryptionSettings_614014, base: "/",
    url: url_GetDataCatalogEncryptionSettings_614015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatabase_614028 = ref object of OpenApiRestCall_612658
proc url_GetDatabase_614030(protocol: Scheme; host: string; base: string;
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

proc validate_GetDatabase_614029(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614031 = header.getOrDefault("X-Amz-Target")
  valid_614031 = validateParameter(valid_614031, JString, required = true,
                                 default = newJString("AWSGlue.GetDatabase"))
  if valid_614031 != nil:
    section.add "X-Amz-Target", valid_614031
  var valid_614032 = header.getOrDefault("X-Amz-Signature")
  valid_614032 = validateParameter(valid_614032, JString, required = false,
                                 default = nil)
  if valid_614032 != nil:
    section.add "X-Amz-Signature", valid_614032
  var valid_614033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614033 = validateParameter(valid_614033, JString, required = false,
                                 default = nil)
  if valid_614033 != nil:
    section.add "X-Amz-Content-Sha256", valid_614033
  var valid_614034 = header.getOrDefault("X-Amz-Date")
  valid_614034 = validateParameter(valid_614034, JString, required = false,
                                 default = nil)
  if valid_614034 != nil:
    section.add "X-Amz-Date", valid_614034
  var valid_614035 = header.getOrDefault("X-Amz-Credential")
  valid_614035 = validateParameter(valid_614035, JString, required = false,
                                 default = nil)
  if valid_614035 != nil:
    section.add "X-Amz-Credential", valid_614035
  var valid_614036 = header.getOrDefault("X-Amz-Security-Token")
  valid_614036 = validateParameter(valid_614036, JString, required = false,
                                 default = nil)
  if valid_614036 != nil:
    section.add "X-Amz-Security-Token", valid_614036
  var valid_614037 = header.getOrDefault("X-Amz-Algorithm")
  valid_614037 = validateParameter(valid_614037, JString, required = false,
                                 default = nil)
  if valid_614037 != nil:
    section.add "X-Amz-Algorithm", valid_614037
  var valid_614038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614038 = validateParameter(valid_614038, JString, required = false,
                                 default = nil)
  if valid_614038 != nil:
    section.add "X-Amz-SignedHeaders", valid_614038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614040: Call_GetDatabase_614028; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definition of a specified database.
  ## 
  let valid = call_614040.validator(path, query, header, formData, body)
  let scheme = call_614040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614040.url(scheme.get, call_614040.host, call_614040.base,
                         call_614040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614040, url, valid)

proc call*(call_614041: Call_GetDatabase_614028; body: JsonNode): Recallable =
  ## getDatabase
  ## Retrieves the definition of a specified database.
  ##   body: JObject (required)
  var body_614042 = newJObject()
  if body != nil:
    body_614042 = body
  result = call_614041.call(nil, nil, nil, nil, body_614042)

var getDatabase* = Call_GetDatabase_614028(name: "getDatabase",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetDatabase",
                                        validator: validate_GetDatabase_614029,
                                        base: "/", url: url_GetDatabase_614030,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatabases_614043 = ref object of OpenApiRestCall_612658
proc url_GetDatabases_614045(protocol: Scheme; host: string; base: string;
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

proc validate_GetDatabases_614044(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614046 = query.getOrDefault("MaxResults")
  valid_614046 = validateParameter(valid_614046, JString, required = false,
                                 default = nil)
  if valid_614046 != nil:
    section.add "MaxResults", valid_614046
  var valid_614047 = query.getOrDefault("NextToken")
  valid_614047 = validateParameter(valid_614047, JString, required = false,
                                 default = nil)
  if valid_614047 != nil:
    section.add "NextToken", valid_614047
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
  var valid_614048 = header.getOrDefault("X-Amz-Target")
  valid_614048 = validateParameter(valid_614048, JString, required = true,
                                 default = newJString("AWSGlue.GetDatabases"))
  if valid_614048 != nil:
    section.add "X-Amz-Target", valid_614048
  var valid_614049 = header.getOrDefault("X-Amz-Signature")
  valid_614049 = validateParameter(valid_614049, JString, required = false,
                                 default = nil)
  if valid_614049 != nil:
    section.add "X-Amz-Signature", valid_614049
  var valid_614050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614050 = validateParameter(valid_614050, JString, required = false,
                                 default = nil)
  if valid_614050 != nil:
    section.add "X-Amz-Content-Sha256", valid_614050
  var valid_614051 = header.getOrDefault("X-Amz-Date")
  valid_614051 = validateParameter(valid_614051, JString, required = false,
                                 default = nil)
  if valid_614051 != nil:
    section.add "X-Amz-Date", valid_614051
  var valid_614052 = header.getOrDefault("X-Amz-Credential")
  valid_614052 = validateParameter(valid_614052, JString, required = false,
                                 default = nil)
  if valid_614052 != nil:
    section.add "X-Amz-Credential", valid_614052
  var valid_614053 = header.getOrDefault("X-Amz-Security-Token")
  valid_614053 = validateParameter(valid_614053, JString, required = false,
                                 default = nil)
  if valid_614053 != nil:
    section.add "X-Amz-Security-Token", valid_614053
  var valid_614054 = header.getOrDefault("X-Amz-Algorithm")
  valid_614054 = validateParameter(valid_614054, JString, required = false,
                                 default = nil)
  if valid_614054 != nil:
    section.add "X-Amz-Algorithm", valid_614054
  var valid_614055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614055 = validateParameter(valid_614055, JString, required = false,
                                 default = nil)
  if valid_614055 != nil:
    section.add "X-Amz-SignedHeaders", valid_614055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614057: Call_GetDatabases_614043; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all databases defined in a given Data Catalog.
  ## 
  let valid = call_614057.validator(path, query, header, formData, body)
  let scheme = call_614057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614057.url(scheme.get, call_614057.host, call_614057.base,
                         call_614057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614057, url, valid)

proc call*(call_614058: Call_GetDatabases_614043; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getDatabases
  ## Retrieves all databases defined in a given Data Catalog.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614059 = newJObject()
  var body_614060 = newJObject()
  add(query_614059, "MaxResults", newJString(MaxResults))
  add(query_614059, "NextToken", newJString(NextToken))
  if body != nil:
    body_614060 = body
  result = call_614058.call(nil, query_614059, nil, nil, body_614060)

var getDatabases* = Call_GetDatabases_614043(name: "getDatabases",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDatabases",
    validator: validate_GetDatabases_614044, base: "/", url: url_GetDatabases_614045,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataflowGraph_614061 = ref object of OpenApiRestCall_612658
proc url_GetDataflowGraph_614063(protocol: Scheme; host: string; base: string;
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

proc validate_GetDataflowGraph_614062(path: JsonNode; query: JsonNode;
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
  var valid_614064 = header.getOrDefault("X-Amz-Target")
  valid_614064 = validateParameter(valid_614064, JString, required = true, default = newJString(
      "AWSGlue.GetDataflowGraph"))
  if valid_614064 != nil:
    section.add "X-Amz-Target", valid_614064
  var valid_614065 = header.getOrDefault("X-Amz-Signature")
  valid_614065 = validateParameter(valid_614065, JString, required = false,
                                 default = nil)
  if valid_614065 != nil:
    section.add "X-Amz-Signature", valid_614065
  var valid_614066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614066 = validateParameter(valid_614066, JString, required = false,
                                 default = nil)
  if valid_614066 != nil:
    section.add "X-Amz-Content-Sha256", valid_614066
  var valid_614067 = header.getOrDefault("X-Amz-Date")
  valid_614067 = validateParameter(valid_614067, JString, required = false,
                                 default = nil)
  if valid_614067 != nil:
    section.add "X-Amz-Date", valid_614067
  var valid_614068 = header.getOrDefault("X-Amz-Credential")
  valid_614068 = validateParameter(valid_614068, JString, required = false,
                                 default = nil)
  if valid_614068 != nil:
    section.add "X-Amz-Credential", valid_614068
  var valid_614069 = header.getOrDefault("X-Amz-Security-Token")
  valid_614069 = validateParameter(valid_614069, JString, required = false,
                                 default = nil)
  if valid_614069 != nil:
    section.add "X-Amz-Security-Token", valid_614069
  var valid_614070 = header.getOrDefault("X-Amz-Algorithm")
  valid_614070 = validateParameter(valid_614070, JString, required = false,
                                 default = nil)
  if valid_614070 != nil:
    section.add "X-Amz-Algorithm", valid_614070
  var valid_614071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614071 = validateParameter(valid_614071, JString, required = false,
                                 default = nil)
  if valid_614071 != nil:
    section.add "X-Amz-SignedHeaders", valid_614071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614073: Call_GetDataflowGraph_614061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Transforms a Python script into a directed acyclic graph (DAG). 
  ## 
  let valid = call_614073.validator(path, query, header, formData, body)
  let scheme = call_614073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614073.url(scheme.get, call_614073.host, call_614073.base,
                         call_614073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614073, url, valid)

proc call*(call_614074: Call_GetDataflowGraph_614061; body: JsonNode): Recallable =
  ## getDataflowGraph
  ## Transforms a Python script into a directed acyclic graph (DAG). 
  ##   body: JObject (required)
  var body_614075 = newJObject()
  if body != nil:
    body_614075 = body
  result = call_614074.call(nil, nil, nil, nil, body_614075)

var getDataflowGraph* = Call_GetDataflowGraph_614061(name: "getDataflowGraph",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDataflowGraph",
    validator: validate_GetDataflowGraph_614062, base: "/",
    url: url_GetDataflowGraph_614063, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevEndpoint_614076 = ref object of OpenApiRestCall_612658
proc url_GetDevEndpoint_614078(protocol: Scheme; host: string; base: string;
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

proc validate_GetDevEndpoint_614077(path: JsonNode; query: JsonNode;
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
  var valid_614079 = header.getOrDefault("X-Amz-Target")
  valid_614079 = validateParameter(valid_614079, JString, required = true,
                                 default = newJString("AWSGlue.GetDevEndpoint"))
  if valid_614079 != nil:
    section.add "X-Amz-Target", valid_614079
  var valid_614080 = header.getOrDefault("X-Amz-Signature")
  valid_614080 = validateParameter(valid_614080, JString, required = false,
                                 default = nil)
  if valid_614080 != nil:
    section.add "X-Amz-Signature", valid_614080
  var valid_614081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614081 = validateParameter(valid_614081, JString, required = false,
                                 default = nil)
  if valid_614081 != nil:
    section.add "X-Amz-Content-Sha256", valid_614081
  var valid_614082 = header.getOrDefault("X-Amz-Date")
  valid_614082 = validateParameter(valid_614082, JString, required = false,
                                 default = nil)
  if valid_614082 != nil:
    section.add "X-Amz-Date", valid_614082
  var valid_614083 = header.getOrDefault("X-Amz-Credential")
  valid_614083 = validateParameter(valid_614083, JString, required = false,
                                 default = nil)
  if valid_614083 != nil:
    section.add "X-Amz-Credential", valid_614083
  var valid_614084 = header.getOrDefault("X-Amz-Security-Token")
  valid_614084 = validateParameter(valid_614084, JString, required = false,
                                 default = nil)
  if valid_614084 != nil:
    section.add "X-Amz-Security-Token", valid_614084
  var valid_614085 = header.getOrDefault("X-Amz-Algorithm")
  valid_614085 = validateParameter(valid_614085, JString, required = false,
                                 default = nil)
  if valid_614085 != nil:
    section.add "X-Amz-Algorithm", valid_614085
  var valid_614086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614086 = validateParameter(valid_614086, JString, required = false,
                                 default = nil)
  if valid_614086 != nil:
    section.add "X-Amz-SignedHeaders", valid_614086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614088: Call_GetDevEndpoint_614076; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ## 
  let valid = call_614088.validator(path, query, header, formData, body)
  let scheme = call_614088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614088.url(scheme.get, call_614088.host, call_614088.base,
                         call_614088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614088, url, valid)

proc call*(call_614089: Call_GetDevEndpoint_614076; body: JsonNode): Recallable =
  ## getDevEndpoint
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ##   body: JObject (required)
  var body_614090 = newJObject()
  if body != nil:
    body_614090 = body
  result = call_614089.call(nil, nil, nil, nil, body_614090)

var getDevEndpoint* = Call_GetDevEndpoint_614076(name: "getDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDevEndpoint",
    validator: validate_GetDevEndpoint_614077, base: "/", url: url_GetDevEndpoint_614078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevEndpoints_614091 = ref object of OpenApiRestCall_612658
proc url_GetDevEndpoints_614093(protocol: Scheme; host: string; base: string;
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

proc validate_GetDevEndpoints_614092(path: JsonNode; query: JsonNode;
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
  var valid_614094 = query.getOrDefault("MaxResults")
  valid_614094 = validateParameter(valid_614094, JString, required = false,
                                 default = nil)
  if valid_614094 != nil:
    section.add "MaxResults", valid_614094
  var valid_614095 = query.getOrDefault("NextToken")
  valid_614095 = validateParameter(valid_614095, JString, required = false,
                                 default = nil)
  if valid_614095 != nil:
    section.add "NextToken", valid_614095
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
  var valid_614096 = header.getOrDefault("X-Amz-Target")
  valid_614096 = validateParameter(valid_614096, JString, required = true, default = newJString(
      "AWSGlue.GetDevEndpoints"))
  if valid_614096 != nil:
    section.add "X-Amz-Target", valid_614096
  var valid_614097 = header.getOrDefault("X-Amz-Signature")
  valid_614097 = validateParameter(valid_614097, JString, required = false,
                                 default = nil)
  if valid_614097 != nil:
    section.add "X-Amz-Signature", valid_614097
  var valid_614098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614098 = validateParameter(valid_614098, JString, required = false,
                                 default = nil)
  if valid_614098 != nil:
    section.add "X-Amz-Content-Sha256", valid_614098
  var valid_614099 = header.getOrDefault("X-Amz-Date")
  valid_614099 = validateParameter(valid_614099, JString, required = false,
                                 default = nil)
  if valid_614099 != nil:
    section.add "X-Amz-Date", valid_614099
  var valid_614100 = header.getOrDefault("X-Amz-Credential")
  valid_614100 = validateParameter(valid_614100, JString, required = false,
                                 default = nil)
  if valid_614100 != nil:
    section.add "X-Amz-Credential", valid_614100
  var valid_614101 = header.getOrDefault("X-Amz-Security-Token")
  valid_614101 = validateParameter(valid_614101, JString, required = false,
                                 default = nil)
  if valid_614101 != nil:
    section.add "X-Amz-Security-Token", valid_614101
  var valid_614102 = header.getOrDefault("X-Amz-Algorithm")
  valid_614102 = validateParameter(valid_614102, JString, required = false,
                                 default = nil)
  if valid_614102 != nil:
    section.add "X-Amz-Algorithm", valid_614102
  var valid_614103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614103 = validateParameter(valid_614103, JString, required = false,
                                 default = nil)
  if valid_614103 != nil:
    section.add "X-Amz-SignedHeaders", valid_614103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614105: Call_GetDevEndpoints_614091; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ## 
  let valid = call_614105.validator(path, query, header, formData, body)
  let scheme = call_614105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614105.url(scheme.get, call_614105.host, call_614105.base,
                         call_614105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614105, url, valid)

proc call*(call_614106: Call_GetDevEndpoints_614091; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getDevEndpoints
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614107 = newJObject()
  var body_614108 = newJObject()
  add(query_614107, "MaxResults", newJString(MaxResults))
  add(query_614107, "NextToken", newJString(NextToken))
  if body != nil:
    body_614108 = body
  result = call_614106.call(nil, query_614107, nil, nil, body_614108)

var getDevEndpoints* = Call_GetDevEndpoints_614091(name: "getDevEndpoints",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDevEndpoints",
    validator: validate_GetDevEndpoints_614092, base: "/", url: url_GetDevEndpoints_614093,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_614109 = ref object of OpenApiRestCall_612658
proc url_GetJob_614111(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetJob_614110(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614112 = header.getOrDefault("X-Amz-Target")
  valid_614112 = validateParameter(valid_614112, JString, required = true,
                                 default = newJString("AWSGlue.GetJob"))
  if valid_614112 != nil:
    section.add "X-Amz-Target", valid_614112
  var valid_614113 = header.getOrDefault("X-Amz-Signature")
  valid_614113 = validateParameter(valid_614113, JString, required = false,
                                 default = nil)
  if valid_614113 != nil:
    section.add "X-Amz-Signature", valid_614113
  var valid_614114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614114 = validateParameter(valid_614114, JString, required = false,
                                 default = nil)
  if valid_614114 != nil:
    section.add "X-Amz-Content-Sha256", valid_614114
  var valid_614115 = header.getOrDefault("X-Amz-Date")
  valid_614115 = validateParameter(valid_614115, JString, required = false,
                                 default = nil)
  if valid_614115 != nil:
    section.add "X-Amz-Date", valid_614115
  var valid_614116 = header.getOrDefault("X-Amz-Credential")
  valid_614116 = validateParameter(valid_614116, JString, required = false,
                                 default = nil)
  if valid_614116 != nil:
    section.add "X-Amz-Credential", valid_614116
  var valid_614117 = header.getOrDefault("X-Amz-Security-Token")
  valid_614117 = validateParameter(valid_614117, JString, required = false,
                                 default = nil)
  if valid_614117 != nil:
    section.add "X-Amz-Security-Token", valid_614117
  var valid_614118 = header.getOrDefault("X-Amz-Algorithm")
  valid_614118 = validateParameter(valid_614118, JString, required = false,
                                 default = nil)
  if valid_614118 != nil:
    section.add "X-Amz-Algorithm", valid_614118
  var valid_614119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614119 = validateParameter(valid_614119, JString, required = false,
                                 default = nil)
  if valid_614119 != nil:
    section.add "X-Amz-SignedHeaders", valid_614119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614121: Call_GetJob_614109; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an existing job definition.
  ## 
  let valid = call_614121.validator(path, query, header, formData, body)
  let scheme = call_614121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614121.url(scheme.get, call_614121.host, call_614121.base,
                         call_614121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614121, url, valid)

proc call*(call_614122: Call_GetJob_614109; body: JsonNode): Recallable =
  ## getJob
  ## Retrieves an existing job definition.
  ##   body: JObject (required)
  var body_614123 = newJObject()
  if body != nil:
    body_614123 = body
  result = call_614122.call(nil, nil, nil, nil, body_614123)

var getJob* = Call_GetJob_614109(name: "getJob", meth: HttpMethod.HttpPost,
                              host: "glue.amazonaws.com",
                              route: "/#X-Amz-Target=AWSGlue.GetJob",
                              validator: validate_GetJob_614110, base: "/",
                              url: url_GetJob_614111,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobBookmark_614124 = ref object of OpenApiRestCall_612658
proc url_GetJobBookmark_614126(protocol: Scheme; host: string; base: string;
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

proc validate_GetJobBookmark_614125(path: JsonNode; query: JsonNode;
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
  var valid_614127 = header.getOrDefault("X-Amz-Target")
  valid_614127 = validateParameter(valid_614127, JString, required = true,
                                 default = newJString("AWSGlue.GetJobBookmark"))
  if valid_614127 != nil:
    section.add "X-Amz-Target", valid_614127
  var valid_614128 = header.getOrDefault("X-Amz-Signature")
  valid_614128 = validateParameter(valid_614128, JString, required = false,
                                 default = nil)
  if valid_614128 != nil:
    section.add "X-Amz-Signature", valid_614128
  var valid_614129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614129 = validateParameter(valid_614129, JString, required = false,
                                 default = nil)
  if valid_614129 != nil:
    section.add "X-Amz-Content-Sha256", valid_614129
  var valid_614130 = header.getOrDefault("X-Amz-Date")
  valid_614130 = validateParameter(valid_614130, JString, required = false,
                                 default = nil)
  if valid_614130 != nil:
    section.add "X-Amz-Date", valid_614130
  var valid_614131 = header.getOrDefault("X-Amz-Credential")
  valid_614131 = validateParameter(valid_614131, JString, required = false,
                                 default = nil)
  if valid_614131 != nil:
    section.add "X-Amz-Credential", valid_614131
  var valid_614132 = header.getOrDefault("X-Amz-Security-Token")
  valid_614132 = validateParameter(valid_614132, JString, required = false,
                                 default = nil)
  if valid_614132 != nil:
    section.add "X-Amz-Security-Token", valid_614132
  var valid_614133 = header.getOrDefault("X-Amz-Algorithm")
  valid_614133 = validateParameter(valid_614133, JString, required = false,
                                 default = nil)
  if valid_614133 != nil:
    section.add "X-Amz-Algorithm", valid_614133
  var valid_614134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614134 = validateParameter(valid_614134, JString, required = false,
                                 default = nil)
  if valid_614134 != nil:
    section.add "X-Amz-SignedHeaders", valid_614134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614136: Call_GetJobBookmark_614124; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information on a job bookmark entry.
  ## 
  let valid = call_614136.validator(path, query, header, formData, body)
  let scheme = call_614136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614136.url(scheme.get, call_614136.host, call_614136.base,
                         call_614136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614136, url, valid)

proc call*(call_614137: Call_GetJobBookmark_614124; body: JsonNode): Recallable =
  ## getJobBookmark
  ## Returns information on a job bookmark entry.
  ##   body: JObject (required)
  var body_614138 = newJObject()
  if body != nil:
    body_614138 = body
  result = call_614137.call(nil, nil, nil, nil, body_614138)

var getJobBookmark* = Call_GetJobBookmark_614124(name: "getJobBookmark",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetJobBookmark",
    validator: validate_GetJobBookmark_614125, base: "/", url: url_GetJobBookmark_614126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobRun_614139 = ref object of OpenApiRestCall_612658
proc url_GetJobRun_614141(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetJobRun_614140(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614142 = header.getOrDefault("X-Amz-Target")
  valid_614142 = validateParameter(valid_614142, JString, required = true,
                                 default = newJString("AWSGlue.GetJobRun"))
  if valid_614142 != nil:
    section.add "X-Amz-Target", valid_614142
  var valid_614143 = header.getOrDefault("X-Amz-Signature")
  valid_614143 = validateParameter(valid_614143, JString, required = false,
                                 default = nil)
  if valid_614143 != nil:
    section.add "X-Amz-Signature", valid_614143
  var valid_614144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614144 = validateParameter(valid_614144, JString, required = false,
                                 default = nil)
  if valid_614144 != nil:
    section.add "X-Amz-Content-Sha256", valid_614144
  var valid_614145 = header.getOrDefault("X-Amz-Date")
  valid_614145 = validateParameter(valid_614145, JString, required = false,
                                 default = nil)
  if valid_614145 != nil:
    section.add "X-Amz-Date", valid_614145
  var valid_614146 = header.getOrDefault("X-Amz-Credential")
  valid_614146 = validateParameter(valid_614146, JString, required = false,
                                 default = nil)
  if valid_614146 != nil:
    section.add "X-Amz-Credential", valid_614146
  var valid_614147 = header.getOrDefault("X-Amz-Security-Token")
  valid_614147 = validateParameter(valid_614147, JString, required = false,
                                 default = nil)
  if valid_614147 != nil:
    section.add "X-Amz-Security-Token", valid_614147
  var valid_614148 = header.getOrDefault("X-Amz-Algorithm")
  valid_614148 = validateParameter(valid_614148, JString, required = false,
                                 default = nil)
  if valid_614148 != nil:
    section.add "X-Amz-Algorithm", valid_614148
  var valid_614149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614149 = validateParameter(valid_614149, JString, required = false,
                                 default = nil)
  if valid_614149 != nil:
    section.add "X-Amz-SignedHeaders", valid_614149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614151: Call_GetJobRun_614139; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the metadata for a given job run.
  ## 
  let valid = call_614151.validator(path, query, header, formData, body)
  let scheme = call_614151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614151.url(scheme.get, call_614151.host, call_614151.base,
                         call_614151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614151, url, valid)

proc call*(call_614152: Call_GetJobRun_614139; body: JsonNode): Recallable =
  ## getJobRun
  ## Retrieves the metadata for a given job run.
  ##   body: JObject (required)
  var body_614153 = newJObject()
  if body != nil:
    body_614153 = body
  result = call_614152.call(nil, nil, nil, nil, body_614153)

var getJobRun* = Call_GetJobRun_614139(name: "getJobRun", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.GetJobRun",
                                    validator: validate_GetJobRun_614140,
                                    base: "/", url: url_GetJobRun_614141,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobRuns_614154 = ref object of OpenApiRestCall_612658
proc url_GetJobRuns_614156(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetJobRuns_614155(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614157 = query.getOrDefault("MaxResults")
  valid_614157 = validateParameter(valid_614157, JString, required = false,
                                 default = nil)
  if valid_614157 != nil:
    section.add "MaxResults", valid_614157
  var valid_614158 = query.getOrDefault("NextToken")
  valid_614158 = validateParameter(valid_614158, JString, required = false,
                                 default = nil)
  if valid_614158 != nil:
    section.add "NextToken", valid_614158
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
  var valid_614159 = header.getOrDefault("X-Amz-Target")
  valid_614159 = validateParameter(valid_614159, JString, required = true,
                                 default = newJString("AWSGlue.GetJobRuns"))
  if valid_614159 != nil:
    section.add "X-Amz-Target", valid_614159
  var valid_614160 = header.getOrDefault("X-Amz-Signature")
  valid_614160 = validateParameter(valid_614160, JString, required = false,
                                 default = nil)
  if valid_614160 != nil:
    section.add "X-Amz-Signature", valid_614160
  var valid_614161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614161 = validateParameter(valid_614161, JString, required = false,
                                 default = nil)
  if valid_614161 != nil:
    section.add "X-Amz-Content-Sha256", valid_614161
  var valid_614162 = header.getOrDefault("X-Amz-Date")
  valid_614162 = validateParameter(valid_614162, JString, required = false,
                                 default = nil)
  if valid_614162 != nil:
    section.add "X-Amz-Date", valid_614162
  var valid_614163 = header.getOrDefault("X-Amz-Credential")
  valid_614163 = validateParameter(valid_614163, JString, required = false,
                                 default = nil)
  if valid_614163 != nil:
    section.add "X-Amz-Credential", valid_614163
  var valid_614164 = header.getOrDefault("X-Amz-Security-Token")
  valid_614164 = validateParameter(valid_614164, JString, required = false,
                                 default = nil)
  if valid_614164 != nil:
    section.add "X-Amz-Security-Token", valid_614164
  var valid_614165 = header.getOrDefault("X-Amz-Algorithm")
  valid_614165 = validateParameter(valid_614165, JString, required = false,
                                 default = nil)
  if valid_614165 != nil:
    section.add "X-Amz-Algorithm", valid_614165
  var valid_614166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614166 = validateParameter(valid_614166, JString, required = false,
                                 default = nil)
  if valid_614166 != nil:
    section.add "X-Amz-SignedHeaders", valid_614166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614168: Call_GetJobRuns_614154; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all runs of a given job definition.
  ## 
  let valid = call_614168.validator(path, query, header, formData, body)
  let scheme = call_614168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614168.url(scheme.get, call_614168.host, call_614168.base,
                         call_614168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614168, url, valid)

proc call*(call_614169: Call_GetJobRuns_614154; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getJobRuns
  ## Retrieves metadata for all runs of a given job definition.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614170 = newJObject()
  var body_614171 = newJObject()
  add(query_614170, "MaxResults", newJString(MaxResults))
  add(query_614170, "NextToken", newJString(NextToken))
  if body != nil:
    body_614171 = body
  result = call_614169.call(nil, query_614170, nil, nil, body_614171)

var getJobRuns* = Call_GetJobRuns_614154(name: "getJobRuns",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetJobRuns",
                                      validator: validate_GetJobRuns_614155,
                                      base: "/", url: url_GetJobRuns_614156,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobs_614172 = ref object of OpenApiRestCall_612658
proc url_GetJobs_614174(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetJobs_614173(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614175 = query.getOrDefault("MaxResults")
  valid_614175 = validateParameter(valid_614175, JString, required = false,
                                 default = nil)
  if valid_614175 != nil:
    section.add "MaxResults", valid_614175
  var valid_614176 = query.getOrDefault("NextToken")
  valid_614176 = validateParameter(valid_614176, JString, required = false,
                                 default = nil)
  if valid_614176 != nil:
    section.add "NextToken", valid_614176
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
  var valid_614177 = header.getOrDefault("X-Amz-Target")
  valid_614177 = validateParameter(valid_614177, JString, required = true,
                                 default = newJString("AWSGlue.GetJobs"))
  if valid_614177 != nil:
    section.add "X-Amz-Target", valid_614177
  var valid_614178 = header.getOrDefault("X-Amz-Signature")
  valid_614178 = validateParameter(valid_614178, JString, required = false,
                                 default = nil)
  if valid_614178 != nil:
    section.add "X-Amz-Signature", valid_614178
  var valid_614179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614179 = validateParameter(valid_614179, JString, required = false,
                                 default = nil)
  if valid_614179 != nil:
    section.add "X-Amz-Content-Sha256", valid_614179
  var valid_614180 = header.getOrDefault("X-Amz-Date")
  valid_614180 = validateParameter(valid_614180, JString, required = false,
                                 default = nil)
  if valid_614180 != nil:
    section.add "X-Amz-Date", valid_614180
  var valid_614181 = header.getOrDefault("X-Amz-Credential")
  valid_614181 = validateParameter(valid_614181, JString, required = false,
                                 default = nil)
  if valid_614181 != nil:
    section.add "X-Amz-Credential", valid_614181
  var valid_614182 = header.getOrDefault("X-Amz-Security-Token")
  valid_614182 = validateParameter(valid_614182, JString, required = false,
                                 default = nil)
  if valid_614182 != nil:
    section.add "X-Amz-Security-Token", valid_614182
  var valid_614183 = header.getOrDefault("X-Amz-Algorithm")
  valid_614183 = validateParameter(valid_614183, JString, required = false,
                                 default = nil)
  if valid_614183 != nil:
    section.add "X-Amz-Algorithm", valid_614183
  var valid_614184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614184 = validateParameter(valid_614184, JString, required = false,
                                 default = nil)
  if valid_614184 != nil:
    section.add "X-Amz-SignedHeaders", valid_614184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614186: Call_GetJobs_614172; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all current job definitions.
  ## 
  let valid = call_614186.validator(path, query, header, formData, body)
  let scheme = call_614186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614186.url(scheme.get, call_614186.host, call_614186.base,
                         call_614186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614186, url, valid)

proc call*(call_614187: Call_GetJobs_614172; body: JsonNode; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## getJobs
  ## Retrieves all current job definitions.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614188 = newJObject()
  var body_614189 = newJObject()
  add(query_614188, "MaxResults", newJString(MaxResults))
  add(query_614188, "NextToken", newJString(NextToken))
  if body != nil:
    body_614189 = body
  result = call_614187.call(nil, query_614188, nil, nil, body_614189)

var getJobs* = Call_GetJobs_614172(name: "getJobs", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetJobs",
                                validator: validate_GetJobs_614173, base: "/",
                                url: url_GetJobs_614174,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTaskRun_614190 = ref object of OpenApiRestCall_612658
proc url_GetMLTaskRun_614192(protocol: Scheme; host: string; base: string;
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

proc validate_GetMLTaskRun_614191(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614193 = header.getOrDefault("X-Amz-Target")
  valid_614193 = validateParameter(valid_614193, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTaskRun"))
  if valid_614193 != nil:
    section.add "X-Amz-Target", valid_614193
  var valid_614194 = header.getOrDefault("X-Amz-Signature")
  valid_614194 = validateParameter(valid_614194, JString, required = false,
                                 default = nil)
  if valid_614194 != nil:
    section.add "X-Amz-Signature", valid_614194
  var valid_614195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614195 = validateParameter(valid_614195, JString, required = false,
                                 default = nil)
  if valid_614195 != nil:
    section.add "X-Amz-Content-Sha256", valid_614195
  var valid_614196 = header.getOrDefault("X-Amz-Date")
  valid_614196 = validateParameter(valid_614196, JString, required = false,
                                 default = nil)
  if valid_614196 != nil:
    section.add "X-Amz-Date", valid_614196
  var valid_614197 = header.getOrDefault("X-Amz-Credential")
  valid_614197 = validateParameter(valid_614197, JString, required = false,
                                 default = nil)
  if valid_614197 != nil:
    section.add "X-Amz-Credential", valid_614197
  var valid_614198 = header.getOrDefault("X-Amz-Security-Token")
  valid_614198 = validateParameter(valid_614198, JString, required = false,
                                 default = nil)
  if valid_614198 != nil:
    section.add "X-Amz-Security-Token", valid_614198
  var valid_614199 = header.getOrDefault("X-Amz-Algorithm")
  valid_614199 = validateParameter(valid_614199, JString, required = false,
                                 default = nil)
  if valid_614199 != nil:
    section.add "X-Amz-Algorithm", valid_614199
  var valid_614200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614200 = validateParameter(valid_614200, JString, required = false,
                                 default = nil)
  if valid_614200 != nil:
    section.add "X-Amz-SignedHeaders", valid_614200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614202: Call_GetMLTaskRun_614190; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
  ## 
  let valid = call_614202.validator(path, query, header, formData, body)
  let scheme = call_614202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614202.url(scheme.get, call_614202.host, call_614202.base,
                         call_614202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614202, url, valid)

proc call*(call_614203: Call_GetMLTaskRun_614190; body: JsonNode): Recallable =
  ## getMLTaskRun
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
  ##   body: JObject (required)
  var body_614204 = newJObject()
  if body != nil:
    body_614204 = body
  result = call_614203.call(nil, nil, nil, nil, body_614204)

var getMLTaskRun* = Call_GetMLTaskRun_614190(name: "getMLTaskRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTaskRun",
    validator: validate_GetMLTaskRun_614191, base: "/", url: url_GetMLTaskRun_614192,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTaskRuns_614205 = ref object of OpenApiRestCall_612658
proc url_GetMLTaskRuns_614207(protocol: Scheme; host: string; base: string;
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

proc validate_GetMLTaskRuns_614206(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614208 = query.getOrDefault("MaxResults")
  valid_614208 = validateParameter(valid_614208, JString, required = false,
                                 default = nil)
  if valid_614208 != nil:
    section.add "MaxResults", valid_614208
  var valid_614209 = query.getOrDefault("NextToken")
  valid_614209 = validateParameter(valid_614209, JString, required = false,
                                 default = nil)
  if valid_614209 != nil:
    section.add "NextToken", valid_614209
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
  var valid_614210 = header.getOrDefault("X-Amz-Target")
  valid_614210 = validateParameter(valid_614210, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTaskRuns"))
  if valid_614210 != nil:
    section.add "X-Amz-Target", valid_614210
  var valid_614211 = header.getOrDefault("X-Amz-Signature")
  valid_614211 = validateParameter(valid_614211, JString, required = false,
                                 default = nil)
  if valid_614211 != nil:
    section.add "X-Amz-Signature", valid_614211
  var valid_614212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614212 = validateParameter(valid_614212, JString, required = false,
                                 default = nil)
  if valid_614212 != nil:
    section.add "X-Amz-Content-Sha256", valid_614212
  var valid_614213 = header.getOrDefault("X-Amz-Date")
  valid_614213 = validateParameter(valid_614213, JString, required = false,
                                 default = nil)
  if valid_614213 != nil:
    section.add "X-Amz-Date", valid_614213
  var valid_614214 = header.getOrDefault("X-Amz-Credential")
  valid_614214 = validateParameter(valid_614214, JString, required = false,
                                 default = nil)
  if valid_614214 != nil:
    section.add "X-Amz-Credential", valid_614214
  var valid_614215 = header.getOrDefault("X-Amz-Security-Token")
  valid_614215 = validateParameter(valid_614215, JString, required = false,
                                 default = nil)
  if valid_614215 != nil:
    section.add "X-Amz-Security-Token", valid_614215
  var valid_614216 = header.getOrDefault("X-Amz-Algorithm")
  valid_614216 = validateParameter(valid_614216, JString, required = false,
                                 default = nil)
  if valid_614216 != nil:
    section.add "X-Amz-Algorithm", valid_614216
  var valid_614217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614217 = validateParameter(valid_614217, JString, required = false,
                                 default = nil)
  if valid_614217 != nil:
    section.add "X-Amz-SignedHeaders", valid_614217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614219: Call_GetMLTaskRuns_614205; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
  ## 
  let valid = call_614219.validator(path, query, header, formData, body)
  let scheme = call_614219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614219.url(scheme.get, call_614219.host, call_614219.base,
                         call_614219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614219, url, valid)

proc call*(call_614220: Call_GetMLTaskRuns_614205; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getMLTaskRuns
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614221 = newJObject()
  var body_614222 = newJObject()
  add(query_614221, "MaxResults", newJString(MaxResults))
  add(query_614221, "NextToken", newJString(NextToken))
  if body != nil:
    body_614222 = body
  result = call_614220.call(nil, query_614221, nil, nil, body_614222)

var getMLTaskRuns* = Call_GetMLTaskRuns_614205(name: "getMLTaskRuns",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTaskRuns",
    validator: validate_GetMLTaskRuns_614206, base: "/", url: url_GetMLTaskRuns_614207,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTransform_614223 = ref object of OpenApiRestCall_612658
proc url_GetMLTransform_614225(protocol: Scheme; host: string; base: string;
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

proc validate_GetMLTransform_614224(path: JsonNode; query: JsonNode;
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
  var valid_614226 = header.getOrDefault("X-Amz-Target")
  valid_614226 = validateParameter(valid_614226, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTransform"))
  if valid_614226 != nil:
    section.add "X-Amz-Target", valid_614226
  var valid_614227 = header.getOrDefault("X-Amz-Signature")
  valid_614227 = validateParameter(valid_614227, JString, required = false,
                                 default = nil)
  if valid_614227 != nil:
    section.add "X-Amz-Signature", valid_614227
  var valid_614228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614228 = validateParameter(valid_614228, JString, required = false,
                                 default = nil)
  if valid_614228 != nil:
    section.add "X-Amz-Content-Sha256", valid_614228
  var valid_614229 = header.getOrDefault("X-Amz-Date")
  valid_614229 = validateParameter(valid_614229, JString, required = false,
                                 default = nil)
  if valid_614229 != nil:
    section.add "X-Amz-Date", valid_614229
  var valid_614230 = header.getOrDefault("X-Amz-Credential")
  valid_614230 = validateParameter(valid_614230, JString, required = false,
                                 default = nil)
  if valid_614230 != nil:
    section.add "X-Amz-Credential", valid_614230
  var valid_614231 = header.getOrDefault("X-Amz-Security-Token")
  valid_614231 = validateParameter(valid_614231, JString, required = false,
                                 default = nil)
  if valid_614231 != nil:
    section.add "X-Amz-Security-Token", valid_614231
  var valid_614232 = header.getOrDefault("X-Amz-Algorithm")
  valid_614232 = validateParameter(valid_614232, JString, required = false,
                                 default = nil)
  if valid_614232 != nil:
    section.add "X-Amz-Algorithm", valid_614232
  var valid_614233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614233 = validateParameter(valid_614233, JString, required = false,
                                 default = nil)
  if valid_614233 != nil:
    section.add "X-Amz-SignedHeaders", valid_614233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614235: Call_GetMLTransform_614223; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
  ## 
  let valid = call_614235.validator(path, query, header, formData, body)
  let scheme = call_614235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614235.url(scheme.get, call_614235.host, call_614235.base,
                         call_614235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614235, url, valid)

proc call*(call_614236: Call_GetMLTransform_614223; body: JsonNode): Recallable =
  ## getMLTransform
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
  ##   body: JObject (required)
  var body_614237 = newJObject()
  if body != nil:
    body_614237 = body
  result = call_614236.call(nil, nil, nil, nil, body_614237)

var getMLTransform* = Call_GetMLTransform_614223(name: "getMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTransform",
    validator: validate_GetMLTransform_614224, base: "/", url: url_GetMLTransform_614225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTransforms_614238 = ref object of OpenApiRestCall_612658
proc url_GetMLTransforms_614240(protocol: Scheme; host: string; base: string;
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

proc validate_GetMLTransforms_614239(path: JsonNode; query: JsonNode;
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
  var valid_614241 = query.getOrDefault("MaxResults")
  valid_614241 = validateParameter(valid_614241, JString, required = false,
                                 default = nil)
  if valid_614241 != nil:
    section.add "MaxResults", valid_614241
  var valid_614242 = query.getOrDefault("NextToken")
  valid_614242 = validateParameter(valid_614242, JString, required = false,
                                 default = nil)
  if valid_614242 != nil:
    section.add "NextToken", valid_614242
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
  var valid_614243 = header.getOrDefault("X-Amz-Target")
  valid_614243 = validateParameter(valid_614243, JString, required = true, default = newJString(
      "AWSGlue.GetMLTransforms"))
  if valid_614243 != nil:
    section.add "X-Amz-Target", valid_614243
  var valid_614244 = header.getOrDefault("X-Amz-Signature")
  valid_614244 = validateParameter(valid_614244, JString, required = false,
                                 default = nil)
  if valid_614244 != nil:
    section.add "X-Amz-Signature", valid_614244
  var valid_614245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614245 = validateParameter(valid_614245, JString, required = false,
                                 default = nil)
  if valid_614245 != nil:
    section.add "X-Amz-Content-Sha256", valid_614245
  var valid_614246 = header.getOrDefault("X-Amz-Date")
  valid_614246 = validateParameter(valid_614246, JString, required = false,
                                 default = nil)
  if valid_614246 != nil:
    section.add "X-Amz-Date", valid_614246
  var valid_614247 = header.getOrDefault("X-Amz-Credential")
  valid_614247 = validateParameter(valid_614247, JString, required = false,
                                 default = nil)
  if valid_614247 != nil:
    section.add "X-Amz-Credential", valid_614247
  var valid_614248 = header.getOrDefault("X-Amz-Security-Token")
  valid_614248 = validateParameter(valid_614248, JString, required = false,
                                 default = nil)
  if valid_614248 != nil:
    section.add "X-Amz-Security-Token", valid_614248
  var valid_614249 = header.getOrDefault("X-Amz-Algorithm")
  valid_614249 = validateParameter(valid_614249, JString, required = false,
                                 default = nil)
  if valid_614249 != nil:
    section.add "X-Amz-Algorithm", valid_614249
  var valid_614250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614250 = validateParameter(valid_614250, JString, required = false,
                                 default = nil)
  if valid_614250 != nil:
    section.add "X-Amz-SignedHeaders", valid_614250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614252: Call_GetMLTransforms_614238; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
  ## 
  let valid = call_614252.validator(path, query, header, formData, body)
  let scheme = call_614252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614252.url(scheme.get, call_614252.host, call_614252.base,
                         call_614252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614252, url, valid)

proc call*(call_614253: Call_GetMLTransforms_614238; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getMLTransforms
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614254 = newJObject()
  var body_614255 = newJObject()
  add(query_614254, "MaxResults", newJString(MaxResults))
  add(query_614254, "NextToken", newJString(NextToken))
  if body != nil:
    body_614255 = body
  result = call_614253.call(nil, query_614254, nil, nil, body_614255)

var getMLTransforms* = Call_GetMLTransforms_614238(name: "getMLTransforms",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTransforms",
    validator: validate_GetMLTransforms_614239, base: "/", url: url_GetMLTransforms_614240,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMapping_614256 = ref object of OpenApiRestCall_612658
proc url_GetMapping_614258(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetMapping_614257(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614259 = header.getOrDefault("X-Amz-Target")
  valid_614259 = validateParameter(valid_614259, JString, required = true,
                                 default = newJString("AWSGlue.GetMapping"))
  if valid_614259 != nil:
    section.add "X-Amz-Target", valid_614259
  var valid_614260 = header.getOrDefault("X-Amz-Signature")
  valid_614260 = validateParameter(valid_614260, JString, required = false,
                                 default = nil)
  if valid_614260 != nil:
    section.add "X-Amz-Signature", valid_614260
  var valid_614261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614261 = validateParameter(valid_614261, JString, required = false,
                                 default = nil)
  if valid_614261 != nil:
    section.add "X-Amz-Content-Sha256", valid_614261
  var valid_614262 = header.getOrDefault("X-Amz-Date")
  valid_614262 = validateParameter(valid_614262, JString, required = false,
                                 default = nil)
  if valid_614262 != nil:
    section.add "X-Amz-Date", valid_614262
  var valid_614263 = header.getOrDefault("X-Amz-Credential")
  valid_614263 = validateParameter(valid_614263, JString, required = false,
                                 default = nil)
  if valid_614263 != nil:
    section.add "X-Amz-Credential", valid_614263
  var valid_614264 = header.getOrDefault("X-Amz-Security-Token")
  valid_614264 = validateParameter(valid_614264, JString, required = false,
                                 default = nil)
  if valid_614264 != nil:
    section.add "X-Amz-Security-Token", valid_614264
  var valid_614265 = header.getOrDefault("X-Amz-Algorithm")
  valid_614265 = validateParameter(valid_614265, JString, required = false,
                                 default = nil)
  if valid_614265 != nil:
    section.add "X-Amz-Algorithm", valid_614265
  var valid_614266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614266 = validateParameter(valid_614266, JString, required = false,
                                 default = nil)
  if valid_614266 != nil:
    section.add "X-Amz-SignedHeaders", valid_614266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614268: Call_GetMapping_614256; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates mappings.
  ## 
  let valid = call_614268.validator(path, query, header, formData, body)
  let scheme = call_614268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614268.url(scheme.get, call_614268.host, call_614268.base,
                         call_614268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614268, url, valid)

proc call*(call_614269: Call_GetMapping_614256; body: JsonNode): Recallable =
  ## getMapping
  ## Creates mappings.
  ##   body: JObject (required)
  var body_614270 = newJObject()
  if body != nil:
    body_614270 = body
  result = call_614269.call(nil, nil, nil, nil, body_614270)

var getMapping* = Call_GetMapping_614256(name: "getMapping",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetMapping",
                                      validator: validate_GetMapping_614257,
                                      base: "/", url: url_GetMapping_614258,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPartition_614271 = ref object of OpenApiRestCall_612658
proc url_GetPartition_614273(protocol: Scheme; host: string; base: string;
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

proc validate_GetPartition_614272(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614274 = header.getOrDefault("X-Amz-Target")
  valid_614274 = validateParameter(valid_614274, JString, required = true,
                                 default = newJString("AWSGlue.GetPartition"))
  if valid_614274 != nil:
    section.add "X-Amz-Target", valid_614274
  var valid_614275 = header.getOrDefault("X-Amz-Signature")
  valid_614275 = validateParameter(valid_614275, JString, required = false,
                                 default = nil)
  if valid_614275 != nil:
    section.add "X-Amz-Signature", valid_614275
  var valid_614276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614276 = validateParameter(valid_614276, JString, required = false,
                                 default = nil)
  if valid_614276 != nil:
    section.add "X-Amz-Content-Sha256", valid_614276
  var valid_614277 = header.getOrDefault("X-Amz-Date")
  valid_614277 = validateParameter(valid_614277, JString, required = false,
                                 default = nil)
  if valid_614277 != nil:
    section.add "X-Amz-Date", valid_614277
  var valid_614278 = header.getOrDefault("X-Amz-Credential")
  valid_614278 = validateParameter(valid_614278, JString, required = false,
                                 default = nil)
  if valid_614278 != nil:
    section.add "X-Amz-Credential", valid_614278
  var valid_614279 = header.getOrDefault("X-Amz-Security-Token")
  valid_614279 = validateParameter(valid_614279, JString, required = false,
                                 default = nil)
  if valid_614279 != nil:
    section.add "X-Amz-Security-Token", valid_614279
  var valid_614280 = header.getOrDefault("X-Amz-Algorithm")
  valid_614280 = validateParameter(valid_614280, JString, required = false,
                                 default = nil)
  if valid_614280 != nil:
    section.add "X-Amz-Algorithm", valid_614280
  var valid_614281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614281 = validateParameter(valid_614281, JString, required = false,
                                 default = nil)
  if valid_614281 != nil:
    section.add "X-Amz-SignedHeaders", valid_614281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614283: Call_GetPartition_614271; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a specified partition.
  ## 
  let valid = call_614283.validator(path, query, header, formData, body)
  let scheme = call_614283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614283.url(scheme.get, call_614283.host, call_614283.base,
                         call_614283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614283, url, valid)

proc call*(call_614284: Call_GetPartition_614271; body: JsonNode): Recallable =
  ## getPartition
  ## Retrieves information about a specified partition.
  ##   body: JObject (required)
  var body_614285 = newJObject()
  if body != nil:
    body_614285 = body
  result = call_614284.call(nil, nil, nil, nil, body_614285)

var getPartition* = Call_GetPartition_614271(name: "getPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetPartition",
    validator: validate_GetPartition_614272, base: "/", url: url_GetPartition_614273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPartitions_614286 = ref object of OpenApiRestCall_612658
proc url_GetPartitions_614288(protocol: Scheme; host: string; base: string;
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

proc validate_GetPartitions_614287(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614289 = query.getOrDefault("MaxResults")
  valid_614289 = validateParameter(valid_614289, JString, required = false,
                                 default = nil)
  if valid_614289 != nil:
    section.add "MaxResults", valid_614289
  var valid_614290 = query.getOrDefault("NextToken")
  valid_614290 = validateParameter(valid_614290, JString, required = false,
                                 default = nil)
  if valid_614290 != nil:
    section.add "NextToken", valid_614290
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
  var valid_614291 = header.getOrDefault("X-Amz-Target")
  valid_614291 = validateParameter(valid_614291, JString, required = true,
                                 default = newJString("AWSGlue.GetPartitions"))
  if valid_614291 != nil:
    section.add "X-Amz-Target", valid_614291
  var valid_614292 = header.getOrDefault("X-Amz-Signature")
  valid_614292 = validateParameter(valid_614292, JString, required = false,
                                 default = nil)
  if valid_614292 != nil:
    section.add "X-Amz-Signature", valid_614292
  var valid_614293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614293 = validateParameter(valid_614293, JString, required = false,
                                 default = nil)
  if valid_614293 != nil:
    section.add "X-Amz-Content-Sha256", valid_614293
  var valid_614294 = header.getOrDefault("X-Amz-Date")
  valid_614294 = validateParameter(valid_614294, JString, required = false,
                                 default = nil)
  if valid_614294 != nil:
    section.add "X-Amz-Date", valid_614294
  var valid_614295 = header.getOrDefault("X-Amz-Credential")
  valid_614295 = validateParameter(valid_614295, JString, required = false,
                                 default = nil)
  if valid_614295 != nil:
    section.add "X-Amz-Credential", valid_614295
  var valid_614296 = header.getOrDefault("X-Amz-Security-Token")
  valid_614296 = validateParameter(valid_614296, JString, required = false,
                                 default = nil)
  if valid_614296 != nil:
    section.add "X-Amz-Security-Token", valid_614296
  var valid_614297 = header.getOrDefault("X-Amz-Algorithm")
  valid_614297 = validateParameter(valid_614297, JString, required = false,
                                 default = nil)
  if valid_614297 != nil:
    section.add "X-Amz-Algorithm", valid_614297
  var valid_614298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614298 = validateParameter(valid_614298, JString, required = false,
                                 default = nil)
  if valid_614298 != nil:
    section.add "X-Amz-SignedHeaders", valid_614298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614300: Call_GetPartitions_614286; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the partitions in a table.
  ## 
  let valid = call_614300.validator(path, query, header, formData, body)
  let scheme = call_614300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614300.url(scheme.get, call_614300.host, call_614300.base,
                         call_614300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614300, url, valid)

proc call*(call_614301: Call_GetPartitions_614286; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getPartitions
  ## Retrieves information about the partitions in a table.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614302 = newJObject()
  var body_614303 = newJObject()
  add(query_614302, "MaxResults", newJString(MaxResults))
  add(query_614302, "NextToken", newJString(NextToken))
  if body != nil:
    body_614303 = body
  result = call_614301.call(nil, query_614302, nil, nil, body_614303)

var getPartitions* = Call_GetPartitions_614286(name: "getPartitions",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetPartitions",
    validator: validate_GetPartitions_614287, base: "/", url: url_GetPartitions_614288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPlan_614304 = ref object of OpenApiRestCall_612658
proc url_GetPlan_614306(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetPlan_614305(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614307 = header.getOrDefault("X-Amz-Target")
  valid_614307 = validateParameter(valid_614307, JString, required = true,
                                 default = newJString("AWSGlue.GetPlan"))
  if valid_614307 != nil:
    section.add "X-Amz-Target", valid_614307
  var valid_614308 = header.getOrDefault("X-Amz-Signature")
  valid_614308 = validateParameter(valid_614308, JString, required = false,
                                 default = nil)
  if valid_614308 != nil:
    section.add "X-Amz-Signature", valid_614308
  var valid_614309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614309 = validateParameter(valid_614309, JString, required = false,
                                 default = nil)
  if valid_614309 != nil:
    section.add "X-Amz-Content-Sha256", valid_614309
  var valid_614310 = header.getOrDefault("X-Amz-Date")
  valid_614310 = validateParameter(valid_614310, JString, required = false,
                                 default = nil)
  if valid_614310 != nil:
    section.add "X-Amz-Date", valid_614310
  var valid_614311 = header.getOrDefault("X-Amz-Credential")
  valid_614311 = validateParameter(valid_614311, JString, required = false,
                                 default = nil)
  if valid_614311 != nil:
    section.add "X-Amz-Credential", valid_614311
  var valid_614312 = header.getOrDefault("X-Amz-Security-Token")
  valid_614312 = validateParameter(valid_614312, JString, required = false,
                                 default = nil)
  if valid_614312 != nil:
    section.add "X-Amz-Security-Token", valid_614312
  var valid_614313 = header.getOrDefault("X-Amz-Algorithm")
  valid_614313 = validateParameter(valid_614313, JString, required = false,
                                 default = nil)
  if valid_614313 != nil:
    section.add "X-Amz-Algorithm", valid_614313
  var valid_614314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614314 = validateParameter(valid_614314, JString, required = false,
                                 default = nil)
  if valid_614314 != nil:
    section.add "X-Amz-SignedHeaders", valid_614314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614316: Call_GetPlan_614304; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets code to perform a specified mapping.
  ## 
  let valid = call_614316.validator(path, query, header, formData, body)
  let scheme = call_614316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614316.url(scheme.get, call_614316.host, call_614316.base,
                         call_614316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614316, url, valid)

proc call*(call_614317: Call_GetPlan_614304; body: JsonNode): Recallable =
  ## getPlan
  ## Gets code to perform a specified mapping.
  ##   body: JObject (required)
  var body_614318 = newJObject()
  if body != nil:
    body_614318 = body
  result = call_614317.call(nil, nil, nil, nil, body_614318)

var getPlan* = Call_GetPlan_614304(name: "getPlan", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetPlan",
                                validator: validate_GetPlan_614305, base: "/",
                                url: url_GetPlan_614306,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourcePolicy_614319 = ref object of OpenApiRestCall_612658
proc url_GetResourcePolicy_614321(protocol: Scheme; host: string; base: string;
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

proc validate_GetResourcePolicy_614320(path: JsonNode; query: JsonNode;
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
  var valid_614322 = header.getOrDefault("X-Amz-Target")
  valid_614322 = validateParameter(valid_614322, JString, required = true, default = newJString(
      "AWSGlue.GetResourcePolicy"))
  if valid_614322 != nil:
    section.add "X-Amz-Target", valid_614322
  var valid_614323 = header.getOrDefault("X-Amz-Signature")
  valid_614323 = validateParameter(valid_614323, JString, required = false,
                                 default = nil)
  if valid_614323 != nil:
    section.add "X-Amz-Signature", valid_614323
  var valid_614324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614324 = validateParameter(valid_614324, JString, required = false,
                                 default = nil)
  if valid_614324 != nil:
    section.add "X-Amz-Content-Sha256", valid_614324
  var valid_614325 = header.getOrDefault("X-Amz-Date")
  valid_614325 = validateParameter(valid_614325, JString, required = false,
                                 default = nil)
  if valid_614325 != nil:
    section.add "X-Amz-Date", valid_614325
  var valid_614326 = header.getOrDefault("X-Amz-Credential")
  valid_614326 = validateParameter(valid_614326, JString, required = false,
                                 default = nil)
  if valid_614326 != nil:
    section.add "X-Amz-Credential", valid_614326
  var valid_614327 = header.getOrDefault("X-Amz-Security-Token")
  valid_614327 = validateParameter(valid_614327, JString, required = false,
                                 default = nil)
  if valid_614327 != nil:
    section.add "X-Amz-Security-Token", valid_614327
  var valid_614328 = header.getOrDefault("X-Amz-Algorithm")
  valid_614328 = validateParameter(valid_614328, JString, required = false,
                                 default = nil)
  if valid_614328 != nil:
    section.add "X-Amz-Algorithm", valid_614328
  var valid_614329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614329 = validateParameter(valid_614329, JString, required = false,
                                 default = nil)
  if valid_614329 != nil:
    section.add "X-Amz-SignedHeaders", valid_614329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614331: Call_GetResourcePolicy_614319; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified resource policy.
  ## 
  let valid = call_614331.validator(path, query, header, formData, body)
  let scheme = call_614331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614331.url(scheme.get, call_614331.host, call_614331.base,
                         call_614331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614331, url, valid)

proc call*(call_614332: Call_GetResourcePolicy_614319; body: JsonNode): Recallable =
  ## getResourcePolicy
  ## Retrieves a specified resource policy.
  ##   body: JObject (required)
  var body_614333 = newJObject()
  if body != nil:
    body_614333 = body
  result = call_614332.call(nil, nil, nil, nil, body_614333)

var getResourcePolicy* = Call_GetResourcePolicy_614319(name: "getResourcePolicy",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetResourcePolicy",
    validator: validate_GetResourcePolicy_614320, base: "/",
    url: url_GetResourcePolicy_614321, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSecurityConfiguration_614334 = ref object of OpenApiRestCall_612658
proc url_GetSecurityConfiguration_614336(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSecurityConfiguration_614335(path: JsonNode; query: JsonNode;
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
  var valid_614337 = header.getOrDefault("X-Amz-Target")
  valid_614337 = validateParameter(valid_614337, JString, required = true, default = newJString(
      "AWSGlue.GetSecurityConfiguration"))
  if valid_614337 != nil:
    section.add "X-Amz-Target", valid_614337
  var valid_614338 = header.getOrDefault("X-Amz-Signature")
  valid_614338 = validateParameter(valid_614338, JString, required = false,
                                 default = nil)
  if valid_614338 != nil:
    section.add "X-Amz-Signature", valid_614338
  var valid_614339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614339 = validateParameter(valid_614339, JString, required = false,
                                 default = nil)
  if valid_614339 != nil:
    section.add "X-Amz-Content-Sha256", valid_614339
  var valid_614340 = header.getOrDefault("X-Amz-Date")
  valid_614340 = validateParameter(valid_614340, JString, required = false,
                                 default = nil)
  if valid_614340 != nil:
    section.add "X-Amz-Date", valid_614340
  var valid_614341 = header.getOrDefault("X-Amz-Credential")
  valid_614341 = validateParameter(valid_614341, JString, required = false,
                                 default = nil)
  if valid_614341 != nil:
    section.add "X-Amz-Credential", valid_614341
  var valid_614342 = header.getOrDefault("X-Amz-Security-Token")
  valid_614342 = validateParameter(valid_614342, JString, required = false,
                                 default = nil)
  if valid_614342 != nil:
    section.add "X-Amz-Security-Token", valid_614342
  var valid_614343 = header.getOrDefault("X-Amz-Algorithm")
  valid_614343 = validateParameter(valid_614343, JString, required = false,
                                 default = nil)
  if valid_614343 != nil:
    section.add "X-Amz-Algorithm", valid_614343
  var valid_614344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614344 = validateParameter(valid_614344, JString, required = false,
                                 default = nil)
  if valid_614344 != nil:
    section.add "X-Amz-SignedHeaders", valid_614344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614346: Call_GetSecurityConfiguration_614334; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified security configuration.
  ## 
  let valid = call_614346.validator(path, query, header, formData, body)
  let scheme = call_614346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614346.url(scheme.get, call_614346.host, call_614346.base,
                         call_614346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614346, url, valid)

proc call*(call_614347: Call_GetSecurityConfiguration_614334; body: JsonNode): Recallable =
  ## getSecurityConfiguration
  ## Retrieves a specified security configuration.
  ##   body: JObject (required)
  var body_614348 = newJObject()
  if body != nil:
    body_614348 = body
  result = call_614347.call(nil, nil, nil, nil, body_614348)

var getSecurityConfiguration* = Call_GetSecurityConfiguration_614334(
    name: "getSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetSecurityConfiguration",
    validator: validate_GetSecurityConfiguration_614335, base: "/",
    url: url_GetSecurityConfiguration_614336, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSecurityConfigurations_614349 = ref object of OpenApiRestCall_612658
proc url_GetSecurityConfigurations_614351(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSecurityConfigurations_614350(path: JsonNode; query: JsonNode;
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
  var valid_614352 = query.getOrDefault("MaxResults")
  valid_614352 = validateParameter(valid_614352, JString, required = false,
                                 default = nil)
  if valid_614352 != nil:
    section.add "MaxResults", valid_614352
  var valid_614353 = query.getOrDefault("NextToken")
  valid_614353 = validateParameter(valid_614353, JString, required = false,
                                 default = nil)
  if valid_614353 != nil:
    section.add "NextToken", valid_614353
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
  var valid_614354 = header.getOrDefault("X-Amz-Target")
  valid_614354 = validateParameter(valid_614354, JString, required = true, default = newJString(
      "AWSGlue.GetSecurityConfigurations"))
  if valid_614354 != nil:
    section.add "X-Amz-Target", valid_614354
  var valid_614355 = header.getOrDefault("X-Amz-Signature")
  valid_614355 = validateParameter(valid_614355, JString, required = false,
                                 default = nil)
  if valid_614355 != nil:
    section.add "X-Amz-Signature", valid_614355
  var valid_614356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614356 = validateParameter(valid_614356, JString, required = false,
                                 default = nil)
  if valid_614356 != nil:
    section.add "X-Amz-Content-Sha256", valid_614356
  var valid_614357 = header.getOrDefault("X-Amz-Date")
  valid_614357 = validateParameter(valid_614357, JString, required = false,
                                 default = nil)
  if valid_614357 != nil:
    section.add "X-Amz-Date", valid_614357
  var valid_614358 = header.getOrDefault("X-Amz-Credential")
  valid_614358 = validateParameter(valid_614358, JString, required = false,
                                 default = nil)
  if valid_614358 != nil:
    section.add "X-Amz-Credential", valid_614358
  var valid_614359 = header.getOrDefault("X-Amz-Security-Token")
  valid_614359 = validateParameter(valid_614359, JString, required = false,
                                 default = nil)
  if valid_614359 != nil:
    section.add "X-Amz-Security-Token", valid_614359
  var valid_614360 = header.getOrDefault("X-Amz-Algorithm")
  valid_614360 = validateParameter(valid_614360, JString, required = false,
                                 default = nil)
  if valid_614360 != nil:
    section.add "X-Amz-Algorithm", valid_614360
  var valid_614361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614361 = validateParameter(valid_614361, JString, required = false,
                                 default = nil)
  if valid_614361 != nil:
    section.add "X-Amz-SignedHeaders", valid_614361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614363: Call_GetSecurityConfigurations_614349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of all security configurations.
  ## 
  let valid = call_614363.validator(path, query, header, formData, body)
  let scheme = call_614363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614363.url(scheme.get, call_614363.host, call_614363.base,
                         call_614363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614363, url, valid)

proc call*(call_614364: Call_GetSecurityConfigurations_614349; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getSecurityConfigurations
  ## Retrieves a list of all security configurations.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614365 = newJObject()
  var body_614366 = newJObject()
  add(query_614365, "MaxResults", newJString(MaxResults))
  add(query_614365, "NextToken", newJString(NextToken))
  if body != nil:
    body_614366 = body
  result = call_614364.call(nil, query_614365, nil, nil, body_614366)

var getSecurityConfigurations* = Call_GetSecurityConfigurations_614349(
    name: "getSecurityConfigurations", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetSecurityConfigurations",
    validator: validate_GetSecurityConfigurations_614350, base: "/",
    url: url_GetSecurityConfigurations_614351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTable_614367 = ref object of OpenApiRestCall_612658
proc url_GetTable_614369(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTable_614368(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614370 = header.getOrDefault("X-Amz-Target")
  valid_614370 = validateParameter(valid_614370, JString, required = true,
                                 default = newJString("AWSGlue.GetTable"))
  if valid_614370 != nil:
    section.add "X-Amz-Target", valid_614370
  var valid_614371 = header.getOrDefault("X-Amz-Signature")
  valid_614371 = validateParameter(valid_614371, JString, required = false,
                                 default = nil)
  if valid_614371 != nil:
    section.add "X-Amz-Signature", valid_614371
  var valid_614372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614372 = validateParameter(valid_614372, JString, required = false,
                                 default = nil)
  if valid_614372 != nil:
    section.add "X-Amz-Content-Sha256", valid_614372
  var valid_614373 = header.getOrDefault("X-Amz-Date")
  valid_614373 = validateParameter(valid_614373, JString, required = false,
                                 default = nil)
  if valid_614373 != nil:
    section.add "X-Amz-Date", valid_614373
  var valid_614374 = header.getOrDefault("X-Amz-Credential")
  valid_614374 = validateParameter(valid_614374, JString, required = false,
                                 default = nil)
  if valid_614374 != nil:
    section.add "X-Amz-Credential", valid_614374
  var valid_614375 = header.getOrDefault("X-Amz-Security-Token")
  valid_614375 = validateParameter(valid_614375, JString, required = false,
                                 default = nil)
  if valid_614375 != nil:
    section.add "X-Amz-Security-Token", valid_614375
  var valid_614376 = header.getOrDefault("X-Amz-Algorithm")
  valid_614376 = validateParameter(valid_614376, JString, required = false,
                                 default = nil)
  if valid_614376 != nil:
    section.add "X-Amz-Algorithm", valid_614376
  var valid_614377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614377 = validateParameter(valid_614377, JString, required = false,
                                 default = nil)
  if valid_614377 != nil:
    section.add "X-Amz-SignedHeaders", valid_614377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614379: Call_GetTable_614367; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
  ## 
  let valid = call_614379.validator(path, query, header, formData, body)
  let scheme = call_614379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614379.url(scheme.get, call_614379.host, call_614379.base,
                         call_614379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614379, url, valid)

proc call*(call_614380: Call_GetTable_614367; body: JsonNode): Recallable =
  ## getTable
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
  ##   body: JObject (required)
  var body_614381 = newJObject()
  if body != nil:
    body_614381 = body
  result = call_614380.call(nil, nil, nil, nil, body_614381)

var getTable* = Call_GetTable_614367(name: "getTable", meth: HttpMethod.HttpPost,
                                  host: "glue.amazonaws.com",
                                  route: "/#X-Amz-Target=AWSGlue.GetTable",
                                  validator: validate_GetTable_614368, base: "/",
                                  url: url_GetTable_614369,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTableVersion_614382 = ref object of OpenApiRestCall_612658
proc url_GetTableVersion_614384(protocol: Scheme; host: string; base: string;
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

proc validate_GetTableVersion_614383(path: JsonNode; query: JsonNode;
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
  var valid_614385 = header.getOrDefault("X-Amz-Target")
  valid_614385 = validateParameter(valid_614385, JString, required = true, default = newJString(
      "AWSGlue.GetTableVersion"))
  if valid_614385 != nil:
    section.add "X-Amz-Target", valid_614385
  var valid_614386 = header.getOrDefault("X-Amz-Signature")
  valid_614386 = validateParameter(valid_614386, JString, required = false,
                                 default = nil)
  if valid_614386 != nil:
    section.add "X-Amz-Signature", valid_614386
  var valid_614387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614387 = validateParameter(valid_614387, JString, required = false,
                                 default = nil)
  if valid_614387 != nil:
    section.add "X-Amz-Content-Sha256", valid_614387
  var valid_614388 = header.getOrDefault("X-Amz-Date")
  valid_614388 = validateParameter(valid_614388, JString, required = false,
                                 default = nil)
  if valid_614388 != nil:
    section.add "X-Amz-Date", valid_614388
  var valid_614389 = header.getOrDefault("X-Amz-Credential")
  valid_614389 = validateParameter(valid_614389, JString, required = false,
                                 default = nil)
  if valid_614389 != nil:
    section.add "X-Amz-Credential", valid_614389
  var valid_614390 = header.getOrDefault("X-Amz-Security-Token")
  valid_614390 = validateParameter(valid_614390, JString, required = false,
                                 default = nil)
  if valid_614390 != nil:
    section.add "X-Amz-Security-Token", valid_614390
  var valid_614391 = header.getOrDefault("X-Amz-Algorithm")
  valid_614391 = validateParameter(valid_614391, JString, required = false,
                                 default = nil)
  if valid_614391 != nil:
    section.add "X-Amz-Algorithm", valid_614391
  var valid_614392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614392 = validateParameter(valid_614392, JString, required = false,
                                 default = nil)
  if valid_614392 != nil:
    section.add "X-Amz-SignedHeaders", valid_614392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614394: Call_GetTableVersion_614382; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified version of a table.
  ## 
  let valid = call_614394.validator(path, query, header, formData, body)
  let scheme = call_614394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614394.url(scheme.get, call_614394.host, call_614394.base,
                         call_614394.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614394, url, valid)

proc call*(call_614395: Call_GetTableVersion_614382; body: JsonNode): Recallable =
  ## getTableVersion
  ## Retrieves a specified version of a table.
  ##   body: JObject (required)
  var body_614396 = newJObject()
  if body != nil:
    body_614396 = body
  result = call_614395.call(nil, nil, nil, nil, body_614396)

var getTableVersion* = Call_GetTableVersion_614382(name: "getTableVersion",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetTableVersion",
    validator: validate_GetTableVersion_614383, base: "/", url: url_GetTableVersion_614384,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTableVersions_614397 = ref object of OpenApiRestCall_612658
proc url_GetTableVersions_614399(protocol: Scheme; host: string; base: string;
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

proc validate_GetTableVersions_614398(path: JsonNode; query: JsonNode;
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
  var valid_614400 = query.getOrDefault("MaxResults")
  valid_614400 = validateParameter(valid_614400, JString, required = false,
                                 default = nil)
  if valid_614400 != nil:
    section.add "MaxResults", valid_614400
  var valid_614401 = query.getOrDefault("NextToken")
  valid_614401 = validateParameter(valid_614401, JString, required = false,
                                 default = nil)
  if valid_614401 != nil:
    section.add "NextToken", valid_614401
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
  var valid_614402 = header.getOrDefault("X-Amz-Target")
  valid_614402 = validateParameter(valid_614402, JString, required = true, default = newJString(
      "AWSGlue.GetTableVersions"))
  if valid_614402 != nil:
    section.add "X-Amz-Target", valid_614402
  var valid_614403 = header.getOrDefault("X-Amz-Signature")
  valid_614403 = validateParameter(valid_614403, JString, required = false,
                                 default = nil)
  if valid_614403 != nil:
    section.add "X-Amz-Signature", valid_614403
  var valid_614404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614404 = validateParameter(valid_614404, JString, required = false,
                                 default = nil)
  if valid_614404 != nil:
    section.add "X-Amz-Content-Sha256", valid_614404
  var valid_614405 = header.getOrDefault("X-Amz-Date")
  valid_614405 = validateParameter(valid_614405, JString, required = false,
                                 default = nil)
  if valid_614405 != nil:
    section.add "X-Amz-Date", valid_614405
  var valid_614406 = header.getOrDefault("X-Amz-Credential")
  valid_614406 = validateParameter(valid_614406, JString, required = false,
                                 default = nil)
  if valid_614406 != nil:
    section.add "X-Amz-Credential", valid_614406
  var valid_614407 = header.getOrDefault("X-Amz-Security-Token")
  valid_614407 = validateParameter(valid_614407, JString, required = false,
                                 default = nil)
  if valid_614407 != nil:
    section.add "X-Amz-Security-Token", valid_614407
  var valid_614408 = header.getOrDefault("X-Amz-Algorithm")
  valid_614408 = validateParameter(valid_614408, JString, required = false,
                                 default = nil)
  if valid_614408 != nil:
    section.add "X-Amz-Algorithm", valid_614408
  var valid_614409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614409 = validateParameter(valid_614409, JString, required = false,
                                 default = nil)
  if valid_614409 != nil:
    section.add "X-Amz-SignedHeaders", valid_614409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614411: Call_GetTableVersions_614397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of strings that identify available versions of a specified table.
  ## 
  let valid = call_614411.validator(path, query, header, formData, body)
  let scheme = call_614411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614411.url(scheme.get, call_614411.host, call_614411.base,
                         call_614411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614411, url, valid)

proc call*(call_614412: Call_GetTableVersions_614397; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getTableVersions
  ## Retrieves a list of strings that identify available versions of a specified table.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614413 = newJObject()
  var body_614414 = newJObject()
  add(query_614413, "MaxResults", newJString(MaxResults))
  add(query_614413, "NextToken", newJString(NextToken))
  if body != nil:
    body_614414 = body
  result = call_614412.call(nil, query_614413, nil, nil, body_614414)

var getTableVersions* = Call_GetTableVersions_614397(name: "getTableVersions",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetTableVersions",
    validator: validate_GetTableVersions_614398, base: "/",
    url: url_GetTableVersions_614399, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTables_614415 = ref object of OpenApiRestCall_612658
proc url_GetTables_614417(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTables_614416(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614418 = query.getOrDefault("MaxResults")
  valid_614418 = validateParameter(valid_614418, JString, required = false,
                                 default = nil)
  if valid_614418 != nil:
    section.add "MaxResults", valid_614418
  var valid_614419 = query.getOrDefault("NextToken")
  valid_614419 = validateParameter(valid_614419, JString, required = false,
                                 default = nil)
  if valid_614419 != nil:
    section.add "NextToken", valid_614419
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
  var valid_614420 = header.getOrDefault("X-Amz-Target")
  valid_614420 = validateParameter(valid_614420, JString, required = true,
                                 default = newJString("AWSGlue.GetTables"))
  if valid_614420 != nil:
    section.add "X-Amz-Target", valid_614420
  var valid_614421 = header.getOrDefault("X-Amz-Signature")
  valid_614421 = validateParameter(valid_614421, JString, required = false,
                                 default = nil)
  if valid_614421 != nil:
    section.add "X-Amz-Signature", valid_614421
  var valid_614422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614422 = validateParameter(valid_614422, JString, required = false,
                                 default = nil)
  if valid_614422 != nil:
    section.add "X-Amz-Content-Sha256", valid_614422
  var valid_614423 = header.getOrDefault("X-Amz-Date")
  valid_614423 = validateParameter(valid_614423, JString, required = false,
                                 default = nil)
  if valid_614423 != nil:
    section.add "X-Amz-Date", valid_614423
  var valid_614424 = header.getOrDefault("X-Amz-Credential")
  valid_614424 = validateParameter(valid_614424, JString, required = false,
                                 default = nil)
  if valid_614424 != nil:
    section.add "X-Amz-Credential", valid_614424
  var valid_614425 = header.getOrDefault("X-Amz-Security-Token")
  valid_614425 = validateParameter(valid_614425, JString, required = false,
                                 default = nil)
  if valid_614425 != nil:
    section.add "X-Amz-Security-Token", valid_614425
  var valid_614426 = header.getOrDefault("X-Amz-Algorithm")
  valid_614426 = validateParameter(valid_614426, JString, required = false,
                                 default = nil)
  if valid_614426 != nil:
    section.add "X-Amz-Algorithm", valid_614426
  var valid_614427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614427 = validateParameter(valid_614427, JString, required = false,
                                 default = nil)
  if valid_614427 != nil:
    section.add "X-Amz-SignedHeaders", valid_614427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614429: Call_GetTables_614415; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
  ## 
  let valid = call_614429.validator(path, query, header, formData, body)
  let scheme = call_614429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614429.url(scheme.get, call_614429.host, call_614429.base,
                         call_614429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614429, url, valid)

proc call*(call_614430: Call_GetTables_614415; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getTables
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614431 = newJObject()
  var body_614432 = newJObject()
  add(query_614431, "MaxResults", newJString(MaxResults))
  add(query_614431, "NextToken", newJString(NextToken))
  if body != nil:
    body_614432 = body
  result = call_614430.call(nil, query_614431, nil, nil, body_614432)

var getTables* = Call_GetTables_614415(name: "getTables", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.GetTables",
                                    validator: validate_GetTables_614416,
                                    base: "/", url: url_GetTables_614417,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_614433 = ref object of OpenApiRestCall_612658
proc url_GetTags_614435(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTags_614434(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614436 = header.getOrDefault("X-Amz-Target")
  valid_614436 = validateParameter(valid_614436, JString, required = true,
                                 default = newJString("AWSGlue.GetTags"))
  if valid_614436 != nil:
    section.add "X-Amz-Target", valid_614436
  var valid_614437 = header.getOrDefault("X-Amz-Signature")
  valid_614437 = validateParameter(valid_614437, JString, required = false,
                                 default = nil)
  if valid_614437 != nil:
    section.add "X-Amz-Signature", valid_614437
  var valid_614438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614438 = validateParameter(valid_614438, JString, required = false,
                                 default = nil)
  if valid_614438 != nil:
    section.add "X-Amz-Content-Sha256", valid_614438
  var valid_614439 = header.getOrDefault("X-Amz-Date")
  valid_614439 = validateParameter(valid_614439, JString, required = false,
                                 default = nil)
  if valid_614439 != nil:
    section.add "X-Amz-Date", valid_614439
  var valid_614440 = header.getOrDefault("X-Amz-Credential")
  valid_614440 = validateParameter(valid_614440, JString, required = false,
                                 default = nil)
  if valid_614440 != nil:
    section.add "X-Amz-Credential", valid_614440
  var valid_614441 = header.getOrDefault("X-Amz-Security-Token")
  valid_614441 = validateParameter(valid_614441, JString, required = false,
                                 default = nil)
  if valid_614441 != nil:
    section.add "X-Amz-Security-Token", valid_614441
  var valid_614442 = header.getOrDefault("X-Amz-Algorithm")
  valid_614442 = validateParameter(valid_614442, JString, required = false,
                                 default = nil)
  if valid_614442 != nil:
    section.add "X-Amz-Algorithm", valid_614442
  var valid_614443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614443 = validateParameter(valid_614443, JString, required = false,
                                 default = nil)
  if valid_614443 != nil:
    section.add "X-Amz-SignedHeaders", valid_614443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614445: Call_GetTags_614433; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of tags associated with a resource.
  ## 
  let valid = call_614445.validator(path, query, header, formData, body)
  let scheme = call_614445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614445.url(scheme.get, call_614445.host, call_614445.base,
                         call_614445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614445, url, valid)

proc call*(call_614446: Call_GetTags_614433; body: JsonNode): Recallable =
  ## getTags
  ## Retrieves a list of tags associated with a resource.
  ##   body: JObject (required)
  var body_614447 = newJObject()
  if body != nil:
    body_614447 = body
  result = call_614446.call(nil, nil, nil, nil, body_614447)

var getTags* = Call_GetTags_614433(name: "getTags", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetTags",
                                validator: validate_GetTags_614434, base: "/",
                                url: url_GetTags_614435,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrigger_614448 = ref object of OpenApiRestCall_612658
proc url_GetTrigger_614450(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTrigger_614449(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614451 = header.getOrDefault("X-Amz-Target")
  valid_614451 = validateParameter(valid_614451, JString, required = true,
                                 default = newJString("AWSGlue.GetTrigger"))
  if valid_614451 != nil:
    section.add "X-Amz-Target", valid_614451
  var valid_614452 = header.getOrDefault("X-Amz-Signature")
  valid_614452 = validateParameter(valid_614452, JString, required = false,
                                 default = nil)
  if valid_614452 != nil:
    section.add "X-Amz-Signature", valid_614452
  var valid_614453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614453 = validateParameter(valid_614453, JString, required = false,
                                 default = nil)
  if valid_614453 != nil:
    section.add "X-Amz-Content-Sha256", valid_614453
  var valid_614454 = header.getOrDefault("X-Amz-Date")
  valid_614454 = validateParameter(valid_614454, JString, required = false,
                                 default = nil)
  if valid_614454 != nil:
    section.add "X-Amz-Date", valid_614454
  var valid_614455 = header.getOrDefault("X-Amz-Credential")
  valid_614455 = validateParameter(valid_614455, JString, required = false,
                                 default = nil)
  if valid_614455 != nil:
    section.add "X-Amz-Credential", valid_614455
  var valid_614456 = header.getOrDefault("X-Amz-Security-Token")
  valid_614456 = validateParameter(valid_614456, JString, required = false,
                                 default = nil)
  if valid_614456 != nil:
    section.add "X-Amz-Security-Token", valid_614456
  var valid_614457 = header.getOrDefault("X-Amz-Algorithm")
  valid_614457 = validateParameter(valid_614457, JString, required = false,
                                 default = nil)
  if valid_614457 != nil:
    section.add "X-Amz-Algorithm", valid_614457
  var valid_614458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614458 = validateParameter(valid_614458, JString, required = false,
                                 default = nil)
  if valid_614458 != nil:
    section.add "X-Amz-SignedHeaders", valid_614458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614460: Call_GetTrigger_614448; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definition of a trigger.
  ## 
  let valid = call_614460.validator(path, query, header, formData, body)
  let scheme = call_614460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614460.url(scheme.get, call_614460.host, call_614460.base,
                         call_614460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614460, url, valid)

proc call*(call_614461: Call_GetTrigger_614448; body: JsonNode): Recallable =
  ## getTrigger
  ## Retrieves the definition of a trigger.
  ##   body: JObject (required)
  var body_614462 = newJObject()
  if body != nil:
    body_614462 = body
  result = call_614461.call(nil, nil, nil, nil, body_614462)

var getTrigger* = Call_GetTrigger_614448(name: "getTrigger",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetTrigger",
                                      validator: validate_GetTrigger_614449,
                                      base: "/", url: url_GetTrigger_614450,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTriggers_614463 = ref object of OpenApiRestCall_612658
proc url_GetTriggers_614465(protocol: Scheme; host: string; base: string;
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

proc validate_GetTriggers_614464(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614466 = query.getOrDefault("MaxResults")
  valid_614466 = validateParameter(valid_614466, JString, required = false,
                                 default = nil)
  if valid_614466 != nil:
    section.add "MaxResults", valid_614466
  var valid_614467 = query.getOrDefault("NextToken")
  valid_614467 = validateParameter(valid_614467, JString, required = false,
                                 default = nil)
  if valid_614467 != nil:
    section.add "NextToken", valid_614467
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
  var valid_614468 = header.getOrDefault("X-Amz-Target")
  valid_614468 = validateParameter(valid_614468, JString, required = true,
                                 default = newJString("AWSGlue.GetTriggers"))
  if valid_614468 != nil:
    section.add "X-Amz-Target", valid_614468
  var valid_614469 = header.getOrDefault("X-Amz-Signature")
  valid_614469 = validateParameter(valid_614469, JString, required = false,
                                 default = nil)
  if valid_614469 != nil:
    section.add "X-Amz-Signature", valid_614469
  var valid_614470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614470 = validateParameter(valid_614470, JString, required = false,
                                 default = nil)
  if valid_614470 != nil:
    section.add "X-Amz-Content-Sha256", valid_614470
  var valid_614471 = header.getOrDefault("X-Amz-Date")
  valid_614471 = validateParameter(valid_614471, JString, required = false,
                                 default = nil)
  if valid_614471 != nil:
    section.add "X-Amz-Date", valid_614471
  var valid_614472 = header.getOrDefault("X-Amz-Credential")
  valid_614472 = validateParameter(valid_614472, JString, required = false,
                                 default = nil)
  if valid_614472 != nil:
    section.add "X-Amz-Credential", valid_614472
  var valid_614473 = header.getOrDefault("X-Amz-Security-Token")
  valid_614473 = validateParameter(valid_614473, JString, required = false,
                                 default = nil)
  if valid_614473 != nil:
    section.add "X-Amz-Security-Token", valid_614473
  var valid_614474 = header.getOrDefault("X-Amz-Algorithm")
  valid_614474 = validateParameter(valid_614474, JString, required = false,
                                 default = nil)
  if valid_614474 != nil:
    section.add "X-Amz-Algorithm", valid_614474
  var valid_614475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614475 = validateParameter(valid_614475, JString, required = false,
                                 default = nil)
  if valid_614475 != nil:
    section.add "X-Amz-SignedHeaders", valid_614475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614477: Call_GetTriggers_614463; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the triggers associated with a job.
  ## 
  let valid = call_614477.validator(path, query, header, formData, body)
  let scheme = call_614477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614477.url(scheme.get, call_614477.host, call_614477.base,
                         call_614477.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614477, url, valid)

proc call*(call_614478: Call_GetTriggers_614463; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getTriggers
  ## Gets all the triggers associated with a job.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614479 = newJObject()
  var body_614480 = newJObject()
  add(query_614479, "MaxResults", newJString(MaxResults))
  add(query_614479, "NextToken", newJString(NextToken))
  if body != nil:
    body_614480 = body
  result = call_614478.call(nil, query_614479, nil, nil, body_614480)

var getTriggers* = Call_GetTriggers_614463(name: "getTriggers",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetTriggers",
                                        validator: validate_GetTriggers_614464,
                                        base: "/", url: url_GetTriggers_614465,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserDefinedFunction_614481 = ref object of OpenApiRestCall_612658
proc url_GetUserDefinedFunction_614483(protocol: Scheme; host: string; base: string;
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

proc validate_GetUserDefinedFunction_614482(path: JsonNode; query: JsonNode;
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
  var valid_614484 = header.getOrDefault("X-Amz-Target")
  valid_614484 = validateParameter(valid_614484, JString, required = true, default = newJString(
      "AWSGlue.GetUserDefinedFunction"))
  if valid_614484 != nil:
    section.add "X-Amz-Target", valid_614484
  var valid_614485 = header.getOrDefault("X-Amz-Signature")
  valid_614485 = validateParameter(valid_614485, JString, required = false,
                                 default = nil)
  if valid_614485 != nil:
    section.add "X-Amz-Signature", valid_614485
  var valid_614486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614486 = validateParameter(valid_614486, JString, required = false,
                                 default = nil)
  if valid_614486 != nil:
    section.add "X-Amz-Content-Sha256", valid_614486
  var valid_614487 = header.getOrDefault("X-Amz-Date")
  valid_614487 = validateParameter(valid_614487, JString, required = false,
                                 default = nil)
  if valid_614487 != nil:
    section.add "X-Amz-Date", valid_614487
  var valid_614488 = header.getOrDefault("X-Amz-Credential")
  valid_614488 = validateParameter(valid_614488, JString, required = false,
                                 default = nil)
  if valid_614488 != nil:
    section.add "X-Amz-Credential", valid_614488
  var valid_614489 = header.getOrDefault("X-Amz-Security-Token")
  valid_614489 = validateParameter(valid_614489, JString, required = false,
                                 default = nil)
  if valid_614489 != nil:
    section.add "X-Amz-Security-Token", valid_614489
  var valid_614490 = header.getOrDefault("X-Amz-Algorithm")
  valid_614490 = validateParameter(valid_614490, JString, required = false,
                                 default = nil)
  if valid_614490 != nil:
    section.add "X-Amz-Algorithm", valid_614490
  var valid_614491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614491 = validateParameter(valid_614491, JString, required = false,
                                 default = nil)
  if valid_614491 != nil:
    section.add "X-Amz-SignedHeaders", valid_614491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614493: Call_GetUserDefinedFunction_614481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified function definition from the Data Catalog.
  ## 
  let valid = call_614493.validator(path, query, header, formData, body)
  let scheme = call_614493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614493.url(scheme.get, call_614493.host, call_614493.base,
                         call_614493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614493, url, valid)

proc call*(call_614494: Call_GetUserDefinedFunction_614481; body: JsonNode): Recallable =
  ## getUserDefinedFunction
  ## Retrieves a specified function definition from the Data Catalog.
  ##   body: JObject (required)
  var body_614495 = newJObject()
  if body != nil:
    body_614495 = body
  result = call_614494.call(nil, nil, nil, nil, body_614495)

var getUserDefinedFunction* = Call_GetUserDefinedFunction_614481(
    name: "getUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetUserDefinedFunction",
    validator: validate_GetUserDefinedFunction_614482, base: "/",
    url: url_GetUserDefinedFunction_614483, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserDefinedFunctions_614496 = ref object of OpenApiRestCall_612658
proc url_GetUserDefinedFunctions_614498(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUserDefinedFunctions_614497(path: JsonNode; query: JsonNode;
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
  var valid_614499 = query.getOrDefault("MaxResults")
  valid_614499 = validateParameter(valid_614499, JString, required = false,
                                 default = nil)
  if valid_614499 != nil:
    section.add "MaxResults", valid_614499
  var valid_614500 = query.getOrDefault("NextToken")
  valid_614500 = validateParameter(valid_614500, JString, required = false,
                                 default = nil)
  if valid_614500 != nil:
    section.add "NextToken", valid_614500
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
  var valid_614501 = header.getOrDefault("X-Amz-Target")
  valid_614501 = validateParameter(valid_614501, JString, required = true, default = newJString(
      "AWSGlue.GetUserDefinedFunctions"))
  if valid_614501 != nil:
    section.add "X-Amz-Target", valid_614501
  var valid_614502 = header.getOrDefault("X-Amz-Signature")
  valid_614502 = validateParameter(valid_614502, JString, required = false,
                                 default = nil)
  if valid_614502 != nil:
    section.add "X-Amz-Signature", valid_614502
  var valid_614503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614503 = validateParameter(valid_614503, JString, required = false,
                                 default = nil)
  if valid_614503 != nil:
    section.add "X-Amz-Content-Sha256", valid_614503
  var valid_614504 = header.getOrDefault("X-Amz-Date")
  valid_614504 = validateParameter(valid_614504, JString, required = false,
                                 default = nil)
  if valid_614504 != nil:
    section.add "X-Amz-Date", valid_614504
  var valid_614505 = header.getOrDefault("X-Amz-Credential")
  valid_614505 = validateParameter(valid_614505, JString, required = false,
                                 default = nil)
  if valid_614505 != nil:
    section.add "X-Amz-Credential", valid_614505
  var valid_614506 = header.getOrDefault("X-Amz-Security-Token")
  valid_614506 = validateParameter(valid_614506, JString, required = false,
                                 default = nil)
  if valid_614506 != nil:
    section.add "X-Amz-Security-Token", valid_614506
  var valid_614507 = header.getOrDefault("X-Amz-Algorithm")
  valid_614507 = validateParameter(valid_614507, JString, required = false,
                                 default = nil)
  if valid_614507 != nil:
    section.add "X-Amz-Algorithm", valid_614507
  var valid_614508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614508 = validateParameter(valid_614508, JString, required = false,
                                 default = nil)
  if valid_614508 != nil:
    section.add "X-Amz-SignedHeaders", valid_614508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614510: Call_GetUserDefinedFunctions_614496; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves multiple function definitions from the Data Catalog.
  ## 
  let valid = call_614510.validator(path, query, header, formData, body)
  let scheme = call_614510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614510.url(scheme.get, call_614510.host, call_614510.base,
                         call_614510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614510, url, valid)

proc call*(call_614511: Call_GetUserDefinedFunctions_614496; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getUserDefinedFunctions
  ## Retrieves multiple function definitions from the Data Catalog.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614512 = newJObject()
  var body_614513 = newJObject()
  add(query_614512, "MaxResults", newJString(MaxResults))
  add(query_614512, "NextToken", newJString(NextToken))
  if body != nil:
    body_614513 = body
  result = call_614511.call(nil, query_614512, nil, nil, body_614513)

var getUserDefinedFunctions* = Call_GetUserDefinedFunctions_614496(
    name: "getUserDefinedFunctions", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetUserDefinedFunctions",
    validator: validate_GetUserDefinedFunctions_614497, base: "/",
    url: url_GetUserDefinedFunctions_614498, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflow_614514 = ref object of OpenApiRestCall_612658
proc url_GetWorkflow_614516(protocol: Scheme; host: string; base: string;
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

proc validate_GetWorkflow_614515(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614517 = header.getOrDefault("X-Amz-Target")
  valid_614517 = validateParameter(valid_614517, JString, required = true,
                                 default = newJString("AWSGlue.GetWorkflow"))
  if valid_614517 != nil:
    section.add "X-Amz-Target", valid_614517
  var valid_614518 = header.getOrDefault("X-Amz-Signature")
  valid_614518 = validateParameter(valid_614518, JString, required = false,
                                 default = nil)
  if valid_614518 != nil:
    section.add "X-Amz-Signature", valid_614518
  var valid_614519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614519 = validateParameter(valid_614519, JString, required = false,
                                 default = nil)
  if valid_614519 != nil:
    section.add "X-Amz-Content-Sha256", valid_614519
  var valid_614520 = header.getOrDefault("X-Amz-Date")
  valid_614520 = validateParameter(valid_614520, JString, required = false,
                                 default = nil)
  if valid_614520 != nil:
    section.add "X-Amz-Date", valid_614520
  var valid_614521 = header.getOrDefault("X-Amz-Credential")
  valid_614521 = validateParameter(valid_614521, JString, required = false,
                                 default = nil)
  if valid_614521 != nil:
    section.add "X-Amz-Credential", valid_614521
  var valid_614522 = header.getOrDefault("X-Amz-Security-Token")
  valid_614522 = validateParameter(valid_614522, JString, required = false,
                                 default = nil)
  if valid_614522 != nil:
    section.add "X-Amz-Security-Token", valid_614522
  var valid_614523 = header.getOrDefault("X-Amz-Algorithm")
  valid_614523 = validateParameter(valid_614523, JString, required = false,
                                 default = nil)
  if valid_614523 != nil:
    section.add "X-Amz-Algorithm", valid_614523
  var valid_614524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614524 = validateParameter(valid_614524, JString, required = false,
                                 default = nil)
  if valid_614524 != nil:
    section.add "X-Amz-SignedHeaders", valid_614524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614526: Call_GetWorkflow_614514; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves resource metadata for a workflow.
  ## 
  let valid = call_614526.validator(path, query, header, formData, body)
  let scheme = call_614526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614526.url(scheme.get, call_614526.host, call_614526.base,
                         call_614526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614526, url, valid)

proc call*(call_614527: Call_GetWorkflow_614514; body: JsonNode): Recallable =
  ## getWorkflow
  ## Retrieves resource metadata for a workflow.
  ##   body: JObject (required)
  var body_614528 = newJObject()
  if body != nil:
    body_614528 = body
  result = call_614527.call(nil, nil, nil, nil, body_614528)

var getWorkflow* = Call_GetWorkflow_614514(name: "getWorkflow",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetWorkflow",
                                        validator: validate_GetWorkflow_614515,
                                        base: "/", url: url_GetWorkflow_614516,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRun_614529 = ref object of OpenApiRestCall_612658
proc url_GetWorkflowRun_614531(protocol: Scheme; host: string; base: string;
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

proc validate_GetWorkflowRun_614530(path: JsonNode; query: JsonNode;
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
  var valid_614532 = header.getOrDefault("X-Amz-Target")
  valid_614532 = validateParameter(valid_614532, JString, required = true,
                                 default = newJString("AWSGlue.GetWorkflowRun"))
  if valid_614532 != nil:
    section.add "X-Amz-Target", valid_614532
  var valid_614533 = header.getOrDefault("X-Amz-Signature")
  valid_614533 = validateParameter(valid_614533, JString, required = false,
                                 default = nil)
  if valid_614533 != nil:
    section.add "X-Amz-Signature", valid_614533
  var valid_614534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614534 = validateParameter(valid_614534, JString, required = false,
                                 default = nil)
  if valid_614534 != nil:
    section.add "X-Amz-Content-Sha256", valid_614534
  var valid_614535 = header.getOrDefault("X-Amz-Date")
  valid_614535 = validateParameter(valid_614535, JString, required = false,
                                 default = nil)
  if valid_614535 != nil:
    section.add "X-Amz-Date", valid_614535
  var valid_614536 = header.getOrDefault("X-Amz-Credential")
  valid_614536 = validateParameter(valid_614536, JString, required = false,
                                 default = nil)
  if valid_614536 != nil:
    section.add "X-Amz-Credential", valid_614536
  var valid_614537 = header.getOrDefault("X-Amz-Security-Token")
  valid_614537 = validateParameter(valid_614537, JString, required = false,
                                 default = nil)
  if valid_614537 != nil:
    section.add "X-Amz-Security-Token", valid_614537
  var valid_614538 = header.getOrDefault("X-Amz-Algorithm")
  valid_614538 = validateParameter(valid_614538, JString, required = false,
                                 default = nil)
  if valid_614538 != nil:
    section.add "X-Amz-Algorithm", valid_614538
  var valid_614539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614539 = validateParameter(valid_614539, JString, required = false,
                                 default = nil)
  if valid_614539 != nil:
    section.add "X-Amz-SignedHeaders", valid_614539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614541: Call_GetWorkflowRun_614529; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the metadata for a given workflow run. 
  ## 
  let valid = call_614541.validator(path, query, header, formData, body)
  let scheme = call_614541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614541.url(scheme.get, call_614541.host, call_614541.base,
                         call_614541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614541, url, valid)

proc call*(call_614542: Call_GetWorkflowRun_614529; body: JsonNode): Recallable =
  ## getWorkflowRun
  ## Retrieves the metadata for a given workflow run. 
  ##   body: JObject (required)
  var body_614543 = newJObject()
  if body != nil:
    body_614543 = body
  result = call_614542.call(nil, nil, nil, nil, body_614543)

var getWorkflowRun* = Call_GetWorkflowRun_614529(name: "getWorkflowRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRun",
    validator: validate_GetWorkflowRun_614530, base: "/", url: url_GetWorkflowRun_614531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRunProperties_614544 = ref object of OpenApiRestCall_612658
proc url_GetWorkflowRunProperties_614546(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetWorkflowRunProperties_614545(path: JsonNode; query: JsonNode;
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
  var valid_614547 = header.getOrDefault("X-Amz-Target")
  valid_614547 = validateParameter(valid_614547, JString, required = true, default = newJString(
      "AWSGlue.GetWorkflowRunProperties"))
  if valid_614547 != nil:
    section.add "X-Amz-Target", valid_614547
  var valid_614548 = header.getOrDefault("X-Amz-Signature")
  valid_614548 = validateParameter(valid_614548, JString, required = false,
                                 default = nil)
  if valid_614548 != nil:
    section.add "X-Amz-Signature", valid_614548
  var valid_614549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614549 = validateParameter(valid_614549, JString, required = false,
                                 default = nil)
  if valid_614549 != nil:
    section.add "X-Amz-Content-Sha256", valid_614549
  var valid_614550 = header.getOrDefault("X-Amz-Date")
  valid_614550 = validateParameter(valid_614550, JString, required = false,
                                 default = nil)
  if valid_614550 != nil:
    section.add "X-Amz-Date", valid_614550
  var valid_614551 = header.getOrDefault("X-Amz-Credential")
  valid_614551 = validateParameter(valid_614551, JString, required = false,
                                 default = nil)
  if valid_614551 != nil:
    section.add "X-Amz-Credential", valid_614551
  var valid_614552 = header.getOrDefault("X-Amz-Security-Token")
  valid_614552 = validateParameter(valid_614552, JString, required = false,
                                 default = nil)
  if valid_614552 != nil:
    section.add "X-Amz-Security-Token", valid_614552
  var valid_614553 = header.getOrDefault("X-Amz-Algorithm")
  valid_614553 = validateParameter(valid_614553, JString, required = false,
                                 default = nil)
  if valid_614553 != nil:
    section.add "X-Amz-Algorithm", valid_614553
  var valid_614554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614554 = validateParameter(valid_614554, JString, required = false,
                                 default = nil)
  if valid_614554 != nil:
    section.add "X-Amz-SignedHeaders", valid_614554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614556: Call_GetWorkflowRunProperties_614544; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the workflow run properties which were set during the run.
  ## 
  let valid = call_614556.validator(path, query, header, formData, body)
  let scheme = call_614556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614556.url(scheme.get, call_614556.host, call_614556.base,
                         call_614556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614556, url, valid)

proc call*(call_614557: Call_GetWorkflowRunProperties_614544; body: JsonNode): Recallable =
  ## getWorkflowRunProperties
  ## Retrieves the workflow run properties which were set during the run.
  ##   body: JObject (required)
  var body_614558 = newJObject()
  if body != nil:
    body_614558 = body
  result = call_614557.call(nil, nil, nil, nil, body_614558)

var getWorkflowRunProperties* = Call_GetWorkflowRunProperties_614544(
    name: "getWorkflowRunProperties", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRunProperties",
    validator: validate_GetWorkflowRunProperties_614545, base: "/",
    url: url_GetWorkflowRunProperties_614546, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRuns_614559 = ref object of OpenApiRestCall_612658
proc url_GetWorkflowRuns_614561(protocol: Scheme; host: string; base: string;
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

proc validate_GetWorkflowRuns_614560(path: JsonNode; query: JsonNode;
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
  var valid_614562 = query.getOrDefault("MaxResults")
  valid_614562 = validateParameter(valid_614562, JString, required = false,
                                 default = nil)
  if valid_614562 != nil:
    section.add "MaxResults", valid_614562
  var valid_614563 = query.getOrDefault("NextToken")
  valid_614563 = validateParameter(valid_614563, JString, required = false,
                                 default = nil)
  if valid_614563 != nil:
    section.add "NextToken", valid_614563
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
  var valid_614564 = header.getOrDefault("X-Amz-Target")
  valid_614564 = validateParameter(valid_614564, JString, required = true, default = newJString(
      "AWSGlue.GetWorkflowRuns"))
  if valid_614564 != nil:
    section.add "X-Amz-Target", valid_614564
  var valid_614565 = header.getOrDefault("X-Amz-Signature")
  valid_614565 = validateParameter(valid_614565, JString, required = false,
                                 default = nil)
  if valid_614565 != nil:
    section.add "X-Amz-Signature", valid_614565
  var valid_614566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614566 = validateParameter(valid_614566, JString, required = false,
                                 default = nil)
  if valid_614566 != nil:
    section.add "X-Amz-Content-Sha256", valid_614566
  var valid_614567 = header.getOrDefault("X-Amz-Date")
  valid_614567 = validateParameter(valid_614567, JString, required = false,
                                 default = nil)
  if valid_614567 != nil:
    section.add "X-Amz-Date", valid_614567
  var valid_614568 = header.getOrDefault("X-Amz-Credential")
  valid_614568 = validateParameter(valid_614568, JString, required = false,
                                 default = nil)
  if valid_614568 != nil:
    section.add "X-Amz-Credential", valid_614568
  var valid_614569 = header.getOrDefault("X-Amz-Security-Token")
  valid_614569 = validateParameter(valid_614569, JString, required = false,
                                 default = nil)
  if valid_614569 != nil:
    section.add "X-Amz-Security-Token", valid_614569
  var valid_614570 = header.getOrDefault("X-Amz-Algorithm")
  valid_614570 = validateParameter(valid_614570, JString, required = false,
                                 default = nil)
  if valid_614570 != nil:
    section.add "X-Amz-Algorithm", valid_614570
  var valid_614571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614571 = validateParameter(valid_614571, JString, required = false,
                                 default = nil)
  if valid_614571 != nil:
    section.add "X-Amz-SignedHeaders", valid_614571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614573: Call_GetWorkflowRuns_614559; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all runs of a given workflow.
  ## 
  let valid = call_614573.validator(path, query, header, formData, body)
  let scheme = call_614573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614573.url(scheme.get, call_614573.host, call_614573.base,
                         call_614573.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614573, url, valid)

proc call*(call_614574: Call_GetWorkflowRuns_614559; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getWorkflowRuns
  ## Retrieves metadata for all runs of a given workflow.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614575 = newJObject()
  var body_614576 = newJObject()
  add(query_614575, "MaxResults", newJString(MaxResults))
  add(query_614575, "NextToken", newJString(NextToken))
  if body != nil:
    body_614576 = body
  result = call_614574.call(nil, query_614575, nil, nil, body_614576)

var getWorkflowRuns* = Call_GetWorkflowRuns_614559(name: "getWorkflowRuns",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRuns",
    validator: validate_GetWorkflowRuns_614560, base: "/", url: url_GetWorkflowRuns_614561,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportCatalogToGlue_614577 = ref object of OpenApiRestCall_612658
proc url_ImportCatalogToGlue_614579(protocol: Scheme; host: string; base: string;
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

proc validate_ImportCatalogToGlue_614578(path: JsonNode; query: JsonNode;
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
  var valid_614580 = header.getOrDefault("X-Amz-Target")
  valid_614580 = validateParameter(valid_614580, JString, required = true, default = newJString(
      "AWSGlue.ImportCatalogToGlue"))
  if valid_614580 != nil:
    section.add "X-Amz-Target", valid_614580
  var valid_614581 = header.getOrDefault("X-Amz-Signature")
  valid_614581 = validateParameter(valid_614581, JString, required = false,
                                 default = nil)
  if valid_614581 != nil:
    section.add "X-Amz-Signature", valid_614581
  var valid_614582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614582 = validateParameter(valid_614582, JString, required = false,
                                 default = nil)
  if valid_614582 != nil:
    section.add "X-Amz-Content-Sha256", valid_614582
  var valid_614583 = header.getOrDefault("X-Amz-Date")
  valid_614583 = validateParameter(valid_614583, JString, required = false,
                                 default = nil)
  if valid_614583 != nil:
    section.add "X-Amz-Date", valid_614583
  var valid_614584 = header.getOrDefault("X-Amz-Credential")
  valid_614584 = validateParameter(valid_614584, JString, required = false,
                                 default = nil)
  if valid_614584 != nil:
    section.add "X-Amz-Credential", valid_614584
  var valid_614585 = header.getOrDefault("X-Amz-Security-Token")
  valid_614585 = validateParameter(valid_614585, JString, required = false,
                                 default = nil)
  if valid_614585 != nil:
    section.add "X-Amz-Security-Token", valid_614585
  var valid_614586 = header.getOrDefault("X-Amz-Algorithm")
  valid_614586 = validateParameter(valid_614586, JString, required = false,
                                 default = nil)
  if valid_614586 != nil:
    section.add "X-Amz-Algorithm", valid_614586
  var valid_614587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614587 = validateParameter(valid_614587, JString, required = false,
                                 default = nil)
  if valid_614587 != nil:
    section.add "X-Amz-SignedHeaders", valid_614587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614589: Call_ImportCatalogToGlue_614577; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
  ## 
  let valid = call_614589.validator(path, query, header, formData, body)
  let scheme = call_614589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614589.url(scheme.get, call_614589.host, call_614589.base,
                         call_614589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614589, url, valid)

proc call*(call_614590: Call_ImportCatalogToGlue_614577; body: JsonNode): Recallable =
  ## importCatalogToGlue
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
  ##   body: JObject (required)
  var body_614591 = newJObject()
  if body != nil:
    body_614591 = body
  result = call_614590.call(nil, nil, nil, nil, body_614591)

var importCatalogToGlue* = Call_ImportCatalogToGlue_614577(
    name: "importCatalogToGlue", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ImportCatalogToGlue",
    validator: validate_ImportCatalogToGlue_614578, base: "/",
    url: url_ImportCatalogToGlue_614579, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCrawlers_614592 = ref object of OpenApiRestCall_612658
proc url_ListCrawlers_614594(protocol: Scheme; host: string; base: string;
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

proc validate_ListCrawlers_614593(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614595 = query.getOrDefault("MaxResults")
  valid_614595 = validateParameter(valid_614595, JString, required = false,
                                 default = nil)
  if valid_614595 != nil:
    section.add "MaxResults", valid_614595
  var valid_614596 = query.getOrDefault("NextToken")
  valid_614596 = validateParameter(valid_614596, JString, required = false,
                                 default = nil)
  if valid_614596 != nil:
    section.add "NextToken", valid_614596
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
  var valid_614597 = header.getOrDefault("X-Amz-Target")
  valid_614597 = validateParameter(valid_614597, JString, required = true,
                                 default = newJString("AWSGlue.ListCrawlers"))
  if valid_614597 != nil:
    section.add "X-Amz-Target", valid_614597
  var valid_614598 = header.getOrDefault("X-Amz-Signature")
  valid_614598 = validateParameter(valid_614598, JString, required = false,
                                 default = nil)
  if valid_614598 != nil:
    section.add "X-Amz-Signature", valid_614598
  var valid_614599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614599 = validateParameter(valid_614599, JString, required = false,
                                 default = nil)
  if valid_614599 != nil:
    section.add "X-Amz-Content-Sha256", valid_614599
  var valid_614600 = header.getOrDefault("X-Amz-Date")
  valid_614600 = validateParameter(valid_614600, JString, required = false,
                                 default = nil)
  if valid_614600 != nil:
    section.add "X-Amz-Date", valid_614600
  var valid_614601 = header.getOrDefault("X-Amz-Credential")
  valid_614601 = validateParameter(valid_614601, JString, required = false,
                                 default = nil)
  if valid_614601 != nil:
    section.add "X-Amz-Credential", valid_614601
  var valid_614602 = header.getOrDefault("X-Amz-Security-Token")
  valid_614602 = validateParameter(valid_614602, JString, required = false,
                                 default = nil)
  if valid_614602 != nil:
    section.add "X-Amz-Security-Token", valid_614602
  var valid_614603 = header.getOrDefault("X-Amz-Algorithm")
  valid_614603 = validateParameter(valid_614603, JString, required = false,
                                 default = nil)
  if valid_614603 != nil:
    section.add "X-Amz-Algorithm", valid_614603
  var valid_614604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614604 = validateParameter(valid_614604, JString, required = false,
                                 default = nil)
  if valid_614604 != nil:
    section.add "X-Amz-SignedHeaders", valid_614604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614606: Call_ListCrawlers_614592; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_614606.validator(path, query, header, formData, body)
  let scheme = call_614606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614606.url(scheme.get, call_614606.host, call_614606.base,
                         call_614606.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614606, url, valid)

proc call*(call_614607: Call_ListCrawlers_614592; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCrawlers
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614608 = newJObject()
  var body_614609 = newJObject()
  add(query_614608, "MaxResults", newJString(MaxResults))
  add(query_614608, "NextToken", newJString(NextToken))
  if body != nil:
    body_614609 = body
  result = call_614607.call(nil, query_614608, nil, nil, body_614609)

var listCrawlers* = Call_ListCrawlers_614592(name: "listCrawlers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListCrawlers",
    validator: validate_ListCrawlers_614593, base: "/", url: url_ListCrawlers_614594,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevEndpoints_614610 = ref object of OpenApiRestCall_612658
proc url_ListDevEndpoints_614612(protocol: Scheme; host: string; base: string;
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

proc validate_ListDevEndpoints_614611(path: JsonNode; query: JsonNode;
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
  var valid_614613 = query.getOrDefault("MaxResults")
  valid_614613 = validateParameter(valid_614613, JString, required = false,
                                 default = nil)
  if valid_614613 != nil:
    section.add "MaxResults", valid_614613
  var valid_614614 = query.getOrDefault("NextToken")
  valid_614614 = validateParameter(valid_614614, JString, required = false,
                                 default = nil)
  if valid_614614 != nil:
    section.add "NextToken", valid_614614
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
  var valid_614615 = header.getOrDefault("X-Amz-Target")
  valid_614615 = validateParameter(valid_614615, JString, required = true, default = newJString(
      "AWSGlue.ListDevEndpoints"))
  if valid_614615 != nil:
    section.add "X-Amz-Target", valid_614615
  var valid_614616 = header.getOrDefault("X-Amz-Signature")
  valid_614616 = validateParameter(valid_614616, JString, required = false,
                                 default = nil)
  if valid_614616 != nil:
    section.add "X-Amz-Signature", valid_614616
  var valid_614617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614617 = validateParameter(valid_614617, JString, required = false,
                                 default = nil)
  if valid_614617 != nil:
    section.add "X-Amz-Content-Sha256", valid_614617
  var valid_614618 = header.getOrDefault("X-Amz-Date")
  valid_614618 = validateParameter(valid_614618, JString, required = false,
                                 default = nil)
  if valid_614618 != nil:
    section.add "X-Amz-Date", valid_614618
  var valid_614619 = header.getOrDefault("X-Amz-Credential")
  valid_614619 = validateParameter(valid_614619, JString, required = false,
                                 default = nil)
  if valid_614619 != nil:
    section.add "X-Amz-Credential", valid_614619
  var valid_614620 = header.getOrDefault("X-Amz-Security-Token")
  valid_614620 = validateParameter(valid_614620, JString, required = false,
                                 default = nil)
  if valid_614620 != nil:
    section.add "X-Amz-Security-Token", valid_614620
  var valid_614621 = header.getOrDefault("X-Amz-Algorithm")
  valid_614621 = validateParameter(valid_614621, JString, required = false,
                                 default = nil)
  if valid_614621 != nil:
    section.add "X-Amz-Algorithm", valid_614621
  var valid_614622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614622 = validateParameter(valid_614622, JString, required = false,
                                 default = nil)
  if valid_614622 != nil:
    section.add "X-Amz-SignedHeaders", valid_614622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614624: Call_ListDevEndpoints_614610; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_614624.validator(path, query, header, formData, body)
  let scheme = call_614624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614624.url(scheme.get, call_614624.host, call_614624.base,
                         call_614624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614624, url, valid)

proc call*(call_614625: Call_ListDevEndpoints_614610; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDevEndpoints
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614626 = newJObject()
  var body_614627 = newJObject()
  add(query_614626, "MaxResults", newJString(MaxResults))
  add(query_614626, "NextToken", newJString(NextToken))
  if body != nil:
    body_614627 = body
  result = call_614625.call(nil, query_614626, nil, nil, body_614627)

var listDevEndpoints* = Call_ListDevEndpoints_614610(name: "listDevEndpoints",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListDevEndpoints",
    validator: validate_ListDevEndpoints_614611, base: "/",
    url: url_ListDevEndpoints_614612, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_614628 = ref object of OpenApiRestCall_612658
proc url_ListJobs_614630(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListJobs_614629(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614631 = query.getOrDefault("MaxResults")
  valid_614631 = validateParameter(valid_614631, JString, required = false,
                                 default = nil)
  if valid_614631 != nil:
    section.add "MaxResults", valid_614631
  var valid_614632 = query.getOrDefault("NextToken")
  valid_614632 = validateParameter(valid_614632, JString, required = false,
                                 default = nil)
  if valid_614632 != nil:
    section.add "NextToken", valid_614632
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
  var valid_614633 = header.getOrDefault("X-Amz-Target")
  valid_614633 = validateParameter(valid_614633, JString, required = true,
                                 default = newJString("AWSGlue.ListJobs"))
  if valid_614633 != nil:
    section.add "X-Amz-Target", valid_614633
  var valid_614634 = header.getOrDefault("X-Amz-Signature")
  valid_614634 = validateParameter(valid_614634, JString, required = false,
                                 default = nil)
  if valid_614634 != nil:
    section.add "X-Amz-Signature", valid_614634
  var valid_614635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614635 = validateParameter(valid_614635, JString, required = false,
                                 default = nil)
  if valid_614635 != nil:
    section.add "X-Amz-Content-Sha256", valid_614635
  var valid_614636 = header.getOrDefault("X-Amz-Date")
  valid_614636 = validateParameter(valid_614636, JString, required = false,
                                 default = nil)
  if valid_614636 != nil:
    section.add "X-Amz-Date", valid_614636
  var valid_614637 = header.getOrDefault("X-Amz-Credential")
  valid_614637 = validateParameter(valid_614637, JString, required = false,
                                 default = nil)
  if valid_614637 != nil:
    section.add "X-Amz-Credential", valid_614637
  var valid_614638 = header.getOrDefault("X-Amz-Security-Token")
  valid_614638 = validateParameter(valid_614638, JString, required = false,
                                 default = nil)
  if valid_614638 != nil:
    section.add "X-Amz-Security-Token", valid_614638
  var valid_614639 = header.getOrDefault("X-Amz-Algorithm")
  valid_614639 = validateParameter(valid_614639, JString, required = false,
                                 default = nil)
  if valid_614639 != nil:
    section.add "X-Amz-Algorithm", valid_614639
  var valid_614640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614640 = validateParameter(valid_614640, JString, required = false,
                                 default = nil)
  if valid_614640 != nil:
    section.add "X-Amz-SignedHeaders", valid_614640
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614642: Call_ListJobs_614628; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_614642.validator(path, query, header, formData, body)
  let scheme = call_614642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614642.url(scheme.get, call_614642.host, call_614642.base,
                         call_614642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614642, url, valid)

proc call*(call_614643: Call_ListJobs_614628; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listJobs
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614644 = newJObject()
  var body_614645 = newJObject()
  add(query_614644, "MaxResults", newJString(MaxResults))
  add(query_614644, "NextToken", newJString(NextToken))
  if body != nil:
    body_614645 = body
  result = call_614643.call(nil, query_614644, nil, nil, body_614645)

var listJobs* = Call_ListJobs_614628(name: "listJobs", meth: HttpMethod.HttpPost,
                                  host: "glue.amazonaws.com",
                                  route: "/#X-Amz-Target=AWSGlue.ListJobs",
                                  validator: validate_ListJobs_614629, base: "/",
                                  url: url_ListJobs_614630,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTriggers_614646 = ref object of OpenApiRestCall_612658
proc url_ListTriggers_614648(protocol: Scheme; host: string; base: string;
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

proc validate_ListTriggers_614647(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614649 = query.getOrDefault("MaxResults")
  valid_614649 = validateParameter(valid_614649, JString, required = false,
                                 default = nil)
  if valid_614649 != nil:
    section.add "MaxResults", valid_614649
  var valid_614650 = query.getOrDefault("NextToken")
  valid_614650 = validateParameter(valid_614650, JString, required = false,
                                 default = nil)
  if valid_614650 != nil:
    section.add "NextToken", valid_614650
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
  var valid_614651 = header.getOrDefault("X-Amz-Target")
  valid_614651 = validateParameter(valid_614651, JString, required = true,
                                 default = newJString("AWSGlue.ListTriggers"))
  if valid_614651 != nil:
    section.add "X-Amz-Target", valid_614651
  var valid_614652 = header.getOrDefault("X-Amz-Signature")
  valid_614652 = validateParameter(valid_614652, JString, required = false,
                                 default = nil)
  if valid_614652 != nil:
    section.add "X-Amz-Signature", valid_614652
  var valid_614653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614653 = validateParameter(valid_614653, JString, required = false,
                                 default = nil)
  if valid_614653 != nil:
    section.add "X-Amz-Content-Sha256", valid_614653
  var valid_614654 = header.getOrDefault("X-Amz-Date")
  valid_614654 = validateParameter(valid_614654, JString, required = false,
                                 default = nil)
  if valid_614654 != nil:
    section.add "X-Amz-Date", valid_614654
  var valid_614655 = header.getOrDefault("X-Amz-Credential")
  valid_614655 = validateParameter(valid_614655, JString, required = false,
                                 default = nil)
  if valid_614655 != nil:
    section.add "X-Amz-Credential", valid_614655
  var valid_614656 = header.getOrDefault("X-Amz-Security-Token")
  valid_614656 = validateParameter(valid_614656, JString, required = false,
                                 default = nil)
  if valid_614656 != nil:
    section.add "X-Amz-Security-Token", valid_614656
  var valid_614657 = header.getOrDefault("X-Amz-Algorithm")
  valid_614657 = validateParameter(valid_614657, JString, required = false,
                                 default = nil)
  if valid_614657 != nil:
    section.add "X-Amz-Algorithm", valid_614657
  var valid_614658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614658 = validateParameter(valid_614658, JString, required = false,
                                 default = nil)
  if valid_614658 != nil:
    section.add "X-Amz-SignedHeaders", valid_614658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614660: Call_ListTriggers_614646; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_614660.validator(path, query, header, formData, body)
  let scheme = call_614660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614660.url(scheme.get, call_614660.host, call_614660.base,
                         call_614660.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614660, url, valid)

proc call*(call_614661: Call_ListTriggers_614646; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTriggers
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614662 = newJObject()
  var body_614663 = newJObject()
  add(query_614662, "MaxResults", newJString(MaxResults))
  add(query_614662, "NextToken", newJString(NextToken))
  if body != nil:
    body_614663 = body
  result = call_614661.call(nil, query_614662, nil, nil, body_614663)

var listTriggers* = Call_ListTriggers_614646(name: "listTriggers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListTriggers",
    validator: validate_ListTriggers_614647, base: "/", url: url_ListTriggers_614648,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkflows_614664 = ref object of OpenApiRestCall_612658
proc url_ListWorkflows_614666(protocol: Scheme; host: string; base: string;
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

proc validate_ListWorkflows_614665(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614667 = query.getOrDefault("MaxResults")
  valid_614667 = validateParameter(valid_614667, JString, required = false,
                                 default = nil)
  if valid_614667 != nil:
    section.add "MaxResults", valid_614667
  var valid_614668 = query.getOrDefault("NextToken")
  valid_614668 = validateParameter(valid_614668, JString, required = false,
                                 default = nil)
  if valid_614668 != nil:
    section.add "NextToken", valid_614668
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
  var valid_614669 = header.getOrDefault("X-Amz-Target")
  valid_614669 = validateParameter(valid_614669, JString, required = true,
                                 default = newJString("AWSGlue.ListWorkflows"))
  if valid_614669 != nil:
    section.add "X-Amz-Target", valid_614669
  var valid_614670 = header.getOrDefault("X-Amz-Signature")
  valid_614670 = validateParameter(valid_614670, JString, required = false,
                                 default = nil)
  if valid_614670 != nil:
    section.add "X-Amz-Signature", valid_614670
  var valid_614671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614671 = validateParameter(valid_614671, JString, required = false,
                                 default = nil)
  if valid_614671 != nil:
    section.add "X-Amz-Content-Sha256", valid_614671
  var valid_614672 = header.getOrDefault("X-Amz-Date")
  valid_614672 = validateParameter(valid_614672, JString, required = false,
                                 default = nil)
  if valid_614672 != nil:
    section.add "X-Amz-Date", valid_614672
  var valid_614673 = header.getOrDefault("X-Amz-Credential")
  valid_614673 = validateParameter(valid_614673, JString, required = false,
                                 default = nil)
  if valid_614673 != nil:
    section.add "X-Amz-Credential", valid_614673
  var valid_614674 = header.getOrDefault("X-Amz-Security-Token")
  valid_614674 = validateParameter(valid_614674, JString, required = false,
                                 default = nil)
  if valid_614674 != nil:
    section.add "X-Amz-Security-Token", valid_614674
  var valid_614675 = header.getOrDefault("X-Amz-Algorithm")
  valid_614675 = validateParameter(valid_614675, JString, required = false,
                                 default = nil)
  if valid_614675 != nil:
    section.add "X-Amz-Algorithm", valid_614675
  var valid_614676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614676 = validateParameter(valid_614676, JString, required = false,
                                 default = nil)
  if valid_614676 != nil:
    section.add "X-Amz-SignedHeaders", valid_614676
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614678: Call_ListWorkflows_614664; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists names of workflows created in the account.
  ## 
  let valid = call_614678.validator(path, query, header, formData, body)
  let scheme = call_614678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614678.url(scheme.get, call_614678.host, call_614678.base,
                         call_614678.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614678, url, valid)

proc call*(call_614679: Call_ListWorkflows_614664; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listWorkflows
  ## Lists names of workflows created in the account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614680 = newJObject()
  var body_614681 = newJObject()
  add(query_614680, "MaxResults", newJString(MaxResults))
  add(query_614680, "NextToken", newJString(NextToken))
  if body != nil:
    body_614681 = body
  result = call_614679.call(nil, query_614680, nil, nil, body_614681)

var listWorkflows* = Call_ListWorkflows_614664(name: "listWorkflows",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListWorkflows",
    validator: validate_ListWorkflows_614665, base: "/", url: url_ListWorkflows_614666,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDataCatalogEncryptionSettings_614682 = ref object of OpenApiRestCall_612658
proc url_PutDataCatalogEncryptionSettings_614684(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutDataCatalogEncryptionSettings_614683(path: JsonNode;
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
  var valid_614685 = header.getOrDefault("X-Amz-Target")
  valid_614685 = validateParameter(valid_614685, JString, required = true, default = newJString(
      "AWSGlue.PutDataCatalogEncryptionSettings"))
  if valid_614685 != nil:
    section.add "X-Amz-Target", valid_614685
  var valid_614686 = header.getOrDefault("X-Amz-Signature")
  valid_614686 = validateParameter(valid_614686, JString, required = false,
                                 default = nil)
  if valid_614686 != nil:
    section.add "X-Amz-Signature", valid_614686
  var valid_614687 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614687 = validateParameter(valid_614687, JString, required = false,
                                 default = nil)
  if valid_614687 != nil:
    section.add "X-Amz-Content-Sha256", valid_614687
  var valid_614688 = header.getOrDefault("X-Amz-Date")
  valid_614688 = validateParameter(valid_614688, JString, required = false,
                                 default = nil)
  if valid_614688 != nil:
    section.add "X-Amz-Date", valid_614688
  var valid_614689 = header.getOrDefault("X-Amz-Credential")
  valid_614689 = validateParameter(valid_614689, JString, required = false,
                                 default = nil)
  if valid_614689 != nil:
    section.add "X-Amz-Credential", valid_614689
  var valid_614690 = header.getOrDefault("X-Amz-Security-Token")
  valid_614690 = validateParameter(valid_614690, JString, required = false,
                                 default = nil)
  if valid_614690 != nil:
    section.add "X-Amz-Security-Token", valid_614690
  var valid_614691 = header.getOrDefault("X-Amz-Algorithm")
  valid_614691 = validateParameter(valid_614691, JString, required = false,
                                 default = nil)
  if valid_614691 != nil:
    section.add "X-Amz-Algorithm", valid_614691
  var valid_614692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614692 = validateParameter(valid_614692, JString, required = false,
                                 default = nil)
  if valid_614692 != nil:
    section.add "X-Amz-SignedHeaders", valid_614692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614694: Call_PutDataCatalogEncryptionSettings_614682;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
  ## 
  let valid = call_614694.validator(path, query, header, formData, body)
  let scheme = call_614694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614694.url(scheme.get, call_614694.host, call_614694.base,
                         call_614694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614694, url, valid)

proc call*(call_614695: Call_PutDataCatalogEncryptionSettings_614682;
          body: JsonNode): Recallable =
  ## putDataCatalogEncryptionSettings
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
  ##   body: JObject (required)
  var body_614696 = newJObject()
  if body != nil:
    body_614696 = body
  result = call_614695.call(nil, nil, nil, nil, body_614696)

var putDataCatalogEncryptionSettings* = Call_PutDataCatalogEncryptionSettings_614682(
    name: "putDataCatalogEncryptionSettings", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutDataCatalogEncryptionSettings",
    validator: validate_PutDataCatalogEncryptionSettings_614683, base: "/",
    url: url_PutDataCatalogEncryptionSettings_614684,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResourcePolicy_614697 = ref object of OpenApiRestCall_612658
proc url_PutResourcePolicy_614699(protocol: Scheme; host: string; base: string;
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

proc validate_PutResourcePolicy_614698(path: JsonNode; query: JsonNode;
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
  var valid_614700 = header.getOrDefault("X-Amz-Target")
  valid_614700 = validateParameter(valid_614700, JString, required = true, default = newJString(
      "AWSGlue.PutResourcePolicy"))
  if valid_614700 != nil:
    section.add "X-Amz-Target", valid_614700
  var valid_614701 = header.getOrDefault("X-Amz-Signature")
  valid_614701 = validateParameter(valid_614701, JString, required = false,
                                 default = nil)
  if valid_614701 != nil:
    section.add "X-Amz-Signature", valid_614701
  var valid_614702 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614702 = validateParameter(valid_614702, JString, required = false,
                                 default = nil)
  if valid_614702 != nil:
    section.add "X-Amz-Content-Sha256", valid_614702
  var valid_614703 = header.getOrDefault("X-Amz-Date")
  valid_614703 = validateParameter(valid_614703, JString, required = false,
                                 default = nil)
  if valid_614703 != nil:
    section.add "X-Amz-Date", valid_614703
  var valid_614704 = header.getOrDefault("X-Amz-Credential")
  valid_614704 = validateParameter(valid_614704, JString, required = false,
                                 default = nil)
  if valid_614704 != nil:
    section.add "X-Amz-Credential", valid_614704
  var valid_614705 = header.getOrDefault("X-Amz-Security-Token")
  valid_614705 = validateParameter(valid_614705, JString, required = false,
                                 default = nil)
  if valid_614705 != nil:
    section.add "X-Amz-Security-Token", valid_614705
  var valid_614706 = header.getOrDefault("X-Amz-Algorithm")
  valid_614706 = validateParameter(valid_614706, JString, required = false,
                                 default = nil)
  if valid_614706 != nil:
    section.add "X-Amz-Algorithm", valid_614706
  var valid_614707 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614707 = validateParameter(valid_614707, JString, required = false,
                                 default = nil)
  if valid_614707 != nil:
    section.add "X-Amz-SignedHeaders", valid_614707
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614709: Call_PutResourcePolicy_614697; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the Data Catalog resource policy for access control.
  ## 
  let valid = call_614709.validator(path, query, header, formData, body)
  let scheme = call_614709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614709.url(scheme.get, call_614709.host, call_614709.base,
                         call_614709.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614709, url, valid)

proc call*(call_614710: Call_PutResourcePolicy_614697; body: JsonNode): Recallable =
  ## putResourcePolicy
  ## Sets the Data Catalog resource policy for access control.
  ##   body: JObject (required)
  var body_614711 = newJObject()
  if body != nil:
    body_614711 = body
  result = call_614710.call(nil, nil, nil, nil, body_614711)

var putResourcePolicy* = Call_PutResourcePolicy_614697(name: "putResourcePolicy",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutResourcePolicy",
    validator: validate_PutResourcePolicy_614698, base: "/",
    url: url_PutResourcePolicy_614699, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutWorkflowRunProperties_614712 = ref object of OpenApiRestCall_612658
proc url_PutWorkflowRunProperties_614714(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutWorkflowRunProperties_614713(path: JsonNode; query: JsonNode;
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
  var valid_614715 = header.getOrDefault("X-Amz-Target")
  valid_614715 = validateParameter(valid_614715, JString, required = true, default = newJString(
      "AWSGlue.PutWorkflowRunProperties"))
  if valid_614715 != nil:
    section.add "X-Amz-Target", valid_614715
  var valid_614716 = header.getOrDefault("X-Amz-Signature")
  valid_614716 = validateParameter(valid_614716, JString, required = false,
                                 default = nil)
  if valid_614716 != nil:
    section.add "X-Amz-Signature", valid_614716
  var valid_614717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614717 = validateParameter(valid_614717, JString, required = false,
                                 default = nil)
  if valid_614717 != nil:
    section.add "X-Amz-Content-Sha256", valid_614717
  var valid_614718 = header.getOrDefault("X-Amz-Date")
  valid_614718 = validateParameter(valid_614718, JString, required = false,
                                 default = nil)
  if valid_614718 != nil:
    section.add "X-Amz-Date", valid_614718
  var valid_614719 = header.getOrDefault("X-Amz-Credential")
  valid_614719 = validateParameter(valid_614719, JString, required = false,
                                 default = nil)
  if valid_614719 != nil:
    section.add "X-Amz-Credential", valid_614719
  var valid_614720 = header.getOrDefault("X-Amz-Security-Token")
  valid_614720 = validateParameter(valid_614720, JString, required = false,
                                 default = nil)
  if valid_614720 != nil:
    section.add "X-Amz-Security-Token", valid_614720
  var valid_614721 = header.getOrDefault("X-Amz-Algorithm")
  valid_614721 = validateParameter(valid_614721, JString, required = false,
                                 default = nil)
  if valid_614721 != nil:
    section.add "X-Amz-Algorithm", valid_614721
  var valid_614722 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614722 = validateParameter(valid_614722, JString, required = false,
                                 default = nil)
  if valid_614722 != nil:
    section.add "X-Amz-SignedHeaders", valid_614722
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614724: Call_PutWorkflowRunProperties_614712; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
  ## 
  let valid = call_614724.validator(path, query, header, formData, body)
  let scheme = call_614724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614724.url(scheme.get, call_614724.host, call_614724.base,
                         call_614724.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614724, url, valid)

proc call*(call_614725: Call_PutWorkflowRunProperties_614712; body: JsonNode): Recallable =
  ## putWorkflowRunProperties
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
  ##   body: JObject (required)
  var body_614726 = newJObject()
  if body != nil:
    body_614726 = body
  result = call_614725.call(nil, nil, nil, nil, body_614726)

var putWorkflowRunProperties* = Call_PutWorkflowRunProperties_614712(
    name: "putWorkflowRunProperties", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutWorkflowRunProperties",
    validator: validate_PutWorkflowRunProperties_614713, base: "/",
    url: url_PutWorkflowRunProperties_614714, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetJobBookmark_614727 = ref object of OpenApiRestCall_612658
proc url_ResetJobBookmark_614729(protocol: Scheme; host: string; base: string;
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

proc validate_ResetJobBookmark_614728(path: JsonNode; query: JsonNode;
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
  var valid_614730 = header.getOrDefault("X-Amz-Target")
  valid_614730 = validateParameter(valid_614730, JString, required = true, default = newJString(
      "AWSGlue.ResetJobBookmark"))
  if valid_614730 != nil:
    section.add "X-Amz-Target", valid_614730
  var valid_614731 = header.getOrDefault("X-Amz-Signature")
  valid_614731 = validateParameter(valid_614731, JString, required = false,
                                 default = nil)
  if valid_614731 != nil:
    section.add "X-Amz-Signature", valid_614731
  var valid_614732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614732 = validateParameter(valid_614732, JString, required = false,
                                 default = nil)
  if valid_614732 != nil:
    section.add "X-Amz-Content-Sha256", valid_614732
  var valid_614733 = header.getOrDefault("X-Amz-Date")
  valid_614733 = validateParameter(valid_614733, JString, required = false,
                                 default = nil)
  if valid_614733 != nil:
    section.add "X-Amz-Date", valid_614733
  var valid_614734 = header.getOrDefault("X-Amz-Credential")
  valid_614734 = validateParameter(valid_614734, JString, required = false,
                                 default = nil)
  if valid_614734 != nil:
    section.add "X-Amz-Credential", valid_614734
  var valid_614735 = header.getOrDefault("X-Amz-Security-Token")
  valid_614735 = validateParameter(valid_614735, JString, required = false,
                                 default = nil)
  if valid_614735 != nil:
    section.add "X-Amz-Security-Token", valid_614735
  var valid_614736 = header.getOrDefault("X-Amz-Algorithm")
  valid_614736 = validateParameter(valid_614736, JString, required = false,
                                 default = nil)
  if valid_614736 != nil:
    section.add "X-Amz-Algorithm", valid_614736
  var valid_614737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614737 = validateParameter(valid_614737, JString, required = false,
                                 default = nil)
  if valid_614737 != nil:
    section.add "X-Amz-SignedHeaders", valid_614737
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614739: Call_ResetJobBookmark_614727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets a bookmark entry.
  ## 
  let valid = call_614739.validator(path, query, header, formData, body)
  let scheme = call_614739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614739.url(scheme.get, call_614739.host, call_614739.base,
                         call_614739.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614739, url, valid)

proc call*(call_614740: Call_ResetJobBookmark_614727; body: JsonNode): Recallable =
  ## resetJobBookmark
  ## Resets a bookmark entry.
  ##   body: JObject (required)
  var body_614741 = newJObject()
  if body != nil:
    body_614741 = body
  result = call_614740.call(nil, nil, nil, nil, body_614741)

var resetJobBookmark* = Call_ResetJobBookmark_614727(name: "resetJobBookmark",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ResetJobBookmark",
    validator: validate_ResetJobBookmark_614728, base: "/",
    url: url_ResetJobBookmark_614729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchTables_614742 = ref object of OpenApiRestCall_612658
proc url_SearchTables_614744(protocol: Scheme; host: string; base: string;
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

proc validate_SearchTables_614743(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614745 = query.getOrDefault("MaxResults")
  valid_614745 = validateParameter(valid_614745, JString, required = false,
                                 default = nil)
  if valid_614745 != nil:
    section.add "MaxResults", valid_614745
  var valid_614746 = query.getOrDefault("NextToken")
  valid_614746 = validateParameter(valid_614746, JString, required = false,
                                 default = nil)
  if valid_614746 != nil:
    section.add "NextToken", valid_614746
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
  var valid_614747 = header.getOrDefault("X-Amz-Target")
  valid_614747 = validateParameter(valid_614747, JString, required = true,
                                 default = newJString("AWSGlue.SearchTables"))
  if valid_614747 != nil:
    section.add "X-Amz-Target", valid_614747
  var valid_614748 = header.getOrDefault("X-Amz-Signature")
  valid_614748 = validateParameter(valid_614748, JString, required = false,
                                 default = nil)
  if valid_614748 != nil:
    section.add "X-Amz-Signature", valid_614748
  var valid_614749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614749 = validateParameter(valid_614749, JString, required = false,
                                 default = nil)
  if valid_614749 != nil:
    section.add "X-Amz-Content-Sha256", valid_614749
  var valid_614750 = header.getOrDefault("X-Amz-Date")
  valid_614750 = validateParameter(valid_614750, JString, required = false,
                                 default = nil)
  if valid_614750 != nil:
    section.add "X-Amz-Date", valid_614750
  var valid_614751 = header.getOrDefault("X-Amz-Credential")
  valid_614751 = validateParameter(valid_614751, JString, required = false,
                                 default = nil)
  if valid_614751 != nil:
    section.add "X-Amz-Credential", valid_614751
  var valid_614752 = header.getOrDefault("X-Amz-Security-Token")
  valid_614752 = validateParameter(valid_614752, JString, required = false,
                                 default = nil)
  if valid_614752 != nil:
    section.add "X-Amz-Security-Token", valid_614752
  var valid_614753 = header.getOrDefault("X-Amz-Algorithm")
  valid_614753 = validateParameter(valid_614753, JString, required = false,
                                 default = nil)
  if valid_614753 != nil:
    section.add "X-Amz-Algorithm", valid_614753
  var valid_614754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614754 = validateParameter(valid_614754, JString, required = false,
                                 default = nil)
  if valid_614754 != nil:
    section.add "X-Amz-SignedHeaders", valid_614754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614756: Call_SearchTables_614742; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
  ## 
  let valid = call_614756.validator(path, query, header, formData, body)
  let scheme = call_614756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614756.url(scheme.get, call_614756.host, call_614756.base,
                         call_614756.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614756, url, valid)

proc call*(call_614757: Call_SearchTables_614742; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchTables
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614758 = newJObject()
  var body_614759 = newJObject()
  add(query_614758, "MaxResults", newJString(MaxResults))
  add(query_614758, "NextToken", newJString(NextToken))
  if body != nil:
    body_614759 = body
  result = call_614757.call(nil, query_614758, nil, nil, body_614759)

var searchTables* = Call_SearchTables_614742(name: "searchTables",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.SearchTables",
    validator: validate_SearchTables_614743, base: "/", url: url_SearchTables_614744,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCrawler_614760 = ref object of OpenApiRestCall_612658
proc url_StartCrawler_614762(protocol: Scheme; host: string; base: string;
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

proc validate_StartCrawler_614761(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614763 = header.getOrDefault("X-Amz-Target")
  valid_614763 = validateParameter(valid_614763, JString, required = true,
                                 default = newJString("AWSGlue.StartCrawler"))
  if valid_614763 != nil:
    section.add "X-Amz-Target", valid_614763
  var valid_614764 = header.getOrDefault("X-Amz-Signature")
  valid_614764 = validateParameter(valid_614764, JString, required = false,
                                 default = nil)
  if valid_614764 != nil:
    section.add "X-Amz-Signature", valid_614764
  var valid_614765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614765 = validateParameter(valid_614765, JString, required = false,
                                 default = nil)
  if valid_614765 != nil:
    section.add "X-Amz-Content-Sha256", valid_614765
  var valid_614766 = header.getOrDefault("X-Amz-Date")
  valid_614766 = validateParameter(valid_614766, JString, required = false,
                                 default = nil)
  if valid_614766 != nil:
    section.add "X-Amz-Date", valid_614766
  var valid_614767 = header.getOrDefault("X-Amz-Credential")
  valid_614767 = validateParameter(valid_614767, JString, required = false,
                                 default = nil)
  if valid_614767 != nil:
    section.add "X-Amz-Credential", valid_614767
  var valid_614768 = header.getOrDefault("X-Amz-Security-Token")
  valid_614768 = validateParameter(valid_614768, JString, required = false,
                                 default = nil)
  if valid_614768 != nil:
    section.add "X-Amz-Security-Token", valid_614768
  var valid_614769 = header.getOrDefault("X-Amz-Algorithm")
  valid_614769 = validateParameter(valid_614769, JString, required = false,
                                 default = nil)
  if valid_614769 != nil:
    section.add "X-Amz-Algorithm", valid_614769
  var valid_614770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614770 = validateParameter(valid_614770, JString, required = false,
                                 default = nil)
  if valid_614770 != nil:
    section.add "X-Amz-SignedHeaders", valid_614770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614772: Call_StartCrawler_614760; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
  ## 
  let valid = call_614772.validator(path, query, header, formData, body)
  let scheme = call_614772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614772.url(scheme.get, call_614772.host, call_614772.base,
                         call_614772.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614772, url, valid)

proc call*(call_614773: Call_StartCrawler_614760; body: JsonNode): Recallable =
  ## startCrawler
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
  ##   body: JObject (required)
  var body_614774 = newJObject()
  if body != nil:
    body_614774 = body
  result = call_614773.call(nil, nil, nil, nil, body_614774)

var startCrawler* = Call_StartCrawler_614760(name: "startCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartCrawler",
    validator: validate_StartCrawler_614761, base: "/", url: url_StartCrawler_614762,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCrawlerSchedule_614775 = ref object of OpenApiRestCall_612658
proc url_StartCrawlerSchedule_614777(protocol: Scheme; host: string; base: string;
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

proc validate_StartCrawlerSchedule_614776(path: JsonNode; query: JsonNode;
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
  var valid_614778 = header.getOrDefault("X-Amz-Target")
  valid_614778 = validateParameter(valid_614778, JString, required = true, default = newJString(
      "AWSGlue.StartCrawlerSchedule"))
  if valid_614778 != nil:
    section.add "X-Amz-Target", valid_614778
  var valid_614779 = header.getOrDefault("X-Amz-Signature")
  valid_614779 = validateParameter(valid_614779, JString, required = false,
                                 default = nil)
  if valid_614779 != nil:
    section.add "X-Amz-Signature", valid_614779
  var valid_614780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614780 = validateParameter(valid_614780, JString, required = false,
                                 default = nil)
  if valid_614780 != nil:
    section.add "X-Amz-Content-Sha256", valid_614780
  var valid_614781 = header.getOrDefault("X-Amz-Date")
  valid_614781 = validateParameter(valid_614781, JString, required = false,
                                 default = nil)
  if valid_614781 != nil:
    section.add "X-Amz-Date", valid_614781
  var valid_614782 = header.getOrDefault("X-Amz-Credential")
  valid_614782 = validateParameter(valid_614782, JString, required = false,
                                 default = nil)
  if valid_614782 != nil:
    section.add "X-Amz-Credential", valid_614782
  var valid_614783 = header.getOrDefault("X-Amz-Security-Token")
  valid_614783 = validateParameter(valid_614783, JString, required = false,
                                 default = nil)
  if valid_614783 != nil:
    section.add "X-Amz-Security-Token", valid_614783
  var valid_614784 = header.getOrDefault("X-Amz-Algorithm")
  valid_614784 = validateParameter(valid_614784, JString, required = false,
                                 default = nil)
  if valid_614784 != nil:
    section.add "X-Amz-Algorithm", valid_614784
  var valid_614785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614785 = validateParameter(valid_614785, JString, required = false,
                                 default = nil)
  if valid_614785 != nil:
    section.add "X-Amz-SignedHeaders", valid_614785
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614787: Call_StartCrawlerSchedule_614775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
  ## 
  let valid = call_614787.validator(path, query, header, formData, body)
  let scheme = call_614787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614787.url(scheme.get, call_614787.host, call_614787.base,
                         call_614787.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614787, url, valid)

proc call*(call_614788: Call_StartCrawlerSchedule_614775; body: JsonNode): Recallable =
  ## startCrawlerSchedule
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
  ##   body: JObject (required)
  var body_614789 = newJObject()
  if body != nil:
    body_614789 = body
  result = call_614788.call(nil, nil, nil, nil, body_614789)

var startCrawlerSchedule* = Call_StartCrawlerSchedule_614775(
    name: "startCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartCrawlerSchedule",
    validator: validate_StartCrawlerSchedule_614776, base: "/",
    url: url_StartCrawlerSchedule_614777, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartExportLabelsTaskRun_614790 = ref object of OpenApiRestCall_612658
proc url_StartExportLabelsTaskRun_614792(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartExportLabelsTaskRun_614791(path: JsonNode; query: JsonNode;
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
  var valid_614793 = header.getOrDefault("X-Amz-Target")
  valid_614793 = validateParameter(valid_614793, JString, required = true, default = newJString(
      "AWSGlue.StartExportLabelsTaskRun"))
  if valid_614793 != nil:
    section.add "X-Amz-Target", valid_614793
  var valid_614794 = header.getOrDefault("X-Amz-Signature")
  valid_614794 = validateParameter(valid_614794, JString, required = false,
                                 default = nil)
  if valid_614794 != nil:
    section.add "X-Amz-Signature", valid_614794
  var valid_614795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614795 = validateParameter(valid_614795, JString, required = false,
                                 default = nil)
  if valid_614795 != nil:
    section.add "X-Amz-Content-Sha256", valid_614795
  var valid_614796 = header.getOrDefault("X-Amz-Date")
  valid_614796 = validateParameter(valid_614796, JString, required = false,
                                 default = nil)
  if valid_614796 != nil:
    section.add "X-Amz-Date", valid_614796
  var valid_614797 = header.getOrDefault("X-Amz-Credential")
  valid_614797 = validateParameter(valid_614797, JString, required = false,
                                 default = nil)
  if valid_614797 != nil:
    section.add "X-Amz-Credential", valid_614797
  var valid_614798 = header.getOrDefault("X-Amz-Security-Token")
  valid_614798 = validateParameter(valid_614798, JString, required = false,
                                 default = nil)
  if valid_614798 != nil:
    section.add "X-Amz-Security-Token", valid_614798
  var valid_614799 = header.getOrDefault("X-Amz-Algorithm")
  valid_614799 = validateParameter(valid_614799, JString, required = false,
                                 default = nil)
  if valid_614799 != nil:
    section.add "X-Amz-Algorithm", valid_614799
  var valid_614800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614800 = validateParameter(valid_614800, JString, required = false,
                                 default = nil)
  if valid_614800 != nil:
    section.add "X-Amz-SignedHeaders", valid_614800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614802: Call_StartExportLabelsTaskRun_614790; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
  ## 
  let valid = call_614802.validator(path, query, header, formData, body)
  let scheme = call_614802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614802.url(scheme.get, call_614802.host, call_614802.base,
                         call_614802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614802, url, valid)

proc call*(call_614803: Call_StartExportLabelsTaskRun_614790; body: JsonNode): Recallable =
  ## startExportLabelsTaskRun
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
  ##   body: JObject (required)
  var body_614804 = newJObject()
  if body != nil:
    body_614804 = body
  result = call_614803.call(nil, nil, nil, nil, body_614804)

var startExportLabelsTaskRun* = Call_StartExportLabelsTaskRun_614790(
    name: "startExportLabelsTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartExportLabelsTaskRun",
    validator: validate_StartExportLabelsTaskRun_614791, base: "/",
    url: url_StartExportLabelsTaskRun_614792, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImportLabelsTaskRun_614805 = ref object of OpenApiRestCall_612658
proc url_StartImportLabelsTaskRun_614807(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartImportLabelsTaskRun_614806(path: JsonNode; query: JsonNode;
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
  var valid_614808 = header.getOrDefault("X-Amz-Target")
  valid_614808 = validateParameter(valid_614808, JString, required = true, default = newJString(
      "AWSGlue.StartImportLabelsTaskRun"))
  if valid_614808 != nil:
    section.add "X-Amz-Target", valid_614808
  var valid_614809 = header.getOrDefault("X-Amz-Signature")
  valid_614809 = validateParameter(valid_614809, JString, required = false,
                                 default = nil)
  if valid_614809 != nil:
    section.add "X-Amz-Signature", valid_614809
  var valid_614810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614810 = validateParameter(valid_614810, JString, required = false,
                                 default = nil)
  if valid_614810 != nil:
    section.add "X-Amz-Content-Sha256", valid_614810
  var valid_614811 = header.getOrDefault("X-Amz-Date")
  valid_614811 = validateParameter(valid_614811, JString, required = false,
                                 default = nil)
  if valid_614811 != nil:
    section.add "X-Amz-Date", valid_614811
  var valid_614812 = header.getOrDefault("X-Amz-Credential")
  valid_614812 = validateParameter(valid_614812, JString, required = false,
                                 default = nil)
  if valid_614812 != nil:
    section.add "X-Amz-Credential", valid_614812
  var valid_614813 = header.getOrDefault("X-Amz-Security-Token")
  valid_614813 = validateParameter(valid_614813, JString, required = false,
                                 default = nil)
  if valid_614813 != nil:
    section.add "X-Amz-Security-Token", valid_614813
  var valid_614814 = header.getOrDefault("X-Amz-Algorithm")
  valid_614814 = validateParameter(valid_614814, JString, required = false,
                                 default = nil)
  if valid_614814 != nil:
    section.add "X-Amz-Algorithm", valid_614814
  var valid_614815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614815 = validateParameter(valid_614815, JString, required = false,
                                 default = nil)
  if valid_614815 != nil:
    section.add "X-Amz-SignedHeaders", valid_614815
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614817: Call_StartImportLabelsTaskRun_614805; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
  ## 
  let valid = call_614817.validator(path, query, header, formData, body)
  let scheme = call_614817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614817.url(scheme.get, call_614817.host, call_614817.base,
                         call_614817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614817, url, valid)

proc call*(call_614818: Call_StartImportLabelsTaskRun_614805; body: JsonNode): Recallable =
  ## startImportLabelsTaskRun
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
  ##   body: JObject (required)
  var body_614819 = newJObject()
  if body != nil:
    body_614819 = body
  result = call_614818.call(nil, nil, nil, nil, body_614819)

var startImportLabelsTaskRun* = Call_StartImportLabelsTaskRun_614805(
    name: "startImportLabelsTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartImportLabelsTaskRun",
    validator: validate_StartImportLabelsTaskRun_614806, base: "/",
    url: url_StartImportLabelsTaskRun_614807, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartJobRun_614820 = ref object of OpenApiRestCall_612658
proc url_StartJobRun_614822(protocol: Scheme; host: string; base: string;
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

proc validate_StartJobRun_614821(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614823 = header.getOrDefault("X-Amz-Target")
  valid_614823 = validateParameter(valid_614823, JString, required = true,
                                 default = newJString("AWSGlue.StartJobRun"))
  if valid_614823 != nil:
    section.add "X-Amz-Target", valid_614823
  var valid_614824 = header.getOrDefault("X-Amz-Signature")
  valid_614824 = validateParameter(valid_614824, JString, required = false,
                                 default = nil)
  if valid_614824 != nil:
    section.add "X-Amz-Signature", valid_614824
  var valid_614825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614825 = validateParameter(valid_614825, JString, required = false,
                                 default = nil)
  if valid_614825 != nil:
    section.add "X-Amz-Content-Sha256", valid_614825
  var valid_614826 = header.getOrDefault("X-Amz-Date")
  valid_614826 = validateParameter(valid_614826, JString, required = false,
                                 default = nil)
  if valid_614826 != nil:
    section.add "X-Amz-Date", valid_614826
  var valid_614827 = header.getOrDefault("X-Amz-Credential")
  valid_614827 = validateParameter(valid_614827, JString, required = false,
                                 default = nil)
  if valid_614827 != nil:
    section.add "X-Amz-Credential", valid_614827
  var valid_614828 = header.getOrDefault("X-Amz-Security-Token")
  valid_614828 = validateParameter(valid_614828, JString, required = false,
                                 default = nil)
  if valid_614828 != nil:
    section.add "X-Amz-Security-Token", valid_614828
  var valid_614829 = header.getOrDefault("X-Amz-Algorithm")
  valid_614829 = validateParameter(valid_614829, JString, required = false,
                                 default = nil)
  if valid_614829 != nil:
    section.add "X-Amz-Algorithm", valid_614829
  var valid_614830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614830 = validateParameter(valid_614830, JString, required = false,
                                 default = nil)
  if valid_614830 != nil:
    section.add "X-Amz-SignedHeaders", valid_614830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614832: Call_StartJobRun_614820; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a job run using a job definition.
  ## 
  let valid = call_614832.validator(path, query, header, formData, body)
  let scheme = call_614832.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614832.url(scheme.get, call_614832.host, call_614832.base,
                         call_614832.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614832, url, valid)

proc call*(call_614833: Call_StartJobRun_614820; body: JsonNode): Recallable =
  ## startJobRun
  ## Starts a job run using a job definition.
  ##   body: JObject (required)
  var body_614834 = newJObject()
  if body != nil:
    body_614834 = body
  result = call_614833.call(nil, nil, nil, nil, body_614834)

var startJobRun* = Call_StartJobRun_614820(name: "startJobRun",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StartJobRun",
                                        validator: validate_StartJobRun_614821,
                                        base: "/", url: url_StartJobRun_614822,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMLEvaluationTaskRun_614835 = ref object of OpenApiRestCall_612658
proc url_StartMLEvaluationTaskRun_614837(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartMLEvaluationTaskRun_614836(path: JsonNode; query: JsonNode;
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
  var valid_614838 = header.getOrDefault("X-Amz-Target")
  valid_614838 = validateParameter(valid_614838, JString, required = true, default = newJString(
      "AWSGlue.StartMLEvaluationTaskRun"))
  if valid_614838 != nil:
    section.add "X-Amz-Target", valid_614838
  var valid_614839 = header.getOrDefault("X-Amz-Signature")
  valid_614839 = validateParameter(valid_614839, JString, required = false,
                                 default = nil)
  if valid_614839 != nil:
    section.add "X-Amz-Signature", valid_614839
  var valid_614840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614840 = validateParameter(valid_614840, JString, required = false,
                                 default = nil)
  if valid_614840 != nil:
    section.add "X-Amz-Content-Sha256", valid_614840
  var valid_614841 = header.getOrDefault("X-Amz-Date")
  valid_614841 = validateParameter(valid_614841, JString, required = false,
                                 default = nil)
  if valid_614841 != nil:
    section.add "X-Amz-Date", valid_614841
  var valid_614842 = header.getOrDefault("X-Amz-Credential")
  valid_614842 = validateParameter(valid_614842, JString, required = false,
                                 default = nil)
  if valid_614842 != nil:
    section.add "X-Amz-Credential", valid_614842
  var valid_614843 = header.getOrDefault("X-Amz-Security-Token")
  valid_614843 = validateParameter(valid_614843, JString, required = false,
                                 default = nil)
  if valid_614843 != nil:
    section.add "X-Amz-Security-Token", valid_614843
  var valid_614844 = header.getOrDefault("X-Amz-Algorithm")
  valid_614844 = validateParameter(valid_614844, JString, required = false,
                                 default = nil)
  if valid_614844 != nil:
    section.add "X-Amz-Algorithm", valid_614844
  var valid_614845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614845 = validateParameter(valid_614845, JString, required = false,
                                 default = nil)
  if valid_614845 != nil:
    section.add "X-Amz-SignedHeaders", valid_614845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614847: Call_StartMLEvaluationTaskRun_614835; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
  ## 
  let valid = call_614847.validator(path, query, header, formData, body)
  let scheme = call_614847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614847.url(scheme.get, call_614847.host, call_614847.base,
                         call_614847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614847, url, valid)

proc call*(call_614848: Call_StartMLEvaluationTaskRun_614835; body: JsonNode): Recallable =
  ## startMLEvaluationTaskRun
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
  ##   body: JObject (required)
  var body_614849 = newJObject()
  if body != nil:
    body_614849 = body
  result = call_614848.call(nil, nil, nil, nil, body_614849)

var startMLEvaluationTaskRun* = Call_StartMLEvaluationTaskRun_614835(
    name: "startMLEvaluationTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartMLEvaluationTaskRun",
    validator: validate_StartMLEvaluationTaskRun_614836, base: "/",
    url: url_StartMLEvaluationTaskRun_614837, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMLLabelingSetGenerationTaskRun_614850 = ref object of OpenApiRestCall_612658
proc url_StartMLLabelingSetGenerationTaskRun_614852(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartMLLabelingSetGenerationTaskRun_614851(path: JsonNode;
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
  var valid_614853 = header.getOrDefault("X-Amz-Target")
  valid_614853 = validateParameter(valid_614853, JString, required = true, default = newJString(
      "AWSGlue.StartMLLabelingSetGenerationTaskRun"))
  if valid_614853 != nil:
    section.add "X-Amz-Target", valid_614853
  var valid_614854 = header.getOrDefault("X-Amz-Signature")
  valid_614854 = validateParameter(valid_614854, JString, required = false,
                                 default = nil)
  if valid_614854 != nil:
    section.add "X-Amz-Signature", valid_614854
  var valid_614855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614855 = validateParameter(valid_614855, JString, required = false,
                                 default = nil)
  if valid_614855 != nil:
    section.add "X-Amz-Content-Sha256", valid_614855
  var valid_614856 = header.getOrDefault("X-Amz-Date")
  valid_614856 = validateParameter(valid_614856, JString, required = false,
                                 default = nil)
  if valid_614856 != nil:
    section.add "X-Amz-Date", valid_614856
  var valid_614857 = header.getOrDefault("X-Amz-Credential")
  valid_614857 = validateParameter(valid_614857, JString, required = false,
                                 default = nil)
  if valid_614857 != nil:
    section.add "X-Amz-Credential", valid_614857
  var valid_614858 = header.getOrDefault("X-Amz-Security-Token")
  valid_614858 = validateParameter(valid_614858, JString, required = false,
                                 default = nil)
  if valid_614858 != nil:
    section.add "X-Amz-Security-Token", valid_614858
  var valid_614859 = header.getOrDefault("X-Amz-Algorithm")
  valid_614859 = validateParameter(valid_614859, JString, required = false,
                                 default = nil)
  if valid_614859 != nil:
    section.add "X-Amz-Algorithm", valid_614859
  var valid_614860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614860 = validateParameter(valid_614860, JString, required = false,
                                 default = nil)
  if valid_614860 != nil:
    section.add "X-Amz-SignedHeaders", valid_614860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614862: Call_StartMLLabelingSetGenerationTaskRun_614850;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
  ## 
  let valid = call_614862.validator(path, query, header, formData, body)
  let scheme = call_614862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614862.url(scheme.get, call_614862.host, call_614862.base,
                         call_614862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614862, url, valid)

proc call*(call_614863: Call_StartMLLabelingSetGenerationTaskRun_614850;
          body: JsonNode): Recallable =
  ## startMLLabelingSetGenerationTaskRun
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
  ##   body: JObject (required)
  var body_614864 = newJObject()
  if body != nil:
    body_614864 = body
  result = call_614863.call(nil, nil, nil, nil, body_614864)

var startMLLabelingSetGenerationTaskRun* = Call_StartMLLabelingSetGenerationTaskRun_614850(
    name: "startMLLabelingSetGenerationTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartMLLabelingSetGenerationTaskRun",
    validator: validate_StartMLLabelingSetGenerationTaskRun_614851, base: "/",
    url: url_StartMLLabelingSetGenerationTaskRun_614852,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTrigger_614865 = ref object of OpenApiRestCall_612658
proc url_StartTrigger_614867(protocol: Scheme; host: string; base: string;
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

proc validate_StartTrigger_614866(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614868 = header.getOrDefault("X-Amz-Target")
  valid_614868 = validateParameter(valid_614868, JString, required = true,
                                 default = newJString("AWSGlue.StartTrigger"))
  if valid_614868 != nil:
    section.add "X-Amz-Target", valid_614868
  var valid_614869 = header.getOrDefault("X-Amz-Signature")
  valid_614869 = validateParameter(valid_614869, JString, required = false,
                                 default = nil)
  if valid_614869 != nil:
    section.add "X-Amz-Signature", valid_614869
  var valid_614870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614870 = validateParameter(valid_614870, JString, required = false,
                                 default = nil)
  if valid_614870 != nil:
    section.add "X-Amz-Content-Sha256", valid_614870
  var valid_614871 = header.getOrDefault("X-Amz-Date")
  valid_614871 = validateParameter(valid_614871, JString, required = false,
                                 default = nil)
  if valid_614871 != nil:
    section.add "X-Amz-Date", valid_614871
  var valid_614872 = header.getOrDefault("X-Amz-Credential")
  valid_614872 = validateParameter(valid_614872, JString, required = false,
                                 default = nil)
  if valid_614872 != nil:
    section.add "X-Amz-Credential", valid_614872
  var valid_614873 = header.getOrDefault("X-Amz-Security-Token")
  valid_614873 = validateParameter(valid_614873, JString, required = false,
                                 default = nil)
  if valid_614873 != nil:
    section.add "X-Amz-Security-Token", valid_614873
  var valid_614874 = header.getOrDefault("X-Amz-Algorithm")
  valid_614874 = validateParameter(valid_614874, JString, required = false,
                                 default = nil)
  if valid_614874 != nil:
    section.add "X-Amz-Algorithm", valid_614874
  var valid_614875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614875 = validateParameter(valid_614875, JString, required = false,
                                 default = nil)
  if valid_614875 != nil:
    section.add "X-Amz-SignedHeaders", valid_614875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614877: Call_StartTrigger_614865; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
  ## 
  let valid = call_614877.validator(path, query, header, formData, body)
  let scheme = call_614877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614877.url(scheme.get, call_614877.host, call_614877.base,
                         call_614877.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614877, url, valid)

proc call*(call_614878: Call_StartTrigger_614865; body: JsonNode): Recallable =
  ## startTrigger
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
  ##   body: JObject (required)
  var body_614879 = newJObject()
  if body != nil:
    body_614879 = body
  result = call_614878.call(nil, nil, nil, nil, body_614879)

var startTrigger* = Call_StartTrigger_614865(name: "startTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartTrigger",
    validator: validate_StartTrigger_614866, base: "/", url: url_StartTrigger_614867,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartWorkflowRun_614880 = ref object of OpenApiRestCall_612658
proc url_StartWorkflowRun_614882(protocol: Scheme; host: string; base: string;
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

proc validate_StartWorkflowRun_614881(path: JsonNode; query: JsonNode;
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
  var valid_614883 = header.getOrDefault("X-Amz-Target")
  valid_614883 = validateParameter(valid_614883, JString, required = true, default = newJString(
      "AWSGlue.StartWorkflowRun"))
  if valid_614883 != nil:
    section.add "X-Amz-Target", valid_614883
  var valid_614884 = header.getOrDefault("X-Amz-Signature")
  valid_614884 = validateParameter(valid_614884, JString, required = false,
                                 default = nil)
  if valid_614884 != nil:
    section.add "X-Amz-Signature", valid_614884
  var valid_614885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614885 = validateParameter(valid_614885, JString, required = false,
                                 default = nil)
  if valid_614885 != nil:
    section.add "X-Amz-Content-Sha256", valid_614885
  var valid_614886 = header.getOrDefault("X-Amz-Date")
  valid_614886 = validateParameter(valid_614886, JString, required = false,
                                 default = nil)
  if valid_614886 != nil:
    section.add "X-Amz-Date", valid_614886
  var valid_614887 = header.getOrDefault("X-Amz-Credential")
  valid_614887 = validateParameter(valid_614887, JString, required = false,
                                 default = nil)
  if valid_614887 != nil:
    section.add "X-Amz-Credential", valid_614887
  var valid_614888 = header.getOrDefault("X-Amz-Security-Token")
  valid_614888 = validateParameter(valid_614888, JString, required = false,
                                 default = nil)
  if valid_614888 != nil:
    section.add "X-Amz-Security-Token", valid_614888
  var valid_614889 = header.getOrDefault("X-Amz-Algorithm")
  valid_614889 = validateParameter(valid_614889, JString, required = false,
                                 default = nil)
  if valid_614889 != nil:
    section.add "X-Amz-Algorithm", valid_614889
  var valid_614890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614890 = validateParameter(valid_614890, JString, required = false,
                                 default = nil)
  if valid_614890 != nil:
    section.add "X-Amz-SignedHeaders", valid_614890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614892: Call_StartWorkflowRun_614880; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a new run of the specified workflow.
  ## 
  let valid = call_614892.validator(path, query, header, formData, body)
  let scheme = call_614892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614892.url(scheme.get, call_614892.host, call_614892.base,
                         call_614892.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614892, url, valid)

proc call*(call_614893: Call_StartWorkflowRun_614880; body: JsonNode): Recallable =
  ## startWorkflowRun
  ## Starts a new run of the specified workflow.
  ##   body: JObject (required)
  var body_614894 = newJObject()
  if body != nil:
    body_614894 = body
  result = call_614893.call(nil, nil, nil, nil, body_614894)

var startWorkflowRun* = Call_StartWorkflowRun_614880(name: "startWorkflowRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartWorkflowRun",
    validator: validate_StartWorkflowRun_614881, base: "/",
    url: url_StartWorkflowRun_614882, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCrawler_614895 = ref object of OpenApiRestCall_612658
proc url_StopCrawler_614897(protocol: Scheme; host: string; base: string;
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

proc validate_StopCrawler_614896(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614898 = header.getOrDefault("X-Amz-Target")
  valid_614898 = validateParameter(valid_614898, JString, required = true,
                                 default = newJString("AWSGlue.StopCrawler"))
  if valid_614898 != nil:
    section.add "X-Amz-Target", valid_614898
  var valid_614899 = header.getOrDefault("X-Amz-Signature")
  valid_614899 = validateParameter(valid_614899, JString, required = false,
                                 default = nil)
  if valid_614899 != nil:
    section.add "X-Amz-Signature", valid_614899
  var valid_614900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614900 = validateParameter(valid_614900, JString, required = false,
                                 default = nil)
  if valid_614900 != nil:
    section.add "X-Amz-Content-Sha256", valid_614900
  var valid_614901 = header.getOrDefault("X-Amz-Date")
  valid_614901 = validateParameter(valid_614901, JString, required = false,
                                 default = nil)
  if valid_614901 != nil:
    section.add "X-Amz-Date", valid_614901
  var valid_614902 = header.getOrDefault("X-Amz-Credential")
  valid_614902 = validateParameter(valid_614902, JString, required = false,
                                 default = nil)
  if valid_614902 != nil:
    section.add "X-Amz-Credential", valid_614902
  var valid_614903 = header.getOrDefault("X-Amz-Security-Token")
  valid_614903 = validateParameter(valid_614903, JString, required = false,
                                 default = nil)
  if valid_614903 != nil:
    section.add "X-Amz-Security-Token", valid_614903
  var valid_614904 = header.getOrDefault("X-Amz-Algorithm")
  valid_614904 = validateParameter(valid_614904, JString, required = false,
                                 default = nil)
  if valid_614904 != nil:
    section.add "X-Amz-Algorithm", valid_614904
  var valid_614905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614905 = validateParameter(valid_614905, JString, required = false,
                                 default = nil)
  if valid_614905 != nil:
    section.add "X-Amz-SignedHeaders", valid_614905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614907: Call_StopCrawler_614895; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## If the specified crawler is running, stops the crawl.
  ## 
  let valid = call_614907.validator(path, query, header, formData, body)
  let scheme = call_614907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614907.url(scheme.get, call_614907.host, call_614907.base,
                         call_614907.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614907, url, valid)

proc call*(call_614908: Call_StopCrawler_614895; body: JsonNode): Recallable =
  ## stopCrawler
  ## If the specified crawler is running, stops the crawl.
  ##   body: JObject (required)
  var body_614909 = newJObject()
  if body != nil:
    body_614909 = body
  result = call_614908.call(nil, nil, nil, nil, body_614909)

var stopCrawler* = Call_StopCrawler_614895(name: "stopCrawler",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StopCrawler",
                                        validator: validate_StopCrawler_614896,
                                        base: "/", url: url_StopCrawler_614897,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCrawlerSchedule_614910 = ref object of OpenApiRestCall_612658
proc url_StopCrawlerSchedule_614912(protocol: Scheme; host: string; base: string;
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

proc validate_StopCrawlerSchedule_614911(path: JsonNode; query: JsonNode;
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
  var valid_614913 = header.getOrDefault("X-Amz-Target")
  valid_614913 = validateParameter(valid_614913, JString, required = true, default = newJString(
      "AWSGlue.StopCrawlerSchedule"))
  if valid_614913 != nil:
    section.add "X-Amz-Target", valid_614913
  var valid_614914 = header.getOrDefault("X-Amz-Signature")
  valid_614914 = validateParameter(valid_614914, JString, required = false,
                                 default = nil)
  if valid_614914 != nil:
    section.add "X-Amz-Signature", valid_614914
  var valid_614915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614915 = validateParameter(valid_614915, JString, required = false,
                                 default = nil)
  if valid_614915 != nil:
    section.add "X-Amz-Content-Sha256", valid_614915
  var valid_614916 = header.getOrDefault("X-Amz-Date")
  valid_614916 = validateParameter(valid_614916, JString, required = false,
                                 default = nil)
  if valid_614916 != nil:
    section.add "X-Amz-Date", valid_614916
  var valid_614917 = header.getOrDefault("X-Amz-Credential")
  valid_614917 = validateParameter(valid_614917, JString, required = false,
                                 default = nil)
  if valid_614917 != nil:
    section.add "X-Amz-Credential", valid_614917
  var valid_614918 = header.getOrDefault("X-Amz-Security-Token")
  valid_614918 = validateParameter(valid_614918, JString, required = false,
                                 default = nil)
  if valid_614918 != nil:
    section.add "X-Amz-Security-Token", valid_614918
  var valid_614919 = header.getOrDefault("X-Amz-Algorithm")
  valid_614919 = validateParameter(valid_614919, JString, required = false,
                                 default = nil)
  if valid_614919 != nil:
    section.add "X-Amz-Algorithm", valid_614919
  var valid_614920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614920 = validateParameter(valid_614920, JString, required = false,
                                 default = nil)
  if valid_614920 != nil:
    section.add "X-Amz-SignedHeaders", valid_614920
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614922: Call_StopCrawlerSchedule_614910; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
  ## 
  let valid = call_614922.validator(path, query, header, formData, body)
  let scheme = call_614922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614922.url(scheme.get, call_614922.host, call_614922.base,
                         call_614922.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614922, url, valid)

proc call*(call_614923: Call_StopCrawlerSchedule_614910; body: JsonNode): Recallable =
  ## stopCrawlerSchedule
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
  ##   body: JObject (required)
  var body_614924 = newJObject()
  if body != nil:
    body_614924 = body
  result = call_614923.call(nil, nil, nil, nil, body_614924)

var stopCrawlerSchedule* = Call_StopCrawlerSchedule_614910(
    name: "stopCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StopCrawlerSchedule",
    validator: validate_StopCrawlerSchedule_614911, base: "/",
    url: url_StopCrawlerSchedule_614912, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrigger_614925 = ref object of OpenApiRestCall_612658
proc url_StopTrigger_614927(protocol: Scheme; host: string; base: string;
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

proc validate_StopTrigger_614926(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614928 = header.getOrDefault("X-Amz-Target")
  valid_614928 = validateParameter(valid_614928, JString, required = true,
                                 default = newJString("AWSGlue.StopTrigger"))
  if valid_614928 != nil:
    section.add "X-Amz-Target", valid_614928
  var valid_614929 = header.getOrDefault("X-Amz-Signature")
  valid_614929 = validateParameter(valid_614929, JString, required = false,
                                 default = nil)
  if valid_614929 != nil:
    section.add "X-Amz-Signature", valid_614929
  var valid_614930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614930 = validateParameter(valid_614930, JString, required = false,
                                 default = nil)
  if valid_614930 != nil:
    section.add "X-Amz-Content-Sha256", valid_614930
  var valid_614931 = header.getOrDefault("X-Amz-Date")
  valid_614931 = validateParameter(valid_614931, JString, required = false,
                                 default = nil)
  if valid_614931 != nil:
    section.add "X-Amz-Date", valid_614931
  var valid_614932 = header.getOrDefault("X-Amz-Credential")
  valid_614932 = validateParameter(valid_614932, JString, required = false,
                                 default = nil)
  if valid_614932 != nil:
    section.add "X-Amz-Credential", valid_614932
  var valid_614933 = header.getOrDefault("X-Amz-Security-Token")
  valid_614933 = validateParameter(valid_614933, JString, required = false,
                                 default = nil)
  if valid_614933 != nil:
    section.add "X-Amz-Security-Token", valid_614933
  var valid_614934 = header.getOrDefault("X-Amz-Algorithm")
  valid_614934 = validateParameter(valid_614934, JString, required = false,
                                 default = nil)
  if valid_614934 != nil:
    section.add "X-Amz-Algorithm", valid_614934
  var valid_614935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614935 = validateParameter(valid_614935, JString, required = false,
                                 default = nil)
  if valid_614935 != nil:
    section.add "X-Amz-SignedHeaders", valid_614935
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614937: Call_StopTrigger_614925; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a specified trigger.
  ## 
  let valid = call_614937.validator(path, query, header, formData, body)
  let scheme = call_614937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614937.url(scheme.get, call_614937.host, call_614937.base,
                         call_614937.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614937, url, valid)

proc call*(call_614938: Call_StopTrigger_614925; body: JsonNode): Recallable =
  ## stopTrigger
  ## Stops a specified trigger.
  ##   body: JObject (required)
  var body_614939 = newJObject()
  if body != nil:
    body_614939 = body
  result = call_614938.call(nil, nil, nil, nil, body_614939)

var stopTrigger* = Call_StopTrigger_614925(name: "stopTrigger",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StopTrigger",
                                        validator: validate_StopTrigger_614926,
                                        base: "/", url: url_StopTrigger_614927,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_614940 = ref object of OpenApiRestCall_612658
proc url_TagResource_614942(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_614941(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614943 = header.getOrDefault("X-Amz-Target")
  valid_614943 = validateParameter(valid_614943, JString, required = true,
                                 default = newJString("AWSGlue.TagResource"))
  if valid_614943 != nil:
    section.add "X-Amz-Target", valid_614943
  var valid_614944 = header.getOrDefault("X-Amz-Signature")
  valid_614944 = validateParameter(valid_614944, JString, required = false,
                                 default = nil)
  if valid_614944 != nil:
    section.add "X-Amz-Signature", valid_614944
  var valid_614945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614945 = validateParameter(valid_614945, JString, required = false,
                                 default = nil)
  if valid_614945 != nil:
    section.add "X-Amz-Content-Sha256", valid_614945
  var valid_614946 = header.getOrDefault("X-Amz-Date")
  valid_614946 = validateParameter(valid_614946, JString, required = false,
                                 default = nil)
  if valid_614946 != nil:
    section.add "X-Amz-Date", valid_614946
  var valid_614947 = header.getOrDefault("X-Amz-Credential")
  valid_614947 = validateParameter(valid_614947, JString, required = false,
                                 default = nil)
  if valid_614947 != nil:
    section.add "X-Amz-Credential", valid_614947
  var valid_614948 = header.getOrDefault("X-Amz-Security-Token")
  valid_614948 = validateParameter(valid_614948, JString, required = false,
                                 default = nil)
  if valid_614948 != nil:
    section.add "X-Amz-Security-Token", valid_614948
  var valid_614949 = header.getOrDefault("X-Amz-Algorithm")
  valid_614949 = validateParameter(valid_614949, JString, required = false,
                                 default = nil)
  if valid_614949 != nil:
    section.add "X-Amz-Algorithm", valid_614949
  var valid_614950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614950 = validateParameter(valid_614950, JString, required = false,
                                 default = nil)
  if valid_614950 != nil:
    section.add "X-Amz-SignedHeaders", valid_614950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614952: Call_TagResource_614940; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
  ## 
  let valid = call_614952.validator(path, query, header, formData, body)
  let scheme = call_614952.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614952.url(scheme.get, call_614952.host, call_614952.base,
                         call_614952.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614952, url, valid)

proc call*(call_614953: Call_TagResource_614940; body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
  ##   body: JObject (required)
  var body_614954 = newJObject()
  if body != nil:
    body_614954 = body
  result = call_614953.call(nil, nil, nil, nil, body_614954)

var tagResource* = Call_TagResource_614940(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.TagResource",
                                        validator: validate_TagResource_614941,
                                        base: "/", url: url_TagResource_614942,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_614955 = ref object of OpenApiRestCall_612658
proc url_UntagResource_614957(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_614956(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614958 = header.getOrDefault("X-Amz-Target")
  valid_614958 = validateParameter(valid_614958, JString, required = true,
                                 default = newJString("AWSGlue.UntagResource"))
  if valid_614958 != nil:
    section.add "X-Amz-Target", valid_614958
  var valid_614959 = header.getOrDefault("X-Amz-Signature")
  valid_614959 = validateParameter(valid_614959, JString, required = false,
                                 default = nil)
  if valid_614959 != nil:
    section.add "X-Amz-Signature", valid_614959
  var valid_614960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614960 = validateParameter(valid_614960, JString, required = false,
                                 default = nil)
  if valid_614960 != nil:
    section.add "X-Amz-Content-Sha256", valid_614960
  var valid_614961 = header.getOrDefault("X-Amz-Date")
  valid_614961 = validateParameter(valid_614961, JString, required = false,
                                 default = nil)
  if valid_614961 != nil:
    section.add "X-Amz-Date", valid_614961
  var valid_614962 = header.getOrDefault("X-Amz-Credential")
  valid_614962 = validateParameter(valid_614962, JString, required = false,
                                 default = nil)
  if valid_614962 != nil:
    section.add "X-Amz-Credential", valid_614962
  var valid_614963 = header.getOrDefault("X-Amz-Security-Token")
  valid_614963 = validateParameter(valid_614963, JString, required = false,
                                 default = nil)
  if valid_614963 != nil:
    section.add "X-Amz-Security-Token", valid_614963
  var valid_614964 = header.getOrDefault("X-Amz-Algorithm")
  valid_614964 = validateParameter(valid_614964, JString, required = false,
                                 default = nil)
  if valid_614964 != nil:
    section.add "X-Amz-Algorithm", valid_614964
  var valid_614965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614965 = validateParameter(valid_614965, JString, required = false,
                                 default = nil)
  if valid_614965 != nil:
    section.add "X-Amz-SignedHeaders", valid_614965
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614967: Call_UntagResource_614955; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a resource.
  ## 
  let valid = call_614967.validator(path, query, header, formData, body)
  let scheme = call_614967.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614967.url(scheme.get, call_614967.host, call_614967.base,
                         call_614967.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614967, url, valid)

proc call*(call_614968: Call_UntagResource_614955; body: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from a resource.
  ##   body: JObject (required)
  var body_614969 = newJObject()
  if body != nil:
    body_614969 = body
  result = call_614968.call(nil, nil, nil, nil, body_614969)

var untagResource* = Call_UntagResource_614955(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UntagResource",
    validator: validate_UntagResource_614956, base: "/", url: url_UntagResource_614957,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClassifier_614970 = ref object of OpenApiRestCall_612658
proc url_UpdateClassifier_614972(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateClassifier_614971(path: JsonNode; query: JsonNode;
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
  var valid_614973 = header.getOrDefault("X-Amz-Target")
  valid_614973 = validateParameter(valid_614973, JString, required = true, default = newJString(
      "AWSGlue.UpdateClassifier"))
  if valid_614973 != nil:
    section.add "X-Amz-Target", valid_614973
  var valid_614974 = header.getOrDefault("X-Amz-Signature")
  valid_614974 = validateParameter(valid_614974, JString, required = false,
                                 default = nil)
  if valid_614974 != nil:
    section.add "X-Amz-Signature", valid_614974
  var valid_614975 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614975 = validateParameter(valid_614975, JString, required = false,
                                 default = nil)
  if valid_614975 != nil:
    section.add "X-Amz-Content-Sha256", valid_614975
  var valid_614976 = header.getOrDefault("X-Amz-Date")
  valid_614976 = validateParameter(valid_614976, JString, required = false,
                                 default = nil)
  if valid_614976 != nil:
    section.add "X-Amz-Date", valid_614976
  var valid_614977 = header.getOrDefault("X-Amz-Credential")
  valid_614977 = validateParameter(valid_614977, JString, required = false,
                                 default = nil)
  if valid_614977 != nil:
    section.add "X-Amz-Credential", valid_614977
  var valid_614978 = header.getOrDefault("X-Amz-Security-Token")
  valid_614978 = validateParameter(valid_614978, JString, required = false,
                                 default = nil)
  if valid_614978 != nil:
    section.add "X-Amz-Security-Token", valid_614978
  var valid_614979 = header.getOrDefault("X-Amz-Algorithm")
  valid_614979 = validateParameter(valid_614979, JString, required = false,
                                 default = nil)
  if valid_614979 != nil:
    section.add "X-Amz-Algorithm", valid_614979
  var valid_614980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614980 = validateParameter(valid_614980, JString, required = false,
                                 default = nil)
  if valid_614980 != nil:
    section.add "X-Amz-SignedHeaders", valid_614980
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614982: Call_UpdateClassifier_614970; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
  ## 
  let valid = call_614982.validator(path, query, header, formData, body)
  let scheme = call_614982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614982.url(scheme.get, call_614982.host, call_614982.base,
                         call_614982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614982, url, valid)

proc call*(call_614983: Call_UpdateClassifier_614970; body: JsonNode): Recallable =
  ## updateClassifier
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
  ##   body: JObject (required)
  var body_614984 = newJObject()
  if body != nil:
    body_614984 = body
  result = call_614983.call(nil, nil, nil, nil, body_614984)

var updateClassifier* = Call_UpdateClassifier_614970(name: "updateClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateClassifier",
    validator: validate_UpdateClassifier_614971, base: "/",
    url: url_UpdateClassifier_614972, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnection_614985 = ref object of OpenApiRestCall_612658
proc url_UpdateConnection_614987(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateConnection_614986(path: JsonNode; query: JsonNode;
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
  var valid_614988 = header.getOrDefault("X-Amz-Target")
  valid_614988 = validateParameter(valid_614988, JString, required = true, default = newJString(
      "AWSGlue.UpdateConnection"))
  if valid_614988 != nil:
    section.add "X-Amz-Target", valid_614988
  var valid_614989 = header.getOrDefault("X-Amz-Signature")
  valid_614989 = validateParameter(valid_614989, JString, required = false,
                                 default = nil)
  if valid_614989 != nil:
    section.add "X-Amz-Signature", valid_614989
  var valid_614990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614990 = validateParameter(valid_614990, JString, required = false,
                                 default = nil)
  if valid_614990 != nil:
    section.add "X-Amz-Content-Sha256", valid_614990
  var valid_614991 = header.getOrDefault("X-Amz-Date")
  valid_614991 = validateParameter(valid_614991, JString, required = false,
                                 default = nil)
  if valid_614991 != nil:
    section.add "X-Amz-Date", valid_614991
  var valid_614992 = header.getOrDefault("X-Amz-Credential")
  valid_614992 = validateParameter(valid_614992, JString, required = false,
                                 default = nil)
  if valid_614992 != nil:
    section.add "X-Amz-Credential", valid_614992
  var valid_614993 = header.getOrDefault("X-Amz-Security-Token")
  valid_614993 = validateParameter(valid_614993, JString, required = false,
                                 default = nil)
  if valid_614993 != nil:
    section.add "X-Amz-Security-Token", valid_614993
  var valid_614994 = header.getOrDefault("X-Amz-Algorithm")
  valid_614994 = validateParameter(valid_614994, JString, required = false,
                                 default = nil)
  if valid_614994 != nil:
    section.add "X-Amz-Algorithm", valid_614994
  var valid_614995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614995 = validateParameter(valid_614995, JString, required = false,
                                 default = nil)
  if valid_614995 != nil:
    section.add "X-Amz-SignedHeaders", valid_614995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614997: Call_UpdateConnection_614985; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a connection definition in the Data Catalog.
  ## 
  let valid = call_614997.validator(path, query, header, formData, body)
  let scheme = call_614997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614997.url(scheme.get, call_614997.host, call_614997.base,
                         call_614997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614997, url, valid)

proc call*(call_614998: Call_UpdateConnection_614985; body: JsonNode): Recallable =
  ## updateConnection
  ## Updates a connection definition in the Data Catalog.
  ##   body: JObject (required)
  var body_614999 = newJObject()
  if body != nil:
    body_614999 = body
  result = call_614998.call(nil, nil, nil, nil, body_614999)

var updateConnection* = Call_UpdateConnection_614985(name: "updateConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateConnection",
    validator: validate_UpdateConnection_614986, base: "/",
    url: url_UpdateConnection_614987, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCrawler_615000 = ref object of OpenApiRestCall_612658
proc url_UpdateCrawler_615002(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateCrawler_615001(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_615003 = header.getOrDefault("X-Amz-Target")
  valid_615003 = validateParameter(valid_615003, JString, required = true,
                                 default = newJString("AWSGlue.UpdateCrawler"))
  if valid_615003 != nil:
    section.add "X-Amz-Target", valid_615003
  var valid_615004 = header.getOrDefault("X-Amz-Signature")
  valid_615004 = validateParameter(valid_615004, JString, required = false,
                                 default = nil)
  if valid_615004 != nil:
    section.add "X-Amz-Signature", valid_615004
  var valid_615005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615005 = validateParameter(valid_615005, JString, required = false,
                                 default = nil)
  if valid_615005 != nil:
    section.add "X-Amz-Content-Sha256", valid_615005
  var valid_615006 = header.getOrDefault("X-Amz-Date")
  valid_615006 = validateParameter(valid_615006, JString, required = false,
                                 default = nil)
  if valid_615006 != nil:
    section.add "X-Amz-Date", valid_615006
  var valid_615007 = header.getOrDefault("X-Amz-Credential")
  valid_615007 = validateParameter(valid_615007, JString, required = false,
                                 default = nil)
  if valid_615007 != nil:
    section.add "X-Amz-Credential", valid_615007
  var valid_615008 = header.getOrDefault("X-Amz-Security-Token")
  valid_615008 = validateParameter(valid_615008, JString, required = false,
                                 default = nil)
  if valid_615008 != nil:
    section.add "X-Amz-Security-Token", valid_615008
  var valid_615009 = header.getOrDefault("X-Amz-Algorithm")
  valid_615009 = validateParameter(valid_615009, JString, required = false,
                                 default = nil)
  if valid_615009 != nil:
    section.add "X-Amz-Algorithm", valid_615009
  var valid_615010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615010 = validateParameter(valid_615010, JString, required = false,
                                 default = nil)
  if valid_615010 != nil:
    section.add "X-Amz-SignedHeaders", valid_615010
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615012: Call_UpdateCrawler_615000; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
  ## 
  let valid = call_615012.validator(path, query, header, formData, body)
  let scheme = call_615012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615012.url(scheme.get, call_615012.host, call_615012.base,
                         call_615012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615012, url, valid)

proc call*(call_615013: Call_UpdateCrawler_615000; body: JsonNode): Recallable =
  ## updateCrawler
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
  ##   body: JObject (required)
  var body_615014 = newJObject()
  if body != nil:
    body_615014 = body
  result = call_615013.call(nil, nil, nil, nil, body_615014)

var updateCrawler* = Call_UpdateCrawler_615000(name: "updateCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateCrawler",
    validator: validate_UpdateCrawler_615001, base: "/", url: url_UpdateCrawler_615002,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCrawlerSchedule_615015 = ref object of OpenApiRestCall_612658
proc url_UpdateCrawlerSchedule_615017(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateCrawlerSchedule_615016(path: JsonNode; query: JsonNode;
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
  var valid_615018 = header.getOrDefault("X-Amz-Target")
  valid_615018 = validateParameter(valid_615018, JString, required = true, default = newJString(
      "AWSGlue.UpdateCrawlerSchedule"))
  if valid_615018 != nil:
    section.add "X-Amz-Target", valid_615018
  var valid_615019 = header.getOrDefault("X-Amz-Signature")
  valid_615019 = validateParameter(valid_615019, JString, required = false,
                                 default = nil)
  if valid_615019 != nil:
    section.add "X-Amz-Signature", valid_615019
  var valid_615020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615020 = validateParameter(valid_615020, JString, required = false,
                                 default = nil)
  if valid_615020 != nil:
    section.add "X-Amz-Content-Sha256", valid_615020
  var valid_615021 = header.getOrDefault("X-Amz-Date")
  valid_615021 = validateParameter(valid_615021, JString, required = false,
                                 default = nil)
  if valid_615021 != nil:
    section.add "X-Amz-Date", valid_615021
  var valid_615022 = header.getOrDefault("X-Amz-Credential")
  valid_615022 = validateParameter(valid_615022, JString, required = false,
                                 default = nil)
  if valid_615022 != nil:
    section.add "X-Amz-Credential", valid_615022
  var valid_615023 = header.getOrDefault("X-Amz-Security-Token")
  valid_615023 = validateParameter(valid_615023, JString, required = false,
                                 default = nil)
  if valid_615023 != nil:
    section.add "X-Amz-Security-Token", valid_615023
  var valid_615024 = header.getOrDefault("X-Amz-Algorithm")
  valid_615024 = validateParameter(valid_615024, JString, required = false,
                                 default = nil)
  if valid_615024 != nil:
    section.add "X-Amz-Algorithm", valid_615024
  var valid_615025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615025 = validateParameter(valid_615025, JString, required = false,
                                 default = nil)
  if valid_615025 != nil:
    section.add "X-Amz-SignedHeaders", valid_615025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615027: Call_UpdateCrawlerSchedule_615015; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
  ## 
  let valid = call_615027.validator(path, query, header, formData, body)
  let scheme = call_615027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615027.url(scheme.get, call_615027.host, call_615027.base,
                         call_615027.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615027, url, valid)

proc call*(call_615028: Call_UpdateCrawlerSchedule_615015; body: JsonNode): Recallable =
  ## updateCrawlerSchedule
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
  ##   body: JObject (required)
  var body_615029 = newJObject()
  if body != nil:
    body_615029 = body
  result = call_615028.call(nil, nil, nil, nil, body_615029)

var updateCrawlerSchedule* = Call_UpdateCrawlerSchedule_615015(
    name: "updateCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateCrawlerSchedule",
    validator: validate_UpdateCrawlerSchedule_615016, base: "/",
    url: url_UpdateCrawlerSchedule_615017, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDatabase_615030 = ref object of OpenApiRestCall_612658
proc url_UpdateDatabase_615032(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDatabase_615031(path: JsonNode; query: JsonNode;
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
  var valid_615033 = header.getOrDefault("X-Amz-Target")
  valid_615033 = validateParameter(valid_615033, JString, required = true,
                                 default = newJString("AWSGlue.UpdateDatabase"))
  if valid_615033 != nil:
    section.add "X-Amz-Target", valid_615033
  var valid_615034 = header.getOrDefault("X-Amz-Signature")
  valid_615034 = validateParameter(valid_615034, JString, required = false,
                                 default = nil)
  if valid_615034 != nil:
    section.add "X-Amz-Signature", valid_615034
  var valid_615035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615035 = validateParameter(valid_615035, JString, required = false,
                                 default = nil)
  if valid_615035 != nil:
    section.add "X-Amz-Content-Sha256", valid_615035
  var valid_615036 = header.getOrDefault("X-Amz-Date")
  valid_615036 = validateParameter(valid_615036, JString, required = false,
                                 default = nil)
  if valid_615036 != nil:
    section.add "X-Amz-Date", valid_615036
  var valid_615037 = header.getOrDefault("X-Amz-Credential")
  valid_615037 = validateParameter(valid_615037, JString, required = false,
                                 default = nil)
  if valid_615037 != nil:
    section.add "X-Amz-Credential", valid_615037
  var valid_615038 = header.getOrDefault("X-Amz-Security-Token")
  valid_615038 = validateParameter(valid_615038, JString, required = false,
                                 default = nil)
  if valid_615038 != nil:
    section.add "X-Amz-Security-Token", valid_615038
  var valid_615039 = header.getOrDefault("X-Amz-Algorithm")
  valid_615039 = validateParameter(valid_615039, JString, required = false,
                                 default = nil)
  if valid_615039 != nil:
    section.add "X-Amz-Algorithm", valid_615039
  var valid_615040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615040 = validateParameter(valid_615040, JString, required = false,
                                 default = nil)
  if valid_615040 != nil:
    section.add "X-Amz-SignedHeaders", valid_615040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615042: Call_UpdateDatabase_615030; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing database definition in a Data Catalog.
  ## 
  let valid = call_615042.validator(path, query, header, formData, body)
  let scheme = call_615042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615042.url(scheme.get, call_615042.host, call_615042.base,
                         call_615042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615042, url, valid)

proc call*(call_615043: Call_UpdateDatabase_615030; body: JsonNode): Recallable =
  ## updateDatabase
  ## Updates an existing database definition in a Data Catalog.
  ##   body: JObject (required)
  var body_615044 = newJObject()
  if body != nil:
    body_615044 = body
  result = call_615043.call(nil, nil, nil, nil, body_615044)

var updateDatabase* = Call_UpdateDatabase_615030(name: "updateDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateDatabase",
    validator: validate_UpdateDatabase_615031, base: "/", url: url_UpdateDatabase_615032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevEndpoint_615045 = ref object of OpenApiRestCall_612658
proc url_UpdateDevEndpoint_615047(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDevEndpoint_615046(path: JsonNode; query: JsonNode;
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
  var valid_615048 = header.getOrDefault("X-Amz-Target")
  valid_615048 = validateParameter(valid_615048, JString, required = true, default = newJString(
      "AWSGlue.UpdateDevEndpoint"))
  if valid_615048 != nil:
    section.add "X-Amz-Target", valid_615048
  var valid_615049 = header.getOrDefault("X-Amz-Signature")
  valid_615049 = validateParameter(valid_615049, JString, required = false,
                                 default = nil)
  if valid_615049 != nil:
    section.add "X-Amz-Signature", valid_615049
  var valid_615050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615050 = validateParameter(valid_615050, JString, required = false,
                                 default = nil)
  if valid_615050 != nil:
    section.add "X-Amz-Content-Sha256", valid_615050
  var valid_615051 = header.getOrDefault("X-Amz-Date")
  valid_615051 = validateParameter(valid_615051, JString, required = false,
                                 default = nil)
  if valid_615051 != nil:
    section.add "X-Amz-Date", valid_615051
  var valid_615052 = header.getOrDefault("X-Amz-Credential")
  valid_615052 = validateParameter(valid_615052, JString, required = false,
                                 default = nil)
  if valid_615052 != nil:
    section.add "X-Amz-Credential", valid_615052
  var valid_615053 = header.getOrDefault("X-Amz-Security-Token")
  valid_615053 = validateParameter(valid_615053, JString, required = false,
                                 default = nil)
  if valid_615053 != nil:
    section.add "X-Amz-Security-Token", valid_615053
  var valid_615054 = header.getOrDefault("X-Amz-Algorithm")
  valid_615054 = validateParameter(valid_615054, JString, required = false,
                                 default = nil)
  if valid_615054 != nil:
    section.add "X-Amz-Algorithm", valid_615054
  var valid_615055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615055 = validateParameter(valid_615055, JString, required = false,
                                 default = nil)
  if valid_615055 != nil:
    section.add "X-Amz-SignedHeaders", valid_615055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615057: Call_UpdateDevEndpoint_615045; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a specified development endpoint.
  ## 
  let valid = call_615057.validator(path, query, header, formData, body)
  let scheme = call_615057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615057.url(scheme.get, call_615057.host, call_615057.base,
                         call_615057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615057, url, valid)

proc call*(call_615058: Call_UpdateDevEndpoint_615045; body: JsonNode): Recallable =
  ## updateDevEndpoint
  ## Updates a specified development endpoint.
  ##   body: JObject (required)
  var body_615059 = newJObject()
  if body != nil:
    body_615059 = body
  result = call_615058.call(nil, nil, nil, nil, body_615059)

var updateDevEndpoint* = Call_UpdateDevEndpoint_615045(name: "updateDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateDevEndpoint",
    validator: validate_UpdateDevEndpoint_615046, base: "/",
    url: url_UpdateDevEndpoint_615047, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJob_615060 = ref object of OpenApiRestCall_612658
proc url_UpdateJob_615062(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateJob_615061(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_615063 = header.getOrDefault("X-Amz-Target")
  valid_615063 = validateParameter(valid_615063, JString, required = true,
                                 default = newJString("AWSGlue.UpdateJob"))
  if valid_615063 != nil:
    section.add "X-Amz-Target", valid_615063
  var valid_615064 = header.getOrDefault("X-Amz-Signature")
  valid_615064 = validateParameter(valid_615064, JString, required = false,
                                 default = nil)
  if valid_615064 != nil:
    section.add "X-Amz-Signature", valid_615064
  var valid_615065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615065 = validateParameter(valid_615065, JString, required = false,
                                 default = nil)
  if valid_615065 != nil:
    section.add "X-Amz-Content-Sha256", valid_615065
  var valid_615066 = header.getOrDefault("X-Amz-Date")
  valid_615066 = validateParameter(valid_615066, JString, required = false,
                                 default = nil)
  if valid_615066 != nil:
    section.add "X-Amz-Date", valid_615066
  var valid_615067 = header.getOrDefault("X-Amz-Credential")
  valid_615067 = validateParameter(valid_615067, JString, required = false,
                                 default = nil)
  if valid_615067 != nil:
    section.add "X-Amz-Credential", valid_615067
  var valid_615068 = header.getOrDefault("X-Amz-Security-Token")
  valid_615068 = validateParameter(valid_615068, JString, required = false,
                                 default = nil)
  if valid_615068 != nil:
    section.add "X-Amz-Security-Token", valid_615068
  var valid_615069 = header.getOrDefault("X-Amz-Algorithm")
  valid_615069 = validateParameter(valid_615069, JString, required = false,
                                 default = nil)
  if valid_615069 != nil:
    section.add "X-Amz-Algorithm", valid_615069
  var valid_615070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615070 = validateParameter(valid_615070, JString, required = false,
                                 default = nil)
  if valid_615070 != nil:
    section.add "X-Amz-SignedHeaders", valid_615070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615072: Call_UpdateJob_615060; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing job definition.
  ## 
  let valid = call_615072.validator(path, query, header, formData, body)
  let scheme = call_615072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615072.url(scheme.get, call_615072.host, call_615072.base,
                         call_615072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615072, url, valid)

proc call*(call_615073: Call_UpdateJob_615060; body: JsonNode): Recallable =
  ## updateJob
  ## Updates an existing job definition.
  ##   body: JObject (required)
  var body_615074 = newJObject()
  if body != nil:
    body_615074 = body
  result = call_615073.call(nil, nil, nil, nil, body_615074)

var updateJob* = Call_UpdateJob_615060(name: "updateJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.UpdateJob",
                                    validator: validate_UpdateJob_615061,
                                    base: "/", url: url_UpdateJob_615062,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMLTransform_615075 = ref object of OpenApiRestCall_612658
proc url_UpdateMLTransform_615077(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMLTransform_615076(path: JsonNode; query: JsonNode;
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
  var valid_615078 = header.getOrDefault("X-Amz-Target")
  valid_615078 = validateParameter(valid_615078, JString, required = true, default = newJString(
      "AWSGlue.UpdateMLTransform"))
  if valid_615078 != nil:
    section.add "X-Amz-Target", valid_615078
  var valid_615079 = header.getOrDefault("X-Amz-Signature")
  valid_615079 = validateParameter(valid_615079, JString, required = false,
                                 default = nil)
  if valid_615079 != nil:
    section.add "X-Amz-Signature", valid_615079
  var valid_615080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615080 = validateParameter(valid_615080, JString, required = false,
                                 default = nil)
  if valid_615080 != nil:
    section.add "X-Amz-Content-Sha256", valid_615080
  var valid_615081 = header.getOrDefault("X-Amz-Date")
  valid_615081 = validateParameter(valid_615081, JString, required = false,
                                 default = nil)
  if valid_615081 != nil:
    section.add "X-Amz-Date", valid_615081
  var valid_615082 = header.getOrDefault("X-Amz-Credential")
  valid_615082 = validateParameter(valid_615082, JString, required = false,
                                 default = nil)
  if valid_615082 != nil:
    section.add "X-Amz-Credential", valid_615082
  var valid_615083 = header.getOrDefault("X-Amz-Security-Token")
  valid_615083 = validateParameter(valid_615083, JString, required = false,
                                 default = nil)
  if valid_615083 != nil:
    section.add "X-Amz-Security-Token", valid_615083
  var valid_615084 = header.getOrDefault("X-Amz-Algorithm")
  valid_615084 = validateParameter(valid_615084, JString, required = false,
                                 default = nil)
  if valid_615084 != nil:
    section.add "X-Amz-Algorithm", valid_615084
  var valid_615085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615085 = validateParameter(valid_615085, JString, required = false,
                                 default = nil)
  if valid_615085 != nil:
    section.add "X-Amz-SignedHeaders", valid_615085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615087: Call_UpdateMLTransform_615075; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
  ## 
  let valid = call_615087.validator(path, query, header, formData, body)
  let scheme = call_615087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615087.url(scheme.get, call_615087.host, call_615087.base,
                         call_615087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615087, url, valid)

proc call*(call_615088: Call_UpdateMLTransform_615075; body: JsonNode): Recallable =
  ## updateMLTransform
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
  ##   body: JObject (required)
  var body_615089 = newJObject()
  if body != nil:
    body_615089 = body
  result = call_615088.call(nil, nil, nil, nil, body_615089)

var updateMLTransform* = Call_UpdateMLTransform_615075(name: "updateMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateMLTransform",
    validator: validate_UpdateMLTransform_615076, base: "/",
    url: url_UpdateMLTransform_615077, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePartition_615090 = ref object of OpenApiRestCall_612658
proc url_UpdatePartition_615092(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePartition_615091(path: JsonNode; query: JsonNode;
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
  var valid_615093 = header.getOrDefault("X-Amz-Target")
  valid_615093 = validateParameter(valid_615093, JString, required = true, default = newJString(
      "AWSGlue.UpdatePartition"))
  if valid_615093 != nil:
    section.add "X-Amz-Target", valid_615093
  var valid_615094 = header.getOrDefault("X-Amz-Signature")
  valid_615094 = validateParameter(valid_615094, JString, required = false,
                                 default = nil)
  if valid_615094 != nil:
    section.add "X-Amz-Signature", valid_615094
  var valid_615095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615095 = validateParameter(valid_615095, JString, required = false,
                                 default = nil)
  if valid_615095 != nil:
    section.add "X-Amz-Content-Sha256", valid_615095
  var valid_615096 = header.getOrDefault("X-Amz-Date")
  valid_615096 = validateParameter(valid_615096, JString, required = false,
                                 default = nil)
  if valid_615096 != nil:
    section.add "X-Amz-Date", valid_615096
  var valid_615097 = header.getOrDefault("X-Amz-Credential")
  valid_615097 = validateParameter(valid_615097, JString, required = false,
                                 default = nil)
  if valid_615097 != nil:
    section.add "X-Amz-Credential", valid_615097
  var valid_615098 = header.getOrDefault("X-Amz-Security-Token")
  valid_615098 = validateParameter(valid_615098, JString, required = false,
                                 default = nil)
  if valid_615098 != nil:
    section.add "X-Amz-Security-Token", valid_615098
  var valid_615099 = header.getOrDefault("X-Amz-Algorithm")
  valid_615099 = validateParameter(valid_615099, JString, required = false,
                                 default = nil)
  if valid_615099 != nil:
    section.add "X-Amz-Algorithm", valid_615099
  var valid_615100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615100 = validateParameter(valid_615100, JString, required = false,
                                 default = nil)
  if valid_615100 != nil:
    section.add "X-Amz-SignedHeaders", valid_615100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615102: Call_UpdatePartition_615090; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a partition.
  ## 
  let valid = call_615102.validator(path, query, header, formData, body)
  let scheme = call_615102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615102.url(scheme.get, call_615102.host, call_615102.base,
                         call_615102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615102, url, valid)

proc call*(call_615103: Call_UpdatePartition_615090; body: JsonNode): Recallable =
  ## updatePartition
  ## Updates a partition.
  ##   body: JObject (required)
  var body_615104 = newJObject()
  if body != nil:
    body_615104 = body
  result = call_615103.call(nil, nil, nil, nil, body_615104)

var updatePartition* = Call_UpdatePartition_615090(name: "updatePartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdatePartition",
    validator: validate_UpdatePartition_615091, base: "/", url: url_UpdatePartition_615092,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTable_615105 = ref object of OpenApiRestCall_612658
proc url_UpdateTable_615107(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTable_615106(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_615108 = header.getOrDefault("X-Amz-Target")
  valid_615108 = validateParameter(valid_615108, JString, required = true,
                                 default = newJString("AWSGlue.UpdateTable"))
  if valid_615108 != nil:
    section.add "X-Amz-Target", valid_615108
  var valid_615109 = header.getOrDefault("X-Amz-Signature")
  valid_615109 = validateParameter(valid_615109, JString, required = false,
                                 default = nil)
  if valid_615109 != nil:
    section.add "X-Amz-Signature", valid_615109
  var valid_615110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615110 = validateParameter(valid_615110, JString, required = false,
                                 default = nil)
  if valid_615110 != nil:
    section.add "X-Amz-Content-Sha256", valid_615110
  var valid_615111 = header.getOrDefault("X-Amz-Date")
  valid_615111 = validateParameter(valid_615111, JString, required = false,
                                 default = nil)
  if valid_615111 != nil:
    section.add "X-Amz-Date", valid_615111
  var valid_615112 = header.getOrDefault("X-Amz-Credential")
  valid_615112 = validateParameter(valid_615112, JString, required = false,
                                 default = nil)
  if valid_615112 != nil:
    section.add "X-Amz-Credential", valid_615112
  var valid_615113 = header.getOrDefault("X-Amz-Security-Token")
  valid_615113 = validateParameter(valid_615113, JString, required = false,
                                 default = nil)
  if valid_615113 != nil:
    section.add "X-Amz-Security-Token", valid_615113
  var valid_615114 = header.getOrDefault("X-Amz-Algorithm")
  valid_615114 = validateParameter(valid_615114, JString, required = false,
                                 default = nil)
  if valid_615114 != nil:
    section.add "X-Amz-Algorithm", valid_615114
  var valid_615115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615115 = validateParameter(valid_615115, JString, required = false,
                                 default = nil)
  if valid_615115 != nil:
    section.add "X-Amz-SignedHeaders", valid_615115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615117: Call_UpdateTable_615105; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a metadata table in the Data Catalog.
  ## 
  let valid = call_615117.validator(path, query, header, formData, body)
  let scheme = call_615117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615117.url(scheme.get, call_615117.host, call_615117.base,
                         call_615117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615117, url, valid)

proc call*(call_615118: Call_UpdateTable_615105; body: JsonNode): Recallable =
  ## updateTable
  ## Updates a metadata table in the Data Catalog.
  ##   body: JObject (required)
  var body_615119 = newJObject()
  if body != nil:
    body_615119 = body
  result = call_615118.call(nil, nil, nil, nil, body_615119)

var updateTable* = Call_UpdateTable_615105(name: "updateTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.UpdateTable",
                                        validator: validate_UpdateTable_615106,
                                        base: "/", url: url_UpdateTable_615107,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrigger_615120 = ref object of OpenApiRestCall_612658
proc url_UpdateTrigger_615122(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTrigger_615121(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_615123 = header.getOrDefault("X-Amz-Target")
  valid_615123 = validateParameter(valid_615123, JString, required = true,
                                 default = newJString("AWSGlue.UpdateTrigger"))
  if valid_615123 != nil:
    section.add "X-Amz-Target", valid_615123
  var valid_615124 = header.getOrDefault("X-Amz-Signature")
  valid_615124 = validateParameter(valid_615124, JString, required = false,
                                 default = nil)
  if valid_615124 != nil:
    section.add "X-Amz-Signature", valid_615124
  var valid_615125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615125 = validateParameter(valid_615125, JString, required = false,
                                 default = nil)
  if valid_615125 != nil:
    section.add "X-Amz-Content-Sha256", valid_615125
  var valid_615126 = header.getOrDefault("X-Amz-Date")
  valid_615126 = validateParameter(valid_615126, JString, required = false,
                                 default = nil)
  if valid_615126 != nil:
    section.add "X-Amz-Date", valid_615126
  var valid_615127 = header.getOrDefault("X-Amz-Credential")
  valid_615127 = validateParameter(valid_615127, JString, required = false,
                                 default = nil)
  if valid_615127 != nil:
    section.add "X-Amz-Credential", valid_615127
  var valid_615128 = header.getOrDefault("X-Amz-Security-Token")
  valid_615128 = validateParameter(valid_615128, JString, required = false,
                                 default = nil)
  if valid_615128 != nil:
    section.add "X-Amz-Security-Token", valid_615128
  var valid_615129 = header.getOrDefault("X-Amz-Algorithm")
  valid_615129 = validateParameter(valid_615129, JString, required = false,
                                 default = nil)
  if valid_615129 != nil:
    section.add "X-Amz-Algorithm", valid_615129
  var valid_615130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615130 = validateParameter(valid_615130, JString, required = false,
                                 default = nil)
  if valid_615130 != nil:
    section.add "X-Amz-SignedHeaders", valid_615130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615132: Call_UpdateTrigger_615120; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a trigger definition.
  ## 
  let valid = call_615132.validator(path, query, header, formData, body)
  let scheme = call_615132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615132.url(scheme.get, call_615132.host, call_615132.base,
                         call_615132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615132, url, valid)

proc call*(call_615133: Call_UpdateTrigger_615120; body: JsonNode): Recallable =
  ## updateTrigger
  ## Updates a trigger definition.
  ##   body: JObject (required)
  var body_615134 = newJObject()
  if body != nil:
    body_615134 = body
  result = call_615133.call(nil, nil, nil, nil, body_615134)

var updateTrigger* = Call_UpdateTrigger_615120(name: "updateTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateTrigger",
    validator: validate_UpdateTrigger_615121, base: "/", url: url_UpdateTrigger_615122,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserDefinedFunction_615135 = ref object of OpenApiRestCall_612658
proc url_UpdateUserDefinedFunction_615137(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUserDefinedFunction_615136(path: JsonNode; query: JsonNode;
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
  var valid_615138 = header.getOrDefault("X-Amz-Target")
  valid_615138 = validateParameter(valid_615138, JString, required = true, default = newJString(
      "AWSGlue.UpdateUserDefinedFunction"))
  if valid_615138 != nil:
    section.add "X-Amz-Target", valid_615138
  var valid_615139 = header.getOrDefault("X-Amz-Signature")
  valid_615139 = validateParameter(valid_615139, JString, required = false,
                                 default = nil)
  if valid_615139 != nil:
    section.add "X-Amz-Signature", valid_615139
  var valid_615140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615140 = validateParameter(valid_615140, JString, required = false,
                                 default = nil)
  if valid_615140 != nil:
    section.add "X-Amz-Content-Sha256", valid_615140
  var valid_615141 = header.getOrDefault("X-Amz-Date")
  valid_615141 = validateParameter(valid_615141, JString, required = false,
                                 default = nil)
  if valid_615141 != nil:
    section.add "X-Amz-Date", valid_615141
  var valid_615142 = header.getOrDefault("X-Amz-Credential")
  valid_615142 = validateParameter(valid_615142, JString, required = false,
                                 default = nil)
  if valid_615142 != nil:
    section.add "X-Amz-Credential", valid_615142
  var valid_615143 = header.getOrDefault("X-Amz-Security-Token")
  valid_615143 = validateParameter(valid_615143, JString, required = false,
                                 default = nil)
  if valid_615143 != nil:
    section.add "X-Amz-Security-Token", valid_615143
  var valid_615144 = header.getOrDefault("X-Amz-Algorithm")
  valid_615144 = validateParameter(valid_615144, JString, required = false,
                                 default = nil)
  if valid_615144 != nil:
    section.add "X-Amz-Algorithm", valid_615144
  var valid_615145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615145 = validateParameter(valid_615145, JString, required = false,
                                 default = nil)
  if valid_615145 != nil:
    section.add "X-Amz-SignedHeaders", valid_615145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615147: Call_UpdateUserDefinedFunction_615135; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing function definition in the Data Catalog.
  ## 
  let valid = call_615147.validator(path, query, header, formData, body)
  let scheme = call_615147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615147.url(scheme.get, call_615147.host, call_615147.base,
                         call_615147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615147, url, valid)

proc call*(call_615148: Call_UpdateUserDefinedFunction_615135; body: JsonNode): Recallable =
  ## updateUserDefinedFunction
  ## Updates an existing function definition in the Data Catalog.
  ##   body: JObject (required)
  var body_615149 = newJObject()
  if body != nil:
    body_615149 = body
  result = call_615148.call(nil, nil, nil, nil, body_615149)

var updateUserDefinedFunction* = Call_UpdateUserDefinedFunction_615135(
    name: "updateUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateUserDefinedFunction",
    validator: validate_UpdateUserDefinedFunction_615136, base: "/",
    url: url_UpdateUserDefinedFunction_615137,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkflow_615150 = ref object of OpenApiRestCall_612658
proc url_UpdateWorkflow_615152(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateWorkflow_615151(path: JsonNode; query: JsonNode;
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
  var valid_615153 = header.getOrDefault("X-Amz-Target")
  valid_615153 = validateParameter(valid_615153, JString, required = true,
                                 default = newJString("AWSGlue.UpdateWorkflow"))
  if valid_615153 != nil:
    section.add "X-Amz-Target", valid_615153
  var valid_615154 = header.getOrDefault("X-Amz-Signature")
  valid_615154 = validateParameter(valid_615154, JString, required = false,
                                 default = nil)
  if valid_615154 != nil:
    section.add "X-Amz-Signature", valid_615154
  var valid_615155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615155 = validateParameter(valid_615155, JString, required = false,
                                 default = nil)
  if valid_615155 != nil:
    section.add "X-Amz-Content-Sha256", valid_615155
  var valid_615156 = header.getOrDefault("X-Amz-Date")
  valid_615156 = validateParameter(valid_615156, JString, required = false,
                                 default = nil)
  if valid_615156 != nil:
    section.add "X-Amz-Date", valid_615156
  var valid_615157 = header.getOrDefault("X-Amz-Credential")
  valid_615157 = validateParameter(valid_615157, JString, required = false,
                                 default = nil)
  if valid_615157 != nil:
    section.add "X-Amz-Credential", valid_615157
  var valid_615158 = header.getOrDefault("X-Amz-Security-Token")
  valid_615158 = validateParameter(valid_615158, JString, required = false,
                                 default = nil)
  if valid_615158 != nil:
    section.add "X-Amz-Security-Token", valid_615158
  var valid_615159 = header.getOrDefault("X-Amz-Algorithm")
  valid_615159 = validateParameter(valid_615159, JString, required = false,
                                 default = nil)
  if valid_615159 != nil:
    section.add "X-Amz-Algorithm", valid_615159
  var valid_615160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615160 = validateParameter(valid_615160, JString, required = false,
                                 default = nil)
  if valid_615160 != nil:
    section.add "X-Amz-SignedHeaders", valid_615160
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615162: Call_UpdateWorkflow_615150; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing workflow.
  ## 
  let valid = call_615162.validator(path, query, header, formData, body)
  let scheme = call_615162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615162.url(scheme.get, call_615162.host, call_615162.base,
                         call_615162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615162, url, valid)

proc call*(call_615163: Call_UpdateWorkflow_615150; body: JsonNode): Recallable =
  ## updateWorkflow
  ## Updates an existing workflow.
  ##   body: JObject (required)
  var body_615164 = newJObject()
  if body != nil:
    body_615164 = body
  result = call_615163.call(nil, nil, nil, nil, body_615164)

var updateWorkflow* = Call_UpdateWorkflow_615150(name: "updateWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateWorkflow",
    validator: validate_UpdateWorkflow_615151, base: "/", url: url_UpdateWorkflow_615152,
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
