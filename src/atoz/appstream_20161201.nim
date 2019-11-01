
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_591364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_591364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_591364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateFleet_591703 = ref object of OpenApiRestCall_591364
proc url_AssociateFleet_591705(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateFleet_591704(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591830 = header.getOrDefault("X-Amz-Target")
  valid_591830 = validateParameter(valid_591830, JString, required = true, default = newJString(
      "PhotonAdminProxyService.AssociateFleet"))
  if valid_591830 != nil:
    section.add "X-Amz-Target", valid_591830
  var valid_591831 = header.getOrDefault("X-Amz-Signature")
  valid_591831 = validateParameter(valid_591831, JString, required = false,
                                 default = nil)
  if valid_591831 != nil:
    section.add "X-Amz-Signature", valid_591831
  var valid_591832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591832 = validateParameter(valid_591832, JString, required = false,
                                 default = nil)
  if valid_591832 != nil:
    section.add "X-Amz-Content-Sha256", valid_591832
  var valid_591833 = header.getOrDefault("X-Amz-Date")
  valid_591833 = validateParameter(valid_591833, JString, required = false,
                                 default = nil)
  if valid_591833 != nil:
    section.add "X-Amz-Date", valid_591833
  var valid_591834 = header.getOrDefault("X-Amz-Credential")
  valid_591834 = validateParameter(valid_591834, JString, required = false,
                                 default = nil)
  if valid_591834 != nil:
    section.add "X-Amz-Credential", valid_591834
  var valid_591835 = header.getOrDefault("X-Amz-Security-Token")
  valid_591835 = validateParameter(valid_591835, JString, required = false,
                                 default = nil)
  if valid_591835 != nil:
    section.add "X-Amz-Security-Token", valid_591835
  var valid_591836 = header.getOrDefault("X-Amz-Algorithm")
  valid_591836 = validateParameter(valid_591836, JString, required = false,
                                 default = nil)
  if valid_591836 != nil:
    section.add "X-Amz-Algorithm", valid_591836
  var valid_591837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591837 = validateParameter(valid_591837, JString, required = false,
                                 default = nil)
  if valid_591837 != nil:
    section.add "X-Amz-SignedHeaders", valid_591837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591861: Call_AssociateFleet_591703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified fleet with the specified stack.
  ## 
  let valid = call_591861.validator(path, query, header, formData, body)
  let scheme = call_591861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591861.url(scheme.get, call_591861.host, call_591861.base,
                         call_591861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591861, url, valid)

proc call*(call_591932: Call_AssociateFleet_591703; body: JsonNode): Recallable =
  ## associateFleet
  ## Associates the specified fleet with the specified stack.
  ##   body: JObject (required)
  var body_591933 = newJObject()
  if body != nil:
    body_591933 = body
  result = call_591932.call(nil, nil, nil, nil, body_591933)

var associateFleet* = Call_AssociateFleet_591703(name: "associateFleet",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.AssociateFleet",
    validator: validate_AssociateFleet_591704, base: "/", url: url_AssociateFleet_591705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchAssociateUserStack_591972 = ref object of OpenApiRestCall_591364
proc url_BatchAssociateUserStack_591974(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchAssociateUserStack_591973(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591975 = header.getOrDefault("X-Amz-Target")
  valid_591975 = validateParameter(valid_591975, JString, required = true, default = newJString(
      "PhotonAdminProxyService.BatchAssociateUserStack"))
  if valid_591975 != nil:
    section.add "X-Amz-Target", valid_591975
  var valid_591976 = header.getOrDefault("X-Amz-Signature")
  valid_591976 = validateParameter(valid_591976, JString, required = false,
                                 default = nil)
  if valid_591976 != nil:
    section.add "X-Amz-Signature", valid_591976
  var valid_591977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591977 = validateParameter(valid_591977, JString, required = false,
                                 default = nil)
  if valid_591977 != nil:
    section.add "X-Amz-Content-Sha256", valid_591977
  var valid_591978 = header.getOrDefault("X-Amz-Date")
  valid_591978 = validateParameter(valid_591978, JString, required = false,
                                 default = nil)
  if valid_591978 != nil:
    section.add "X-Amz-Date", valid_591978
  var valid_591979 = header.getOrDefault("X-Amz-Credential")
  valid_591979 = validateParameter(valid_591979, JString, required = false,
                                 default = nil)
  if valid_591979 != nil:
    section.add "X-Amz-Credential", valid_591979
  var valid_591980 = header.getOrDefault("X-Amz-Security-Token")
  valid_591980 = validateParameter(valid_591980, JString, required = false,
                                 default = nil)
  if valid_591980 != nil:
    section.add "X-Amz-Security-Token", valid_591980
  var valid_591981 = header.getOrDefault("X-Amz-Algorithm")
  valid_591981 = validateParameter(valid_591981, JString, required = false,
                                 default = nil)
  if valid_591981 != nil:
    section.add "X-Amz-Algorithm", valid_591981
  var valid_591982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591982 = validateParameter(valid_591982, JString, required = false,
                                 default = nil)
  if valid_591982 != nil:
    section.add "X-Amz-SignedHeaders", valid_591982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591984: Call_BatchAssociateUserStack_591972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified users with the specified stacks. Users in a user pool cannot be assigned to stacks with fleets that are joined to an Active Directory domain.
  ## 
  let valid = call_591984.validator(path, query, header, formData, body)
  let scheme = call_591984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591984.url(scheme.get, call_591984.host, call_591984.base,
                         call_591984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591984, url, valid)

proc call*(call_591985: Call_BatchAssociateUserStack_591972; body: JsonNode): Recallable =
  ## batchAssociateUserStack
  ## Associates the specified users with the specified stacks. Users in a user pool cannot be assigned to stacks with fleets that are joined to an Active Directory domain.
  ##   body: JObject (required)
  var body_591986 = newJObject()
  if body != nil:
    body_591986 = body
  result = call_591985.call(nil, nil, nil, nil, body_591986)

var batchAssociateUserStack* = Call_BatchAssociateUserStack_591972(
    name: "batchAssociateUserStack", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.BatchAssociateUserStack",
    validator: validate_BatchAssociateUserStack_591973, base: "/",
    url: url_BatchAssociateUserStack_591974, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDisassociateUserStack_591987 = ref object of OpenApiRestCall_591364
proc url_BatchDisassociateUserStack_591989(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDisassociateUserStack_591988(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591990 = header.getOrDefault("X-Amz-Target")
  valid_591990 = validateParameter(valid_591990, JString, required = true, default = newJString(
      "PhotonAdminProxyService.BatchDisassociateUserStack"))
  if valid_591990 != nil:
    section.add "X-Amz-Target", valid_591990
  var valid_591991 = header.getOrDefault("X-Amz-Signature")
  valid_591991 = validateParameter(valid_591991, JString, required = false,
                                 default = nil)
  if valid_591991 != nil:
    section.add "X-Amz-Signature", valid_591991
  var valid_591992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591992 = validateParameter(valid_591992, JString, required = false,
                                 default = nil)
  if valid_591992 != nil:
    section.add "X-Amz-Content-Sha256", valid_591992
  var valid_591993 = header.getOrDefault("X-Amz-Date")
  valid_591993 = validateParameter(valid_591993, JString, required = false,
                                 default = nil)
  if valid_591993 != nil:
    section.add "X-Amz-Date", valid_591993
  var valid_591994 = header.getOrDefault("X-Amz-Credential")
  valid_591994 = validateParameter(valid_591994, JString, required = false,
                                 default = nil)
  if valid_591994 != nil:
    section.add "X-Amz-Credential", valid_591994
  var valid_591995 = header.getOrDefault("X-Amz-Security-Token")
  valid_591995 = validateParameter(valid_591995, JString, required = false,
                                 default = nil)
  if valid_591995 != nil:
    section.add "X-Amz-Security-Token", valid_591995
  var valid_591996 = header.getOrDefault("X-Amz-Algorithm")
  valid_591996 = validateParameter(valid_591996, JString, required = false,
                                 default = nil)
  if valid_591996 != nil:
    section.add "X-Amz-Algorithm", valid_591996
  var valid_591997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591997 = validateParameter(valid_591997, JString, required = false,
                                 default = nil)
  if valid_591997 != nil:
    section.add "X-Amz-SignedHeaders", valid_591997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591999: Call_BatchDisassociateUserStack_591987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified users from the specified stacks.
  ## 
  let valid = call_591999.validator(path, query, header, formData, body)
  let scheme = call_591999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591999.url(scheme.get, call_591999.host, call_591999.base,
                         call_591999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591999, url, valid)

proc call*(call_592000: Call_BatchDisassociateUserStack_591987; body: JsonNode): Recallable =
  ## batchDisassociateUserStack
  ## Disassociates the specified users from the specified stacks.
  ##   body: JObject (required)
  var body_592001 = newJObject()
  if body != nil:
    body_592001 = body
  result = call_592000.call(nil, nil, nil, nil, body_592001)

var batchDisassociateUserStack* = Call_BatchDisassociateUserStack_591987(
    name: "batchDisassociateUserStack", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.BatchDisassociateUserStack",
    validator: validate_BatchDisassociateUserStack_591988, base: "/",
    url: url_BatchDisassociateUserStack_591989,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyImage_592002 = ref object of OpenApiRestCall_591364
proc url_CopyImage_592004(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CopyImage_592003(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592005 = header.getOrDefault("X-Amz-Target")
  valid_592005 = validateParameter(valid_592005, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CopyImage"))
  if valid_592005 != nil:
    section.add "X-Amz-Target", valid_592005
  var valid_592006 = header.getOrDefault("X-Amz-Signature")
  valid_592006 = validateParameter(valid_592006, JString, required = false,
                                 default = nil)
  if valid_592006 != nil:
    section.add "X-Amz-Signature", valid_592006
  var valid_592007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592007 = validateParameter(valid_592007, JString, required = false,
                                 default = nil)
  if valid_592007 != nil:
    section.add "X-Amz-Content-Sha256", valid_592007
  var valid_592008 = header.getOrDefault("X-Amz-Date")
  valid_592008 = validateParameter(valid_592008, JString, required = false,
                                 default = nil)
  if valid_592008 != nil:
    section.add "X-Amz-Date", valid_592008
  var valid_592009 = header.getOrDefault("X-Amz-Credential")
  valid_592009 = validateParameter(valid_592009, JString, required = false,
                                 default = nil)
  if valid_592009 != nil:
    section.add "X-Amz-Credential", valid_592009
  var valid_592010 = header.getOrDefault("X-Amz-Security-Token")
  valid_592010 = validateParameter(valid_592010, JString, required = false,
                                 default = nil)
  if valid_592010 != nil:
    section.add "X-Amz-Security-Token", valid_592010
  var valid_592011 = header.getOrDefault("X-Amz-Algorithm")
  valid_592011 = validateParameter(valid_592011, JString, required = false,
                                 default = nil)
  if valid_592011 != nil:
    section.add "X-Amz-Algorithm", valid_592011
  var valid_592012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592012 = validateParameter(valid_592012, JString, required = false,
                                 default = nil)
  if valid_592012 != nil:
    section.add "X-Amz-SignedHeaders", valid_592012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592014: Call_CopyImage_592002; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the image within the same region or to a new region within the same AWS account. Note that any tags you added to the image will not be copied.
  ## 
  let valid = call_592014.validator(path, query, header, formData, body)
  let scheme = call_592014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592014.url(scheme.get, call_592014.host, call_592014.base,
                         call_592014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592014, url, valid)

proc call*(call_592015: Call_CopyImage_592002; body: JsonNode): Recallable =
  ## copyImage
  ## Copies the image within the same region or to a new region within the same AWS account. Note that any tags you added to the image will not be copied.
  ##   body: JObject (required)
  var body_592016 = newJObject()
  if body != nil:
    body_592016 = body
  result = call_592015.call(nil, nil, nil, nil, body_592016)

var copyImage* = Call_CopyImage_592002(name: "copyImage", meth: HttpMethod.HttpPost,
                                    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.CopyImage",
                                    validator: validate_CopyImage_592003,
                                    base: "/", url: url_CopyImage_592004,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectoryConfig_592017 = ref object of OpenApiRestCall_591364
proc url_CreateDirectoryConfig_592019(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDirectoryConfig_592018(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592020 = header.getOrDefault("X-Amz-Target")
  valid_592020 = validateParameter(valid_592020, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CreateDirectoryConfig"))
  if valid_592020 != nil:
    section.add "X-Amz-Target", valid_592020
  var valid_592021 = header.getOrDefault("X-Amz-Signature")
  valid_592021 = validateParameter(valid_592021, JString, required = false,
                                 default = nil)
  if valid_592021 != nil:
    section.add "X-Amz-Signature", valid_592021
  var valid_592022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592022 = validateParameter(valid_592022, JString, required = false,
                                 default = nil)
  if valid_592022 != nil:
    section.add "X-Amz-Content-Sha256", valid_592022
  var valid_592023 = header.getOrDefault("X-Amz-Date")
  valid_592023 = validateParameter(valid_592023, JString, required = false,
                                 default = nil)
  if valid_592023 != nil:
    section.add "X-Amz-Date", valid_592023
  var valid_592024 = header.getOrDefault("X-Amz-Credential")
  valid_592024 = validateParameter(valid_592024, JString, required = false,
                                 default = nil)
  if valid_592024 != nil:
    section.add "X-Amz-Credential", valid_592024
  var valid_592025 = header.getOrDefault("X-Amz-Security-Token")
  valid_592025 = validateParameter(valid_592025, JString, required = false,
                                 default = nil)
  if valid_592025 != nil:
    section.add "X-Amz-Security-Token", valid_592025
  var valid_592026 = header.getOrDefault("X-Amz-Algorithm")
  valid_592026 = validateParameter(valid_592026, JString, required = false,
                                 default = nil)
  if valid_592026 != nil:
    section.add "X-Amz-Algorithm", valid_592026
  var valid_592027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592027 = validateParameter(valid_592027, JString, required = false,
                                 default = nil)
  if valid_592027 != nil:
    section.add "X-Amz-SignedHeaders", valid_592027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592029: Call_CreateDirectoryConfig_592017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Directory Config object in AppStream 2.0. This object includes the configuration information required to join fleets and image builders to Microsoft Active Directory domains.
  ## 
  let valid = call_592029.validator(path, query, header, formData, body)
  let scheme = call_592029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592029.url(scheme.get, call_592029.host, call_592029.base,
                         call_592029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592029, url, valid)

proc call*(call_592030: Call_CreateDirectoryConfig_592017; body: JsonNode): Recallable =
  ## createDirectoryConfig
  ## Creates a Directory Config object in AppStream 2.0. This object includes the configuration information required to join fleets and image builders to Microsoft Active Directory domains.
  ##   body: JObject (required)
  var body_592031 = newJObject()
  if body != nil:
    body_592031 = body
  result = call_592030.call(nil, nil, nil, nil, body_592031)

var createDirectoryConfig* = Call_CreateDirectoryConfig_592017(
    name: "createDirectoryConfig", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.CreateDirectoryConfig",
    validator: validate_CreateDirectoryConfig_592018, base: "/",
    url: url_CreateDirectoryConfig_592019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFleet_592032 = ref object of OpenApiRestCall_591364
proc url_CreateFleet_592034(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateFleet_592033(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592035 = header.getOrDefault("X-Amz-Target")
  valid_592035 = validateParameter(valid_592035, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CreateFleet"))
  if valid_592035 != nil:
    section.add "X-Amz-Target", valid_592035
  var valid_592036 = header.getOrDefault("X-Amz-Signature")
  valid_592036 = validateParameter(valid_592036, JString, required = false,
                                 default = nil)
  if valid_592036 != nil:
    section.add "X-Amz-Signature", valid_592036
  var valid_592037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592037 = validateParameter(valid_592037, JString, required = false,
                                 default = nil)
  if valid_592037 != nil:
    section.add "X-Amz-Content-Sha256", valid_592037
  var valid_592038 = header.getOrDefault("X-Amz-Date")
  valid_592038 = validateParameter(valid_592038, JString, required = false,
                                 default = nil)
  if valid_592038 != nil:
    section.add "X-Amz-Date", valid_592038
  var valid_592039 = header.getOrDefault("X-Amz-Credential")
  valid_592039 = validateParameter(valid_592039, JString, required = false,
                                 default = nil)
  if valid_592039 != nil:
    section.add "X-Amz-Credential", valid_592039
  var valid_592040 = header.getOrDefault("X-Amz-Security-Token")
  valid_592040 = validateParameter(valid_592040, JString, required = false,
                                 default = nil)
  if valid_592040 != nil:
    section.add "X-Amz-Security-Token", valid_592040
  var valid_592041 = header.getOrDefault("X-Amz-Algorithm")
  valid_592041 = validateParameter(valid_592041, JString, required = false,
                                 default = nil)
  if valid_592041 != nil:
    section.add "X-Amz-Algorithm", valid_592041
  var valid_592042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592042 = validateParameter(valid_592042, JString, required = false,
                                 default = nil)
  if valid_592042 != nil:
    section.add "X-Amz-SignedHeaders", valid_592042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592044: Call_CreateFleet_592032; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a fleet. A fleet consists of streaming instances that run a specified image.
  ## 
  let valid = call_592044.validator(path, query, header, formData, body)
  let scheme = call_592044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592044.url(scheme.get, call_592044.host, call_592044.base,
                         call_592044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592044, url, valid)

proc call*(call_592045: Call_CreateFleet_592032; body: JsonNode): Recallable =
  ## createFleet
  ## Creates a fleet. A fleet consists of streaming instances that run a specified image.
  ##   body: JObject (required)
  var body_592046 = newJObject()
  if body != nil:
    body_592046 = body
  result = call_592045.call(nil, nil, nil, nil, body_592046)

var createFleet* = Call_CreateFleet_592032(name: "createFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.CreateFleet",
                                        validator: validate_CreateFleet_592033,
                                        base: "/", url: url_CreateFleet_592034,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImageBuilder_592047 = ref object of OpenApiRestCall_591364
proc url_CreateImageBuilder_592049(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateImageBuilder_592048(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592050 = header.getOrDefault("X-Amz-Target")
  valid_592050 = validateParameter(valid_592050, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CreateImageBuilder"))
  if valid_592050 != nil:
    section.add "X-Amz-Target", valid_592050
  var valid_592051 = header.getOrDefault("X-Amz-Signature")
  valid_592051 = validateParameter(valid_592051, JString, required = false,
                                 default = nil)
  if valid_592051 != nil:
    section.add "X-Amz-Signature", valid_592051
  var valid_592052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592052 = validateParameter(valid_592052, JString, required = false,
                                 default = nil)
  if valid_592052 != nil:
    section.add "X-Amz-Content-Sha256", valid_592052
  var valid_592053 = header.getOrDefault("X-Amz-Date")
  valid_592053 = validateParameter(valid_592053, JString, required = false,
                                 default = nil)
  if valid_592053 != nil:
    section.add "X-Amz-Date", valid_592053
  var valid_592054 = header.getOrDefault("X-Amz-Credential")
  valid_592054 = validateParameter(valid_592054, JString, required = false,
                                 default = nil)
  if valid_592054 != nil:
    section.add "X-Amz-Credential", valid_592054
  var valid_592055 = header.getOrDefault("X-Amz-Security-Token")
  valid_592055 = validateParameter(valid_592055, JString, required = false,
                                 default = nil)
  if valid_592055 != nil:
    section.add "X-Amz-Security-Token", valid_592055
  var valid_592056 = header.getOrDefault("X-Amz-Algorithm")
  valid_592056 = validateParameter(valid_592056, JString, required = false,
                                 default = nil)
  if valid_592056 != nil:
    section.add "X-Amz-Algorithm", valid_592056
  var valid_592057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592057 = validateParameter(valid_592057, JString, required = false,
                                 default = nil)
  if valid_592057 != nil:
    section.add "X-Amz-SignedHeaders", valid_592057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592059: Call_CreateImageBuilder_592047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an image builder. An image builder is a virtual machine that is used to create an image.</p> <p>The initial state of the builder is <code>PENDING</code>. When it is ready, the state is <code>RUNNING</code>.</p>
  ## 
  let valid = call_592059.validator(path, query, header, formData, body)
  let scheme = call_592059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592059.url(scheme.get, call_592059.host, call_592059.base,
                         call_592059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592059, url, valid)

proc call*(call_592060: Call_CreateImageBuilder_592047; body: JsonNode): Recallable =
  ## createImageBuilder
  ## <p>Creates an image builder. An image builder is a virtual machine that is used to create an image.</p> <p>The initial state of the builder is <code>PENDING</code>. When it is ready, the state is <code>RUNNING</code>.</p>
  ##   body: JObject (required)
  var body_592061 = newJObject()
  if body != nil:
    body_592061 = body
  result = call_592060.call(nil, nil, nil, nil, body_592061)

var createImageBuilder* = Call_CreateImageBuilder_592047(
    name: "createImageBuilder", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.CreateImageBuilder",
    validator: validate_CreateImageBuilder_592048, base: "/",
    url: url_CreateImageBuilder_592049, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImageBuilderStreamingURL_592062 = ref object of OpenApiRestCall_591364
proc url_CreateImageBuilderStreamingURL_592064(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateImageBuilderStreamingURL_592063(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592065 = header.getOrDefault("X-Amz-Target")
  valid_592065 = validateParameter(valid_592065, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CreateImageBuilderStreamingURL"))
  if valid_592065 != nil:
    section.add "X-Amz-Target", valid_592065
  var valid_592066 = header.getOrDefault("X-Amz-Signature")
  valid_592066 = validateParameter(valid_592066, JString, required = false,
                                 default = nil)
  if valid_592066 != nil:
    section.add "X-Amz-Signature", valid_592066
  var valid_592067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592067 = validateParameter(valid_592067, JString, required = false,
                                 default = nil)
  if valid_592067 != nil:
    section.add "X-Amz-Content-Sha256", valid_592067
  var valid_592068 = header.getOrDefault("X-Amz-Date")
  valid_592068 = validateParameter(valid_592068, JString, required = false,
                                 default = nil)
  if valid_592068 != nil:
    section.add "X-Amz-Date", valid_592068
  var valid_592069 = header.getOrDefault("X-Amz-Credential")
  valid_592069 = validateParameter(valid_592069, JString, required = false,
                                 default = nil)
  if valid_592069 != nil:
    section.add "X-Amz-Credential", valid_592069
  var valid_592070 = header.getOrDefault("X-Amz-Security-Token")
  valid_592070 = validateParameter(valid_592070, JString, required = false,
                                 default = nil)
  if valid_592070 != nil:
    section.add "X-Amz-Security-Token", valid_592070
  var valid_592071 = header.getOrDefault("X-Amz-Algorithm")
  valid_592071 = validateParameter(valid_592071, JString, required = false,
                                 default = nil)
  if valid_592071 != nil:
    section.add "X-Amz-Algorithm", valid_592071
  var valid_592072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592072 = validateParameter(valid_592072, JString, required = false,
                                 default = nil)
  if valid_592072 != nil:
    section.add "X-Amz-SignedHeaders", valid_592072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592074: Call_CreateImageBuilderStreamingURL_592062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a URL to start an image builder streaming session.
  ## 
  let valid = call_592074.validator(path, query, header, formData, body)
  let scheme = call_592074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592074.url(scheme.get, call_592074.host, call_592074.base,
                         call_592074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592074, url, valid)

proc call*(call_592075: Call_CreateImageBuilderStreamingURL_592062; body: JsonNode): Recallable =
  ## createImageBuilderStreamingURL
  ## Creates a URL to start an image builder streaming session.
  ##   body: JObject (required)
  var body_592076 = newJObject()
  if body != nil:
    body_592076 = body
  result = call_592075.call(nil, nil, nil, nil, body_592076)

var createImageBuilderStreamingURL* = Call_CreateImageBuilderStreamingURL_592062(
    name: "createImageBuilderStreamingURL", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.CreateImageBuilderStreamingURL",
    validator: validate_CreateImageBuilderStreamingURL_592063, base: "/",
    url: url_CreateImageBuilderStreamingURL_592064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStack_592077 = ref object of OpenApiRestCall_591364
proc url_CreateStack_592079(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateStack_592078(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592080 = header.getOrDefault("X-Amz-Target")
  valid_592080 = validateParameter(valid_592080, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CreateStack"))
  if valid_592080 != nil:
    section.add "X-Amz-Target", valid_592080
  var valid_592081 = header.getOrDefault("X-Amz-Signature")
  valid_592081 = validateParameter(valid_592081, JString, required = false,
                                 default = nil)
  if valid_592081 != nil:
    section.add "X-Amz-Signature", valid_592081
  var valid_592082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592082 = validateParameter(valid_592082, JString, required = false,
                                 default = nil)
  if valid_592082 != nil:
    section.add "X-Amz-Content-Sha256", valid_592082
  var valid_592083 = header.getOrDefault("X-Amz-Date")
  valid_592083 = validateParameter(valid_592083, JString, required = false,
                                 default = nil)
  if valid_592083 != nil:
    section.add "X-Amz-Date", valid_592083
  var valid_592084 = header.getOrDefault("X-Amz-Credential")
  valid_592084 = validateParameter(valid_592084, JString, required = false,
                                 default = nil)
  if valid_592084 != nil:
    section.add "X-Amz-Credential", valid_592084
  var valid_592085 = header.getOrDefault("X-Amz-Security-Token")
  valid_592085 = validateParameter(valid_592085, JString, required = false,
                                 default = nil)
  if valid_592085 != nil:
    section.add "X-Amz-Security-Token", valid_592085
  var valid_592086 = header.getOrDefault("X-Amz-Algorithm")
  valid_592086 = validateParameter(valid_592086, JString, required = false,
                                 default = nil)
  if valid_592086 != nil:
    section.add "X-Amz-Algorithm", valid_592086
  var valid_592087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592087 = validateParameter(valid_592087, JString, required = false,
                                 default = nil)
  if valid_592087 != nil:
    section.add "X-Amz-SignedHeaders", valid_592087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592089: Call_CreateStack_592077; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a stack to start streaming applications to users. A stack consists of an associated fleet, user access policies, and storage configurations. 
  ## 
  let valid = call_592089.validator(path, query, header, formData, body)
  let scheme = call_592089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592089.url(scheme.get, call_592089.host, call_592089.base,
                         call_592089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592089, url, valid)

proc call*(call_592090: Call_CreateStack_592077; body: JsonNode): Recallable =
  ## createStack
  ## Creates a stack to start streaming applications to users. A stack consists of an associated fleet, user access policies, and storage configurations. 
  ##   body: JObject (required)
  var body_592091 = newJObject()
  if body != nil:
    body_592091 = body
  result = call_592090.call(nil, nil, nil, nil, body_592091)

var createStack* = Call_CreateStack_592077(name: "createStack",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.CreateStack",
                                        validator: validate_CreateStack_592078,
                                        base: "/", url: url_CreateStack_592079,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingURL_592092 = ref object of OpenApiRestCall_591364
proc url_CreateStreamingURL_592094(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateStreamingURL_592093(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592095 = header.getOrDefault("X-Amz-Target")
  valid_592095 = validateParameter(valid_592095, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CreateStreamingURL"))
  if valid_592095 != nil:
    section.add "X-Amz-Target", valid_592095
  var valid_592096 = header.getOrDefault("X-Amz-Signature")
  valid_592096 = validateParameter(valid_592096, JString, required = false,
                                 default = nil)
  if valid_592096 != nil:
    section.add "X-Amz-Signature", valid_592096
  var valid_592097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592097 = validateParameter(valid_592097, JString, required = false,
                                 default = nil)
  if valid_592097 != nil:
    section.add "X-Amz-Content-Sha256", valid_592097
  var valid_592098 = header.getOrDefault("X-Amz-Date")
  valid_592098 = validateParameter(valid_592098, JString, required = false,
                                 default = nil)
  if valid_592098 != nil:
    section.add "X-Amz-Date", valid_592098
  var valid_592099 = header.getOrDefault("X-Amz-Credential")
  valid_592099 = validateParameter(valid_592099, JString, required = false,
                                 default = nil)
  if valid_592099 != nil:
    section.add "X-Amz-Credential", valid_592099
  var valid_592100 = header.getOrDefault("X-Amz-Security-Token")
  valid_592100 = validateParameter(valid_592100, JString, required = false,
                                 default = nil)
  if valid_592100 != nil:
    section.add "X-Amz-Security-Token", valid_592100
  var valid_592101 = header.getOrDefault("X-Amz-Algorithm")
  valid_592101 = validateParameter(valid_592101, JString, required = false,
                                 default = nil)
  if valid_592101 != nil:
    section.add "X-Amz-Algorithm", valid_592101
  var valid_592102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592102 = validateParameter(valid_592102, JString, required = false,
                                 default = nil)
  if valid_592102 != nil:
    section.add "X-Amz-SignedHeaders", valid_592102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592104: Call_CreateStreamingURL_592092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a temporary URL to start an AppStream 2.0 streaming session for the specified user. A streaming URL enables application streaming to be tested without user setup. 
  ## 
  let valid = call_592104.validator(path, query, header, formData, body)
  let scheme = call_592104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592104.url(scheme.get, call_592104.host, call_592104.base,
                         call_592104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592104, url, valid)

proc call*(call_592105: Call_CreateStreamingURL_592092; body: JsonNode): Recallable =
  ## createStreamingURL
  ## Creates a temporary URL to start an AppStream 2.0 streaming session for the specified user. A streaming URL enables application streaming to be tested without user setup. 
  ##   body: JObject (required)
  var body_592106 = newJObject()
  if body != nil:
    body_592106 = body
  result = call_592105.call(nil, nil, nil, nil, body_592106)

var createStreamingURL* = Call_CreateStreamingURL_592092(
    name: "createStreamingURL", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.CreateStreamingURL",
    validator: validate_CreateStreamingURL_592093, base: "/",
    url: url_CreateStreamingURL_592094, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsageReportSubscription_592107 = ref object of OpenApiRestCall_591364
proc url_CreateUsageReportSubscription_592109(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateUsageReportSubscription_592108(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592110 = header.getOrDefault("X-Amz-Target")
  valid_592110 = validateParameter(valid_592110, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CreateUsageReportSubscription"))
  if valid_592110 != nil:
    section.add "X-Amz-Target", valid_592110
  var valid_592111 = header.getOrDefault("X-Amz-Signature")
  valid_592111 = validateParameter(valid_592111, JString, required = false,
                                 default = nil)
  if valid_592111 != nil:
    section.add "X-Amz-Signature", valid_592111
  var valid_592112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592112 = validateParameter(valid_592112, JString, required = false,
                                 default = nil)
  if valid_592112 != nil:
    section.add "X-Amz-Content-Sha256", valid_592112
  var valid_592113 = header.getOrDefault("X-Amz-Date")
  valid_592113 = validateParameter(valid_592113, JString, required = false,
                                 default = nil)
  if valid_592113 != nil:
    section.add "X-Amz-Date", valid_592113
  var valid_592114 = header.getOrDefault("X-Amz-Credential")
  valid_592114 = validateParameter(valid_592114, JString, required = false,
                                 default = nil)
  if valid_592114 != nil:
    section.add "X-Amz-Credential", valid_592114
  var valid_592115 = header.getOrDefault("X-Amz-Security-Token")
  valid_592115 = validateParameter(valid_592115, JString, required = false,
                                 default = nil)
  if valid_592115 != nil:
    section.add "X-Amz-Security-Token", valid_592115
  var valid_592116 = header.getOrDefault("X-Amz-Algorithm")
  valid_592116 = validateParameter(valid_592116, JString, required = false,
                                 default = nil)
  if valid_592116 != nil:
    section.add "X-Amz-Algorithm", valid_592116
  var valid_592117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592117 = validateParameter(valid_592117, JString, required = false,
                                 default = nil)
  if valid_592117 != nil:
    section.add "X-Amz-SignedHeaders", valid_592117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592119: Call_CreateUsageReportSubscription_592107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a usage report subscription. Usage reports are generated daily.
  ## 
  let valid = call_592119.validator(path, query, header, formData, body)
  let scheme = call_592119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592119.url(scheme.get, call_592119.host, call_592119.base,
                         call_592119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592119, url, valid)

proc call*(call_592120: Call_CreateUsageReportSubscription_592107; body: JsonNode): Recallable =
  ## createUsageReportSubscription
  ## Creates a usage report subscription. Usage reports are generated daily.
  ##   body: JObject (required)
  var body_592121 = newJObject()
  if body != nil:
    body_592121 = body
  result = call_592120.call(nil, nil, nil, nil, body_592121)

var createUsageReportSubscription* = Call_CreateUsageReportSubscription_592107(
    name: "createUsageReportSubscription", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.CreateUsageReportSubscription",
    validator: validate_CreateUsageReportSubscription_592108, base: "/",
    url: url_CreateUsageReportSubscription_592109,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_592122 = ref object of OpenApiRestCall_591364
proc url_CreateUser_592124(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateUser_592123(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592125 = header.getOrDefault("X-Amz-Target")
  valid_592125 = validateParameter(valid_592125, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CreateUser"))
  if valid_592125 != nil:
    section.add "X-Amz-Target", valid_592125
  var valid_592126 = header.getOrDefault("X-Amz-Signature")
  valid_592126 = validateParameter(valid_592126, JString, required = false,
                                 default = nil)
  if valid_592126 != nil:
    section.add "X-Amz-Signature", valid_592126
  var valid_592127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592127 = validateParameter(valid_592127, JString, required = false,
                                 default = nil)
  if valid_592127 != nil:
    section.add "X-Amz-Content-Sha256", valid_592127
  var valid_592128 = header.getOrDefault("X-Amz-Date")
  valid_592128 = validateParameter(valid_592128, JString, required = false,
                                 default = nil)
  if valid_592128 != nil:
    section.add "X-Amz-Date", valid_592128
  var valid_592129 = header.getOrDefault("X-Amz-Credential")
  valid_592129 = validateParameter(valid_592129, JString, required = false,
                                 default = nil)
  if valid_592129 != nil:
    section.add "X-Amz-Credential", valid_592129
  var valid_592130 = header.getOrDefault("X-Amz-Security-Token")
  valid_592130 = validateParameter(valid_592130, JString, required = false,
                                 default = nil)
  if valid_592130 != nil:
    section.add "X-Amz-Security-Token", valid_592130
  var valid_592131 = header.getOrDefault("X-Amz-Algorithm")
  valid_592131 = validateParameter(valid_592131, JString, required = false,
                                 default = nil)
  if valid_592131 != nil:
    section.add "X-Amz-Algorithm", valid_592131
  var valid_592132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592132 = validateParameter(valid_592132, JString, required = false,
                                 default = nil)
  if valid_592132 != nil:
    section.add "X-Amz-SignedHeaders", valid_592132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592134: Call_CreateUser_592122; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new user in the user pool.
  ## 
  let valid = call_592134.validator(path, query, header, formData, body)
  let scheme = call_592134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592134.url(scheme.get, call_592134.host, call_592134.base,
                         call_592134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592134, url, valid)

proc call*(call_592135: Call_CreateUser_592122; body: JsonNode): Recallable =
  ## createUser
  ## Creates a new user in the user pool.
  ##   body: JObject (required)
  var body_592136 = newJObject()
  if body != nil:
    body_592136 = body
  result = call_592135.call(nil, nil, nil, nil, body_592136)

var createUser* = Call_CreateUser_592122(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.CreateUser",
                                      validator: validate_CreateUser_592123,
                                      base: "/", url: url_CreateUser_592124,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectoryConfig_592137 = ref object of OpenApiRestCall_591364
proc url_DeleteDirectoryConfig_592139(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDirectoryConfig_592138(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592140 = header.getOrDefault("X-Amz-Target")
  valid_592140 = validateParameter(valid_592140, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteDirectoryConfig"))
  if valid_592140 != nil:
    section.add "X-Amz-Target", valid_592140
  var valid_592141 = header.getOrDefault("X-Amz-Signature")
  valid_592141 = validateParameter(valid_592141, JString, required = false,
                                 default = nil)
  if valid_592141 != nil:
    section.add "X-Amz-Signature", valid_592141
  var valid_592142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592142 = validateParameter(valid_592142, JString, required = false,
                                 default = nil)
  if valid_592142 != nil:
    section.add "X-Amz-Content-Sha256", valid_592142
  var valid_592143 = header.getOrDefault("X-Amz-Date")
  valid_592143 = validateParameter(valid_592143, JString, required = false,
                                 default = nil)
  if valid_592143 != nil:
    section.add "X-Amz-Date", valid_592143
  var valid_592144 = header.getOrDefault("X-Amz-Credential")
  valid_592144 = validateParameter(valid_592144, JString, required = false,
                                 default = nil)
  if valid_592144 != nil:
    section.add "X-Amz-Credential", valid_592144
  var valid_592145 = header.getOrDefault("X-Amz-Security-Token")
  valid_592145 = validateParameter(valid_592145, JString, required = false,
                                 default = nil)
  if valid_592145 != nil:
    section.add "X-Amz-Security-Token", valid_592145
  var valid_592146 = header.getOrDefault("X-Amz-Algorithm")
  valid_592146 = validateParameter(valid_592146, JString, required = false,
                                 default = nil)
  if valid_592146 != nil:
    section.add "X-Amz-Algorithm", valid_592146
  var valid_592147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592147 = validateParameter(valid_592147, JString, required = false,
                                 default = nil)
  if valid_592147 != nil:
    section.add "X-Amz-SignedHeaders", valid_592147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592149: Call_DeleteDirectoryConfig_592137; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Directory Config object from AppStream 2.0. This object includes the information required to join streaming instances to an Active Directory domain.
  ## 
  let valid = call_592149.validator(path, query, header, formData, body)
  let scheme = call_592149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592149.url(scheme.get, call_592149.host, call_592149.base,
                         call_592149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592149, url, valid)

proc call*(call_592150: Call_DeleteDirectoryConfig_592137; body: JsonNode): Recallable =
  ## deleteDirectoryConfig
  ## Deletes the specified Directory Config object from AppStream 2.0. This object includes the information required to join streaming instances to an Active Directory domain.
  ##   body: JObject (required)
  var body_592151 = newJObject()
  if body != nil:
    body_592151 = body
  result = call_592150.call(nil, nil, nil, nil, body_592151)

var deleteDirectoryConfig* = Call_DeleteDirectoryConfig_592137(
    name: "deleteDirectoryConfig", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteDirectoryConfig",
    validator: validate_DeleteDirectoryConfig_592138, base: "/",
    url: url_DeleteDirectoryConfig_592139, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFleet_592152 = ref object of OpenApiRestCall_591364
proc url_DeleteFleet_592154(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteFleet_592153(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592155 = header.getOrDefault("X-Amz-Target")
  valid_592155 = validateParameter(valid_592155, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteFleet"))
  if valid_592155 != nil:
    section.add "X-Amz-Target", valid_592155
  var valid_592156 = header.getOrDefault("X-Amz-Signature")
  valid_592156 = validateParameter(valid_592156, JString, required = false,
                                 default = nil)
  if valid_592156 != nil:
    section.add "X-Amz-Signature", valid_592156
  var valid_592157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592157 = validateParameter(valid_592157, JString, required = false,
                                 default = nil)
  if valid_592157 != nil:
    section.add "X-Amz-Content-Sha256", valid_592157
  var valid_592158 = header.getOrDefault("X-Amz-Date")
  valid_592158 = validateParameter(valid_592158, JString, required = false,
                                 default = nil)
  if valid_592158 != nil:
    section.add "X-Amz-Date", valid_592158
  var valid_592159 = header.getOrDefault("X-Amz-Credential")
  valid_592159 = validateParameter(valid_592159, JString, required = false,
                                 default = nil)
  if valid_592159 != nil:
    section.add "X-Amz-Credential", valid_592159
  var valid_592160 = header.getOrDefault("X-Amz-Security-Token")
  valid_592160 = validateParameter(valid_592160, JString, required = false,
                                 default = nil)
  if valid_592160 != nil:
    section.add "X-Amz-Security-Token", valid_592160
  var valid_592161 = header.getOrDefault("X-Amz-Algorithm")
  valid_592161 = validateParameter(valid_592161, JString, required = false,
                                 default = nil)
  if valid_592161 != nil:
    section.add "X-Amz-Algorithm", valid_592161
  var valid_592162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592162 = validateParameter(valid_592162, JString, required = false,
                                 default = nil)
  if valid_592162 != nil:
    section.add "X-Amz-SignedHeaders", valid_592162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592164: Call_DeleteFleet_592152; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified fleet.
  ## 
  let valid = call_592164.validator(path, query, header, formData, body)
  let scheme = call_592164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592164.url(scheme.get, call_592164.host, call_592164.base,
                         call_592164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592164, url, valid)

proc call*(call_592165: Call_DeleteFleet_592152; body: JsonNode): Recallable =
  ## deleteFleet
  ## Deletes the specified fleet.
  ##   body: JObject (required)
  var body_592166 = newJObject()
  if body != nil:
    body_592166 = body
  result = call_592165.call(nil, nil, nil, nil, body_592166)

var deleteFleet* = Call_DeleteFleet_592152(name: "deleteFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteFleet",
                                        validator: validate_DeleteFleet_592153,
                                        base: "/", url: url_DeleteFleet_592154,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImage_592167 = ref object of OpenApiRestCall_591364
proc url_DeleteImage_592169(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteImage_592168(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592170 = header.getOrDefault("X-Amz-Target")
  valid_592170 = validateParameter(valid_592170, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteImage"))
  if valid_592170 != nil:
    section.add "X-Amz-Target", valid_592170
  var valid_592171 = header.getOrDefault("X-Amz-Signature")
  valid_592171 = validateParameter(valid_592171, JString, required = false,
                                 default = nil)
  if valid_592171 != nil:
    section.add "X-Amz-Signature", valid_592171
  var valid_592172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592172 = validateParameter(valid_592172, JString, required = false,
                                 default = nil)
  if valid_592172 != nil:
    section.add "X-Amz-Content-Sha256", valid_592172
  var valid_592173 = header.getOrDefault("X-Amz-Date")
  valid_592173 = validateParameter(valid_592173, JString, required = false,
                                 default = nil)
  if valid_592173 != nil:
    section.add "X-Amz-Date", valid_592173
  var valid_592174 = header.getOrDefault("X-Amz-Credential")
  valid_592174 = validateParameter(valid_592174, JString, required = false,
                                 default = nil)
  if valid_592174 != nil:
    section.add "X-Amz-Credential", valid_592174
  var valid_592175 = header.getOrDefault("X-Amz-Security-Token")
  valid_592175 = validateParameter(valid_592175, JString, required = false,
                                 default = nil)
  if valid_592175 != nil:
    section.add "X-Amz-Security-Token", valid_592175
  var valid_592176 = header.getOrDefault("X-Amz-Algorithm")
  valid_592176 = validateParameter(valid_592176, JString, required = false,
                                 default = nil)
  if valid_592176 != nil:
    section.add "X-Amz-Algorithm", valid_592176
  var valid_592177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592177 = validateParameter(valid_592177, JString, required = false,
                                 default = nil)
  if valid_592177 != nil:
    section.add "X-Amz-SignedHeaders", valid_592177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592179: Call_DeleteImage_592167; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified image. You cannot delete an image when it is in use. After you delete an image, you cannot provision new capacity using the image.
  ## 
  let valid = call_592179.validator(path, query, header, formData, body)
  let scheme = call_592179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592179.url(scheme.get, call_592179.host, call_592179.base,
                         call_592179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592179, url, valid)

proc call*(call_592180: Call_DeleteImage_592167; body: JsonNode): Recallable =
  ## deleteImage
  ## Deletes the specified image. You cannot delete an image when it is in use. After you delete an image, you cannot provision new capacity using the image.
  ##   body: JObject (required)
  var body_592181 = newJObject()
  if body != nil:
    body_592181 = body
  result = call_592180.call(nil, nil, nil, nil, body_592181)

var deleteImage* = Call_DeleteImage_592167(name: "deleteImage",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteImage",
                                        validator: validate_DeleteImage_592168,
                                        base: "/", url: url_DeleteImage_592169,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImageBuilder_592182 = ref object of OpenApiRestCall_591364
proc url_DeleteImageBuilder_592184(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteImageBuilder_592183(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592185 = header.getOrDefault("X-Amz-Target")
  valid_592185 = validateParameter(valid_592185, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteImageBuilder"))
  if valid_592185 != nil:
    section.add "X-Amz-Target", valid_592185
  var valid_592186 = header.getOrDefault("X-Amz-Signature")
  valid_592186 = validateParameter(valid_592186, JString, required = false,
                                 default = nil)
  if valid_592186 != nil:
    section.add "X-Amz-Signature", valid_592186
  var valid_592187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592187 = validateParameter(valid_592187, JString, required = false,
                                 default = nil)
  if valid_592187 != nil:
    section.add "X-Amz-Content-Sha256", valid_592187
  var valid_592188 = header.getOrDefault("X-Amz-Date")
  valid_592188 = validateParameter(valid_592188, JString, required = false,
                                 default = nil)
  if valid_592188 != nil:
    section.add "X-Amz-Date", valid_592188
  var valid_592189 = header.getOrDefault("X-Amz-Credential")
  valid_592189 = validateParameter(valid_592189, JString, required = false,
                                 default = nil)
  if valid_592189 != nil:
    section.add "X-Amz-Credential", valid_592189
  var valid_592190 = header.getOrDefault("X-Amz-Security-Token")
  valid_592190 = validateParameter(valid_592190, JString, required = false,
                                 default = nil)
  if valid_592190 != nil:
    section.add "X-Amz-Security-Token", valid_592190
  var valid_592191 = header.getOrDefault("X-Amz-Algorithm")
  valid_592191 = validateParameter(valid_592191, JString, required = false,
                                 default = nil)
  if valid_592191 != nil:
    section.add "X-Amz-Algorithm", valid_592191
  var valid_592192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592192 = validateParameter(valid_592192, JString, required = false,
                                 default = nil)
  if valid_592192 != nil:
    section.add "X-Amz-SignedHeaders", valid_592192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592194: Call_DeleteImageBuilder_592182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified image builder and releases the capacity.
  ## 
  let valid = call_592194.validator(path, query, header, formData, body)
  let scheme = call_592194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592194.url(scheme.get, call_592194.host, call_592194.base,
                         call_592194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592194, url, valid)

proc call*(call_592195: Call_DeleteImageBuilder_592182; body: JsonNode): Recallable =
  ## deleteImageBuilder
  ## Deletes the specified image builder and releases the capacity.
  ##   body: JObject (required)
  var body_592196 = newJObject()
  if body != nil:
    body_592196 = body
  result = call_592195.call(nil, nil, nil, nil, body_592196)

var deleteImageBuilder* = Call_DeleteImageBuilder_592182(
    name: "deleteImageBuilder", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteImageBuilder",
    validator: validate_DeleteImageBuilder_592183, base: "/",
    url: url_DeleteImageBuilder_592184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImagePermissions_592197 = ref object of OpenApiRestCall_591364
proc url_DeleteImagePermissions_592199(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteImagePermissions_592198(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592200 = header.getOrDefault("X-Amz-Target")
  valid_592200 = validateParameter(valid_592200, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteImagePermissions"))
  if valid_592200 != nil:
    section.add "X-Amz-Target", valid_592200
  var valid_592201 = header.getOrDefault("X-Amz-Signature")
  valid_592201 = validateParameter(valid_592201, JString, required = false,
                                 default = nil)
  if valid_592201 != nil:
    section.add "X-Amz-Signature", valid_592201
  var valid_592202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592202 = validateParameter(valid_592202, JString, required = false,
                                 default = nil)
  if valid_592202 != nil:
    section.add "X-Amz-Content-Sha256", valid_592202
  var valid_592203 = header.getOrDefault("X-Amz-Date")
  valid_592203 = validateParameter(valid_592203, JString, required = false,
                                 default = nil)
  if valid_592203 != nil:
    section.add "X-Amz-Date", valid_592203
  var valid_592204 = header.getOrDefault("X-Amz-Credential")
  valid_592204 = validateParameter(valid_592204, JString, required = false,
                                 default = nil)
  if valid_592204 != nil:
    section.add "X-Amz-Credential", valid_592204
  var valid_592205 = header.getOrDefault("X-Amz-Security-Token")
  valid_592205 = validateParameter(valid_592205, JString, required = false,
                                 default = nil)
  if valid_592205 != nil:
    section.add "X-Amz-Security-Token", valid_592205
  var valid_592206 = header.getOrDefault("X-Amz-Algorithm")
  valid_592206 = validateParameter(valid_592206, JString, required = false,
                                 default = nil)
  if valid_592206 != nil:
    section.add "X-Amz-Algorithm", valid_592206
  var valid_592207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592207 = validateParameter(valid_592207, JString, required = false,
                                 default = nil)
  if valid_592207 != nil:
    section.add "X-Amz-SignedHeaders", valid_592207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592209: Call_DeleteImagePermissions_592197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes permissions for the specified private image. After you delete permissions for an image, AWS accounts to which you previously granted these permissions can no longer use the image.
  ## 
  let valid = call_592209.validator(path, query, header, formData, body)
  let scheme = call_592209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592209.url(scheme.get, call_592209.host, call_592209.base,
                         call_592209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592209, url, valid)

proc call*(call_592210: Call_DeleteImagePermissions_592197; body: JsonNode): Recallable =
  ## deleteImagePermissions
  ## Deletes permissions for the specified private image. After you delete permissions for an image, AWS accounts to which you previously granted these permissions can no longer use the image.
  ##   body: JObject (required)
  var body_592211 = newJObject()
  if body != nil:
    body_592211 = body
  result = call_592210.call(nil, nil, nil, nil, body_592211)

var deleteImagePermissions* = Call_DeleteImagePermissions_592197(
    name: "deleteImagePermissions", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteImagePermissions",
    validator: validate_DeleteImagePermissions_592198, base: "/",
    url: url_DeleteImagePermissions_592199, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStack_592212 = ref object of OpenApiRestCall_591364
proc url_DeleteStack_592214(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteStack_592213(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592215 = header.getOrDefault("X-Amz-Target")
  valid_592215 = validateParameter(valid_592215, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteStack"))
  if valid_592215 != nil:
    section.add "X-Amz-Target", valid_592215
  var valid_592216 = header.getOrDefault("X-Amz-Signature")
  valid_592216 = validateParameter(valid_592216, JString, required = false,
                                 default = nil)
  if valid_592216 != nil:
    section.add "X-Amz-Signature", valid_592216
  var valid_592217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592217 = validateParameter(valid_592217, JString, required = false,
                                 default = nil)
  if valid_592217 != nil:
    section.add "X-Amz-Content-Sha256", valid_592217
  var valid_592218 = header.getOrDefault("X-Amz-Date")
  valid_592218 = validateParameter(valid_592218, JString, required = false,
                                 default = nil)
  if valid_592218 != nil:
    section.add "X-Amz-Date", valid_592218
  var valid_592219 = header.getOrDefault("X-Amz-Credential")
  valid_592219 = validateParameter(valid_592219, JString, required = false,
                                 default = nil)
  if valid_592219 != nil:
    section.add "X-Amz-Credential", valid_592219
  var valid_592220 = header.getOrDefault("X-Amz-Security-Token")
  valid_592220 = validateParameter(valid_592220, JString, required = false,
                                 default = nil)
  if valid_592220 != nil:
    section.add "X-Amz-Security-Token", valid_592220
  var valid_592221 = header.getOrDefault("X-Amz-Algorithm")
  valid_592221 = validateParameter(valid_592221, JString, required = false,
                                 default = nil)
  if valid_592221 != nil:
    section.add "X-Amz-Algorithm", valid_592221
  var valid_592222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592222 = validateParameter(valid_592222, JString, required = false,
                                 default = nil)
  if valid_592222 != nil:
    section.add "X-Amz-SignedHeaders", valid_592222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592224: Call_DeleteStack_592212; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified stack. After the stack is deleted, the application streaming environment provided by the stack is no longer available to users. Also, any reservations made for application streaming sessions for the stack are released.
  ## 
  let valid = call_592224.validator(path, query, header, formData, body)
  let scheme = call_592224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592224.url(scheme.get, call_592224.host, call_592224.base,
                         call_592224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592224, url, valid)

proc call*(call_592225: Call_DeleteStack_592212; body: JsonNode): Recallable =
  ## deleteStack
  ## Deletes the specified stack. After the stack is deleted, the application streaming environment provided by the stack is no longer available to users. Also, any reservations made for application streaming sessions for the stack are released.
  ##   body: JObject (required)
  var body_592226 = newJObject()
  if body != nil:
    body_592226 = body
  result = call_592225.call(nil, nil, nil, nil, body_592226)

var deleteStack* = Call_DeleteStack_592212(name: "deleteStack",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteStack",
                                        validator: validate_DeleteStack_592213,
                                        base: "/", url: url_DeleteStack_592214,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsageReportSubscription_592227 = ref object of OpenApiRestCall_591364
proc url_DeleteUsageReportSubscription_592229(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteUsageReportSubscription_592228(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592230 = header.getOrDefault("X-Amz-Target")
  valid_592230 = validateParameter(valid_592230, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteUsageReportSubscription"))
  if valid_592230 != nil:
    section.add "X-Amz-Target", valid_592230
  var valid_592231 = header.getOrDefault("X-Amz-Signature")
  valid_592231 = validateParameter(valid_592231, JString, required = false,
                                 default = nil)
  if valid_592231 != nil:
    section.add "X-Amz-Signature", valid_592231
  var valid_592232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592232 = validateParameter(valid_592232, JString, required = false,
                                 default = nil)
  if valid_592232 != nil:
    section.add "X-Amz-Content-Sha256", valid_592232
  var valid_592233 = header.getOrDefault("X-Amz-Date")
  valid_592233 = validateParameter(valid_592233, JString, required = false,
                                 default = nil)
  if valid_592233 != nil:
    section.add "X-Amz-Date", valid_592233
  var valid_592234 = header.getOrDefault("X-Amz-Credential")
  valid_592234 = validateParameter(valid_592234, JString, required = false,
                                 default = nil)
  if valid_592234 != nil:
    section.add "X-Amz-Credential", valid_592234
  var valid_592235 = header.getOrDefault("X-Amz-Security-Token")
  valid_592235 = validateParameter(valid_592235, JString, required = false,
                                 default = nil)
  if valid_592235 != nil:
    section.add "X-Amz-Security-Token", valid_592235
  var valid_592236 = header.getOrDefault("X-Amz-Algorithm")
  valid_592236 = validateParameter(valid_592236, JString, required = false,
                                 default = nil)
  if valid_592236 != nil:
    section.add "X-Amz-Algorithm", valid_592236
  var valid_592237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592237 = validateParameter(valid_592237, JString, required = false,
                                 default = nil)
  if valid_592237 != nil:
    section.add "X-Amz-SignedHeaders", valid_592237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592239: Call_DeleteUsageReportSubscription_592227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables usage report generation.
  ## 
  let valid = call_592239.validator(path, query, header, formData, body)
  let scheme = call_592239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592239.url(scheme.get, call_592239.host, call_592239.base,
                         call_592239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592239, url, valid)

proc call*(call_592240: Call_DeleteUsageReportSubscription_592227; body: JsonNode): Recallable =
  ## deleteUsageReportSubscription
  ## Disables usage report generation.
  ##   body: JObject (required)
  var body_592241 = newJObject()
  if body != nil:
    body_592241 = body
  result = call_592240.call(nil, nil, nil, nil, body_592241)

var deleteUsageReportSubscription* = Call_DeleteUsageReportSubscription_592227(
    name: "deleteUsageReportSubscription", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteUsageReportSubscription",
    validator: validate_DeleteUsageReportSubscription_592228, base: "/",
    url: url_DeleteUsageReportSubscription_592229,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_592242 = ref object of OpenApiRestCall_591364
proc url_DeleteUser_592244(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteUser_592243(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592245 = header.getOrDefault("X-Amz-Target")
  valid_592245 = validateParameter(valid_592245, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteUser"))
  if valid_592245 != nil:
    section.add "X-Amz-Target", valid_592245
  var valid_592246 = header.getOrDefault("X-Amz-Signature")
  valid_592246 = validateParameter(valid_592246, JString, required = false,
                                 default = nil)
  if valid_592246 != nil:
    section.add "X-Amz-Signature", valid_592246
  var valid_592247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592247 = validateParameter(valid_592247, JString, required = false,
                                 default = nil)
  if valid_592247 != nil:
    section.add "X-Amz-Content-Sha256", valid_592247
  var valid_592248 = header.getOrDefault("X-Amz-Date")
  valid_592248 = validateParameter(valid_592248, JString, required = false,
                                 default = nil)
  if valid_592248 != nil:
    section.add "X-Amz-Date", valid_592248
  var valid_592249 = header.getOrDefault("X-Amz-Credential")
  valid_592249 = validateParameter(valid_592249, JString, required = false,
                                 default = nil)
  if valid_592249 != nil:
    section.add "X-Amz-Credential", valid_592249
  var valid_592250 = header.getOrDefault("X-Amz-Security-Token")
  valid_592250 = validateParameter(valid_592250, JString, required = false,
                                 default = nil)
  if valid_592250 != nil:
    section.add "X-Amz-Security-Token", valid_592250
  var valid_592251 = header.getOrDefault("X-Amz-Algorithm")
  valid_592251 = validateParameter(valid_592251, JString, required = false,
                                 default = nil)
  if valid_592251 != nil:
    section.add "X-Amz-Algorithm", valid_592251
  var valid_592252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592252 = validateParameter(valid_592252, JString, required = false,
                                 default = nil)
  if valid_592252 != nil:
    section.add "X-Amz-SignedHeaders", valid_592252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592254: Call_DeleteUser_592242; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a user from the user pool.
  ## 
  let valid = call_592254.validator(path, query, header, formData, body)
  let scheme = call_592254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592254.url(scheme.get, call_592254.host, call_592254.base,
                         call_592254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592254, url, valid)

proc call*(call_592255: Call_DeleteUser_592242; body: JsonNode): Recallable =
  ## deleteUser
  ## Deletes a user from the user pool.
  ##   body: JObject (required)
  var body_592256 = newJObject()
  if body != nil:
    body_592256 = body
  result = call_592255.call(nil, nil, nil, nil, body_592256)

var deleteUser* = Call_DeleteUser_592242(name: "deleteUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteUser",
                                      validator: validate_DeleteUser_592243,
                                      base: "/", url: url_DeleteUser_592244,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDirectoryConfigs_592257 = ref object of OpenApiRestCall_591364
proc url_DescribeDirectoryConfigs_592259(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDirectoryConfigs_592258(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592260 = header.getOrDefault("X-Amz-Target")
  valid_592260 = validateParameter(valid_592260, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeDirectoryConfigs"))
  if valid_592260 != nil:
    section.add "X-Amz-Target", valid_592260
  var valid_592261 = header.getOrDefault("X-Amz-Signature")
  valid_592261 = validateParameter(valid_592261, JString, required = false,
                                 default = nil)
  if valid_592261 != nil:
    section.add "X-Amz-Signature", valid_592261
  var valid_592262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592262 = validateParameter(valid_592262, JString, required = false,
                                 default = nil)
  if valid_592262 != nil:
    section.add "X-Amz-Content-Sha256", valid_592262
  var valid_592263 = header.getOrDefault("X-Amz-Date")
  valid_592263 = validateParameter(valid_592263, JString, required = false,
                                 default = nil)
  if valid_592263 != nil:
    section.add "X-Amz-Date", valid_592263
  var valid_592264 = header.getOrDefault("X-Amz-Credential")
  valid_592264 = validateParameter(valid_592264, JString, required = false,
                                 default = nil)
  if valid_592264 != nil:
    section.add "X-Amz-Credential", valid_592264
  var valid_592265 = header.getOrDefault("X-Amz-Security-Token")
  valid_592265 = validateParameter(valid_592265, JString, required = false,
                                 default = nil)
  if valid_592265 != nil:
    section.add "X-Amz-Security-Token", valid_592265
  var valid_592266 = header.getOrDefault("X-Amz-Algorithm")
  valid_592266 = validateParameter(valid_592266, JString, required = false,
                                 default = nil)
  if valid_592266 != nil:
    section.add "X-Amz-Algorithm", valid_592266
  var valid_592267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592267 = validateParameter(valid_592267, JString, required = false,
                                 default = nil)
  if valid_592267 != nil:
    section.add "X-Amz-SignedHeaders", valid_592267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592269: Call_DescribeDirectoryConfigs_592257; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list that describes one or more specified Directory Config objects for AppStream 2.0, if the names for these objects are provided. Otherwise, all Directory Config objects in the account are described. These objects include the configuration information required to join fleets and image builders to Microsoft Active Directory domains. </p> <p>Although the response syntax in this topic includes the account password, this password is not returned in the actual response.</p>
  ## 
  let valid = call_592269.validator(path, query, header, formData, body)
  let scheme = call_592269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592269.url(scheme.get, call_592269.host, call_592269.base,
                         call_592269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592269, url, valid)

proc call*(call_592270: Call_DescribeDirectoryConfigs_592257; body: JsonNode): Recallable =
  ## describeDirectoryConfigs
  ## <p>Retrieves a list that describes one or more specified Directory Config objects for AppStream 2.0, if the names for these objects are provided. Otherwise, all Directory Config objects in the account are described. These objects include the configuration information required to join fleets and image builders to Microsoft Active Directory domains. </p> <p>Although the response syntax in this topic includes the account password, this password is not returned in the actual response.</p>
  ##   body: JObject (required)
  var body_592271 = newJObject()
  if body != nil:
    body_592271 = body
  result = call_592270.call(nil, nil, nil, nil, body_592271)

var describeDirectoryConfigs* = Call_DescribeDirectoryConfigs_592257(
    name: "describeDirectoryConfigs", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeDirectoryConfigs",
    validator: validate_DescribeDirectoryConfigs_592258, base: "/",
    url: url_DescribeDirectoryConfigs_592259, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFleets_592272 = ref object of OpenApiRestCall_591364
proc url_DescribeFleets_592274(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeFleets_592273(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592275 = header.getOrDefault("X-Amz-Target")
  valid_592275 = validateParameter(valid_592275, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeFleets"))
  if valid_592275 != nil:
    section.add "X-Amz-Target", valid_592275
  var valid_592276 = header.getOrDefault("X-Amz-Signature")
  valid_592276 = validateParameter(valid_592276, JString, required = false,
                                 default = nil)
  if valid_592276 != nil:
    section.add "X-Amz-Signature", valid_592276
  var valid_592277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592277 = validateParameter(valid_592277, JString, required = false,
                                 default = nil)
  if valid_592277 != nil:
    section.add "X-Amz-Content-Sha256", valid_592277
  var valid_592278 = header.getOrDefault("X-Amz-Date")
  valid_592278 = validateParameter(valid_592278, JString, required = false,
                                 default = nil)
  if valid_592278 != nil:
    section.add "X-Amz-Date", valid_592278
  var valid_592279 = header.getOrDefault("X-Amz-Credential")
  valid_592279 = validateParameter(valid_592279, JString, required = false,
                                 default = nil)
  if valid_592279 != nil:
    section.add "X-Amz-Credential", valid_592279
  var valid_592280 = header.getOrDefault("X-Amz-Security-Token")
  valid_592280 = validateParameter(valid_592280, JString, required = false,
                                 default = nil)
  if valid_592280 != nil:
    section.add "X-Amz-Security-Token", valid_592280
  var valid_592281 = header.getOrDefault("X-Amz-Algorithm")
  valid_592281 = validateParameter(valid_592281, JString, required = false,
                                 default = nil)
  if valid_592281 != nil:
    section.add "X-Amz-Algorithm", valid_592281
  var valid_592282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592282 = validateParameter(valid_592282, JString, required = false,
                                 default = nil)
  if valid_592282 != nil:
    section.add "X-Amz-SignedHeaders", valid_592282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592284: Call_DescribeFleets_592272; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified fleets, if the fleet names are provided. Otherwise, all fleets in the account are described.
  ## 
  let valid = call_592284.validator(path, query, header, formData, body)
  let scheme = call_592284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592284.url(scheme.get, call_592284.host, call_592284.base,
                         call_592284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592284, url, valid)

proc call*(call_592285: Call_DescribeFleets_592272; body: JsonNode): Recallable =
  ## describeFleets
  ## Retrieves a list that describes one or more specified fleets, if the fleet names are provided. Otherwise, all fleets in the account are described.
  ##   body: JObject (required)
  var body_592286 = newJObject()
  if body != nil:
    body_592286 = body
  result = call_592285.call(nil, nil, nil, nil, body_592286)

var describeFleets* = Call_DescribeFleets_592272(name: "describeFleets",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeFleets",
    validator: validate_DescribeFleets_592273, base: "/", url: url_DescribeFleets_592274,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeImageBuilders_592287 = ref object of OpenApiRestCall_591364
proc url_DescribeImageBuilders_592289(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeImageBuilders_592288(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592290 = header.getOrDefault("X-Amz-Target")
  valid_592290 = validateParameter(valid_592290, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeImageBuilders"))
  if valid_592290 != nil:
    section.add "X-Amz-Target", valid_592290
  var valid_592291 = header.getOrDefault("X-Amz-Signature")
  valid_592291 = validateParameter(valid_592291, JString, required = false,
                                 default = nil)
  if valid_592291 != nil:
    section.add "X-Amz-Signature", valid_592291
  var valid_592292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592292 = validateParameter(valid_592292, JString, required = false,
                                 default = nil)
  if valid_592292 != nil:
    section.add "X-Amz-Content-Sha256", valid_592292
  var valid_592293 = header.getOrDefault("X-Amz-Date")
  valid_592293 = validateParameter(valid_592293, JString, required = false,
                                 default = nil)
  if valid_592293 != nil:
    section.add "X-Amz-Date", valid_592293
  var valid_592294 = header.getOrDefault("X-Amz-Credential")
  valid_592294 = validateParameter(valid_592294, JString, required = false,
                                 default = nil)
  if valid_592294 != nil:
    section.add "X-Amz-Credential", valid_592294
  var valid_592295 = header.getOrDefault("X-Amz-Security-Token")
  valid_592295 = validateParameter(valid_592295, JString, required = false,
                                 default = nil)
  if valid_592295 != nil:
    section.add "X-Amz-Security-Token", valid_592295
  var valid_592296 = header.getOrDefault("X-Amz-Algorithm")
  valid_592296 = validateParameter(valid_592296, JString, required = false,
                                 default = nil)
  if valid_592296 != nil:
    section.add "X-Amz-Algorithm", valid_592296
  var valid_592297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592297 = validateParameter(valid_592297, JString, required = false,
                                 default = nil)
  if valid_592297 != nil:
    section.add "X-Amz-SignedHeaders", valid_592297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592299: Call_DescribeImageBuilders_592287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified image builders, if the image builder names are provided. Otherwise, all image builders in the account are described.
  ## 
  let valid = call_592299.validator(path, query, header, formData, body)
  let scheme = call_592299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592299.url(scheme.get, call_592299.host, call_592299.base,
                         call_592299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592299, url, valid)

proc call*(call_592300: Call_DescribeImageBuilders_592287; body: JsonNode): Recallable =
  ## describeImageBuilders
  ## Retrieves a list that describes one or more specified image builders, if the image builder names are provided. Otherwise, all image builders in the account are described.
  ##   body: JObject (required)
  var body_592301 = newJObject()
  if body != nil:
    body_592301 = body
  result = call_592300.call(nil, nil, nil, nil, body_592301)

var describeImageBuilders* = Call_DescribeImageBuilders_592287(
    name: "describeImageBuilders", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeImageBuilders",
    validator: validate_DescribeImageBuilders_592288, base: "/",
    url: url_DescribeImageBuilders_592289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeImagePermissions_592302 = ref object of OpenApiRestCall_591364
proc url_DescribeImagePermissions_592304(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeImagePermissions_592303(path: JsonNode; query: JsonNode;
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
  var valid_592305 = query.getOrDefault("MaxResults")
  valid_592305 = validateParameter(valid_592305, JString, required = false,
                                 default = nil)
  if valid_592305 != nil:
    section.add "MaxResults", valid_592305
  var valid_592306 = query.getOrDefault("NextToken")
  valid_592306 = validateParameter(valid_592306, JString, required = false,
                                 default = nil)
  if valid_592306 != nil:
    section.add "NextToken", valid_592306
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_592307 = header.getOrDefault("X-Amz-Target")
  valid_592307 = validateParameter(valid_592307, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeImagePermissions"))
  if valid_592307 != nil:
    section.add "X-Amz-Target", valid_592307
  var valid_592308 = header.getOrDefault("X-Amz-Signature")
  valid_592308 = validateParameter(valid_592308, JString, required = false,
                                 default = nil)
  if valid_592308 != nil:
    section.add "X-Amz-Signature", valid_592308
  var valid_592309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592309 = validateParameter(valid_592309, JString, required = false,
                                 default = nil)
  if valid_592309 != nil:
    section.add "X-Amz-Content-Sha256", valid_592309
  var valid_592310 = header.getOrDefault("X-Amz-Date")
  valid_592310 = validateParameter(valid_592310, JString, required = false,
                                 default = nil)
  if valid_592310 != nil:
    section.add "X-Amz-Date", valid_592310
  var valid_592311 = header.getOrDefault("X-Amz-Credential")
  valid_592311 = validateParameter(valid_592311, JString, required = false,
                                 default = nil)
  if valid_592311 != nil:
    section.add "X-Amz-Credential", valid_592311
  var valid_592312 = header.getOrDefault("X-Amz-Security-Token")
  valid_592312 = validateParameter(valid_592312, JString, required = false,
                                 default = nil)
  if valid_592312 != nil:
    section.add "X-Amz-Security-Token", valid_592312
  var valid_592313 = header.getOrDefault("X-Amz-Algorithm")
  valid_592313 = validateParameter(valid_592313, JString, required = false,
                                 default = nil)
  if valid_592313 != nil:
    section.add "X-Amz-Algorithm", valid_592313
  var valid_592314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592314 = validateParameter(valid_592314, JString, required = false,
                                 default = nil)
  if valid_592314 != nil:
    section.add "X-Amz-SignedHeaders", valid_592314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592316: Call_DescribeImagePermissions_592302; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes the permissions for shared AWS account IDs on a private image that you own. 
  ## 
  let valid = call_592316.validator(path, query, header, formData, body)
  let scheme = call_592316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592316.url(scheme.get, call_592316.host, call_592316.base,
                         call_592316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592316, url, valid)

proc call*(call_592317: Call_DescribeImagePermissions_592302; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeImagePermissions
  ## Retrieves a list that describes the permissions for shared AWS account IDs on a private image that you own. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_592318 = newJObject()
  var body_592319 = newJObject()
  add(query_592318, "MaxResults", newJString(MaxResults))
  add(query_592318, "NextToken", newJString(NextToken))
  if body != nil:
    body_592319 = body
  result = call_592317.call(nil, query_592318, nil, nil, body_592319)

var describeImagePermissions* = Call_DescribeImagePermissions_592302(
    name: "describeImagePermissions", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeImagePermissions",
    validator: validate_DescribeImagePermissions_592303, base: "/",
    url: url_DescribeImagePermissions_592304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeImages_592321 = ref object of OpenApiRestCall_591364
proc url_DescribeImages_592323(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeImages_592322(path: JsonNode; query: JsonNode;
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
  var valid_592324 = query.getOrDefault("MaxResults")
  valid_592324 = validateParameter(valid_592324, JString, required = false,
                                 default = nil)
  if valid_592324 != nil:
    section.add "MaxResults", valid_592324
  var valid_592325 = query.getOrDefault("NextToken")
  valid_592325 = validateParameter(valid_592325, JString, required = false,
                                 default = nil)
  if valid_592325 != nil:
    section.add "NextToken", valid_592325
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_592326 = header.getOrDefault("X-Amz-Target")
  valid_592326 = validateParameter(valid_592326, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeImages"))
  if valid_592326 != nil:
    section.add "X-Amz-Target", valid_592326
  var valid_592327 = header.getOrDefault("X-Amz-Signature")
  valid_592327 = validateParameter(valid_592327, JString, required = false,
                                 default = nil)
  if valid_592327 != nil:
    section.add "X-Amz-Signature", valid_592327
  var valid_592328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592328 = validateParameter(valid_592328, JString, required = false,
                                 default = nil)
  if valid_592328 != nil:
    section.add "X-Amz-Content-Sha256", valid_592328
  var valid_592329 = header.getOrDefault("X-Amz-Date")
  valid_592329 = validateParameter(valid_592329, JString, required = false,
                                 default = nil)
  if valid_592329 != nil:
    section.add "X-Amz-Date", valid_592329
  var valid_592330 = header.getOrDefault("X-Amz-Credential")
  valid_592330 = validateParameter(valid_592330, JString, required = false,
                                 default = nil)
  if valid_592330 != nil:
    section.add "X-Amz-Credential", valid_592330
  var valid_592331 = header.getOrDefault("X-Amz-Security-Token")
  valid_592331 = validateParameter(valid_592331, JString, required = false,
                                 default = nil)
  if valid_592331 != nil:
    section.add "X-Amz-Security-Token", valid_592331
  var valid_592332 = header.getOrDefault("X-Amz-Algorithm")
  valid_592332 = validateParameter(valid_592332, JString, required = false,
                                 default = nil)
  if valid_592332 != nil:
    section.add "X-Amz-Algorithm", valid_592332
  var valid_592333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592333 = validateParameter(valid_592333, JString, required = false,
                                 default = nil)
  if valid_592333 != nil:
    section.add "X-Amz-SignedHeaders", valid_592333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592335: Call_DescribeImages_592321; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified images, if the image names or image ARNs are provided. Otherwise, all images in the account are described.
  ## 
  let valid = call_592335.validator(path, query, header, formData, body)
  let scheme = call_592335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592335.url(scheme.get, call_592335.host, call_592335.base,
                         call_592335.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592335, url, valid)

proc call*(call_592336: Call_DescribeImages_592321; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeImages
  ## Retrieves a list that describes one or more specified images, if the image names or image ARNs are provided. Otherwise, all images in the account are described.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_592337 = newJObject()
  var body_592338 = newJObject()
  add(query_592337, "MaxResults", newJString(MaxResults))
  add(query_592337, "NextToken", newJString(NextToken))
  if body != nil:
    body_592338 = body
  result = call_592336.call(nil, query_592337, nil, nil, body_592338)

var describeImages* = Call_DescribeImages_592321(name: "describeImages",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeImages",
    validator: validate_DescribeImages_592322, base: "/", url: url_DescribeImages_592323,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSessions_592339 = ref object of OpenApiRestCall_591364
proc url_DescribeSessions_592341(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSessions_592340(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592342 = header.getOrDefault("X-Amz-Target")
  valid_592342 = validateParameter(valid_592342, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeSessions"))
  if valid_592342 != nil:
    section.add "X-Amz-Target", valid_592342
  var valid_592343 = header.getOrDefault("X-Amz-Signature")
  valid_592343 = validateParameter(valid_592343, JString, required = false,
                                 default = nil)
  if valid_592343 != nil:
    section.add "X-Amz-Signature", valid_592343
  var valid_592344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592344 = validateParameter(valid_592344, JString, required = false,
                                 default = nil)
  if valid_592344 != nil:
    section.add "X-Amz-Content-Sha256", valid_592344
  var valid_592345 = header.getOrDefault("X-Amz-Date")
  valid_592345 = validateParameter(valid_592345, JString, required = false,
                                 default = nil)
  if valid_592345 != nil:
    section.add "X-Amz-Date", valid_592345
  var valid_592346 = header.getOrDefault("X-Amz-Credential")
  valid_592346 = validateParameter(valid_592346, JString, required = false,
                                 default = nil)
  if valid_592346 != nil:
    section.add "X-Amz-Credential", valid_592346
  var valid_592347 = header.getOrDefault("X-Amz-Security-Token")
  valid_592347 = validateParameter(valid_592347, JString, required = false,
                                 default = nil)
  if valid_592347 != nil:
    section.add "X-Amz-Security-Token", valid_592347
  var valid_592348 = header.getOrDefault("X-Amz-Algorithm")
  valid_592348 = validateParameter(valid_592348, JString, required = false,
                                 default = nil)
  if valid_592348 != nil:
    section.add "X-Amz-Algorithm", valid_592348
  var valid_592349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592349 = validateParameter(valid_592349, JString, required = false,
                                 default = nil)
  if valid_592349 != nil:
    section.add "X-Amz-SignedHeaders", valid_592349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592351: Call_DescribeSessions_592339; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes the streaming sessions for a specified stack and fleet. If a UserId is provided for the stack and fleet, only streaming sessions for that user are described. If an authentication type is not provided, the default is to authenticate users using a streaming URL.
  ## 
  let valid = call_592351.validator(path, query, header, formData, body)
  let scheme = call_592351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592351.url(scheme.get, call_592351.host, call_592351.base,
                         call_592351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592351, url, valid)

proc call*(call_592352: Call_DescribeSessions_592339; body: JsonNode): Recallable =
  ## describeSessions
  ## Retrieves a list that describes the streaming sessions for a specified stack and fleet. If a UserId is provided for the stack and fleet, only streaming sessions for that user are described. If an authentication type is not provided, the default is to authenticate users using a streaming URL.
  ##   body: JObject (required)
  var body_592353 = newJObject()
  if body != nil:
    body_592353 = body
  result = call_592352.call(nil, nil, nil, nil, body_592353)

var describeSessions* = Call_DescribeSessions_592339(name: "describeSessions",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeSessions",
    validator: validate_DescribeSessions_592340, base: "/",
    url: url_DescribeSessions_592341, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStacks_592354 = ref object of OpenApiRestCall_591364
proc url_DescribeStacks_592356(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeStacks_592355(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592357 = header.getOrDefault("X-Amz-Target")
  valid_592357 = validateParameter(valid_592357, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeStacks"))
  if valid_592357 != nil:
    section.add "X-Amz-Target", valid_592357
  var valid_592358 = header.getOrDefault("X-Amz-Signature")
  valid_592358 = validateParameter(valid_592358, JString, required = false,
                                 default = nil)
  if valid_592358 != nil:
    section.add "X-Amz-Signature", valid_592358
  var valid_592359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592359 = validateParameter(valid_592359, JString, required = false,
                                 default = nil)
  if valid_592359 != nil:
    section.add "X-Amz-Content-Sha256", valid_592359
  var valid_592360 = header.getOrDefault("X-Amz-Date")
  valid_592360 = validateParameter(valid_592360, JString, required = false,
                                 default = nil)
  if valid_592360 != nil:
    section.add "X-Amz-Date", valid_592360
  var valid_592361 = header.getOrDefault("X-Amz-Credential")
  valid_592361 = validateParameter(valid_592361, JString, required = false,
                                 default = nil)
  if valid_592361 != nil:
    section.add "X-Amz-Credential", valid_592361
  var valid_592362 = header.getOrDefault("X-Amz-Security-Token")
  valid_592362 = validateParameter(valid_592362, JString, required = false,
                                 default = nil)
  if valid_592362 != nil:
    section.add "X-Amz-Security-Token", valid_592362
  var valid_592363 = header.getOrDefault("X-Amz-Algorithm")
  valid_592363 = validateParameter(valid_592363, JString, required = false,
                                 default = nil)
  if valid_592363 != nil:
    section.add "X-Amz-Algorithm", valid_592363
  var valid_592364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592364 = validateParameter(valid_592364, JString, required = false,
                                 default = nil)
  if valid_592364 != nil:
    section.add "X-Amz-SignedHeaders", valid_592364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592366: Call_DescribeStacks_592354; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified stacks, if the stack names are provided. Otherwise, all stacks in the account are described.
  ## 
  let valid = call_592366.validator(path, query, header, formData, body)
  let scheme = call_592366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592366.url(scheme.get, call_592366.host, call_592366.base,
                         call_592366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592366, url, valid)

proc call*(call_592367: Call_DescribeStacks_592354; body: JsonNode): Recallable =
  ## describeStacks
  ## Retrieves a list that describes one or more specified stacks, if the stack names are provided. Otherwise, all stacks in the account are described.
  ##   body: JObject (required)
  var body_592368 = newJObject()
  if body != nil:
    body_592368 = body
  result = call_592367.call(nil, nil, nil, nil, body_592368)

var describeStacks* = Call_DescribeStacks_592354(name: "describeStacks",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeStacks",
    validator: validate_DescribeStacks_592355, base: "/", url: url_DescribeStacks_592356,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUsageReportSubscriptions_592369 = ref object of OpenApiRestCall_591364
proc url_DescribeUsageReportSubscriptions_592371(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeUsageReportSubscriptions_592370(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592372 = header.getOrDefault("X-Amz-Target")
  valid_592372 = validateParameter(valid_592372, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeUsageReportSubscriptions"))
  if valid_592372 != nil:
    section.add "X-Amz-Target", valid_592372
  var valid_592373 = header.getOrDefault("X-Amz-Signature")
  valid_592373 = validateParameter(valid_592373, JString, required = false,
                                 default = nil)
  if valid_592373 != nil:
    section.add "X-Amz-Signature", valid_592373
  var valid_592374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592374 = validateParameter(valid_592374, JString, required = false,
                                 default = nil)
  if valid_592374 != nil:
    section.add "X-Amz-Content-Sha256", valid_592374
  var valid_592375 = header.getOrDefault("X-Amz-Date")
  valid_592375 = validateParameter(valid_592375, JString, required = false,
                                 default = nil)
  if valid_592375 != nil:
    section.add "X-Amz-Date", valid_592375
  var valid_592376 = header.getOrDefault("X-Amz-Credential")
  valid_592376 = validateParameter(valid_592376, JString, required = false,
                                 default = nil)
  if valid_592376 != nil:
    section.add "X-Amz-Credential", valid_592376
  var valid_592377 = header.getOrDefault("X-Amz-Security-Token")
  valid_592377 = validateParameter(valid_592377, JString, required = false,
                                 default = nil)
  if valid_592377 != nil:
    section.add "X-Amz-Security-Token", valid_592377
  var valid_592378 = header.getOrDefault("X-Amz-Algorithm")
  valid_592378 = validateParameter(valid_592378, JString, required = false,
                                 default = nil)
  if valid_592378 != nil:
    section.add "X-Amz-Algorithm", valid_592378
  var valid_592379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592379 = validateParameter(valid_592379, JString, required = false,
                                 default = nil)
  if valid_592379 != nil:
    section.add "X-Amz-SignedHeaders", valid_592379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592381: Call_DescribeUsageReportSubscriptions_592369;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more usage report subscriptions.
  ## 
  let valid = call_592381.validator(path, query, header, formData, body)
  let scheme = call_592381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592381.url(scheme.get, call_592381.host, call_592381.base,
                         call_592381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592381, url, valid)

proc call*(call_592382: Call_DescribeUsageReportSubscriptions_592369;
          body: JsonNode): Recallable =
  ## describeUsageReportSubscriptions
  ## Retrieves a list that describes one or more usage report subscriptions.
  ##   body: JObject (required)
  var body_592383 = newJObject()
  if body != nil:
    body_592383 = body
  result = call_592382.call(nil, nil, nil, nil, body_592383)

var describeUsageReportSubscriptions* = Call_DescribeUsageReportSubscriptions_592369(
    name: "describeUsageReportSubscriptions", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeUsageReportSubscriptions",
    validator: validate_DescribeUsageReportSubscriptions_592370, base: "/",
    url: url_DescribeUsageReportSubscriptions_592371,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserStackAssociations_592384 = ref object of OpenApiRestCall_591364
proc url_DescribeUserStackAssociations_592386(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeUserStackAssociations_592385(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592387 = header.getOrDefault("X-Amz-Target")
  valid_592387 = validateParameter(valid_592387, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeUserStackAssociations"))
  if valid_592387 != nil:
    section.add "X-Amz-Target", valid_592387
  var valid_592388 = header.getOrDefault("X-Amz-Signature")
  valid_592388 = validateParameter(valid_592388, JString, required = false,
                                 default = nil)
  if valid_592388 != nil:
    section.add "X-Amz-Signature", valid_592388
  var valid_592389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592389 = validateParameter(valid_592389, JString, required = false,
                                 default = nil)
  if valid_592389 != nil:
    section.add "X-Amz-Content-Sha256", valid_592389
  var valid_592390 = header.getOrDefault("X-Amz-Date")
  valid_592390 = validateParameter(valid_592390, JString, required = false,
                                 default = nil)
  if valid_592390 != nil:
    section.add "X-Amz-Date", valid_592390
  var valid_592391 = header.getOrDefault("X-Amz-Credential")
  valid_592391 = validateParameter(valid_592391, JString, required = false,
                                 default = nil)
  if valid_592391 != nil:
    section.add "X-Amz-Credential", valid_592391
  var valid_592392 = header.getOrDefault("X-Amz-Security-Token")
  valid_592392 = validateParameter(valid_592392, JString, required = false,
                                 default = nil)
  if valid_592392 != nil:
    section.add "X-Amz-Security-Token", valid_592392
  var valid_592393 = header.getOrDefault("X-Amz-Algorithm")
  valid_592393 = validateParameter(valid_592393, JString, required = false,
                                 default = nil)
  if valid_592393 != nil:
    section.add "X-Amz-Algorithm", valid_592393
  var valid_592394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592394 = validateParameter(valid_592394, JString, required = false,
                                 default = nil)
  if valid_592394 != nil:
    section.add "X-Amz-SignedHeaders", valid_592394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592396: Call_DescribeUserStackAssociations_592384; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list that describes the UserStackAssociation objects. You must specify either or both of the following:</p> <ul> <li> <p>The stack name</p> </li> <li> <p>The user name (email address of the user associated with the stack) and the authentication type for the user</p> </li> </ul>
  ## 
  let valid = call_592396.validator(path, query, header, formData, body)
  let scheme = call_592396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592396.url(scheme.get, call_592396.host, call_592396.base,
                         call_592396.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592396, url, valid)

proc call*(call_592397: Call_DescribeUserStackAssociations_592384; body: JsonNode): Recallable =
  ## describeUserStackAssociations
  ## <p>Retrieves a list that describes the UserStackAssociation objects. You must specify either or both of the following:</p> <ul> <li> <p>The stack name</p> </li> <li> <p>The user name (email address of the user associated with the stack) and the authentication type for the user</p> </li> </ul>
  ##   body: JObject (required)
  var body_592398 = newJObject()
  if body != nil:
    body_592398 = body
  result = call_592397.call(nil, nil, nil, nil, body_592398)

var describeUserStackAssociations* = Call_DescribeUserStackAssociations_592384(
    name: "describeUserStackAssociations", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeUserStackAssociations",
    validator: validate_DescribeUserStackAssociations_592385, base: "/",
    url: url_DescribeUserStackAssociations_592386,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUsers_592399 = ref object of OpenApiRestCall_591364
proc url_DescribeUsers_592401(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeUsers_592400(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592402 = header.getOrDefault("X-Amz-Target")
  valid_592402 = validateParameter(valid_592402, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeUsers"))
  if valid_592402 != nil:
    section.add "X-Amz-Target", valid_592402
  var valid_592403 = header.getOrDefault("X-Amz-Signature")
  valid_592403 = validateParameter(valid_592403, JString, required = false,
                                 default = nil)
  if valid_592403 != nil:
    section.add "X-Amz-Signature", valid_592403
  var valid_592404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592404 = validateParameter(valid_592404, JString, required = false,
                                 default = nil)
  if valid_592404 != nil:
    section.add "X-Amz-Content-Sha256", valid_592404
  var valid_592405 = header.getOrDefault("X-Amz-Date")
  valid_592405 = validateParameter(valid_592405, JString, required = false,
                                 default = nil)
  if valid_592405 != nil:
    section.add "X-Amz-Date", valid_592405
  var valid_592406 = header.getOrDefault("X-Amz-Credential")
  valid_592406 = validateParameter(valid_592406, JString, required = false,
                                 default = nil)
  if valid_592406 != nil:
    section.add "X-Amz-Credential", valid_592406
  var valid_592407 = header.getOrDefault("X-Amz-Security-Token")
  valid_592407 = validateParameter(valid_592407, JString, required = false,
                                 default = nil)
  if valid_592407 != nil:
    section.add "X-Amz-Security-Token", valid_592407
  var valid_592408 = header.getOrDefault("X-Amz-Algorithm")
  valid_592408 = validateParameter(valid_592408, JString, required = false,
                                 default = nil)
  if valid_592408 != nil:
    section.add "X-Amz-Algorithm", valid_592408
  var valid_592409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592409 = validateParameter(valid_592409, JString, required = false,
                                 default = nil)
  if valid_592409 != nil:
    section.add "X-Amz-SignedHeaders", valid_592409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592411: Call_DescribeUsers_592399; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified users in the user pool.
  ## 
  let valid = call_592411.validator(path, query, header, formData, body)
  let scheme = call_592411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592411.url(scheme.get, call_592411.host, call_592411.base,
                         call_592411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592411, url, valid)

proc call*(call_592412: Call_DescribeUsers_592399; body: JsonNode): Recallable =
  ## describeUsers
  ## Retrieves a list that describes one or more specified users in the user pool.
  ##   body: JObject (required)
  var body_592413 = newJObject()
  if body != nil:
    body_592413 = body
  result = call_592412.call(nil, nil, nil, nil, body_592413)

var describeUsers* = Call_DescribeUsers_592399(name: "describeUsers",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeUsers",
    validator: validate_DescribeUsers_592400, base: "/", url: url_DescribeUsers_592401,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableUser_592414 = ref object of OpenApiRestCall_591364
proc url_DisableUser_592416(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisableUser_592415(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592417 = header.getOrDefault("X-Amz-Target")
  valid_592417 = validateParameter(valid_592417, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DisableUser"))
  if valid_592417 != nil:
    section.add "X-Amz-Target", valid_592417
  var valid_592418 = header.getOrDefault("X-Amz-Signature")
  valid_592418 = validateParameter(valid_592418, JString, required = false,
                                 default = nil)
  if valid_592418 != nil:
    section.add "X-Amz-Signature", valid_592418
  var valid_592419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592419 = validateParameter(valid_592419, JString, required = false,
                                 default = nil)
  if valid_592419 != nil:
    section.add "X-Amz-Content-Sha256", valid_592419
  var valid_592420 = header.getOrDefault("X-Amz-Date")
  valid_592420 = validateParameter(valid_592420, JString, required = false,
                                 default = nil)
  if valid_592420 != nil:
    section.add "X-Amz-Date", valid_592420
  var valid_592421 = header.getOrDefault("X-Amz-Credential")
  valid_592421 = validateParameter(valid_592421, JString, required = false,
                                 default = nil)
  if valid_592421 != nil:
    section.add "X-Amz-Credential", valid_592421
  var valid_592422 = header.getOrDefault("X-Amz-Security-Token")
  valid_592422 = validateParameter(valid_592422, JString, required = false,
                                 default = nil)
  if valid_592422 != nil:
    section.add "X-Amz-Security-Token", valid_592422
  var valid_592423 = header.getOrDefault("X-Amz-Algorithm")
  valid_592423 = validateParameter(valid_592423, JString, required = false,
                                 default = nil)
  if valid_592423 != nil:
    section.add "X-Amz-Algorithm", valid_592423
  var valid_592424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592424 = validateParameter(valid_592424, JString, required = false,
                                 default = nil)
  if valid_592424 != nil:
    section.add "X-Amz-SignedHeaders", valid_592424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592426: Call_DisableUser_592414; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the specified user in the user pool. Users can't sign in to AppStream 2.0 until they are re-enabled. This action does not delete the user. 
  ## 
  let valid = call_592426.validator(path, query, header, formData, body)
  let scheme = call_592426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592426.url(scheme.get, call_592426.host, call_592426.base,
                         call_592426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592426, url, valid)

proc call*(call_592427: Call_DisableUser_592414; body: JsonNode): Recallable =
  ## disableUser
  ## Disables the specified user in the user pool. Users can't sign in to AppStream 2.0 until they are re-enabled. This action does not delete the user. 
  ##   body: JObject (required)
  var body_592428 = newJObject()
  if body != nil:
    body_592428 = body
  result = call_592427.call(nil, nil, nil, nil, body_592428)

var disableUser* = Call_DisableUser_592414(name: "disableUser",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DisableUser",
                                        validator: validate_DisableUser_592415,
                                        base: "/", url: url_DisableUser_592416,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateFleet_592429 = ref object of OpenApiRestCall_591364
proc url_DisassociateFleet_592431(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateFleet_592430(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592432 = header.getOrDefault("X-Amz-Target")
  valid_592432 = validateParameter(valid_592432, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DisassociateFleet"))
  if valid_592432 != nil:
    section.add "X-Amz-Target", valid_592432
  var valid_592433 = header.getOrDefault("X-Amz-Signature")
  valid_592433 = validateParameter(valid_592433, JString, required = false,
                                 default = nil)
  if valid_592433 != nil:
    section.add "X-Amz-Signature", valid_592433
  var valid_592434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592434 = validateParameter(valid_592434, JString, required = false,
                                 default = nil)
  if valid_592434 != nil:
    section.add "X-Amz-Content-Sha256", valid_592434
  var valid_592435 = header.getOrDefault("X-Amz-Date")
  valid_592435 = validateParameter(valid_592435, JString, required = false,
                                 default = nil)
  if valid_592435 != nil:
    section.add "X-Amz-Date", valid_592435
  var valid_592436 = header.getOrDefault("X-Amz-Credential")
  valid_592436 = validateParameter(valid_592436, JString, required = false,
                                 default = nil)
  if valid_592436 != nil:
    section.add "X-Amz-Credential", valid_592436
  var valid_592437 = header.getOrDefault("X-Amz-Security-Token")
  valid_592437 = validateParameter(valid_592437, JString, required = false,
                                 default = nil)
  if valid_592437 != nil:
    section.add "X-Amz-Security-Token", valid_592437
  var valid_592438 = header.getOrDefault("X-Amz-Algorithm")
  valid_592438 = validateParameter(valid_592438, JString, required = false,
                                 default = nil)
  if valid_592438 != nil:
    section.add "X-Amz-Algorithm", valid_592438
  var valid_592439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592439 = validateParameter(valid_592439, JString, required = false,
                                 default = nil)
  if valid_592439 != nil:
    section.add "X-Amz-SignedHeaders", valid_592439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592441: Call_DisassociateFleet_592429; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified fleet from the specified stack.
  ## 
  let valid = call_592441.validator(path, query, header, formData, body)
  let scheme = call_592441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592441.url(scheme.get, call_592441.host, call_592441.base,
                         call_592441.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592441, url, valid)

proc call*(call_592442: Call_DisassociateFleet_592429; body: JsonNode): Recallable =
  ## disassociateFleet
  ## Disassociates the specified fleet from the specified stack.
  ##   body: JObject (required)
  var body_592443 = newJObject()
  if body != nil:
    body_592443 = body
  result = call_592442.call(nil, nil, nil, nil, body_592443)

var disassociateFleet* = Call_DisassociateFleet_592429(name: "disassociateFleet",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DisassociateFleet",
    validator: validate_DisassociateFleet_592430, base: "/",
    url: url_DisassociateFleet_592431, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableUser_592444 = ref object of OpenApiRestCall_591364
proc url_EnableUser_592446(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_EnableUser_592445(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592447 = header.getOrDefault("X-Amz-Target")
  valid_592447 = validateParameter(valid_592447, JString, required = true, default = newJString(
      "PhotonAdminProxyService.EnableUser"))
  if valid_592447 != nil:
    section.add "X-Amz-Target", valid_592447
  var valid_592448 = header.getOrDefault("X-Amz-Signature")
  valid_592448 = validateParameter(valid_592448, JString, required = false,
                                 default = nil)
  if valid_592448 != nil:
    section.add "X-Amz-Signature", valid_592448
  var valid_592449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592449 = validateParameter(valid_592449, JString, required = false,
                                 default = nil)
  if valid_592449 != nil:
    section.add "X-Amz-Content-Sha256", valid_592449
  var valid_592450 = header.getOrDefault("X-Amz-Date")
  valid_592450 = validateParameter(valid_592450, JString, required = false,
                                 default = nil)
  if valid_592450 != nil:
    section.add "X-Amz-Date", valid_592450
  var valid_592451 = header.getOrDefault("X-Amz-Credential")
  valid_592451 = validateParameter(valid_592451, JString, required = false,
                                 default = nil)
  if valid_592451 != nil:
    section.add "X-Amz-Credential", valid_592451
  var valid_592452 = header.getOrDefault("X-Amz-Security-Token")
  valid_592452 = validateParameter(valid_592452, JString, required = false,
                                 default = nil)
  if valid_592452 != nil:
    section.add "X-Amz-Security-Token", valid_592452
  var valid_592453 = header.getOrDefault("X-Amz-Algorithm")
  valid_592453 = validateParameter(valid_592453, JString, required = false,
                                 default = nil)
  if valid_592453 != nil:
    section.add "X-Amz-Algorithm", valid_592453
  var valid_592454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592454 = validateParameter(valid_592454, JString, required = false,
                                 default = nil)
  if valid_592454 != nil:
    section.add "X-Amz-SignedHeaders", valid_592454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592456: Call_EnableUser_592444; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables a user in the user pool. After being enabled, users can sign in to AppStream 2.0 and open applications from the stacks to which they are assigned.
  ## 
  let valid = call_592456.validator(path, query, header, formData, body)
  let scheme = call_592456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592456.url(scheme.get, call_592456.host, call_592456.base,
                         call_592456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592456, url, valid)

proc call*(call_592457: Call_EnableUser_592444; body: JsonNode): Recallable =
  ## enableUser
  ## Enables a user in the user pool. After being enabled, users can sign in to AppStream 2.0 and open applications from the stacks to which they are assigned.
  ##   body: JObject (required)
  var body_592458 = newJObject()
  if body != nil:
    body_592458 = body
  result = call_592457.call(nil, nil, nil, nil, body_592458)

var enableUser* = Call_EnableUser_592444(name: "enableUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.EnableUser",
                                      validator: validate_EnableUser_592445,
                                      base: "/", url: url_EnableUser_592446,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExpireSession_592459 = ref object of OpenApiRestCall_591364
proc url_ExpireSession_592461(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ExpireSession_592460(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592462 = header.getOrDefault("X-Amz-Target")
  valid_592462 = validateParameter(valid_592462, JString, required = true, default = newJString(
      "PhotonAdminProxyService.ExpireSession"))
  if valid_592462 != nil:
    section.add "X-Amz-Target", valid_592462
  var valid_592463 = header.getOrDefault("X-Amz-Signature")
  valid_592463 = validateParameter(valid_592463, JString, required = false,
                                 default = nil)
  if valid_592463 != nil:
    section.add "X-Amz-Signature", valid_592463
  var valid_592464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592464 = validateParameter(valid_592464, JString, required = false,
                                 default = nil)
  if valid_592464 != nil:
    section.add "X-Amz-Content-Sha256", valid_592464
  var valid_592465 = header.getOrDefault("X-Amz-Date")
  valid_592465 = validateParameter(valid_592465, JString, required = false,
                                 default = nil)
  if valid_592465 != nil:
    section.add "X-Amz-Date", valid_592465
  var valid_592466 = header.getOrDefault("X-Amz-Credential")
  valid_592466 = validateParameter(valid_592466, JString, required = false,
                                 default = nil)
  if valid_592466 != nil:
    section.add "X-Amz-Credential", valid_592466
  var valid_592467 = header.getOrDefault("X-Amz-Security-Token")
  valid_592467 = validateParameter(valid_592467, JString, required = false,
                                 default = nil)
  if valid_592467 != nil:
    section.add "X-Amz-Security-Token", valid_592467
  var valid_592468 = header.getOrDefault("X-Amz-Algorithm")
  valid_592468 = validateParameter(valid_592468, JString, required = false,
                                 default = nil)
  if valid_592468 != nil:
    section.add "X-Amz-Algorithm", valid_592468
  var valid_592469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592469 = validateParameter(valid_592469, JString, required = false,
                                 default = nil)
  if valid_592469 != nil:
    section.add "X-Amz-SignedHeaders", valid_592469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592471: Call_ExpireSession_592459; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Immediately stops the specified streaming session.
  ## 
  let valid = call_592471.validator(path, query, header, formData, body)
  let scheme = call_592471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592471.url(scheme.get, call_592471.host, call_592471.base,
                         call_592471.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592471, url, valid)

proc call*(call_592472: Call_ExpireSession_592459; body: JsonNode): Recallable =
  ## expireSession
  ## Immediately stops the specified streaming session.
  ##   body: JObject (required)
  var body_592473 = newJObject()
  if body != nil:
    body_592473 = body
  result = call_592472.call(nil, nil, nil, nil, body_592473)

var expireSession* = Call_ExpireSession_592459(name: "expireSession",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.ExpireSession",
    validator: validate_ExpireSession_592460, base: "/", url: url_ExpireSession_592461,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociatedFleets_592474 = ref object of OpenApiRestCall_591364
proc url_ListAssociatedFleets_592476(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAssociatedFleets_592475(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592477 = header.getOrDefault("X-Amz-Target")
  valid_592477 = validateParameter(valid_592477, JString, required = true, default = newJString(
      "PhotonAdminProxyService.ListAssociatedFleets"))
  if valid_592477 != nil:
    section.add "X-Amz-Target", valid_592477
  var valid_592478 = header.getOrDefault("X-Amz-Signature")
  valid_592478 = validateParameter(valid_592478, JString, required = false,
                                 default = nil)
  if valid_592478 != nil:
    section.add "X-Amz-Signature", valid_592478
  var valid_592479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592479 = validateParameter(valid_592479, JString, required = false,
                                 default = nil)
  if valid_592479 != nil:
    section.add "X-Amz-Content-Sha256", valid_592479
  var valid_592480 = header.getOrDefault("X-Amz-Date")
  valid_592480 = validateParameter(valid_592480, JString, required = false,
                                 default = nil)
  if valid_592480 != nil:
    section.add "X-Amz-Date", valid_592480
  var valid_592481 = header.getOrDefault("X-Amz-Credential")
  valid_592481 = validateParameter(valid_592481, JString, required = false,
                                 default = nil)
  if valid_592481 != nil:
    section.add "X-Amz-Credential", valid_592481
  var valid_592482 = header.getOrDefault("X-Amz-Security-Token")
  valid_592482 = validateParameter(valid_592482, JString, required = false,
                                 default = nil)
  if valid_592482 != nil:
    section.add "X-Amz-Security-Token", valid_592482
  var valid_592483 = header.getOrDefault("X-Amz-Algorithm")
  valid_592483 = validateParameter(valid_592483, JString, required = false,
                                 default = nil)
  if valid_592483 != nil:
    section.add "X-Amz-Algorithm", valid_592483
  var valid_592484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592484 = validateParameter(valid_592484, JString, required = false,
                                 default = nil)
  if valid_592484 != nil:
    section.add "X-Amz-SignedHeaders", valid_592484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592486: Call_ListAssociatedFleets_592474; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the name of the fleet that is associated with the specified stack.
  ## 
  let valid = call_592486.validator(path, query, header, formData, body)
  let scheme = call_592486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592486.url(scheme.get, call_592486.host, call_592486.base,
                         call_592486.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592486, url, valid)

proc call*(call_592487: Call_ListAssociatedFleets_592474; body: JsonNode): Recallable =
  ## listAssociatedFleets
  ## Retrieves the name of the fleet that is associated with the specified stack.
  ##   body: JObject (required)
  var body_592488 = newJObject()
  if body != nil:
    body_592488 = body
  result = call_592487.call(nil, nil, nil, nil, body_592488)

var listAssociatedFleets* = Call_ListAssociatedFleets_592474(
    name: "listAssociatedFleets", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.ListAssociatedFleets",
    validator: validate_ListAssociatedFleets_592475, base: "/",
    url: url_ListAssociatedFleets_592476, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociatedStacks_592489 = ref object of OpenApiRestCall_591364
proc url_ListAssociatedStacks_592491(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAssociatedStacks_592490(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592492 = header.getOrDefault("X-Amz-Target")
  valid_592492 = validateParameter(valid_592492, JString, required = true, default = newJString(
      "PhotonAdminProxyService.ListAssociatedStacks"))
  if valid_592492 != nil:
    section.add "X-Amz-Target", valid_592492
  var valid_592493 = header.getOrDefault("X-Amz-Signature")
  valid_592493 = validateParameter(valid_592493, JString, required = false,
                                 default = nil)
  if valid_592493 != nil:
    section.add "X-Amz-Signature", valid_592493
  var valid_592494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592494 = validateParameter(valid_592494, JString, required = false,
                                 default = nil)
  if valid_592494 != nil:
    section.add "X-Amz-Content-Sha256", valid_592494
  var valid_592495 = header.getOrDefault("X-Amz-Date")
  valid_592495 = validateParameter(valid_592495, JString, required = false,
                                 default = nil)
  if valid_592495 != nil:
    section.add "X-Amz-Date", valid_592495
  var valid_592496 = header.getOrDefault("X-Amz-Credential")
  valid_592496 = validateParameter(valid_592496, JString, required = false,
                                 default = nil)
  if valid_592496 != nil:
    section.add "X-Amz-Credential", valid_592496
  var valid_592497 = header.getOrDefault("X-Amz-Security-Token")
  valid_592497 = validateParameter(valid_592497, JString, required = false,
                                 default = nil)
  if valid_592497 != nil:
    section.add "X-Amz-Security-Token", valid_592497
  var valid_592498 = header.getOrDefault("X-Amz-Algorithm")
  valid_592498 = validateParameter(valid_592498, JString, required = false,
                                 default = nil)
  if valid_592498 != nil:
    section.add "X-Amz-Algorithm", valid_592498
  var valid_592499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592499 = validateParameter(valid_592499, JString, required = false,
                                 default = nil)
  if valid_592499 != nil:
    section.add "X-Amz-SignedHeaders", valid_592499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592501: Call_ListAssociatedStacks_592489; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the name of the stack with which the specified fleet is associated.
  ## 
  let valid = call_592501.validator(path, query, header, formData, body)
  let scheme = call_592501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592501.url(scheme.get, call_592501.host, call_592501.base,
                         call_592501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592501, url, valid)

proc call*(call_592502: Call_ListAssociatedStacks_592489; body: JsonNode): Recallable =
  ## listAssociatedStacks
  ## Retrieves the name of the stack with which the specified fleet is associated.
  ##   body: JObject (required)
  var body_592503 = newJObject()
  if body != nil:
    body_592503 = body
  result = call_592502.call(nil, nil, nil, nil, body_592503)

var listAssociatedStacks* = Call_ListAssociatedStacks_592489(
    name: "listAssociatedStacks", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.ListAssociatedStacks",
    validator: validate_ListAssociatedStacks_592490, base: "/",
    url: url_ListAssociatedStacks_592491, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_592504 = ref object of OpenApiRestCall_591364
proc url_ListTagsForResource_592506(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_592505(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592507 = header.getOrDefault("X-Amz-Target")
  valid_592507 = validateParameter(valid_592507, JString, required = true, default = newJString(
      "PhotonAdminProxyService.ListTagsForResource"))
  if valid_592507 != nil:
    section.add "X-Amz-Target", valid_592507
  var valid_592508 = header.getOrDefault("X-Amz-Signature")
  valid_592508 = validateParameter(valid_592508, JString, required = false,
                                 default = nil)
  if valid_592508 != nil:
    section.add "X-Amz-Signature", valid_592508
  var valid_592509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592509 = validateParameter(valid_592509, JString, required = false,
                                 default = nil)
  if valid_592509 != nil:
    section.add "X-Amz-Content-Sha256", valid_592509
  var valid_592510 = header.getOrDefault("X-Amz-Date")
  valid_592510 = validateParameter(valid_592510, JString, required = false,
                                 default = nil)
  if valid_592510 != nil:
    section.add "X-Amz-Date", valid_592510
  var valid_592511 = header.getOrDefault("X-Amz-Credential")
  valid_592511 = validateParameter(valid_592511, JString, required = false,
                                 default = nil)
  if valid_592511 != nil:
    section.add "X-Amz-Credential", valid_592511
  var valid_592512 = header.getOrDefault("X-Amz-Security-Token")
  valid_592512 = validateParameter(valid_592512, JString, required = false,
                                 default = nil)
  if valid_592512 != nil:
    section.add "X-Amz-Security-Token", valid_592512
  var valid_592513 = header.getOrDefault("X-Amz-Algorithm")
  valid_592513 = validateParameter(valid_592513, JString, required = false,
                                 default = nil)
  if valid_592513 != nil:
    section.add "X-Amz-Algorithm", valid_592513
  var valid_592514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592514 = validateParameter(valid_592514, JString, required = false,
                                 default = nil)
  if valid_592514 != nil:
    section.add "X-Amz-SignedHeaders", valid_592514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592516: Call_ListTagsForResource_592504; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of all tags for the specified AppStream 2.0 resource. You can tag AppStream 2.0 image builders, images, fleets, and stacks.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
  ## 
  let valid = call_592516.validator(path, query, header, formData, body)
  let scheme = call_592516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592516.url(scheme.get, call_592516.host, call_592516.base,
                         call_592516.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592516, url, valid)

proc call*(call_592517: Call_ListTagsForResource_592504; body: JsonNode): Recallable =
  ## listTagsForResource
  ## <p>Retrieves a list of all tags for the specified AppStream 2.0 resource. You can tag AppStream 2.0 image builders, images, fleets, and stacks.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
  ##   body: JObject (required)
  var body_592518 = newJObject()
  if body != nil:
    body_592518 = body
  result = call_592517.call(nil, nil, nil, nil, body_592518)

var listTagsForResource* = Call_ListTagsForResource_592504(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.ListTagsForResource",
    validator: validate_ListTagsForResource_592505, base: "/",
    url: url_ListTagsForResource_592506, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartFleet_592519 = ref object of OpenApiRestCall_591364
proc url_StartFleet_592521(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartFleet_592520(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592522 = header.getOrDefault("X-Amz-Target")
  valid_592522 = validateParameter(valid_592522, JString, required = true, default = newJString(
      "PhotonAdminProxyService.StartFleet"))
  if valid_592522 != nil:
    section.add "X-Amz-Target", valid_592522
  var valid_592523 = header.getOrDefault("X-Amz-Signature")
  valid_592523 = validateParameter(valid_592523, JString, required = false,
                                 default = nil)
  if valid_592523 != nil:
    section.add "X-Amz-Signature", valid_592523
  var valid_592524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592524 = validateParameter(valid_592524, JString, required = false,
                                 default = nil)
  if valid_592524 != nil:
    section.add "X-Amz-Content-Sha256", valid_592524
  var valid_592525 = header.getOrDefault("X-Amz-Date")
  valid_592525 = validateParameter(valid_592525, JString, required = false,
                                 default = nil)
  if valid_592525 != nil:
    section.add "X-Amz-Date", valid_592525
  var valid_592526 = header.getOrDefault("X-Amz-Credential")
  valid_592526 = validateParameter(valid_592526, JString, required = false,
                                 default = nil)
  if valid_592526 != nil:
    section.add "X-Amz-Credential", valid_592526
  var valid_592527 = header.getOrDefault("X-Amz-Security-Token")
  valid_592527 = validateParameter(valid_592527, JString, required = false,
                                 default = nil)
  if valid_592527 != nil:
    section.add "X-Amz-Security-Token", valid_592527
  var valid_592528 = header.getOrDefault("X-Amz-Algorithm")
  valid_592528 = validateParameter(valid_592528, JString, required = false,
                                 default = nil)
  if valid_592528 != nil:
    section.add "X-Amz-Algorithm", valid_592528
  var valid_592529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592529 = validateParameter(valid_592529, JString, required = false,
                                 default = nil)
  if valid_592529 != nil:
    section.add "X-Amz-SignedHeaders", valid_592529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592531: Call_StartFleet_592519; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the specified fleet.
  ## 
  let valid = call_592531.validator(path, query, header, formData, body)
  let scheme = call_592531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592531.url(scheme.get, call_592531.host, call_592531.base,
                         call_592531.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592531, url, valid)

proc call*(call_592532: Call_StartFleet_592519; body: JsonNode): Recallable =
  ## startFleet
  ## Starts the specified fleet.
  ##   body: JObject (required)
  var body_592533 = newJObject()
  if body != nil:
    body_592533 = body
  result = call_592532.call(nil, nil, nil, nil, body_592533)

var startFleet* = Call_StartFleet_592519(name: "startFleet",
                                      meth: HttpMethod.HttpPost,
                                      host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.StartFleet",
                                      validator: validate_StartFleet_592520,
                                      base: "/", url: url_StartFleet_592521,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImageBuilder_592534 = ref object of OpenApiRestCall_591364
proc url_StartImageBuilder_592536(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartImageBuilder_592535(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592537 = header.getOrDefault("X-Amz-Target")
  valid_592537 = validateParameter(valid_592537, JString, required = true, default = newJString(
      "PhotonAdminProxyService.StartImageBuilder"))
  if valid_592537 != nil:
    section.add "X-Amz-Target", valid_592537
  var valid_592538 = header.getOrDefault("X-Amz-Signature")
  valid_592538 = validateParameter(valid_592538, JString, required = false,
                                 default = nil)
  if valid_592538 != nil:
    section.add "X-Amz-Signature", valid_592538
  var valid_592539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592539 = validateParameter(valid_592539, JString, required = false,
                                 default = nil)
  if valid_592539 != nil:
    section.add "X-Amz-Content-Sha256", valid_592539
  var valid_592540 = header.getOrDefault("X-Amz-Date")
  valid_592540 = validateParameter(valid_592540, JString, required = false,
                                 default = nil)
  if valid_592540 != nil:
    section.add "X-Amz-Date", valid_592540
  var valid_592541 = header.getOrDefault("X-Amz-Credential")
  valid_592541 = validateParameter(valid_592541, JString, required = false,
                                 default = nil)
  if valid_592541 != nil:
    section.add "X-Amz-Credential", valid_592541
  var valid_592542 = header.getOrDefault("X-Amz-Security-Token")
  valid_592542 = validateParameter(valid_592542, JString, required = false,
                                 default = nil)
  if valid_592542 != nil:
    section.add "X-Amz-Security-Token", valid_592542
  var valid_592543 = header.getOrDefault("X-Amz-Algorithm")
  valid_592543 = validateParameter(valid_592543, JString, required = false,
                                 default = nil)
  if valid_592543 != nil:
    section.add "X-Amz-Algorithm", valid_592543
  var valid_592544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592544 = validateParameter(valid_592544, JString, required = false,
                                 default = nil)
  if valid_592544 != nil:
    section.add "X-Amz-SignedHeaders", valid_592544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592546: Call_StartImageBuilder_592534; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the specified image builder.
  ## 
  let valid = call_592546.validator(path, query, header, formData, body)
  let scheme = call_592546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592546.url(scheme.get, call_592546.host, call_592546.base,
                         call_592546.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592546, url, valid)

proc call*(call_592547: Call_StartImageBuilder_592534; body: JsonNode): Recallable =
  ## startImageBuilder
  ## Starts the specified image builder.
  ##   body: JObject (required)
  var body_592548 = newJObject()
  if body != nil:
    body_592548 = body
  result = call_592547.call(nil, nil, nil, nil, body_592548)

var startImageBuilder* = Call_StartImageBuilder_592534(name: "startImageBuilder",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.StartImageBuilder",
    validator: validate_StartImageBuilder_592535, base: "/",
    url: url_StartImageBuilder_592536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopFleet_592549 = ref object of OpenApiRestCall_591364
proc url_StopFleet_592551(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopFleet_592550(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592552 = header.getOrDefault("X-Amz-Target")
  valid_592552 = validateParameter(valid_592552, JString, required = true, default = newJString(
      "PhotonAdminProxyService.StopFleet"))
  if valid_592552 != nil:
    section.add "X-Amz-Target", valid_592552
  var valid_592553 = header.getOrDefault("X-Amz-Signature")
  valid_592553 = validateParameter(valid_592553, JString, required = false,
                                 default = nil)
  if valid_592553 != nil:
    section.add "X-Amz-Signature", valid_592553
  var valid_592554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592554 = validateParameter(valid_592554, JString, required = false,
                                 default = nil)
  if valid_592554 != nil:
    section.add "X-Amz-Content-Sha256", valid_592554
  var valid_592555 = header.getOrDefault("X-Amz-Date")
  valid_592555 = validateParameter(valid_592555, JString, required = false,
                                 default = nil)
  if valid_592555 != nil:
    section.add "X-Amz-Date", valid_592555
  var valid_592556 = header.getOrDefault("X-Amz-Credential")
  valid_592556 = validateParameter(valid_592556, JString, required = false,
                                 default = nil)
  if valid_592556 != nil:
    section.add "X-Amz-Credential", valid_592556
  var valid_592557 = header.getOrDefault("X-Amz-Security-Token")
  valid_592557 = validateParameter(valid_592557, JString, required = false,
                                 default = nil)
  if valid_592557 != nil:
    section.add "X-Amz-Security-Token", valid_592557
  var valid_592558 = header.getOrDefault("X-Amz-Algorithm")
  valid_592558 = validateParameter(valid_592558, JString, required = false,
                                 default = nil)
  if valid_592558 != nil:
    section.add "X-Amz-Algorithm", valid_592558
  var valid_592559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592559 = validateParameter(valid_592559, JString, required = false,
                                 default = nil)
  if valid_592559 != nil:
    section.add "X-Amz-SignedHeaders", valid_592559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592561: Call_StopFleet_592549; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the specified fleet.
  ## 
  let valid = call_592561.validator(path, query, header, formData, body)
  let scheme = call_592561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592561.url(scheme.get, call_592561.host, call_592561.base,
                         call_592561.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592561, url, valid)

proc call*(call_592562: Call_StopFleet_592549; body: JsonNode): Recallable =
  ## stopFleet
  ## Stops the specified fleet.
  ##   body: JObject (required)
  var body_592563 = newJObject()
  if body != nil:
    body_592563 = body
  result = call_592562.call(nil, nil, nil, nil, body_592563)

var stopFleet* = Call_StopFleet_592549(name: "stopFleet", meth: HttpMethod.HttpPost,
                                    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.StopFleet",
                                    validator: validate_StopFleet_592550,
                                    base: "/", url: url_StopFleet_592551,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopImageBuilder_592564 = ref object of OpenApiRestCall_591364
proc url_StopImageBuilder_592566(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopImageBuilder_592565(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592567 = header.getOrDefault("X-Amz-Target")
  valid_592567 = validateParameter(valid_592567, JString, required = true, default = newJString(
      "PhotonAdminProxyService.StopImageBuilder"))
  if valid_592567 != nil:
    section.add "X-Amz-Target", valid_592567
  var valid_592568 = header.getOrDefault("X-Amz-Signature")
  valid_592568 = validateParameter(valid_592568, JString, required = false,
                                 default = nil)
  if valid_592568 != nil:
    section.add "X-Amz-Signature", valid_592568
  var valid_592569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592569 = validateParameter(valid_592569, JString, required = false,
                                 default = nil)
  if valid_592569 != nil:
    section.add "X-Amz-Content-Sha256", valid_592569
  var valid_592570 = header.getOrDefault("X-Amz-Date")
  valid_592570 = validateParameter(valid_592570, JString, required = false,
                                 default = nil)
  if valid_592570 != nil:
    section.add "X-Amz-Date", valid_592570
  var valid_592571 = header.getOrDefault("X-Amz-Credential")
  valid_592571 = validateParameter(valid_592571, JString, required = false,
                                 default = nil)
  if valid_592571 != nil:
    section.add "X-Amz-Credential", valid_592571
  var valid_592572 = header.getOrDefault("X-Amz-Security-Token")
  valid_592572 = validateParameter(valid_592572, JString, required = false,
                                 default = nil)
  if valid_592572 != nil:
    section.add "X-Amz-Security-Token", valid_592572
  var valid_592573 = header.getOrDefault("X-Amz-Algorithm")
  valid_592573 = validateParameter(valid_592573, JString, required = false,
                                 default = nil)
  if valid_592573 != nil:
    section.add "X-Amz-Algorithm", valid_592573
  var valid_592574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592574 = validateParameter(valid_592574, JString, required = false,
                                 default = nil)
  if valid_592574 != nil:
    section.add "X-Amz-SignedHeaders", valid_592574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592576: Call_StopImageBuilder_592564; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the specified image builder.
  ## 
  let valid = call_592576.validator(path, query, header, formData, body)
  let scheme = call_592576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592576.url(scheme.get, call_592576.host, call_592576.base,
                         call_592576.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592576, url, valid)

proc call*(call_592577: Call_StopImageBuilder_592564; body: JsonNode): Recallable =
  ## stopImageBuilder
  ## Stops the specified image builder.
  ##   body: JObject (required)
  var body_592578 = newJObject()
  if body != nil:
    body_592578 = body
  result = call_592577.call(nil, nil, nil, nil, body_592578)

var stopImageBuilder* = Call_StopImageBuilder_592564(name: "stopImageBuilder",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.StopImageBuilder",
    validator: validate_StopImageBuilder_592565, base: "/",
    url: url_StopImageBuilder_592566, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_592579 = ref object of OpenApiRestCall_591364
proc url_TagResource_592581(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_592580(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592582 = header.getOrDefault("X-Amz-Target")
  valid_592582 = validateParameter(valid_592582, JString, required = true, default = newJString(
      "PhotonAdminProxyService.TagResource"))
  if valid_592582 != nil:
    section.add "X-Amz-Target", valid_592582
  var valid_592583 = header.getOrDefault("X-Amz-Signature")
  valid_592583 = validateParameter(valid_592583, JString, required = false,
                                 default = nil)
  if valid_592583 != nil:
    section.add "X-Amz-Signature", valid_592583
  var valid_592584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592584 = validateParameter(valid_592584, JString, required = false,
                                 default = nil)
  if valid_592584 != nil:
    section.add "X-Amz-Content-Sha256", valid_592584
  var valid_592585 = header.getOrDefault("X-Amz-Date")
  valid_592585 = validateParameter(valid_592585, JString, required = false,
                                 default = nil)
  if valid_592585 != nil:
    section.add "X-Amz-Date", valid_592585
  var valid_592586 = header.getOrDefault("X-Amz-Credential")
  valid_592586 = validateParameter(valid_592586, JString, required = false,
                                 default = nil)
  if valid_592586 != nil:
    section.add "X-Amz-Credential", valid_592586
  var valid_592587 = header.getOrDefault("X-Amz-Security-Token")
  valid_592587 = validateParameter(valid_592587, JString, required = false,
                                 default = nil)
  if valid_592587 != nil:
    section.add "X-Amz-Security-Token", valid_592587
  var valid_592588 = header.getOrDefault("X-Amz-Algorithm")
  valid_592588 = validateParameter(valid_592588, JString, required = false,
                                 default = nil)
  if valid_592588 != nil:
    section.add "X-Amz-Algorithm", valid_592588
  var valid_592589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592589 = validateParameter(valid_592589, JString, required = false,
                                 default = nil)
  if valid_592589 != nil:
    section.add "X-Amz-SignedHeaders", valid_592589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592591: Call_TagResource_592579; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or overwrites one or more tags for the specified AppStream 2.0 resource. You can tag AppStream 2.0 image builders, images, fleets, and stacks.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, this operation updates its value.</p> <p>To list the current tags for your resources, use <a>ListTagsForResource</a>. To disassociate tags from your resources, use <a>UntagResource</a>.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
  ## 
  let valid = call_592591.validator(path, query, header, formData, body)
  let scheme = call_592591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592591.url(scheme.get, call_592591.host, call_592591.base,
                         call_592591.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592591, url, valid)

proc call*(call_592592: Call_TagResource_592579; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds or overwrites one or more tags for the specified AppStream 2.0 resource. You can tag AppStream 2.0 image builders, images, fleets, and stacks.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, this operation updates its value.</p> <p>To list the current tags for your resources, use <a>ListTagsForResource</a>. To disassociate tags from your resources, use <a>UntagResource</a>.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
  ##   body: JObject (required)
  var body_592593 = newJObject()
  if body != nil:
    body_592593 = body
  result = call_592592.call(nil, nil, nil, nil, body_592593)

var tagResource* = Call_TagResource_592579(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.TagResource",
                                        validator: validate_TagResource_592580,
                                        base: "/", url: url_TagResource_592581,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_592594 = ref object of OpenApiRestCall_591364
proc url_UntagResource_592596(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_592595(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592597 = header.getOrDefault("X-Amz-Target")
  valid_592597 = validateParameter(valid_592597, JString, required = true, default = newJString(
      "PhotonAdminProxyService.UntagResource"))
  if valid_592597 != nil:
    section.add "X-Amz-Target", valid_592597
  var valid_592598 = header.getOrDefault("X-Amz-Signature")
  valid_592598 = validateParameter(valid_592598, JString, required = false,
                                 default = nil)
  if valid_592598 != nil:
    section.add "X-Amz-Signature", valid_592598
  var valid_592599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592599 = validateParameter(valid_592599, JString, required = false,
                                 default = nil)
  if valid_592599 != nil:
    section.add "X-Amz-Content-Sha256", valid_592599
  var valid_592600 = header.getOrDefault("X-Amz-Date")
  valid_592600 = validateParameter(valid_592600, JString, required = false,
                                 default = nil)
  if valid_592600 != nil:
    section.add "X-Amz-Date", valid_592600
  var valid_592601 = header.getOrDefault("X-Amz-Credential")
  valid_592601 = validateParameter(valid_592601, JString, required = false,
                                 default = nil)
  if valid_592601 != nil:
    section.add "X-Amz-Credential", valid_592601
  var valid_592602 = header.getOrDefault("X-Amz-Security-Token")
  valid_592602 = validateParameter(valid_592602, JString, required = false,
                                 default = nil)
  if valid_592602 != nil:
    section.add "X-Amz-Security-Token", valid_592602
  var valid_592603 = header.getOrDefault("X-Amz-Algorithm")
  valid_592603 = validateParameter(valid_592603, JString, required = false,
                                 default = nil)
  if valid_592603 != nil:
    section.add "X-Amz-Algorithm", valid_592603
  var valid_592604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592604 = validateParameter(valid_592604, JString, required = false,
                                 default = nil)
  if valid_592604 != nil:
    section.add "X-Amz-SignedHeaders", valid_592604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592606: Call_UntagResource_592594; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates one or more specified tags from the specified AppStream 2.0 resource.</p> <p>To list the current tags for your resources, use <a>ListTagsForResource</a>.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
  ## 
  let valid = call_592606.validator(path, query, header, formData, body)
  let scheme = call_592606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592606.url(scheme.get, call_592606.host, call_592606.base,
                         call_592606.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592606, url, valid)

proc call*(call_592607: Call_UntagResource_592594; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Disassociates one or more specified tags from the specified AppStream 2.0 resource.</p> <p>To list the current tags for your resources, use <a>ListTagsForResource</a>.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
  ##   body: JObject (required)
  var body_592608 = newJObject()
  if body != nil:
    body_592608 = body
  result = call_592607.call(nil, nil, nil, nil, body_592608)

var untagResource* = Call_UntagResource_592594(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.UntagResource",
    validator: validate_UntagResource_592595, base: "/", url: url_UntagResource_592596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDirectoryConfig_592609 = ref object of OpenApiRestCall_591364
proc url_UpdateDirectoryConfig_592611(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDirectoryConfig_592610(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592612 = header.getOrDefault("X-Amz-Target")
  valid_592612 = validateParameter(valid_592612, JString, required = true, default = newJString(
      "PhotonAdminProxyService.UpdateDirectoryConfig"))
  if valid_592612 != nil:
    section.add "X-Amz-Target", valid_592612
  var valid_592613 = header.getOrDefault("X-Amz-Signature")
  valid_592613 = validateParameter(valid_592613, JString, required = false,
                                 default = nil)
  if valid_592613 != nil:
    section.add "X-Amz-Signature", valid_592613
  var valid_592614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592614 = validateParameter(valid_592614, JString, required = false,
                                 default = nil)
  if valid_592614 != nil:
    section.add "X-Amz-Content-Sha256", valid_592614
  var valid_592615 = header.getOrDefault("X-Amz-Date")
  valid_592615 = validateParameter(valid_592615, JString, required = false,
                                 default = nil)
  if valid_592615 != nil:
    section.add "X-Amz-Date", valid_592615
  var valid_592616 = header.getOrDefault("X-Amz-Credential")
  valid_592616 = validateParameter(valid_592616, JString, required = false,
                                 default = nil)
  if valid_592616 != nil:
    section.add "X-Amz-Credential", valid_592616
  var valid_592617 = header.getOrDefault("X-Amz-Security-Token")
  valid_592617 = validateParameter(valid_592617, JString, required = false,
                                 default = nil)
  if valid_592617 != nil:
    section.add "X-Amz-Security-Token", valid_592617
  var valid_592618 = header.getOrDefault("X-Amz-Algorithm")
  valid_592618 = validateParameter(valid_592618, JString, required = false,
                                 default = nil)
  if valid_592618 != nil:
    section.add "X-Amz-Algorithm", valid_592618
  var valid_592619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592619 = validateParameter(valid_592619, JString, required = false,
                                 default = nil)
  if valid_592619 != nil:
    section.add "X-Amz-SignedHeaders", valid_592619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592621: Call_UpdateDirectoryConfig_592609; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified Directory Config object in AppStream 2.0. This object includes the configuration information required to join fleets and image builders to Microsoft Active Directory domains.
  ## 
  let valid = call_592621.validator(path, query, header, formData, body)
  let scheme = call_592621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592621.url(scheme.get, call_592621.host, call_592621.base,
                         call_592621.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592621, url, valid)

proc call*(call_592622: Call_UpdateDirectoryConfig_592609; body: JsonNode): Recallable =
  ## updateDirectoryConfig
  ## Updates the specified Directory Config object in AppStream 2.0. This object includes the configuration information required to join fleets and image builders to Microsoft Active Directory domains.
  ##   body: JObject (required)
  var body_592623 = newJObject()
  if body != nil:
    body_592623 = body
  result = call_592622.call(nil, nil, nil, nil, body_592623)

var updateDirectoryConfig* = Call_UpdateDirectoryConfig_592609(
    name: "updateDirectoryConfig", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.UpdateDirectoryConfig",
    validator: validate_UpdateDirectoryConfig_592610, base: "/",
    url: url_UpdateDirectoryConfig_592611, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFleet_592624 = ref object of OpenApiRestCall_591364
proc url_UpdateFleet_592626(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateFleet_592625(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592627 = header.getOrDefault("X-Amz-Target")
  valid_592627 = validateParameter(valid_592627, JString, required = true, default = newJString(
      "PhotonAdminProxyService.UpdateFleet"))
  if valid_592627 != nil:
    section.add "X-Amz-Target", valid_592627
  var valid_592628 = header.getOrDefault("X-Amz-Signature")
  valid_592628 = validateParameter(valid_592628, JString, required = false,
                                 default = nil)
  if valid_592628 != nil:
    section.add "X-Amz-Signature", valid_592628
  var valid_592629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592629 = validateParameter(valid_592629, JString, required = false,
                                 default = nil)
  if valid_592629 != nil:
    section.add "X-Amz-Content-Sha256", valid_592629
  var valid_592630 = header.getOrDefault("X-Amz-Date")
  valid_592630 = validateParameter(valid_592630, JString, required = false,
                                 default = nil)
  if valid_592630 != nil:
    section.add "X-Amz-Date", valid_592630
  var valid_592631 = header.getOrDefault("X-Amz-Credential")
  valid_592631 = validateParameter(valid_592631, JString, required = false,
                                 default = nil)
  if valid_592631 != nil:
    section.add "X-Amz-Credential", valid_592631
  var valid_592632 = header.getOrDefault("X-Amz-Security-Token")
  valid_592632 = validateParameter(valid_592632, JString, required = false,
                                 default = nil)
  if valid_592632 != nil:
    section.add "X-Amz-Security-Token", valid_592632
  var valid_592633 = header.getOrDefault("X-Amz-Algorithm")
  valid_592633 = validateParameter(valid_592633, JString, required = false,
                                 default = nil)
  if valid_592633 != nil:
    section.add "X-Amz-Algorithm", valid_592633
  var valid_592634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592634 = validateParameter(valid_592634, JString, required = false,
                                 default = nil)
  if valid_592634 != nil:
    section.add "X-Amz-SignedHeaders", valid_592634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592636: Call_UpdateFleet_592624; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified fleet.</p> <p>If the fleet is in the <code>STOPPED</code> state, you can update any attribute except the fleet name. If the fleet is in the <code>RUNNING</code> state, you can update the <code>DisplayName</code>, <code>ComputeCapacity</code>, <code>ImageARN</code>, <code>ImageName</code>, <code>IdleDisconnectTimeoutInSeconds</code>, and <code>DisconnectTimeoutInSeconds</code> attributes. If the fleet is in the <code>STARTING</code> or <code>STOPPING</code> state, you can't update it.</p>
  ## 
  let valid = call_592636.validator(path, query, header, formData, body)
  let scheme = call_592636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592636.url(scheme.get, call_592636.host, call_592636.base,
                         call_592636.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592636, url, valid)

proc call*(call_592637: Call_UpdateFleet_592624; body: JsonNode): Recallable =
  ## updateFleet
  ## <p>Updates the specified fleet.</p> <p>If the fleet is in the <code>STOPPED</code> state, you can update any attribute except the fleet name. If the fleet is in the <code>RUNNING</code> state, you can update the <code>DisplayName</code>, <code>ComputeCapacity</code>, <code>ImageARN</code>, <code>ImageName</code>, <code>IdleDisconnectTimeoutInSeconds</code>, and <code>DisconnectTimeoutInSeconds</code> attributes. If the fleet is in the <code>STARTING</code> or <code>STOPPING</code> state, you can't update it.</p>
  ##   body: JObject (required)
  var body_592638 = newJObject()
  if body != nil:
    body_592638 = body
  result = call_592637.call(nil, nil, nil, nil, body_592638)

var updateFleet* = Call_UpdateFleet_592624(name: "updateFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.UpdateFleet",
                                        validator: validate_UpdateFleet_592625,
                                        base: "/", url: url_UpdateFleet_592626,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateImagePermissions_592639 = ref object of OpenApiRestCall_591364
proc url_UpdateImagePermissions_592641(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateImagePermissions_592640(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592642 = header.getOrDefault("X-Amz-Target")
  valid_592642 = validateParameter(valid_592642, JString, required = true, default = newJString(
      "PhotonAdminProxyService.UpdateImagePermissions"))
  if valid_592642 != nil:
    section.add "X-Amz-Target", valid_592642
  var valid_592643 = header.getOrDefault("X-Amz-Signature")
  valid_592643 = validateParameter(valid_592643, JString, required = false,
                                 default = nil)
  if valid_592643 != nil:
    section.add "X-Amz-Signature", valid_592643
  var valid_592644 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592644 = validateParameter(valid_592644, JString, required = false,
                                 default = nil)
  if valid_592644 != nil:
    section.add "X-Amz-Content-Sha256", valid_592644
  var valid_592645 = header.getOrDefault("X-Amz-Date")
  valid_592645 = validateParameter(valid_592645, JString, required = false,
                                 default = nil)
  if valid_592645 != nil:
    section.add "X-Amz-Date", valid_592645
  var valid_592646 = header.getOrDefault("X-Amz-Credential")
  valid_592646 = validateParameter(valid_592646, JString, required = false,
                                 default = nil)
  if valid_592646 != nil:
    section.add "X-Amz-Credential", valid_592646
  var valid_592647 = header.getOrDefault("X-Amz-Security-Token")
  valid_592647 = validateParameter(valid_592647, JString, required = false,
                                 default = nil)
  if valid_592647 != nil:
    section.add "X-Amz-Security-Token", valid_592647
  var valid_592648 = header.getOrDefault("X-Amz-Algorithm")
  valid_592648 = validateParameter(valid_592648, JString, required = false,
                                 default = nil)
  if valid_592648 != nil:
    section.add "X-Amz-Algorithm", valid_592648
  var valid_592649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592649 = validateParameter(valid_592649, JString, required = false,
                                 default = nil)
  if valid_592649 != nil:
    section.add "X-Amz-SignedHeaders", valid_592649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592651: Call_UpdateImagePermissions_592639; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates permissions for the specified private image. 
  ## 
  let valid = call_592651.validator(path, query, header, formData, body)
  let scheme = call_592651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592651.url(scheme.get, call_592651.host, call_592651.base,
                         call_592651.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592651, url, valid)

proc call*(call_592652: Call_UpdateImagePermissions_592639; body: JsonNode): Recallable =
  ## updateImagePermissions
  ## Adds or updates permissions for the specified private image. 
  ##   body: JObject (required)
  var body_592653 = newJObject()
  if body != nil:
    body_592653 = body
  result = call_592652.call(nil, nil, nil, nil, body_592653)

var updateImagePermissions* = Call_UpdateImagePermissions_592639(
    name: "updateImagePermissions", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.UpdateImagePermissions",
    validator: validate_UpdateImagePermissions_592640, base: "/",
    url: url_UpdateImagePermissions_592641, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStack_592654 = ref object of OpenApiRestCall_591364
proc url_UpdateStack_592656(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateStack_592655(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592657 = header.getOrDefault("X-Amz-Target")
  valid_592657 = validateParameter(valid_592657, JString, required = true, default = newJString(
      "PhotonAdminProxyService.UpdateStack"))
  if valid_592657 != nil:
    section.add "X-Amz-Target", valid_592657
  var valid_592658 = header.getOrDefault("X-Amz-Signature")
  valid_592658 = validateParameter(valid_592658, JString, required = false,
                                 default = nil)
  if valid_592658 != nil:
    section.add "X-Amz-Signature", valid_592658
  var valid_592659 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592659 = validateParameter(valid_592659, JString, required = false,
                                 default = nil)
  if valid_592659 != nil:
    section.add "X-Amz-Content-Sha256", valid_592659
  var valid_592660 = header.getOrDefault("X-Amz-Date")
  valid_592660 = validateParameter(valid_592660, JString, required = false,
                                 default = nil)
  if valid_592660 != nil:
    section.add "X-Amz-Date", valid_592660
  var valid_592661 = header.getOrDefault("X-Amz-Credential")
  valid_592661 = validateParameter(valid_592661, JString, required = false,
                                 default = nil)
  if valid_592661 != nil:
    section.add "X-Amz-Credential", valid_592661
  var valid_592662 = header.getOrDefault("X-Amz-Security-Token")
  valid_592662 = validateParameter(valid_592662, JString, required = false,
                                 default = nil)
  if valid_592662 != nil:
    section.add "X-Amz-Security-Token", valid_592662
  var valid_592663 = header.getOrDefault("X-Amz-Algorithm")
  valid_592663 = validateParameter(valid_592663, JString, required = false,
                                 default = nil)
  if valid_592663 != nil:
    section.add "X-Amz-Algorithm", valid_592663
  var valid_592664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592664 = validateParameter(valid_592664, JString, required = false,
                                 default = nil)
  if valid_592664 != nil:
    section.add "X-Amz-SignedHeaders", valid_592664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592666: Call_UpdateStack_592654; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified fields for the specified stack.
  ## 
  let valid = call_592666.validator(path, query, header, formData, body)
  let scheme = call_592666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592666.url(scheme.get, call_592666.host, call_592666.base,
                         call_592666.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592666, url, valid)

proc call*(call_592667: Call_UpdateStack_592654; body: JsonNode): Recallable =
  ## updateStack
  ## Updates the specified fields for the specified stack.
  ##   body: JObject (required)
  var body_592668 = newJObject()
  if body != nil:
    body_592668 = body
  result = call_592667.call(nil, nil, nil, nil, body_592668)

var updateStack* = Call_UpdateStack_592654(name: "updateStack",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.UpdateStack",
                                        validator: validate_UpdateStack_592655,
                                        base: "/", url: url_UpdateStack_592656,
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
