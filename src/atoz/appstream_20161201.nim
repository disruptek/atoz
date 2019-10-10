
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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
  Call_AssociateFleet_602803 = ref object of OpenApiRestCall_602466
proc url_AssociateFleet_602805(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateFleet_602804(path: JsonNode; query: JsonNode;
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
  var valid_602917 = header.getOrDefault("X-Amz-Date")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Date", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Security-Token")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Security-Token", valid_602918
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602932 = header.getOrDefault("X-Amz-Target")
  valid_602932 = validateParameter(valid_602932, JString, required = true, default = newJString(
      "PhotonAdminProxyService.AssociateFleet"))
  if valid_602932 != nil:
    section.add "X-Amz-Target", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Content-Sha256", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Algorithm")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Algorithm", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Signature")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Signature", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-SignedHeaders", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Credential")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Credential", valid_602937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602961: Call_AssociateFleet_602803; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified fleet with the specified stack.
  ## 
  let valid = call_602961.validator(path, query, header, formData, body)
  let scheme = call_602961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602961.url(scheme.get, call_602961.host, call_602961.base,
                         call_602961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602961, url, valid)

proc call*(call_603032: Call_AssociateFleet_602803; body: JsonNode): Recallable =
  ## associateFleet
  ## Associates the specified fleet with the specified stack.
  ##   body: JObject (required)
  var body_603033 = newJObject()
  if body != nil:
    body_603033 = body
  result = call_603032.call(nil, nil, nil, nil, body_603033)

var associateFleet* = Call_AssociateFleet_602803(name: "associateFleet",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.AssociateFleet",
    validator: validate_AssociateFleet_602804, base: "/", url: url_AssociateFleet_602805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchAssociateUserStack_603072 = ref object of OpenApiRestCall_602466
proc url_BatchAssociateUserStack_603074(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchAssociateUserStack_603073(path: JsonNode; query: JsonNode;
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
  var valid_603075 = header.getOrDefault("X-Amz-Date")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Date", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Security-Token")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Security-Token", valid_603076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603077 = header.getOrDefault("X-Amz-Target")
  valid_603077 = validateParameter(valid_603077, JString, required = true, default = newJString(
      "PhotonAdminProxyService.BatchAssociateUserStack"))
  if valid_603077 != nil:
    section.add "X-Amz-Target", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Content-Sha256", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Algorithm")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Algorithm", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Signature")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Signature", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-SignedHeaders", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Credential")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Credential", valid_603082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603084: Call_BatchAssociateUserStack_603072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified users with the specified stacks. Users in a user pool cannot be assigned to stacks with fleets that are joined to an Active Directory domain.
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603084, url, valid)

proc call*(call_603085: Call_BatchAssociateUserStack_603072; body: JsonNode): Recallable =
  ## batchAssociateUserStack
  ## Associates the specified users with the specified stacks. Users in a user pool cannot be assigned to stacks with fleets that are joined to an Active Directory domain.
  ##   body: JObject (required)
  var body_603086 = newJObject()
  if body != nil:
    body_603086 = body
  result = call_603085.call(nil, nil, nil, nil, body_603086)

var batchAssociateUserStack* = Call_BatchAssociateUserStack_603072(
    name: "batchAssociateUserStack", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.BatchAssociateUserStack",
    validator: validate_BatchAssociateUserStack_603073, base: "/",
    url: url_BatchAssociateUserStack_603074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDisassociateUserStack_603087 = ref object of OpenApiRestCall_602466
proc url_BatchDisassociateUserStack_603089(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDisassociateUserStack_603088(path: JsonNode; query: JsonNode;
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
  var valid_603090 = header.getOrDefault("X-Amz-Date")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Date", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Security-Token")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Security-Token", valid_603091
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603092 = header.getOrDefault("X-Amz-Target")
  valid_603092 = validateParameter(valid_603092, JString, required = true, default = newJString(
      "PhotonAdminProxyService.BatchDisassociateUserStack"))
  if valid_603092 != nil:
    section.add "X-Amz-Target", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Content-Sha256", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Algorithm")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Algorithm", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Signature")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Signature", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-SignedHeaders", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Credential")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Credential", valid_603097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603099: Call_BatchDisassociateUserStack_603087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified users from the specified stacks.
  ## 
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_BatchDisassociateUserStack_603087; body: JsonNode): Recallable =
  ## batchDisassociateUserStack
  ## Disassociates the specified users from the specified stacks.
  ##   body: JObject (required)
  var body_603101 = newJObject()
  if body != nil:
    body_603101 = body
  result = call_603100.call(nil, nil, nil, nil, body_603101)

var batchDisassociateUserStack* = Call_BatchDisassociateUserStack_603087(
    name: "batchDisassociateUserStack", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.BatchDisassociateUserStack",
    validator: validate_BatchDisassociateUserStack_603088, base: "/",
    url: url_BatchDisassociateUserStack_603089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyImage_603102 = ref object of OpenApiRestCall_602466
proc url_CopyImage_603104(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CopyImage_603103(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603105 = header.getOrDefault("X-Amz-Date")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Date", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Security-Token")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Security-Token", valid_603106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603107 = header.getOrDefault("X-Amz-Target")
  valid_603107 = validateParameter(valid_603107, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CopyImage"))
  if valid_603107 != nil:
    section.add "X-Amz-Target", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Content-Sha256", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Algorithm")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Algorithm", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Signature")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Signature", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-SignedHeaders", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Credential")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Credential", valid_603112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603114: Call_CopyImage_603102; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the image within the same region or to a new region within the same AWS account. Note that any tags you added to the image will not be copied.
  ## 
  let valid = call_603114.validator(path, query, header, formData, body)
  let scheme = call_603114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603114.url(scheme.get, call_603114.host, call_603114.base,
                         call_603114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603114, url, valid)

proc call*(call_603115: Call_CopyImage_603102; body: JsonNode): Recallable =
  ## copyImage
  ## Copies the image within the same region or to a new region within the same AWS account. Note that any tags you added to the image will not be copied.
  ##   body: JObject (required)
  var body_603116 = newJObject()
  if body != nil:
    body_603116 = body
  result = call_603115.call(nil, nil, nil, nil, body_603116)

var copyImage* = Call_CopyImage_603102(name: "copyImage", meth: HttpMethod.HttpPost,
                                    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.CopyImage",
                                    validator: validate_CopyImage_603103,
                                    base: "/", url: url_CopyImage_603104,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectoryConfig_603117 = ref object of OpenApiRestCall_602466
proc url_CreateDirectoryConfig_603119(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDirectoryConfig_603118(path: JsonNode; query: JsonNode;
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
  var valid_603120 = header.getOrDefault("X-Amz-Date")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Date", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Security-Token")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Security-Token", valid_603121
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603122 = header.getOrDefault("X-Amz-Target")
  valid_603122 = validateParameter(valid_603122, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CreateDirectoryConfig"))
  if valid_603122 != nil:
    section.add "X-Amz-Target", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Content-Sha256", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Algorithm")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Algorithm", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Signature")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Signature", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-SignedHeaders", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Credential")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Credential", valid_603127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603129: Call_CreateDirectoryConfig_603117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Directory Config object in AppStream 2.0. This object includes the configuration information required to join fleets and image builders to Microsoft Active Directory domains.
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_CreateDirectoryConfig_603117; body: JsonNode): Recallable =
  ## createDirectoryConfig
  ## Creates a Directory Config object in AppStream 2.0. This object includes the configuration information required to join fleets and image builders to Microsoft Active Directory domains.
  ##   body: JObject (required)
  var body_603131 = newJObject()
  if body != nil:
    body_603131 = body
  result = call_603130.call(nil, nil, nil, nil, body_603131)

var createDirectoryConfig* = Call_CreateDirectoryConfig_603117(
    name: "createDirectoryConfig", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.CreateDirectoryConfig",
    validator: validate_CreateDirectoryConfig_603118, base: "/",
    url: url_CreateDirectoryConfig_603119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFleet_603132 = ref object of OpenApiRestCall_602466
proc url_CreateFleet_603134(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateFleet_603133(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603135 = header.getOrDefault("X-Amz-Date")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Date", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Security-Token")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Security-Token", valid_603136
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603137 = header.getOrDefault("X-Amz-Target")
  valid_603137 = validateParameter(valid_603137, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CreateFleet"))
  if valid_603137 != nil:
    section.add "X-Amz-Target", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Content-Sha256", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Algorithm")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Algorithm", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Signature")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Signature", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-SignedHeaders", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Credential")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Credential", valid_603142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603144: Call_CreateFleet_603132; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a fleet. A fleet consists of streaming instances that run a specified image.
  ## 
  let valid = call_603144.validator(path, query, header, formData, body)
  let scheme = call_603144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603144.url(scheme.get, call_603144.host, call_603144.base,
                         call_603144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603144, url, valid)

proc call*(call_603145: Call_CreateFleet_603132; body: JsonNode): Recallable =
  ## createFleet
  ## Creates a fleet. A fleet consists of streaming instances that run a specified image.
  ##   body: JObject (required)
  var body_603146 = newJObject()
  if body != nil:
    body_603146 = body
  result = call_603145.call(nil, nil, nil, nil, body_603146)

var createFleet* = Call_CreateFleet_603132(name: "createFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.CreateFleet",
                                        validator: validate_CreateFleet_603133,
                                        base: "/", url: url_CreateFleet_603134,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImageBuilder_603147 = ref object of OpenApiRestCall_602466
proc url_CreateImageBuilder_603149(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateImageBuilder_603148(path: JsonNode; query: JsonNode;
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
  var valid_603150 = header.getOrDefault("X-Amz-Date")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Date", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Security-Token")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Security-Token", valid_603151
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603152 = header.getOrDefault("X-Amz-Target")
  valid_603152 = validateParameter(valid_603152, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CreateImageBuilder"))
  if valid_603152 != nil:
    section.add "X-Amz-Target", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Content-Sha256", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Algorithm")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Algorithm", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Signature")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Signature", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-SignedHeaders", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Credential")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Credential", valid_603157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603159: Call_CreateImageBuilder_603147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an image builder. An image builder is a virtual machine that is used to create an image.</p> <p>The initial state of the builder is <code>PENDING</code>. When it is ready, the state is <code>RUNNING</code>.</p>
  ## 
  let valid = call_603159.validator(path, query, header, formData, body)
  let scheme = call_603159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603159.url(scheme.get, call_603159.host, call_603159.base,
                         call_603159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603159, url, valid)

proc call*(call_603160: Call_CreateImageBuilder_603147; body: JsonNode): Recallable =
  ## createImageBuilder
  ## <p>Creates an image builder. An image builder is a virtual machine that is used to create an image.</p> <p>The initial state of the builder is <code>PENDING</code>. When it is ready, the state is <code>RUNNING</code>.</p>
  ##   body: JObject (required)
  var body_603161 = newJObject()
  if body != nil:
    body_603161 = body
  result = call_603160.call(nil, nil, nil, nil, body_603161)

var createImageBuilder* = Call_CreateImageBuilder_603147(
    name: "createImageBuilder", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.CreateImageBuilder",
    validator: validate_CreateImageBuilder_603148, base: "/",
    url: url_CreateImageBuilder_603149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImageBuilderStreamingURL_603162 = ref object of OpenApiRestCall_602466
proc url_CreateImageBuilderStreamingURL_603164(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateImageBuilderStreamingURL_603163(path: JsonNode;
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
  var valid_603165 = header.getOrDefault("X-Amz-Date")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Date", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Security-Token")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Security-Token", valid_603166
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603167 = header.getOrDefault("X-Amz-Target")
  valid_603167 = validateParameter(valid_603167, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CreateImageBuilderStreamingURL"))
  if valid_603167 != nil:
    section.add "X-Amz-Target", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Content-Sha256", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Algorithm")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Algorithm", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Signature")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Signature", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-SignedHeaders", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Credential")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Credential", valid_603172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603174: Call_CreateImageBuilderStreamingURL_603162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a URL to start an image builder streaming session.
  ## 
  let valid = call_603174.validator(path, query, header, formData, body)
  let scheme = call_603174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603174.url(scheme.get, call_603174.host, call_603174.base,
                         call_603174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603174, url, valid)

proc call*(call_603175: Call_CreateImageBuilderStreamingURL_603162; body: JsonNode): Recallable =
  ## createImageBuilderStreamingURL
  ## Creates a URL to start an image builder streaming session.
  ##   body: JObject (required)
  var body_603176 = newJObject()
  if body != nil:
    body_603176 = body
  result = call_603175.call(nil, nil, nil, nil, body_603176)

var createImageBuilderStreamingURL* = Call_CreateImageBuilderStreamingURL_603162(
    name: "createImageBuilderStreamingURL", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.CreateImageBuilderStreamingURL",
    validator: validate_CreateImageBuilderStreamingURL_603163, base: "/",
    url: url_CreateImageBuilderStreamingURL_603164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStack_603177 = ref object of OpenApiRestCall_602466
proc url_CreateStack_603179(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateStack_603178(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603180 = header.getOrDefault("X-Amz-Date")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Date", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Security-Token")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Security-Token", valid_603181
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603182 = header.getOrDefault("X-Amz-Target")
  valid_603182 = validateParameter(valid_603182, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CreateStack"))
  if valid_603182 != nil:
    section.add "X-Amz-Target", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Content-Sha256", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Algorithm")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Algorithm", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Signature")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Signature", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-SignedHeaders", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Credential")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Credential", valid_603187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603189: Call_CreateStack_603177; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a stack to start streaming applications to users. A stack consists of an associated fleet, user access policies, and storage configurations. 
  ## 
  let valid = call_603189.validator(path, query, header, formData, body)
  let scheme = call_603189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603189.url(scheme.get, call_603189.host, call_603189.base,
                         call_603189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603189, url, valid)

proc call*(call_603190: Call_CreateStack_603177; body: JsonNode): Recallable =
  ## createStack
  ## Creates a stack to start streaming applications to users. A stack consists of an associated fleet, user access policies, and storage configurations. 
  ##   body: JObject (required)
  var body_603191 = newJObject()
  if body != nil:
    body_603191 = body
  result = call_603190.call(nil, nil, nil, nil, body_603191)

var createStack* = Call_CreateStack_603177(name: "createStack",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.CreateStack",
                                        validator: validate_CreateStack_603178,
                                        base: "/", url: url_CreateStack_603179,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingURL_603192 = ref object of OpenApiRestCall_602466
proc url_CreateStreamingURL_603194(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateStreamingURL_603193(path: JsonNode; query: JsonNode;
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
  var valid_603195 = header.getOrDefault("X-Amz-Date")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Date", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Security-Token")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Security-Token", valid_603196
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603197 = header.getOrDefault("X-Amz-Target")
  valid_603197 = validateParameter(valid_603197, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CreateStreamingURL"))
  if valid_603197 != nil:
    section.add "X-Amz-Target", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Content-Sha256", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Algorithm")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Algorithm", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Signature")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Signature", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-SignedHeaders", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Credential")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Credential", valid_603202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603204: Call_CreateStreamingURL_603192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a temporary URL to start an AppStream 2.0 streaming session for the specified user. A streaming URL enables application streaming to be tested without user setup. 
  ## 
  let valid = call_603204.validator(path, query, header, formData, body)
  let scheme = call_603204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603204.url(scheme.get, call_603204.host, call_603204.base,
                         call_603204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603204, url, valid)

proc call*(call_603205: Call_CreateStreamingURL_603192; body: JsonNode): Recallable =
  ## createStreamingURL
  ## Creates a temporary URL to start an AppStream 2.0 streaming session for the specified user. A streaming URL enables application streaming to be tested without user setup. 
  ##   body: JObject (required)
  var body_603206 = newJObject()
  if body != nil:
    body_603206 = body
  result = call_603205.call(nil, nil, nil, nil, body_603206)

var createStreamingURL* = Call_CreateStreamingURL_603192(
    name: "createStreamingURL", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.CreateStreamingURL",
    validator: validate_CreateStreamingURL_603193, base: "/",
    url: url_CreateStreamingURL_603194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsageReportSubscription_603207 = ref object of OpenApiRestCall_602466
proc url_CreateUsageReportSubscription_603209(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateUsageReportSubscription_603208(path: JsonNode; query: JsonNode;
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
  var valid_603210 = header.getOrDefault("X-Amz-Date")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Date", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Security-Token")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Security-Token", valid_603211
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603212 = header.getOrDefault("X-Amz-Target")
  valid_603212 = validateParameter(valid_603212, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CreateUsageReportSubscription"))
  if valid_603212 != nil:
    section.add "X-Amz-Target", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Content-Sha256", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Algorithm")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Algorithm", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Signature")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Signature", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-SignedHeaders", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Credential")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Credential", valid_603217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603219: Call_CreateUsageReportSubscription_603207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a usage report subscription. Usage reports are generated daily.
  ## 
  let valid = call_603219.validator(path, query, header, formData, body)
  let scheme = call_603219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603219.url(scheme.get, call_603219.host, call_603219.base,
                         call_603219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603219, url, valid)

proc call*(call_603220: Call_CreateUsageReportSubscription_603207; body: JsonNode): Recallable =
  ## createUsageReportSubscription
  ## Creates a usage report subscription. Usage reports are generated daily.
  ##   body: JObject (required)
  var body_603221 = newJObject()
  if body != nil:
    body_603221 = body
  result = call_603220.call(nil, nil, nil, nil, body_603221)

var createUsageReportSubscription* = Call_CreateUsageReportSubscription_603207(
    name: "createUsageReportSubscription", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.CreateUsageReportSubscription",
    validator: validate_CreateUsageReportSubscription_603208, base: "/",
    url: url_CreateUsageReportSubscription_603209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_603222 = ref object of OpenApiRestCall_602466
proc url_CreateUser_603224(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateUser_603223(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603225 = header.getOrDefault("X-Amz-Date")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Date", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Security-Token")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Security-Token", valid_603226
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603227 = header.getOrDefault("X-Amz-Target")
  valid_603227 = validateParameter(valid_603227, JString, required = true, default = newJString(
      "PhotonAdminProxyService.CreateUser"))
  if valid_603227 != nil:
    section.add "X-Amz-Target", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Content-Sha256", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Algorithm")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Algorithm", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Signature")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Signature", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-SignedHeaders", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Credential")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Credential", valid_603232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603234: Call_CreateUser_603222; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new user in the user pool.
  ## 
  let valid = call_603234.validator(path, query, header, formData, body)
  let scheme = call_603234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603234.url(scheme.get, call_603234.host, call_603234.base,
                         call_603234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603234, url, valid)

proc call*(call_603235: Call_CreateUser_603222; body: JsonNode): Recallable =
  ## createUser
  ## Creates a new user in the user pool.
  ##   body: JObject (required)
  var body_603236 = newJObject()
  if body != nil:
    body_603236 = body
  result = call_603235.call(nil, nil, nil, nil, body_603236)

var createUser* = Call_CreateUser_603222(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.CreateUser",
                                      validator: validate_CreateUser_603223,
                                      base: "/", url: url_CreateUser_603224,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectoryConfig_603237 = ref object of OpenApiRestCall_602466
proc url_DeleteDirectoryConfig_603239(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDirectoryConfig_603238(path: JsonNode; query: JsonNode;
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
  var valid_603240 = header.getOrDefault("X-Amz-Date")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Date", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Security-Token")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Security-Token", valid_603241
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603242 = header.getOrDefault("X-Amz-Target")
  valid_603242 = validateParameter(valid_603242, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteDirectoryConfig"))
  if valid_603242 != nil:
    section.add "X-Amz-Target", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Content-Sha256", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Algorithm")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Algorithm", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Signature")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Signature", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-SignedHeaders", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Credential")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Credential", valid_603247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603249: Call_DeleteDirectoryConfig_603237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Directory Config object from AppStream 2.0. This object includes the information required to join streaming instances to an Active Directory domain.
  ## 
  let valid = call_603249.validator(path, query, header, formData, body)
  let scheme = call_603249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603249.url(scheme.get, call_603249.host, call_603249.base,
                         call_603249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603249, url, valid)

proc call*(call_603250: Call_DeleteDirectoryConfig_603237; body: JsonNode): Recallable =
  ## deleteDirectoryConfig
  ## Deletes the specified Directory Config object from AppStream 2.0. This object includes the information required to join streaming instances to an Active Directory domain.
  ##   body: JObject (required)
  var body_603251 = newJObject()
  if body != nil:
    body_603251 = body
  result = call_603250.call(nil, nil, nil, nil, body_603251)

var deleteDirectoryConfig* = Call_DeleteDirectoryConfig_603237(
    name: "deleteDirectoryConfig", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteDirectoryConfig",
    validator: validate_DeleteDirectoryConfig_603238, base: "/",
    url: url_DeleteDirectoryConfig_603239, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFleet_603252 = ref object of OpenApiRestCall_602466
proc url_DeleteFleet_603254(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteFleet_603253(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603255 = header.getOrDefault("X-Amz-Date")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Date", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Security-Token")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Security-Token", valid_603256
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603257 = header.getOrDefault("X-Amz-Target")
  valid_603257 = validateParameter(valid_603257, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteFleet"))
  if valid_603257 != nil:
    section.add "X-Amz-Target", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Content-Sha256", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Algorithm")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Algorithm", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Signature")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Signature", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-SignedHeaders", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Credential")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Credential", valid_603262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603264: Call_DeleteFleet_603252; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified fleet.
  ## 
  let valid = call_603264.validator(path, query, header, formData, body)
  let scheme = call_603264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603264.url(scheme.get, call_603264.host, call_603264.base,
                         call_603264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603264, url, valid)

proc call*(call_603265: Call_DeleteFleet_603252; body: JsonNode): Recallable =
  ## deleteFleet
  ## Deletes the specified fleet.
  ##   body: JObject (required)
  var body_603266 = newJObject()
  if body != nil:
    body_603266 = body
  result = call_603265.call(nil, nil, nil, nil, body_603266)

var deleteFleet* = Call_DeleteFleet_603252(name: "deleteFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteFleet",
                                        validator: validate_DeleteFleet_603253,
                                        base: "/", url: url_DeleteFleet_603254,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImage_603267 = ref object of OpenApiRestCall_602466
proc url_DeleteImage_603269(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteImage_603268(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603270 = header.getOrDefault("X-Amz-Date")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Date", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Security-Token")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Security-Token", valid_603271
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603272 = header.getOrDefault("X-Amz-Target")
  valid_603272 = validateParameter(valid_603272, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteImage"))
  if valid_603272 != nil:
    section.add "X-Amz-Target", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Content-Sha256", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Algorithm")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Algorithm", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Signature")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Signature", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-SignedHeaders", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Credential")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Credential", valid_603277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603279: Call_DeleteImage_603267; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified image. You cannot delete an image when it is in use. After you delete an image, you cannot provision new capacity using the image.
  ## 
  let valid = call_603279.validator(path, query, header, formData, body)
  let scheme = call_603279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603279.url(scheme.get, call_603279.host, call_603279.base,
                         call_603279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603279, url, valid)

proc call*(call_603280: Call_DeleteImage_603267; body: JsonNode): Recallable =
  ## deleteImage
  ## Deletes the specified image. You cannot delete an image when it is in use. After you delete an image, you cannot provision new capacity using the image.
  ##   body: JObject (required)
  var body_603281 = newJObject()
  if body != nil:
    body_603281 = body
  result = call_603280.call(nil, nil, nil, nil, body_603281)

var deleteImage* = Call_DeleteImage_603267(name: "deleteImage",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteImage",
                                        validator: validate_DeleteImage_603268,
                                        base: "/", url: url_DeleteImage_603269,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImageBuilder_603282 = ref object of OpenApiRestCall_602466
proc url_DeleteImageBuilder_603284(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteImageBuilder_603283(path: JsonNode; query: JsonNode;
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
  var valid_603285 = header.getOrDefault("X-Amz-Date")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Date", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Security-Token")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Security-Token", valid_603286
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603287 = header.getOrDefault("X-Amz-Target")
  valid_603287 = validateParameter(valid_603287, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteImageBuilder"))
  if valid_603287 != nil:
    section.add "X-Amz-Target", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Content-Sha256", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Algorithm")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Algorithm", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Signature")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Signature", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-SignedHeaders", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Credential")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Credential", valid_603292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603294: Call_DeleteImageBuilder_603282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified image builder and releases the capacity.
  ## 
  let valid = call_603294.validator(path, query, header, formData, body)
  let scheme = call_603294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603294.url(scheme.get, call_603294.host, call_603294.base,
                         call_603294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603294, url, valid)

proc call*(call_603295: Call_DeleteImageBuilder_603282; body: JsonNode): Recallable =
  ## deleteImageBuilder
  ## Deletes the specified image builder and releases the capacity.
  ##   body: JObject (required)
  var body_603296 = newJObject()
  if body != nil:
    body_603296 = body
  result = call_603295.call(nil, nil, nil, nil, body_603296)

var deleteImageBuilder* = Call_DeleteImageBuilder_603282(
    name: "deleteImageBuilder", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteImageBuilder",
    validator: validate_DeleteImageBuilder_603283, base: "/",
    url: url_DeleteImageBuilder_603284, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImagePermissions_603297 = ref object of OpenApiRestCall_602466
proc url_DeleteImagePermissions_603299(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteImagePermissions_603298(path: JsonNode; query: JsonNode;
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
  var valid_603300 = header.getOrDefault("X-Amz-Date")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Date", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Security-Token")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Security-Token", valid_603301
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603302 = header.getOrDefault("X-Amz-Target")
  valid_603302 = validateParameter(valid_603302, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteImagePermissions"))
  if valid_603302 != nil:
    section.add "X-Amz-Target", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Content-Sha256", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Algorithm")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Algorithm", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Signature")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Signature", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-SignedHeaders", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Credential")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Credential", valid_603307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603309: Call_DeleteImagePermissions_603297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes permissions for the specified private image. After you delete permissions for an image, AWS accounts to which you previously granted these permissions can no longer use the image.
  ## 
  let valid = call_603309.validator(path, query, header, formData, body)
  let scheme = call_603309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603309.url(scheme.get, call_603309.host, call_603309.base,
                         call_603309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603309, url, valid)

proc call*(call_603310: Call_DeleteImagePermissions_603297; body: JsonNode): Recallable =
  ## deleteImagePermissions
  ## Deletes permissions for the specified private image. After you delete permissions for an image, AWS accounts to which you previously granted these permissions can no longer use the image.
  ##   body: JObject (required)
  var body_603311 = newJObject()
  if body != nil:
    body_603311 = body
  result = call_603310.call(nil, nil, nil, nil, body_603311)

var deleteImagePermissions* = Call_DeleteImagePermissions_603297(
    name: "deleteImagePermissions", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteImagePermissions",
    validator: validate_DeleteImagePermissions_603298, base: "/",
    url: url_DeleteImagePermissions_603299, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStack_603312 = ref object of OpenApiRestCall_602466
proc url_DeleteStack_603314(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteStack_603313(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603315 = header.getOrDefault("X-Amz-Date")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Date", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Security-Token")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Security-Token", valid_603316
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603317 = header.getOrDefault("X-Amz-Target")
  valid_603317 = validateParameter(valid_603317, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteStack"))
  if valid_603317 != nil:
    section.add "X-Amz-Target", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Content-Sha256", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Algorithm")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Algorithm", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Signature")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Signature", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-SignedHeaders", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Credential")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Credential", valid_603322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603324: Call_DeleteStack_603312; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified stack. After the stack is deleted, the application streaming environment provided by the stack is no longer available to users. Also, any reservations made for application streaming sessions for the stack are released.
  ## 
  let valid = call_603324.validator(path, query, header, formData, body)
  let scheme = call_603324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603324.url(scheme.get, call_603324.host, call_603324.base,
                         call_603324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603324, url, valid)

proc call*(call_603325: Call_DeleteStack_603312; body: JsonNode): Recallable =
  ## deleteStack
  ## Deletes the specified stack. After the stack is deleted, the application streaming environment provided by the stack is no longer available to users. Also, any reservations made for application streaming sessions for the stack are released.
  ##   body: JObject (required)
  var body_603326 = newJObject()
  if body != nil:
    body_603326 = body
  result = call_603325.call(nil, nil, nil, nil, body_603326)

var deleteStack* = Call_DeleteStack_603312(name: "deleteStack",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteStack",
                                        validator: validate_DeleteStack_603313,
                                        base: "/", url: url_DeleteStack_603314,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsageReportSubscription_603327 = ref object of OpenApiRestCall_602466
proc url_DeleteUsageReportSubscription_603329(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteUsageReportSubscription_603328(path: JsonNode; query: JsonNode;
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
  var valid_603330 = header.getOrDefault("X-Amz-Date")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Date", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Security-Token")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Security-Token", valid_603331
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603332 = header.getOrDefault("X-Amz-Target")
  valid_603332 = validateParameter(valid_603332, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteUsageReportSubscription"))
  if valid_603332 != nil:
    section.add "X-Amz-Target", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Content-Sha256", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Algorithm")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Algorithm", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Signature")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Signature", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-SignedHeaders", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Credential")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Credential", valid_603337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603339: Call_DeleteUsageReportSubscription_603327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables usage report generation.
  ## 
  let valid = call_603339.validator(path, query, header, formData, body)
  let scheme = call_603339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603339.url(scheme.get, call_603339.host, call_603339.base,
                         call_603339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603339, url, valid)

proc call*(call_603340: Call_DeleteUsageReportSubscription_603327; body: JsonNode): Recallable =
  ## deleteUsageReportSubscription
  ## Disables usage report generation.
  ##   body: JObject (required)
  var body_603341 = newJObject()
  if body != nil:
    body_603341 = body
  result = call_603340.call(nil, nil, nil, nil, body_603341)

var deleteUsageReportSubscription* = Call_DeleteUsageReportSubscription_603327(
    name: "deleteUsageReportSubscription", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteUsageReportSubscription",
    validator: validate_DeleteUsageReportSubscription_603328, base: "/",
    url: url_DeleteUsageReportSubscription_603329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_603342 = ref object of OpenApiRestCall_602466
proc url_DeleteUser_603344(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteUser_603343(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603345 = header.getOrDefault("X-Amz-Date")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Date", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Security-Token")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Security-Token", valid_603346
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603347 = header.getOrDefault("X-Amz-Target")
  valid_603347 = validateParameter(valid_603347, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DeleteUser"))
  if valid_603347 != nil:
    section.add "X-Amz-Target", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Content-Sha256", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Algorithm")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Algorithm", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Signature")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Signature", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-SignedHeaders", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Credential")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Credential", valid_603352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603354: Call_DeleteUser_603342; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a user from the user pool.
  ## 
  let valid = call_603354.validator(path, query, header, formData, body)
  let scheme = call_603354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603354.url(scheme.get, call_603354.host, call_603354.base,
                         call_603354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603354, url, valid)

proc call*(call_603355: Call_DeleteUser_603342; body: JsonNode): Recallable =
  ## deleteUser
  ## Deletes a user from the user pool.
  ##   body: JObject (required)
  var body_603356 = newJObject()
  if body != nil:
    body_603356 = body
  result = call_603355.call(nil, nil, nil, nil, body_603356)

var deleteUser* = Call_DeleteUser_603342(name: "deleteUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DeleteUser",
                                      validator: validate_DeleteUser_603343,
                                      base: "/", url: url_DeleteUser_603344,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDirectoryConfigs_603357 = ref object of OpenApiRestCall_602466
proc url_DescribeDirectoryConfigs_603359(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDirectoryConfigs_603358(path: JsonNode; query: JsonNode;
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
  var valid_603360 = header.getOrDefault("X-Amz-Date")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Date", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Security-Token")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Security-Token", valid_603361
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603362 = header.getOrDefault("X-Amz-Target")
  valid_603362 = validateParameter(valid_603362, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeDirectoryConfigs"))
  if valid_603362 != nil:
    section.add "X-Amz-Target", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Content-Sha256", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-Algorithm")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Algorithm", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Signature")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Signature", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-SignedHeaders", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Credential")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Credential", valid_603367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603369: Call_DescribeDirectoryConfigs_603357; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list that describes one or more specified Directory Config objects for AppStream 2.0, if the names for these objects are provided. Otherwise, all Directory Config objects in the account are described. These objects include the configuration information required to join fleets and image builders to Microsoft Active Directory domains. </p> <p>Although the response syntax in this topic includes the account password, this password is not returned in the actual response.</p>
  ## 
  let valid = call_603369.validator(path, query, header, formData, body)
  let scheme = call_603369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603369.url(scheme.get, call_603369.host, call_603369.base,
                         call_603369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603369, url, valid)

proc call*(call_603370: Call_DescribeDirectoryConfigs_603357; body: JsonNode): Recallable =
  ## describeDirectoryConfigs
  ## <p>Retrieves a list that describes one or more specified Directory Config objects for AppStream 2.0, if the names for these objects are provided. Otherwise, all Directory Config objects in the account are described. These objects include the configuration information required to join fleets and image builders to Microsoft Active Directory domains. </p> <p>Although the response syntax in this topic includes the account password, this password is not returned in the actual response.</p>
  ##   body: JObject (required)
  var body_603371 = newJObject()
  if body != nil:
    body_603371 = body
  result = call_603370.call(nil, nil, nil, nil, body_603371)

var describeDirectoryConfigs* = Call_DescribeDirectoryConfigs_603357(
    name: "describeDirectoryConfigs", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeDirectoryConfigs",
    validator: validate_DescribeDirectoryConfigs_603358, base: "/",
    url: url_DescribeDirectoryConfigs_603359, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFleets_603372 = ref object of OpenApiRestCall_602466
proc url_DescribeFleets_603374(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeFleets_603373(path: JsonNode; query: JsonNode;
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
  var valid_603375 = header.getOrDefault("X-Amz-Date")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Date", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Security-Token")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Security-Token", valid_603376
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603377 = header.getOrDefault("X-Amz-Target")
  valid_603377 = validateParameter(valid_603377, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeFleets"))
  if valid_603377 != nil:
    section.add "X-Amz-Target", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Content-Sha256", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Algorithm")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Algorithm", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Signature")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Signature", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-SignedHeaders", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-Credential")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Credential", valid_603382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603384: Call_DescribeFleets_603372; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified fleets, if the fleet names are provided. Otherwise, all fleets in the account are described.
  ## 
  let valid = call_603384.validator(path, query, header, formData, body)
  let scheme = call_603384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603384.url(scheme.get, call_603384.host, call_603384.base,
                         call_603384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603384, url, valid)

proc call*(call_603385: Call_DescribeFleets_603372; body: JsonNode): Recallable =
  ## describeFleets
  ## Retrieves a list that describes one or more specified fleets, if the fleet names are provided. Otherwise, all fleets in the account are described.
  ##   body: JObject (required)
  var body_603386 = newJObject()
  if body != nil:
    body_603386 = body
  result = call_603385.call(nil, nil, nil, nil, body_603386)

var describeFleets* = Call_DescribeFleets_603372(name: "describeFleets",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeFleets",
    validator: validate_DescribeFleets_603373, base: "/", url: url_DescribeFleets_603374,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeImageBuilders_603387 = ref object of OpenApiRestCall_602466
proc url_DescribeImageBuilders_603389(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeImageBuilders_603388(path: JsonNode; query: JsonNode;
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
  var valid_603390 = header.getOrDefault("X-Amz-Date")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Date", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Security-Token")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Security-Token", valid_603391
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603392 = header.getOrDefault("X-Amz-Target")
  valid_603392 = validateParameter(valid_603392, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeImageBuilders"))
  if valid_603392 != nil:
    section.add "X-Amz-Target", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Content-Sha256", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Algorithm")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Algorithm", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Signature")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Signature", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-SignedHeaders", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-Credential")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Credential", valid_603397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603399: Call_DescribeImageBuilders_603387; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified image builders, if the image builder names are provided. Otherwise, all image builders in the account are described.
  ## 
  let valid = call_603399.validator(path, query, header, formData, body)
  let scheme = call_603399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603399.url(scheme.get, call_603399.host, call_603399.base,
                         call_603399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603399, url, valid)

proc call*(call_603400: Call_DescribeImageBuilders_603387; body: JsonNode): Recallable =
  ## describeImageBuilders
  ## Retrieves a list that describes one or more specified image builders, if the image builder names are provided. Otherwise, all image builders in the account are described.
  ##   body: JObject (required)
  var body_603401 = newJObject()
  if body != nil:
    body_603401 = body
  result = call_603400.call(nil, nil, nil, nil, body_603401)

var describeImageBuilders* = Call_DescribeImageBuilders_603387(
    name: "describeImageBuilders", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeImageBuilders",
    validator: validate_DescribeImageBuilders_603388, base: "/",
    url: url_DescribeImageBuilders_603389, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeImagePermissions_603402 = ref object of OpenApiRestCall_602466
proc url_DescribeImagePermissions_603404(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeImagePermissions_603403(path: JsonNode; query: JsonNode;
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
  var valid_603405 = query.getOrDefault("NextToken")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "NextToken", valid_603405
  var valid_603406 = query.getOrDefault("MaxResults")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "MaxResults", valid_603406
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
  var valid_603407 = header.getOrDefault("X-Amz-Date")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-Date", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-Security-Token")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Security-Token", valid_603408
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603409 = header.getOrDefault("X-Amz-Target")
  valid_603409 = validateParameter(valid_603409, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeImagePermissions"))
  if valid_603409 != nil:
    section.add "X-Amz-Target", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Content-Sha256", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-Algorithm")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-Algorithm", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-Signature")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Signature", valid_603412
  var valid_603413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "X-Amz-SignedHeaders", valid_603413
  var valid_603414 = header.getOrDefault("X-Amz-Credential")
  valid_603414 = validateParameter(valid_603414, JString, required = false,
                                 default = nil)
  if valid_603414 != nil:
    section.add "X-Amz-Credential", valid_603414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603416: Call_DescribeImagePermissions_603402; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes the permissions for shared AWS account IDs on a private image that you own. 
  ## 
  let valid = call_603416.validator(path, query, header, formData, body)
  let scheme = call_603416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603416.url(scheme.get, call_603416.host, call_603416.base,
                         call_603416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603416, url, valid)

proc call*(call_603417: Call_DescribeImagePermissions_603402; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeImagePermissions
  ## Retrieves a list that describes the permissions for shared AWS account IDs on a private image that you own. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603418 = newJObject()
  var body_603419 = newJObject()
  add(query_603418, "NextToken", newJString(NextToken))
  if body != nil:
    body_603419 = body
  add(query_603418, "MaxResults", newJString(MaxResults))
  result = call_603417.call(nil, query_603418, nil, nil, body_603419)

var describeImagePermissions* = Call_DescribeImagePermissions_603402(
    name: "describeImagePermissions", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeImagePermissions",
    validator: validate_DescribeImagePermissions_603403, base: "/",
    url: url_DescribeImagePermissions_603404, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeImages_603421 = ref object of OpenApiRestCall_602466
proc url_DescribeImages_603423(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeImages_603422(path: JsonNode; query: JsonNode;
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
  var valid_603424 = query.getOrDefault("NextToken")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "NextToken", valid_603424
  var valid_603425 = query.getOrDefault("MaxResults")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "MaxResults", valid_603425
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
  var valid_603426 = header.getOrDefault("X-Amz-Date")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-Date", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-Security-Token")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Security-Token", valid_603427
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603428 = header.getOrDefault("X-Amz-Target")
  valid_603428 = validateParameter(valid_603428, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeImages"))
  if valid_603428 != nil:
    section.add "X-Amz-Target", valid_603428
  var valid_603429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603429 = validateParameter(valid_603429, JString, required = false,
                                 default = nil)
  if valid_603429 != nil:
    section.add "X-Amz-Content-Sha256", valid_603429
  var valid_603430 = header.getOrDefault("X-Amz-Algorithm")
  valid_603430 = validateParameter(valid_603430, JString, required = false,
                                 default = nil)
  if valid_603430 != nil:
    section.add "X-Amz-Algorithm", valid_603430
  var valid_603431 = header.getOrDefault("X-Amz-Signature")
  valid_603431 = validateParameter(valid_603431, JString, required = false,
                                 default = nil)
  if valid_603431 != nil:
    section.add "X-Amz-Signature", valid_603431
  var valid_603432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603432 = validateParameter(valid_603432, JString, required = false,
                                 default = nil)
  if valid_603432 != nil:
    section.add "X-Amz-SignedHeaders", valid_603432
  var valid_603433 = header.getOrDefault("X-Amz-Credential")
  valid_603433 = validateParameter(valid_603433, JString, required = false,
                                 default = nil)
  if valid_603433 != nil:
    section.add "X-Amz-Credential", valid_603433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603435: Call_DescribeImages_603421; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified images, if the image names or image ARNs are provided. Otherwise, all images in the account are described.
  ## 
  let valid = call_603435.validator(path, query, header, formData, body)
  let scheme = call_603435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603435.url(scheme.get, call_603435.host, call_603435.base,
                         call_603435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603435, url, valid)

proc call*(call_603436: Call_DescribeImages_603421; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeImages
  ## Retrieves a list that describes one or more specified images, if the image names or image ARNs are provided. Otherwise, all images in the account are described.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603437 = newJObject()
  var body_603438 = newJObject()
  add(query_603437, "NextToken", newJString(NextToken))
  if body != nil:
    body_603438 = body
  add(query_603437, "MaxResults", newJString(MaxResults))
  result = call_603436.call(nil, query_603437, nil, nil, body_603438)

var describeImages* = Call_DescribeImages_603421(name: "describeImages",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeImages",
    validator: validate_DescribeImages_603422, base: "/", url: url_DescribeImages_603423,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSessions_603439 = ref object of OpenApiRestCall_602466
proc url_DescribeSessions_603441(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSessions_603440(path: JsonNode; query: JsonNode;
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
  var valid_603442 = header.getOrDefault("X-Amz-Date")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Date", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-Security-Token")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-Security-Token", valid_603443
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603444 = header.getOrDefault("X-Amz-Target")
  valid_603444 = validateParameter(valid_603444, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeSessions"))
  if valid_603444 != nil:
    section.add "X-Amz-Target", valid_603444
  var valid_603445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603445 = validateParameter(valid_603445, JString, required = false,
                                 default = nil)
  if valid_603445 != nil:
    section.add "X-Amz-Content-Sha256", valid_603445
  var valid_603446 = header.getOrDefault("X-Amz-Algorithm")
  valid_603446 = validateParameter(valid_603446, JString, required = false,
                                 default = nil)
  if valid_603446 != nil:
    section.add "X-Amz-Algorithm", valid_603446
  var valid_603447 = header.getOrDefault("X-Amz-Signature")
  valid_603447 = validateParameter(valid_603447, JString, required = false,
                                 default = nil)
  if valid_603447 != nil:
    section.add "X-Amz-Signature", valid_603447
  var valid_603448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603448 = validateParameter(valid_603448, JString, required = false,
                                 default = nil)
  if valid_603448 != nil:
    section.add "X-Amz-SignedHeaders", valid_603448
  var valid_603449 = header.getOrDefault("X-Amz-Credential")
  valid_603449 = validateParameter(valid_603449, JString, required = false,
                                 default = nil)
  if valid_603449 != nil:
    section.add "X-Amz-Credential", valid_603449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603451: Call_DescribeSessions_603439; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes the streaming sessions for a specified stack and fleet. If a UserId is provided for the stack and fleet, only streaming sessions for that user are described. If an authentication type is not provided, the default is to authenticate users using a streaming URL.
  ## 
  let valid = call_603451.validator(path, query, header, formData, body)
  let scheme = call_603451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603451.url(scheme.get, call_603451.host, call_603451.base,
                         call_603451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603451, url, valid)

proc call*(call_603452: Call_DescribeSessions_603439; body: JsonNode): Recallable =
  ## describeSessions
  ## Retrieves a list that describes the streaming sessions for a specified stack and fleet. If a UserId is provided for the stack and fleet, only streaming sessions for that user are described. If an authentication type is not provided, the default is to authenticate users using a streaming URL.
  ##   body: JObject (required)
  var body_603453 = newJObject()
  if body != nil:
    body_603453 = body
  result = call_603452.call(nil, nil, nil, nil, body_603453)

var describeSessions* = Call_DescribeSessions_603439(name: "describeSessions",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeSessions",
    validator: validate_DescribeSessions_603440, base: "/",
    url: url_DescribeSessions_603441, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStacks_603454 = ref object of OpenApiRestCall_602466
proc url_DescribeStacks_603456(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeStacks_603455(path: JsonNode; query: JsonNode;
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
  var valid_603457 = header.getOrDefault("X-Amz-Date")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Date", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-Security-Token")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Security-Token", valid_603458
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603459 = header.getOrDefault("X-Amz-Target")
  valid_603459 = validateParameter(valid_603459, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeStacks"))
  if valid_603459 != nil:
    section.add "X-Amz-Target", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-Content-Sha256", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-Algorithm")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-Algorithm", valid_603461
  var valid_603462 = header.getOrDefault("X-Amz-Signature")
  valid_603462 = validateParameter(valid_603462, JString, required = false,
                                 default = nil)
  if valid_603462 != nil:
    section.add "X-Amz-Signature", valid_603462
  var valid_603463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603463 = validateParameter(valid_603463, JString, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "X-Amz-SignedHeaders", valid_603463
  var valid_603464 = header.getOrDefault("X-Amz-Credential")
  valid_603464 = validateParameter(valid_603464, JString, required = false,
                                 default = nil)
  if valid_603464 != nil:
    section.add "X-Amz-Credential", valid_603464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603466: Call_DescribeStacks_603454; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified stacks, if the stack names are provided. Otherwise, all stacks in the account are described.
  ## 
  let valid = call_603466.validator(path, query, header, formData, body)
  let scheme = call_603466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603466.url(scheme.get, call_603466.host, call_603466.base,
                         call_603466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603466, url, valid)

proc call*(call_603467: Call_DescribeStacks_603454; body: JsonNode): Recallable =
  ## describeStacks
  ## Retrieves a list that describes one or more specified stacks, if the stack names are provided. Otherwise, all stacks in the account are described.
  ##   body: JObject (required)
  var body_603468 = newJObject()
  if body != nil:
    body_603468 = body
  result = call_603467.call(nil, nil, nil, nil, body_603468)

var describeStacks* = Call_DescribeStacks_603454(name: "describeStacks",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeStacks",
    validator: validate_DescribeStacks_603455, base: "/", url: url_DescribeStacks_603456,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUsageReportSubscriptions_603469 = ref object of OpenApiRestCall_602466
proc url_DescribeUsageReportSubscriptions_603471(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeUsageReportSubscriptions_603470(path: JsonNode;
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
  var valid_603472 = header.getOrDefault("X-Amz-Date")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Date", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Security-Token")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Security-Token", valid_603473
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603474 = header.getOrDefault("X-Amz-Target")
  valid_603474 = validateParameter(valid_603474, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeUsageReportSubscriptions"))
  if valid_603474 != nil:
    section.add "X-Amz-Target", valid_603474
  var valid_603475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-Content-Sha256", valid_603475
  var valid_603476 = header.getOrDefault("X-Amz-Algorithm")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-Algorithm", valid_603476
  var valid_603477 = header.getOrDefault("X-Amz-Signature")
  valid_603477 = validateParameter(valid_603477, JString, required = false,
                                 default = nil)
  if valid_603477 != nil:
    section.add "X-Amz-Signature", valid_603477
  var valid_603478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603478 = validateParameter(valid_603478, JString, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "X-Amz-SignedHeaders", valid_603478
  var valid_603479 = header.getOrDefault("X-Amz-Credential")
  valid_603479 = validateParameter(valid_603479, JString, required = false,
                                 default = nil)
  if valid_603479 != nil:
    section.add "X-Amz-Credential", valid_603479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603481: Call_DescribeUsageReportSubscriptions_603469;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more usage report subscriptions.
  ## 
  let valid = call_603481.validator(path, query, header, formData, body)
  let scheme = call_603481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603481.url(scheme.get, call_603481.host, call_603481.base,
                         call_603481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603481, url, valid)

proc call*(call_603482: Call_DescribeUsageReportSubscriptions_603469;
          body: JsonNode): Recallable =
  ## describeUsageReportSubscriptions
  ## Retrieves a list that describes one or more usage report subscriptions.
  ##   body: JObject (required)
  var body_603483 = newJObject()
  if body != nil:
    body_603483 = body
  result = call_603482.call(nil, nil, nil, nil, body_603483)

var describeUsageReportSubscriptions* = Call_DescribeUsageReportSubscriptions_603469(
    name: "describeUsageReportSubscriptions", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeUsageReportSubscriptions",
    validator: validate_DescribeUsageReportSubscriptions_603470, base: "/",
    url: url_DescribeUsageReportSubscriptions_603471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserStackAssociations_603484 = ref object of OpenApiRestCall_602466
proc url_DescribeUserStackAssociations_603486(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeUserStackAssociations_603485(path: JsonNode; query: JsonNode;
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
  var valid_603487 = header.getOrDefault("X-Amz-Date")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Date", valid_603487
  var valid_603488 = header.getOrDefault("X-Amz-Security-Token")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "X-Amz-Security-Token", valid_603488
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603489 = header.getOrDefault("X-Amz-Target")
  valid_603489 = validateParameter(valid_603489, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeUserStackAssociations"))
  if valid_603489 != nil:
    section.add "X-Amz-Target", valid_603489
  var valid_603490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "X-Amz-Content-Sha256", valid_603490
  var valid_603491 = header.getOrDefault("X-Amz-Algorithm")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "X-Amz-Algorithm", valid_603491
  var valid_603492 = header.getOrDefault("X-Amz-Signature")
  valid_603492 = validateParameter(valid_603492, JString, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "X-Amz-Signature", valid_603492
  var valid_603493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603493 = validateParameter(valid_603493, JString, required = false,
                                 default = nil)
  if valid_603493 != nil:
    section.add "X-Amz-SignedHeaders", valid_603493
  var valid_603494 = header.getOrDefault("X-Amz-Credential")
  valid_603494 = validateParameter(valid_603494, JString, required = false,
                                 default = nil)
  if valid_603494 != nil:
    section.add "X-Amz-Credential", valid_603494
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603496: Call_DescribeUserStackAssociations_603484; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list that describes the UserStackAssociation objects. You must specify either or both of the following:</p> <ul> <li> <p>The stack name</p> </li> <li> <p>The user name (email address of the user associated with the stack) and the authentication type for the user</p> </li> </ul>
  ## 
  let valid = call_603496.validator(path, query, header, formData, body)
  let scheme = call_603496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603496.url(scheme.get, call_603496.host, call_603496.base,
                         call_603496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603496, url, valid)

proc call*(call_603497: Call_DescribeUserStackAssociations_603484; body: JsonNode): Recallable =
  ## describeUserStackAssociations
  ## <p>Retrieves a list that describes the UserStackAssociation objects. You must specify either or both of the following:</p> <ul> <li> <p>The stack name</p> </li> <li> <p>The user name (email address of the user associated with the stack) and the authentication type for the user</p> </li> </ul>
  ##   body: JObject (required)
  var body_603498 = newJObject()
  if body != nil:
    body_603498 = body
  result = call_603497.call(nil, nil, nil, nil, body_603498)

var describeUserStackAssociations* = Call_DescribeUserStackAssociations_603484(
    name: "describeUserStackAssociations", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeUserStackAssociations",
    validator: validate_DescribeUserStackAssociations_603485, base: "/",
    url: url_DescribeUserStackAssociations_603486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUsers_603499 = ref object of OpenApiRestCall_602466
proc url_DescribeUsers_603501(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeUsers_603500(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603502 = header.getOrDefault("X-Amz-Date")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Date", valid_603502
  var valid_603503 = header.getOrDefault("X-Amz-Security-Token")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-Security-Token", valid_603503
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603504 = header.getOrDefault("X-Amz-Target")
  valid_603504 = validateParameter(valid_603504, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DescribeUsers"))
  if valid_603504 != nil:
    section.add "X-Amz-Target", valid_603504
  var valid_603505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-Content-Sha256", valid_603505
  var valid_603506 = header.getOrDefault("X-Amz-Algorithm")
  valid_603506 = validateParameter(valid_603506, JString, required = false,
                                 default = nil)
  if valid_603506 != nil:
    section.add "X-Amz-Algorithm", valid_603506
  var valid_603507 = header.getOrDefault("X-Amz-Signature")
  valid_603507 = validateParameter(valid_603507, JString, required = false,
                                 default = nil)
  if valid_603507 != nil:
    section.add "X-Amz-Signature", valid_603507
  var valid_603508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603508 = validateParameter(valid_603508, JString, required = false,
                                 default = nil)
  if valid_603508 != nil:
    section.add "X-Amz-SignedHeaders", valid_603508
  var valid_603509 = header.getOrDefault("X-Amz-Credential")
  valid_603509 = validateParameter(valid_603509, JString, required = false,
                                 default = nil)
  if valid_603509 != nil:
    section.add "X-Amz-Credential", valid_603509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603511: Call_DescribeUsers_603499; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified users in the user pool.
  ## 
  let valid = call_603511.validator(path, query, header, formData, body)
  let scheme = call_603511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603511.url(scheme.get, call_603511.host, call_603511.base,
                         call_603511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603511, url, valid)

proc call*(call_603512: Call_DescribeUsers_603499; body: JsonNode): Recallable =
  ## describeUsers
  ## Retrieves a list that describes one or more specified users in the user pool.
  ##   body: JObject (required)
  var body_603513 = newJObject()
  if body != nil:
    body_603513 = body
  result = call_603512.call(nil, nil, nil, nil, body_603513)

var describeUsers* = Call_DescribeUsers_603499(name: "describeUsers",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DescribeUsers",
    validator: validate_DescribeUsers_603500, base: "/", url: url_DescribeUsers_603501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableUser_603514 = ref object of OpenApiRestCall_602466
proc url_DisableUser_603516(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisableUser_603515(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603517 = header.getOrDefault("X-Amz-Date")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Date", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-Security-Token")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-Security-Token", valid_603518
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603519 = header.getOrDefault("X-Amz-Target")
  valid_603519 = validateParameter(valid_603519, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DisableUser"))
  if valid_603519 != nil:
    section.add "X-Amz-Target", valid_603519
  var valid_603520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603520 = validateParameter(valid_603520, JString, required = false,
                                 default = nil)
  if valid_603520 != nil:
    section.add "X-Amz-Content-Sha256", valid_603520
  var valid_603521 = header.getOrDefault("X-Amz-Algorithm")
  valid_603521 = validateParameter(valid_603521, JString, required = false,
                                 default = nil)
  if valid_603521 != nil:
    section.add "X-Amz-Algorithm", valid_603521
  var valid_603522 = header.getOrDefault("X-Amz-Signature")
  valid_603522 = validateParameter(valid_603522, JString, required = false,
                                 default = nil)
  if valid_603522 != nil:
    section.add "X-Amz-Signature", valid_603522
  var valid_603523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603523 = validateParameter(valid_603523, JString, required = false,
                                 default = nil)
  if valid_603523 != nil:
    section.add "X-Amz-SignedHeaders", valid_603523
  var valid_603524 = header.getOrDefault("X-Amz-Credential")
  valid_603524 = validateParameter(valid_603524, JString, required = false,
                                 default = nil)
  if valid_603524 != nil:
    section.add "X-Amz-Credential", valid_603524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603526: Call_DisableUser_603514; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the specified user in the user pool. Users can't sign in to AppStream 2.0 until they are re-enabled. This action does not delete the user. 
  ## 
  let valid = call_603526.validator(path, query, header, formData, body)
  let scheme = call_603526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603526.url(scheme.get, call_603526.host, call_603526.base,
                         call_603526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603526, url, valid)

proc call*(call_603527: Call_DisableUser_603514; body: JsonNode): Recallable =
  ## disableUser
  ## Disables the specified user in the user pool. Users can't sign in to AppStream 2.0 until they are re-enabled. This action does not delete the user. 
  ##   body: JObject (required)
  var body_603528 = newJObject()
  if body != nil:
    body_603528 = body
  result = call_603527.call(nil, nil, nil, nil, body_603528)

var disableUser* = Call_DisableUser_603514(name: "disableUser",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.DisableUser",
                                        validator: validate_DisableUser_603515,
                                        base: "/", url: url_DisableUser_603516,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateFleet_603529 = ref object of OpenApiRestCall_602466
proc url_DisassociateFleet_603531(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateFleet_603530(path: JsonNode; query: JsonNode;
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
  var valid_603532 = header.getOrDefault("X-Amz-Date")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Date", valid_603532
  var valid_603533 = header.getOrDefault("X-Amz-Security-Token")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-Security-Token", valid_603533
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603534 = header.getOrDefault("X-Amz-Target")
  valid_603534 = validateParameter(valid_603534, JString, required = true, default = newJString(
      "PhotonAdminProxyService.DisassociateFleet"))
  if valid_603534 != nil:
    section.add "X-Amz-Target", valid_603534
  var valid_603535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "X-Amz-Content-Sha256", valid_603535
  var valid_603536 = header.getOrDefault("X-Amz-Algorithm")
  valid_603536 = validateParameter(valid_603536, JString, required = false,
                                 default = nil)
  if valid_603536 != nil:
    section.add "X-Amz-Algorithm", valid_603536
  var valid_603537 = header.getOrDefault("X-Amz-Signature")
  valid_603537 = validateParameter(valid_603537, JString, required = false,
                                 default = nil)
  if valid_603537 != nil:
    section.add "X-Amz-Signature", valid_603537
  var valid_603538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603538 = validateParameter(valid_603538, JString, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "X-Amz-SignedHeaders", valid_603538
  var valid_603539 = header.getOrDefault("X-Amz-Credential")
  valid_603539 = validateParameter(valid_603539, JString, required = false,
                                 default = nil)
  if valid_603539 != nil:
    section.add "X-Amz-Credential", valid_603539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603541: Call_DisassociateFleet_603529; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified fleet from the specified stack.
  ## 
  let valid = call_603541.validator(path, query, header, formData, body)
  let scheme = call_603541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603541.url(scheme.get, call_603541.host, call_603541.base,
                         call_603541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603541, url, valid)

proc call*(call_603542: Call_DisassociateFleet_603529; body: JsonNode): Recallable =
  ## disassociateFleet
  ## Disassociates the specified fleet from the specified stack.
  ##   body: JObject (required)
  var body_603543 = newJObject()
  if body != nil:
    body_603543 = body
  result = call_603542.call(nil, nil, nil, nil, body_603543)

var disassociateFleet* = Call_DisassociateFleet_603529(name: "disassociateFleet",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.DisassociateFleet",
    validator: validate_DisassociateFleet_603530, base: "/",
    url: url_DisassociateFleet_603531, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableUser_603544 = ref object of OpenApiRestCall_602466
proc url_EnableUser_603546(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_EnableUser_603545(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603547 = header.getOrDefault("X-Amz-Date")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Date", valid_603547
  var valid_603548 = header.getOrDefault("X-Amz-Security-Token")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-Security-Token", valid_603548
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603549 = header.getOrDefault("X-Amz-Target")
  valid_603549 = validateParameter(valid_603549, JString, required = true, default = newJString(
      "PhotonAdminProxyService.EnableUser"))
  if valid_603549 != nil:
    section.add "X-Amz-Target", valid_603549
  var valid_603550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-Content-Sha256", valid_603550
  var valid_603551 = header.getOrDefault("X-Amz-Algorithm")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "X-Amz-Algorithm", valid_603551
  var valid_603552 = header.getOrDefault("X-Amz-Signature")
  valid_603552 = validateParameter(valid_603552, JString, required = false,
                                 default = nil)
  if valid_603552 != nil:
    section.add "X-Amz-Signature", valid_603552
  var valid_603553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-SignedHeaders", valid_603553
  var valid_603554 = header.getOrDefault("X-Amz-Credential")
  valid_603554 = validateParameter(valid_603554, JString, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "X-Amz-Credential", valid_603554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603556: Call_EnableUser_603544; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables a user in the user pool. After being enabled, users can sign in to AppStream 2.0 and open applications from the stacks to which they are assigned.
  ## 
  let valid = call_603556.validator(path, query, header, formData, body)
  let scheme = call_603556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603556.url(scheme.get, call_603556.host, call_603556.base,
                         call_603556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603556, url, valid)

proc call*(call_603557: Call_EnableUser_603544; body: JsonNode): Recallable =
  ## enableUser
  ## Enables a user in the user pool. After being enabled, users can sign in to AppStream 2.0 and open applications from the stacks to which they are assigned.
  ##   body: JObject (required)
  var body_603558 = newJObject()
  if body != nil:
    body_603558 = body
  result = call_603557.call(nil, nil, nil, nil, body_603558)

var enableUser* = Call_EnableUser_603544(name: "enableUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.EnableUser",
                                      validator: validate_EnableUser_603545,
                                      base: "/", url: url_EnableUser_603546,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExpireSession_603559 = ref object of OpenApiRestCall_602466
proc url_ExpireSession_603561(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ExpireSession_603560(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603562 = header.getOrDefault("X-Amz-Date")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-Date", valid_603562
  var valid_603563 = header.getOrDefault("X-Amz-Security-Token")
  valid_603563 = validateParameter(valid_603563, JString, required = false,
                                 default = nil)
  if valid_603563 != nil:
    section.add "X-Amz-Security-Token", valid_603563
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603564 = header.getOrDefault("X-Amz-Target")
  valid_603564 = validateParameter(valid_603564, JString, required = true, default = newJString(
      "PhotonAdminProxyService.ExpireSession"))
  if valid_603564 != nil:
    section.add "X-Amz-Target", valid_603564
  var valid_603565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "X-Amz-Content-Sha256", valid_603565
  var valid_603566 = header.getOrDefault("X-Amz-Algorithm")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "X-Amz-Algorithm", valid_603566
  var valid_603567 = header.getOrDefault("X-Amz-Signature")
  valid_603567 = validateParameter(valid_603567, JString, required = false,
                                 default = nil)
  if valid_603567 != nil:
    section.add "X-Amz-Signature", valid_603567
  var valid_603568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603568 = validateParameter(valid_603568, JString, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "X-Amz-SignedHeaders", valid_603568
  var valid_603569 = header.getOrDefault("X-Amz-Credential")
  valid_603569 = validateParameter(valid_603569, JString, required = false,
                                 default = nil)
  if valid_603569 != nil:
    section.add "X-Amz-Credential", valid_603569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603571: Call_ExpireSession_603559; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Immediately stops the specified streaming session.
  ## 
  let valid = call_603571.validator(path, query, header, formData, body)
  let scheme = call_603571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603571.url(scheme.get, call_603571.host, call_603571.base,
                         call_603571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603571, url, valid)

proc call*(call_603572: Call_ExpireSession_603559; body: JsonNode): Recallable =
  ## expireSession
  ## Immediately stops the specified streaming session.
  ##   body: JObject (required)
  var body_603573 = newJObject()
  if body != nil:
    body_603573 = body
  result = call_603572.call(nil, nil, nil, nil, body_603573)

var expireSession* = Call_ExpireSession_603559(name: "expireSession",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.ExpireSession",
    validator: validate_ExpireSession_603560, base: "/", url: url_ExpireSession_603561,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociatedFleets_603574 = ref object of OpenApiRestCall_602466
proc url_ListAssociatedFleets_603576(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAssociatedFleets_603575(path: JsonNode; query: JsonNode;
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
  var valid_603577 = header.getOrDefault("X-Amz-Date")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-Date", valid_603577
  var valid_603578 = header.getOrDefault("X-Amz-Security-Token")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "X-Amz-Security-Token", valid_603578
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603579 = header.getOrDefault("X-Amz-Target")
  valid_603579 = validateParameter(valid_603579, JString, required = true, default = newJString(
      "PhotonAdminProxyService.ListAssociatedFleets"))
  if valid_603579 != nil:
    section.add "X-Amz-Target", valid_603579
  var valid_603580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603580 = validateParameter(valid_603580, JString, required = false,
                                 default = nil)
  if valid_603580 != nil:
    section.add "X-Amz-Content-Sha256", valid_603580
  var valid_603581 = header.getOrDefault("X-Amz-Algorithm")
  valid_603581 = validateParameter(valid_603581, JString, required = false,
                                 default = nil)
  if valid_603581 != nil:
    section.add "X-Amz-Algorithm", valid_603581
  var valid_603582 = header.getOrDefault("X-Amz-Signature")
  valid_603582 = validateParameter(valid_603582, JString, required = false,
                                 default = nil)
  if valid_603582 != nil:
    section.add "X-Amz-Signature", valid_603582
  var valid_603583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603583 = validateParameter(valid_603583, JString, required = false,
                                 default = nil)
  if valid_603583 != nil:
    section.add "X-Amz-SignedHeaders", valid_603583
  var valid_603584 = header.getOrDefault("X-Amz-Credential")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "X-Amz-Credential", valid_603584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603586: Call_ListAssociatedFleets_603574; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the name of the fleet that is associated with the specified stack.
  ## 
  let valid = call_603586.validator(path, query, header, formData, body)
  let scheme = call_603586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603586.url(scheme.get, call_603586.host, call_603586.base,
                         call_603586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603586, url, valid)

proc call*(call_603587: Call_ListAssociatedFleets_603574; body: JsonNode): Recallable =
  ## listAssociatedFleets
  ## Retrieves the name of the fleet that is associated with the specified stack.
  ##   body: JObject (required)
  var body_603588 = newJObject()
  if body != nil:
    body_603588 = body
  result = call_603587.call(nil, nil, nil, nil, body_603588)

var listAssociatedFleets* = Call_ListAssociatedFleets_603574(
    name: "listAssociatedFleets", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.ListAssociatedFleets",
    validator: validate_ListAssociatedFleets_603575, base: "/",
    url: url_ListAssociatedFleets_603576, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociatedStacks_603589 = ref object of OpenApiRestCall_602466
proc url_ListAssociatedStacks_603591(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAssociatedStacks_603590(path: JsonNode; query: JsonNode;
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
  var valid_603592 = header.getOrDefault("X-Amz-Date")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-Date", valid_603592
  var valid_603593 = header.getOrDefault("X-Amz-Security-Token")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "X-Amz-Security-Token", valid_603593
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603594 = header.getOrDefault("X-Amz-Target")
  valid_603594 = validateParameter(valid_603594, JString, required = true, default = newJString(
      "PhotonAdminProxyService.ListAssociatedStacks"))
  if valid_603594 != nil:
    section.add "X-Amz-Target", valid_603594
  var valid_603595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603595 = validateParameter(valid_603595, JString, required = false,
                                 default = nil)
  if valid_603595 != nil:
    section.add "X-Amz-Content-Sha256", valid_603595
  var valid_603596 = header.getOrDefault("X-Amz-Algorithm")
  valid_603596 = validateParameter(valid_603596, JString, required = false,
                                 default = nil)
  if valid_603596 != nil:
    section.add "X-Amz-Algorithm", valid_603596
  var valid_603597 = header.getOrDefault("X-Amz-Signature")
  valid_603597 = validateParameter(valid_603597, JString, required = false,
                                 default = nil)
  if valid_603597 != nil:
    section.add "X-Amz-Signature", valid_603597
  var valid_603598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603598 = validateParameter(valid_603598, JString, required = false,
                                 default = nil)
  if valid_603598 != nil:
    section.add "X-Amz-SignedHeaders", valid_603598
  var valid_603599 = header.getOrDefault("X-Amz-Credential")
  valid_603599 = validateParameter(valid_603599, JString, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "X-Amz-Credential", valid_603599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603601: Call_ListAssociatedStacks_603589; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the name of the stack with which the specified fleet is associated.
  ## 
  let valid = call_603601.validator(path, query, header, formData, body)
  let scheme = call_603601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603601.url(scheme.get, call_603601.host, call_603601.base,
                         call_603601.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603601, url, valid)

proc call*(call_603602: Call_ListAssociatedStacks_603589; body: JsonNode): Recallable =
  ## listAssociatedStacks
  ## Retrieves the name of the stack with which the specified fleet is associated.
  ##   body: JObject (required)
  var body_603603 = newJObject()
  if body != nil:
    body_603603 = body
  result = call_603602.call(nil, nil, nil, nil, body_603603)

var listAssociatedStacks* = Call_ListAssociatedStacks_603589(
    name: "listAssociatedStacks", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.ListAssociatedStacks",
    validator: validate_ListAssociatedStacks_603590, base: "/",
    url: url_ListAssociatedStacks_603591, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603604 = ref object of OpenApiRestCall_602466
proc url_ListTagsForResource_603606(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_603605(path: JsonNode; query: JsonNode;
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
  var valid_603607 = header.getOrDefault("X-Amz-Date")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Date", valid_603607
  var valid_603608 = header.getOrDefault("X-Amz-Security-Token")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "X-Amz-Security-Token", valid_603608
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603609 = header.getOrDefault("X-Amz-Target")
  valid_603609 = validateParameter(valid_603609, JString, required = true, default = newJString(
      "PhotonAdminProxyService.ListTagsForResource"))
  if valid_603609 != nil:
    section.add "X-Amz-Target", valid_603609
  var valid_603610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603610 = validateParameter(valid_603610, JString, required = false,
                                 default = nil)
  if valid_603610 != nil:
    section.add "X-Amz-Content-Sha256", valid_603610
  var valid_603611 = header.getOrDefault("X-Amz-Algorithm")
  valid_603611 = validateParameter(valid_603611, JString, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "X-Amz-Algorithm", valid_603611
  var valid_603612 = header.getOrDefault("X-Amz-Signature")
  valid_603612 = validateParameter(valid_603612, JString, required = false,
                                 default = nil)
  if valid_603612 != nil:
    section.add "X-Amz-Signature", valid_603612
  var valid_603613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603613 = validateParameter(valid_603613, JString, required = false,
                                 default = nil)
  if valid_603613 != nil:
    section.add "X-Amz-SignedHeaders", valid_603613
  var valid_603614 = header.getOrDefault("X-Amz-Credential")
  valid_603614 = validateParameter(valid_603614, JString, required = false,
                                 default = nil)
  if valid_603614 != nil:
    section.add "X-Amz-Credential", valid_603614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603616: Call_ListTagsForResource_603604; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of all tags for the specified AppStream 2.0 resource. You can tag AppStream 2.0 image builders, images, fleets, and stacks.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
  ## 
  let valid = call_603616.validator(path, query, header, formData, body)
  let scheme = call_603616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603616.url(scheme.get, call_603616.host, call_603616.base,
                         call_603616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603616, url, valid)

proc call*(call_603617: Call_ListTagsForResource_603604; body: JsonNode): Recallable =
  ## listTagsForResource
  ## <p>Retrieves a list of all tags for the specified AppStream 2.0 resource. You can tag AppStream 2.0 image builders, images, fleets, and stacks.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
  ##   body: JObject (required)
  var body_603618 = newJObject()
  if body != nil:
    body_603618 = body
  result = call_603617.call(nil, nil, nil, nil, body_603618)

var listTagsForResource* = Call_ListTagsForResource_603604(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.ListTagsForResource",
    validator: validate_ListTagsForResource_603605, base: "/",
    url: url_ListTagsForResource_603606, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartFleet_603619 = ref object of OpenApiRestCall_602466
proc url_StartFleet_603621(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartFleet_603620(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603622 = header.getOrDefault("X-Amz-Date")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-Date", valid_603622
  var valid_603623 = header.getOrDefault("X-Amz-Security-Token")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "X-Amz-Security-Token", valid_603623
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603624 = header.getOrDefault("X-Amz-Target")
  valid_603624 = validateParameter(valid_603624, JString, required = true, default = newJString(
      "PhotonAdminProxyService.StartFleet"))
  if valid_603624 != nil:
    section.add "X-Amz-Target", valid_603624
  var valid_603625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603625 = validateParameter(valid_603625, JString, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "X-Amz-Content-Sha256", valid_603625
  var valid_603626 = header.getOrDefault("X-Amz-Algorithm")
  valid_603626 = validateParameter(valid_603626, JString, required = false,
                                 default = nil)
  if valid_603626 != nil:
    section.add "X-Amz-Algorithm", valid_603626
  var valid_603627 = header.getOrDefault("X-Amz-Signature")
  valid_603627 = validateParameter(valid_603627, JString, required = false,
                                 default = nil)
  if valid_603627 != nil:
    section.add "X-Amz-Signature", valid_603627
  var valid_603628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = nil)
  if valid_603628 != nil:
    section.add "X-Amz-SignedHeaders", valid_603628
  var valid_603629 = header.getOrDefault("X-Amz-Credential")
  valid_603629 = validateParameter(valid_603629, JString, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "X-Amz-Credential", valid_603629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603631: Call_StartFleet_603619; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the specified fleet.
  ## 
  let valid = call_603631.validator(path, query, header, formData, body)
  let scheme = call_603631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603631.url(scheme.get, call_603631.host, call_603631.base,
                         call_603631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603631, url, valid)

proc call*(call_603632: Call_StartFleet_603619; body: JsonNode): Recallable =
  ## startFleet
  ## Starts the specified fleet.
  ##   body: JObject (required)
  var body_603633 = newJObject()
  if body != nil:
    body_603633 = body
  result = call_603632.call(nil, nil, nil, nil, body_603633)

var startFleet* = Call_StartFleet_603619(name: "startFleet",
                                      meth: HttpMethod.HttpPost,
                                      host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.StartFleet",
                                      validator: validate_StartFleet_603620,
                                      base: "/", url: url_StartFleet_603621,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImageBuilder_603634 = ref object of OpenApiRestCall_602466
proc url_StartImageBuilder_603636(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartImageBuilder_603635(path: JsonNode; query: JsonNode;
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
  var valid_603637 = header.getOrDefault("X-Amz-Date")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "X-Amz-Date", valid_603637
  var valid_603638 = header.getOrDefault("X-Amz-Security-Token")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "X-Amz-Security-Token", valid_603638
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603639 = header.getOrDefault("X-Amz-Target")
  valid_603639 = validateParameter(valid_603639, JString, required = true, default = newJString(
      "PhotonAdminProxyService.StartImageBuilder"))
  if valid_603639 != nil:
    section.add "X-Amz-Target", valid_603639
  var valid_603640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603640 = validateParameter(valid_603640, JString, required = false,
                                 default = nil)
  if valid_603640 != nil:
    section.add "X-Amz-Content-Sha256", valid_603640
  var valid_603641 = header.getOrDefault("X-Amz-Algorithm")
  valid_603641 = validateParameter(valid_603641, JString, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "X-Amz-Algorithm", valid_603641
  var valid_603642 = header.getOrDefault("X-Amz-Signature")
  valid_603642 = validateParameter(valid_603642, JString, required = false,
                                 default = nil)
  if valid_603642 != nil:
    section.add "X-Amz-Signature", valid_603642
  var valid_603643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603643 = validateParameter(valid_603643, JString, required = false,
                                 default = nil)
  if valid_603643 != nil:
    section.add "X-Amz-SignedHeaders", valid_603643
  var valid_603644 = header.getOrDefault("X-Amz-Credential")
  valid_603644 = validateParameter(valid_603644, JString, required = false,
                                 default = nil)
  if valid_603644 != nil:
    section.add "X-Amz-Credential", valid_603644
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603646: Call_StartImageBuilder_603634; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the specified image builder.
  ## 
  let valid = call_603646.validator(path, query, header, formData, body)
  let scheme = call_603646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603646.url(scheme.get, call_603646.host, call_603646.base,
                         call_603646.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603646, url, valid)

proc call*(call_603647: Call_StartImageBuilder_603634; body: JsonNode): Recallable =
  ## startImageBuilder
  ## Starts the specified image builder.
  ##   body: JObject (required)
  var body_603648 = newJObject()
  if body != nil:
    body_603648 = body
  result = call_603647.call(nil, nil, nil, nil, body_603648)

var startImageBuilder* = Call_StartImageBuilder_603634(name: "startImageBuilder",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.StartImageBuilder",
    validator: validate_StartImageBuilder_603635, base: "/",
    url: url_StartImageBuilder_603636, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopFleet_603649 = ref object of OpenApiRestCall_602466
proc url_StopFleet_603651(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopFleet_603650(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603652 = header.getOrDefault("X-Amz-Date")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-Date", valid_603652
  var valid_603653 = header.getOrDefault("X-Amz-Security-Token")
  valid_603653 = validateParameter(valid_603653, JString, required = false,
                                 default = nil)
  if valid_603653 != nil:
    section.add "X-Amz-Security-Token", valid_603653
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603654 = header.getOrDefault("X-Amz-Target")
  valid_603654 = validateParameter(valid_603654, JString, required = true, default = newJString(
      "PhotonAdminProxyService.StopFleet"))
  if valid_603654 != nil:
    section.add "X-Amz-Target", valid_603654
  var valid_603655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603655 = validateParameter(valid_603655, JString, required = false,
                                 default = nil)
  if valid_603655 != nil:
    section.add "X-Amz-Content-Sha256", valid_603655
  var valid_603656 = header.getOrDefault("X-Amz-Algorithm")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "X-Amz-Algorithm", valid_603656
  var valid_603657 = header.getOrDefault("X-Amz-Signature")
  valid_603657 = validateParameter(valid_603657, JString, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "X-Amz-Signature", valid_603657
  var valid_603658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "X-Amz-SignedHeaders", valid_603658
  var valid_603659 = header.getOrDefault("X-Amz-Credential")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "X-Amz-Credential", valid_603659
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603661: Call_StopFleet_603649; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the specified fleet.
  ## 
  let valid = call_603661.validator(path, query, header, formData, body)
  let scheme = call_603661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603661.url(scheme.get, call_603661.host, call_603661.base,
                         call_603661.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603661, url, valid)

proc call*(call_603662: Call_StopFleet_603649; body: JsonNode): Recallable =
  ## stopFleet
  ## Stops the specified fleet.
  ##   body: JObject (required)
  var body_603663 = newJObject()
  if body != nil:
    body_603663 = body
  result = call_603662.call(nil, nil, nil, nil, body_603663)

var stopFleet* = Call_StopFleet_603649(name: "stopFleet", meth: HttpMethod.HttpPost,
                                    host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.StopFleet",
                                    validator: validate_StopFleet_603650,
                                    base: "/", url: url_StopFleet_603651,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopImageBuilder_603664 = ref object of OpenApiRestCall_602466
proc url_StopImageBuilder_603666(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopImageBuilder_603665(path: JsonNode; query: JsonNode;
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
  var valid_603667 = header.getOrDefault("X-Amz-Date")
  valid_603667 = validateParameter(valid_603667, JString, required = false,
                                 default = nil)
  if valid_603667 != nil:
    section.add "X-Amz-Date", valid_603667
  var valid_603668 = header.getOrDefault("X-Amz-Security-Token")
  valid_603668 = validateParameter(valid_603668, JString, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "X-Amz-Security-Token", valid_603668
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603669 = header.getOrDefault("X-Amz-Target")
  valid_603669 = validateParameter(valid_603669, JString, required = true, default = newJString(
      "PhotonAdminProxyService.StopImageBuilder"))
  if valid_603669 != nil:
    section.add "X-Amz-Target", valid_603669
  var valid_603670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603670 = validateParameter(valid_603670, JString, required = false,
                                 default = nil)
  if valid_603670 != nil:
    section.add "X-Amz-Content-Sha256", valid_603670
  var valid_603671 = header.getOrDefault("X-Amz-Algorithm")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "X-Amz-Algorithm", valid_603671
  var valid_603672 = header.getOrDefault("X-Amz-Signature")
  valid_603672 = validateParameter(valid_603672, JString, required = false,
                                 default = nil)
  if valid_603672 != nil:
    section.add "X-Amz-Signature", valid_603672
  var valid_603673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "X-Amz-SignedHeaders", valid_603673
  var valid_603674 = header.getOrDefault("X-Amz-Credential")
  valid_603674 = validateParameter(valid_603674, JString, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "X-Amz-Credential", valid_603674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603676: Call_StopImageBuilder_603664; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the specified image builder.
  ## 
  let valid = call_603676.validator(path, query, header, formData, body)
  let scheme = call_603676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603676.url(scheme.get, call_603676.host, call_603676.base,
                         call_603676.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603676, url, valid)

proc call*(call_603677: Call_StopImageBuilder_603664; body: JsonNode): Recallable =
  ## stopImageBuilder
  ## Stops the specified image builder.
  ##   body: JObject (required)
  var body_603678 = newJObject()
  if body != nil:
    body_603678 = body
  result = call_603677.call(nil, nil, nil, nil, body_603678)

var stopImageBuilder* = Call_StopImageBuilder_603664(name: "stopImageBuilder",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.StopImageBuilder",
    validator: validate_StopImageBuilder_603665, base: "/",
    url: url_StopImageBuilder_603666, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603679 = ref object of OpenApiRestCall_602466
proc url_TagResource_603681(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_603680(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603682 = header.getOrDefault("X-Amz-Date")
  valid_603682 = validateParameter(valid_603682, JString, required = false,
                                 default = nil)
  if valid_603682 != nil:
    section.add "X-Amz-Date", valid_603682
  var valid_603683 = header.getOrDefault("X-Amz-Security-Token")
  valid_603683 = validateParameter(valid_603683, JString, required = false,
                                 default = nil)
  if valid_603683 != nil:
    section.add "X-Amz-Security-Token", valid_603683
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603684 = header.getOrDefault("X-Amz-Target")
  valid_603684 = validateParameter(valid_603684, JString, required = true, default = newJString(
      "PhotonAdminProxyService.TagResource"))
  if valid_603684 != nil:
    section.add "X-Amz-Target", valid_603684
  var valid_603685 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603685 = validateParameter(valid_603685, JString, required = false,
                                 default = nil)
  if valid_603685 != nil:
    section.add "X-Amz-Content-Sha256", valid_603685
  var valid_603686 = header.getOrDefault("X-Amz-Algorithm")
  valid_603686 = validateParameter(valid_603686, JString, required = false,
                                 default = nil)
  if valid_603686 != nil:
    section.add "X-Amz-Algorithm", valid_603686
  var valid_603687 = header.getOrDefault("X-Amz-Signature")
  valid_603687 = validateParameter(valid_603687, JString, required = false,
                                 default = nil)
  if valid_603687 != nil:
    section.add "X-Amz-Signature", valid_603687
  var valid_603688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603688 = validateParameter(valid_603688, JString, required = false,
                                 default = nil)
  if valid_603688 != nil:
    section.add "X-Amz-SignedHeaders", valid_603688
  var valid_603689 = header.getOrDefault("X-Amz-Credential")
  valid_603689 = validateParameter(valid_603689, JString, required = false,
                                 default = nil)
  if valid_603689 != nil:
    section.add "X-Amz-Credential", valid_603689
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603691: Call_TagResource_603679; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or overwrites one or more tags for the specified AppStream 2.0 resource. You can tag AppStream 2.0 image builders, images, fleets, and stacks.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, this operation updates its value.</p> <p>To list the current tags for your resources, use <a>ListTagsForResource</a>. To disassociate tags from your resources, use <a>UntagResource</a>.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
  ## 
  let valid = call_603691.validator(path, query, header, formData, body)
  let scheme = call_603691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603691.url(scheme.get, call_603691.host, call_603691.base,
                         call_603691.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603691, url, valid)

proc call*(call_603692: Call_TagResource_603679; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds or overwrites one or more tags for the specified AppStream 2.0 resource. You can tag AppStream 2.0 image builders, images, fleets, and stacks.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, this operation updates its value.</p> <p>To list the current tags for your resources, use <a>ListTagsForResource</a>. To disassociate tags from your resources, use <a>UntagResource</a>.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
  ##   body: JObject (required)
  var body_603693 = newJObject()
  if body != nil:
    body_603693 = body
  result = call_603692.call(nil, nil, nil, nil, body_603693)

var tagResource* = Call_TagResource_603679(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.TagResource",
                                        validator: validate_TagResource_603680,
                                        base: "/", url: url_TagResource_603681,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603694 = ref object of OpenApiRestCall_602466
proc url_UntagResource_603696(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_603695(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603697 = header.getOrDefault("X-Amz-Date")
  valid_603697 = validateParameter(valid_603697, JString, required = false,
                                 default = nil)
  if valid_603697 != nil:
    section.add "X-Amz-Date", valid_603697
  var valid_603698 = header.getOrDefault("X-Amz-Security-Token")
  valid_603698 = validateParameter(valid_603698, JString, required = false,
                                 default = nil)
  if valid_603698 != nil:
    section.add "X-Amz-Security-Token", valid_603698
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603699 = header.getOrDefault("X-Amz-Target")
  valid_603699 = validateParameter(valid_603699, JString, required = true, default = newJString(
      "PhotonAdminProxyService.UntagResource"))
  if valid_603699 != nil:
    section.add "X-Amz-Target", valid_603699
  var valid_603700 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603700 = validateParameter(valid_603700, JString, required = false,
                                 default = nil)
  if valid_603700 != nil:
    section.add "X-Amz-Content-Sha256", valid_603700
  var valid_603701 = header.getOrDefault("X-Amz-Algorithm")
  valid_603701 = validateParameter(valid_603701, JString, required = false,
                                 default = nil)
  if valid_603701 != nil:
    section.add "X-Amz-Algorithm", valid_603701
  var valid_603702 = header.getOrDefault("X-Amz-Signature")
  valid_603702 = validateParameter(valid_603702, JString, required = false,
                                 default = nil)
  if valid_603702 != nil:
    section.add "X-Amz-Signature", valid_603702
  var valid_603703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603703 = validateParameter(valid_603703, JString, required = false,
                                 default = nil)
  if valid_603703 != nil:
    section.add "X-Amz-SignedHeaders", valid_603703
  var valid_603704 = header.getOrDefault("X-Amz-Credential")
  valid_603704 = validateParameter(valid_603704, JString, required = false,
                                 default = nil)
  if valid_603704 != nil:
    section.add "X-Amz-Credential", valid_603704
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603706: Call_UntagResource_603694; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates one or more specified tags from the specified AppStream 2.0 resource.</p> <p>To list the current tags for your resources, use <a>ListTagsForResource</a>.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
  ## 
  let valid = call_603706.validator(path, query, header, formData, body)
  let scheme = call_603706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603706.url(scheme.get, call_603706.host, call_603706.base,
                         call_603706.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603706, url, valid)

proc call*(call_603707: Call_UntagResource_603694; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Disassociates one or more specified tags from the specified AppStream 2.0 resource.</p> <p>To list the current tags for your resources, use <a>ListTagsForResource</a>.</p> <p>For more information about tags, see <a href="https://docs.aws.amazon.com/appstream2/latest/developerguide/tagging-basic.html">Tagging Your Resources</a> in the <i>Amazon AppStream 2.0 Administration Guide</i>.</p>
  ##   body: JObject (required)
  var body_603708 = newJObject()
  if body != nil:
    body_603708 = body
  result = call_603707.call(nil, nil, nil, nil, body_603708)

var untagResource* = Call_UntagResource_603694(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.UntagResource",
    validator: validate_UntagResource_603695, base: "/", url: url_UntagResource_603696,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDirectoryConfig_603709 = ref object of OpenApiRestCall_602466
proc url_UpdateDirectoryConfig_603711(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDirectoryConfig_603710(path: JsonNode; query: JsonNode;
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
  var valid_603712 = header.getOrDefault("X-Amz-Date")
  valid_603712 = validateParameter(valid_603712, JString, required = false,
                                 default = nil)
  if valid_603712 != nil:
    section.add "X-Amz-Date", valid_603712
  var valid_603713 = header.getOrDefault("X-Amz-Security-Token")
  valid_603713 = validateParameter(valid_603713, JString, required = false,
                                 default = nil)
  if valid_603713 != nil:
    section.add "X-Amz-Security-Token", valid_603713
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603714 = header.getOrDefault("X-Amz-Target")
  valid_603714 = validateParameter(valid_603714, JString, required = true, default = newJString(
      "PhotonAdminProxyService.UpdateDirectoryConfig"))
  if valid_603714 != nil:
    section.add "X-Amz-Target", valid_603714
  var valid_603715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603715 = validateParameter(valid_603715, JString, required = false,
                                 default = nil)
  if valid_603715 != nil:
    section.add "X-Amz-Content-Sha256", valid_603715
  var valid_603716 = header.getOrDefault("X-Amz-Algorithm")
  valid_603716 = validateParameter(valid_603716, JString, required = false,
                                 default = nil)
  if valid_603716 != nil:
    section.add "X-Amz-Algorithm", valid_603716
  var valid_603717 = header.getOrDefault("X-Amz-Signature")
  valid_603717 = validateParameter(valid_603717, JString, required = false,
                                 default = nil)
  if valid_603717 != nil:
    section.add "X-Amz-Signature", valid_603717
  var valid_603718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603718 = validateParameter(valid_603718, JString, required = false,
                                 default = nil)
  if valid_603718 != nil:
    section.add "X-Amz-SignedHeaders", valid_603718
  var valid_603719 = header.getOrDefault("X-Amz-Credential")
  valid_603719 = validateParameter(valid_603719, JString, required = false,
                                 default = nil)
  if valid_603719 != nil:
    section.add "X-Amz-Credential", valid_603719
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603721: Call_UpdateDirectoryConfig_603709; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified Directory Config object in AppStream 2.0. This object includes the configuration information required to join fleets and image builders to Microsoft Active Directory domains.
  ## 
  let valid = call_603721.validator(path, query, header, formData, body)
  let scheme = call_603721.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603721.url(scheme.get, call_603721.host, call_603721.base,
                         call_603721.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603721, url, valid)

proc call*(call_603722: Call_UpdateDirectoryConfig_603709; body: JsonNode): Recallable =
  ## updateDirectoryConfig
  ## Updates the specified Directory Config object in AppStream 2.0. This object includes the configuration information required to join fleets and image builders to Microsoft Active Directory domains.
  ##   body: JObject (required)
  var body_603723 = newJObject()
  if body != nil:
    body_603723 = body
  result = call_603722.call(nil, nil, nil, nil, body_603723)

var updateDirectoryConfig* = Call_UpdateDirectoryConfig_603709(
    name: "updateDirectoryConfig", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.UpdateDirectoryConfig",
    validator: validate_UpdateDirectoryConfig_603710, base: "/",
    url: url_UpdateDirectoryConfig_603711, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFleet_603724 = ref object of OpenApiRestCall_602466
proc url_UpdateFleet_603726(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateFleet_603725(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603727 = header.getOrDefault("X-Amz-Date")
  valid_603727 = validateParameter(valid_603727, JString, required = false,
                                 default = nil)
  if valid_603727 != nil:
    section.add "X-Amz-Date", valid_603727
  var valid_603728 = header.getOrDefault("X-Amz-Security-Token")
  valid_603728 = validateParameter(valid_603728, JString, required = false,
                                 default = nil)
  if valid_603728 != nil:
    section.add "X-Amz-Security-Token", valid_603728
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603729 = header.getOrDefault("X-Amz-Target")
  valid_603729 = validateParameter(valid_603729, JString, required = true, default = newJString(
      "PhotonAdminProxyService.UpdateFleet"))
  if valid_603729 != nil:
    section.add "X-Amz-Target", valid_603729
  var valid_603730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603730 = validateParameter(valid_603730, JString, required = false,
                                 default = nil)
  if valid_603730 != nil:
    section.add "X-Amz-Content-Sha256", valid_603730
  var valid_603731 = header.getOrDefault("X-Amz-Algorithm")
  valid_603731 = validateParameter(valid_603731, JString, required = false,
                                 default = nil)
  if valid_603731 != nil:
    section.add "X-Amz-Algorithm", valid_603731
  var valid_603732 = header.getOrDefault("X-Amz-Signature")
  valid_603732 = validateParameter(valid_603732, JString, required = false,
                                 default = nil)
  if valid_603732 != nil:
    section.add "X-Amz-Signature", valid_603732
  var valid_603733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603733 = validateParameter(valid_603733, JString, required = false,
                                 default = nil)
  if valid_603733 != nil:
    section.add "X-Amz-SignedHeaders", valid_603733
  var valid_603734 = header.getOrDefault("X-Amz-Credential")
  valid_603734 = validateParameter(valid_603734, JString, required = false,
                                 default = nil)
  if valid_603734 != nil:
    section.add "X-Amz-Credential", valid_603734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603736: Call_UpdateFleet_603724; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified fleet.</p> <p>If the fleet is in the <code>STOPPED</code> state, you can update any attribute except the fleet name. If the fleet is in the <code>RUNNING</code> state, you can update the <code>DisplayName</code>, <code>ComputeCapacity</code>, <code>ImageARN</code>, <code>ImageName</code>, <code>IdleDisconnectTimeoutInSeconds</code>, and <code>DisconnectTimeoutInSeconds</code> attributes. If the fleet is in the <code>STARTING</code> or <code>STOPPING</code> state, you can't update it.</p>
  ## 
  let valid = call_603736.validator(path, query, header, formData, body)
  let scheme = call_603736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603736.url(scheme.get, call_603736.host, call_603736.base,
                         call_603736.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603736, url, valid)

proc call*(call_603737: Call_UpdateFleet_603724; body: JsonNode): Recallable =
  ## updateFleet
  ## <p>Updates the specified fleet.</p> <p>If the fleet is in the <code>STOPPED</code> state, you can update any attribute except the fleet name. If the fleet is in the <code>RUNNING</code> state, you can update the <code>DisplayName</code>, <code>ComputeCapacity</code>, <code>ImageARN</code>, <code>ImageName</code>, <code>IdleDisconnectTimeoutInSeconds</code>, and <code>DisconnectTimeoutInSeconds</code> attributes. If the fleet is in the <code>STARTING</code> or <code>STOPPING</code> state, you can't update it.</p>
  ##   body: JObject (required)
  var body_603738 = newJObject()
  if body != nil:
    body_603738 = body
  result = call_603737.call(nil, nil, nil, nil, body_603738)

var updateFleet* = Call_UpdateFleet_603724(name: "updateFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.UpdateFleet",
                                        validator: validate_UpdateFleet_603725,
                                        base: "/", url: url_UpdateFleet_603726,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateImagePermissions_603739 = ref object of OpenApiRestCall_602466
proc url_UpdateImagePermissions_603741(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateImagePermissions_603740(path: JsonNode; query: JsonNode;
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
  var valid_603742 = header.getOrDefault("X-Amz-Date")
  valid_603742 = validateParameter(valid_603742, JString, required = false,
                                 default = nil)
  if valid_603742 != nil:
    section.add "X-Amz-Date", valid_603742
  var valid_603743 = header.getOrDefault("X-Amz-Security-Token")
  valid_603743 = validateParameter(valid_603743, JString, required = false,
                                 default = nil)
  if valid_603743 != nil:
    section.add "X-Amz-Security-Token", valid_603743
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603744 = header.getOrDefault("X-Amz-Target")
  valid_603744 = validateParameter(valid_603744, JString, required = true, default = newJString(
      "PhotonAdminProxyService.UpdateImagePermissions"))
  if valid_603744 != nil:
    section.add "X-Amz-Target", valid_603744
  var valid_603745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603745 = validateParameter(valid_603745, JString, required = false,
                                 default = nil)
  if valid_603745 != nil:
    section.add "X-Amz-Content-Sha256", valid_603745
  var valid_603746 = header.getOrDefault("X-Amz-Algorithm")
  valid_603746 = validateParameter(valid_603746, JString, required = false,
                                 default = nil)
  if valid_603746 != nil:
    section.add "X-Amz-Algorithm", valid_603746
  var valid_603747 = header.getOrDefault("X-Amz-Signature")
  valid_603747 = validateParameter(valid_603747, JString, required = false,
                                 default = nil)
  if valid_603747 != nil:
    section.add "X-Amz-Signature", valid_603747
  var valid_603748 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603748 = validateParameter(valid_603748, JString, required = false,
                                 default = nil)
  if valid_603748 != nil:
    section.add "X-Amz-SignedHeaders", valid_603748
  var valid_603749 = header.getOrDefault("X-Amz-Credential")
  valid_603749 = validateParameter(valid_603749, JString, required = false,
                                 default = nil)
  if valid_603749 != nil:
    section.add "X-Amz-Credential", valid_603749
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603751: Call_UpdateImagePermissions_603739; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates permissions for the specified private image. 
  ## 
  let valid = call_603751.validator(path, query, header, formData, body)
  let scheme = call_603751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603751.url(scheme.get, call_603751.host, call_603751.base,
                         call_603751.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603751, url, valid)

proc call*(call_603752: Call_UpdateImagePermissions_603739; body: JsonNode): Recallable =
  ## updateImagePermissions
  ## Adds or updates permissions for the specified private image. 
  ##   body: JObject (required)
  var body_603753 = newJObject()
  if body != nil:
    body_603753 = body
  result = call_603752.call(nil, nil, nil, nil, body_603753)

var updateImagePermissions* = Call_UpdateImagePermissions_603739(
    name: "updateImagePermissions", meth: HttpMethod.HttpPost,
    host: "appstream2.amazonaws.com",
    route: "/#X-Amz-Target=PhotonAdminProxyService.UpdateImagePermissions",
    validator: validate_UpdateImagePermissions_603740, base: "/",
    url: url_UpdateImagePermissions_603741, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStack_603754 = ref object of OpenApiRestCall_602466
proc url_UpdateStack_603756(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateStack_603755(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603757 = header.getOrDefault("X-Amz-Date")
  valid_603757 = validateParameter(valid_603757, JString, required = false,
                                 default = nil)
  if valid_603757 != nil:
    section.add "X-Amz-Date", valid_603757
  var valid_603758 = header.getOrDefault("X-Amz-Security-Token")
  valid_603758 = validateParameter(valid_603758, JString, required = false,
                                 default = nil)
  if valid_603758 != nil:
    section.add "X-Amz-Security-Token", valid_603758
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603759 = header.getOrDefault("X-Amz-Target")
  valid_603759 = validateParameter(valid_603759, JString, required = true, default = newJString(
      "PhotonAdminProxyService.UpdateStack"))
  if valid_603759 != nil:
    section.add "X-Amz-Target", valid_603759
  var valid_603760 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603760 = validateParameter(valid_603760, JString, required = false,
                                 default = nil)
  if valid_603760 != nil:
    section.add "X-Amz-Content-Sha256", valid_603760
  var valid_603761 = header.getOrDefault("X-Amz-Algorithm")
  valid_603761 = validateParameter(valid_603761, JString, required = false,
                                 default = nil)
  if valid_603761 != nil:
    section.add "X-Amz-Algorithm", valid_603761
  var valid_603762 = header.getOrDefault("X-Amz-Signature")
  valid_603762 = validateParameter(valid_603762, JString, required = false,
                                 default = nil)
  if valid_603762 != nil:
    section.add "X-Amz-Signature", valid_603762
  var valid_603763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603763 = validateParameter(valid_603763, JString, required = false,
                                 default = nil)
  if valid_603763 != nil:
    section.add "X-Amz-SignedHeaders", valid_603763
  var valid_603764 = header.getOrDefault("X-Amz-Credential")
  valid_603764 = validateParameter(valid_603764, JString, required = false,
                                 default = nil)
  if valid_603764 != nil:
    section.add "X-Amz-Credential", valid_603764
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603766: Call_UpdateStack_603754; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified fields for the specified stack.
  ## 
  let valid = call_603766.validator(path, query, header, formData, body)
  let scheme = call_603766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603766.url(scheme.get, call_603766.host, call_603766.base,
                         call_603766.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603766, url, valid)

proc call*(call_603767: Call_UpdateStack_603754; body: JsonNode): Recallable =
  ## updateStack
  ## Updates the specified fields for the specified stack.
  ##   body: JObject (required)
  var body_603768 = newJObject()
  if body != nil:
    body_603768 = body
  result = call_603767.call(nil, nil, nil, nil, body_603768)

var updateStack* = Call_UpdateStack_603754(name: "updateStack",
                                        meth: HttpMethod.HttpPost,
                                        host: "appstream2.amazonaws.com", route: "/#X-Amz-Target=PhotonAdminProxyService.UpdateStack",
                                        validator: validate_UpdateStack_603755,
                                        base: "/", url: url_UpdateStack_603756,
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
