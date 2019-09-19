
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AssociateFleet_600768 = ref object of OpenApiRestCall_600426
proc url_AssociateFleet_600770(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AssociateFleet_600769(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600882 = header.getOrDefault("X-Amz-Date")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Date", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-Security-Token")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Security-Token", valid_600883
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600897 = header.getOrDefault("X-Amz-Target")
  valid_600897 = validateParameter(valid_600897, JString, required = true, default = newJString(
      "PhotonAdminProxyService.AssociateFleet"))
  if valid_600897 != nil:
    section.add "X-Amz-Target", valid_600897
  var valid_600898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-Content-Sha256", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-Algorithm")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Algorithm", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Signature")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Signature", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-SignedHeaders", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Credential")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Credential", valid_600902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600926: Call_AssociateFleet_600768; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified fleet with the specified stack.
  ## 
  let valid = call_600926.validator(path, query, header, formData, body)
  let scheme = call_600926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600926.url(scheme.get, call_600926.host, call_600926.base,
                         call_600926.route, valid.getOrDefault("path"))
  result = hook(call_600926, url, valid)

proc call*(call_600997: Call_AssociateFleet_600768; body: JsonNode): Recallable =
  ## associateFleet
  ## Associates the specified fleet with the specified stack.
  ##   body: JObject (required)
  var body_600998 = newJObject()
  if body != nil:
    body_600998 = body
  result = call_600997.call(nil, nil, nil, nil, body_600998)

var associateFleet* = Call_AssociateFleet_600768(name: "associateFleet",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.AssociateFleet",
    validator: validate_AssociateFleet_600769, base: "/", url: url_AssociateFleet_600770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchAssociateUserStack_601037 = ref object of OpenApiRestCall_600426
proc url_BatchAssociateUserStack_601039(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchAssociateUserStack_601038(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601040 = header.getOrDefault("X-Amz-Date")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Date", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Security-Token")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Security-Token", valid_601041
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601042 = header.getOrDefault("X-Amz-Target")
  valid_601042 = validateParameter(valid_601042, JString, required = true, default = newJString(
      "PhotonAdminProxyService.BatchAssociateUserStack"))
  if valid_601042 != nil:
    section.add "X-Amz-Target", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Content-Sha256", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Algorithm")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Algorithm", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Signature")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Signature", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-SignedHeaders", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Credential")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Credential", valid_601047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601049: Call_BatchAssociateUserStack_601037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified users with the specified stacks. Users in a user pool cannot be assigned to stacks with fleets that are joined to an Active Directory domain.
  ## 
  let valid = call_601049.validator(path, query, header, formData, body)
  let scheme = call_601049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601049.url(scheme.get, call_601049.host, call_601049.base,
                         call_601049.route, valid.getOrDefault("path"))
  result = hook(call_601049, url, valid)

proc call*(call_601050: Call_BatchAssociateUserStack_601037; body: JsonNode): Recallable =
  ## batchAssociateUserStack
  ## Associates the specified users with the specified stacks. Users in a user pool cannot be assigned to stacks with fleets that are joined to an Active Directory domain.
  ##   body: JObject (required)
  var body_601051 = newJObject()
  if body != nil:
    body_601051 = body
  result = call_601050.call(nil, nil, nil, nil, body_601051)

var batchAssociateUserStack* = Call_BatchAssociateUserStack_601037(
    name: "batchAssociateUserStack", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.BatchAssociateUserStack",
    validator: validate_BatchAssociateUserStack_601038, base: "/",
    url: url_BatchAssociateUserStack_601039, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDisassociateUserStack_601052 = ref object of OpenApiRestCall_600426
proc url_BatchDisassociateUserStack_601054(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchDisassociateUserStack_601053(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601055 = header.getOrDefault("X-Amz-Date")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Date", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Security-Token")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Security-Token", valid_601056
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601057 = header.getOrDefault("X-Amz-Target")
  valid_601057 = validateParameter(valid_601057, JString, required = true, default = newJString(
      "PhotonAdminProxyService.BatchDisassociateUserStack"))
  if valid_601057 != nil:
    section.add "X-Amz-Target", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Content-Sha256", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Algorithm")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Algorithm", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Signature")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Signature", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-SignedHeaders", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Credential")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Credential", valid_601062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601064: Call_BatchDisassociateUserStack_601052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified users from the specified stacks.
  ## 
  let valid = call_601064.validator(path, query, header, formData, body)
  let scheme = call_601064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601064.url(scheme.get, call_601064.host, call_601064.base,
                         call_601064.route, valid.getOrDefault("path"))
  result = hook(call_601064, url, valid)

proc call*(call_601065: Call_BatchDisassociateUserStack_601052; body: JsonNode): Recallable =
  ## batchDisassociateUserStack
  ## Disassociates the specified users from the specified stacks.
  ##   body: JObject (required)
  var body_601066 = newJObject()
  if body != nil:
    body_601066 = body
  result = call_601065.call(nil, nil, nil, nil, body_601066)

var batchDisassociateUserStack* = Call_BatchDisassociateUserStack_601052(
    name: "batchDisassociateUserStack", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.BatchDisassociateUserStack",
    validator: validate_BatchDisassociateUserStack_601053, base: "/",
    url: url_BatchDisassociateUserStack_601054,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyImage_601067 = ref object of OpenApiRestCall_600426
proc url_CopyImage_601069(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CopyImage_601068(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601070 = header.getOrDefault("X-Amz-Date")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Date", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Security-Token")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Security-Token", valid_601071
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601072 = header.getOrDefault("X-Amz-Target")
  valid_601072 = validateParameter(valid_601072, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CopyImage"))
  if valid_601072 != nil:
    section.add "X-Amz-Target", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Content-Sha256", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Algorithm")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Algorithm", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Signature")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Signature", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-SignedHeaders", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Credential")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Credential", valid_601077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601079: Call_CopyImage_601067; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the image within the same region or to a new region within the same AWS account. Note that any tags you added to the image will not be copied.
  ## 
  let valid = call_601079.validator(path, query, header, formData, body)
  let scheme = call_601079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601079.url(scheme.get, call_601079.host, call_601079.base,
                         call_601079.route, valid.getOrDefault("path"))
  result = hook(call_601079, url, valid)

proc call*(call_601080: Call_CopyImage_601067; body: JsonNode): Recallable =
  ## copyImage
  ## Copies the image within the same region or to a new region within the same AWS account. Note that any tags you added to the image will not be copied.
  ##   body: JObject (required)
  var body_601081 = newJObject()
  if body != nil:
    body_601081 = body
  result = call_601080.call(nil, nil, nil, nil, body_601081)

var copyImage* = Call_CopyImage_601067(name: "copyImage", meth: HttpMethod.HttpPost,
                                    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.CopyImage",
                                    validator: validate_CopyImage_601068,
                                    base: "/", url: url_CopyImage_601069,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectoryConfig_601082 = ref object of OpenApiRestCall_600426
proc url_CreateDirectoryConfig_601084(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDirectoryConfig_601083(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601085 = header.getOrDefault("X-Amz-Date")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Date", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Security-Token")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Security-Token", valid_601086
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601087 = header.getOrDefault("X-Amz-Target")
  valid_601087 = validateParameter(valid_601087, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CreateDirectoryConfig"))
  if valid_601087 != nil:
    section.add "X-Amz-Target", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Content-Sha256", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Algorithm")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Algorithm", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Signature")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Signature", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-SignedHeaders", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Credential")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Credential", valid_601092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601094: Call_CreateDirectoryConfig_601082; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Directory Config object in AppStream 2.0. This object includes the configuration information required to join fleets and image builders to Microsoft Active Directory domains.
  ## 
  let valid = call_601094.validator(path, query, header, formData, body)
  let scheme = call_601094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601094.url(scheme.get, call_601094.host, call_601094.base,
                         call_601094.route, valid.getOrDefault("path"))
  result = hook(call_601094, url, valid)

proc call*(call_601095: Call_CreateDirectoryConfig_601082; body: JsonNode): Recallable =
  ## createDirectoryConfig
  ## Creates a Directory Config object in AppStream 2.0. This object includes the configuration information required to join fleets and image builders to Microsoft Active Directory domains.
  ##   body: JObject (required)
  var body_601096 = newJObject()
  if body != nil:
    body_601096 = body
  result = call_601095.call(nil, nil, nil, nil, body_601096)

var createDirectoryConfig* = Call_CreateDirectoryConfig_601082(
    name: "createDirectoryConfig", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.CreateDirectoryConfig",
    validator: validate_CreateDirectoryConfig_601083, base: "/",
    url: url_CreateDirectoryConfig_601084, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFleet_601097 = ref object of OpenApiRestCall_600426
proc url_CreateFleet_601099(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateFleet_601098(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601100 = header.getOrDefault("X-Amz-Date")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Date", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Security-Token")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Security-Token", valid_601101
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601102 = header.getOrDefault("X-Amz-Target")
  valid_601102 = validateParameter(valid_601102, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CreateFleet"))
  if valid_601102 != nil:
    section.add "X-Amz-Target", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Content-Sha256", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Algorithm")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Algorithm", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Signature")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Signature", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-SignedHeaders", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Credential")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Credential", valid_601107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601109: Call_CreateFleet_601097; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a fleet. A fleet consists of streaming instances that run a specified image.
  ## 
  let valid = call_601109.validator(path, query, header, formData, body)
  let scheme = call_601109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601109.url(scheme.get, call_601109.host, call_601109.base,
                         call_601109.route, valid.getOrDefault("path"))
  result = hook(call_601109, url, valid)

proc call*(call_601110: Call_CreateFleet_601097; body: JsonNode): Recallable =
  ## createFleet
  ## Creates a fleet. A fleet consists of streaming instances that run a specified image.
  ##   body: JObject (required)
  var body_601111 = newJObject()
  if body != nil:
    body_601111 = body
  result = call_601110.call(nil, nil, nil, nil, body_601111)

var createFleet* = Call_CreateFleet_601097(name: "createFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.CreateFleet",
                                        validator: validate_CreateFleet_601098,
                                        base: "/", url: url_CreateFleet_601099,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImageBuilder_601112 = ref object of OpenApiRestCall_600426
proc url_CreateImageBuilder_601114(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateImageBuilder_601113(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601115 = header.getOrDefault("X-Amz-Date")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Date", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Security-Token")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Security-Token", valid_601116
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601117 = header.getOrDefault("X-Amz-Target")
  valid_601117 = validateParameter(valid_601117, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CreateImageBuilder"))
  if valid_601117 != nil:
    section.add "X-Amz-Target", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Content-Sha256", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Algorithm")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Algorithm", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Signature")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Signature", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-SignedHeaders", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Credential")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Credential", valid_601122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601124: Call_CreateImageBuilder_601112; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an image builder. An image builder is a virtual machine that is used to create an image.</p> <p>The initial state of the builder is <code>PENDING</code>. When it is ready, the state is <code>RUNNING</code>.</p>
  ## 
  let valid = call_601124.validator(path, query, header, formData, body)
  let scheme = call_601124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601124.url(scheme.get, call_601124.host, call_601124.base,
                         call_601124.route, valid.getOrDefault("path"))
  result = hook(call_601124, url, valid)

proc call*(call_601125: Call_CreateImageBuilder_601112; body: JsonNode): Recallable =
  ## createImageBuilder
  ## <p>Creates an image builder. An image builder is a virtual machine that is used to create an image.</p> <p>The initial state of the builder is <code>PENDING</code>. When it is ready, the state is <code>RUNNING</code>.</p>
  ##   body: JObject (required)
  var body_601126 = newJObject()
  if body != nil:
    body_601126 = body
  result = call_601125.call(nil, nil, nil, nil, body_601126)

var createImageBuilder* = Call_CreateImageBuilder_601112(
    name: "createImageBuilder", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.CreateImageBuilder",
    validator: validate_CreateImageBuilder_601113, base: "/",
    url: url_CreateImageBuilder_601114, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImageBuilderStreamingURL_601127 = ref object of OpenApiRestCall_600426
proc url_CreateImageBuilderStreamingURL_601129(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateImageBuilderStreamingURL_601128(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601130 = header.getOrDefault("X-Amz-Date")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Date", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Security-Token")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Security-Token", valid_601131
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601132 = header.getOrDefault("X-Amz-Target")
  valid_601132 = validateParameter(valid_601132, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CreateImageBuilderStreamingURL"))
  if valid_601132 != nil:
    section.add "X-Amz-Target", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Content-Sha256", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Algorithm")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Algorithm", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Signature")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Signature", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-SignedHeaders", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Credential")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Credential", valid_601137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601139: Call_CreateImageBuilderStreamingURL_601127; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a URL to start an image builder streaming session.
  ## 
  let valid = call_601139.validator(path, query, header, formData, body)
  let scheme = call_601139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601139.url(scheme.get, call_601139.host, call_601139.base,
                         call_601139.route, valid.getOrDefault("path"))
  result = hook(call_601139, url, valid)

proc call*(call_601140: Call_CreateImageBuilderStreamingURL_601127; body: JsonNode): Recallable =
  ## createImageBuilderStreamingURL
  ## Creates a URL to start an image builder streaming session.
  ##   body: JObject (required)
  var body_601141 = newJObject()
  if body != nil:
    body_601141 = body
  result = call_601140.call(nil, nil, nil, nil, body_601141)

var createImageBuilderStreamingURL* = Call_CreateImageBuilderStreamingURL_601127(
    name: "createImageBuilderStreamingURL", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.CreateImageBuilderStreamingURL",
    validator: validate_CreateImageBuilderStreamingURL_601128, base: "/",
    url: url_CreateImageBuilderStreamingURL_601129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStack_601142 = ref object of OpenApiRestCall_600426
proc url_CreateStack_601144(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateStack_601143(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601145 = header.getOrDefault("X-Amz-Date")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Date", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-Security-Token")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Security-Token", valid_601146
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601147 = header.getOrDefault("X-Amz-Target")
  valid_601147 = validateParameter(valid_601147, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CreateStack"))
  if valid_601147 != nil:
    section.add "X-Amz-Target", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Content-Sha256", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Algorithm")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Algorithm", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Signature")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Signature", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-SignedHeaders", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Credential")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Credential", valid_601152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601154: Call_CreateStack_601142; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a stack to start streaming applications to users. A stack consists of an associated fleet, user access policies, and storage configurations. 
  ## 
  let valid = call_601154.validator(path, query, header, formData, body)
  let scheme = call_601154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601154.url(scheme.get, call_601154.host, call_601154.base,
                         call_601154.route, valid.getOrDefault("path"))
  result = hook(call_601154, url, valid)

proc call*(call_601155: Call_CreateStack_601142; body: JsonNode): Recallable =
  ## createStack
  ## Creates a stack to start streaming applications to users. A stack consists of an associated fleet, user access policies, and storage configurations. 
  ##   body: JObject (required)
  var body_601156 = newJObject()
  if body != nil:
    body_601156 = body
  result = call_601155.call(nil, nil, nil, nil, body_601156)

var createStack* = Call_CreateStack_601142(name: "createStack",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.CreateStack",
                                        validator: validate_CreateStack_601143,
                                        base: "/", url: url_CreateStack_601144,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingURL_601157 = ref object of OpenApiRestCall_600426
proc url_CreateStreamingURL_601159(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateStreamingURL_601158(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601160 = header.getOrDefault("X-Amz-Date")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-Date", valid_601160
  var valid_601161 = header.getOrDefault("X-Amz-Security-Token")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Security-Token", valid_601161
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601162 = header.getOrDefault("X-Amz-Target")
  valid_601162 = validateParameter(valid_601162, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CreateStreamingURL"))
  if valid_601162 != nil:
    section.add "X-Amz-Target", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Content-Sha256", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-Algorithm")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Algorithm", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Signature")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Signature", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-SignedHeaders", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Credential")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Credential", valid_601167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601169: Call_CreateStreamingURL_601157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a temporary URL to start an AppStream 2.0 streaming session for the specified user. A streaming URL enables application streaming to be tested without user setup. 
  ## 
  let valid = call_601169.validator(path, query, header, formData, body)
  let scheme = call_601169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601169.url(scheme.get, call_601169.host, call_601169.base,
                         call_601169.route, valid.getOrDefault("path"))
  result = hook(call_601169, url, valid)

proc call*(call_601170: Call_CreateStreamingURL_601157; body: JsonNode): Recallable =
  ## createStreamingURL
  ## Creates a temporary URL to start an AppStream 2.0 streaming session for the specified user. A streaming URL enables application streaming to be tested without user setup. 
  ##   body: JObject (required)
  var body_601171 = newJObject()
  if body != nil:
    body_601171 = body
  result = call_601170.call(nil, nil, nil, nil, body_601171)

var createStreamingURL* = Call_CreateStreamingURL_601157(
    name: "createStreamingURL", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.CreateStreamingURL",
    validator: validate_CreateStreamingURL_601158, base: "/",
    url: url_CreateStreamingURL_601159, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsageReportSubscription_601172 = ref object of OpenApiRestCall_600426
proc url_CreateUsageReportSubscription_601174(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateUsageReportSubscription_601173(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601175 = header.getOrDefault("X-Amz-Date")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "X-Amz-Date", valid_601175
  var valid_601176 = header.getOrDefault("X-Amz-Security-Token")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "X-Amz-Security-Token", valid_601176
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601177 = header.getOrDefault("X-Amz-Target")
  valid_601177 = validateParameter(valid_601177, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CreateUsageReportSubscription"))
  if valid_601177 != nil:
    section.add "X-Amz-Target", valid_601177
  var valid_601178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "X-Amz-Content-Sha256", valid_601178
  var valid_601179 = header.getOrDefault("X-Amz-Algorithm")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Algorithm", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-Signature")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Signature", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-SignedHeaders", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Credential")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Credential", valid_601182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601184: Call_CreateUsageReportSubscription_601172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a usage report subscription. Usage reports are generated daily.
  ## 
  let valid = call_601184.validator(path, query, header, formData, body)
  let scheme = call_601184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601184.url(scheme.get, call_601184.host, call_601184.base,
                         call_601184.route, valid.getOrDefault("path"))
  result = hook(call_601184, url, valid)

proc call*(call_601185: Call_CreateUsageReportSubscription_601172; body: JsonNode): Recallable =
  ## createUsageReportSubscription
  ## Creates a usage report subscription. Usage reports are generated daily.
  ##   body: JObject (required)
  var body_601186 = newJObject()
  if body != nil:
    body_601186 = body
  result = call_601185.call(nil, nil, nil, nil, body_601186)

var createUsageReportSubscription* = Call_CreateUsageReportSubscription_601172(
    name: "createUsageReportSubscription", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.CreateUsageReportSubscription",
    validator: validate_CreateUsageReportSubscription_601173, base: "/",
    url: url_CreateUsageReportSubscription_601174,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_601187 = ref object of OpenApiRestCall_600426
proc url_CreateUser_601189(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateUser_601188(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601190 = header.getOrDefault("X-Amz-Date")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-Date", valid_601190
  var valid_601191 = header.getOrDefault("X-Amz-Security-Token")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-Security-Token", valid_601191
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601192 = header.getOrDefault("X-Amz-Target")
  valid_601192 = validateParameter(valid_601192, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CreateUser"))
  if valid_601192 != nil:
    section.add "X-Amz-Target", valid_601192
  var valid_601193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Content-Sha256", valid_601193
  var valid_601194 = header.getOrDefault("X-Amz-Algorithm")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Algorithm", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-Signature")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Signature", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-SignedHeaders", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Credential")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Credential", valid_601197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601199: Call_CreateUser_601187; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new user in the user pool.
  ## 
  let valid = call_601199.validator(path, query, header, formData, body)
  let scheme = call_601199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601199.url(scheme.get, call_601199.host, call_601199.base,
                         call_601199.route, valid.getOrDefault("path"))
  result = hook(call_601199, url, valid)

proc call*(call_601200: Call_CreateUser_601187; body: JsonNode): Recallable =
  ## createUser
  ## Creates a new user in the user pool.
  ##   body: JObject (required)
  var body_601201 = newJObject()
  if body != nil:
    body_601201 = body
  result = call_601200.call(nil, nil, nil, nil, body_601201)

var createUser* = Call_CreateUser_601187(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.CreateUser",
                                      validator: validate_CreateUser_601188,
                                      base: "/", url: url_CreateUser_601189,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectoryConfig_601202 = ref object of OpenApiRestCall_600426
proc url_DeleteDirectoryConfig_601204(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteDirectoryConfig_601203(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601205 = header.getOrDefault("X-Amz-Date")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-Date", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-Security-Token")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Security-Token", valid_601206
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601207 = header.getOrDefault("X-Amz-Target")
  valid_601207 = validateParameter(valid_601207, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteDirectoryConfig"))
  if valid_601207 != nil:
    section.add "X-Amz-Target", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-Content-Sha256", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-Algorithm")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Algorithm", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Signature")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Signature", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-SignedHeaders", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Credential")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Credential", valid_601212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601214: Call_DeleteDirectoryConfig_601202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Directory Config object from AppStream 2.0. This object includes the information required to join streaming instances to an Active Directory domain.
  ## 
  let valid = call_601214.validator(path, query, header, formData, body)
  let scheme = call_601214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601214.url(scheme.get, call_601214.host, call_601214.base,
                         call_601214.route, valid.getOrDefault("path"))
  result = hook(call_601214, url, valid)

proc call*(call_601215: Call_DeleteDirectoryConfig_601202; body: JsonNode): Recallable =
  ## deleteDirectoryConfig
  ## Deletes the specified Directory Config object from AppStream 2.0. This object includes the information required to join streaming instances to an Active Directory domain.
  ##   body: JObject (required)
  var body_601216 = newJObject()
  if body != nil:
    body_601216 = body
  result = call_601215.call(nil, nil, nil, nil, body_601216)

var deleteDirectoryConfig* = Call_DeleteDirectoryConfig_601202(
    name: "deleteDirectoryConfig", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteDirectoryConfig",
    validator: validate_DeleteDirectoryConfig_601203, base: "/",
    url: url_DeleteDirectoryConfig_601204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFleet_601217 = ref object of OpenApiRestCall_600426
proc url_DeleteFleet_601219(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteFleet_601218(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601220 = header.getOrDefault("X-Amz-Date")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Date", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-Security-Token")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-Security-Token", valid_601221
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601222 = header.getOrDefault("X-Amz-Target")
  valid_601222 = validateParameter(valid_601222, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteFleet"))
  if valid_601222 != nil:
    section.add "X-Amz-Target", valid_601222
  var valid_601223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "X-Amz-Content-Sha256", valid_601223
  var valid_601224 = header.getOrDefault("X-Amz-Algorithm")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-Algorithm", valid_601224
  var valid_601225 = header.getOrDefault("X-Amz-Signature")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "X-Amz-Signature", valid_601225
  var valid_601226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-SignedHeaders", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-Credential")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Credential", valid_601227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601229: Call_DeleteFleet_601217; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified fleet.
  ## 
  let valid = call_601229.validator(path, query, header, formData, body)
  let scheme = call_601229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601229.url(scheme.get, call_601229.host, call_601229.base,
                         call_601229.route, valid.getOrDefault("path"))
  result = hook(call_601229, url, valid)

proc call*(call_601230: Call_DeleteFleet_601217; body: JsonNode): Recallable =
  ## deleteFleet
  ## Deletes the specified fleet.
  ##   body: JObject (required)
  var body_601231 = newJObject()
  if body != nil:
    body_601231 = body
  result = call_601230.call(nil, nil, nil, nil, body_601231)

var deleteFleet* = Call_DeleteFleet_601217(name: "deleteFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteFleet",
                                        validator: validate_DeleteFleet_601218,
                                        base: "/", url: url_DeleteFleet_601219,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImage_601232 = ref object of OpenApiRestCall_600426
proc url_DeleteImage_601234(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteImage_601233(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601235 = header.getOrDefault("X-Amz-Date")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Date", valid_601235
  var valid_601236 = header.getOrDefault("X-Amz-Security-Token")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-Security-Token", valid_601236
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601237 = header.getOrDefault("X-Amz-Target")
  valid_601237 = validateParameter(valid_601237, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteImage"))
  if valid_601237 != nil:
    section.add "X-Amz-Target", valid_601237
  var valid_601238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "X-Amz-Content-Sha256", valid_601238
  var valid_601239 = header.getOrDefault("X-Amz-Algorithm")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "X-Amz-Algorithm", valid_601239
  var valid_601240 = header.getOrDefault("X-Amz-Signature")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "X-Amz-Signature", valid_601240
  var valid_601241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-SignedHeaders", valid_601241
  var valid_601242 = header.getOrDefault("X-Amz-Credential")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Credential", valid_601242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601244: Call_DeleteImage_601232; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified image. You cannot delete an image when it is in use. After you delete an image, you cannot provision new capacity using the image.
  ## 
  let valid = call_601244.validator(path, query, header, formData, body)
  let scheme = call_601244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601244.url(scheme.get, call_601244.host, call_601244.base,
                         call_601244.route, valid.getOrDefault("path"))
  result = hook(call_601244, url, valid)

proc call*(call_601245: Call_DeleteImage_601232; body: JsonNode): Recallable =
  ## deleteImage
  ## Deletes the specified image. You cannot delete an image when it is in use. After you delete an image, you cannot provision new capacity using the image.
  ##   body: JObject (required)
  var body_601246 = newJObject()
  if body != nil:
    body_601246 = body
  result = call_601245.call(nil, nil, nil, nil, body_601246)

var deleteImage* = Call_DeleteImage_601232(name: "deleteImage",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteImage",
                                        validator: validate_DeleteImage_601233,
                                        base: "/", url: url_DeleteImage_601234,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImageBuilder_601247 = ref object of OpenApiRestCall_600426
proc url_DeleteImageBuilder_601249(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteImageBuilder_601248(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601250 = header.getOrDefault("X-Amz-Date")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-Date", valid_601250
  var valid_601251 = header.getOrDefault("X-Amz-Security-Token")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-Security-Token", valid_601251
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601252 = header.getOrDefault("X-Amz-Target")
  valid_601252 = validateParameter(valid_601252, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteImageBuilder"))
  if valid_601252 != nil:
    section.add "X-Amz-Target", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-Content-Sha256", valid_601253
  var valid_601254 = header.getOrDefault("X-Amz-Algorithm")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Algorithm", valid_601254
  var valid_601255 = header.getOrDefault("X-Amz-Signature")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-Signature", valid_601255
  var valid_601256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-SignedHeaders", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-Credential")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Credential", valid_601257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601259: Call_DeleteImageBuilder_601247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified image builder and releases the capacity.
  ## 
  let valid = call_601259.validator(path, query, header, formData, body)
  let scheme = call_601259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601259.url(scheme.get, call_601259.host, call_601259.base,
                         call_601259.route, valid.getOrDefault("path"))
  result = hook(call_601259, url, valid)

proc call*(call_601260: Call_DeleteImageBuilder_601247; body: JsonNode): Recallable =
  ## deleteImageBuilder
  ## Deletes the specified image builder and releases the capacity.
  ##   body: JObject (required)
  var body_601261 = newJObject()
  if body != nil:
    body_601261 = body
  result = call_601260.call(nil, nil, nil, nil, body_601261)

var deleteImageBuilder* = Call_DeleteImageBuilder_601247(
    name: "deleteImageBuilder", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteImageBuilder",
    validator: validate_DeleteImageBuilder_601248, base: "/",
    url: url_DeleteImageBuilder_601249, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImagePermissions_601262 = ref object of OpenApiRestCall_600426
proc url_DeleteImagePermissions_601264(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteImagePermissions_601263(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601265 = header.getOrDefault("X-Amz-Date")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Date", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-Security-Token")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Security-Token", valid_601266
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601267 = header.getOrDefault("X-Amz-Target")
  valid_601267 = validateParameter(valid_601267, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteImagePermissions"))
  if valid_601267 != nil:
    section.add "X-Amz-Target", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-Content-Sha256", valid_601268
  var valid_601269 = header.getOrDefault("X-Amz-Algorithm")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-Algorithm", valid_601269
  var valid_601270 = header.getOrDefault("X-Amz-Signature")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Signature", valid_601270
  var valid_601271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-SignedHeaders", valid_601271
  var valid_601272 = header.getOrDefault("X-Amz-Credential")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-Credential", valid_601272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601274: Call_DeleteImagePermissions_601262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes permissions for the specified private image. After you delete permissions for an image, AWS accounts to which you previously granted these permissions can no longer use the image.
  ## 
  let valid = call_601274.validator(path, query, header, formData, body)
  let scheme = call_601274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601274.url(scheme.get, call_601274.host, call_601274.base,
                         call_601274.route, valid.getOrDefault("path"))
  result = hook(call_601274, url, valid)

proc call*(call_601275: Call_DeleteImagePermissions_601262; body: JsonNode): Recallable =
  ## deleteImagePermissions
  ## Deletes permissions for the specified private image. After you delete permissions for an image, AWS accounts to which you previously granted these permissions can no longer use the image.
  ##   body: JObject (required)
  var body_601276 = newJObject()
  if body != nil:
    body_601276 = body
  result = call_601275.call(nil, nil, nil, nil, body_601276)

var deleteImagePermissions* = Call_DeleteImagePermissions_601262(
    name: "deleteImagePermissions", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteImagePermissions",
    validator: validate_DeleteImagePermissions_601263, base: "/",
    url: url_DeleteImagePermissions_601264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStack_601277 = ref object of OpenApiRestCall_600426
proc url_DeleteStack_601279(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteStack_601278(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601280 = header.getOrDefault("X-Amz-Date")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-Date", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-Security-Token")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-Security-Token", valid_601281
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601282 = header.getOrDefault("X-Amz-Target")
  valid_601282 = validateParameter(valid_601282, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteStack"))
  if valid_601282 != nil:
    section.add "X-Amz-Target", valid_601282
  var valid_601283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "X-Amz-Content-Sha256", valid_601283
  var valid_601284 = header.getOrDefault("X-Amz-Algorithm")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-Algorithm", valid_601284
  var valid_601285 = header.getOrDefault("X-Amz-Signature")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "X-Amz-Signature", valid_601285
  var valid_601286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "X-Amz-SignedHeaders", valid_601286
  var valid_601287 = header.getOrDefault("X-Amz-Credential")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Credential", valid_601287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601289: Call_DeleteStack_601277; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified stack. After the stack is deleted, the application streaming environment provided by the stack is no longer available to users. Also, any reservations made for application streaming sessions for the stack are released.
  ## 
  let valid = call_601289.validator(path, query, header, formData, body)
  let scheme = call_601289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601289.url(scheme.get, call_601289.host, call_601289.base,
                         call_601289.route, valid.getOrDefault("path"))
  result = hook(call_601289, url, valid)

proc call*(call_601290: Call_DeleteStack_601277; body: JsonNode): Recallable =
  ## deleteStack
  ## Deletes the specified stack. After the stack is deleted, the application streaming environment provided by the stack is no longer available to users. Also, any reservations made for application streaming sessions for the stack are released.
  ##   body: JObject (required)
  var body_601291 = newJObject()
  if body != nil:
    body_601291 = body
  result = call_601290.call(nil, nil, nil, nil, body_601291)

var deleteStack* = Call_DeleteStack_601277(name: "deleteStack",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteStack",
                                        validator: validate_DeleteStack_601278,
                                        base: "/", url: url_DeleteStack_601279,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsageReportSubscription_601292 = ref object of OpenApiRestCall_600426
proc url_DeleteUsageReportSubscription_601294(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteUsageReportSubscription_601293(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601295 = header.getOrDefault("X-Amz-Date")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-Date", valid_601295
  var valid_601296 = header.getOrDefault("X-Amz-Security-Token")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-Security-Token", valid_601296
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601297 = header.getOrDefault("X-Amz-Target")
  valid_601297 = validateParameter(valid_601297, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteUsageReportSubscription"))
  if valid_601297 != nil:
    section.add "X-Amz-Target", valid_601297
  var valid_601298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "X-Amz-Content-Sha256", valid_601298
  var valid_601299 = header.getOrDefault("X-Amz-Algorithm")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "X-Amz-Algorithm", valid_601299
  var valid_601300 = header.getOrDefault("X-Amz-Signature")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "X-Amz-Signature", valid_601300
  var valid_601301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "X-Amz-SignedHeaders", valid_601301
  var valid_601302 = header.getOrDefault("X-Amz-Credential")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "X-Amz-Credential", valid_601302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601304: Call_DeleteUsageReportSubscription_601292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables usage report generation.
  ## 
  let valid = call_601304.validator(path, query, header, formData, body)
  let scheme = call_601304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601304.url(scheme.get, call_601304.host, call_601304.base,
                         call_601304.route, valid.getOrDefault("path"))
  result = hook(call_601304, url, valid)

proc call*(call_601305: Call_DeleteUsageReportSubscription_601292; body: JsonNode): Recallable =
  ## deleteUsageReportSubscription
  ## Disables usage report generation.
  ##   body: JObject (required)
  var body_601306 = newJObject()
  if body != nil:
    body_601306 = body
  result = call_601305.call(nil, nil, nil, nil, body_601306)

var deleteUsageReportSubscription* = Call_DeleteUsageReportSubscription_601292(
    name: "deleteUsageReportSubscription", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteUsageReportSubscription",
    validator: validate_DeleteUsageReportSubscription_601293, base: "/",
    url: url_DeleteUsageReportSubscription_601294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_601307 = ref object of OpenApiRestCall_600426
proc url_DeleteUser_601309(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteUser_601308(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601310 = header.getOrDefault("X-Amz-Date")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-Date", valid_601310
  var valid_601311 = header.getOrDefault("X-Amz-Security-Token")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "X-Amz-Security-Token", valid_601311
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601312 = header.getOrDefault("X-Amz-Target")
  valid_601312 = validateParameter(valid_601312, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteUser"))
  if valid_601312 != nil:
    section.add "X-Amz-Target", valid_601312
  var valid_601313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "X-Amz-Content-Sha256", valid_601313
  var valid_601314 = header.getOrDefault("X-Amz-Algorithm")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "X-Amz-Algorithm", valid_601314
  var valid_601315 = header.getOrDefault("X-Amz-Signature")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-Signature", valid_601315
  var valid_601316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "X-Amz-SignedHeaders", valid_601316
  var valid_601317 = header.getOrDefault("X-Amz-Credential")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "X-Amz-Credential", valid_601317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601319: Call_DeleteUser_601307; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a user from the user pool.
  ## 
  let valid = call_601319.validator(path, query, header, formData, body)
  let scheme = call_601319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601319.url(scheme.get, call_601319.host, call_601319.base,
                         call_601319.route, valid.getOrDefault("path"))
  result = hook(call_601319, url, valid)

proc call*(call_601320: Call_DeleteUser_601307; body: JsonNode): Recallable =
  ## deleteUser
  ## Deletes a user from the user pool.
  ##   body: JObject (required)
  var body_601321 = newJObject()
  if body != nil:
    body_601321 = body
  result = call_601320.call(nil, nil, nil, nil, body_601321)

var deleteUser* = Call_DeleteUser_601307(name: "deleteUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteUser",
                                      validator: validate_DeleteUser_601308,
                                      base: "/", url: url_DeleteUser_601309,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDirectoryConfigs_601322 = ref object of OpenApiRestCall_600426
proc url_DescribeDirectoryConfigs_601324(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeDirectoryConfigs_601323(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601325 = header.getOrDefault("X-Amz-Date")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "X-Amz-Date", valid_601325
  var valid_601326 = header.getOrDefault("X-Amz-Security-Token")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-Security-Token", valid_601326
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601327 = header.getOrDefault("X-Amz-Target")
  valid_601327 = validateParameter(valid_601327, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeDirectoryConfigs"))
  if valid_601327 != nil:
    section.add "X-Amz-Target", valid_601327
  var valid_601328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601328 = validateParameter(valid_601328, JString, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "X-Amz-Content-Sha256", valid_601328
  var valid_601329 = header.getOrDefault("X-Amz-Algorithm")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "X-Amz-Algorithm", valid_601329
  var valid_601330 = header.getOrDefault("X-Amz-Signature")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "X-Amz-Signature", valid_601330
  var valid_601331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-SignedHeaders", valid_601331
  var valid_601332 = header.getOrDefault("X-Amz-Credential")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-Credential", valid_601332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601334: Call_DescribeDirectoryConfigs_601322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list that describes one or more specified Directory Config objects for AppStream 2.0, if the names for these objects are provided. Otherwise, all Directory Config objects in the account are described. These objects include the configuration information required to join fleets and image builders to Microsoft Active Directory domains. </p> <p>Although the response syntax in this topic includes the account password, this password is not returned in the actual response.</p>
  ## 
  let valid = call_601334.validator(path, query, header, formData, body)
  let scheme = call_601334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601334.url(scheme.get, call_601334.host, call_601334.base,
                         call_601334.route, valid.getOrDefault("path"))
  result = hook(call_601334, url, valid)

proc call*(call_601335: Call_DescribeDirectoryConfigs_601322; body: JsonNode): Recallable =
  ## describeDirectoryConfigs
  ## <p>Retrieves a list that describes one or more specified Directory Config objects for AppStream 2.0, if the names for these objects are provided. Otherwise, all Directory Config objects in the account are described. These objects include the configuration information required to join fleets and image builders to Microsoft Active Directory domains. </p> <p>Although the response syntax in this topic includes the account password, this password is not returned in the actual response.</p>
  ##   body: JObject (required)
  var body_601336 = newJObject()
  if body != nil:
    body_601336 = body
  result = call_601335.call(nil, nil, nil, nil, body_601336)

var describeDirectoryConfigs* = Call_DescribeDirectoryConfigs_601322(
    name: "describeDirectoryConfigs", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeDirectoryConfigs",
    validator: validate_DescribeDirectoryConfigs_601323, base: "/",
    url: url_DescribeDirectoryConfigs_601324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFleets_601337 = ref object of OpenApiRestCall_600426
proc url_DescribeFleets_601339(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeFleets_601338(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601340 = header.getOrDefault("X-Amz-Date")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "X-Amz-Date", valid_601340
  var valid_601341 = header.getOrDefault("X-Amz-Security-Token")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-Security-Token", valid_601341
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601342 = header.getOrDefault("X-Amz-Target")
  valid_601342 = validateParameter(valid_601342, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeFleets"))
  if valid_601342 != nil:
    section.add "X-Amz-Target", valid_601342
  var valid_601343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-Content-Sha256", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-Algorithm")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Algorithm", valid_601344
  var valid_601345 = header.getOrDefault("X-Amz-Signature")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-Signature", valid_601345
  var valid_601346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-SignedHeaders", valid_601346
  var valid_601347 = header.getOrDefault("X-Amz-Credential")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-Credential", valid_601347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601349: Call_DescribeFleets_601337; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified fleets, if the fleet names are provided. Otherwise, all fleets in the account are described.
  ## 
  let valid = call_601349.validator(path, query, header, formData, body)
  let scheme = call_601349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601349.url(scheme.get, call_601349.host, call_601349.base,
                         call_601349.route, valid.getOrDefault("path"))
  result = hook(call_601349, url, valid)

proc call*(call_601350: Call_DescribeFleets_601337; body: JsonNode): Recallable =
  ## describeFleets
  ## Retrieves a list that describes one or more specified fleets, if the fleet names are provided. Otherwise, all fleets in the account are described.
  ##   body: JObject (required)
  var body_601351 = newJObject()
  if body != nil:
    body_601351 = body
  result = call_601350.call(nil, nil, nil, nil, body_601351)

var describeFleets* = Call_DescribeFleets_601337(name: "describeFleets",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeFleets",
    validator: validate_DescribeFleets_601338, base: "/", url: url_DescribeFleets_601339,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeImageBuilders_601352 = ref object of OpenApiRestCall_600426
proc url_DescribeImageBuilders_601354(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeImageBuilders_601353(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601355 = header.getOrDefault("X-Amz-Date")
  valid_601355 = validateParameter(valid_601355, JString, required = false,
                                 default = nil)
  if valid_601355 != nil:
    section.add "X-Amz-Date", valid_601355
  var valid_601356 = header.getOrDefault("X-Amz-Security-Token")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "X-Amz-Security-Token", valid_601356
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601357 = header.getOrDefault("X-Amz-Target")
  valid_601357 = validateParameter(valid_601357, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeImageBuilders"))
  if valid_601357 != nil:
    section.add "X-Amz-Target", valid_601357
  var valid_601358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-Content-Sha256", valid_601358
  var valid_601359 = header.getOrDefault("X-Amz-Algorithm")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "X-Amz-Algorithm", valid_601359
  var valid_601360 = header.getOrDefault("X-Amz-Signature")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "X-Amz-Signature", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-SignedHeaders", valid_601361
  var valid_601362 = header.getOrDefault("X-Amz-Credential")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-Credential", valid_601362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601364: Call_DescribeImageBuilders_601352; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified image builders, if the image builder names are provided. Otherwise, all image builders in the account are described.
  ## 
  let valid = call_601364.validator(path, query, header, formData, body)
  let scheme = call_601364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601364.url(scheme.get, call_601364.host, call_601364.base,
                         call_601364.route, valid.getOrDefault("path"))
  result = hook(call_601364, url, valid)

proc call*(call_601365: Call_DescribeImageBuilders_601352; body: JsonNode): Recallable =
  ## describeImageBuilders
  ## Retrieves a list that describes one or more specified image builders, if the image builder names are provided. Otherwise, all image builders in the account are described.
  ##   body: JObject (required)
  var body_601366 = newJObject()
  if body != nil:
    body_601366 = body
  result = call_601365.call(nil, nil, nil, nil, body_601366)

var describeImageBuilders* = Call_DescribeImageBuilders_601352(
    name: "describeImageBuilders", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeImageBuilders",
    validator: validate_DescribeImageBuilders_601353, base: "/",
    url: url_DescribeImageBuilders_601354, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeImagePermissions_601367 = ref object of OpenApiRestCall_600426
proc url_DescribeImagePermissions_601369(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeImagePermissions_601368(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list that describes the permissions for shared AWS account IDs on a private image that you own. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_601370 = query.getOrDefault("NextToken")
  valid_601370 = validateParameter(valid_601370, JString, required = false,
                                 default = nil)
  if valid_601370 != nil:
    section.add "NextToken", valid_601370
  var valid_601371 = query.getOrDefault("MaxResults")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "MaxResults", valid_601371
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
  var valid_601372 = header.getOrDefault("X-Amz-Date")
  valid_601372 = validateParameter(valid_601372, JString, required = false,
                                 default = nil)
  if valid_601372 != nil:
    section.add "X-Amz-Date", valid_601372
  var valid_601373 = header.getOrDefault("X-Amz-Security-Token")
  valid_601373 = validateParameter(valid_601373, JString, required = false,
                                 default = nil)
  if valid_601373 != nil:
    section.add "X-Amz-Security-Token", valid_601373
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601374 = header.getOrDefault("X-Amz-Target")
  valid_601374 = validateParameter(valid_601374, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeImagePermissions"))
  if valid_601374 != nil:
    section.add "X-Amz-Target", valid_601374
  var valid_601375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601375 = validateParameter(valid_601375, JString, required = false,
                                 default = nil)
  if valid_601375 != nil:
    section.add "X-Amz-Content-Sha256", valid_601375
  var valid_601376 = header.getOrDefault("X-Amz-Algorithm")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "X-Amz-Algorithm", valid_601376
  var valid_601377 = header.getOrDefault("X-Amz-Signature")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "X-Amz-Signature", valid_601377
  var valid_601378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601378 = validateParameter(valid_601378, JString, required = false,
                                 default = nil)
  if valid_601378 != nil:
    section.add "X-Amz-SignedHeaders", valid_601378
  var valid_601379 = header.getOrDefault("X-Amz-Credential")
  valid_601379 = validateParameter(valid_601379, JString, required = false,
                                 default = nil)
  if valid_601379 != nil:
    section.add "X-Amz-Credential", valid_601379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601381: Call_DescribeImagePermissions_601367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes the permissions for shared AWS account IDs on a private image that you own. 
  ## 
  let valid = call_601381.validator(path, query, header, formData, body)
  let scheme = call_601381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601381.url(scheme.get, call_601381.host, call_601381.base,
                         call_601381.route, valid.getOrDefault("path"))
  result = hook(call_601381, url, valid)

proc call*(call_601382: Call_DescribeImagePermissions_601367; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeImagePermissions
  ## Retrieves a list that describes the permissions for shared AWS account IDs on a private image that you own. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601383 = newJObject()
  var body_601384 = newJObject()
  add(query_601383, "NextToken", newJString(NextToken))
  if body != nil:
    body_601384 = body
  add(query_601383, "MaxResults", newJString(MaxResults))
  result = call_601382.call(nil, query_601383, nil, nil, body_601384)

var describeImagePermissions* = Call_DescribeImagePermissions_601367(
    name: "describeImagePermissions", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeImagePermissions",
    validator: validate_DescribeImagePermissions_601368, base: "/",
    url: url_DescribeImagePermissions_601369, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeImages_601386 = ref object of OpenApiRestCall_600426
proc url_DescribeImages_601388(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeImages_601387(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves a list that describes one or more specified images, if the image names or image ARNs are provided. Otherwise, all images in the account are described.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_601389 = query.getOrDefault("NextToken")
  valid_601389 = validateParameter(valid_601389, JString, required = false,
                                 default = nil)
  if valid_601389 != nil:
    section.add "NextToken", valid_601389
  var valid_601390 = query.getOrDefault("MaxResults")
  valid_601390 = validateParameter(valid_601390, JString, required = false,
                                 default = nil)
  if valid_601390 != nil:
    section.add "MaxResults", valid_601390
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
  var valid_601391 = header.getOrDefault("X-Amz-Date")
  valid_601391 = validateParameter(valid_601391, JString, required = false,
                                 default = nil)
  if valid_601391 != nil:
    section.add "X-Amz-Date", valid_601391
  var valid_601392 = header.getOrDefault("X-Amz-Security-Token")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "X-Amz-Security-Token", valid_601392
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601393 = header.getOrDefault("X-Amz-Target")
  valid_601393 = validateParameter(valid_601393, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeImages"))
  if valid_601393 != nil:
    section.add "X-Amz-Target", valid_601393
  var valid_601394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601394 = validateParameter(valid_601394, JString, required = false,
                                 default = nil)
  if valid_601394 != nil:
    section.add "X-Amz-Content-Sha256", valid_601394
  var valid_601395 = header.getOrDefault("X-Amz-Algorithm")
  valid_601395 = validateParameter(valid_601395, JString, required = false,
                                 default = nil)
  if valid_601395 != nil:
    section.add "X-Amz-Algorithm", valid_601395
  var valid_601396 = header.getOrDefault("X-Amz-Signature")
  valid_601396 = validateParameter(valid_601396, JString, required = false,
                                 default = nil)
  if valid_601396 != nil:
    section.add "X-Amz-Signature", valid_601396
  var valid_601397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601397 = validateParameter(valid_601397, JString, required = false,
                                 default = nil)
  if valid_601397 != nil:
    section.add "X-Amz-SignedHeaders", valid_601397
  var valid_601398 = header.getOrDefault("X-Amz-Credential")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "X-Amz-Credential", valid_601398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601400: Call_DescribeImages_601386; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified images, if the image names or image ARNs are provided. Otherwise, all images in the account are described.
  ## 
  let valid = call_601400.validator(path, query, header, formData, body)
  let scheme = call_601400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601400.url(scheme.get, call_601400.host, call_601400.base,
                         call_601400.route, valid.getOrDefault("path"))
  result = hook(call_601400, url, valid)

proc call*(call_601401: Call_DescribeImages_601386; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeImages
  ## Retrieves a list that describes one or more specified images, if the image names or image ARNs are provided. Otherwise, all images in the account are described.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601402 = newJObject()
  var body_601403 = newJObject()
  add(query_601402, "NextToken", newJString(NextToken))
  if body != nil:
    body_601403 = body
  add(query_601402, "MaxResults", newJString(MaxResults))
  result = call_601401.call(nil, query_601402, nil, nil, body_601403)

var describeImages* = Call_DescribeImages_601386(name: "describeImages",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeImages",
    validator: validate_DescribeImages_601387, base: "/", url: url_DescribeImages_601388,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSessions_601404 = ref object of OpenApiRestCall_600426
proc url_DescribeSessions_601406(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeSessions_601405(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601407 = header.getOrDefault("X-Amz-Date")
  valid_601407 = validateParameter(valid_601407, JString, required = false,
                                 default = nil)
  if valid_601407 != nil:
    section.add "X-Amz-Date", valid_601407
  var valid_601408 = header.getOrDefault("X-Amz-Security-Token")
  valid_601408 = validateParameter(valid_601408, JString, required = false,
                                 default = nil)
  if valid_601408 != nil:
    section.add "X-Amz-Security-Token", valid_601408
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601409 = header.getOrDefault("X-Amz-Target")
  valid_601409 = validateParameter(valid_601409, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeSessions"))
  if valid_601409 != nil:
    section.add "X-Amz-Target", valid_601409
  var valid_601410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601410 = validateParameter(valid_601410, JString, required = false,
                                 default = nil)
  if valid_601410 != nil:
    section.add "X-Amz-Content-Sha256", valid_601410
  var valid_601411 = header.getOrDefault("X-Amz-Algorithm")
  valid_601411 = validateParameter(valid_601411, JString, required = false,
                                 default = nil)
  if valid_601411 != nil:
    section.add "X-Amz-Algorithm", valid_601411
  var valid_601412 = header.getOrDefault("X-Amz-Signature")
  valid_601412 = validateParameter(valid_601412, JString, required = false,
                                 default = nil)
  if valid_601412 != nil:
    section.add "X-Amz-Signature", valid_601412
  var valid_601413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601413 = validateParameter(valid_601413, JString, required = false,
                                 default = nil)
  if valid_601413 != nil:
    section.add "X-Amz-SignedHeaders", valid_601413
  var valid_601414 = header.getOrDefault("X-Amz-Credential")
  valid_601414 = validateParameter(valid_601414, JString, required = false,
                                 default = nil)
  if valid_601414 != nil:
    section.add "X-Amz-Credential", valid_601414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601416: Call_DescribeSessions_601404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes the streaming sessions for a specified stack and fleet. If a UserId is provided for the stack and fleet, only streaming sessions for that user are described. If an authentication type is not provided, the default is to authenticate users using a streaming URL.
  ## 
  let valid = call_601416.validator(path, query, header, formData, body)
  let scheme = call_601416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601416.url(scheme.get, call_601416.host, call_601416.base,
                         call_601416.route, valid.getOrDefault("path"))
  result = hook(call_601416, url, valid)

proc call*(call_601417: Call_DescribeSessions_601404; body: JsonNode): Recallable =
  ## describeSessions
  ## Retrieves a list that describes the streaming sessions for a specified stack and fleet. If a UserId is provided for the stack and fleet, only streaming sessions for that user are described. If an authentication type is not provided, the default is to authenticate users using a streaming URL.
  ##   body: JObject (required)
  var body_601418 = newJObject()
  if body != nil:
    body_601418 = body
  result = call_601417.call(nil, nil, nil, nil, body_601418)

var describeSessions* = Call_DescribeSessions_601404(name: "describeSessions",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeSessions",
    validator: validate_DescribeSessions_601405, base: "/",
    url: url_DescribeSessions_601406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStacks_601419 = ref object of OpenApiRestCall_600426
proc url_DescribeStacks_601421(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeStacks_601420(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601422 = header.getOrDefault("X-Amz-Date")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-Date", valid_601422
  var valid_601423 = header.getOrDefault("X-Amz-Security-Token")
  valid_601423 = validateParameter(valid_601423, JString, required = false,
                                 default = nil)
  if valid_601423 != nil:
    section.add "X-Amz-Security-Token", valid_601423
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601424 = header.getOrDefault("X-Amz-Target")
  valid_601424 = validateParameter(valid_601424, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeStacks"))
  if valid_601424 != nil:
    section.add "X-Amz-Target", valid_601424
  var valid_601425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601425 = validateParameter(valid_601425, JString, required = false,
                                 default = nil)
  if valid_601425 != nil:
    section.add "X-Amz-Content-Sha256", valid_601425
  var valid_601426 = header.getOrDefault("X-Amz-Algorithm")
  valid_601426 = validateParameter(valid_601426, JString, required = false,
                                 default = nil)
  if valid_601426 != nil:
    section.add "X-Amz-Algorithm", valid_601426
  var valid_601427 = header.getOrDefault("X-Amz-Signature")
  valid_601427 = validateParameter(valid_601427, JString, required = false,
                                 default = nil)
  if valid_601427 != nil:
    section.add "X-Amz-Signature", valid_601427
  var valid_601428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601428 = validateParameter(valid_601428, JString, required = false,
                                 default = nil)
  if valid_601428 != nil:
    section.add "X-Amz-SignedHeaders", valid_601428
  var valid_601429 = header.getOrDefault("X-Amz-Credential")
  valid_601429 = validateParameter(valid_601429, JString, required = false,
                                 default = nil)
  if valid_601429 != nil:
    section.add "X-Amz-Credential", valid_601429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601431: Call_DescribeStacks_601419; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified stacks, if the stack names are provided. Otherwise, all stacks in the account are described.
  ## 
  let valid = call_601431.validator(path, query, header, formData, body)
  let scheme = call_601431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601431.url(scheme.get, call_601431.host, call_601431.base,
                         call_601431.route, valid.getOrDefault("path"))
  result = hook(call_601431, url, valid)

proc call*(call_601432: Call_DescribeStacks_601419; body: JsonNode): Recallable =
  ## describeStacks
  ## Retrieves a list that describes one or more specified stacks, if the stack names are provided. Otherwise, all stacks in the account are described.
  ##   body: JObject (required)
  var body_601433 = newJObject()
  if body != nil:
    body_601433 = body
  result = call_601432.call(nil, nil, nil, nil, body_601433)

var describeStacks* = Call_DescribeStacks_601419(name: "describeStacks",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeStacks",
    validator: validate_DescribeStacks_601420, base: "/", url: url_DescribeStacks_601421,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUsageReportSubscriptions_601434 = ref object of OpenApiRestCall_600426
proc url_DescribeUsageReportSubscriptions_601436(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeUsageReportSubscriptions_601435(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601437 = header.getOrDefault("X-Amz-Date")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-Date", valid_601437
  var valid_601438 = header.getOrDefault("X-Amz-Security-Token")
  valid_601438 = validateParameter(valid_601438, JString, required = false,
                                 default = nil)
  if valid_601438 != nil:
    section.add "X-Amz-Security-Token", valid_601438
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601439 = header.getOrDefault("X-Amz-Target")
  valid_601439 = validateParameter(valid_601439, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeUsageReportSubscriptions"))
  if valid_601439 != nil:
    section.add "X-Amz-Target", valid_601439
  var valid_601440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "X-Amz-Content-Sha256", valid_601440
  var valid_601441 = header.getOrDefault("X-Amz-Algorithm")
  valid_601441 = validateParameter(valid_601441, JString, required = false,
                                 default = nil)
  if valid_601441 != nil:
    section.add "X-Amz-Algorithm", valid_601441
  var valid_601442 = header.getOrDefault("X-Amz-Signature")
  valid_601442 = validateParameter(valid_601442, JString, required = false,
                                 default = nil)
  if valid_601442 != nil:
    section.add "X-Amz-Signature", valid_601442
  var valid_601443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601443 = validateParameter(valid_601443, JString, required = false,
                                 default = nil)
  if valid_601443 != nil:
    section.add "X-Amz-SignedHeaders", valid_601443
  var valid_601444 = header.getOrDefault("X-Amz-Credential")
  valid_601444 = validateParameter(valid_601444, JString, required = false,
                                 default = nil)
  if valid_601444 != nil:
    section.add "X-Amz-Credential", valid_601444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601446: Call_DescribeUsageReportSubscriptions_601434;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more usage report subscriptions.
  ## 
  let valid = call_601446.validator(path, query, header, formData, body)
  let scheme = call_601446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601446.url(scheme.get, call_601446.host, call_601446.base,
                         call_601446.route, valid.getOrDefault("path"))
  result = hook(call_601446, url, valid)

proc call*(call_601447: Call_DescribeUsageReportSubscriptions_601434;
          body: JsonNode): Recallable =
  ## describeUsageReportSubscriptions
  ## Retrieves a list that describes one or more usage report subscriptions.
  ##   body: JObject (required)
  var body_601448 = newJObject()
  if body != nil:
    body_601448 = body
  result = call_601447.call(nil, nil, nil, nil, body_601448)

var describeUsageReportSubscriptions* = Call_DescribeUsageReportSubscriptions_601434(
    name: "describeUsageReportSubscriptions", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeUsageReportSubscriptions",
    validator: validate_DescribeUsageReportSubscriptions_601435, base: "/",
    url: url_DescribeUsageReportSubscriptions_601436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserStackAssociations_601449 = ref object of OpenApiRestCall_600426
proc url_DescribeUserStackAssociations_601451(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeUserStackAssociations_601450(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601452 = header.getOrDefault("X-Amz-Date")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "X-Amz-Date", valid_601452
  var valid_601453 = header.getOrDefault("X-Amz-Security-Token")
  valid_601453 = validateParameter(valid_601453, JString, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "X-Amz-Security-Token", valid_601453
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601454 = header.getOrDefault("X-Amz-Target")
  valid_601454 = validateParameter(valid_601454, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeUserStackAssociations"))
  if valid_601454 != nil:
    section.add "X-Amz-Target", valid_601454
  var valid_601455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601455 = validateParameter(valid_601455, JString, required = false,
                                 default = nil)
  if valid_601455 != nil:
    section.add "X-Amz-Content-Sha256", valid_601455
  var valid_601456 = header.getOrDefault("X-Amz-Algorithm")
  valid_601456 = validateParameter(valid_601456, JString, required = false,
                                 default = nil)
  if valid_601456 != nil:
    section.add "X-Amz-Algorithm", valid_601456
  var valid_601457 = header.getOrDefault("X-Amz-Signature")
  valid_601457 = validateParameter(valid_601457, JString, required = false,
                                 default = nil)
  if valid_601457 != nil:
    section.add "X-Amz-Signature", valid_601457
  var valid_601458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601458 = validateParameter(valid_601458, JString, required = false,
                                 default = nil)
  if valid_601458 != nil:
    section.add "X-Amz-SignedHeaders", valid_601458
  var valid_601459 = header.getOrDefault("X-Amz-Credential")
  valid_601459 = validateParameter(valid_601459, JString, required = false,
                                 default = nil)
  if valid_601459 != nil:
    section.add "X-Amz-Credential", valid_601459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601461: Call_DescribeUserStackAssociations_601449; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list that describes the UserStackAssociation objects. You must specify either or both of the following:</p> <ul> <li> <p>The stack name</p> </li> <li> <p>The user name (email address of the user associated with the stack) and the authentication type for the user</p> </li> </ul>
  ## 
  let valid = call_601461.validator(path, query, header, formData, body)
  let scheme = call_601461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601461.url(scheme.get, call_601461.host, call_601461.base,
                         call_601461.route, valid.getOrDefault("path"))
  result = hook(call_601461, url, valid)

proc call*(call_601462: Call_DescribeUserStackAssociations_601449; body: JsonNode): Recallable =
  ## describeUserStackAssociations
  ## <p>Retrieves a list that describes the UserStackAssociation objects. You must specify either or both of the following:</p> <ul> <li> <p>The stack name</p> </li> <li> <p>The user name (email address of the user associated with the stack) and the authentication type for the user</p> </li> </ul>
  ##   body: JObject (required)
  var body_601463 = newJObject()
  if body != nil:
    body_601463 = body
  result = call_601462.call(nil, nil, nil, nil, body_601463)

var describeUserStackAssociations* = Call_DescribeUserStackAssociations_601449(
    name: "describeUserStackAssociations", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeUserStackAssociations",
    validator: validate_DescribeUserStackAssociations_601450, base: "/",
    url: url_DescribeUserStackAssociations_601451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUsers_601464 = ref object of OpenApiRestCall_600426
proc url_DescribeUsers_601466(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeUsers_601465(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601467 = header.getOrDefault("X-Amz-Date")
  valid_601467 = validateParameter(valid_601467, JString, required = false,
                                 default = nil)
  if valid_601467 != nil:
    section.add "X-Amz-Date", valid_601467
  var valid_601468 = header.getOrDefault("X-Amz-Security-Token")
  valid_601468 = validateParameter(valid_601468, JString, required = false,
                                 default = nil)
  if valid_601468 != nil:
    section.add "X-Amz-Security-Token", valid_601468
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601469 = header.getOrDefault("X-Amz-Target")
  valid_601469 = validateParameter(valid_601469, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeUsers"))
  if valid_601469 != nil:
    section.add "X-Amz-Target", valid_601469
  var valid_601470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = nil)
  if valid_601470 != nil:
    section.add "X-Amz-Content-Sha256", valid_601470
  var valid_601471 = header.getOrDefault("X-Amz-Algorithm")
  valid_601471 = validateParameter(valid_601471, JString, required = false,
                                 default = nil)
  if valid_601471 != nil:
    section.add "X-Amz-Algorithm", valid_601471
  var valid_601472 = header.getOrDefault("X-Amz-Signature")
  valid_601472 = validateParameter(valid_601472, JString, required = false,
                                 default = nil)
  if valid_601472 != nil:
    section.add "X-Amz-Signature", valid_601472
  var valid_601473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601473 = validateParameter(valid_601473, JString, required = false,
                                 default = nil)
  if valid_601473 != nil:
    section.add "X-Amz-SignedHeaders", valid_601473
  var valid_601474 = header.getOrDefault("X-Amz-Credential")
  valid_601474 = validateParameter(valid_601474, JString, required = false,
                                 default = nil)
  if valid_601474 != nil:
    section.add "X-Amz-Credential", valid_601474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601476: Call_DescribeUsers_601464; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified users in the user pool.
  ## 
  let valid = call_601476.validator(path, query, header, formData, body)
  let scheme = call_601476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601476.url(scheme.get, call_601476.host, call_601476.base,
                         call_601476.route, valid.getOrDefault("path"))
  result = hook(call_601476, url, valid)

proc call*(call_601477: Call_DescribeUsers_601464; body: JsonNode): Recallable =
  ## describeUsers
  ## Retrieves a list that describes one or more specified users in the user pool.
  ##   body: JObject (required)
  var body_601478 = newJObject()
  if body != nil:
    body_601478 = body
  result = call_601477.call(nil, nil, nil, nil, body_601478)

var describeUsers* = Call_DescribeUsers_601464(name: "describeUsers",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeUsers",
    validator: validate_DescribeUsers_601465, base: "/", url: url_DescribeUsers_601466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableUser_601479 = ref object of OpenApiRestCall_600426
proc url_DisableUser_601481(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisableUser_601480(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601482 = header.getOrDefault("X-Amz-Date")
  valid_601482 = validateParameter(valid_601482, JString, required = false,
                                 default = nil)
  if valid_601482 != nil:
    section.add "X-Amz-Date", valid_601482
  var valid_601483 = header.getOrDefault("X-Amz-Security-Token")
  valid_601483 = validateParameter(valid_601483, JString, required = false,
                                 default = nil)
  if valid_601483 != nil:
    section.add "X-Amz-Security-Token", valid_601483
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601484 = header.getOrDefault("X-Amz-Target")
  valid_601484 = validateParameter(valid_601484, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DisableUser"))
  if valid_601484 != nil:
    section.add "X-Amz-Target", valid_601484
  var valid_601485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601485 = validateParameter(valid_601485, JString, required = false,
                                 default = nil)
  if valid_601485 != nil:
    section.add "X-Amz-Content-Sha256", valid_601485
  var valid_601486 = header.getOrDefault("X-Amz-Algorithm")
  valid_601486 = validateParameter(valid_601486, JString, required = false,
                                 default = nil)
  if valid_601486 != nil:
    section.add "X-Amz-Algorithm", valid_601486
  var valid_601487 = header.getOrDefault("X-Amz-Signature")
  valid_601487 = validateParameter(valid_601487, JString, required = false,
                                 default = nil)
  if valid_601487 != nil:
    section.add "X-Amz-Signature", valid_601487
  var valid_601488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601488 = validateParameter(valid_601488, JString, required = false,
                                 default = nil)
  if valid_601488 != nil:
    section.add "X-Amz-SignedHeaders", valid_601488
  var valid_601489 = header.getOrDefault("X-Amz-Credential")
  valid_601489 = validateParameter(valid_601489, JString, required = false,
                                 default = nil)
  if valid_601489 != nil:
    section.add "X-Amz-Credential", valid_601489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601491: Call_DisableUser_601479; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the specified user in the user pool. Users can't sign in to AppStream 2.0 until they are re-enabled. This action does not delete the user. 
  ## 
  let valid = call_601491.validator(path, query, header, formData, body)
  let scheme = call_601491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601491.url(scheme.get, call_601491.host, call_601491.base,
                         call_601491.route, valid.getOrDefault("path"))
  result = hook(call_601491, url, valid)

proc call*(call_601492: Call_DisableUser_601479; body: JsonNode): Recallable =
  ## disableUser
  ## Disables the specified user in the user pool. Users can't sign in to AppStream 2.0 until they are re-enabled. This action does not delete the user. 
  ##   body: JObject (required)
  var body_601493 = newJObject()
  if body != nil:
    body_601493 = body
  result = call_601492.call(nil, nil, nil, nil, body_601493)

var disableUser* = Call_DisableUser_601479(name: "disableUser",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DisableUser",
                                        validator: validate_DisableUser_601480,
                                        base: "/", url: url_DisableUser_601481,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateFleet_601494 = ref object of OpenApiRestCall_600426
proc url_DisassociateFleet_601496(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociateFleet_601495(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601497 = header.getOrDefault("X-Amz-Date")
  valid_601497 = validateParameter(valid_601497, JString, required = false,
                                 default = nil)
  if valid_601497 != nil:
    section.add "X-Amz-Date", valid_601497
  var valid_601498 = header.getOrDefault("X-Amz-Security-Token")
  valid_601498 = validateParameter(valid_601498, JString, required = false,
                                 default = nil)
  if valid_601498 != nil:
    section.add "X-Amz-Security-Token", valid_601498
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601499 = header.getOrDefault("X-Amz-Target")
  valid_601499 = validateParameter(valid_601499, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DisassociateFleet"))
  if valid_601499 != nil:
    section.add "X-Amz-Target", valid_601499
  var valid_601500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601500 = validateParameter(valid_601500, JString, required = false,
                                 default = nil)
  if valid_601500 != nil:
    section.add "X-Amz-Content-Sha256", valid_601500
  var valid_601501 = header.getOrDefault("X-Amz-Algorithm")
  valid_601501 = validateParameter(valid_601501, JString, required = false,
                                 default = nil)
  if valid_601501 != nil:
    section.add "X-Amz-Algorithm", valid_601501
  var valid_601502 = header.getOrDefault("X-Amz-Signature")
  valid_601502 = validateParameter(valid_601502, JString, required = false,
                                 default = nil)
  if valid_601502 != nil:
    section.add "X-Amz-Signature", valid_601502
  var valid_601503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601503 = validateParameter(valid_601503, JString, required = false,
                                 default = nil)
  if valid_601503 != nil:
    section.add "X-Amz-SignedHeaders", valid_601503
  var valid_601504 = header.getOrDefault("X-Amz-Credential")
  valid_601504 = validateParameter(valid_601504, JString, required = false,
                                 default = nil)
  if valid_601504 != nil:
    section.add "X-Amz-Credential", valid_601504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601506: Call_DisassociateFleet_601494; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified fleet from the specified stack.
  ## 
  let valid = call_601506.validator(path, query, header, formData, body)
  let scheme = call_601506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601506.url(scheme.get, call_601506.host, call_601506.base,
                         call_601506.route, valid.getOrDefault("path"))
  result = hook(call_601506, url, valid)

proc call*(call_601507: Call_DisassociateFleet_601494; body: JsonNode): Recallable =
  ## disassociateFleet
  ## Disassociates the specified fleet from the specified stack.
  ##   body: JObject (required)
  var body_601508 = newJObject()
  if body != nil:
    body_601508 = body
  result = call_601507.call(nil, nil, nil, nil, body_601508)

var disassociateFleet* = Call_DisassociateFleet_601494(name: "disassociateFleet",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DisassociateFleet",
    validator: validate_DisassociateFleet_601495, base: "/",
    url: url_DisassociateFleet_601496, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableUser_601509 = ref object of OpenApiRestCall_600426
proc url_EnableUser_601511(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_EnableUser_601510(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601512 = header.getOrDefault("X-Amz-Date")
  valid_601512 = validateParameter(valid_601512, JString, required = false,
                                 default = nil)
  if valid_601512 != nil:
    section.add "X-Amz-Date", valid_601512
  var valid_601513 = header.getOrDefault("X-Amz-Security-Token")
  valid_601513 = validateParameter(valid_601513, JString, required = false,
                                 default = nil)
  if valid_601513 != nil:
    section.add "X-Amz-Security-Token", valid_601513
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601514 = header.getOrDefault("X-Amz-Target")
  valid_601514 = validateParameter(valid_601514, JString, required = true, default = newJString(
      "PhotonAdminProxyService.EnableUser"))
  if valid_601514 != nil:
    section.add "X-Amz-Target", valid_601514
  var valid_601515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601515 = validateParameter(valid_601515, JString, required = false,
                                 default = nil)
  if valid_601515 != nil:
    section.add "X-Amz-Content-Sha256", valid_601515
  var valid_601516 = header.getOrDefault("X-Amz-Algorithm")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "X-Amz-Algorithm", valid_601516
  var valid_601517 = header.getOrDefault("X-Amz-Signature")
  valid_601517 = validateParameter(valid_601517, JString, required = false,
                                 default = nil)
  if valid_601517 != nil:
    section.add "X-Amz-Signature", valid_601517
  var valid_601518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601518 = validateParameter(valid_601518, JString, required = false,
                                 default = nil)
  if valid_601518 != nil:
    section.add "X-Amz-SignedHeaders", valid_601518
  var valid_601519 = header.getOrDefault("X-Amz-Credential")
  valid_601519 = validateParameter(valid_601519, JString, required = false,
                                 default = nil)
  if valid_601519 != nil:
    section.add "X-Amz-Credential", valid_601519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601521: Call_EnableUser_601509; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables a user in the user pool. After being enabled, users can sign in to AppStream 2.0 and open applications from the stacks to which they are assigned.
  ## 
  let valid = call_601521.validator(path, query, header, formData, body)
  let scheme = call_601521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601521.url(scheme.get, call_601521.host, call_601521.base,
                         call_601521.route, valid.getOrDefault("path"))
  result = hook(call_601521, url, valid)

proc call*(call_601522: Call_EnableUser_601509; body: JsonNode): Recallable =
  ## enableUser
  ## Enables a user in the user pool. After being enabled, users can sign in to AppStream 2.0 and open applications from the stacks to which they are assigned.
  ##   body: JObject (required)
  var body_601523 = newJObject()
  if body != nil:
    body_601523 = body
  result = call_601522.call(nil, nil, nil, nil, body_601523)

var enableUser* = Call_EnableUser_601509(name: "enableUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.EnableUser",
                                      validator: validate_EnableUser_601510,
                                      base: "/", url: url_EnableUser_601511,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExpireSession_601524 = ref object of OpenApiRestCall_600426
proc url_ExpireSession_601526(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ExpireSession_601525(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601527 = header.getOrDefault("X-Amz-Date")
  valid_601527 = validateParameter(valid_601527, JString, required = false,
                                 default = nil)
  if valid_601527 != nil:
    section.add "X-Amz-Date", valid_601527
  var valid_601528 = header.getOrDefault("X-Amz-Security-Token")
  valid_601528 = validateParameter(valid_601528, JString, required = false,
                                 default = nil)
  if valid_601528 != nil:
    section.add "X-Amz-Security-Token", valid_601528
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601529 = header.getOrDefault("X-Amz-Target")
  valid_601529 = validateParameter(valid_601529, JString, required = true, default = newJString(
      "PhotonAdminProxyService.ExpireSession"))
  if valid_601529 != nil:
    section.add "X-Amz-Target", valid_601529
  var valid_601530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601530 = validateParameter(valid_601530, JString, required = false,
                                 default = nil)
  if valid_601530 != nil:
    section.add "X-Amz-Content-Sha256", valid_601530
  var valid_601531 = header.getOrDefault("X-Amz-Algorithm")
  valid_601531 = validateParameter(valid_601531, JString, required = false,
                                 default = nil)
  if valid_601531 != nil:
    section.add "X-Amz-Algorithm", valid_601531
  var valid_601532 = header.getOrDefault("X-Amz-Signature")
  valid_601532 = validateParameter(valid_601532, JString, required = false,
                                 default = nil)
  if valid_601532 != nil:
    section.add "X-Amz-Signature", valid_601532
  var valid_601533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601533 = validateParameter(valid_601533, JString, required = false,
                                 default = nil)
  if valid_601533 != nil:
    section.add "X-Amz-SignedHeaders", valid_601533
  var valid_601534 = header.getOrDefault("X-Amz-Credential")
  valid_601534 = validateParameter(valid_601534, JString, required = false,
                                 default = nil)
  if valid_601534 != nil:
    section.add "X-Amz-Credential", valid_601534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601536: Call_ExpireSession_601524; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Immediately stops the specified streaming session.
  ## 
  let valid = call_601536.validator(path, query, header, formData, body)
  let scheme = call_601536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601536.url(scheme.get, call_601536.host, call_601536.base,
                         call_601536.route, valid.getOrDefault("path"))
  result = hook(call_601536, url, valid)

proc call*(call_601537: Call_ExpireSession_601524; body: JsonNode): Recallable =
  ## expireSession
  ## Immediately stops the specified streaming session.
  ##   body: JObject (required)
  var body_601538 = newJObject()
  if body != nil:
    body_601538 = body
  result = call_601537.call(nil, nil, nil, nil, body_601538)

var expireSession* = Call_ExpireSession_601524(name: "expireSession",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.ExpireSession",
    validator: validate_ExpireSession_601525, base: "/", url: url_ExpireSession_601526,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociatedFleets_601539 = ref object of OpenApiRestCall_600426
proc url_ListAssociatedFleets_601541(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAssociatedFleets_601540(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601542 = header.getOrDefault("X-Amz-Date")
  valid_601542 = validateParameter(valid_601542, JString, required = false,
                                 default = nil)
  if valid_601542 != nil:
    section.add "X-Amz-Date", valid_601542
  var valid_601543 = header.getOrDefault("X-Amz-Security-Token")
  valid_601543 = validateParameter(valid_601543, JString, required = false,
                                 default = nil)
  if valid_601543 != nil:
    section.add "X-Amz-Security-Token", valid_601543
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601544 = header.getOrDefault("X-Amz-Target")
  valid_601544 = validateParameter(valid_601544, JString, required = true, default = newJString(
      "PhotonAdminProxyService.ListAssociatedFleets"))
  if valid_601544 != nil:
    section.add "X-Amz-Target", valid_601544
  var valid_601545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601545 = validateParameter(valid_601545, JString, required = false,
                                 default = nil)
  if valid_601545 != nil:
    section.add "X-Amz-Content-Sha256", valid_601545
  var valid_601546 = header.getOrDefault("X-Amz-Algorithm")
  valid_601546 = validateParameter(valid_601546, JString, required = false,
                                 default = nil)
  if valid_601546 != nil:
    section.add "X-Amz-Algorithm", valid_601546
  var valid_601547 = header.getOrDefault("X-Amz-Signature")
  valid_601547 = validateParameter(valid_601547, JString, required = false,
                                 default = nil)
  if valid_601547 != nil:
    section.add "X-Amz-Signature", valid_601547
  var valid_601548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601548 = validateParameter(valid_601548, JString, required = false,
                                 default = nil)
  if valid_601548 != nil:
    section.add "X-Amz-SignedHeaders", valid_601548
  var valid_601549 = header.getOrDefault("X-Amz-Credential")
  valid_601549 = validateParameter(valid_601549, JString, required = false,
                                 default = nil)
  if valid_601549 != nil:
    section.add "X-Amz-Credential", valid_601549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601551: Call_ListAssociatedFleets_601539; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the name of the fleet that is associated with the specified stack.
  ## 
  let valid = call_601551.validator(path, query, header, formData, body)
  let scheme = call_601551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601551.url(scheme.get, call_601551.host, call_601551.base,
                         call_601551.route, valid.getOrDefault("path"))
  result = hook(call_601551, url, valid)

proc call*(call_601552: Call_ListAssociatedFleets_601539; body: JsonNode): Recallable =
  ## listAssociatedFleets
  ## Retrieves the name of the fleet that is associated with the specified stack.
  ##   body: JObject (required)
  var body_601553 = newJObject()
  if body != nil:
    body_601553 = body
  result = call_601552.call(nil, nil, nil, nil, body_601553)

var listAssociatedFleets* = Call_ListAssociatedFleets_601539(
    name: "listAssociatedFleets", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.ListAssociatedFleets",
    validator: validate_ListAssociatedFleets_601540, base: "/",
    url: url_ListAssociatedFleets_601541, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociatedStacks_601554 = ref object of OpenApiRestCall_600426
proc url_ListAssociatedStacks_601556(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAssociatedStacks_601555(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601557 = header.getOrDefault("X-Amz-Date")
  valid_601557 = validateParameter(valid_601557, JString, required = false,
                                 default = nil)
  if valid_601557 != nil:
    section.add "X-Amz-Date", valid_601557
  var valid_601558 = header.getOrDefault("X-Amz-Security-Token")
  valid_601558 = validateParameter(valid_601558, JString, required = false,
                                 default = nil)
  if valid_601558 != nil:
    section.add "X-Amz-Security-Token", valid_601558
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601559 = header.getOrDefault("X-Amz-Target")
  valid_601559 = validateParameter(valid_601559, JString, required = true, default = newJString(
      "PhotonAdminProxyService.ListAssociatedStacks"))
  if valid_601559 != nil:
    section.add "X-Amz-Target", valid_601559
  var valid_601560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601560 = validateParameter(valid_601560, JString, required = false,
                                 default = nil)
  if valid_601560 != nil:
    section.add "X-Amz-Content-Sha256", valid_601560
  var valid_601561 = header.getOrDefault("X-Amz-Algorithm")
  valid_601561 = validateParameter(valid_601561, JString, required = false,
                                 default = nil)
  if valid_601561 != nil:
    section.add "X-Amz-Algorithm", valid_601561
  var valid_601562 = header.getOrDefault("X-Amz-Signature")
  valid_601562 = validateParameter(valid_601562, JString, required = false,
                                 default = nil)
  if valid_601562 != nil:
    section.add "X-Amz-Signature", valid_601562
  var valid_601563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601563 = validateParameter(valid_601563, JString, required = false,
                                 default = nil)
  if valid_601563 != nil:
    section.add "X-Amz-SignedHeaders", valid_601563
  var valid_601564 = header.getOrDefault("X-Amz-Credential")
  valid_601564 = validateParameter(valid_601564, JString, required = false,
                                 default = nil)
  if valid_601564 != nil:
    section.add "X-Amz-Credential", valid_601564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601566: Call_ListAssociatedStacks_601554; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the name of the stack with which the specified fleet is associated.
  ## 
  let valid = call_601566.validator(path, query, header, formData, body)
  let scheme = call_601566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601566.url(scheme.get, call_601566.host, call_601566.base,
                         call_601566.route, valid.getOrDefault("path"))
  result = hook(call_601566, url, valid)

proc call*(call_601567: Call_ListAssociatedStacks_601554; body: JsonNode): Recallable =
  ## listAssociatedStacks
  ## Retrieves the name of the stack with which the specified fleet is associated.
  ##   body: JObject (required)
  var body_601568 = newJObject()
  if body != nil:
    body_601568 = body
  result = call_601567.call(nil, nil, nil, nil, body_601568)

var listAssociatedStacks* = Call_ListAssociatedStacks_601554(
    name: "listAssociatedStacks", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.ListAssociatedStacks",
    validator: validate_ListAssociatedStacks_601555, base: "/",
    url: url_ListAssociatedStacks_601556, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_601569 = ref object of OpenApiRestCall_600426
proc url_ListTagsForResource_601571(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_601570(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601572 = header.getOrDefault("X-Amz-Date")
  valid_601572 = validateParameter(valid_601572, JString, required = false,
                                 default = nil)
  if valid_601572 != nil:
    section.add "X-Amz-Date", valid_601572
  var valid_601573 = header.getOrDefault("X-Amz-Security-Token")
  valid_601573 = validateParameter(valid_601573, JString, required = false,
                                 default = nil)
  if valid_601573 != nil:
    section.add "X-Amz-Security-Token", valid_601573
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601574 = header.getOrDefault("X-Amz-Target")
  valid_601574 = validateParameter(valid_601574, JString, required = true, default = newJString(
      "PhotonAdminProxyService.ListTagsForResource"))
  if valid_601574 != nil:
    section.add "X-Amz-Target", valid_601574
  var valid_601575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601575 = validateParameter(valid_601575, JString, required = false,
                                 default = nil)
  if valid_601575 != nil:
    section.add "X-Amz-Content-Sha256", valid_601575
  var valid_601576 = header.getOrDefault("X-Amz-Algorithm")
  valid_601576 = validateParameter(valid_601576, JString, required = false,
                                 default = nil)
  if valid_601576 != nil:
    section.add "X-Amz-Algorithm", valid_601576
  var valid_601577 = header.getOrDefault("X-Amz-Signature")
  valid_601577 = validateParameter(valid_601577, JString, required = false,
                                 default = nil)
  if valid_601577 != nil:
    section.add "X-Amz-Signature", valid_601577
  var valid_601578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601578 = validateParameter(valid_601578, JString, required = false,
                                 default = nil)
  if valid_601578 != nil:
    section.add "X-Amz-SignedHeaders", valid_601578
  var valid_601579 = header.getOrDefault("X-Amz-Credential")
  valid_601579 = validateParameter(valid_601579, JString, required = false,
                                 default = nil)
  if valid_601579 != nil:
    section.add "X-Amz-Credential", valid_601579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601581: Call_ListTagsForResource_601569; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of all tags for the specified AppStream 2.0 resource. You can tag AppStream 2.0 image builders, images, fleets, and stacks.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
  ## 
  let valid = call_601581.validator(path, query, header, formData, body)
  let scheme = call_601581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601581.url(scheme.get, call_601581.host, call_601581.base,
                         call_601581.route, valid.getOrDefault("path"))
  result = hook(call_601581, url, valid)

proc call*(call_601582: Call_ListTagsForResource_601569; body: JsonNode): Recallable =
  ## listTagsForResource
  ## <p>Retrieves a list of all tags for the specified AppStream 2.0 resource. You can tag AppStream 2.0 image builders, images, fleets, and stacks.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
  ##   body: JObject (required)
  var body_601583 = newJObject()
  if body != nil:
    body_601583 = body
  result = call_601582.call(nil, nil, nil, nil, body_601583)

var listTagsForResource* = Call_ListTagsForResource_601569(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.ListTagsForResource",
    validator: validate_ListTagsForResource_601570, base: "/",
    url: url_ListTagsForResource_601571, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartFleet_601584 = ref object of OpenApiRestCall_600426
proc url_StartFleet_601586(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartFleet_601585(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601587 = header.getOrDefault("X-Amz-Date")
  valid_601587 = validateParameter(valid_601587, JString, required = false,
                                 default = nil)
  if valid_601587 != nil:
    section.add "X-Amz-Date", valid_601587
  var valid_601588 = header.getOrDefault("X-Amz-Security-Token")
  valid_601588 = validateParameter(valid_601588, JString, required = false,
                                 default = nil)
  if valid_601588 != nil:
    section.add "X-Amz-Security-Token", valid_601588
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601589 = header.getOrDefault("X-Amz-Target")
  valid_601589 = validateParameter(valid_601589, JString, required = true, default = newJString(
      "PhotonAdminProxyService.StartFleet"))
  if valid_601589 != nil:
    section.add "X-Amz-Target", valid_601589
  var valid_601590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601590 = validateParameter(valid_601590, JString, required = false,
                                 default = nil)
  if valid_601590 != nil:
    section.add "X-Amz-Content-Sha256", valid_601590
  var valid_601591 = header.getOrDefault("X-Amz-Algorithm")
  valid_601591 = validateParameter(valid_601591, JString, required = false,
                                 default = nil)
  if valid_601591 != nil:
    section.add "X-Amz-Algorithm", valid_601591
  var valid_601592 = header.getOrDefault("X-Amz-Signature")
  valid_601592 = validateParameter(valid_601592, JString, required = false,
                                 default = nil)
  if valid_601592 != nil:
    section.add "X-Amz-Signature", valid_601592
  var valid_601593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601593 = validateParameter(valid_601593, JString, required = false,
                                 default = nil)
  if valid_601593 != nil:
    section.add "X-Amz-SignedHeaders", valid_601593
  var valid_601594 = header.getOrDefault("X-Amz-Credential")
  valid_601594 = validateParameter(valid_601594, JString, required = false,
                                 default = nil)
  if valid_601594 != nil:
    section.add "X-Amz-Credential", valid_601594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601596: Call_StartFleet_601584; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the specified fleet.
  ## 
  let valid = call_601596.validator(path, query, header, formData, body)
  let scheme = call_601596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601596.url(scheme.get, call_601596.host, call_601596.base,
                         call_601596.route, valid.getOrDefault("path"))
  result = hook(call_601596, url, valid)

proc call*(call_601597: Call_StartFleet_601584; body: JsonNode): Recallable =
  ## startFleet
  ## Starts the specified fleet.
  ##   body: JObject (required)
  var body_601598 = newJObject()
  if body != nil:
    body_601598 = body
  result = call_601597.call(nil, nil, nil, nil, body_601598)

var startFleet* = Call_StartFleet_601584(name: "startFleet",
                                      meth: HttpMethod.HttpPost,
                                      host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.StartFleet",
                                      validator: validate_StartFleet_601585,
                                      base: "/", url: url_StartFleet_601586,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImageBuilder_601599 = ref object of OpenApiRestCall_600426
proc url_StartImageBuilder_601601(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartImageBuilder_601600(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601602 = header.getOrDefault("X-Amz-Date")
  valid_601602 = validateParameter(valid_601602, JString, required = false,
                                 default = nil)
  if valid_601602 != nil:
    section.add "X-Amz-Date", valid_601602
  var valid_601603 = header.getOrDefault("X-Amz-Security-Token")
  valid_601603 = validateParameter(valid_601603, JString, required = false,
                                 default = nil)
  if valid_601603 != nil:
    section.add "X-Amz-Security-Token", valid_601603
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601604 = header.getOrDefault("X-Amz-Target")
  valid_601604 = validateParameter(valid_601604, JString, required = true, default = newJString(
      "PhotonAdminProxyService.StartImageBuilder"))
  if valid_601604 != nil:
    section.add "X-Amz-Target", valid_601604
  var valid_601605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601605 = validateParameter(valid_601605, JString, required = false,
                                 default = nil)
  if valid_601605 != nil:
    section.add "X-Amz-Content-Sha256", valid_601605
  var valid_601606 = header.getOrDefault("X-Amz-Algorithm")
  valid_601606 = validateParameter(valid_601606, JString, required = false,
                                 default = nil)
  if valid_601606 != nil:
    section.add "X-Amz-Algorithm", valid_601606
  var valid_601607 = header.getOrDefault("X-Amz-Signature")
  valid_601607 = validateParameter(valid_601607, JString, required = false,
                                 default = nil)
  if valid_601607 != nil:
    section.add "X-Amz-Signature", valid_601607
  var valid_601608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601608 = validateParameter(valid_601608, JString, required = false,
                                 default = nil)
  if valid_601608 != nil:
    section.add "X-Amz-SignedHeaders", valid_601608
  var valid_601609 = header.getOrDefault("X-Amz-Credential")
  valid_601609 = validateParameter(valid_601609, JString, required = false,
                                 default = nil)
  if valid_601609 != nil:
    section.add "X-Amz-Credential", valid_601609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601611: Call_StartImageBuilder_601599; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the specified image builder.
  ## 
  let valid = call_601611.validator(path, query, header, formData, body)
  let scheme = call_601611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601611.url(scheme.get, call_601611.host, call_601611.base,
                         call_601611.route, valid.getOrDefault("path"))
  result = hook(call_601611, url, valid)

proc call*(call_601612: Call_StartImageBuilder_601599; body: JsonNode): Recallable =
  ## startImageBuilder
  ## Starts the specified image builder.
  ##   body: JObject (required)
  var body_601613 = newJObject()
  if body != nil:
    body_601613 = body
  result = call_601612.call(nil, nil, nil, nil, body_601613)

var startImageBuilder* = Call_StartImageBuilder_601599(name: "startImageBuilder",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.StartImageBuilder",
    validator: validate_StartImageBuilder_601600, base: "/",
    url: url_StartImageBuilder_601601, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopFleet_601614 = ref object of OpenApiRestCall_600426
proc url_StopFleet_601616(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopFleet_601615(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601617 = header.getOrDefault("X-Amz-Date")
  valid_601617 = validateParameter(valid_601617, JString, required = false,
                                 default = nil)
  if valid_601617 != nil:
    section.add "X-Amz-Date", valid_601617
  var valid_601618 = header.getOrDefault("X-Amz-Security-Token")
  valid_601618 = validateParameter(valid_601618, JString, required = false,
                                 default = nil)
  if valid_601618 != nil:
    section.add "X-Amz-Security-Token", valid_601618
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601619 = header.getOrDefault("X-Amz-Target")
  valid_601619 = validateParameter(valid_601619, JString, required = true, default = newJString(
      "PhotonAdminProxyService.StopFleet"))
  if valid_601619 != nil:
    section.add "X-Amz-Target", valid_601619
  var valid_601620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601620 = validateParameter(valid_601620, JString, required = false,
                                 default = nil)
  if valid_601620 != nil:
    section.add "X-Amz-Content-Sha256", valid_601620
  var valid_601621 = header.getOrDefault("X-Amz-Algorithm")
  valid_601621 = validateParameter(valid_601621, JString, required = false,
                                 default = nil)
  if valid_601621 != nil:
    section.add "X-Amz-Algorithm", valid_601621
  var valid_601622 = header.getOrDefault("X-Amz-Signature")
  valid_601622 = validateParameter(valid_601622, JString, required = false,
                                 default = nil)
  if valid_601622 != nil:
    section.add "X-Amz-Signature", valid_601622
  var valid_601623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601623 = validateParameter(valid_601623, JString, required = false,
                                 default = nil)
  if valid_601623 != nil:
    section.add "X-Amz-SignedHeaders", valid_601623
  var valid_601624 = header.getOrDefault("X-Amz-Credential")
  valid_601624 = validateParameter(valid_601624, JString, required = false,
                                 default = nil)
  if valid_601624 != nil:
    section.add "X-Amz-Credential", valid_601624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601626: Call_StopFleet_601614; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the specified fleet.
  ## 
  let valid = call_601626.validator(path, query, header, formData, body)
  let scheme = call_601626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601626.url(scheme.get, call_601626.host, call_601626.base,
                         call_601626.route, valid.getOrDefault("path"))
  result = hook(call_601626, url, valid)

proc call*(call_601627: Call_StopFleet_601614; body: JsonNode): Recallable =
  ## stopFleet
  ## Stops the specified fleet.
  ##   body: JObject (required)
  var body_601628 = newJObject()
  if body != nil:
    body_601628 = body
  result = call_601627.call(nil, nil, nil, nil, body_601628)

var stopFleet* = Call_StopFleet_601614(name: "stopFleet", meth: HttpMethod.HttpPost,
                                    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.StopFleet",
                                    validator: validate_StopFleet_601615,
                                    base: "/", url: url_StopFleet_601616,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopImageBuilder_601629 = ref object of OpenApiRestCall_600426
proc url_StopImageBuilder_601631(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopImageBuilder_601630(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601632 = header.getOrDefault("X-Amz-Date")
  valid_601632 = validateParameter(valid_601632, JString, required = false,
                                 default = nil)
  if valid_601632 != nil:
    section.add "X-Amz-Date", valid_601632
  var valid_601633 = header.getOrDefault("X-Amz-Security-Token")
  valid_601633 = validateParameter(valid_601633, JString, required = false,
                                 default = nil)
  if valid_601633 != nil:
    section.add "X-Amz-Security-Token", valid_601633
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601634 = header.getOrDefault("X-Amz-Target")
  valid_601634 = validateParameter(valid_601634, JString, required = true, default = newJString(
      "PhotonAdminProxyService.StopImageBuilder"))
  if valid_601634 != nil:
    section.add "X-Amz-Target", valid_601634
  var valid_601635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601635 = validateParameter(valid_601635, JString, required = false,
                                 default = nil)
  if valid_601635 != nil:
    section.add "X-Amz-Content-Sha256", valid_601635
  var valid_601636 = header.getOrDefault("X-Amz-Algorithm")
  valid_601636 = validateParameter(valid_601636, JString, required = false,
                                 default = nil)
  if valid_601636 != nil:
    section.add "X-Amz-Algorithm", valid_601636
  var valid_601637 = header.getOrDefault("X-Amz-Signature")
  valid_601637 = validateParameter(valid_601637, JString, required = false,
                                 default = nil)
  if valid_601637 != nil:
    section.add "X-Amz-Signature", valid_601637
  var valid_601638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601638 = validateParameter(valid_601638, JString, required = false,
                                 default = nil)
  if valid_601638 != nil:
    section.add "X-Amz-SignedHeaders", valid_601638
  var valid_601639 = header.getOrDefault("X-Amz-Credential")
  valid_601639 = validateParameter(valid_601639, JString, required = false,
                                 default = nil)
  if valid_601639 != nil:
    section.add "X-Amz-Credential", valid_601639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601641: Call_StopImageBuilder_601629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the specified image builder.
  ## 
  let valid = call_601641.validator(path, query, header, formData, body)
  let scheme = call_601641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601641.url(scheme.get, call_601641.host, call_601641.base,
                         call_601641.route, valid.getOrDefault("path"))
  result = hook(call_601641, url, valid)

proc call*(call_601642: Call_StopImageBuilder_601629; body: JsonNode): Recallable =
  ## stopImageBuilder
  ## Stops the specified image builder.
  ##   body: JObject (required)
  var body_601643 = newJObject()
  if body != nil:
    body_601643 = body
  result = call_601642.call(nil, nil, nil, nil, body_601643)

var stopImageBuilder* = Call_StopImageBuilder_601629(name: "stopImageBuilder",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.StopImageBuilder",
    validator: validate_StopImageBuilder_601630, base: "/",
    url: url_StopImageBuilder_601631, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601644 = ref object of OpenApiRestCall_600426
proc url_TagResource_601646(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_601645(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601647 = header.getOrDefault("X-Amz-Date")
  valid_601647 = validateParameter(valid_601647, JString, required = false,
                                 default = nil)
  if valid_601647 != nil:
    section.add "X-Amz-Date", valid_601647
  var valid_601648 = header.getOrDefault("X-Amz-Security-Token")
  valid_601648 = validateParameter(valid_601648, JString, required = false,
                                 default = nil)
  if valid_601648 != nil:
    section.add "X-Amz-Security-Token", valid_601648
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601649 = header.getOrDefault("X-Amz-Target")
  valid_601649 = validateParameter(valid_601649, JString, required = true, default = newJString(
      "PhotonAdminProxyService.TagResource"))
  if valid_601649 != nil:
    section.add "X-Amz-Target", valid_601649
  var valid_601650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601650 = validateParameter(valid_601650, JString, required = false,
                                 default = nil)
  if valid_601650 != nil:
    section.add "X-Amz-Content-Sha256", valid_601650
  var valid_601651 = header.getOrDefault("X-Amz-Algorithm")
  valid_601651 = validateParameter(valid_601651, JString, required = false,
                                 default = nil)
  if valid_601651 != nil:
    section.add "X-Amz-Algorithm", valid_601651
  var valid_601652 = header.getOrDefault("X-Amz-Signature")
  valid_601652 = validateParameter(valid_601652, JString, required = false,
                                 default = nil)
  if valid_601652 != nil:
    section.add "X-Amz-Signature", valid_601652
  var valid_601653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601653 = validateParameter(valid_601653, JString, required = false,
                                 default = nil)
  if valid_601653 != nil:
    section.add "X-Amz-SignedHeaders", valid_601653
  var valid_601654 = header.getOrDefault("X-Amz-Credential")
  valid_601654 = validateParameter(valid_601654, JString, required = false,
                                 default = nil)
  if valid_601654 != nil:
    section.add "X-Amz-Credential", valid_601654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601656: Call_TagResource_601644; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or overwrites one or more tags for the specified AppStream 2.0 resource. You can tag AppStream 2.0 image builders, images, fleets, and stacks.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, this operation updates its value.</p> <p>To list the current tags for your resources, use <a>ListTagsForResource</a>. To disassociate tags from your resources, use <a>UntagResource</a>.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
  ## 
  let valid = call_601656.validator(path, query, header, formData, body)
  let scheme = call_601656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601656.url(scheme.get, call_601656.host, call_601656.base,
                         call_601656.route, valid.getOrDefault("path"))
  result = hook(call_601656, url, valid)

proc call*(call_601657: Call_TagResource_601644; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds or overwrites one or more tags for the specified AppStream 2.0 resource. You can tag AppStream 2.0 image builders, images, fleets, and stacks.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, this operation updates its value.</p> <p>To list the current tags for your resources, use <a>ListTagsForResource</a>. To disassociate tags from your resources, use <a>UntagResource</a>.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
  ##   body: JObject (required)
  var body_601658 = newJObject()
  if body != nil:
    body_601658 = body
  result = call_601657.call(nil, nil, nil, nil, body_601658)

var tagResource* = Call_TagResource_601644(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.TagResource",
                                        validator: validate_TagResource_601645,
                                        base: "/", url: url_TagResource_601646,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601659 = ref object of OpenApiRestCall_600426
proc url_UntagResource_601661(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_601660(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601662 = header.getOrDefault("X-Amz-Date")
  valid_601662 = validateParameter(valid_601662, JString, required = false,
                                 default = nil)
  if valid_601662 != nil:
    section.add "X-Amz-Date", valid_601662
  var valid_601663 = header.getOrDefault("X-Amz-Security-Token")
  valid_601663 = validateParameter(valid_601663, JString, required = false,
                                 default = nil)
  if valid_601663 != nil:
    section.add "X-Amz-Security-Token", valid_601663
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601664 = header.getOrDefault("X-Amz-Target")
  valid_601664 = validateParameter(valid_601664, JString, required = true, default = newJString(
      "PhotonAdminProxyService.UntagResource"))
  if valid_601664 != nil:
    section.add "X-Amz-Target", valid_601664
  var valid_601665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601665 = validateParameter(valid_601665, JString, required = false,
                                 default = nil)
  if valid_601665 != nil:
    section.add "X-Amz-Content-Sha256", valid_601665
  var valid_601666 = header.getOrDefault("X-Amz-Algorithm")
  valid_601666 = validateParameter(valid_601666, JString, required = false,
                                 default = nil)
  if valid_601666 != nil:
    section.add "X-Amz-Algorithm", valid_601666
  var valid_601667 = header.getOrDefault("X-Amz-Signature")
  valid_601667 = validateParameter(valid_601667, JString, required = false,
                                 default = nil)
  if valid_601667 != nil:
    section.add "X-Amz-Signature", valid_601667
  var valid_601668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601668 = validateParameter(valid_601668, JString, required = false,
                                 default = nil)
  if valid_601668 != nil:
    section.add "X-Amz-SignedHeaders", valid_601668
  var valid_601669 = header.getOrDefault("X-Amz-Credential")
  valid_601669 = validateParameter(valid_601669, JString, required = false,
                                 default = nil)
  if valid_601669 != nil:
    section.add "X-Amz-Credential", valid_601669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601671: Call_UntagResource_601659; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates one or more specified tags from the specified AppStream 2.0 resource.</p> <p>To list the current tags for your resources, use <a>ListTagsForResource</a>.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
  ## 
  let valid = call_601671.validator(path, query, header, formData, body)
  let scheme = call_601671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601671.url(scheme.get, call_601671.host, call_601671.base,
                         call_601671.route, valid.getOrDefault("path"))
  result = hook(call_601671, url, valid)

proc call*(call_601672: Call_UntagResource_601659; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Disassociates one or more specified tags from the specified AppStream 2.0 resource.</p> <p>To list the current tags for your resources, use <a>ListTagsForResource</a>.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
  ##   body: JObject (required)
  var body_601673 = newJObject()
  if body != nil:
    body_601673 = body
  result = call_601672.call(nil, nil, nil, nil, body_601673)

var untagResource* = Call_UntagResource_601659(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.UntagResource",
    validator: validate_UntagResource_601660, base: "/", url: url_UntagResource_601661,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDirectoryConfig_601674 = ref object of OpenApiRestCall_600426
proc url_UpdateDirectoryConfig_601676(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateDirectoryConfig_601675(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601677 = header.getOrDefault("X-Amz-Date")
  valid_601677 = validateParameter(valid_601677, JString, required = false,
                                 default = nil)
  if valid_601677 != nil:
    section.add "X-Amz-Date", valid_601677
  var valid_601678 = header.getOrDefault("X-Amz-Security-Token")
  valid_601678 = validateParameter(valid_601678, JString, required = false,
                                 default = nil)
  if valid_601678 != nil:
    section.add "X-Amz-Security-Token", valid_601678
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601679 = header.getOrDefault("X-Amz-Target")
  valid_601679 = validateParameter(valid_601679, JString, required = true, default = newJString(
      "PhotonAdminProxyService.UpdateDirectoryConfig"))
  if valid_601679 != nil:
    section.add "X-Amz-Target", valid_601679
  var valid_601680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601680 = validateParameter(valid_601680, JString, required = false,
                                 default = nil)
  if valid_601680 != nil:
    section.add "X-Amz-Content-Sha256", valid_601680
  var valid_601681 = header.getOrDefault("X-Amz-Algorithm")
  valid_601681 = validateParameter(valid_601681, JString, required = false,
                                 default = nil)
  if valid_601681 != nil:
    section.add "X-Amz-Algorithm", valid_601681
  var valid_601682 = header.getOrDefault("X-Amz-Signature")
  valid_601682 = validateParameter(valid_601682, JString, required = false,
                                 default = nil)
  if valid_601682 != nil:
    section.add "X-Amz-Signature", valid_601682
  var valid_601683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601683 = validateParameter(valid_601683, JString, required = false,
                                 default = nil)
  if valid_601683 != nil:
    section.add "X-Amz-SignedHeaders", valid_601683
  var valid_601684 = header.getOrDefault("X-Amz-Credential")
  valid_601684 = validateParameter(valid_601684, JString, required = false,
                                 default = nil)
  if valid_601684 != nil:
    section.add "X-Amz-Credential", valid_601684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601686: Call_UpdateDirectoryConfig_601674; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified Directory Config object in AppStream 2.0. This object includes the configuration information required to join fleets and image builders to Microsoft Active Directory domains.
  ## 
  let valid = call_601686.validator(path, query, header, formData, body)
  let scheme = call_601686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601686.url(scheme.get, call_601686.host, call_601686.base,
                         call_601686.route, valid.getOrDefault("path"))
  result = hook(call_601686, url, valid)

proc call*(call_601687: Call_UpdateDirectoryConfig_601674; body: JsonNode): Recallable =
  ## updateDirectoryConfig
  ## Updates the specified Directory Config object in AppStream 2.0. This object includes the configuration information required to join fleets and image builders to Microsoft Active Directory domains.
  ##   body: JObject (required)
  var body_601688 = newJObject()
  if body != nil:
    body_601688 = body
  result = call_601687.call(nil, nil, nil, nil, body_601688)

var updateDirectoryConfig* = Call_UpdateDirectoryConfig_601674(
    name: "updateDirectoryConfig", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.UpdateDirectoryConfig",
    validator: validate_UpdateDirectoryConfig_601675, base: "/",
    url: url_UpdateDirectoryConfig_601676, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFleet_601689 = ref object of OpenApiRestCall_600426
proc url_UpdateFleet_601691(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateFleet_601690(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601692 = header.getOrDefault("X-Amz-Date")
  valid_601692 = validateParameter(valid_601692, JString, required = false,
                                 default = nil)
  if valid_601692 != nil:
    section.add "X-Amz-Date", valid_601692
  var valid_601693 = header.getOrDefault("X-Amz-Security-Token")
  valid_601693 = validateParameter(valid_601693, JString, required = false,
                                 default = nil)
  if valid_601693 != nil:
    section.add "X-Amz-Security-Token", valid_601693
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601694 = header.getOrDefault("X-Amz-Target")
  valid_601694 = validateParameter(valid_601694, JString, required = true, default = newJString(
      "PhotonAdminProxyService.UpdateFleet"))
  if valid_601694 != nil:
    section.add "X-Amz-Target", valid_601694
  var valid_601695 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601695 = validateParameter(valid_601695, JString, required = false,
                                 default = nil)
  if valid_601695 != nil:
    section.add "X-Amz-Content-Sha256", valid_601695
  var valid_601696 = header.getOrDefault("X-Amz-Algorithm")
  valid_601696 = validateParameter(valid_601696, JString, required = false,
                                 default = nil)
  if valid_601696 != nil:
    section.add "X-Amz-Algorithm", valid_601696
  var valid_601697 = header.getOrDefault("X-Amz-Signature")
  valid_601697 = validateParameter(valid_601697, JString, required = false,
                                 default = nil)
  if valid_601697 != nil:
    section.add "X-Amz-Signature", valid_601697
  var valid_601698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601698 = validateParameter(valid_601698, JString, required = false,
                                 default = nil)
  if valid_601698 != nil:
    section.add "X-Amz-SignedHeaders", valid_601698
  var valid_601699 = header.getOrDefault("X-Amz-Credential")
  valid_601699 = validateParameter(valid_601699, JString, required = false,
                                 default = nil)
  if valid_601699 != nil:
    section.add "X-Amz-Credential", valid_601699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601701: Call_UpdateFleet_601689; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified fleet.</p> <p>If the fleet is in the <code>STOPPED</code> state, you can update any attribute except the fleet name. If the fleet is in the <code>RUNNING</code> state, you can update the <code>DisplayName</code>, <code>ComputeCapacity</code>, <code>ImageARN</code>, <code>ImageName</code>, <code>IdleDisconnectTimeoutInSeconds</code>, and <code>DisconnectTimeoutInSeconds</code> attributes. If the fleet is in the <code>STARTING</code> or <code>STOPPING</code> state, you can't update it.</p>
  ## 
  let valid = call_601701.validator(path, query, header, formData, body)
  let scheme = call_601701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601701.url(scheme.get, call_601701.host, call_601701.base,
                         call_601701.route, valid.getOrDefault("path"))
  result = hook(call_601701, url, valid)

proc call*(call_601702: Call_UpdateFleet_601689; body: JsonNode): Recallable =
  ## updateFleet
  ## <p>Updates the specified fleet.</p> <p>If the fleet is in the <code>STOPPED</code> state, you can update any attribute except the fleet name. If the fleet is in the <code>RUNNING</code> state, you can update the <code>DisplayName</code>, <code>ComputeCapacity</code>, <code>ImageARN</code>, <code>ImageName</code>, <code>IdleDisconnectTimeoutInSeconds</code>, and <code>DisconnectTimeoutInSeconds</code> attributes. If the fleet is in the <code>STARTING</code> or <code>STOPPING</code> state, you can't update it.</p>
  ##   body: JObject (required)
  var body_601703 = newJObject()
  if body != nil:
    body_601703 = body
  result = call_601702.call(nil, nil, nil, nil, body_601703)

var updateFleet* = Call_UpdateFleet_601689(name: "updateFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.UpdateFleet",
                                        validator: validate_UpdateFleet_601690,
                                        base: "/", url: url_UpdateFleet_601691,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateImagePermissions_601704 = ref object of OpenApiRestCall_600426
proc url_UpdateImagePermissions_601706(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateImagePermissions_601705(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601707 = header.getOrDefault("X-Amz-Date")
  valid_601707 = validateParameter(valid_601707, JString, required = false,
                                 default = nil)
  if valid_601707 != nil:
    section.add "X-Amz-Date", valid_601707
  var valid_601708 = header.getOrDefault("X-Amz-Security-Token")
  valid_601708 = validateParameter(valid_601708, JString, required = false,
                                 default = nil)
  if valid_601708 != nil:
    section.add "X-Amz-Security-Token", valid_601708
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601709 = header.getOrDefault("X-Amz-Target")
  valid_601709 = validateParameter(valid_601709, JString, required = true, default = newJString(
      "PhotonAdminProxyService.UpdateImagePermissions"))
  if valid_601709 != nil:
    section.add "X-Amz-Target", valid_601709
  var valid_601710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601710 = validateParameter(valid_601710, JString, required = false,
                                 default = nil)
  if valid_601710 != nil:
    section.add "X-Amz-Content-Sha256", valid_601710
  var valid_601711 = header.getOrDefault("X-Amz-Algorithm")
  valid_601711 = validateParameter(valid_601711, JString, required = false,
                                 default = nil)
  if valid_601711 != nil:
    section.add "X-Amz-Algorithm", valid_601711
  var valid_601712 = header.getOrDefault("X-Amz-Signature")
  valid_601712 = validateParameter(valid_601712, JString, required = false,
                                 default = nil)
  if valid_601712 != nil:
    section.add "X-Amz-Signature", valid_601712
  var valid_601713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601713 = validateParameter(valid_601713, JString, required = false,
                                 default = nil)
  if valid_601713 != nil:
    section.add "X-Amz-SignedHeaders", valid_601713
  var valid_601714 = header.getOrDefault("X-Amz-Credential")
  valid_601714 = validateParameter(valid_601714, JString, required = false,
                                 default = nil)
  if valid_601714 != nil:
    section.add "X-Amz-Credential", valid_601714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601716: Call_UpdateImagePermissions_601704; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates permissions for the specified private image. 
  ## 
  let valid = call_601716.validator(path, query, header, formData, body)
  let scheme = call_601716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601716.url(scheme.get, call_601716.host, call_601716.base,
                         call_601716.route, valid.getOrDefault("path"))
  result = hook(call_601716, url, valid)

proc call*(call_601717: Call_UpdateImagePermissions_601704; body: JsonNode): Recallable =
  ## updateImagePermissions
  ## Adds or updates permissions for the specified private image. 
  ##   body: JObject (required)
  var body_601718 = newJObject()
  if body != nil:
    body_601718 = body
  result = call_601717.call(nil, nil, nil, nil, body_601718)

var updateImagePermissions* = Call_UpdateImagePermissions_601704(
    name: "updateImagePermissions", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.UpdateImagePermissions",
    validator: validate_UpdateImagePermissions_601705, base: "/",
    url: url_UpdateImagePermissions_601706, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStack_601719 = ref object of OpenApiRestCall_600426
proc url_UpdateStack_601721(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateStack_601720(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601722 = header.getOrDefault("X-Amz-Date")
  valid_601722 = validateParameter(valid_601722, JString, required = false,
                                 default = nil)
  if valid_601722 != nil:
    section.add "X-Amz-Date", valid_601722
  var valid_601723 = header.getOrDefault("X-Amz-Security-Token")
  valid_601723 = validateParameter(valid_601723, JString, required = false,
                                 default = nil)
  if valid_601723 != nil:
    section.add "X-Amz-Security-Token", valid_601723
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601724 = header.getOrDefault("X-Amz-Target")
  valid_601724 = validateParameter(valid_601724, JString, required = true, default = newJString(
      "PhotonAdminProxyService.UpdateStack"))
  if valid_601724 != nil:
    section.add "X-Amz-Target", valid_601724
  var valid_601725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601725 = validateParameter(valid_601725, JString, required = false,
                                 default = nil)
  if valid_601725 != nil:
    section.add "X-Amz-Content-Sha256", valid_601725
  var valid_601726 = header.getOrDefault("X-Amz-Algorithm")
  valid_601726 = validateParameter(valid_601726, JString, required = false,
                                 default = nil)
  if valid_601726 != nil:
    section.add "X-Amz-Algorithm", valid_601726
  var valid_601727 = header.getOrDefault("X-Amz-Signature")
  valid_601727 = validateParameter(valid_601727, JString, required = false,
                                 default = nil)
  if valid_601727 != nil:
    section.add "X-Amz-Signature", valid_601727
  var valid_601728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601728 = validateParameter(valid_601728, JString, required = false,
                                 default = nil)
  if valid_601728 != nil:
    section.add "X-Amz-SignedHeaders", valid_601728
  var valid_601729 = header.getOrDefault("X-Amz-Credential")
  valid_601729 = validateParameter(valid_601729, JString, required = false,
                                 default = nil)
  if valid_601729 != nil:
    section.add "X-Amz-Credential", valid_601729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601731: Call_UpdateStack_601719; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified fields for the specified stack.
  ## 
  let valid = call_601731.validator(path, query, header, formData, body)
  let scheme = call_601731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601731.url(scheme.get, call_601731.host, call_601731.base,
                         call_601731.route, valid.getOrDefault("path"))
  result = hook(call_601731, url, valid)

proc call*(call_601732: Call_UpdateStack_601719; body: JsonNode): Recallable =
  ## updateStack
  ## Updates the specified fields for the specified stack.
  ##   body: JObject (required)
  var body_601733 = newJObject()
  if body != nil:
    body_601733 = body
  result = call_601732.call(nil, nil, nil, nil, body_601733)

var updateStack* = Call_UpdateStack_601719(name: "updateStack",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.UpdateStack",
                                        validator: validate_UpdateStack_601720,
                                        base: "/", url: url_UpdateStack_601721,
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
