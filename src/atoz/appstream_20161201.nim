
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon AppStream
## version: 2016-12-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon AppStream 2.0</fullname> <p>This is the <i>Amazon AppStream 2.0 API Reference</i>. This documentation provides descriptions and syntax for each of the actions and data types in AppStream 2.0. AppStream 2.0 is a fully managed, secure application streaming service that lets you stream desktop applications to users without rewriting applications. AppStream 2.0 manages the AWS resources that are required to host and run your applications, scales automatically, and provides access to your users on demand. </p> <note> <p>You can call the AppStream 2.0 API operations by using an interface VPC endpoint (interface endpoint). For more information, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/access-api-cli-through-interface-vpc-endpoint.html">Access AppStream 2.0 API Operations and CLI Commands Through an Interface VPC Endpoint</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p> </note> <p>To learn more about AppStream 2.0, see the following resources:</p> <ul> <li> <p> <a href="http://aws.amazon.com/appstream2">Amazon AppStream 2.0 product page</a> </p> </li> <li> <p> <a href="http://aws.amazon.com/documentation/appstream2">Amazon AppStream 2.0 documentation</a> </p> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/appstream2/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "appstream2.ap-northeast-1.amazonaws.com", "ap-southeast-1": "appstream2.ap-southeast-1.amazonaws.com",
                           "us-west-2": "appstream2.us-west-2.amazonaws.com",
                           "eu-west-2": "appstream2.eu-west-2.amazonaws.com", "ap-northeast-3": "appstream2.ap-northeast-3.amazonaws.com", "eu-central-1": "appstream2.eu-central-1.amazonaws.com",
                           "us-east-2": "appstream2.us-east-2.amazonaws.com",
                           "us-east-1": "appstream2.us-east-1.amazonaws.com", "cn-northwest-1": "appstream2.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "appstream2.ap-south-1.amazonaws.com",
                           "eu-north-1": "appstream2.eu-north-1.amazonaws.com", "ap-northeast-2": "appstream2.ap-northeast-2.amazonaws.com",
                           "us-west-1": "appstream2.us-west-1.amazonaws.com", "us-gov-east-1": "appstream2.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "appstream2.eu-west-3.amazonaws.com", "cn-north-1": "appstream2.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "appstream2.sa-east-1.amazonaws.com",
                           "eu-west-1": "appstream2.eu-west-1.amazonaws.com", "us-gov-west-1": "appstream2.us-gov-west-1.amazonaws.com", "ap-southeast-2": "appstream2.ap-southeast-2.amazonaws.com", "ca-central-1": "appstream2.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "appstream2.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "appstream2.ap-southeast-1.amazonaws.com",
      "us-west-2": "appstream2.us-west-2.amazonaws.com",
      "eu-west-2": "appstream2.eu-west-2.amazonaws.com",
      "ap-northeast-3": "appstream2.ap-northeast-3.amazonaws.com",
      "eu-central-1": "appstream2.eu-central-1.amazonaws.com",
      "us-east-2": "appstream2.us-east-2.amazonaws.com",
      "us-east-1": "appstream2.us-east-1.amazonaws.com",
      "cn-northwest-1": "appstream2.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "appstream2.ap-south-1.amazonaws.com",
      "eu-north-1": "appstream2.eu-north-1.amazonaws.com",
      "ap-northeast-2": "appstream2.ap-northeast-2.amazonaws.com",
      "us-west-1": "appstream2.us-west-1.amazonaws.com",
      "us-gov-east-1": "appstream2.us-gov-east-1.amazonaws.com",
      "eu-west-3": "appstream2.eu-west-3.amazonaws.com",
      "cn-north-1": "appstream2.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "appstream2.sa-east-1.amazonaws.com",
      "eu-west-1": "appstream2.eu-west-1.amazonaws.com",
      "us-gov-west-1": "appstream2.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "appstream2.ap-southeast-2.amazonaws.com",
      "ca-central-1": "appstream2.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "appstream"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateFleet_610996 = ref object of OpenApiRestCall_610658
proc url_AssociateFleet_610998(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateFleet_610997(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Associates the specified fleet with the specified stack.
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
      "PhotonAdminProxyService.AssociateFleet"))
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

proc call*(call_611154: Call_AssociateFleet_610996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified fleet with the specified stack.
  ## 
  let valid = call_611154.validator(path, query, header, formData, body)
  let scheme = call_611154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611154.url(scheme.get, call_611154.host, call_611154.base,
                         call_611154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611154, url, valid)

proc call*(call_611225: Call_AssociateFleet_610996; body: JsonNode): Recallable =
  ## associateFleet
  ## Associates the specified fleet with the specified stack.
  ##   body: JObject (required)
  var body_611226 = newJObject()
  if body != nil:
    body_611226 = body
  result = call_611225.call(nil, nil, nil, nil, body_611226)

var associateFleet* = Call_AssociateFleet_610996(name: "associateFleet",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.AssociateFleet",
    validator: validate_AssociateFleet_610997, base: "/", url: url_AssociateFleet_610998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchAssociateUserStack_611265 = ref object of OpenApiRestCall_610658
proc url_BatchAssociateUserStack_611267(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchAssociateUserStack_611266(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates the specified users with the specified stacks. Users in a user pool cannot be assigned to stacks with fleets that are joined to an Active Directory domain.
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
      "PhotonAdminProxyService.BatchAssociateUserStack"))
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

proc call*(call_611277: Call_BatchAssociateUserStack_611265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified users with the specified stacks. Users in a user pool cannot be assigned to stacks with fleets that are joined to an Active Directory domain.
  ## 
  let valid = call_611277.validator(path, query, header, formData, body)
  let scheme = call_611277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611277.url(scheme.get, call_611277.host, call_611277.base,
                         call_611277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611277, url, valid)

proc call*(call_611278: Call_BatchAssociateUserStack_611265; body: JsonNode): Recallable =
  ## batchAssociateUserStack
  ## Associates the specified users with the specified stacks. Users in a user pool cannot be assigned to stacks with fleets that are joined to an Active Directory domain.
  ##   body: JObject (required)
  var body_611279 = newJObject()
  if body != nil:
    body_611279 = body
  result = call_611278.call(nil, nil, nil, nil, body_611279)

var batchAssociateUserStack* = Call_BatchAssociateUserStack_611265(
    name: "batchAssociateUserStack", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.BatchAssociateUserStack",
    validator: validate_BatchAssociateUserStack_611266, base: "/",
    url: url_BatchAssociateUserStack_611267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDisassociateUserStack_611280 = ref object of OpenApiRestCall_610658
proc url_BatchDisassociateUserStack_611282(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDisassociateUserStack_611281(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates the specified users from the specified stacks.
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
      "PhotonAdminProxyService.BatchDisassociateUserStack"))
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

proc call*(call_611292: Call_BatchDisassociateUserStack_611280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified users from the specified stacks.
  ## 
  let valid = call_611292.validator(path, query, header, formData, body)
  let scheme = call_611292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611292.url(scheme.get, call_611292.host, call_611292.base,
                         call_611292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611292, url, valid)

proc call*(call_611293: Call_BatchDisassociateUserStack_611280; body: JsonNode): Recallable =
  ## batchDisassociateUserStack
  ## Disassociates the specified users from the specified stacks.
  ##   body: JObject (required)
  var body_611294 = newJObject()
  if body != nil:
    body_611294 = body
  result = call_611293.call(nil, nil, nil, nil, body_611294)

var batchDisassociateUserStack* = Call_BatchDisassociateUserStack_611280(
    name: "batchDisassociateUserStack", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.BatchDisassociateUserStack",
    validator: validate_BatchDisassociateUserStack_611281, base: "/",
    url: url_BatchDisassociateUserStack_611282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyImage_611295 = ref object of OpenApiRestCall_610658
proc url_CopyImage_611297(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CopyImage_611296(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Copies the image within the same region or to a new region within the same AWS account. Note that any tags you added to the image will not be copied.
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
      "PhotonAdminProxyService.CopyImage"))
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

proc call*(call_611307: Call_CopyImage_611295; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the image within the same region or to a new region within the same AWS account. Note that any tags you added to the image will not be copied.
  ## 
  let valid = call_611307.validator(path, query, header, formData, body)
  let scheme = call_611307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611307.url(scheme.get, call_611307.host, call_611307.base,
                         call_611307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611307, url, valid)

proc call*(call_611308: Call_CopyImage_611295; body: JsonNode): Recallable =
  ## copyImage
  ## Copies the image within the same region or to a new region within the same AWS account. Note that any tags you added to the image will not be copied.
  ##   body: JObject (required)
  var body_611309 = newJObject()
  if body != nil:
    body_611309 = body
  result = call_611308.call(nil, nil, nil, nil, body_611309)

var copyImage* = Call_CopyImage_611295(name: "copyImage", meth: HttpMethod.HttpPost,
                                    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.CopyImage",
                                    validator: validate_CopyImage_611296,
                                    base: "/", url: url_CopyImage_611297,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectoryConfig_611310 = ref object of OpenApiRestCall_610658
proc url_CreateDirectoryConfig_611312(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDirectoryConfig_611311(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a Directory Config object in AppStream 2.0. This object includes the configuration information required to join fleets and image builders to Microsoft Active Directory domains.
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
      "PhotonAdminProxyService.CreateDirectoryConfig"))
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

proc call*(call_611322: Call_CreateDirectoryConfig_611310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Directory Config object in AppStream 2.0. This object includes the configuration information required to join fleets and image builders to Microsoft Active Directory domains.
  ## 
  let valid = call_611322.validator(path, query, header, formData, body)
  let scheme = call_611322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611322.url(scheme.get, call_611322.host, call_611322.base,
                         call_611322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611322, url, valid)

proc call*(call_611323: Call_CreateDirectoryConfig_611310; body: JsonNode): Recallable =
  ## createDirectoryConfig
  ## Creates a Directory Config object in AppStream 2.0. This object includes the configuration information required to join fleets and image builders to Microsoft Active Directory domains.
  ##   body: JObject (required)
  var body_611324 = newJObject()
  if body != nil:
    body_611324 = body
  result = call_611323.call(nil, nil, nil, nil, body_611324)

var createDirectoryConfig* = Call_CreateDirectoryConfig_611310(
    name: "createDirectoryConfig", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.CreateDirectoryConfig",
    validator: validate_CreateDirectoryConfig_611311, base: "/",
    url: url_CreateDirectoryConfig_611312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFleet_611325 = ref object of OpenApiRestCall_610658
proc url_CreateFleet_611327(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFleet_611326(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a fleet. A fleet consists of streaming instances that run a specified image.
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
      "PhotonAdminProxyService.CreateFleet"))
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

proc call*(call_611337: Call_CreateFleet_611325; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a fleet. A fleet consists of streaming instances that run a specified image.
  ## 
  let valid = call_611337.validator(path, query, header, formData, body)
  let scheme = call_611337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611337.url(scheme.get, call_611337.host, call_611337.base,
                         call_611337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611337, url, valid)

proc call*(call_611338: Call_CreateFleet_611325; body: JsonNode): Recallable =
  ## createFleet
  ## Creates a fleet. A fleet consists of streaming instances that run a specified image.
  ##   body: JObject (required)
  var body_611339 = newJObject()
  if body != nil:
    body_611339 = body
  result = call_611338.call(nil, nil, nil, nil, body_611339)

var createFleet* = Call_CreateFleet_611325(name: "createFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.CreateFleet",
                                        validator: validate_CreateFleet_611326,
                                        base: "/", url: url_CreateFleet_611327,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImageBuilder_611340 = ref object of OpenApiRestCall_610658
proc url_CreateImageBuilder_611342(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateImageBuilder_611341(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Creates an image builder. An image builder is a virtual machine that is used to create an image.</p> <p>The initial state of the builder is <code>PENDING</code>. When it is ready, the state is <code>RUNNING</code>.</p>
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
      "PhotonAdminProxyService.CreateImageBuilder"))
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

proc call*(call_611352: Call_CreateImageBuilder_611340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an image builder. An image builder is a virtual machine that is used to create an image.</p> <p>The initial state of the builder is <code>PENDING</code>. When it is ready, the state is <code>RUNNING</code>.</p>
  ## 
  let valid = call_611352.validator(path, query, header, formData, body)
  let scheme = call_611352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611352.url(scheme.get, call_611352.host, call_611352.base,
                         call_611352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611352, url, valid)

proc call*(call_611353: Call_CreateImageBuilder_611340; body: JsonNode): Recallable =
  ## createImageBuilder
  ## <p>Creates an image builder. An image builder is a virtual machine that is used to create an image.</p> <p>The initial state of the builder is <code>PENDING</code>. When it is ready, the state is <code>RUNNING</code>.</p>
  ##   body: JObject (required)
  var body_611354 = newJObject()
  if body != nil:
    body_611354 = body
  result = call_611353.call(nil, nil, nil, nil, body_611354)

var createImageBuilder* = Call_CreateImageBuilder_611340(
    name: "createImageBuilder", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.CreateImageBuilder",
    validator: validate_CreateImageBuilder_611341, base: "/",
    url: url_CreateImageBuilder_611342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImageBuilderStreamingURL_611355 = ref object of OpenApiRestCall_610658
proc url_CreateImageBuilderStreamingURL_611357(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateImageBuilderStreamingURL_611356(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a URL to start an image builder streaming session.
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
  valid_611358 = validateParameter(valid_611358, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CreateImageBuilderStreamingURL"))
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

proc call*(call_611367: Call_CreateImageBuilderStreamingURL_611355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a URL to start an image builder streaming session.
  ## 
  let valid = call_611367.validator(path, query, header, formData, body)
  let scheme = call_611367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611367.url(scheme.get, call_611367.host, call_611367.base,
                         call_611367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611367, url, valid)

proc call*(call_611368: Call_CreateImageBuilderStreamingURL_611355; body: JsonNode): Recallable =
  ## createImageBuilderStreamingURL
  ## Creates a URL to start an image builder streaming session.
  ##   body: JObject (required)
  var body_611369 = newJObject()
  if body != nil:
    body_611369 = body
  result = call_611368.call(nil, nil, nil, nil, body_611369)

var createImageBuilderStreamingURL* = Call_CreateImageBuilderStreamingURL_611355(
    name: "createImageBuilderStreamingURL", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.CreateImageBuilderStreamingURL",
    validator: validate_CreateImageBuilderStreamingURL_611356, base: "/",
    url: url_CreateImageBuilderStreamingURL_611357,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStack_611370 = ref object of OpenApiRestCall_610658
proc url_CreateStack_611372(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateStack_611371(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a stack to start streaming applications to users. A stack consists of an associated fleet, user access policies, and storage configurations. 
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
      "PhotonAdminProxyService.CreateStack"))
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

proc call*(call_611382: Call_CreateStack_611370; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a stack to start streaming applications to users. A stack consists of an associated fleet, user access policies, and storage configurations. 
  ## 
  let valid = call_611382.validator(path, query, header, formData, body)
  let scheme = call_611382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611382.url(scheme.get, call_611382.host, call_611382.base,
                         call_611382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611382, url, valid)

proc call*(call_611383: Call_CreateStack_611370; body: JsonNode): Recallable =
  ## createStack
  ## Creates a stack to start streaming applications to users. A stack consists of an associated fleet, user access policies, and storage configurations. 
  ##   body: JObject (required)
  var body_611384 = newJObject()
  if body != nil:
    body_611384 = body
  result = call_611383.call(nil, nil, nil, nil, body_611384)

var createStack* = Call_CreateStack_611370(name: "createStack",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.CreateStack",
                                        validator: validate_CreateStack_611371,
                                        base: "/", url: url_CreateStack_611372,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingURL_611385 = ref object of OpenApiRestCall_610658
proc url_CreateStreamingURL_611387(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateStreamingURL_611386(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Creates a temporary URL to start an AppStream 2.0 streaming session for the specified user. A streaming URL enables application streaming to be tested without user setup. 
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
      "PhotonAdminProxyService.CreateStreamingURL"))
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

proc call*(call_611397: Call_CreateStreamingURL_611385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a temporary URL to start an AppStream 2.0 streaming session for the specified user. A streaming URL enables application streaming to be tested without user setup. 
  ## 
  let valid = call_611397.validator(path, query, header, formData, body)
  let scheme = call_611397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611397.url(scheme.get, call_611397.host, call_611397.base,
                         call_611397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611397, url, valid)

proc call*(call_611398: Call_CreateStreamingURL_611385; body: JsonNode): Recallable =
  ## createStreamingURL
  ## Creates a temporary URL to start an AppStream 2.0 streaming session for the specified user. A streaming URL enables application streaming to be tested without user setup. 
  ##   body: JObject (required)
  var body_611399 = newJObject()
  if body != nil:
    body_611399 = body
  result = call_611398.call(nil, nil, nil, nil, body_611399)

var createStreamingURL* = Call_CreateStreamingURL_611385(
    name: "createStreamingURL", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.CreateStreamingURL",
    validator: validate_CreateStreamingURL_611386, base: "/",
    url: url_CreateStreamingURL_611387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsageReportSubscription_611400 = ref object of OpenApiRestCall_610658
proc url_CreateUsageReportSubscription_611402(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUsageReportSubscription_611401(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a usage report subscription. Usage reports are generated daily.
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
      "PhotonAdminProxyService.CreateUsageReportSubscription"))
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

proc call*(call_611412: Call_CreateUsageReportSubscription_611400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a usage report subscription. Usage reports are generated daily.
  ## 
  let valid = call_611412.validator(path, query, header, formData, body)
  let scheme = call_611412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611412.url(scheme.get, call_611412.host, call_611412.base,
                         call_611412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611412, url, valid)

proc call*(call_611413: Call_CreateUsageReportSubscription_611400; body: JsonNode): Recallable =
  ## createUsageReportSubscription
  ## Creates a usage report subscription. Usage reports are generated daily.
  ##   body: JObject (required)
  var body_611414 = newJObject()
  if body != nil:
    body_611414 = body
  result = call_611413.call(nil, nil, nil, nil, body_611414)

var createUsageReportSubscription* = Call_CreateUsageReportSubscription_611400(
    name: "createUsageReportSubscription", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.CreateUsageReportSubscription",
    validator: validate_CreateUsageReportSubscription_611401, base: "/",
    url: url_CreateUsageReportSubscription_611402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_611415 = ref object of OpenApiRestCall_610658
proc url_CreateUser_611417(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUser_611416(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new user in the user pool.
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
      "PhotonAdminProxyService.CreateUser"))
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

proc call*(call_611427: Call_CreateUser_611415; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new user in the user pool.
  ## 
  let valid = call_611427.validator(path, query, header, formData, body)
  let scheme = call_611427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611427.url(scheme.get, call_611427.host, call_611427.base,
                         call_611427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611427, url, valid)

proc call*(call_611428: Call_CreateUser_611415; body: JsonNode): Recallable =
  ## createUser
  ## Creates a new user in the user pool.
  ##   body: JObject (required)
  var body_611429 = newJObject()
  if body != nil:
    body_611429 = body
  result = call_611428.call(nil, nil, nil, nil, body_611429)

var createUser* = Call_CreateUser_611415(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.CreateUser",
                                      validator: validate_CreateUser_611416,
                                      base: "/", url: url_CreateUser_611417,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectoryConfig_611430 = ref object of OpenApiRestCall_610658
proc url_DeleteDirectoryConfig_611432(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDirectoryConfig_611431(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified Directory Config object from AppStream 2.0. This object includes the information required to join streaming instances to an Active Directory domain.
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
      "PhotonAdminProxyService.DeleteDirectoryConfig"))
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

proc call*(call_611442: Call_DeleteDirectoryConfig_611430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Directory Config object from AppStream 2.0. This object includes the information required to join streaming instances to an Active Directory domain.
  ## 
  let valid = call_611442.validator(path, query, header, formData, body)
  let scheme = call_611442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611442.url(scheme.get, call_611442.host, call_611442.base,
                         call_611442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611442, url, valid)

proc call*(call_611443: Call_DeleteDirectoryConfig_611430; body: JsonNode): Recallable =
  ## deleteDirectoryConfig
  ## Deletes the specified Directory Config object from AppStream 2.0. This object includes the information required to join streaming instances to an Active Directory domain.
  ##   body: JObject (required)
  var body_611444 = newJObject()
  if body != nil:
    body_611444 = body
  result = call_611443.call(nil, nil, nil, nil, body_611444)

var deleteDirectoryConfig* = Call_DeleteDirectoryConfig_611430(
    name: "deleteDirectoryConfig", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteDirectoryConfig",
    validator: validate_DeleteDirectoryConfig_611431, base: "/",
    url: url_DeleteDirectoryConfig_611432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFleet_611445 = ref object of OpenApiRestCall_610658
proc url_DeleteFleet_611447(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteFleet_611446(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified fleet.
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
      "PhotonAdminProxyService.DeleteFleet"))
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

proc call*(call_611457: Call_DeleteFleet_611445; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified fleet.
  ## 
  let valid = call_611457.validator(path, query, header, formData, body)
  let scheme = call_611457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611457.url(scheme.get, call_611457.host, call_611457.base,
                         call_611457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611457, url, valid)

proc call*(call_611458: Call_DeleteFleet_611445; body: JsonNode): Recallable =
  ## deleteFleet
  ## Deletes the specified fleet.
  ##   body: JObject (required)
  var body_611459 = newJObject()
  if body != nil:
    body_611459 = body
  result = call_611458.call(nil, nil, nil, nil, body_611459)

var deleteFleet* = Call_DeleteFleet_611445(name: "deleteFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteFleet",
                                        validator: validate_DeleteFleet_611446,
                                        base: "/", url: url_DeleteFleet_611447,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImage_611460 = ref object of OpenApiRestCall_610658
proc url_DeleteImage_611462(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteImage_611461(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified image. You cannot delete an image when it is in use. After you delete an image, you cannot provision new capacity using the image.
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
      "PhotonAdminProxyService.DeleteImage"))
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

proc call*(call_611472: Call_DeleteImage_611460; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified image. You cannot delete an image when it is in use. After you delete an image, you cannot provision new capacity using the image.
  ## 
  let valid = call_611472.validator(path, query, header, formData, body)
  let scheme = call_611472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611472.url(scheme.get, call_611472.host, call_611472.base,
                         call_611472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611472, url, valid)

proc call*(call_611473: Call_DeleteImage_611460; body: JsonNode): Recallable =
  ## deleteImage
  ## Deletes the specified image. You cannot delete an image when it is in use. After you delete an image, you cannot provision new capacity using the image.
  ##   body: JObject (required)
  var body_611474 = newJObject()
  if body != nil:
    body_611474 = body
  result = call_611473.call(nil, nil, nil, nil, body_611474)

var deleteImage* = Call_DeleteImage_611460(name: "deleteImage",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteImage",
                                        validator: validate_DeleteImage_611461,
                                        base: "/", url: url_DeleteImage_611462,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImageBuilder_611475 = ref object of OpenApiRestCall_610658
proc url_DeleteImageBuilder_611477(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteImageBuilder_611476(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes the specified image builder and releases the capacity.
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
  valid_611478 = validateParameter(valid_611478, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteImageBuilder"))
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

proc call*(call_611487: Call_DeleteImageBuilder_611475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified image builder and releases the capacity.
  ## 
  let valid = call_611487.validator(path, query, header, formData, body)
  let scheme = call_611487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611487.url(scheme.get, call_611487.host, call_611487.base,
                         call_611487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611487, url, valid)

proc call*(call_611488: Call_DeleteImageBuilder_611475; body: JsonNode): Recallable =
  ## deleteImageBuilder
  ## Deletes the specified image builder and releases the capacity.
  ##   body: JObject (required)
  var body_611489 = newJObject()
  if body != nil:
    body_611489 = body
  result = call_611488.call(nil, nil, nil, nil, body_611489)

var deleteImageBuilder* = Call_DeleteImageBuilder_611475(
    name: "deleteImageBuilder", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteImageBuilder",
    validator: validate_DeleteImageBuilder_611476, base: "/",
    url: url_DeleteImageBuilder_611477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImagePermissions_611490 = ref object of OpenApiRestCall_610658
proc url_DeleteImagePermissions_611492(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteImagePermissions_611491(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes permissions for the specified private image. After you delete permissions for an image, AWS accounts to which you previously granted these permissions can no longer use the image.
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
  valid_611493 = validateParameter(valid_611493, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteImagePermissions"))
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

proc call*(call_611502: Call_DeleteImagePermissions_611490; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes permissions for the specified private image. After you delete permissions for an image, AWS accounts to which you previously granted these permissions can no longer use the image.
  ## 
  let valid = call_611502.validator(path, query, header, formData, body)
  let scheme = call_611502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611502.url(scheme.get, call_611502.host, call_611502.base,
                         call_611502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611502, url, valid)

proc call*(call_611503: Call_DeleteImagePermissions_611490; body: JsonNode): Recallable =
  ## deleteImagePermissions
  ## Deletes permissions for the specified private image. After you delete permissions for an image, AWS accounts to which you previously granted these permissions can no longer use the image.
  ##   body: JObject (required)
  var body_611504 = newJObject()
  if body != nil:
    body_611504 = body
  result = call_611503.call(nil, nil, nil, nil, body_611504)

var deleteImagePermissions* = Call_DeleteImagePermissions_611490(
    name: "deleteImagePermissions", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteImagePermissions",
    validator: validate_DeleteImagePermissions_611491, base: "/",
    url: url_DeleteImagePermissions_611492, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStack_611505 = ref object of OpenApiRestCall_610658
proc url_DeleteStack_611507(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteStack_611506(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified stack. After the stack is deleted, the application streaming environment provided by the stack is no longer available to users. Also, any reservations made for application streaming sessions for the stack are released.
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
      "PhotonAdminProxyService.DeleteStack"))
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

proc call*(call_611517: Call_DeleteStack_611505; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified stack. After the stack is deleted, the application streaming environment provided by the stack is no longer available to users. Also, any reservations made for application streaming sessions for the stack are released.
  ## 
  let valid = call_611517.validator(path, query, header, formData, body)
  let scheme = call_611517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611517.url(scheme.get, call_611517.host, call_611517.base,
                         call_611517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611517, url, valid)

proc call*(call_611518: Call_DeleteStack_611505; body: JsonNode): Recallable =
  ## deleteStack
  ## Deletes the specified stack. After the stack is deleted, the application streaming environment provided by the stack is no longer available to users. Also, any reservations made for application streaming sessions for the stack are released.
  ##   body: JObject (required)
  var body_611519 = newJObject()
  if body != nil:
    body_611519 = body
  result = call_611518.call(nil, nil, nil, nil, body_611519)

var deleteStack* = Call_DeleteStack_611505(name: "deleteStack",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteStack",
                                        validator: validate_DeleteStack_611506,
                                        base: "/", url: url_DeleteStack_611507,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsageReportSubscription_611520 = ref object of OpenApiRestCall_610658
proc url_DeleteUsageReportSubscription_611522(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUsageReportSubscription_611521(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disables usage report generation.
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
  valid_611523 = validateParameter(valid_611523, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteUsageReportSubscription"))
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

proc call*(call_611532: Call_DeleteUsageReportSubscription_611520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables usage report generation.
  ## 
  let valid = call_611532.validator(path, query, header, formData, body)
  let scheme = call_611532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611532.url(scheme.get, call_611532.host, call_611532.base,
                         call_611532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611532, url, valid)

proc call*(call_611533: Call_DeleteUsageReportSubscription_611520; body: JsonNode): Recallable =
  ## deleteUsageReportSubscription
  ## Disables usage report generation.
  ##   body: JObject (required)
  var body_611534 = newJObject()
  if body != nil:
    body_611534 = body
  result = call_611533.call(nil, nil, nil, nil, body_611534)

var deleteUsageReportSubscription* = Call_DeleteUsageReportSubscription_611520(
    name: "deleteUsageReportSubscription", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteUsageReportSubscription",
    validator: validate_DeleteUsageReportSubscription_611521, base: "/",
    url: url_DeleteUsageReportSubscription_611522,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_611535 = ref object of OpenApiRestCall_610658
proc url_DeleteUser_611537(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUser_611536(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a user from the user pool.
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
      "PhotonAdminProxyService.DeleteUser"))
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

proc call*(call_611547: Call_DeleteUser_611535; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a user from the user pool.
  ## 
  let valid = call_611547.validator(path, query, header, formData, body)
  let scheme = call_611547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611547.url(scheme.get, call_611547.host, call_611547.base,
                         call_611547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611547, url, valid)

proc call*(call_611548: Call_DeleteUser_611535; body: JsonNode): Recallable =
  ## deleteUser
  ## Deletes a user from the user pool.
  ##   body: JObject (required)
  var body_611549 = newJObject()
  if body != nil:
    body_611549 = body
  result = call_611548.call(nil, nil, nil, nil, body_611549)

var deleteUser* = Call_DeleteUser_611535(name: "deleteUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteUser",
                                      validator: validate_DeleteUser_611536,
                                      base: "/", url: url_DeleteUser_611537,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDirectoryConfigs_611550 = ref object of OpenApiRestCall_610658
proc url_DescribeDirectoryConfigs_611552(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDirectoryConfigs_611551(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves a list that describes one or more specified Directory Config objects for AppStream 2.0, if the names for these objects are provided. Otherwise, all Directory Config objects in the account are described. These objects include the configuration information required to join fleets and image builders to Microsoft Active Directory domains. </p> <p>Although the response syntax in this topic includes the account password, this password is not returned in the actual response.</p>
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
      "PhotonAdminProxyService.DescribeDirectoryConfigs"))
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

proc call*(call_611562: Call_DescribeDirectoryConfigs_611550; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list that describes one or more specified Directory Config objects for AppStream 2.0, if the names for these objects are provided. Otherwise, all Directory Config objects in the account are described. These objects include the configuration information required to join fleets and image builders to Microsoft Active Directory domains. </p> <p>Although the response syntax in this topic includes the account password, this password is not returned in the actual response.</p>
  ## 
  let valid = call_611562.validator(path, query, header, formData, body)
  let scheme = call_611562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611562.url(scheme.get, call_611562.host, call_611562.base,
                         call_611562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611562, url, valid)

proc call*(call_611563: Call_DescribeDirectoryConfigs_611550; body: JsonNode): Recallable =
  ## describeDirectoryConfigs
  ## <p>Retrieves a list that describes one or more specified Directory Config objects for AppStream 2.0, if the names for these objects are provided. Otherwise, all Directory Config objects in the account are described. These objects include the configuration information required to join fleets and image builders to Microsoft Active Directory domains. </p> <p>Although the response syntax in this topic includes the account password, this password is not returned in the actual response.</p>
  ##   body: JObject (required)
  var body_611564 = newJObject()
  if body != nil:
    body_611564 = body
  result = call_611563.call(nil, nil, nil, nil, body_611564)

var describeDirectoryConfigs* = Call_DescribeDirectoryConfigs_611550(
    name: "describeDirectoryConfigs", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeDirectoryConfigs",
    validator: validate_DescribeDirectoryConfigs_611551, base: "/",
    url: url_DescribeDirectoryConfigs_611552, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFleets_611565 = ref object of OpenApiRestCall_610658
proc url_DescribeFleets_611567(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeFleets_611566(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves a list that describes one or more specified fleets, if the fleet names are provided. Otherwise, all fleets in the account are described.
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
  valid_611568 = validateParameter(valid_611568, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeFleets"))
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

proc call*(call_611577: Call_DescribeFleets_611565; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified fleets, if the fleet names are provided. Otherwise, all fleets in the account are described.
  ## 
  let valid = call_611577.validator(path, query, header, formData, body)
  let scheme = call_611577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611577.url(scheme.get, call_611577.host, call_611577.base,
                         call_611577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611577, url, valid)

proc call*(call_611578: Call_DescribeFleets_611565; body: JsonNode): Recallable =
  ## describeFleets
  ## Retrieves a list that describes one or more specified fleets, if the fleet names are provided. Otherwise, all fleets in the account are described.
  ##   body: JObject (required)
  var body_611579 = newJObject()
  if body != nil:
    body_611579 = body
  result = call_611578.call(nil, nil, nil, nil, body_611579)

var describeFleets* = Call_DescribeFleets_611565(name: "describeFleets",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeFleets",
    validator: validate_DescribeFleets_611566, base: "/", url: url_DescribeFleets_611567,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeImageBuilders_611580 = ref object of OpenApiRestCall_610658
proc url_DescribeImageBuilders_611582(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeImageBuilders_611581(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list that describes one or more specified image builders, if the image builder names are provided. Otherwise, all image builders in the account are described.
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
      "PhotonAdminProxyService.DescribeImageBuilders"))
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

proc call*(call_611592: Call_DescribeImageBuilders_611580; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified image builders, if the image builder names are provided. Otherwise, all image builders in the account are described.
  ## 
  let valid = call_611592.validator(path, query, header, formData, body)
  let scheme = call_611592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611592.url(scheme.get, call_611592.host, call_611592.base,
                         call_611592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611592, url, valid)

proc call*(call_611593: Call_DescribeImageBuilders_611580; body: JsonNode): Recallable =
  ## describeImageBuilders
  ## Retrieves a list that describes one or more specified image builders, if the image builder names are provided. Otherwise, all image builders in the account are described.
  ##   body: JObject (required)
  var body_611594 = newJObject()
  if body != nil:
    body_611594 = body
  result = call_611593.call(nil, nil, nil, nil, body_611594)

var describeImageBuilders* = Call_DescribeImageBuilders_611580(
    name: "describeImageBuilders", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeImageBuilders",
    validator: validate_DescribeImageBuilders_611581, base: "/",
    url: url_DescribeImageBuilders_611582, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeImagePermissions_611595 = ref object of OpenApiRestCall_610658
proc url_DescribeImagePermissions_611597(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeImagePermissions_611596(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list that describes the permissions for shared AWS account IDs on a private image that you own. 
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
  var valid_611598 = query.getOrDefault("MaxResults")
  valid_611598 = validateParameter(valid_611598, JString, required = false,
                                 default = nil)
  if valid_611598 != nil:
    section.add "MaxResults", valid_611598
  var valid_611599 = query.getOrDefault("NextToken")
  valid_611599 = validateParameter(valid_611599, JString, required = false,
                                 default = nil)
  if valid_611599 != nil:
    section.add "NextToken", valid_611599
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611600 = header.getOrDefault("X-Amz-Target")
  valid_611600 = validateParameter(valid_611600, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeImagePermissions"))
  if valid_611600 != nil:
    section.add "X-Amz-Target", valid_611600
  var valid_611601 = header.getOrDefault("X-Amz-Signature")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "X-Amz-Signature", valid_611601
  var valid_611602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "X-Amz-Content-Sha256", valid_611602
  var valid_611603 = header.getOrDefault("X-Amz-Date")
  valid_611603 = validateParameter(valid_611603, JString, required = false,
                                 default = nil)
  if valid_611603 != nil:
    section.add "X-Amz-Date", valid_611603
  var valid_611604 = header.getOrDefault("X-Amz-Credential")
  valid_611604 = validateParameter(valid_611604, JString, required = false,
                                 default = nil)
  if valid_611604 != nil:
    section.add "X-Amz-Credential", valid_611604
  var valid_611605 = header.getOrDefault("X-Amz-Security-Token")
  valid_611605 = validateParameter(valid_611605, JString, required = false,
                                 default = nil)
  if valid_611605 != nil:
    section.add "X-Amz-Security-Token", valid_611605
  var valid_611606 = header.getOrDefault("X-Amz-Algorithm")
  valid_611606 = validateParameter(valid_611606, JString, required = false,
                                 default = nil)
  if valid_611606 != nil:
    section.add "X-Amz-Algorithm", valid_611606
  var valid_611607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611607 = validateParameter(valid_611607, JString, required = false,
                                 default = nil)
  if valid_611607 != nil:
    section.add "X-Amz-SignedHeaders", valid_611607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611609: Call_DescribeImagePermissions_611595; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes the permissions for shared AWS account IDs on a private image that you own. 
  ## 
  let valid = call_611609.validator(path, query, header, formData, body)
  let scheme = call_611609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611609.url(scheme.get, call_611609.host, call_611609.base,
                         call_611609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611609, url, valid)

proc call*(call_611610: Call_DescribeImagePermissions_611595; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeImagePermissions
  ## Retrieves a list that describes the permissions for shared AWS account IDs on a private image that you own. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611611 = newJObject()
  var body_611612 = newJObject()
  add(query_611611, "MaxResults", newJString(MaxResults))
  add(query_611611, "NextToken", newJString(NextToken))
  if body != nil:
    body_611612 = body
  result = call_611610.call(nil, query_611611, nil, nil, body_611612)

var describeImagePermissions* = Call_DescribeImagePermissions_611595(
    name: "describeImagePermissions", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeImagePermissions",
    validator: validate_DescribeImagePermissions_611596, base: "/",
    url: url_DescribeImagePermissions_611597, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeImages_611614 = ref object of OpenApiRestCall_610658
proc url_DescribeImages_611616(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeImages_611615(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves a list that describes one or more specified images, if the image names or image ARNs are provided. Otherwise, all images in the account are described.
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
  var valid_611617 = query.getOrDefault("MaxResults")
  valid_611617 = validateParameter(valid_611617, JString, required = false,
                                 default = nil)
  if valid_611617 != nil:
    section.add "MaxResults", valid_611617
  var valid_611618 = query.getOrDefault("NextToken")
  valid_611618 = validateParameter(valid_611618, JString, required = false,
                                 default = nil)
  if valid_611618 != nil:
    section.add "NextToken", valid_611618
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611619 = header.getOrDefault("X-Amz-Target")
  valid_611619 = validateParameter(valid_611619, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeImages"))
  if valid_611619 != nil:
    section.add "X-Amz-Target", valid_611619
  var valid_611620 = header.getOrDefault("X-Amz-Signature")
  valid_611620 = validateParameter(valid_611620, JString, required = false,
                                 default = nil)
  if valid_611620 != nil:
    section.add "X-Amz-Signature", valid_611620
  var valid_611621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611621 = validateParameter(valid_611621, JString, required = false,
                                 default = nil)
  if valid_611621 != nil:
    section.add "X-Amz-Content-Sha256", valid_611621
  var valid_611622 = header.getOrDefault("X-Amz-Date")
  valid_611622 = validateParameter(valid_611622, JString, required = false,
                                 default = nil)
  if valid_611622 != nil:
    section.add "X-Amz-Date", valid_611622
  var valid_611623 = header.getOrDefault("X-Amz-Credential")
  valid_611623 = validateParameter(valid_611623, JString, required = false,
                                 default = nil)
  if valid_611623 != nil:
    section.add "X-Amz-Credential", valid_611623
  var valid_611624 = header.getOrDefault("X-Amz-Security-Token")
  valid_611624 = validateParameter(valid_611624, JString, required = false,
                                 default = nil)
  if valid_611624 != nil:
    section.add "X-Amz-Security-Token", valid_611624
  var valid_611625 = header.getOrDefault("X-Amz-Algorithm")
  valid_611625 = validateParameter(valid_611625, JString, required = false,
                                 default = nil)
  if valid_611625 != nil:
    section.add "X-Amz-Algorithm", valid_611625
  var valid_611626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611626 = validateParameter(valid_611626, JString, required = false,
                                 default = nil)
  if valid_611626 != nil:
    section.add "X-Amz-SignedHeaders", valid_611626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611628: Call_DescribeImages_611614; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified images, if the image names or image ARNs are provided. Otherwise, all images in the account are described.
  ## 
  let valid = call_611628.validator(path, query, header, formData, body)
  let scheme = call_611628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611628.url(scheme.get, call_611628.host, call_611628.base,
                         call_611628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611628, url, valid)

proc call*(call_611629: Call_DescribeImages_611614; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeImages
  ## Retrieves a list that describes one or more specified images, if the image names or image ARNs are provided. Otherwise, all images in the account are described.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611630 = newJObject()
  var body_611631 = newJObject()
  add(query_611630, "MaxResults", newJString(MaxResults))
  add(query_611630, "NextToken", newJString(NextToken))
  if body != nil:
    body_611631 = body
  result = call_611629.call(nil, query_611630, nil, nil, body_611631)

var describeImages* = Call_DescribeImages_611614(name: "describeImages",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeImages",
    validator: validate_DescribeImages_611615, base: "/", url: url_DescribeImages_611616,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSessions_611632 = ref object of OpenApiRestCall_610658
proc url_DescribeSessions_611634(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSessions_611633(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieves a list that describes the streaming sessions for a specified stack and fleet. If a UserId is provided for the stack and fleet, only streaming sessions for that user are described. If an authentication type is not provided, the default is to authenticate users using a streaming URL.
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
  var valid_611635 = header.getOrDefault("X-Amz-Target")
  valid_611635 = validateParameter(valid_611635, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeSessions"))
  if valid_611635 != nil:
    section.add "X-Amz-Target", valid_611635
  var valid_611636 = header.getOrDefault("X-Amz-Signature")
  valid_611636 = validateParameter(valid_611636, JString, required = false,
                                 default = nil)
  if valid_611636 != nil:
    section.add "X-Amz-Signature", valid_611636
  var valid_611637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611637 = validateParameter(valid_611637, JString, required = false,
                                 default = nil)
  if valid_611637 != nil:
    section.add "X-Amz-Content-Sha256", valid_611637
  var valid_611638 = header.getOrDefault("X-Amz-Date")
  valid_611638 = validateParameter(valid_611638, JString, required = false,
                                 default = nil)
  if valid_611638 != nil:
    section.add "X-Amz-Date", valid_611638
  var valid_611639 = header.getOrDefault("X-Amz-Credential")
  valid_611639 = validateParameter(valid_611639, JString, required = false,
                                 default = nil)
  if valid_611639 != nil:
    section.add "X-Amz-Credential", valid_611639
  var valid_611640 = header.getOrDefault("X-Amz-Security-Token")
  valid_611640 = validateParameter(valid_611640, JString, required = false,
                                 default = nil)
  if valid_611640 != nil:
    section.add "X-Amz-Security-Token", valid_611640
  var valid_611641 = header.getOrDefault("X-Amz-Algorithm")
  valid_611641 = validateParameter(valid_611641, JString, required = false,
                                 default = nil)
  if valid_611641 != nil:
    section.add "X-Amz-Algorithm", valid_611641
  var valid_611642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611642 = validateParameter(valid_611642, JString, required = false,
                                 default = nil)
  if valid_611642 != nil:
    section.add "X-Amz-SignedHeaders", valid_611642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611644: Call_DescribeSessions_611632; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes the streaming sessions for a specified stack and fleet. If a UserId is provided for the stack and fleet, only streaming sessions for that user are described. If an authentication type is not provided, the default is to authenticate users using a streaming URL.
  ## 
  let valid = call_611644.validator(path, query, header, formData, body)
  let scheme = call_611644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611644.url(scheme.get, call_611644.host, call_611644.base,
                         call_611644.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611644, url, valid)

proc call*(call_611645: Call_DescribeSessions_611632; body: JsonNode): Recallable =
  ## describeSessions
  ## Retrieves a list that describes the streaming sessions for a specified stack and fleet. If a UserId is provided for the stack and fleet, only streaming sessions for that user are described. If an authentication type is not provided, the default is to authenticate users using a streaming URL.
  ##   body: JObject (required)
  var body_611646 = newJObject()
  if body != nil:
    body_611646 = body
  result = call_611645.call(nil, nil, nil, nil, body_611646)

var describeSessions* = Call_DescribeSessions_611632(name: "describeSessions",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeSessions",
    validator: validate_DescribeSessions_611633, base: "/",
    url: url_DescribeSessions_611634, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStacks_611647 = ref object of OpenApiRestCall_610658
proc url_DescribeStacks_611649(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeStacks_611648(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves a list that describes one or more specified stacks, if the stack names are provided. Otherwise, all stacks in the account are described.
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
  var valid_611650 = header.getOrDefault("X-Amz-Target")
  valid_611650 = validateParameter(valid_611650, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeStacks"))
  if valid_611650 != nil:
    section.add "X-Amz-Target", valid_611650
  var valid_611651 = header.getOrDefault("X-Amz-Signature")
  valid_611651 = validateParameter(valid_611651, JString, required = false,
                                 default = nil)
  if valid_611651 != nil:
    section.add "X-Amz-Signature", valid_611651
  var valid_611652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611652 = validateParameter(valid_611652, JString, required = false,
                                 default = nil)
  if valid_611652 != nil:
    section.add "X-Amz-Content-Sha256", valid_611652
  var valid_611653 = header.getOrDefault("X-Amz-Date")
  valid_611653 = validateParameter(valid_611653, JString, required = false,
                                 default = nil)
  if valid_611653 != nil:
    section.add "X-Amz-Date", valid_611653
  var valid_611654 = header.getOrDefault("X-Amz-Credential")
  valid_611654 = validateParameter(valid_611654, JString, required = false,
                                 default = nil)
  if valid_611654 != nil:
    section.add "X-Amz-Credential", valid_611654
  var valid_611655 = header.getOrDefault("X-Amz-Security-Token")
  valid_611655 = validateParameter(valid_611655, JString, required = false,
                                 default = nil)
  if valid_611655 != nil:
    section.add "X-Amz-Security-Token", valid_611655
  var valid_611656 = header.getOrDefault("X-Amz-Algorithm")
  valid_611656 = validateParameter(valid_611656, JString, required = false,
                                 default = nil)
  if valid_611656 != nil:
    section.add "X-Amz-Algorithm", valid_611656
  var valid_611657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611657 = validateParameter(valid_611657, JString, required = false,
                                 default = nil)
  if valid_611657 != nil:
    section.add "X-Amz-SignedHeaders", valid_611657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611659: Call_DescribeStacks_611647; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified stacks, if the stack names are provided. Otherwise, all stacks in the account are described.
  ## 
  let valid = call_611659.validator(path, query, header, formData, body)
  let scheme = call_611659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611659.url(scheme.get, call_611659.host, call_611659.base,
                         call_611659.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611659, url, valid)

proc call*(call_611660: Call_DescribeStacks_611647; body: JsonNode): Recallable =
  ## describeStacks
  ## Retrieves a list that describes one or more specified stacks, if the stack names are provided. Otherwise, all stacks in the account are described.
  ##   body: JObject (required)
  var body_611661 = newJObject()
  if body != nil:
    body_611661 = body
  result = call_611660.call(nil, nil, nil, nil, body_611661)

var describeStacks* = Call_DescribeStacks_611647(name: "describeStacks",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeStacks",
    validator: validate_DescribeStacks_611648, base: "/", url: url_DescribeStacks_611649,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUsageReportSubscriptions_611662 = ref object of OpenApiRestCall_610658
proc url_DescribeUsageReportSubscriptions_611664(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUsageReportSubscriptions_611663(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list that describes one or more usage report subscriptions.
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
  var valid_611665 = header.getOrDefault("X-Amz-Target")
  valid_611665 = validateParameter(valid_611665, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeUsageReportSubscriptions"))
  if valid_611665 != nil:
    section.add "X-Amz-Target", valid_611665
  var valid_611666 = header.getOrDefault("X-Amz-Signature")
  valid_611666 = validateParameter(valid_611666, JString, required = false,
                                 default = nil)
  if valid_611666 != nil:
    section.add "X-Amz-Signature", valid_611666
  var valid_611667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611667 = validateParameter(valid_611667, JString, required = false,
                                 default = nil)
  if valid_611667 != nil:
    section.add "X-Amz-Content-Sha256", valid_611667
  var valid_611668 = header.getOrDefault("X-Amz-Date")
  valid_611668 = validateParameter(valid_611668, JString, required = false,
                                 default = nil)
  if valid_611668 != nil:
    section.add "X-Amz-Date", valid_611668
  var valid_611669 = header.getOrDefault("X-Amz-Credential")
  valid_611669 = validateParameter(valid_611669, JString, required = false,
                                 default = nil)
  if valid_611669 != nil:
    section.add "X-Amz-Credential", valid_611669
  var valid_611670 = header.getOrDefault("X-Amz-Security-Token")
  valid_611670 = validateParameter(valid_611670, JString, required = false,
                                 default = nil)
  if valid_611670 != nil:
    section.add "X-Amz-Security-Token", valid_611670
  var valid_611671 = header.getOrDefault("X-Amz-Algorithm")
  valid_611671 = validateParameter(valid_611671, JString, required = false,
                                 default = nil)
  if valid_611671 != nil:
    section.add "X-Amz-Algorithm", valid_611671
  var valid_611672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611672 = validateParameter(valid_611672, JString, required = false,
                                 default = nil)
  if valid_611672 != nil:
    section.add "X-Amz-SignedHeaders", valid_611672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611674: Call_DescribeUsageReportSubscriptions_611662;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more usage report subscriptions.
  ## 
  let valid = call_611674.validator(path, query, header, formData, body)
  let scheme = call_611674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611674.url(scheme.get, call_611674.host, call_611674.base,
                         call_611674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611674, url, valid)

proc call*(call_611675: Call_DescribeUsageReportSubscriptions_611662;
          body: JsonNode): Recallable =
  ## describeUsageReportSubscriptions
  ## Retrieves a list that describes one or more usage report subscriptions.
  ##   body: JObject (required)
  var body_611676 = newJObject()
  if body != nil:
    body_611676 = body
  result = call_611675.call(nil, nil, nil, nil, body_611676)

var describeUsageReportSubscriptions* = Call_DescribeUsageReportSubscriptions_611662(
    name: "describeUsageReportSubscriptions", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeUsageReportSubscriptions",
    validator: validate_DescribeUsageReportSubscriptions_611663, base: "/",
    url: url_DescribeUsageReportSubscriptions_611664,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserStackAssociations_611677 = ref object of OpenApiRestCall_610658
proc url_DescribeUserStackAssociations_611679(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUserStackAssociations_611678(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves a list that describes the UserStackAssociation objects. You must specify either or both of the following:</p> <ul> <li> <p>The stack name</p> </li> <li> <p>The user name (email address of the user associated with the stack) and the authentication type for the user</p> </li> </ul>
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
  var valid_611680 = header.getOrDefault("X-Amz-Target")
  valid_611680 = validateParameter(valid_611680, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeUserStackAssociations"))
  if valid_611680 != nil:
    section.add "X-Amz-Target", valid_611680
  var valid_611681 = header.getOrDefault("X-Amz-Signature")
  valid_611681 = validateParameter(valid_611681, JString, required = false,
                                 default = nil)
  if valid_611681 != nil:
    section.add "X-Amz-Signature", valid_611681
  var valid_611682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611682 = validateParameter(valid_611682, JString, required = false,
                                 default = nil)
  if valid_611682 != nil:
    section.add "X-Amz-Content-Sha256", valid_611682
  var valid_611683 = header.getOrDefault("X-Amz-Date")
  valid_611683 = validateParameter(valid_611683, JString, required = false,
                                 default = nil)
  if valid_611683 != nil:
    section.add "X-Amz-Date", valid_611683
  var valid_611684 = header.getOrDefault("X-Amz-Credential")
  valid_611684 = validateParameter(valid_611684, JString, required = false,
                                 default = nil)
  if valid_611684 != nil:
    section.add "X-Amz-Credential", valid_611684
  var valid_611685 = header.getOrDefault("X-Amz-Security-Token")
  valid_611685 = validateParameter(valid_611685, JString, required = false,
                                 default = nil)
  if valid_611685 != nil:
    section.add "X-Amz-Security-Token", valid_611685
  var valid_611686 = header.getOrDefault("X-Amz-Algorithm")
  valid_611686 = validateParameter(valid_611686, JString, required = false,
                                 default = nil)
  if valid_611686 != nil:
    section.add "X-Amz-Algorithm", valid_611686
  var valid_611687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611687 = validateParameter(valid_611687, JString, required = false,
                                 default = nil)
  if valid_611687 != nil:
    section.add "X-Amz-SignedHeaders", valid_611687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611689: Call_DescribeUserStackAssociations_611677; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list that describes the UserStackAssociation objects. You must specify either or both of the following:</p> <ul> <li> <p>The stack name</p> </li> <li> <p>The user name (email address of the user associated with the stack) and the authentication type for the user</p> </li> </ul>
  ## 
  let valid = call_611689.validator(path, query, header, formData, body)
  let scheme = call_611689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611689.url(scheme.get, call_611689.host, call_611689.base,
                         call_611689.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611689, url, valid)

proc call*(call_611690: Call_DescribeUserStackAssociations_611677; body: JsonNode): Recallable =
  ## describeUserStackAssociations
  ## <p>Retrieves a list that describes the UserStackAssociation objects. You must specify either or both of the following:</p> <ul> <li> <p>The stack name</p> </li> <li> <p>The user name (email address of the user associated with the stack) and the authentication type for the user</p> </li> </ul>
  ##   body: JObject (required)
  var body_611691 = newJObject()
  if body != nil:
    body_611691 = body
  result = call_611690.call(nil, nil, nil, nil, body_611691)

var describeUserStackAssociations* = Call_DescribeUserStackAssociations_611677(
    name: "describeUserStackAssociations", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeUserStackAssociations",
    validator: validate_DescribeUserStackAssociations_611678, base: "/",
    url: url_DescribeUserStackAssociations_611679,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUsers_611692 = ref object of OpenApiRestCall_610658
proc url_DescribeUsers_611694(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUsers_611693(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list that describes one or more specified users in the user pool.
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
  var valid_611695 = header.getOrDefault("X-Amz-Target")
  valid_611695 = validateParameter(valid_611695, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeUsers"))
  if valid_611695 != nil:
    section.add "X-Amz-Target", valid_611695
  var valid_611696 = header.getOrDefault("X-Amz-Signature")
  valid_611696 = validateParameter(valid_611696, JString, required = false,
                                 default = nil)
  if valid_611696 != nil:
    section.add "X-Amz-Signature", valid_611696
  var valid_611697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611697 = validateParameter(valid_611697, JString, required = false,
                                 default = nil)
  if valid_611697 != nil:
    section.add "X-Amz-Content-Sha256", valid_611697
  var valid_611698 = header.getOrDefault("X-Amz-Date")
  valid_611698 = validateParameter(valid_611698, JString, required = false,
                                 default = nil)
  if valid_611698 != nil:
    section.add "X-Amz-Date", valid_611698
  var valid_611699 = header.getOrDefault("X-Amz-Credential")
  valid_611699 = validateParameter(valid_611699, JString, required = false,
                                 default = nil)
  if valid_611699 != nil:
    section.add "X-Amz-Credential", valid_611699
  var valid_611700 = header.getOrDefault("X-Amz-Security-Token")
  valid_611700 = validateParameter(valid_611700, JString, required = false,
                                 default = nil)
  if valid_611700 != nil:
    section.add "X-Amz-Security-Token", valid_611700
  var valid_611701 = header.getOrDefault("X-Amz-Algorithm")
  valid_611701 = validateParameter(valid_611701, JString, required = false,
                                 default = nil)
  if valid_611701 != nil:
    section.add "X-Amz-Algorithm", valid_611701
  var valid_611702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611702 = validateParameter(valid_611702, JString, required = false,
                                 default = nil)
  if valid_611702 != nil:
    section.add "X-Amz-SignedHeaders", valid_611702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611704: Call_DescribeUsers_611692; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified users in the user pool.
  ## 
  let valid = call_611704.validator(path, query, header, formData, body)
  let scheme = call_611704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611704.url(scheme.get, call_611704.host, call_611704.base,
                         call_611704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611704, url, valid)

proc call*(call_611705: Call_DescribeUsers_611692; body: JsonNode): Recallable =
  ## describeUsers
  ## Retrieves a list that describes one or more specified users in the user pool.
  ##   body: JObject (required)
  var body_611706 = newJObject()
  if body != nil:
    body_611706 = body
  result = call_611705.call(nil, nil, nil, nil, body_611706)

var describeUsers* = Call_DescribeUsers_611692(name: "describeUsers",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeUsers",
    validator: validate_DescribeUsers_611693, base: "/", url: url_DescribeUsers_611694,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableUser_611707 = ref object of OpenApiRestCall_610658
proc url_DisableUser_611709(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableUser_611708(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Disables the specified user in the user pool. Users can't sign in to AppStream 2.0 until they are re-enabled. This action does not delete the user. 
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
  var valid_611710 = header.getOrDefault("X-Amz-Target")
  valid_611710 = validateParameter(valid_611710, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DisableUser"))
  if valid_611710 != nil:
    section.add "X-Amz-Target", valid_611710
  var valid_611711 = header.getOrDefault("X-Amz-Signature")
  valid_611711 = validateParameter(valid_611711, JString, required = false,
                                 default = nil)
  if valid_611711 != nil:
    section.add "X-Amz-Signature", valid_611711
  var valid_611712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611712 = validateParameter(valid_611712, JString, required = false,
                                 default = nil)
  if valid_611712 != nil:
    section.add "X-Amz-Content-Sha256", valid_611712
  var valid_611713 = header.getOrDefault("X-Amz-Date")
  valid_611713 = validateParameter(valid_611713, JString, required = false,
                                 default = nil)
  if valid_611713 != nil:
    section.add "X-Amz-Date", valid_611713
  var valid_611714 = header.getOrDefault("X-Amz-Credential")
  valid_611714 = validateParameter(valid_611714, JString, required = false,
                                 default = nil)
  if valid_611714 != nil:
    section.add "X-Amz-Credential", valid_611714
  var valid_611715 = header.getOrDefault("X-Amz-Security-Token")
  valid_611715 = validateParameter(valid_611715, JString, required = false,
                                 default = nil)
  if valid_611715 != nil:
    section.add "X-Amz-Security-Token", valid_611715
  var valid_611716 = header.getOrDefault("X-Amz-Algorithm")
  valid_611716 = validateParameter(valid_611716, JString, required = false,
                                 default = nil)
  if valid_611716 != nil:
    section.add "X-Amz-Algorithm", valid_611716
  var valid_611717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611717 = validateParameter(valid_611717, JString, required = false,
                                 default = nil)
  if valid_611717 != nil:
    section.add "X-Amz-SignedHeaders", valid_611717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611719: Call_DisableUser_611707; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the specified user in the user pool. Users can't sign in to AppStream 2.0 until they are re-enabled. This action does not delete the user. 
  ## 
  let valid = call_611719.validator(path, query, header, formData, body)
  let scheme = call_611719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611719.url(scheme.get, call_611719.host, call_611719.base,
                         call_611719.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611719, url, valid)

proc call*(call_611720: Call_DisableUser_611707; body: JsonNode): Recallable =
  ## disableUser
  ## Disables the specified user in the user pool. Users can't sign in to AppStream 2.0 until they are re-enabled. This action does not delete the user. 
  ##   body: JObject (required)
  var body_611721 = newJObject()
  if body != nil:
    body_611721 = body
  result = call_611720.call(nil, nil, nil, nil, body_611721)

var disableUser* = Call_DisableUser_611707(name: "disableUser",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DisableUser",
                                        validator: validate_DisableUser_611708,
                                        base: "/", url: url_DisableUser_611709,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateFleet_611722 = ref object of OpenApiRestCall_610658
proc url_DisassociateFleet_611724(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateFleet_611723(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Disassociates the specified fleet from the specified stack.
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
  var valid_611725 = header.getOrDefault("X-Amz-Target")
  valid_611725 = validateParameter(valid_611725, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DisassociateFleet"))
  if valid_611725 != nil:
    section.add "X-Amz-Target", valid_611725
  var valid_611726 = header.getOrDefault("X-Amz-Signature")
  valid_611726 = validateParameter(valid_611726, JString, required = false,
                                 default = nil)
  if valid_611726 != nil:
    section.add "X-Amz-Signature", valid_611726
  var valid_611727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611727 = validateParameter(valid_611727, JString, required = false,
                                 default = nil)
  if valid_611727 != nil:
    section.add "X-Amz-Content-Sha256", valid_611727
  var valid_611728 = header.getOrDefault("X-Amz-Date")
  valid_611728 = validateParameter(valid_611728, JString, required = false,
                                 default = nil)
  if valid_611728 != nil:
    section.add "X-Amz-Date", valid_611728
  var valid_611729 = header.getOrDefault("X-Amz-Credential")
  valid_611729 = validateParameter(valid_611729, JString, required = false,
                                 default = nil)
  if valid_611729 != nil:
    section.add "X-Amz-Credential", valid_611729
  var valid_611730 = header.getOrDefault("X-Amz-Security-Token")
  valid_611730 = validateParameter(valid_611730, JString, required = false,
                                 default = nil)
  if valid_611730 != nil:
    section.add "X-Amz-Security-Token", valid_611730
  var valid_611731 = header.getOrDefault("X-Amz-Algorithm")
  valid_611731 = validateParameter(valid_611731, JString, required = false,
                                 default = nil)
  if valid_611731 != nil:
    section.add "X-Amz-Algorithm", valid_611731
  var valid_611732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611732 = validateParameter(valid_611732, JString, required = false,
                                 default = nil)
  if valid_611732 != nil:
    section.add "X-Amz-SignedHeaders", valid_611732
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611734: Call_DisassociateFleet_611722; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified fleet from the specified stack.
  ## 
  let valid = call_611734.validator(path, query, header, formData, body)
  let scheme = call_611734.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611734.url(scheme.get, call_611734.host, call_611734.base,
                         call_611734.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611734, url, valid)

proc call*(call_611735: Call_DisassociateFleet_611722; body: JsonNode): Recallable =
  ## disassociateFleet
  ## Disassociates the specified fleet from the specified stack.
  ##   body: JObject (required)
  var body_611736 = newJObject()
  if body != nil:
    body_611736 = body
  result = call_611735.call(nil, nil, nil, nil, body_611736)

var disassociateFleet* = Call_DisassociateFleet_611722(name: "disassociateFleet",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DisassociateFleet",
    validator: validate_DisassociateFleet_611723, base: "/",
    url: url_DisassociateFleet_611724, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableUser_611737 = ref object of OpenApiRestCall_610658
proc url_EnableUser_611739(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableUser_611738(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Enables a user in the user pool. After being enabled, users can sign in to AppStream 2.0 and open applications from the stacks to which they are assigned.
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
  var valid_611740 = header.getOrDefault("X-Amz-Target")
  valid_611740 = validateParameter(valid_611740, JString, required = true, default = newJString(
      "PhotonAdminProxyService.EnableUser"))
  if valid_611740 != nil:
    section.add "X-Amz-Target", valid_611740
  var valid_611741 = header.getOrDefault("X-Amz-Signature")
  valid_611741 = validateParameter(valid_611741, JString, required = false,
                                 default = nil)
  if valid_611741 != nil:
    section.add "X-Amz-Signature", valid_611741
  var valid_611742 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611742 = validateParameter(valid_611742, JString, required = false,
                                 default = nil)
  if valid_611742 != nil:
    section.add "X-Amz-Content-Sha256", valid_611742
  var valid_611743 = header.getOrDefault("X-Amz-Date")
  valid_611743 = validateParameter(valid_611743, JString, required = false,
                                 default = nil)
  if valid_611743 != nil:
    section.add "X-Amz-Date", valid_611743
  var valid_611744 = header.getOrDefault("X-Amz-Credential")
  valid_611744 = validateParameter(valid_611744, JString, required = false,
                                 default = nil)
  if valid_611744 != nil:
    section.add "X-Amz-Credential", valid_611744
  var valid_611745 = header.getOrDefault("X-Amz-Security-Token")
  valid_611745 = validateParameter(valid_611745, JString, required = false,
                                 default = nil)
  if valid_611745 != nil:
    section.add "X-Amz-Security-Token", valid_611745
  var valid_611746 = header.getOrDefault("X-Amz-Algorithm")
  valid_611746 = validateParameter(valid_611746, JString, required = false,
                                 default = nil)
  if valid_611746 != nil:
    section.add "X-Amz-Algorithm", valid_611746
  var valid_611747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611747 = validateParameter(valid_611747, JString, required = false,
                                 default = nil)
  if valid_611747 != nil:
    section.add "X-Amz-SignedHeaders", valid_611747
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611749: Call_EnableUser_611737; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables a user in the user pool. After being enabled, users can sign in to AppStream 2.0 and open applications from the stacks to which they are assigned.
  ## 
  let valid = call_611749.validator(path, query, header, formData, body)
  let scheme = call_611749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611749.url(scheme.get, call_611749.host, call_611749.base,
                         call_611749.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611749, url, valid)

proc call*(call_611750: Call_EnableUser_611737; body: JsonNode): Recallable =
  ## enableUser
  ## Enables a user in the user pool. After being enabled, users can sign in to AppStream 2.0 and open applications from the stacks to which they are assigned.
  ##   body: JObject (required)
  var body_611751 = newJObject()
  if body != nil:
    body_611751 = body
  result = call_611750.call(nil, nil, nil, nil, body_611751)

var enableUser* = Call_EnableUser_611737(name: "enableUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.EnableUser",
                                      validator: validate_EnableUser_611738,
                                      base: "/", url: url_EnableUser_611739,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExpireSession_611752 = ref object of OpenApiRestCall_610658
proc url_ExpireSession_611754(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ExpireSession_611753(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Immediately stops the specified streaming session.
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
  var valid_611755 = header.getOrDefault("X-Amz-Target")
  valid_611755 = validateParameter(valid_611755, JString, required = true, default = newJString(
      "PhotonAdminProxyService.ExpireSession"))
  if valid_611755 != nil:
    section.add "X-Amz-Target", valid_611755
  var valid_611756 = header.getOrDefault("X-Amz-Signature")
  valid_611756 = validateParameter(valid_611756, JString, required = false,
                                 default = nil)
  if valid_611756 != nil:
    section.add "X-Amz-Signature", valid_611756
  var valid_611757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611757 = validateParameter(valid_611757, JString, required = false,
                                 default = nil)
  if valid_611757 != nil:
    section.add "X-Amz-Content-Sha256", valid_611757
  var valid_611758 = header.getOrDefault("X-Amz-Date")
  valid_611758 = validateParameter(valid_611758, JString, required = false,
                                 default = nil)
  if valid_611758 != nil:
    section.add "X-Amz-Date", valid_611758
  var valid_611759 = header.getOrDefault("X-Amz-Credential")
  valid_611759 = validateParameter(valid_611759, JString, required = false,
                                 default = nil)
  if valid_611759 != nil:
    section.add "X-Amz-Credential", valid_611759
  var valid_611760 = header.getOrDefault("X-Amz-Security-Token")
  valid_611760 = validateParameter(valid_611760, JString, required = false,
                                 default = nil)
  if valid_611760 != nil:
    section.add "X-Amz-Security-Token", valid_611760
  var valid_611761 = header.getOrDefault("X-Amz-Algorithm")
  valid_611761 = validateParameter(valid_611761, JString, required = false,
                                 default = nil)
  if valid_611761 != nil:
    section.add "X-Amz-Algorithm", valid_611761
  var valid_611762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611762 = validateParameter(valid_611762, JString, required = false,
                                 default = nil)
  if valid_611762 != nil:
    section.add "X-Amz-SignedHeaders", valid_611762
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611764: Call_ExpireSession_611752; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Immediately stops the specified streaming session.
  ## 
  let valid = call_611764.validator(path, query, header, formData, body)
  let scheme = call_611764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611764.url(scheme.get, call_611764.host, call_611764.base,
                         call_611764.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611764, url, valid)

proc call*(call_611765: Call_ExpireSession_611752; body: JsonNode): Recallable =
  ## expireSession
  ## Immediately stops the specified streaming session.
  ##   body: JObject (required)
  var body_611766 = newJObject()
  if body != nil:
    body_611766 = body
  result = call_611765.call(nil, nil, nil, nil, body_611766)

var expireSession* = Call_ExpireSession_611752(name: "expireSession",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.ExpireSession",
    validator: validate_ExpireSession_611753, base: "/", url: url_ExpireSession_611754,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociatedFleets_611767 = ref object of OpenApiRestCall_610658
proc url_ListAssociatedFleets_611769(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAssociatedFleets_611768(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the name of the fleet that is associated with the specified stack.
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
  var valid_611770 = header.getOrDefault("X-Amz-Target")
  valid_611770 = validateParameter(valid_611770, JString, required = true, default = newJString(
      "PhotonAdminProxyService.ListAssociatedFleets"))
  if valid_611770 != nil:
    section.add "X-Amz-Target", valid_611770
  var valid_611771 = header.getOrDefault("X-Amz-Signature")
  valid_611771 = validateParameter(valid_611771, JString, required = false,
                                 default = nil)
  if valid_611771 != nil:
    section.add "X-Amz-Signature", valid_611771
  var valid_611772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611772 = validateParameter(valid_611772, JString, required = false,
                                 default = nil)
  if valid_611772 != nil:
    section.add "X-Amz-Content-Sha256", valid_611772
  var valid_611773 = header.getOrDefault("X-Amz-Date")
  valid_611773 = validateParameter(valid_611773, JString, required = false,
                                 default = nil)
  if valid_611773 != nil:
    section.add "X-Amz-Date", valid_611773
  var valid_611774 = header.getOrDefault("X-Amz-Credential")
  valid_611774 = validateParameter(valid_611774, JString, required = false,
                                 default = nil)
  if valid_611774 != nil:
    section.add "X-Amz-Credential", valid_611774
  var valid_611775 = header.getOrDefault("X-Amz-Security-Token")
  valid_611775 = validateParameter(valid_611775, JString, required = false,
                                 default = nil)
  if valid_611775 != nil:
    section.add "X-Amz-Security-Token", valid_611775
  var valid_611776 = header.getOrDefault("X-Amz-Algorithm")
  valid_611776 = validateParameter(valid_611776, JString, required = false,
                                 default = nil)
  if valid_611776 != nil:
    section.add "X-Amz-Algorithm", valid_611776
  var valid_611777 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611777 = validateParameter(valid_611777, JString, required = false,
                                 default = nil)
  if valid_611777 != nil:
    section.add "X-Amz-SignedHeaders", valid_611777
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611779: Call_ListAssociatedFleets_611767; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the name of the fleet that is associated with the specified stack.
  ## 
  let valid = call_611779.validator(path, query, header, formData, body)
  let scheme = call_611779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611779.url(scheme.get, call_611779.host, call_611779.base,
                         call_611779.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611779, url, valid)

proc call*(call_611780: Call_ListAssociatedFleets_611767; body: JsonNode): Recallable =
  ## listAssociatedFleets
  ## Retrieves the name of the fleet that is associated with the specified stack.
  ##   body: JObject (required)
  var body_611781 = newJObject()
  if body != nil:
    body_611781 = body
  result = call_611780.call(nil, nil, nil, nil, body_611781)

var listAssociatedFleets* = Call_ListAssociatedFleets_611767(
    name: "listAssociatedFleets", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.ListAssociatedFleets",
    validator: validate_ListAssociatedFleets_611768, base: "/",
    url: url_ListAssociatedFleets_611769, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociatedStacks_611782 = ref object of OpenApiRestCall_610658
proc url_ListAssociatedStacks_611784(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAssociatedStacks_611783(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the name of the stack with which the specified fleet is associated.
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
  var valid_611785 = header.getOrDefault("X-Amz-Target")
  valid_611785 = validateParameter(valid_611785, JString, required = true, default = newJString(
      "PhotonAdminProxyService.ListAssociatedStacks"))
  if valid_611785 != nil:
    section.add "X-Amz-Target", valid_611785
  var valid_611786 = header.getOrDefault("X-Amz-Signature")
  valid_611786 = validateParameter(valid_611786, JString, required = false,
                                 default = nil)
  if valid_611786 != nil:
    section.add "X-Amz-Signature", valid_611786
  var valid_611787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611787 = validateParameter(valid_611787, JString, required = false,
                                 default = nil)
  if valid_611787 != nil:
    section.add "X-Amz-Content-Sha256", valid_611787
  var valid_611788 = header.getOrDefault("X-Amz-Date")
  valid_611788 = validateParameter(valid_611788, JString, required = false,
                                 default = nil)
  if valid_611788 != nil:
    section.add "X-Amz-Date", valid_611788
  var valid_611789 = header.getOrDefault("X-Amz-Credential")
  valid_611789 = validateParameter(valid_611789, JString, required = false,
                                 default = nil)
  if valid_611789 != nil:
    section.add "X-Amz-Credential", valid_611789
  var valid_611790 = header.getOrDefault("X-Amz-Security-Token")
  valid_611790 = validateParameter(valid_611790, JString, required = false,
                                 default = nil)
  if valid_611790 != nil:
    section.add "X-Amz-Security-Token", valid_611790
  var valid_611791 = header.getOrDefault("X-Amz-Algorithm")
  valid_611791 = validateParameter(valid_611791, JString, required = false,
                                 default = nil)
  if valid_611791 != nil:
    section.add "X-Amz-Algorithm", valid_611791
  var valid_611792 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611792 = validateParameter(valid_611792, JString, required = false,
                                 default = nil)
  if valid_611792 != nil:
    section.add "X-Amz-SignedHeaders", valid_611792
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611794: Call_ListAssociatedStacks_611782; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the name of the stack with which the specified fleet is associated.
  ## 
  let valid = call_611794.validator(path, query, header, formData, body)
  let scheme = call_611794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611794.url(scheme.get, call_611794.host, call_611794.base,
                         call_611794.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611794, url, valid)

proc call*(call_611795: Call_ListAssociatedStacks_611782; body: JsonNode): Recallable =
  ## listAssociatedStacks
  ## Retrieves the name of the stack with which the specified fleet is associated.
  ##   body: JObject (required)
  var body_611796 = newJObject()
  if body != nil:
    body_611796 = body
  result = call_611795.call(nil, nil, nil, nil, body_611796)

var listAssociatedStacks* = Call_ListAssociatedStacks_611782(
    name: "listAssociatedStacks", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.ListAssociatedStacks",
    validator: validate_ListAssociatedStacks_611783, base: "/",
    url: url_ListAssociatedStacks_611784, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_611797 = ref object of OpenApiRestCall_610658
proc url_ListTagsForResource_611799(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_611798(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Retrieves a list of all tags for the specified AppStream 2.0 resource. You can tag AppStream 2.0 image builders, images, fleets, and stacks.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
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
  var valid_611800 = header.getOrDefault("X-Amz-Target")
  valid_611800 = validateParameter(valid_611800, JString, required = true, default = newJString(
      "PhotonAdminProxyService.ListTagsForResource"))
  if valid_611800 != nil:
    section.add "X-Amz-Target", valid_611800
  var valid_611801 = header.getOrDefault("X-Amz-Signature")
  valid_611801 = validateParameter(valid_611801, JString, required = false,
                                 default = nil)
  if valid_611801 != nil:
    section.add "X-Amz-Signature", valid_611801
  var valid_611802 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611802 = validateParameter(valid_611802, JString, required = false,
                                 default = nil)
  if valid_611802 != nil:
    section.add "X-Amz-Content-Sha256", valid_611802
  var valid_611803 = header.getOrDefault("X-Amz-Date")
  valid_611803 = validateParameter(valid_611803, JString, required = false,
                                 default = nil)
  if valid_611803 != nil:
    section.add "X-Amz-Date", valid_611803
  var valid_611804 = header.getOrDefault("X-Amz-Credential")
  valid_611804 = validateParameter(valid_611804, JString, required = false,
                                 default = nil)
  if valid_611804 != nil:
    section.add "X-Amz-Credential", valid_611804
  var valid_611805 = header.getOrDefault("X-Amz-Security-Token")
  valid_611805 = validateParameter(valid_611805, JString, required = false,
                                 default = nil)
  if valid_611805 != nil:
    section.add "X-Amz-Security-Token", valid_611805
  var valid_611806 = header.getOrDefault("X-Amz-Algorithm")
  valid_611806 = validateParameter(valid_611806, JString, required = false,
                                 default = nil)
  if valid_611806 != nil:
    section.add "X-Amz-Algorithm", valid_611806
  var valid_611807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611807 = validateParameter(valid_611807, JString, required = false,
                                 default = nil)
  if valid_611807 != nil:
    section.add "X-Amz-SignedHeaders", valid_611807
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611809: Call_ListTagsForResource_611797; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of all tags for the specified AppStream 2.0 resource. You can tag AppStream 2.0 image builders, images, fleets, and stacks.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
  ## 
  let valid = call_611809.validator(path, query, header, formData, body)
  let scheme = call_611809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611809.url(scheme.get, call_611809.host, call_611809.base,
                         call_611809.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611809, url, valid)

proc call*(call_611810: Call_ListTagsForResource_611797; body: JsonNode): Recallable =
  ## listTagsForResource
  ## <p>Retrieves a list of all tags for the specified AppStream 2.0 resource. You can tag AppStream 2.0 image builders, images, fleets, and stacks.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
  ##   body: JObject (required)
  var body_611811 = newJObject()
  if body != nil:
    body_611811 = body
  result = call_611810.call(nil, nil, nil, nil, body_611811)

var listTagsForResource* = Call_ListTagsForResource_611797(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.ListTagsForResource",
    validator: validate_ListTagsForResource_611798, base: "/",
    url: url_ListTagsForResource_611799, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartFleet_611812 = ref object of OpenApiRestCall_610658
proc url_StartFleet_611814(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartFleet_611813(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts the specified fleet.
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
  var valid_611815 = header.getOrDefault("X-Amz-Target")
  valid_611815 = validateParameter(valid_611815, JString, required = true, default = newJString(
      "PhotonAdminProxyService.StartFleet"))
  if valid_611815 != nil:
    section.add "X-Amz-Target", valid_611815
  var valid_611816 = header.getOrDefault("X-Amz-Signature")
  valid_611816 = validateParameter(valid_611816, JString, required = false,
                                 default = nil)
  if valid_611816 != nil:
    section.add "X-Amz-Signature", valid_611816
  var valid_611817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611817 = validateParameter(valid_611817, JString, required = false,
                                 default = nil)
  if valid_611817 != nil:
    section.add "X-Amz-Content-Sha256", valid_611817
  var valid_611818 = header.getOrDefault("X-Amz-Date")
  valid_611818 = validateParameter(valid_611818, JString, required = false,
                                 default = nil)
  if valid_611818 != nil:
    section.add "X-Amz-Date", valid_611818
  var valid_611819 = header.getOrDefault("X-Amz-Credential")
  valid_611819 = validateParameter(valid_611819, JString, required = false,
                                 default = nil)
  if valid_611819 != nil:
    section.add "X-Amz-Credential", valid_611819
  var valid_611820 = header.getOrDefault("X-Amz-Security-Token")
  valid_611820 = validateParameter(valid_611820, JString, required = false,
                                 default = nil)
  if valid_611820 != nil:
    section.add "X-Amz-Security-Token", valid_611820
  var valid_611821 = header.getOrDefault("X-Amz-Algorithm")
  valid_611821 = validateParameter(valid_611821, JString, required = false,
                                 default = nil)
  if valid_611821 != nil:
    section.add "X-Amz-Algorithm", valid_611821
  var valid_611822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611822 = validateParameter(valid_611822, JString, required = false,
                                 default = nil)
  if valid_611822 != nil:
    section.add "X-Amz-SignedHeaders", valid_611822
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611824: Call_StartFleet_611812; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the specified fleet.
  ## 
  let valid = call_611824.validator(path, query, header, formData, body)
  let scheme = call_611824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611824.url(scheme.get, call_611824.host, call_611824.base,
                         call_611824.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611824, url, valid)

proc call*(call_611825: Call_StartFleet_611812; body: JsonNode): Recallable =
  ## startFleet
  ## Starts the specified fleet.
  ##   body: JObject (required)
  var body_611826 = newJObject()
  if body != nil:
    body_611826 = body
  result = call_611825.call(nil, nil, nil, nil, body_611826)

var startFleet* = Call_StartFleet_611812(name: "startFleet",
                                      meth: HttpMethod.HttpPost,
                                      host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.StartFleet",
                                      validator: validate_StartFleet_611813,
                                      base: "/", url: url_StartFleet_611814,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImageBuilder_611827 = ref object of OpenApiRestCall_610658
proc url_StartImageBuilder_611829(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartImageBuilder_611828(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Starts the specified image builder.
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
  var valid_611830 = header.getOrDefault("X-Amz-Target")
  valid_611830 = validateParameter(valid_611830, JString, required = true, default = newJString(
      "PhotonAdminProxyService.StartImageBuilder"))
  if valid_611830 != nil:
    section.add "X-Amz-Target", valid_611830
  var valid_611831 = header.getOrDefault("X-Amz-Signature")
  valid_611831 = validateParameter(valid_611831, JString, required = false,
                                 default = nil)
  if valid_611831 != nil:
    section.add "X-Amz-Signature", valid_611831
  var valid_611832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611832 = validateParameter(valid_611832, JString, required = false,
                                 default = nil)
  if valid_611832 != nil:
    section.add "X-Amz-Content-Sha256", valid_611832
  var valid_611833 = header.getOrDefault("X-Amz-Date")
  valid_611833 = validateParameter(valid_611833, JString, required = false,
                                 default = nil)
  if valid_611833 != nil:
    section.add "X-Amz-Date", valid_611833
  var valid_611834 = header.getOrDefault("X-Amz-Credential")
  valid_611834 = validateParameter(valid_611834, JString, required = false,
                                 default = nil)
  if valid_611834 != nil:
    section.add "X-Amz-Credential", valid_611834
  var valid_611835 = header.getOrDefault("X-Amz-Security-Token")
  valid_611835 = validateParameter(valid_611835, JString, required = false,
                                 default = nil)
  if valid_611835 != nil:
    section.add "X-Amz-Security-Token", valid_611835
  var valid_611836 = header.getOrDefault("X-Amz-Algorithm")
  valid_611836 = validateParameter(valid_611836, JString, required = false,
                                 default = nil)
  if valid_611836 != nil:
    section.add "X-Amz-Algorithm", valid_611836
  var valid_611837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611837 = validateParameter(valid_611837, JString, required = false,
                                 default = nil)
  if valid_611837 != nil:
    section.add "X-Amz-SignedHeaders", valid_611837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611839: Call_StartImageBuilder_611827; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the specified image builder.
  ## 
  let valid = call_611839.validator(path, query, header, formData, body)
  let scheme = call_611839.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611839.url(scheme.get, call_611839.host, call_611839.base,
                         call_611839.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611839, url, valid)

proc call*(call_611840: Call_StartImageBuilder_611827; body: JsonNode): Recallable =
  ## startImageBuilder
  ## Starts the specified image builder.
  ##   body: JObject (required)
  var body_611841 = newJObject()
  if body != nil:
    body_611841 = body
  result = call_611840.call(nil, nil, nil, nil, body_611841)

var startImageBuilder* = Call_StartImageBuilder_611827(name: "startImageBuilder",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.StartImageBuilder",
    validator: validate_StartImageBuilder_611828, base: "/",
    url: url_StartImageBuilder_611829, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopFleet_611842 = ref object of OpenApiRestCall_610658
proc url_StopFleet_611844(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopFleet_611843(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Stops the specified fleet.
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
  var valid_611845 = header.getOrDefault("X-Amz-Target")
  valid_611845 = validateParameter(valid_611845, JString, required = true, default = newJString(
      "PhotonAdminProxyService.StopFleet"))
  if valid_611845 != nil:
    section.add "X-Amz-Target", valid_611845
  var valid_611846 = header.getOrDefault("X-Amz-Signature")
  valid_611846 = validateParameter(valid_611846, JString, required = false,
                                 default = nil)
  if valid_611846 != nil:
    section.add "X-Amz-Signature", valid_611846
  var valid_611847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611847 = validateParameter(valid_611847, JString, required = false,
                                 default = nil)
  if valid_611847 != nil:
    section.add "X-Amz-Content-Sha256", valid_611847
  var valid_611848 = header.getOrDefault("X-Amz-Date")
  valid_611848 = validateParameter(valid_611848, JString, required = false,
                                 default = nil)
  if valid_611848 != nil:
    section.add "X-Amz-Date", valid_611848
  var valid_611849 = header.getOrDefault("X-Amz-Credential")
  valid_611849 = validateParameter(valid_611849, JString, required = false,
                                 default = nil)
  if valid_611849 != nil:
    section.add "X-Amz-Credential", valid_611849
  var valid_611850 = header.getOrDefault("X-Amz-Security-Token")
  valid_611850 = validateParameter(valid_611850, JString, required = false,
                                 default = nil)
  if valid_611850 != nil:
    section.add "X-Amz-Security-Token", valid_611850
  var valid_611851 = header.getOrDefault("X-Amz-Algorithm")
  valid_611851 = validateParameter(valid_611851, JString, required = false,
                                 default = nil)
  if valid_611851 != nil:
    section.add "X-Amz-Algorithm", valid_611851
  var valid_611852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611852 = validateParameter(valid_611852, JString, required = false,
                                 default = nil)
  if valid_611852 != nil:
    section.add "X-Amz-SignedHeaders", valid_611852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611854: Call_StopFleet_611842; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the specified fleet.
  ## 
  let valid = call_611854.validator(path, query, header, formData, body)
  let scheme = call_611854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611854.url(scheme.get, call_611854.host, call_611854.base,
                         call_611854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611854, url, valid)

proc call*(call_611855: Call_StopFleet_611842; body: JsonNode): Recallable =
  ## stopFleet
  ## Stops the specified fleet.
  ##   body: JObject (required)
  var body_611856 = newJObject()
  if body != nil:
    body_611856 = body
  result = call_611855.call(nil, nil, nil, nil, body_611856)

var stopFleet* = Call_StopFleet_611842(name: "stopFleet", meth: HttpMethod.HttpPost,
                                    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.StopFleet",
                                    validator: validate_StopFleet_611843,
                                    base: "/", url: url_StopFleet_611844,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopImageBuilder_611857 = ref object of OpenApiRestCall_610658
proc url_StopImageBuilder_611859(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopImageBuilder_611858(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Stops the specified image builder.
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
  var valid_611860 = header.getOrDefault("X-Amz-Target")
  valid_611860 = validateParameter(valid_611860, JString, required = true, default = newJString(
      "PhotonAdminProxyService.StopImageBuilder"))
  if valid_611860 != nil:
    section.add "X-Amz-Target", valid_611860
  var valid_611861 = header.getOrDefault("X-Amz-Signature")
  valid_611861 = validateParameter(valid_611861, JString, required = false,
                                 default = nil)
  if valid_611861 != nil:
    section.add "X-Amz-Signature", valid_611861
  var valid_611862 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611862 = validateParameter(valid_611862, JString, required = false,
                                 default = nil)
  if valid_611862 != nil:
    section.add "X-Amz-Content-Sha256", valid_611862
  var valid_611863 = header.getOrDefault("X-Amz-Date")
  valid_611863 = validateParameter(valid_611863, JString, required = false,
                                 default = nil)
  if valid_611863 != nil:
    section.add "X-Amz-Date", valid_611863
  var valid_611864 = header.getOrDefault("X-Amz-Credential")
  valid_611864 = validateParameter(valid_611864, JString, required = false,
                                 default = nil)
  if valid_611864 != nil:
    section.add "X-Amz-Credential", valid_611864
  var valid_611865 = header.getOrDefault("X-Amz-Security-Token")
  valid_611865 = validateParameter(valid_611865, JString, required = false,
                                 default = nil)
  if valid_611865 != nil:
    section.add "X-Amz-Security-Token", valid_611865
  var valid_611866 = header.getOrDefault("X-Amz-Algorithm")
  valid_611866 = validateParameter(valid_611866, JString, required = false,
                                 default = nil)
  if valid_611866 != nil:
    section.add "X-Amz-Algorithm", valid_611866
  var valid_611867 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611867 = validateParameter(valid_611867, JString, required = false,
                                 default = nil)
  if valid_611867 != nil:
    section.add "X-Amz-SignedHeaders", valid_611867
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611869: Call_StopImageBuilder_611857; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the specified image builder.
  ## 
  let valid = call_611869.validator(path, query, header, formData, body)
  let scheme = call_611869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611869.url(scheme.get, call_611869.host, call_611869.base,
                         call_611869.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611869, url, valid)

proc call*(call_611870: Call_StopImageBuilder_611857; body: JsonNode): Recallable =
  ## stopImageBuilder
  ## Stops the specified image builder.
  ##   body: JObject (required)
  var body_611871 = newJObject()
  if body != nil:
    body_611871 = body
  result = call_611870.call(nil, nil, nil, nil, body_611871)

var stopImageBuilder* = Call_StopImageBuilder_611857(name: "stopImageBuilder",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.StopImageBuilder",
    validator: validate_StopImageBuilder_611858, base: "/",
    url: url_StopImageBuilder_611859, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_611872 = ref object of OpenApiRestCall_610658
proc url_TagResource_611874(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_611873(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds or overwrites one or more tags for the specified AppStream 2.0 resource. You can tag AppStream 2.0 image builders, images, fleets, and stacks.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, this operation updates its value.</p> <p>To list the current tags for your resources, use <a>ListTagsForResource</a>. To disassociate tags from your resources, use <a>UntagResource</a>.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
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
  var valid_611875 = header.getOrDefault("X-Amz-Target")
  valid_611875 = validateParameter(valid_611875, JString, required = true, default = newJString(
      "PhotonAdminProxyService.TagResource"))
  if valid_611875 != nil:
    section.add "X-Amz-Target", valid_611875
  var valid_611876 = header.getOrDefault("X-Amz-Signature")
  valid_611876 = validateParameter(valid_611876, JString, required = false,
                                 default = nil)
  if valid_611876 != nil:
    section.add "X-Amz-Signature", valid_611876
  var valid_611877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611877 = validateParameter(valid_611877, JString, required = false,
                                 default = nil)
  if valid_611877 != nil:
    section.add "X-Amz-Content-Sha256", valid_611877
  var valid_611878 = header.getOrDefault("X-Amz-Date")
  valid_611878 = validateParameter(valid_611878, JString, required = false,
                                 default = nil)
  if valid_611878 != nil:
    section.add "X-Amz-Date", valid_611878
  var valid_611879 = header.getOrDefault("X-Amz-Credential")
  valid_611879 = validateParameter(valid_611879, JString, required = false,
                                 default = nil)
  if valid_611879 != nil:
    section.add "X-Amz-Credential", valid_611879
  var valid_611880 = header.getOrDefault("X-Amz-Security-Token")
  valid_611880 = validateParameter(valid_611880, JString, required = false,
                                 default = nil)
  if valid_611880 != nil:
    section.add "X-Amz-Security-Token", valid_611880
  var valid_611881 = header.getOrDefault("X-Amz-Algorithm")
  valid_611881 = validateParameter(valid_611881, JString, required = false,
                                 default = nil)
  if valid_611881 != nil:
    section.add "X-Amz-Algorithm", valid_611881
  var valid_611882 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611882 = validateParameter(valid_611882, JString, required = false,
                                 default = nil)
  if valid_611882 != nil:
    section.add "X-Amz-SignedHeaders", valid_611882
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611884: Call_TagResource_611872; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or overwrites one or more tags for the specified AppStream 2.0 resource. You can tag AppStream 2.0 image builders, images, fleets, and stacks.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, this operation updates its value.</p> <p>To list the current tags for your resources, use <a>ListTagsForResource</a>. To disassociate tags from your resources, use <a>UntagResource</a>.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
  ## 
  let valid = call_611884.validator(path, query, header, formData, body)
  let scheme = call_611884.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611884.url(scheme.get, call_611884.host, call_611884.base,
                         call_611884.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611884, url, valid)

proc call*(call_611885: Call_TagResource_611872; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds or overwrites one or more tags for the specified AppStream 2.0 resource. You can tag AppStream 2.0 image builders, images, fleets, and stacks.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, this operation updates its value.</p> <p>To list the current tags for your resources, use <a>ListTagsForResource</a>. To disassociate tags from your resources, use <a>UntagResource</a>.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
  ##   body: JObject (required)
  var body_611886 = newJObject()
  if body != nil:
    body_611886 = body
  result = call_611885.call(nil, nil, nil, nil, body_611886)

var tagResource* = Call_TagResource_611872(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.TagResource",
                                        validator: validate_TagResource_611873,
                                        base: "/", url: url_TagResource_611874,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_611887 = ref object of OpenApiRestCall_610658
proc url_UntagResource_611889(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_611888(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Disassociates one or more specified tags from the specified AppStream 2.0 resource.</p> <p>To list the current tags for your resources, use <a>ListTagsForResource</a>.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
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
  var valid_611890 = header.getOrDefault("X-Amz-Target")
  valid_611890 = validateParameter(valid_611890, JString, required = true, default = newJString(
      "PhotonAdminProxyService.UntagResource"))
  if valid_611890 != nil:
    section.add "X-Amz-Target", valid_611890
  var valid_611891 = header.getOrDefault("X-Amz-Signature")
  valid_611891 = validateParameter(valid_611891, JString, required = false,
                                 default = nil)
  if valid_611891 != nil:
    section.add "X-Amz-Signature", valid_611891
  var valid_611892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611892 = validateParameter(valid_611892, JString, required = false,
                                 default = nil)
  if valid_611892 != nil:
    section.add "X-Amz-Content-Sha256", valid_611892
  var valid_611893 = header.getOrDefault("X-Amz-Date")
  valid_611893 = validateParameter(valid_611893, JString, required = false,
                                 default = nil)
  if valid_611893 != nil:
    section.add "X-Amz-Date", valid_611893
  var valid_611894 = header.getOrDefault("X-Amz-Credential")
  valid_611894 = validateParameter(valid_611894, JString, required = false,
                                 default = nil)
  if valid_611894 != nil:
    section.add "X-Amz-Credential", valid_611894
  var valid_611895 = header.getOrDefault("X-Amz-Security-Token")
  valid_611895 = validateParameter(valid_611895, JString, required = false,
                                 default = nil)
  if valid_611895 != nil:
    section.add "X-Amz-Security-Token", valid_611895
  var valid_611896 = header.getOrDefault("X-Amz-Algorithm")
  valid_611896 = validateParameter(valid_611896, JString, required = false,
                                 default = nil)
  if valid_611896 != nil:
    section.add "X-Amz-Algorithm", valid_611896
  var valid_611897 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611897 = validateParameter(valid_611897, JString, required = false,
                                 default = nil)
  if valid_611897 != nil:
    section.add "X-Amz-SignedHeaders", valid_611897
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611899: Call_UntagResource_611887; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates one or more specified tags from the specified AppStream 2.0 resource.</p> <p>To list the current tags for your resources, use <a>ListTagsForResource</a>.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
  ## 
  let valid = call_611899.validator(path, query, header, formData, body)
  let scheme = call_611899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611899.url(scheme.get, call_611899.host, call_611899.base,
                         call_611899.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611899, url, valid)

proc call*(call_611900: Call_UntagResource_611887; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Disassociates one or more specified tags from the specified AppStream 2.0 resource.</p> <p>To list the current tags for your resources, use <a>ListTagsForResource</a>.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
  ##   body: JObject (required)
  var body_611901 = newJObject()
  if body != nil:
    body_611901 = body
  result = call_611900.call(nil, nil, nil, nil, body_611901)

var untagResource* = Call_UntagResource_611887(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.UntagResource",
    validator: validate_UntagResource_611888, base: "/", url: url_UntagResource_611889,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDirectoryConfig_611902 = ref object of OpenApiRestCall_610658
proc url_UpdateDirectoryConfig_611904(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDirectoryConfig_611903(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the specified Directory Config object in AppStream 2.0. This object includes the configuration information required to join fleets and image builders to Microsoft Active Directory domains.
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
  var valid_611905 = header.getOrDefault("X-Amz-Target")
  valid_611905 = validateParameter(valid_611905, JString, required = true, default = newJString(
      "PhotonAdminProxyService.UpdateDirectoryConfig"))
  if valid_611905 != nil:
    section.add "X-Amz-Target", valid_611905
  var valid_611906 = header.getOrDefault("X-Amz-Signature")
  valid_611906 = validateParameter(valid_611906, JString, required = false,
                                 default = nil)
  if valid_611906 != nil:
    section.add "X-Amz-Signature", valid_611906
  var valid_611907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611907 = validateParameter(valid_611907, JString, required = false,
                                 default = nil)
  if valid_611907 != nil:
    section.add "X-Amz-Content-Sha256", valid_611907
  var valid_611908 = header.getOrDefault("X-Amz-Date")
  valid_611908 = validateParameter(valid_611908, JString, required = false,
                                 default = nil)
  if valid_611908 != nil:
    section.add "X-Amz-Date", valid_611908
  var valid_611909 = header.getOrDefault("X-Amz-Credential")
  valid_611909 = validateParameter(valid_611909, JString, required = false,
                                 default = nil)
  if valid_611909 != nil:
    section.add "X-Amz-Credential", valid_611909
  var valid_611910 = header.getOrDefault("X-Amz-Security-Token")
  valid_611910 = validateParameter(valid_611910, JString, required = false,
                                 default = nil)
  if valid_611910 != nil:
    section.add "X-Amz-Security-Token", valid_611910
  var valid_611911 = header.getOrDefault("X-Amz-Algorithm")
  valid_611911 = validateParameter(valid_611911, JString, required = false,
                                 default = nil)
  if valid_611911 != nil:
    section.add "X-Amz-Algorithm", valid_611911
  var valid_611912 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611912 = validateParameter(valid_611912, JString, required = false,
                                 default = nil)
  if valid_611912 != nil:
    section.add "X-Amz-SignedHeaders", valid_611912
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611914: Call_UpdateDirectoryConfig_611902; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified Directory Config object in AppStream 2.0. This object includes the configuration information required to join fleets and image builders to Microsoft Active Directory domains.
  ## 
  let valid = call_611914.validator(path, query, header, formData, body)
  let scheme = call_611914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611914.url(scheme.get, call_611914.host, call_611914.base,
                         call_611914.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611914, url, valid)

proc call*(call_611915: Call_UpdateDirectoryConfig_611902; body: JsonNode): Recallable =
  ## updateDirectoryConfig
  ## Updates the specified Directory Config object in AppStream 2.0. This object includes the configuration information required to join fleets and image builders to Microsoft Active Directory domains.
  ##   body: JObject (required)
  var body_611916 = newJObject()
  if body != nil:
    body_611916 = body
  result = call_611915.call(nil, nil, nil, nil, body_611916)

var updateDirectoryConfig* = Call_UpdateDirectoryConfig_611902(
    name: "updateDirectoryConfig", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.UpdateDirectoryConfig",
    validator: validate_UpdateDirectoryConfig_611903, base: "/",
    url: url_UpdateDirectoryConfig_611904, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFleet_611917 = ref object of OpenApiRestCall_610658
proc url_UpdateFleet_611919(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateFleet_611918(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the specified fleet.</p> <p>If the fleet is in the <code>STOPPED</code> state, you can update any attribute except the fleet name. If the fleet is in the <code>RUNNING</code> state, you can update the <code>DisplayName</code>, <code>ComputeCapacity</code>, <code>ImageARN</code>, <code>ImageName</code>, <code>IdleDisconnectTimeoutInSeconds</code>, and <code>DisconnectTimeoutInSeconds</code> attributes. If the fleet is in the <code>STARTING</code> or <code>STOPPING</code> state, you can't update it.</p>
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
  var valid_611920 = header.getOrDefault("X-Amz-Target")
  valid_611920 = validateParameter(valid_611920, JString, required = true, default = newJString(
      "PhotonAdminProxyService.UpdateFleet"))
  if valid_611920 != nil:
    section.add "X-Amz-Target", valid_611920
  var valid_611921 = header.getOrDefault("X-Amz-Signature")
  valid_611921 = validateParameter(valid_611921, JString, required = false,
                                 default = nil)
  if valid_611921 != nil:
    section.add "X-Amz-Signature", valid_611921
  var valid_611922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611922 = validateParameter(valid_611922, JString, required = false,
                                 default = nil)
  if valid_611922 != nil:
    section.add "X-Amz-Content-Sha256", valid_611922
  var valid_611923 = header.getOrDefault("X-Amz-Date")
  valid_611923 = validateParameter(valid_611923, JString, required = false,
                                 default = nil)
  if valid_611923 != nil:
    section.add "X-Amz-Date", valid_611923
  var valid_611924 = header.getOrDefault("X-Amz-Credential")
  valid_611924 = validateParameter(valid_611924, JString, required = false,
                                 default = nil)
  if valid_611924 != nil:
    section.add "X-Amz-Credential", valid_611924
  var valid_611925 = header.getOrDefault("X-Amz-Security-Token")
  valid_611925 = validateParameter(valid_611925, JString, required = false,
                                 default = nil)
  if valid_611925 != nil:
    section.add "X-Amz-Security-Token", valid_611925
  var valid_611926 = header.getOrDefault("X-Amz-Algorithm")
  valid_611926 = validateParameter(valid_611926, JString, required = false,
                                 default = nil)
  if valid_611926 != nil:
    section.add "X-Amz-Algorithm", valid_611926
  var valid_611927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611927 = validateParameter(valid_611927, JString, required = false,
                                 default = nil)
  if valid_611927 != nil:
    section.add "X-Amz-SignedHeaders", valid_611927
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611929: Call_UpdateFleet_611917; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified fleet.</p> <p>If the fleet is in the <code>STOPPED</code> state, you can update any attribute except the fleet name. If the fleet is in the <code>RUNNING</code> state, you can update the <code>DisplayName</code>, <code>ComputeCapacity</code>, <code>ImageARN</code>, <code>ImageName</code>, <code>IdleDisconnectTimeoutInSeconds</code>, and <code>DisconnectTimeoutInSeconds</code> attributes. If the fleet is in the <code>STARTING</code> or <code>STOPPING</code> state, you can't update it.</p>
  ## 
  let valid = call_611929.validator(path, query, header, formData, body)
  let scheme = call_611929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611929.url(scheme.get, call_611929.host, call_611929.base,
                         call_611929.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611929, url, valid)

proc call*(call_611930: Call_UpdateFleet_611917; body: JsonNode): Recallable =
  ## updateFleet
  ## <p>Updates the specified fleet.</p> <p>If the fleet is in the <code>STOPPED</code> state, you can update any attribute except the fleet name. If the fleet is in the <code>RUNNING</code> state, you can update the <code>DisplayName</code>, <code>ComputeCapacity</code>, <code>ImageARN</code>, <code>ImageName</code>, <code>IdleDisconnectTimeoutInSeconds</code>, and <code>DisconnectTimeoutInSeconds</code> attributes. If the fleet is in the <code>STARTING</code> or <code>STOPPING</code> state, you can't update it.</p>
  ##   body: JObject (required)
  var body_611931 = newJObject()
  if body != nil:
    body_611931 = body
  result = call_611930.call(nil, nil, nil, nil, body_611931)

var updateFleet* = Call_UpdateFleet_611917(name: "updateFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.UpdateFleet",
                                        validator: validate_UpdateFleet_611918,
                                        base: "/", url: url_UpdateFleet_611919,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateImagePermissions_611932 = ref object of OpenApiRestCall_610658
proc url_UpdateImagePermissions_611934(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateImagePermissions_611933(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds or updates permissions for the specified private image. 
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
  var valid_611935 = header.getOrDefault("X-Amz-Target")
  valid_611935 = validateParameter(valid_611935, JString, required = true, default = newJString(
      "PhotonAdminProxyService.UpdateImagePermissions"))
  if valid_611935 != nil:
    section.add "X-Amz-Target", valid_611935
  var valid_611936 = header.getOrDefault("X-Amz-Signature")
  valid_611936 = validateParameter(valid_611936, JString, required = false,
                                 default = nil)
  if valid_611936 != nil:
    section.add "X-Amz-Signature", valid_611936
  var valid_611937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611937 = validateParameter(valid_611937, JString, required = false,
                                 default = nil)
  if valid_611937 != nil:
    section.add "X-Amz-Content-Sha256", valid_611937
  var valid_611938 = header.getOrDefault("X-Amz-Date")
  valid_611938 = validateParameter(valid_611938, JString, required = false,
                                 default = nil)
  if valid_611938 != nil:
    section.add "X-Amz-Date", valid_611938
  var valid_611939 = header.getOrDefault("X-Amz-Credential")
  valid_611939 = validateParameter(valid_611939, JString, required = false,
                                 default = nil)
  if valid_611939 != nil:
    section.add "X-Amz-Credential", valid_611939
  var valid_611940 = header.getOrDefault("X-Amz-Security-Token")
  valid_611940 = validateParameter(valid_611940, JString, required = false,
                                 default = nil)
  if valid_611940 != nil:
    section.add "X-Amz-Security-Token", valid_611940
  var valid_611941 = header.getOrDefault("X-Amz-Algorithm")
  valid_611941 = validateParameter(valid_611941, JString, required = false,
                                 default = nil)
  if valid_611941 != nil:
    section.add "X-Amz-Algorithm", valid_611941
  var valid_611942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611942 = validateParameter(valid_611942, JString, required = false,
                                 default = nil)
  if valid_611942 != nil:
    section.add "X-Amz-SignedHeaders", valid_611942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611944: Call_UpdateImagePermissions_611932; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates permissions for the specified private image. 
  ## 
  let valid = call_611944.validator(path, query, header, formData, body)
  let scheme = call_611944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611944.url(scheme.get, call_611944.host, call_611944.base,
                         call_611944.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611944, url, valid)

proc call*(call_611945: Call_UpdateImagePermissions_611932; body: JsonNode): Recallable =
  ## updateImagePermissions
  ## Adds or updates permissions for the specified private image. 
  ##   body: JObject (required)
  var body_611946 = newJObject()
  if body != nil:
    body_611946 = body
  result = call_611945.call(nil, nil, nil, nil, body_611946)

var updateImagePermissions* = Call_UpdateImagePermissions_611932(
    name: "updateImagePermissions", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.UpdateImagePermissions",
    validator: validate_UpdateImagePermissions_611933, base: "/",
    url: url_UpdateImagePermissions_611934, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStack_611947 = ref object of OpenApiRestCall_610658
proc url_UpdateStack_611949(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateStack_611948(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the specified fields for the specified stack.
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
  var valid_611950 = header.getOrDefault("X-Amz-Target")
  valid_611950 = validateParameter(valid_611950, JString, required = true, default = newJString(
      "PhotonAdminProxyService.UpdateStack"))
  if valid_611950 != nil:
    section.add "X-Amz-Target", valid_611950
  var valid_611951 = header.getOrDefault("X-Amz-Signature")
  valid_611951 = validateParameter(valid_611951, JString, required = false,
                                 default = nil)
  if valid_611951 != nil:
    section.add "X-Amz-Signature", valid_611951
  var valid_611952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611952 = validateParameter(valid_611952, JString, required = false,
                                 default = nil)
  if valid_611952 != nil:
    section.add "X-Amz-Content-Sha256", valid_611952
  var valid_611953 = header.getOrDefault("X-Amz-Date")
  valid_611953 = validateParameter(valid_611953, JString, required = false,
                                 default = nil)
  if valid_611953 != nil:
    section.add "X-Amz-Date", valid_611953
  var valid_611954 = header.getOrDefault("X-Amz-Credential")
  valid_611954 = validateParameter(valid_611954, JString, required = false,
                                 default = nil)
  if valid_611954 != nil:
    section.add "X-Amz-Credential", valid_611954
  var valid_611955 = header.getOrDefault("X-Amz-Security-Token")
  valid_611955 = validateParameter(valid_611955, JString, required = false,
                                 default = nil)
  if valid_611955 != nil:
    section.add "X-Amz-Security-Token", valid_611955
  var valid_611956 = header.getOrDefault("X-Amz-Algorithm")
  valid_611956 = validateParameter(valid_611956, JString, required = false,
                                 default = nil)
  if valid_611956 != nil:
    section.add "X-Amz-Algorithm", valid_611956
  var valid_611957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611957 = validateParameter(valid_611957, JString, required = false,
                                 default = nil)
  if valid_611957 != nil:
    section.add "X-Amz-SignedHeaders", valid_611957
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611959: Call_UpdateStack_611947; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified fields for the specified stack.
  ## 
  let valid = call_611959.validator(path, query, header, formData, body)
  let scheme = call_611959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611959.url(scheme.get, call_611959.host, call_611959.base,
                         call_611959.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611959, url, valid)

proc call*(call_611960: Call_UpdateStack_611947; body: JsonNode): Recallable =
  ## updateStack
  ## Updates the specified fields for the specified stack.
  ##   body: JObject (required)
  var body_611961 = newJObject()
  if body != nil:
    body_611961 = body
  result = call_611960.call(nil, nil, nil, nil, body_611961)

var updateStack* = Call_UpdateStack_611947(name: "updateStack",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.UpdateStack",
                                        validator: validate_UpdateStack_611948,
                                        base: "/", url: url_UpdateStack_611949,
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
