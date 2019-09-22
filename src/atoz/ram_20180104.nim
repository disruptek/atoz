
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Resource Access Manager
## version: 2018-01-04
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Use AWS Resource Access Manager to share AWS resources between AWS accounts. To share a resource, you create a resource share, associate the resource with the resource share, and specify the principals that can access the resources associated with the resource share. The following principals are supported: AWS accounts, organizational units (OU) from AWS Organizations, and organizations from AWS Organizations.</p> <p>For more information, see the <a href="https://docs.aws.amazon.com/ram/latest/userguide/">AWS Resource Access Manager User Guide</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/ram/
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

  OpenApiRestCall_602433 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602433](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602433): Option[Scheme] {.used.} =
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
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "ram.ap-northeast-1.amazonaws.com", "ap-southeast-1": "ram.ap-southeast-1.amazonaws.com",
                           "us-west-2": "ram.us-west-2.amazonaws.com",
                           "eu-west-2": "ram.eu-west-2.amazonaws.com", "ap-northeast-3": "ram.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "ram.eu-central-1.amazonaws.com",
                           "us-east-2": "ram.us-east-2.amazonaws.com",
                           "us-east-1": "ram.us-east-1.amazonaws.com", "cn-northwest-1": "ram.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "ram.ap-south-1.amazonaws.com",
                           "eu-north-1": "ram.eu-north-1.amazonaws.com", "ap-northeast-2": "ram.ap-northeast-2.amazonaws.com",
                           "us-west-1": "ram.us-west-1.amazonaws.com",
                           "us-gov-east-1": "ram.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "ram.eu-west-3.amazonaws.com",
                           "cn-north-1": "ram.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "ram.sa-east-1.amazonaws.com",
                           "eu-west-1": "ram.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "ram.us-gov-west-1.amazonaws.com", "ap-southeast-2": "ram.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "ram.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "ram.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "ram.ap-southeast-1.amazonaws.com",
      "us-west-2": "ram.us-west-2.amazonaws.com",
      "eu-west-2": "ram.eu-west-2.amazonaws.com",
      "ap-northeast-3": "ram.ap-northeast-3.amazonaws.com",
      "eu-central-1": "ram.eu-central-1.amazonaws.com",
      "us-east-2": "ram.us-east-2.amazonaws.com",
      "us-east-1": "ram.us-east-1.amazonaws.com",
      "cn-northwest-1": "ram.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "ram.ap-south-1.amazonaws.com",
      "eu-north-1": "ram.eu-north-1.amazonaws.com",
      "ap-northeast-2": "ram.ap-northeast-2.amazonaws.com",
      "us-west-1": "ram.us-west-1.amazonaws.com",
      "us-gov-east-1": "ram.us-gov-east-1.amazonaws.com",
      "eu-west-3": "ram.eu-west-3.amazonaws.com",
      "cn-north-1": "ram.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "ram.sa-east-1.amazonaws.com",
      "eu-west-1": "ram.eu-west-1.amazonaws.com",
      "us-gov-west-1": "ram.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "ram.ap-southeast-2.amazonaws.com",
      "ca-central-1": "ram.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "ram"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AcceptResourceShareInvitation_602770 = ref object of OpenApiRestCall_602433
proc url_AcceptResourceShareInvitation_602772(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AcceptResourceShareInvitation_602771(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Accepts an invitation to a resource share from another AWS account.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602884 = header.getOrDefault("X-Amz-Date")
  valid_602884 = validateParameter(valid_602884, JString, required = false,
                                 default = nil)
  if valid_602884 != nil:
    section.add "X-Amz-Date", valid_602884
  var valid_602885 = header.getOrDefault("X-Amz-Security-Token")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "X-Amz-Security-Token", valid_602885
  var valid_602886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602886 = validateParameter(valid_602886, JString, required = false,
                                 default = nil)
  if valid_602886 != nil:
    section.add "X-Amz-Content-Sha256", valid_602886
  var valid_602887 = header.getOrDefault("X-Amz-Algorithm")
  valid_602887 = validateParameter(valid_602887, JString, required = false,
                                 default = nil)
  if valid_602887 != nil:
    section.add "X-Amz-Algorithm", valid_602887
  var valid_602888 = header.getOrDefault("X-Amz-Signature")
  valid_602888 = validateParameter(valid_602888, JString, required = false,
                                 default = nil)
  if valid_602888 != nil:
    section.add "X-Amz-Signature", valid_602888
  var valid_602889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602889 = validateParameter(valid_602889, JString, required = false,
                                 default = nil)
  if valid_602889 != nil:
    section.add "X-Amz-SignedHeaders", valid_602889
  var valid_602890 = header.getOrDefault("X-Amz-Credential")
  valid_602890 = validateParameter(valid_602890, JString, required = false,
                                 default = nil)
  if valid_602890 != nil:
    section.add "X-Amz-Credential", valid_602890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602914: Call_AcceptResourceShareInvitation_602770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts an invitation to a resource share from another AWS account.
  ## 
  let valid = call_602914.validator(path, query, header, formData, body)
  let scheme = call_602914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602914.url(scheme.get, call_602914.host, call_602914.base,
                         call_602914.route, valid.getOrDefault("path"))
  result = hook(call_602914, url, valid)

proc call*(call_602985: Call_AcceptResourceShareInvitation_602770; body: JsonNode): Recallable =
  ## acceptResourceShareInvitation
  ## Accepts an invitation to a resource share from another AWS account.
  ##   body: JObject (required)
  var body_602986 = newJObject()
  if body != nil:
    body_602986 = body
  result = call_602985.call(nil, nil, nil, nil, body_602986)

var acceptResourceShareInvitation* = Call_AcceptResourceShareInvitation_602770(
    name: "acceptResourceShareInvitation", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/acceptresourceshareinvitation",
    validator: validate_AcceptResourceShareInvitation_602771, base: "/",
    url: url_AcceptResourceShareInvitation_602772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateResourceShare_603025 = ref object of OpenApiRestCall_602433
proc url_AssociateResourceShare_603027(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AssociateResourceShare_603026(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates the specified resource share with the specified principals and resources.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603028 = header.getOrDefault("X-Amz-Date")
  valid_603028 = validateParameter(valid_603028, JString, required = false,
                                 default = nil)
  if valid_603028 != nil:
    section.add "X-Amz-Date", valid_603028
  var valid_603029 = header.getOrDefault("X-Amz-Security-Token")
  valid_603029 = validateParameter(valid_603029, JString, required = false,
                                 default = nil)
  if valid_603029 != nil:
    section.add "X-Amz-Security-Token", valid_603029
  var valid_603030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603030 = validateParameter(valid_603030, JString, required = false,
                                 default = nil)
  if valid_603030 != nil:
    section.add "X-Amz-Content-Sha256", valid_603030
  var valid_603031 = header.getOrDefault("X-Amz-Algorithm")
  valid_603031 = validateParameter(valid_603031, JString, required = false,
                                 default = nil)
  if valid_603031 != nil:
    section.add "X-Amz-Algorithm", valid_603031
  var valid_603032 = header.getOrDefault("X-Amz-Signature")
  valid_603032 = validateParameter(valid_603032, JString, required = false,
                                 default = nil)
  if valid_603032 != nil:
    section.add "X-Amz-Signature", valid_603032
  var valid_603033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603033 = validateParameter(valid_603033, JString, required = false,
                                 default = nil)
  if valid_603033 != nil:
    section.add "X-Amz-SignedHeaders", valid_603033
  var valid_603034 = header.getOrDefault("X-Amz-Credential")
  valid_603034 = validateParameter(valid_603034, JString, required = false,
                                 default = nil)
  if valid_603034 != nil:
    section.add "X-Amz-Credential", valid_603034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603036: Call_AssociateResourceShare_603025; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified resource share with the specified principals and resources.
  ## 
  let valid = call_603036.validator(path, query, header, formData, body)
  let scheme = call_603036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603036.url(scheme.get, call_603036.host, call_603036.base,
                         call_603036.route, valid.getOrDefault("path"))
  result = hook(call_603036, url, valid)

proc call*(call_603037: Call_AssociateResourceShare_603025; body: JsonNode): Recallable =
  ## associateResourceShare
  ## Associates the specified resource share with the specified principals and resources.
  ##   body: JObject (required)
  var body_603038 = newJObject()
  if body != nil:
    body_603038 = body
  result = call_603037.call(nil, nil, nil, nil, body_603038)

var associateResourceShare* = Call_AssociateResourceShare_603025(
    name: "associateResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/associateresourceshare",
    validator: validate_AssociateResourceShare_603026, base: "/",
    url: url_AssociateResourceShare_603027, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceShare_603039 = ref object of OpenApiRestCall_602433
proc url_CreateResourceShare_603041(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateResourceShare_603040(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates a resource share.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603042 = header.getOrDefault("X-Amz-Date")
  valid_603042 = validateParameter(valid_603042, JString, required = false,
                                 default = nil)
  if valid_603042 != nil:
    section.add "X-Amz-Date", valid_603042
  var valid_603043 = header.getOrDefault("X-Amz-Security-Token")
  valid_603043 = validateParameter(valid_603043, JString, required = false,
                                 default = nil)
  if valid_603043 != nil:
    section.add "X-Amz-Security-Token", valid_603043
  var valid_603044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603044 = validateParameter(valid_603044, JString, required = false,
                                 default = nil)
  if valid_603044 != nil:
    section.add "X-Amz-Content-Sha256", valid_603044
  var valid_603045 = header.getOrDefault("X-Amz-Algorithm")
  valid_603045 = validateParameter(valid_603045, JString, required = false,
                                 default = nil)
  if valid_603045 != nil:
    section.add "X-Amz-Algorithm", valid_603045
  var valid_603046 = header.getOrDefault("X-Amz-Signature")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "X-Amz-Signature", valid_603046
  var valid_603047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-SignedHeaders", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-Credential")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-Credential", valid_603048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603050: Call_CreateResourceShare_603039; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a resource share.
  ## 
  let valid = call_603050.validator(path, query, header, formData, body)
  let scheme = call_603050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603050.url(scheme.get, call_603050.host, call_603050.base,
                         call_603050.route, valid.getOrDefault("path"))
  result = hook(call_603050, url, valid)

proc call*(call_603051: Call_CreateResourceShare_603039; body: JsonNode): Recallable =
  ## createResourceShare
  ## Creates a resource share.
  ##   body: JObject (required)
  var body_603052 = newJObject()
  if body != nil:
    body_603052 = body
  result = call_603051.call(nil, nil, nil, nil, body_603052)

var createResourceShare* = Call_CreateResourceShare_603039(
    name: "createResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/createresourceshare",
    validator: validate_CreateResourceShare_603040, base: "/",
    url: url_CreateResourceShare_603041, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceShare_603053 = ref object of OpenApiRestCall_602433
proc url_DeleteResourceShare_603055(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteResourceShare_603054(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes the specified resource share.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   resourceShareArn: JString (required)
  ##                   : The Amazon Resource Name (ARN) of the resource share.
  ##   clientToken: JString
  ##              : A unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `resourceShareArn` field"
  var valid_603056 = query.getOrDefault("resourceShareArn")
  valid_603056 = validateParameter(valid_603056, JString, required = true,
                                 default = nil)
  if valid_603056 != nil:
    section.add "resourceShareArn", valid_603056
  var valid_603057 = query.getOrDefault("clientToken")
  valid_603057 = validateParameter(valid_603057, JString, required = false,
                                 default = nil)
  if valid_603057 != nil:
    section.add "clientToken", valid_603057
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603058 = header.getOrDefault("X-Amz-Date")
  valid_603058 = validateParameter(valid_603058, JString, required = false,
                                 default = nil)
  if valid_603058 != nil:
    section.add "X-Amz-Date", valid_603058
  var valid_603059 = header.getOrDefault("X-Amz-Security-Token")
  valid_603059 = validateParameter(valid_603059, JString, required = false,
                                 default = nil)
  if valid_603059 != nil:
    section.add "X-Amz-Security-Token", valid_603059
  var valid_603060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603060 = validateParameter(valid_603060, JString, required = false,
                                 default = nil)
  if valid_603060 != nil:
    section.add "X-Amz-Content-Sha256", valid_603060
  var valid_603061 = header.getOrDefault("X-Amz-Algorithm")
  valid_603061 = validateParameter(valid_603061, JString, required = false,
                                 default = nil)
  if valid_603061 != nil:
    section.add "X-Amz-Algorithm", valid_603061
  var valid_603062 = header.getOrDefault("X-Amz-Signature")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "X-Amz-Signature", valid_603062
  var valid_603063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-SignedHeaders", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-Credential")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Credential", valid_603064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603065: Call_DeleteResourceShare_603053; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified resource share.
  ## 
  let valid = call_603065.validator(path, query, header, formData, body)
  let scheme = call_603065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603065.url(scheme.get, call_603065.host, call_603065.base,
                         call_603065.route, valid.getOrDefault("path"))
  result = hook(call_603065, url, valid)

proc call*(call_603066: Call_DeleteResourceShare_603053; resourceShareArn: string;
          clientToken: string = ""): Recallable =
  ## deleteResourceShare
  ## Deletes the specified resource share.
  ##   resourceShareArn: string (required)
  ##                   : The Amazon Resource Name (ARN) of the resource share.
  ##   clientToken: string
  ##              : A unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  var query_603067 = newJObject()
  add(query_603067, "resourceShareArn", newJString(resourceShareArn))
  add(query_603067, "clientToken", newJString(clientToken))
  result = call_603066.call(nil, query_603067, nil, nil, nil)

var deleteResourceShare* = Call_DeleteResourceShare_603053(
    name: "deleteResourceShare", meth: HttpMethod.HttpDelete,
    host: "ram.amazonaws.com", route: "/deleteresourceshare#resourceShareArn",
    validator: validate_DeleteResourceShare_603054, base: "/",
    url: url_DeleteResourceShare_603055, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateResourceShare_603069 = ref object of OpenApiRestCall_602433
proc url_DisassociateResourceShare_603071(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociateResourceShare_603070(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates the specified principals or resources from the specified resource share.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603072 = header.getOrDefault("X-Amz-Date")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-Date", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-Security-Token")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Security-Token", valid_603073
  var valid_603074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603074 = validateParameter(valid_603074, JString, required = false,
                                 default = nil)
  if valid_603074 != nil:
    section.add "X-Amz-Content-Sha256", valid_603074
  var valid_603075 = header.getOrDefault("X-Amz-Algorithm")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Algorithm", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Signature")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Signature", valid_603076
  var valid_603077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-SignedHeaders", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Credential")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Credential", valid_603078
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603080: Call_DisassociateResourceShare_603069; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified principals or resources from the specified resource share.
  ## 
  let valid = call_603080.validator(path, query, header, formData, body)
  let scheme = call_603080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603080.url(scheme.get, call_603080.host, call_603080.base,
                         call_603080.route, valid.getOrDefault("path"))
  result = hook(call_603080, url, valid)

proc call*(call_603081: Call_DisassociateResourceShare_603069; body: JsonNode): Recallable =
  ## disassociateResourceShare
  ## Disassociates the specified principals or resources from the specified resource share.
  ##   body: JObject (required)
  var body_603082 = newJObject()
  if body != nil:
    body_603082 = body
  result = call_603081.call(nil, nil, nil, nil, body_603082)

var disassociateResourceShare* = Call_DisassociateResourceShare_603069(
    name: "disassociateResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/disassociateresourceshare",
    validator: validate_DisassociateResourceShare_603070, base: "/",
    url: url_DisassociateResourceShare_603071,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableSharingWithAwsOrganization_603083 = ref object of OpenApiRestCall_602433
proc url_EnableSharingWithAwsOrganization_603085(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_EnableSharingWithAwsOrganization_603084(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Enables resource sharing within your AWS Organization.</p> <p>The caller must be the master account for the AWS Organization.</p>
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603086 = header.getOrDefault("X-Amz-Date")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Date", valid_603086
  var valid_603087 = header.getOrDefault("X-Amz-Security-Token")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Security-Token", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Content-Sha256", valid_603088
  var valid_603089 = header.getOrDefault("X-Amz-Algorithm")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-Algorithm", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-Signature")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Signature", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-SignedHeaders", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-Credential")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Credential", valid_603092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603093: Call_EnableSharingWithAwsOrganization_603083;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Enables resource sharing within your AWS Organization.</p> <p>The caller must be the master account for the AWS Organization.</p>
  ## 
  let valid = call_603093.validator(path, query, header, formData, body)
  let scheme = call_603093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603093.url(scheme.get, call_603093.host, call_603093.base,
                         call_603093.route, valid.getOrDefault("path"))
  result = hook(call_603093, url, valid)

proc call*(call_603094: Call_EnableSharingWithAwsOrganization_603083): Recallable =
  ## enableSharingWithAwsOrganization
  ## <p>Enables resource sharing within your AWS Organization.</p> <p>The caller must be the master account for the AWS Organization.</p>
  result = call_603094.call(nil, nil, nil, nil, nil)

var enableSharingWithAwsOrganization* = Call_EnableSharingWithAwsOrganization_603083(
    name: "enableSharingWithAwsOrganization", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/enablesharingwithawsorganization",
    validator: validate_EnableSharingWithAwsOrganization_603084, base: "/",
    url: url_EnableSharingWithAwsOrganization_603085,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourcePolicies_603095 = ref object of OpenApiRestCall_602433
proc url_GetResourcePolicies_603097(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResourcePolicies_603096(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets the policies for the specified resources that you own and have shared.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603098 = query.getOrDefault("maxResults")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "maxResults", valid_603098
  var valid_603099 = query.getOrDefault("nextToken")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "nextToken", valid_603099
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603100 = header.getOrDefault("X-Amz-Date")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Date", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-Security-Token")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-Security-Token", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Content-Sha256", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Algorithm")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Algorithm", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-Signature")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Signature", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-SignedHeaders", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Credential")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Credential", valid_603106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603108: Call_GetResourcePolicies_603095; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the policies for the specified resources that you own and have shared.
  ## 
  let valid = call_603108.validator(path, query, header, formData, body)
  let scheme = call_603108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603108.url(scheme.get, call_603108.host, call_603108.base,
                         call_603108.route, valid.getOrDefault("path"))
  result = hook(call_603108, url, valid)

proc call*(call_603109: Call_GetResourcePolicies_603095; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getResourcePolicies
  ## Gets the policies for the specified resources that you own and have shared.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603110 = newJObject()
  var body_603111 = newJObject()
  add(query_603110, "maxResults", newJString(maxResults))
  add(query_603110, "nextToken", newJString(nextToken))
  if body != nil:
    body_603111 = body
  result = call_603109.call(nil, query_603110, nil, nil, body_603111)

var getResourcePolicies* = Call_GetResourcePolicies_603095(
    name: "getResourcePolicies", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/getresourcepolicies",
    validator: validate_GetResourcePolicies_603096, base: "/",
    url: url_GetResourcePolicies_603097, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceShareAssociations_603112 = ref object of OpenApiRestCall_602433
proc url_GetResourceShareAssociations_603114(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResourceShareAssociations_603113(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the resources or principals for the resource shares that you own.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603115 = query.getOrDefault("maxResults")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "maxResults", valid_603115
  var valid_603116 = query.getOrDefault("nextToken")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "nextToken", valid_603116
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603117 = header.getOrDefault("X-Amz-Date")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Date", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Security-Token")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Security-Token", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Content-Sha256", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Algorithm")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Algorithm", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Signature")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Signature", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-SignedHeaders", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Credential")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Credential", valid_603123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603125: Call_GetResourceShareAssociations_603112; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the resources or principals for the resource shares that you own.
  ## 
  let valid = call_603125.validator(path, query, header, formData, body)
  let scheme = call_603125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603125.url(scheme.get, call_603125.host, call_603125.base,
                         call_603125.route, valid.getOrDefault("path"))
  result = hook(call_603125, url, valid)

proc call*(call_603126: Call_GetResourceShareAssociations_603112; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getResourceShareAssociations
  ## Gets the resources or principals for the resource shares that you own.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603127 = newJObject()
  var body_603128 = newJObject()
  add(query_603127, "maxResults", newJString(maxResults))
  add(query_603127, "nextToken", newJString(nextToken))
  if body != nil:
    body_603128 = body
  result = call_603126.call(nil, query_603127, nil, nil, body_603128)

var getResourceShareAssociations* = Call_GetResourceShareAssociations_603112(
    name: "getResourceShareAssociations", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/getresourceshareassociations",
    validator: validate_GetResourceShareAssociations_603113, base: "/",
    url: url_GetResourceShareAssociations_603114,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceShareInvitations_603129 = ref object of OpenApiRestCall_602433
proc url_GetResourceShareInvitations_603131(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResourceShareInvitations_603130(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the invitations for resource sharing that you've received.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603132 = query.getOrDefault("maxResults")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "maxResults", valid_603132
  var valid_603133 = query.getOrDefault("nextToken")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "nextToken", valid_603133
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603134 = header.getOrDefault("X-Amz-Date")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-Date", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-Security-Token")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Security-Token", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Content-Sha256", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Algorithm")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Algorithm", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Signature")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Signature", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-SignedHeaders", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Credential")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Credential", valid_603140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603142: Call_GetResourceShareInvitations_603129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the invitations for resource sharing that you've received.
  ## 
  let valid = call_603142.validator(path, query, header, formData, body)
  let scheme = call_603142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603142.url(scheme.get, call_603142.host, call_603142.base,
                         call_603142.route, valid.getOrDefault("path"))
  result = hook(call_603142, url, valid)

proc call*(call_603143: Call_GetResourceShareInvitations_603129; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getResourceShareInvitations
  ## Gets the invitations for resource sharing that you've received.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603144 = newJObject()
  var body_603145 = newJObject()
  add(query_603144, "maxResults", newJString(maxResults))
  add(query_603144, "nextToken", newJString(nextToken))
  if body != nil:
    body_603145 = body
  result = call_603143.call(nil, query_603144, nil, nil, body_603145)

var getResourceShareInvitations* = Call_GetResourceShareInvitations_603129(
    name: "getResourceShareInvitations", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/getresourceshareinvitations",
    validator: validate_GetResourceShareInvitations_603130, base: "/",
    url: url_GetResourceShareInvitations_603131,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceShares_603146 = ref object of OpenApiRestCall_602433
proc url_GetResourceShares_603148(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResourceShares_603147(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Gets the resource shares that you own or the resource shares that are shared with you.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603149 = query.getOrDefault("maxResults")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "maxResults", valid_603149
  var valid_603150 = query.getOrDefault("nextToken")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "nextToken", valid_603150
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603151 = header.getOrDefault("X-Amz-Date")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Date", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Security-Token")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Security-Token", valid_603152
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

proc call*(call_603159: Call_GetResourceShares_603146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the resource shares that you own or the resource shares that are shared with you.
  ## 
  let valid = call_603159.validator(path, query, header, formData, body)
  let scheme = call_603159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603159.url(scheme.get, call_603159.host, call_603159.base,
                         call_603159.route, valid.getOrDefault("path"))
  result = hook(call_603159, url, valid)

proc call*(call_603160: Call_GetResourceShares_603146; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getResourceShares
  ## Gets the resource shares that you own or the resource shares that are shared with you.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603161 = newJObject()
  var body_603162 = newJObject()
  add(query_603161, "maxResults", newJString(maxResults))
  add(query_603161, "nextToken", newJString(nextToken))
  if body != nil:
    body_603162 = body
  result = call_603160.call(nil, query_603161, nil, nil, body_603162)

var getResourceShares* = Call_GetResourceShares_603146(name: "getResourceShares",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com",
    route: "/getresourceshares", validator: validate_GetResourceShares_603147,
    base: "/", url: url_GetResourceShares_603148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPendingInvitationResources_603163 = ref object of OpenApiRestCall_602433
proc url_ListPendingInvitationResources_603165(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPendingInvitationResources_603164(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the resources in a resource share that is shared with you but that the invitation is still pending for.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603166 = query.getOrDefault("maxResults")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "maxResults", valid_603166
  var valid_603167 = query.getOrDefault("nextToken")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "nextToken", valid_603167
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603168 = header.getOrDefault("X-Amz-Date")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Date", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Security-Token")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Security-Token", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Content-Sha256", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-Algorithm")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-Algorithm", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Signature")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Signature", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-SignedHeaders", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-Credential")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-Credential", valid_603174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603176: Call_ListPendingInvitationResources_603163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resources in a resource share that is shared with you but that the invitation is still pending for.
  ## 
  let valid = call_603176.validator(path, query, header, formData, body)
  let scheme = call_603176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603176.url(scheme.get, call_603176.host, call_603176.base,
                         call_603176.route, valid.getOrDefault("path"))
  result = hook(call_603176, url, valid)

proc call*(call_603177: Call_ListPendingInvitationResources_603163; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listPendingInvitationResources
  ## Lists the resources in a resource share that is shared with you but that the invitation is still pending for.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603178 = newJObject()
  var body_603179 = newJObject()
  add(query_603178, "maxResults", newJString(maxResults))
  add(query_603178, "nextToken", newJString(nextToken))
  if body != nil:
    body_603179 = body
  result = call_603177.call(nil, query_603178, nil, nil, body_603179)

var listPendingInvitationResources* = Call_ListPendingInvitationResources_603163(
    name: "listPendingInvitationResources", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/listpendinginvitationresources",
    validator: validate_ListPendingInvitationResources_603164, base: "/",
    url: url_ListPendingInvitationResources_603165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPrincipals_603180 = ref object of OpenApiRestCall_602433
proc url_ListPrincipals_603182(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPrincipals_603181(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists the principals that you have shared resources with or the principals that have shared resources with you.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603183 = query.getOrDefault("maxResults")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "maxResults", valid_603183
  var valid_603184 = query.getOrDefault("nextToken")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "nextToken", valid_603184
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603185 = header.getOrDefault("X-Amz-Date")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Date", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-Security-Token")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-Security-Token", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Content-Sha256", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Algorithm")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Algorithm", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-Signature")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Signature", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-SignedHeaders", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-Credential")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-Credential", valid_603191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603193: Call_ListPrincipals_603180; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the principals that you have shared resources with or the principals that have shared resources with you.
  ## 
  let valid = call_603193.validator(path, query, header, formData, body)
  let scheme = call_603193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603193.url(scheme.get, call_603193.host, call_603193.base,
                         call_603193.route, valid.getOrDefault("path"))
  result = hook(call_603193, url, valid)

proc call*(call_603194: Call_ListPrincipals_603180; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listPrincipals
  ## Lists the principals that you have shared resources with or the principals that have shared resources with you.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603195 = newJObject()
  var body_603196 = newJObject()
  add(query_603195, "maxResults", newJString(maxResults))
  add(query_603195, "nextToken", newJString(nextToken))
  if body != nil:
    body_603196 = body
  result = call_603194.call(nil, query_603195, nil, nil, body_603196)

var listPrincipals* = Call_ListPrincipals_603180(name: "listPrincipals",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com", route: "/listprincipals",
    validator: validate_ListPrincipals_603181, base: "/", url: url_ListPrincipals_603182,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResources_603197 = ref object of OpenApiRestCall_602433
proc url_ListResources_603199(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListResources_603198(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the resources that you added to a resource shares or the resources that are shared with you.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603200 = query.getOrDefault("maxResults")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "maxResults", valid_603200
  var valid_603201 = query.getOrDefault("nextToken")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "nextToken", valid_603201
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603202 = header.getOrDefault("X-Amz-Date")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Date", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Security-Token")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Security-Token", valid_603203
  var valid_603204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-Content-Sha256", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-Algorithm")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Algorithm", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-Signature")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Signature", valid_603206
  var valid_603207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-SignedHeaders", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-Credential")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Credential", valid_603208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603210: Call_ListResources_603197; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resources that you added to a resource shares or the resources that are shared with you.
  ## 
  let valid = call_603210.validator(path, query, header, formData, body)
  let scheme = call_603210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603210.url(scheme.get, call_603210.host, call_603210.base,
                         call_603210.route, valid.getOrDefault("path"))
  result = hook(call_603210, url, valid)

proc call*(call_603211: Call_ListResources_603197; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listResources
  ## Lists the resources that you added to a resource shares or the resources that are shared with you.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603212 = newJObject()
  var body_603213 = newJObject()
  add(query_603212, "maxResults", newJString(maxResults))
  add(query_603212, "nextToken", newJString(nextToken))
  if body != nil:
    body_603213 = body
  result = call_603211.call(nil, query_603212, nil, nil, body_603213)

var listResources* = Call_ListResources_603197(name: "listResources",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com", route: "/listresources",
    validator: validate_ListResources_603198, base: "/", url: url_ListResources_603199,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectResourceShareInvitation_603214 = ref object of OpenApiRestCall_602433
proc url_RejectResourceShareInvitation_603216(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RejectResourceShareInvitation_603215(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Rejects an invitation to a resource share from another AWS account.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603217 = header.getOrDefault("X-Amz-Date")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Date", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Security-Token")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Security-Token", valid_603218
  var valid_603219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-Content-Sha256", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-Algorithm")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Algorithm", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-Signature")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Signature", valid_603221
  var valid_603222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-SignedHeaders", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Credential")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Credential", valid_603223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603225: Call_RejectResourceShareInvitation_603214; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Rejects an invitation to a resource share from another AWS account.
  ## 
  let valid = call_603225.validator(path, query, header, formData, body)
  let scheme = call_603225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603225.url(scheme.get, call_603225.host, call_603225.base,
                         call_603225.route, valid.getOrDefault("path"))
  result = hook(call_603225, url, valid)

proc call*(call_603226: Call_RejectResourceShareInvitation_603214; body: JsonNode): Recallable =
  ## rejectResourceShareInvitation
  ## Rejects an invitation to a resource share from another AWS account.
  ##   body: JObject (required)
  var body_603227 = newJObject()
  if body != nil:
    body_603227 = body
  result = call_603226.call(nil, nil, nil, nil, body_603227)

var rejectResourceShareInvitation* = Call_RejectResourceShareInvitation_603214(
    name: "rejectResourceShareInvitation", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/rejectresourceshareinvitation",
    validator: validate_RejectResourceShareInvitation_603215, base: "/",
    url: url_RejectResourceShareInvitation_603216,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603228 = ref object of OpenApiRestCall_602433
proc url_TagResource_603230(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_603229(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds the specified tags to the specified resource share that you own.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603231 = header.getOrDefault("X-Amz-Date")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-Date", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Security-Token")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Security-Token", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-Content-Sha256", valid_603233
  var valid_603234 = header.getOrDefault("X-Amz-Algorithm")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-Algorithm", valid_603234
  var valid_603235 = header.getOrDefault("X-Amz-Signature")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-Signature", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-SignedHeaders", valid_603236
  var valid_603237 = header.getOrDefault("X-Amz-Credential")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Credential", valid_603237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603239: Call_TagResource_603228; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds the specified tags to the specified resource share that you own.
  ## 
  let valid = call_603239.validator(path, query, header, formData, body)
  let scheme = call_603239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603239.url(scheme.get, call_603239.host, call_603239.base,
                         call_603239.route, valid.getOrDefault("path"))
  result = hook(call_603239, url, valid)

proc call*(call_603240: Call_TagResource_603228; body: JsonNode): Recallable =
  ## tagResource
  ## Adds the specified tags to the specified resource share that you own.
  ##   body: JObject (required)
  var body_603241 = newJObject()
  if body != nil:
    body_603241 = body
  result = call_603240.call(nil, nil, nil, nil, body_603241)

var tagResource* = Call_TagResource_603228(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "ram.amazonaws.com",
                                        route: "/tagresource",
                                        validator: validate_TagResource_603229,
                                        base: "/", url: url_TagResource_603230,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603242 = ref object of OpenApiRestCall_602433
proc url_UntagResource_603244(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_603243(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the specified tags from the specified resource share that you own.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603245 = header.getOrDefault("X-Amz-Date")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Date", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-Security-Token")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-Security-Token", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Content-Sha256", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-Algorithm")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-Algorithm", valid_603248
  var valid_603249 = header.getOrDefault("X-Amz-Signature")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-Signature", valid_603249
  var valid_603250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "X-Amz-SignedHeaders", valid_603250
  var valid_603251 = header.getOrDefault("X-Amz-Credential")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "X-Amz-Credential", valid_603251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603253: Call_UntagResource_603242; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tags from the specified resource share that you own.
  ## 
  let valid = call_603253.validator(path, query, header, formData, body)
  let scheme = call_603253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603253.url(scheme.get, call_603253.host, call_603253.base,
                         call_603253.route, valid.getOrDefault("path"))
  result = hook(call_603253, url, valid)

proc call*(call_603254: Call_UntagResource_603242; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tags from the specified resource share that you own.
  ##   body: JObject (required)
  var body_603255 = newJObject()
  if body != nil:
    body_603255 = body
  result = call_603254.call(nil, nil, nil, nil, body_603255)

var untagResource* = Call_UntagResource_603242(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com", route: "/untagresource",
    validator: validate_UntagResource_603243, base: "/", url: url_UntagResource_603244,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceShare_603256 = ref object of OpenApiRestCall_602433
proc url_UpdateResourceShare_603258(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateResourceShare_603257(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Updates the specified resource share that you own.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603259 = header.getOrDefault("X-Amz-Date")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Date", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Security-Token")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Security-Token", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Content-Sha256", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Algorithm")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Algorithm", valid_603262
  var valid_603263 = header.getOrDefault("X-Amz-Signature")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-Signature", valid_603263
  var valid_603264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-SignedHeaders", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-Credential")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Credential", valid_603265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603267: Call_UpdateResourceShare_603256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified resource share that you own.
  ## 
  let valid = call_603267.validator(path, query, header, formData, body)
  let scheme = call_603267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603267.url(scheme.get, call_603267.host, call_603267.base,
                         call_603267.route, valid.getOrDefault("path"))
  result = hook(call_603267, url, valid)

proc call*(call_603268: Call_UpdateResourceShare_603256; body: JsonNode): Recallable =
  ## updateResourceShare
  ## Updates the specified resource share that you own.
  ##   body: JObject (required)
  var body_603269 = newJObject()
  if body != nil:
    body_603269 = body
  result = call_603268.call(nil, nil, nil, nil, body_603269)

var updateResourceShare* = Call_UpdateResourceShare_603256(
    name: "updateResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/updateresourceshare",
    validator: validate_UpdateResourceShare_603257, base: "/",
    url: url_UpdateResourceShare_603258, schemes: {Scheme.Https, Scheme.Http})
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

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
