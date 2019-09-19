
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
## <p>Use AWS Resource Access Manager to share AWS resources between AWS accounts. To share a resource, you create a resource share, associate the resource with the resource share, and specify the principals that can access the resource. The following principals are supported:</p> <ul> <li> <p>The ID of an AWS account</p> </li> <li> <p>The Amazon Resource Name (ARN) of an OU from AWS Organizations</p> </li> <li> <p>The Amazon Resource Name (ARN) of an organization from AWS Organizations</p> </li> </ul> <p>If you specify an AWS account that doesn't exist in the same organization as the account that owns the resource share, the owner of the specified account receives an invitation to accept the resource share. After the owner accepts the invitation, they can access the resources in the resource share. An administrator of the specified account can use IAM policies to restrict access resources in the resource share.</p>
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
  Call_AcceptResourceShareInvitation_772933 = ref object of OpenApiRestCall_772597
proc url_AcceptResourceShareInvitation_772935(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AcceptResourceShareInvitation_772934(path: JsonNode; query: JsonNode;
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
  var valid_773047 = header.getOrDefault("X-Amz-Date")
  valid_773047 = validateParameter(valid_773047, JString, required = false,
                                 default = nil)
  if valid_773047 != nil:
    section.add "X-Amz-Date", valid_773047
  var valid_773048 = header.getOrDefault("X-Amz-Security-Token")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "X-Amz-Security-Token", valid_773048
  var valid_773049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773049 = validateParameter(valid_773049, JString, required = false,
                                 default = nil)
  if valid_773049 != nil:
    section.add "X-Amz-Content-Sha256", valid_773049
  var valid_773050 = header.getOrDefault("X-Amz-Algorithm")
  valid_773050 = validateParameter(valid_773050, JString, required = false,
                                 default = nil)
  if valid_773050 != nil:
    section.add "X-Amz-Algorithm", valid_773050
  var valid_773051 = header.getOrDefault("X-Amz-Signature")
  valid_773051 = validateParameter(valid_773051, JString, required = false,
                                 default = nil)
  if valid_773051 != nil:
    section.add "X-Amz-Signature", valid_773051
  var valid_773052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773052 = validateParameter(valid_773052, JString, required = false,
                                 default = nil)
  if valid_773052 != nil:
    section.add "X-Amz-SignedHeaders", valid_773052
  var valid_773053 = header.getOrDefault("X-Amz-Credential")
  valid_773053 = validateParameter(valid_773053, JString, required = false,
                                 default = nil)
  if valid_773053 != nil:
    section.add "X-Amz-Credential", valid_773053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773077: Call_AcceptResourceShareInvitation_772933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts an invitation to a resource share from another AWS account.
  ## 
  let valid = call_773077.validator(path, query, header, formData, body)
  let scheme = call_773077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773077.url(scheme.get, call_773077.host, call_773077.base,
                         call_773077.route, valid.getOrDefault("path"))
  result = hook(call_773077, url, valid)

proc call*(call_773148: Call_AcceptResourceShareInvitation_772933; body: JsonNode): Recallable =
  ## acceptResourceShareInvitation
  ## Accepts an invitation to a resource share from another AWS account.
  ##   body: JObject (required)
  var body_773149 = newJObject()
  if body != nil:
    body_773149 = body
  result = call_773148.call(nil, nil, nil, nil, body_773149)

var acceptResourceShareInvitation* = Call_AcceptResourceShareInvitation_772933(
    name: "acceptResourceShareInvitation", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/acceptresourceshareinvitation",
    validator: validate_AcceptResourceShareInvitation_772934, base: "/",
    url: url_AcceptResourceShareInvitation_772935,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateResourceShare_773188 = ref object of OpenApiRestCall_772597
proc url_AssociateResourceShare_773190(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AssociateResourceShare_773189(path: JsonNode; query: JsonNode;
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
  var valid_773191 = header.getOrDefault("X-Amz-Date")
  valid_773191 = validateParameter(valid_773191, JString, required = false,
                                 default = nil)
  if valid_773191 != nil:
    section.add "X-Amz-Date", valid_773191
  var valid_773192 = header.getOrDefault("X-Amz-Security-Token")
  valid_773192 = validateParameter(valid_773192, JString, required = false,
                                 default = nil)
  if valid_773192 != nil:
    section.add "X-Amz-Security-Token", valid_773192
  var valid_773193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773193 = validateParameter(valid_773193, JString, required = false,
                                 default = nil)
  if valid_773193 != nil:
    section.add "X-Amz-Content-Sha256", valid_773193
  var valid_773194 = header.getOrDefault("X-Amz-Algorithm")
  valid_773194 = validateParameter(valid_773194, JString, required = false,
                                 default = nil)
  if valid_773194 != nil:
    section.add "X-Amz-Algorithm", valid_773194
  var valid_773195 = header.getOrDefault("X-Amz-Signature")
  valid_773195 = validateParameter(valid_773195, JString, required = false,
                                 default = nil)
  if valid_773195 != nil:
    section.add "X-Amz-Signature", valid_773195
  var valid_773196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773196 = validateParameter(valid_773196, JString, required = false,
                                 default = nil)
  if valid_773196 != nil:
    section.add "X-Amz-SignedHeaders", valid_773196
  var valid_773197 = header.getOrDefault("X-Amz-Credential")
  valid_773197 = validateParameter(valid_773197, JString, required = false,
                                 default = nil)
  if valid_773197 != nil:
    section.add "X-Amz-Credential", valid_773197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773199: Call_AssociateResourceShare_773188; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified resource share with the specified principals and resources.
  ## 
  let valid = call_773199.validator(path, query, header, formData, body)
  let scheme = call_773199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773199.url(scheme.get, call_773199.host, call_773199.base,
                         call_773199.route, valid.getOrDefault("path"))
  result = hook(call_773199, url, valid)

proc call*(call_773200: Call_AssociateResourceShare_773188; body: JsonNode): Recallable =
  ## associateResourceShare
  ## Associates the specified resource share with the specified principals and resources.
  ##   body: JObject (required)
  var body_773201 = newJObject()
  if body != nil:
    body_773201 = body
  result = call_773200.call(nil, nil, nil, nil, body_773201)

var associateResourceShare* = Call_AssociateResourceShare_773188(
    name: "associateResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/associateresourceshare",
    validator: validate_AssociateResourceShare_773189, base: "/",
    url: url_AssociateResourceShare_773190, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceShare_773202 = ref object of OpenApiRestCall_772597
proc url_CreateResourceShare_773204(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateResourceShare_773203(path: JsonNode; query: JsonNode;
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
  var valid_773205 = header.getOrDefault("X-Amz-Date")
  valid_773205 = validateParameter(valid_773205, JString, required = false,
                                 default = nil)
  if valid_773205 != nil:
    section.add "X-Amz-Date", valid_773205
  var valid_773206 = header.getOrDefault("X-Amz-Security-Token")
  valid_773206 = validateParameter(valid_773206, JString, required = false,
                                 default = nil)
  if valid_773206 != nil:
    section.add "X-Amz-Security-Token", valid_773206
  var valid_773207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773207 = validateParameter(valid_773207, JString, required = false,
                                 default = nil)
  if valid_773207 != nil:
    section.add "X-Amz-Content-Sha256", valid_773207
  var valid_773208 = header.getOrDefault("X-Amz-Algorithm")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "X-Amz-Algorithm", valid_773208
  var valid_773209 = header.getOrDefault("X-Amz-Signature")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Signature", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-SignedHeaders", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-Credential")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-Credential", valid_773211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773213: Call_CreateResourceShare_773202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a resource share.
  ## 
  let valid = call_773213.validator(path, query, header, formData, body)
  let scheme = call_773213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773213.url(scheme.get, call_773213.host, call_773213.base,
                         call_773213.route, valid.getOrDefault("path"))
  result = hook(call_773213, url, valid)

proc call*(call_773214: Call_CreateResourceShare_773202; body: JsonNode): Recallable =
  ## createResourceShare
  ## Creates a resource share.
  ##   body: JObject (required)
  var body_773215 = newJObject()
  if body != nil:
    body_773215 = body
  result = call_773214.call(nil, nil, nil, nil, body_773215)

var createResourceShare* = Call_CreateResourceShare_773202(
    name: "createResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/createresourceshare",
    validator: validate_CreateResourceShare_773203, base: "/",
    url: url_CreateResourceShare_773204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceShare_773216 = ref object of OpenApiRestCall_772597
proc url_DeleteResourceShare_773218(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteResourceShare_773217(path: JsonNode; query: JsonNode;
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
  var valid_773219 = query.getOrDefault("resourceShareArn")
  valid_773219 = validateParameter(valid_773219, JString, required = true,
                                 default = nil)
  if valid_773219 != nil:
    section.add "resourceShareArn", valid_773219
  var valid_773220 = query.getOrDefault("clientToken")
  valid_773220 = validateParameter(valid_773220, JString, required = false,
                                 default = nil)
  if valid_773220 != nil:
    section.add "clientToken", valid_773220
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
  var valid_773221 = header.getOrDefault("X-Amz-Date")
  valid_773221 = validateParameter(valid_773221, JString, required = false,
                                 default = nil)
  if valid_773221 != nil:
    section.add "X-Amz-Date", valid_773221
  var valid_773222 = header.getOrDefault("X-Amz-Security-Token")
  valid_773222 = validateParameter(valid_773222, JString, required = false,
                                 default = nil)
  if valid_773222 != nil:
    section.add "X-Amz-Security-Token", valid_773222
  var valid_773223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Content-Sha256", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-Algorithm")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-Algorithm", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-Signature")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Signature", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-SignedHeaders", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-Credential")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Credential", valid_773227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773228: Call_DeleteResourceShare_773216; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified resource share.
  ## 
  let valid = call_773228.validator(path, query, header, formData, body)
  let scheme = call_773228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773228.url(scheme.get, call_773228.host, call_773228.base,
                         call_773228.route, valid.getOrDefault("path"))
  result = hook(call_773228, url, valid)

proc call*(call_773229: Call_DeleteResourceShare_773216; resourceShareArn: string;
          clientToken: string = ""): Recallable =
  ## deleteResourceShare
  ## Deletes the specified resource share.
  ##   resourceShareArn: string (required)
  ##                   : The Amazon Resource Name (ARN) of the resource share.
  ##   clientToken: string
  ##              : A unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  var query_773230 = newJObject()
  add(query_773230, "resourceShareArn", newJString(resourceShareArn))
  add(query_773230, "clientToken", newJString(clientToken))
  result = call_773229.call(nil, query_773230, nil, nil, nil)

var deleteResourceShare* = Call_DeleteResourceShare_773216(
    name: "deleteResourceShare", meth: HttpMethod.HttpDelete,
    host: "ram.amazonaws.com", route: "/deleteresourceshare#resourceShareArn",
    validator: validate_DeleteResourceShare_773217, base: "/",
    url: url_DeleteResourceShare_773218, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateResourceShare_773232 = ref object of OpenApiRestCall_772597
proc url_DisassociateResourceShare_773234(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociateResourceShare_773233(path: JsonNode; query: JsonNode;
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
  var valid_773235 = header.getOrDefault("X-Amz-Date")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-Date", valid_773235
  var valid_773236 = header.getOrDefault("X-Amz-Security-Token")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-Security-Token", valid_773236
  var valid_773237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773237 = validateParameter(valid_773237, JString, required = false,
                                 default = nil)
  if valid_773237 != nil:
    section.add "X-Amz-Content-Sha256", valid_773237
  var valid_773238 = header.getOrDefault("X-Amz-Algorithm")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "X-Amz-Algorithm", valid_773238
  var valid_773239 = header.getOrDefault("X-Amz-Signature")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "X-Amz-Signature", valid_773239
  var valid_773240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773240 = validateParameter(valid_773240, JString, required = false,
                                 default = nil)
  if valid_773240 != nil:
    section.add "X-Amz-SignedHeaders", valid_773240
  var valid_773241 = header.getOrDefault("X-Amz-Credential")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-Credential", valid_773241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773243: Call_DisassociateResourceShare_773232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified principals or resources from the specified resource share.
  ## 
  let valid = call_773243.validator(path, query, header, formData, body)
  let scheme = call_773243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773243.url(scheme.get, call_773243.host, call_773243.base,
                         call_773243.route, valid.getOrDefault("path"))
  result = hook(call_773243, url, valid)

proc call*(call_773244: Call_DisassociateResourceShare_773232; body: JsonNode): Recallable =
  ## disassociateResourceShare
  ## Disassociates the specified principals or resources from the specified resource share.
  ##   body: JObject (required)
  var body_773245 = newJObject()
  if body != nil:
    body_773245 = body
  result = call_773244.call(nil, nil, nil, nil, body_773245)

var disassociateResourceShare* = Call_DisassociateResourceShare_773232(
    name: "disassociateResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/disassociateresourceshare",
    validator: validate_DisassociateResourceShare_773233, base: "/",
    url: url_DisassociateResourceShare_773234,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableSharingWithAwsOrganization_773246 = ref object of OpenApiRestCall_772597
proc url_EnableSharingWithAwsOrganization_773248(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_EnableSharingWithAwsOrganization_773247(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Enables resource sharing within your organization.
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
  var valid_773249 = header.getOrDefault("X-Amz-Date")
  valid_773249 = validateParameter(valid_773249, JString, required = false,
                                 default = nil)
  if valid_773249 != nil:
    section.add "X-Amz-Date", valid_773249
  var valid_773250 = header.getOrDefault("X-Amz-Security-Token")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-Security-Token", valid_773250
  var valid_773251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-Content-Sha256", valid_773251
  var valid_773252 = header.getOrDefault("X-Amz-Algorithm")
  valid_773252 = validateParameter(valid_773252, JString, required = false,
                                 default = nil)
  if valid_773252 != nil:
    section.add "X-Amz-Algorithm", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-Signature")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Signature", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-SignedHeaders", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-Credential")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-Credential", valid_773255
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773256: Call_EnableSharingWithAwsOrganization_773246;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enables resource sharing within your organization.
  ## 
  let valid = call_773256.validator(path, query, header, formData, body)
  let scheme = call_773256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773256.url(scheme.get, call_773256.host, call_773256.base,
                         call_773256.route, valid.getOrDefault("path"))
  result = hook(call_773256, url, valid)

proc call*(call_773257: Call_EnableSharingWithAwsOrganization_773246): Recallable =
  ## enableSharingWithAwsOrganization
  ## Enables resource sharing within your organization.
  result = call_773257.call(nil, nil, nil, nil, nil)

var enableSharingWithAwsOrganization* = Call_EnableSharingWithAwsOrganization_773246(
    name: "enableSharingWithAwsOrganization", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/enablesharingwithawsorganization",
    validator: validate_EnableSharingWithAwsOrganization_773247, base: "/",
    url: url_EnableSharingWithAwsOrganization_773248,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourcePolicies_773258 = ref object of OpenApiRestCall_772597
proc url_GetResourcePolicies_773260(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResourcePolicies_773259(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets the policies for the specifies resources.
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
  var valid_773261 = query.getOrDefault("maxResults")
  valid_773261 = validateParameter(valid_773261, JString, required = false,
                                 default = nil)
  if valid_773261 != nil:
    section.add "maxResults", valid_773261
  var valid_773262 = query.getOrDefault("nextToken")
  valid_773262 = validateParameter(valid_773262, JString, required = false,
                                 default = nil)
  if valid_773262 != nil:
    section.add "nextToken", valid_773262
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
  var valid_773263 = header.getOrDefault("X-Amz-Date")
  valid_773263 = validateParameter(valid_773263, JString, required = false,
                                 default = nil)
  if valid_773263 != nil:
    section.add "X-Amz-Date", valid_773263
  var valid_773264 = header.getOrDefault("X-Amz-Security-Token")
  valid_773264 = validateParameter(valid_773264, JString, required = false,
                                 default = nil)
  if valid_773264 != nil:
    section.add "X-Amz-Security-Token", valid_773264
  var valid_773265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-Content-Sha256", valid_773265
  var valid_773266 = header.getOrDefault("X-Amz-Algorithm")
  valid_773266 = validateParameter(valid_773266, JString, required = false,
                                 default = nil)
  if valid_773266 != nil:
    section.add "X-Amz-Algorithm", valid_773266
  var valid_773267 = header.getOrDefault("X-Amz-Signature")
  valid_773267 = validateParameter(valid_773267, JString, required = false,
                                 default = nil)
  if valid_773267 != nil:
    section.add "X-Amz-Signature", valid_773267
  var valid_773268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-SignedHeaders", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Credential")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Credential", valid_773269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773271: Call_GetResourcePolicies_773258; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the policies for the specifies resources.
  ## 
  let valid = call_773271.validator(path, query, header, formData, body)
  let scheme = call_773271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773271.url(scheme.get, call_773271.host, call_773271.base,
                         call_773271.route, valid.getOrDefault("path"))
  result = hook(call_773271, url, valid)

proc call*(call_773272: Call_GetResourcePolicies_773258; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getResourcePolicies
  ## Gets the policies for the specifies resources.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773273 = newJObject()
  var body_773274 = newJObject()
  add(query_773273, "maxResults", newJString(maxResults))
  add(query_773273, "nextToken", newJString(nextToken))
  if body != nil:
    body_773274 = body
  result = call_773272.call(nil, query_773273, nil, nil, body_773274)

var getResourcePolicies* = Call_GetResourcePolicies_773258(
    name: "getResourcePolicies", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/getresourcepolicies",
    validator: validate_GetResourcePolicies_773259, base: "/",
    url: url_GetResourcePolicies_773260, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceShareAssociations_773275 = ref object of OpenApiRestCall_772597
proc url_GetResourceShareAssociations_773277(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResourceShareAssociations_773276(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the associations for the specified resource share.
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
  var valid_773278 = query.getOrDefault("maxResults")
  valid_773278 = validateParameter(valid_773278, JString, required = false,
                                 default = nil)
  if valid_773278 != nil:
    section.add "maxResults", valid_773278
  var valid_773279 = query.getOrDefault("nextToken")
  valid_773279 = validateParameter(valid_773279, JString, required = false,
                                 default = nil)
  if valid_773279 != nil:
    section.add "nextToken", valid_773279
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
  var valid_773280 = header.getOrDefault("X-Amz-Date")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "X-Amz-Date", valid_773280
  var valid_773281 = header.getOrDefault("X-Amz-Security-Token")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "X-Amz-Security-Token", valid_773281
  var valid_773282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773282 = validateParameter(valid_773282, JString, required = false,
                                 default = nil)
  if valid_773282 != nil:
    section.add "X-Amz-Content-Sha256", valid_773282
  var valid_773283 = header.getOrDefault("X-Amz-Algorithm")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "X-Amz-Algorithm", valid_773283
  var valid_773284 = header.getOrDefault("X-Amz-Signature")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "X-Amz-Signature", valid_773284
  var valid_773285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "X-Amz-SignedHeaders", valid_773285
  var valid_773286 = header.getOrDefault("X-Amz-Credential")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-Credential", valid_773286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773288: Call_GetResourceShareAssociations_773275; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the associations for the specified resource share.
  ## 
  let valid = call_773288.validator(path, query, header, formData, body)
  let scheme = call_773288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773288.url(scheme.get, call_773288.host, call_773288.base,
                         call_773288.route, valid.getOrDefault("path"))
  result = hook(call_773288, url, valid)

proc call*(call_773289: Call_GetResourceShareAssociations_773275; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getResourceShareAssociations
  ## Gets the associations for the specified resource share.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773290 = newJObject()
  var body_773291 = newJObject()
  add(query_773290, "maxResults", newJString(maxResults))
  add(query_773290, "nextToken", newJString(nextToken))
  if body != nil:
    body_773291 = body
  result = call_773289.call(nil, query_773290, nil, nil, body_773291)

var getResourceShareAssociations* = Call_GetResourceShareAssociations_773275(
    name: "getResourceShareAssociations", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/getresourceshareassociations",
    validator: validate_GetResourceShareAssociations_773276, base: "/",
    url: url_GetResourceShareAssociations_773277,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceShareInvitations_773292 = ref object of OpenApiRestCall_772597
proc url_GetResourceShareInvitations_773294(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResourceShareInvitations_773293(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the specified invitations for resource sharing.
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
  var valid_773295 = query.getOrDefault("maxResults")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "maxResults", valid_773295
  var valid_773296 = query.getOrDefault("nextToken")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "nextToken", valid_773296
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
  var valid_773297 = header.getOrDefault("X-Amz-Date")
  valid_773297 = validateParameter(valid_773297, JString, required = false,
                                 default = nil)
  if valid_773297 != nil:
    section.add "X-Amz-Date", valid_773297
  var valid_773298 = header.getOrDefault("X-Amz-Security-Token")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "X-Amz-Security-Token", valid_773298
  var valid_773299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773299 = validateParameter(valid_773299, JString, required = false,
                                 default = nil)
  if valid_773299 != nil:
    section.add "X-Amz-Content-Sha256", valid_773299
  var valid_773300 = header.getOrDefault("X-Amz-Algorithm")
  valid_773300 = validateParameter(valid_773300, JString, required = false,
                                 default = nil)
  if valid_773300 != nil:
    section.add "X-Amz-Algorithm", valid_773300
  var valid_773301 = header.getOrDefault("X-Amz-Signature")
  valid_773301 = validateParameter(valid_773301, JString, required = false,
                                 default = nil)
  if valid_773301 != nil:
    section.add "X-Amz-Signature", valid_773301
  var valid_773302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "X-Amz-SignedHeaders", valid_773302
  var valid_773303 = header.getOrDefault("X-Amz-Credential")
  valid_773303 = validateParameter(valid_773303, JString, required = false,
                                 default = nil)
  if valid_773303 != nil:
    section.add "X-Amz-Credential", valid_773303
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773305: Call_GetResourceShareInvitations_773292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the specified invitations for resource sharing.
  ## 
  let valid = call_773305.validator(path, query, header, formData, body)
  let scheme = call_773305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773305.url(scheme.get, call_773305.host, call_773305.base,
                         call_773305.route, valid.getOrDefault("path"))
  result = hook(call_773305, url, valid)

proc call*(call_773306: Call_GetResourceShareInvitations_773292; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getResourceShareInvitations
  ## Gets the specified invitations for resource sharing.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773307 = newJObject()
  var body_773308 = newJObject()
  add(query_773307, "maxResults", newJString(maxResults))
  add(query_773307, "nextToken", newJString(nextToken))
  if body != nil:
    body_773308 = body
  result = call_773306.call(nil, query_773307, nil, nil, body_773308)

var getResourceShareInvitations* = Call_GetResourceShareInvitations_773292(
    name: "getResourceShareInvitations", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/getresourceshareinvitations",
    validator: validate_GetResourceShareInvitations_773293, base: "/",
    url: url_GetResourceShareInvitations_773294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceShares_773309 = ref object of OpenApiRestCall_772597
proc url_GetResourceShares_773311(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResourceShares_773310(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Gets the specified resource shares or all of your resource shares.
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
  var valid_773312 = query.getOrDefault("maxResults")
  valid_773312 = validateParameter(valid_773312, JString, required = false,
                                 default = nil)
  if valid_773312 != nil:
    section.add "maxResults", valid_773312
  var valid_773313 = query.getOrDefault("nextToken")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "nextToken", valid_773313
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
  var valid_773314 = header.getOrDefault("X-Amz-Date")
  valid_773314 = validateParameter(valid_773314, JString, required = false,
                                 default = nil)
  if valid_773314 != nil:
    section.add "X-Amz-Date", valid_773314
  var valid_773315 = header.getOrDefault("X-Amz-Security-Token")
  valid_773315 = validateParameter(valid_773315, JString, required = false,
                                 default = nil)
  if valid_773315 != nil:
    section.add "X-Amz-Security-Token", valid_773315
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

proc call*(call_773322: Call_GetResourceShares_773309; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the specified resource shares or all of your resource shares.
  ## 
  let valid = call_773322.validator(path, query, header, formData, body)
  let scheme = call_773322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773322.url(scheme.get, call_773322.host, call_773322.base,
                         call_773322.route, valid.getOrDefault("path"))
  result = hook(call_773322, url, valid)

proc call*(call_773323: Call_GetResourceShares_773309; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getResourceShares
  ## Gets the specified resource shares or all of your resource shares.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773324 = newJObject()
  var body_773325 = newJObject()
  add(query_773324, "maxResults", newJString(maxResults))
  add(query_773324, "nextToken", newJString(nextToken))
  if body != nil:
    body_773325 = body
  result = call_773323.call(nil, query_773324, nil, nil, body_773325)

var getResourceShares* = Call_GetResourceShares_773309(name: "getResourceShares",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com",
    route: "/getresourceshares", validator: validate_GetResourceShares_773310,
    base: "/", url: url_GetResourceShares_773311,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPrincipals_773326 = ref object of OpenApiRestCall_772597
proc url_ListPrincipals_773328(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPrincipals_773327(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists the principals with access to the specified resource.
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
  var valid_773329 = query.getOrDefault("maxResults")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "maxResults", valid_773329
  var valid_773330 = query.getOrDefault("nextToken")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "nextToken", valid_773330
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
  var valid_773331 = header.getOrDefault("X-Amz-Date")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "X-Amz-Date", valid_773331
  var valid_773332 = header.getOrDefault("X-Amz-Security-Token")
  valid_773332 = validateParameter(valid_773332, JString, required = false,
                                 default = nil)
  if valid_773332 != nil:
    section.add "X-Amz-Security-Token", valid_773332
  var valid_773333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773333 = validateParameter(valid_773333, JString, required = false,
                                 default = nil)
  if valid_773333 != nil:
    section.add "X-Amz-Content-Sha256", valid_773333
  var valid_773334 = header.getOrDefault("X-Amz-Algorithm")
  valid_773334 = validateParameter(valid_773334, JString, required = false,
                                 default = nil)
  if valid_773334 != nil:
    section.add "X-Amz-Algorithm", valid_773334
  var valid_773335 = header.getOrDefault("X-Amz-Signature")
  valid_773335 = validateParameter(valid_773335, JString, required = false,
                                 default = nil)
  if valid_773335 != nil:
    section.add "X-Amz-Signature", valid_773335
  var valid_773336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773336 = validateParameter(valid_773336, JString, required = false,
                                 default = nil)
  if valid_773336 != nil:
    section.add "X-Amz-SignedHeaders", valid_773336
  var valid_773337 = header.getOrDefault("X-Amz-Credential")
  valid_773337 = validateParameter(valid_773337, JString, required = false,
                                 default = nil)
  if valid_773337 != nil:
    section.add "X-Amz-Credential", valid_773337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773339: Call_ListPrincipals_773326; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the principals with access to the specified resource.
  ## 
  let valid = call_773339.validator(path, query, header, formData, body)
  let scheme = call_773339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773339.url(scheme.get, call_773339.host, call_773339.base,
                         call_773339.route, valid.getOrDefault("path"))
  result = hook(call_773339, url, valid)

proc call*(call_773340: Call_ListPrincipals_773326; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listPrincipals
  ## Lists the principals with access to the specified resource.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773341 = newJObject()
  var body_773342 = newJObject()
  add(query_773341, "maxResults", newJString(maxResults))
  add(query_773341, "nextToken", newJString(nextToken))
  if body != nil:
    body_773342 = body
  result = call_773340.call(nil, query_773341, nil, nil, body_773342)

var listPrincipals* = Call_ListPrincipals_773326(name: "listPrincipals",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com", route: "/listprincipals",
    validator: validate_ListPrincipals_773327, base: "/", url: url_ListPrincipals_773328,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResources_773343 = ref object of OpenApiRestCall_772597
proc url_ListResources_773345(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListResources_773344(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the resources that the specified principal can access.
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
  var valid_773346 = query.getOrDefault("maxResults")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "maxResults", valid_773346
  var valid_773347 = query.getOrDefault("nextToken")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "nextToken", valid_773347
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
  var valid_773348 = header.getOrDefault("X-Amz-Date")
  valid_773348 = validateParameter(valid_773348, JString, required = false,
                                 default = nil)
  if valid_773348 != nil:
    section.add "X-Amz-Date", valid_773348
  var valid_773349 = header.getOrDefault("X-Amz-Security-Token")
  valid_773349 = validateParameter(valid_773349, JString, required = false,
                                 default = nil)
  if valid_773349 != nil:
    section.add "X-Amz-Security-Token", valid_773349
  var valid_773350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773350 = validateParameter(valid_773350, JString, required = false,
                                 default = nil)
  if valid_773350 != nil:
    section.add "X-Amz-Content-Sha256", valid_773350
  var valid_773351 = header.getOrDefault("X-Amz-Algorithm")
  valid_773351 = validateParameter(valid_773351, JString, required = false,
                                 default = nil)
  if valid_773351 != nil:
    section.add "X-Amz-Algorithm", valid_773351
  var valid_773352 = header.getOrDefault("X-Amz-Signature")
  valid_773352 = validateParameter(valid_773352, JString, required = false,
                                 default = nil)
  if valid_773352 != nil:
    section.add "X-Amz-Signature", valid_773352
  var valid_773353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773353 = validateParameter(valid_773353, JString, required = false,
                                 default = nil)
  if valid_773353 != nil:
    section.add "X-Amz-SignedHeaders", valid_773353
  var valid_773354 = header.getOrDefault("X-Amz-Credential")
  valid_773354 = validateParameter(valid_773354, JString, required = false,
                                 default = nil)
  if valid_773354 != nil:
    section.add "X-Amz-Credential", valid_773354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773356: Call_ListResources_773343; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resources that the specified principal can access.
  ## 
  let valid = call_773356.validator(path, query, header, formData, body)
  let scheme = call_773356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773356.url(scheme.get, call_773356.host, call_773356.base,
                         call_773356.route, valid.getOrDefault("path"))
  result = hook(call_773356, url, valid)

proc call*(call_773357: Call_ListResources_773343; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listResources
  ## Lists the resources that the specified principal can access.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773358 = newJObject()
  var body_773359 = newJObject()
  add(query_773358, "maxResults", newJString(maxResults))
  add(query_773358, "nextToken", newJString(nextToken))
  if body != nil:
    body_773359 = body
  result = call_773357.call(nil, query_773358, nil, nil, body_773359)

var listResources* = Call_ListResources_773343(name: "listResources",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com", route: "/listresources",
    validator: validate_ListResources_773344, base: "/", url: url_ListResources_773345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectResourceShareInvitation_773360 = ref object of OpenApiRestCall_772597
proc url_RejectResourceShareInvitation_773362(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RejectResourceShareInvitation_773361(path: JsonNode; query: JsonNode;
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
  var valid_773363 = header.getOrDefault("X-Amz-Date")
  valid_773363 = validateParameter(valid_773363, JString, required = false,
                                 default = nil)
  if valid_773363 != nil:
    section.add "X-Amz-Date", valid_773363
  var valid_773364 = header.getOrDefault("X-Amz-Security-Token")
  valid_773364 = validateParameter(valid_773364, JString, required = false,
                                 default = nil)
  if valid_773364 != nil:
    section.add "X-Amz-Security-Token", valid_773364
  var valid_773365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773365 = validateParameter(valid_773365, JString, required = false,
                                 default = nil)
  if valid_773365 != nil:
    section.add "X-Amz-Content-Sha256", valid_773365
  var valid_773366 = header.getOrDefault("X-Amz-Algorithm")
  valid_773366 = validateParameter(valid_773366, JString, required = false,
                                 default = nil)
  if valid_773366 != nil:
    section.add "X-Amz-Algorithm", valid_773366
  var valid_773367 = header.getOrDefault("X-Amz-Signature")
  valid_773367 = validateParameter(valid_773367, JString, required = false,
                                 default = nil)
  if valid_773367 != nil:
    section.add "X-Amz-Signature", valid_773367
  var valid_773368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773368 = validateParameter(valid_773368, JString, required = false,
                                 default = nil)
  if valid_773368 != nil:
    section.add "X-Amz-SignedHeaders", valid_773368
  var valid_773369 = header.getOrDefault("X-Amz-Credential")
  valid_773369 = validateParameter(valid_773369, JString, required = false,
                                 default = nil)
  if valid_773369 != nil:
    section.add "X-Amz-Credential", valid_773369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773371: Call_RejectResourceShareInvitation_773360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Rejects an invitation to a resource share from another AWS account.
  ## 
  let valid = call_773371.validator(path, query, header, formData, body)
  let scheme = call_773371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773371.url(scheme.get, call_773371.host, call_773371.base,
                         call_773371.route, valid.getOrDefault("path"))
  result = hook(call_773371, url, valid)

proc call*(call_773372: Call_RejectResourceShareInvitation_773360; body: JsonNode): Recallable =
  ## rejectResourceShareInvitation
  ## Rejects an invitation to a resource share from another AWS account.
  ##   body: JObject (required)
  var body_773373 = newJObject()
  if body != nil:
    body_773373 = body
  result = call_773372.call(nil, nil, nil, nil, body_773373)

var rejectResourceShareInvitation* = Call_RejectResourceShareInvitation_773360(
    name: "rejectResourceShareInvitation", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/rejectresourceshareinvitation",
    validator: validate_RejectResourceShareInvitation_773361, base: "/",
    url: url_RejectResourceShareInvitation_773362,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_773374 = ref object of OpenApiRestCall_772597
proc url_TagResource_773376(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_773375(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds the specified tags to the specified resource share.
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
  var valid_773377 = header.getOrDefault("X-Amz-Date")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "X-Amz-Date", valid_773377
  var valid_773378 = header.getOrDefault("X-Amz-Security-Token")
  valid_773378 = validateParameter(valid_773378, JString, required = false,
                                 default = nil)
  if valid_773378 != nil:
    section.add "X-Amz-Security-Token", valid_773378
  var valid_773379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773379 = validateParameter(valid_773379, JString, required = false,
                                 default = nil)
  if valid_773379 != nil:
    section.add "X-Amz-Content-Sha256", valid_773379
  var valid_773380 = header.getOrDefault("X-Amz-Algorithm")
  valid_773380 = validateParameter(valid_773380, JString, required = false,
                                 default = nil)
  if valid_773380 != nil:
    section.add "X-Amz-Algorithm", valid_773380
  var valid_773381 = header.getOrDefault("X-Amz-Signature")
  valid_773381 = validateParameter(valid_773381, JString, required = false,
                                 default = nil)
  if valid_773381 != nil:
    section.add "X-Amz-Signature", valid_773381
  var valid_773382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773382 = validateParameter(valid_773382, JString, required = false,
                                 default = nil)
  if valid_773382 != nil:
    section.add "X-Amz-SignedHeaders", valid_773382
  var valid_773383 = header.getOrDefault("X-Amz-Credential")
  valid_773383 = validateParameter(valid_773383, JString, required = false,
                                 default = nil)
  if valid_773383 != nil:
    section.add "X-Amz-Credential", valid_773383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773385: Call_TagResource_773374; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds the specified tags to the specified resource share.
  ## 
  let valid = call_773385.validator(path, query, header, formData, body)
  let scheme = call_773385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773385.url(scheme.get, call_773385.host, call_773385.base,
                         call_773385.route, valid.getOrDefault("path"))
  result = hook(call_773385, url, valid)

proc call*(call_773386: Call_TagResource_773374; body: JsonNode): Recallable =
  ## tagResource
  ## Adds the specified tags to the specified resource share.
  ##   body: JObject (required)
  var body_773387 = newJObject()
  if body != nil:
    body_773387 = body
  result = call_773386.call(nil, nil, nil, nil, body_773387)

var tagResource* = Call_TagResource_773374(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "ram.amazonaws.com",
                                        route: "/tagresource",
                                        validator: validate_TagResource_773375,
                                        base: "/", url: url_TagResource_773376,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_773388 = ref object of OpenApiRestCall_772597
proc url_UntagResource_773390(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_773389(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the specified tags from the specified resource share.
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
  var valid_773391 = header.getOrDefault("X-Amz-Date")
  valid_773391 = validateParameter(valid_773391, JString, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "X-Amz-Date", valid_773391
  var valid_773392 = header.getOrDefault("X-Amz-Security-Token")
  valid_773392 = validateParameter(valid_773392, JString, required = false,
                                 default = nil)
  if valid_773392 != nil:
    section.add "X-Amz-Security-Token", valid_773392
  var valid_773393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773393 = validateParameter(valid_773393, JString, required = false,
                                 default = nil)
  if valid_773393 != nil:
    section.add "X-Amz-Content-Sha256", valid_773393
  var valid_773394 = header.getOrDefault("X-Amz-Algorithm")
  valid_773394 = validateParameter(valid_773394, JString, required = false,
                                 default = nil)
  if valid_773394 != nil:
    section.add "X-Amz-Algorithm", valid_773394
  var valid_773395 = header.getOrDefault("X-Amz-Signature")
  valid_773395 = validateParameter(valid_773395, JString, required = false,
                                 default = nil)
  if valid_773395 != nil:
    section.add "X-Amz-Signature", valid_773395
  var valid_773396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773396 = validateParameter(valid_773396, JString, required = false,
                                 default = nil)
  if valid_773396 != nil:
    section.add "X-Amz-SignedHeaders", valid_773396
  var valid_773397 = header.getOrDefault("X-Amz-Credential")
  valid_773397 = validateParameter(valid_773397, JString, required = false,
                                 default = nil)
  if valid_773397 != nil:
    section.add "X-Amz-Credential", valid_773397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773399: Call_UntagResource_773388; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tags from the specified resource share.
  ## 
  let valid = call_773399.validator(path, query, header, formData, body)
  let scheme = call_773399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773399.url(scheme.get, call_773399.host, call_773399.base,
                         call_773399.route, valid.getOrDefault("path"))
  result = hook(call_773399, url, valid)

proc call*(call_773400: Call_UntagResource_773388; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tags from the specified resource share.
  ##   body: JObject (required)
  var body_773401 = newJObject()
  if body != nil:
    body_773401 = body
  result = call_773400.call(nil, nil, nil, nil, body_773401)

var untagResource* = Call_UntagResource_773388(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com", route: "/untagresource",
    validator: validate_UntagResource_773389, base: "/", url: url_UntagResource_773390,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceShare_773402 = ref object of OpenApiRestCall_772597
proc url_UpdateResourceShare_773404(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateResourceShare_773403(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Updates the specified resource share.
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
  var valid_773405 = header.getOrDefault("X-Amz-Date")
  valid_773405 = validateParameter(valid_773405, JString, required = false,
                                 default = nil)
  if valid_773405 != nil:
    section.add "X-Amz-Date", valid_773405
  var valid_773406 = header.getOrDefault("X-Amz-Security-Token")
  valid_773406 = validateParameter(valid_773406, JString, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "X-Amz-Security-Token", valid_773406
  var valid_773407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773407 = validateParameter(valid_773407, JString, required = false,
                                 default = nil)
  if valid_773407 != nil:
    section.add "X-Amz-Content-Sha256", valid_773407
  var valid_773408 = header.getOrDefault("X-Amz-Algorithm")
  valid_773408 = validateParameter(valid_773408, JString, required = false,
                                 default = nil)
  if valid_773408 != nil:
    section.add "X-Amz-Algorithm", valid_773408
  var valid_773409 = header.getOrDefault("X-Amz-Signature")
  valid_773409 = validateParameter(valid_773409, JString, required = false,
                                 default = nil)
  if valid_773409 != nil:
    section.add "X-Amz-Signature", valid_773409
  var valid_773410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773410 = validateParameter(valid_773410, JString, required = false,
                                 default = nil)
  if valid_773410 != nil:
    section.add "X-Amz-SignedHeaders", valid_773410
  var valid_773411 = header.getOrDefault("X-Amz-Credential")
  valid_773411 = validateParameter(valid_773411, JString, required = false,
                                 default = nil)
  if valid_773411 != nil:
    section.add "X-Amz-Credential", valid_773411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773413: Call_UpdateResourceShare_773402; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified resource share.
  ## 
  let valid = call_773413.validator(path, query, header, formData, body)
  let scheme = call_773413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773413.url(scheme.get, call_773413.host, call_773413.base,
                         call_773413.route, valid.getOrDefault("path"))
  result = hook(call_773413, url, valid)

proc call*(call_773414: Call_UpdateResourceShare_773402; body: JsonNode): Recallable =
  ## updateResourceShare
  ## Updates the specified resource share.
  ##   body: JObject (required)
  var body_773415 = newJObject()
  if body != nil:
    body_773415 = body
  result = call_773414.call(nil, nil, nil, nil, body_773415)

var updateResourceShare* = Call_UpdateResourceShare_773402(
    name: "updateResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/updateresourceshare",
    validator: validate_UpdateResourceShare_773403, base: "/",
    url: url_UpdateResourceShare_773404, schemes: {Scheme.Https, Scheme.Http})
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
