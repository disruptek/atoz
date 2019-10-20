
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AcceptResourceShareInvitation_592703 = ref object of OpenApiRestCall_592364
proc url_AcceptResourceShareInvitation_592705(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AcceptResourceShareInvitation_592704(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592817 = header.getOrDefault("X-Amz-Signature")
  valid_592817 = validateParameter(valid_592817, JString, required = false,
                                 default = nil)
  if valid_592817 != nil:
    section.add "X-Amz-Signature", valid_592817
  var valid_592818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592818 = validateParameter(valid_592818, JString, required = false,
                                 default = nil)
  if valid_592818 != nil:
    section.add "X-Amz-Content-Sha256", valid_592818
  var valid_592819 = header.getOrDefault("X-Amz-Date")
  valid_592819 = validateParameter(valid_592819, JString, required = false,
                                 default = nil)
  if valid_592819 != nil:
    section.add "X-Amz-Date", valid_592819
  var valid_592820 = header.getOrDefault("X-Amz-Credential")
  valid_592820 = validateParameter(valid_592820, JString, required = false,
                                 default = nil)
  if valid_592820 != nil:
    section.add "X-Amz-Credential", valid_592820
  var valid_592821 = header.getOrDefault("X-Amz-Security-Token")
  valid_592821 = validateParameter(valid_592821, JString, required = false,
                                 default = nil)
  if valid_592821 != nil:
    section.add "X-Amz-Security-Token", valid_592821
  var valid_592822 = header.getOrDefault("X-Amz-Algorithm")
  valid_592822 = validateParameter(valid_592822, JString, required = false,
                                 default = nil)
  if valid_592822 != nil:
    section.add "X-Amz-Algorithm", valid_592822
  var valid_592823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592823 = validateParameter(valid_592823, JString, required = false,
                                 default = nil)
  if valid_592823 != nil:
    section.add "X-Amz-SignedHeaders", valid_592823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592847: Call_AcceptResourceShareInvitation_592703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts an invitation to a resource share from another AWS account.
  ## 
  let valid = call_592847.validator(path, query, header, formData, body)
  let scheme = call_592847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592847.url(scheme.get, call_592847.host, call_592847.base,
                         call_592847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592847, url, valid)

proc call*(call_592918: Call_AcceptResourceShareInvitation_592703; body: JsonNode): Recallable =
  ## acceptResourceShareInvitation
  ## Accepts an invitation to a resource share from another AWS account.
  ##   body: JObject (required)
  var body_592919 = newJObject()
  if body != nil:
    body_592919 = body
  result = call_592918.call(nil, nil, nil, nil, body_592919)

var acceptResourceShareInvitation* = Call_AcceptResourceShareInvitation_592703(
    name: "acceptResourceShareInvitation", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/acceptresourceshareinvitation",
    validator: validate_AcceptResourceShareInvitation_592704, base: "/",
    url: url_AcceptResourceShareInvitation_592705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateResourceShare_592958 = ref object of OpenApiRestCall_592364
proc url_AssociateResourceShare_592960(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateResourceShare_592959(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592961 = header.getOrDefault("X-Amz-Signature")
  valid_592961 = validateParameter(valid_592961, JString, required = false,
                                 default = nil)
  if valid_592961 != nil:
    section.add "X-Amz-Signature", valid_592961
  var valid_592962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592962 = validateParameter(valid_592962, JString, required = false,
                                 default = nil)
  if valid_592962 != nil:
    section.add "X-Amz-Content-Sha256", valid_592962
  var valid_592963 = header.getOrDefault("X-Amz-Date")
  valid_592963 = validateParameter(valid_592963, JString, required = false,
                                 default = nil)
  if valid_592963 != nil:
    section.add "X-Amz-Date", valid_592963
  var valid_592964 = header.getOrDefault("X-Amz-Credential")
  valid_592964 = validateParameter(valid_592964, JString, required = false,
                                 default = nil)
  if valid_592964 != nil:
    section.add "X-Amz-Credential", valid_592964
  var valid_592965 = header.getOrDefault("X-Amz-Security-Token")
  valid_592965 = validateParameter(valid_592965, JString, required = false,
                                 default = nil)
  if valid_592965 != nil:
    section.add "X-Amz-Security-Token", valid_592965
  var valid_592966 = header.getOrDefault("X-Amz-Algorithm")
  valid_592966 = validateParameter(valid_592966, JString, required = false,
                                 default = nil)
  if valid_592966 != nil:
    section.add "X-Amz-Algorithm", valid_592966
  var valid_592967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592967 = validateParameter(valid_592967, JString, required = false,
                                 default = nil)
  if valid_592967 != nil:
    section.add "X-Amz-SignedHeaders", valid_592967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592969: Call_AssociateResourceShare_592958; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified resource share with the specified principals and resources.
  ## 
  let valid = call_592969.validator(path, query, header, formData, body)
  let scheme = call_592969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592969.url(scheme.get, call_592969.host, call_592969.base,
                         call_592969.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592969, url, valid)

proc call*(call_592970: Call_AssociateResourceShare_592958; body: JsonNode): Recallable =
  ## associateResourceShare
  ## Associates the specified resource share with the specified principals and resources.
  ##   body: JObject (required)
  var body_592971 = newJObject()
  if body != nil:
    body_592971 = body
  result = call_592970.call(nil, nil, nil, nil, body_592971)

var associateResourceShare* = Call_AssociateResourceShare_592958(
    name: "associateResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/associateresourceshare",
    validator: validate_AssociateResourceShare_592959, base: "/",
    url: url_AssociateResourceShare_592960, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceShare_592972 = ref object of OpenApiRestCall_592364
proc url_CreateResourceShare_592974(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateResourceShare_592973(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592975 = header.getOrDefault("X-Amz-Signature")
  valid_592975 = validateParameter(valid_592975, JString, required = false,
                                 default = nil)
  if valid_592975 != nil:
    section.add "X-Amz-Signature", valid_592975
  var valid_592976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592976 = validateParameter(valid_592976, JString, required = false,
                                 default = nil)
  if valid_592976 != nil:
    section.add "X-Amz-Content-Sha256", valid_592976
  var valid_592977 = header.getOrDefault("X-Amz-Date")
  valid_592977 = validateParameter(valid_592977, JString, required = false,
                                 default = nil)
  if valid_592977 != nil:
    section.add "X-Amz-Date", valid_592977
  var valid_592978 = header.getOrDefault("X-Amz-Credential")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "X-Amz-Credential", valid_592978
  var valid_592979 = header.getOrDefault("X-Amz-Security-Token")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Security-Token", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Algorithm")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Algorithm", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-SignedHeaders", valid_592981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592983: Call_CreateResourceShare_592972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a resource share.
  ## 
  let valid = call_592983.validator(path, query, header, formData, body)
  let scheme = call_592983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592983.url(scheme.get, call_592983.host, call_592983.base,
                         call_592983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592983, url, valid)

proc call*(call_592984: Call_CreateResourceShare_592972; body: JsonNode): Recallable =
  ## createResourceShare
  ## Creates a resource share.
  ##   body: JObject (required)
  var body_592985 = newJObject()
  if body != nil:
    body_592985 = body
  result = call_592984.call(nil, nil, nil, nil, body_592985)

var createResourceShare* = Call_CreateResourceShare_592972(
    name: "createResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/createresourceshare",
    validator: validate_CreateResourceShare_592973, base: "/",
    url: url_CreateResourceShare_592974, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceShare_592986 = ref object of OpenApiRestCall_592364
proc url_DeleteResourceShare_592988(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteResourceShare_592987(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes the specified resource share.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   clientToken: JString
  ##              : A unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  ##   resourceShareArn: JString (required)
  ##                   : The Amazon Resource Name (ARN) of the resource share.
  section = newJObject()
  var valid_592989 = query.getOrDefault("clientToken")
  valid_592989 = validateParameter(valid_592989, JString, required = false,
                                 default = nil)
  if valid_592989 != nil:
    section.add "clientToken", valid_592989
  assert query != nil,
        "query argument is necessary due to required `resourceShareArn` field"
  var valid_592990 = query.getOrDefault("resourceShareArn")
  valid_592990 = validateParameter(valid_592990, JString, required = true,
                                 default = nil)
  if valid_592990 != nil:
    section.add "resourceShareArn", valid_592990
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592991 = header.getOrDefault("X-Amz-Signature")
  valid_592991 = validateParameter(valid_592991, JString, required = false,
                                 default = nil)
  if valid_592991 != nil:
    section.add "X-Amz-Signature", valid_592991
  var valid_592992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "X-Amz-Content-Sha256", valid_592992
  var valid_592993 = header.getOrDefault("X-Amz-Date")
  valid_592993 = validateParameter(valid_592993, JString, required = false,
                                 default = nil)
  if valid_592993 != nil:
    section.add "X-Amz-Date", valid_592993
  var valid_592994 = header.getOrDefault("X-Amz-Credential")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Credential", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-Security-Token")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Security-Token", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-Algorithm")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Algorithm", valid_592996
  var valid_592997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-SignedHeaders", valid_592997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592998: Call_DeleteResourceShare_592986; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified resource share.
  ## 
  let valid = call_592998.validator(path, query, header, formData, body)
  let scheme = call_592998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592998.url(scheme.get, call_592998.host, call_592998.base,
                         call_592998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592998, url, valid)

proc call*(call_592999: Call_DeleteResourceShare_592986; resourceShareArn: string;
          clientToken: string = ""): Recallable =
  ## deleteResourceShare
  ## Deletes the specified resource share.
  ##   clientToken: string
  ##              : A unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  ##   resourceShareArn: string (required)
  ##                   : The Amazon Resource Name (ARN) of the resource share.
  var query_593000 = newJObject()
  add(query_593000, "clientToken", newJString(clientToken))
  add(query_593000, "resourceShareArn", newJString(resourceShareArn))
  result = call_592999.call(nil, query_593000, nil, nil, nil)

var deleteResourceShare* = Call_DeleteResourceShare_592986(
    name: "deleteResourceShare", meth: HttpMethod.HttpDelete,
    host: "ram.amazonaws.com", route: "/deleteresourceshare#resourceShareArn",
    validator: validate_DeleteResourceShare_592987, base: "/",
    url: url_DeleteResourceShare_592988, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateResourceShare_593002 = ref object of OpenApiRestCall_592364
proc url_DisassociateResourceShare_593004(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateResourceShare_593003(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593005 = header.getOrDefault("X-Amz-Signature")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "X-Amz-Signature", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-Content-Sha256", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-Date")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Date", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-Credential")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-Credential", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-Security-Token")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-Security-Token", valid_593009
  var valid_593010 = header.getOrDefault("X-Amz-Algorithm")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Algorithm", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-SignedHeaders", valid_593011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593013: Call_DisassociateResourceShare_593002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified principals or resources from the specified resource share.
  ## 
  let valid = call_593013.validator(path, query, header, formData, body)
  let scheme = call_593013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593013.url(scheme.get, call_593013.host, call_593013.base,
                         call_593013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593013, url, valid)

proc call*(call_593014: Call_DisassociateResourceShare_593002; body: JsonNode): Recallable =
  ## disassociateResourceShare
  ## Disassociates the specified principals or resources from the specified resource share.
  ##   body: JObject (required)
  var body_593015 = newJObject()
  if body != nil:
    body_593015 = body
  result = call_593014.call(nil, nil, nil, nil, body_593015)

var disassociateResourceShare* = Call_DisassociateResourceShare_593002(
    name: "disassociateResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/disassociateresourceshare",
    validator: validate_DisassociateResourceShare_593003, base: "/",
    url: url_DisassociateResourceShare_593004,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableSharingWithAwsOrganization_593016 = ref object of OpenApiRestCall_592364
proc url_EnableSharingWithAwsOrganization_593018(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_EnableSharingWithAwsOrganization_593017(path: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593019 = header.getOrDefault("X-Amz-Signature")
  valid_593019 = validateParameter(valid_593019, JString, required = false,
                                 default = nil)
  if valid_593019 != nil:
    section.add "X-Amz-Signature", valid_593019
  var valid_593020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = nil)
  if valid_593020 != nil:
    section.add "X-Amz-Content-Sha256", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-Date")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-Date", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-Credential")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Credential", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-Security-Token")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-Security-Token", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-Algorithm")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Algorithm", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-SignedHeaders", valid_593025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593026: Call_EnableSharingWithAwsOrganization_593016;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Enables resource sharing within your AWS Organization.</p> <p>The caller must be the master account for the AWS Organization.</p>
  ## 
  let valid = call_593026.validator(path, query, header, formData, body)
  let scheme = call_593026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593026.url(scheme.get, call_593026.host, call_593026.base,
                         call_593026.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593026, url, valid)

proc call*(call_593027: Call_EnableSharingWithAwsOrganization_593016): Recallable =
  ## enableSharingWithAwsOrganization
  ## <p>Enables resource sharing within your AWS Organization.</p> <p>The caller must be the master account for the AWS Organization.</p>
  result = call_593027.call(nil, nil, nil, nil, nil)

var enableSharingWithAwsOrganization* = Call_EnableSharingWithAwsOrganization_593016(
    name: "enableSharingWithAwsOrganization", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/enablesharingwithawsorganization",
    validator: validate_EnableSharingWithAwsOrganization_593017, base: "/",
    url: url_EnableSharingWithAwsOrganization_593018,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourcePolicies_593028 = ref object of OpenApiRestCall_592364
proc url_GetResourcePolicies_593030(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResourcePolicies_593029(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets the policies for the specified resources that you own and have shared.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_593031 = query.getOrDefault("nextToken")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "nextToken", valid_593031
  var valid_593032 = query.getOrDefault("maxResults")
  valid_593032 = validateParameter(valid_593032, JString, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "maxResults", valid_593032
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593033 = header.getOrDefault("X-Amz-Signature")
  valid_593033 = validateParameter(valid_593033, JString, required = false,
                                 default = nil)
  if valid_593033 != nil:
    section.add "X-Amz-Signature", valid_593033
  var valid_593034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593034 = validateParameter(valid_593034, JString, required = false,
                                 default = nil)
  if valid_593034 != nil:
    section.add "X-Amz-Content-Sha256", valid_593034
  var valid_593035 = header.getOrDefault("X-Amz-Date")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "X-Amz-Date", valid_593035
  var valid_593036 = header.getOrDefault("X-Amz-Credential")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-Credential", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-Security-Token")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Security-Token", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-Algorithm")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Algorithm", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-SignedHeaders", valid_593039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593041: Call_GetResourcePolicies_593028; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the policies for the specified resources that you own and have shared.
  ## 
  let valid = call_593041.validator(path, query, header, formData, body)
  let scheme = call_593041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593041.url(scheme.get, call_593041.host, call_593041.base,
                         call_593041.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593041, url, valid)

proc call*(call_593042: Call_GetResourcePolicies_593028; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getResourcePolicies
  ## Gets the policies for the specified resources that you own and have shared.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593043 = newJObject()
  var body_593044 = newJObject()
  add(query_593043, "nextToken", newJString(nextToken))
  if body != nil:
    body_593044 = body
  add(query_593043, "maxResults", newJString(maxResults))
  result = call_593042.call(nil, query_593043, nil, nil, body_593044)

var getResourcePolicies* = Call_GetResourcePolicies_593028(
    name: "getResourcePolicies", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/getresourcepolicies",
    validator: validate_GetResourcePolicies_593029, base: "/",
    url: url_GetResourcePolicies_593030, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceShareAssociations_593045 = ref object of OpenApiRestCall_592364
proc url_GetResourceShareAssociations_593047(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResourceShareAssociations_593046(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the resources or principals for the resource shares that you own.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_593048 = query.getOrDefault("nextToken")
  valid_593048 = validateParameter(valid_593048, JString, required = false,
                                 default = nil)
  if valid_593048 != nil:
    section.add "nextToken", valid_593048
  var valid_593049 = query.getOrDefault("maxResults")
  valid_593049 = validateParameter(valid_593049, JString, required = false,
                                 default = nil)
  if valid_593049 != nil:
    section.add "maxResults", valid_593049
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593050 = header.getOrDefault("X-Amz-Signature")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = nil)
  if valid_593050 != nil:
    section.add "X-Amz-Signature", valid_593050
  var valid_593051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "X-Amz-Content-Sha256", valid_593051
  var valid_593052 = header.getOrDefault("X-Amz-Date")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-Date", valid_593052
  var valid_593053 = header.getOrDefault("X-Amz-Credential")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Credential", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-Security-Token")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Security-Token", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Algorithm")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Algorithm", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-SignedHeaders", valid_593056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593058: Call_GetResourceShareAssociations_593045; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the resources or principals for the resource shares that you own.
  ## 
  let valid = call_593058.validator(path, query, header, formData, body)
  let scheme = call_593058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593058.url(scheme.get, call_593058.host, call_593058.base,
                         call_593058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593058, url, valid)

proc call*(call_593059: Call_GetResourceShareAssociations_593045; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getResourceShareAssociations
  ## Gets the resources or principals for the resource shares that you own.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593060 = newJObject()
  var body_593061 = newJObject()
  add(query_593060, "nextToken", newJString(nextToken))
  if body != nil:
    body_593061 = body
  add(query_593060, "maxResults", newJString(maxResults))
  result = call_593059.call(nil, query_593060, nil, nil, body_593061)

var getResourceShareAssociations* = Call_GetResourceShareAssociations_593045(
    name: "getResourceShareAssociations", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/getresourceshareassociations",
    validator: validate_GetResourceShareAssociations_593046, base: "/",
    url: url_GetResourceShareAssociations_593047,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceShareInvitations_593062 = ref object of OpenApiRestCall_592364
proc url_GetResourceShareInvitations_593064(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResourceShareInvitations_593063(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the invitations for resource sharing that you've received.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_593065 = query.getOrDefault("nextToken")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "nextToken", valid_593065
  var valid_593066 = query.getOrDefault("maxResults")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "maxResults", valid_593066
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593067 = header.getOrDefault("X-Amz-Signature")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-Signature", valid_593067
  var valid_593068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-Content-Sha256", valid_593068
  var valid_593069 = header.getOrDefault("X-Amz-Date")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "X-Amz-Date", valid_593069
  var valid_593070 = header.getOrDefault("X-Amz-Credential")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "X-Amz-Credential", valid_593070
  var valid_593071 = header.getOrDefault("X-Amz-Security-Token")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-Security-Token", valid_593071
  var valid_593072 = header.getOrDefault("X-Amz-Algorithm")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-Algorithm", valid_593072
  var valid_593073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593073 = validateParameter(valid_593073, JString, required = false,
                                 default = nil)
  if valid_593073 != nil:
    section.add "X-Amz-SignedHeaders", valid_593073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593075: Call_GetResourceShareInvitations_593062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the invitations for resource sharing that you've received.
  ## 
  let valid = call_593075.validator(path, query, header, formData, body)
  let scheme = call_593075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593075.url(scheme.get, call_593075.host, call_593075.base,
                         call_593075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593075, url, valid)

proc call*(call_593076: Call_GetResourceShareInvitations_593062; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getResourceShareInvitations
  ## Gets the invitations for resource sharing that you've received.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593077 = newJObject()
  var body_593078 = newJObject()
  add(query_593077, "nextToken", newJString(nextToken))
  if body != nil:
    body_593078 = body
  add(query_593077, "maxResults", newJString(maxResults))
  result = call_593076.call(nil, query_593077, nil, nil, body_593078)

var getResourceShareInvitations* = Call_GetResourceShareInvitations_593062(
    name: "getResourceShareInvitations", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/getresourceshareinvitations",
    validator: validate_GetResourceShareInvitations_593063, base: "/",
    url: url_GetResourceShareInvitations_593064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceShares_593079 = ref object of OpenApiRestCall_592364
proc url_GetResourceShares_593081(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResourceShares_593080(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Gets the resource shares that you own or the resource shares that are shared with you.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_593082 = query.getOrDefault("nextToken")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "nextToken", valid_593082
  var valid_593083 = query.getOrDefault("maxResults")
  valid_593083 = validateParameter(valid_593083, JString, required = false,
                                 default = nil)
  if valid_593083 != nil:
    section.add "maxResults", valid_593083
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593084 = header.getOrDefault("X-Amz-Signature")
  valid_593084 = validateParameter(valid_593084, JString, required = false,
                                 default = nil)
  if valid_593084 != nil:
    section.add "X-Amz-Signature", valid_593084
  var valid_593085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "X-Amz-Content-Sha256", valid_593085
  var valid_593086 = header.getOrDefault("X-Amz-Date")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "X-Amz-Date", valid_593086
  var valid_593087 = header.getOrDefault("X-Amz-Credential")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "X-Amz-Credential", valid_593087
  var valid_593088 = header.getOrDefault("X-Amz-Security-Token")
  valid_593088 = validateParameter(valid_593088, JString, required = false,
                                 default = nil)
  if valid_593088 != nil:
    section.add "X-Amz-Security-Token", valid_593088
  var valid_593089 = header.getOrDefault("X-Amz-Algorithm")
  valid_593089 = validateParameter(valid_593089, JString, required = false,
                                 default = nil)
  if valid_593089 != nil:
    section.add "X-Amz-Algorithm", valid_593089
  var valid_593090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "X-Amz-SignedHeaders", valid_593090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593092: Call_GetResourceShares_593079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the resource shares that you own or the resource shares that are shared with you.
  ## 
  let valid = call_593092.validator(path, query, header, formData, body)
  let scheme = call_593092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593092.url(scheme.get, call_593092.host, call_593092.base,
                         call_593092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593092, url, valid)

proc call*(call_593093: Call_GetResourceShares_593079; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getResourceShares
  ## Gets the resource shares that you own or the resource shares that are shared with you.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593094 = newJObject()
  var body_593095 = newJObject()
  add(query_593094, "nextToken", newJString(nextToken))
  if body != nil:
    body_593095 = body
  add(query_593094, "maxResults", newJString(maxResults))
  result = call_593093.call(nil, query_593094, nil, nil, body_593095)

var getResourceShares* = Call_GetResourceShares_593079(name: "getResourceShares",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com",
    route: "/getresourceshares", validator: validate_GetResourceShares_593080,
    base: "/", url: url_GetResourceShares_593081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPendingInvitationResources_593096 = ref object of OpenApiRestCall_592364
proc url_ListPendingInvitationResources_593098(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPendingInvitationResources_593097(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the resources in a resource share that is shared with you but that the invitation is still pending for.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_593099 = query.getOrDefault("nextToken")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "nextToken", valid_593099
  var valid_593100 = query.getOrDefault("maxResults")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "maxResults", valid_593100
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593101 = header.getOrDefault("X-Amz-Signature")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-Signature", valid_593101
  var valid_593102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "X-Amz-Content-Sha256", valid_593102
  var valid_593103 = header.getOrDefault("X-Amz-Date")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "X-Amz-Date", valid_593103
  var valid_593104 = header.getOrDefault("X-Amz-Credential")
  valid_593104 = validateParameter(valid_593104, JString, required = false,
                                 default = nil)
  if valid_593104 != nil:
    section.add "X-Amz-Credential", valid_593104
  var valid_593105 = header.getOrDefault("X-Amz-Security-Token")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "X-Amz-Security-Token", valid_593105
  var valid_593106 = header.getOrDefault("X-Amz-Algorithm")
  valid_593106 = validateParameter(valid_593106, JString, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "X-Amz-Algorithm", valid_593106
  var valid_593107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "X-Amz-SignedHeaders", valid_593107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593109: Call_ListPendingInvitationResources_593096; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resources in a resource share that is shared with you but that the invitation is still pending for.
  ## 
  let valid = call_593109.validator(path, query, header, formData, body)
  let scheme = call_593109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593109.url(scheme.get, call_593109.host, call_593109.base,
                         call_593109.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593109, url, valid)

proc call*(call_593110: Call_ListPendingInvitationResources_593096; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listPendingInvitationResources
  ## Lists the resources in a resource share that is shared with you but that the invitation is still pending for.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593111 = newJObject()
  var body_593112 = newJObject()
  add(query_593111, "nextToken", newJString(nextToken))
  if body != nil:
    body_593112 = body
  add(query_593111, "maxResults", newJString(maxResults))
  result = call_593110.call(nil, query_593111, nil, nil, body_593112)

var listPendingInvitationResources* = Call_ListPendingInvitationResources_593096(
    name: "listPendingInvitationResources", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/listpendinginvitationresources",
    validator: validate_ListPendingInvitationResources_593097, base: "/",
    url: url_ListPendingInvitationResources_593098,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPrincipals_593113 = ref object of OpenApiRestCall_592364
proc url_ListPrincipals_593115(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPrincipals_593114(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists the principals that you have shared resources with or the principals that have shared resources with you.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_593116 = query.getOrDefault("nextToken")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "nextToken", valid_593116
  var valid_593117 = query.getOrDefault("maxResults")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "maxResults", valid_593117
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593118 = header.getOrDefault("X-Amz-Signature")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "X-Amz-Signature", valid_593118
  var valid_593119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "X-Amz-Content-Sha256", valid_593119
  var valid_593120 = header.getOrDefault("X-Amz-Date")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "X-Amz-Date", valid_593120
  var valid_593121 = header.getOrDefault("X-Amz-Credential")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "X-Amz-Credential", valid_593121
  var valid_593122 = header.getOrDefault("X-Amz-Security-Token")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "X-Amz-Security-Token", valid_593122
  var valid_593123 = header.getOrDefault("X-Amz-Algorithm")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-Algorithm", valid_593123
  var valid_593124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593124 = validateParameter(valid_593124, JString, required = false,
                                 default = nil)
  if valid_593124 != nil:
    section.add "X-Amz-SignedHeaders", valid_593124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593126: Call_ListPrincipals_593113; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the principals that you have shared resources with or the principals that have shared resources with you.
  ## 
  let valid = call_593126.validator(path, query, header, formData, body)
  let scheme = call_593126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593126.url(scheme.get, call_593126.host, call_593126.base,
                         call_593126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593126, url, valid)

proc call*(call_593127: Call_ListPrincipals_593113; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listPrincipals
  ## Lists the principals that you have shared resources with or the principals that have shared resources with you.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593128 = newJObject()
  var body_593129 = newJObject()
  add(query_593128, "nextToken", newJString(nextToken))
  if body != nil:
    body_593129 = body
  add(query_593128, "maxResults", newJString(maxResults))
  result = call_593127.call(nil, query_593128, nil, nil, body_593129)

var listPrincipals* = Call_ListPrincipals_593113(name: "listPrincipals",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com", route: "/listprincipals",
    validator: validate_ListPrincipals_593114, base: "/", url: url_ListPrincipals_593115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResources_593130 = ref object of OpenApiRestCall_592364
proc url_ListResources_593132(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListResources_593131(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the resources that you added to a resource shares or the resources that are shared with you.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_593133 = query.getOrDefault("nextToken")
  valid_593133 = validateParameter(valid_593133, JString, required = false,
                                 default = nil)
  if valid_593133 != nil:
    section.add "nextToken", valid_593133
  var valid_593134 = query.getOrDefault("maxResults")
  valid_593134 = validateParameter(valid_593134, JString, required = false,
                                 default = nil)
  if valid_593134 != nil:
    section.add "maxResults", valid_593134
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593135 = header.getOrDefault("X-Amz-Signature")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "X-Amz-Signature", valid_593135
  var valid_593136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593136 = validateParameter(valid_593136, JString, required = false,
                                 default = nil)
  if valid_593136 != nil:
    section.add "X-Amz-Content-Sha256", valid_593136
  var valid_593137 = header.getOrDefault("X-Amz-Date")
  valid_593137 = validateParameter(valid_593137, JString, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "X-Amz-Date", valid_593137
  var valid_593138 = header.getOrDefault("X-Amz-Credential")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-Credential", valid_593138
  var valid_593139 = header.getOrDefault("X-Amz-Security-Token")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "X-Amz-Security-Token", valid_593139
  var valid_593140 = header.getOrDefault("X-Amz-Algorithm")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-Algorithm", valid_593140
  var valid_593141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-SignedHeaders", valid_593141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593143: Call_ListResources_593130; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resources that you added to a resource shares or the resources that are shared with you.
  ## 
  let valid = call_593143.validator(path, query, header, formData, body)
  let scheme = call_593143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593143.url(scheme.get, call_593143.host, call_593143.base,
                         call_593143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593143, url, valid)

proc call*(call_593144: Call_ListResources_593130; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listResources
  ## Lists the resources that you added to a resource shares or the resources that are shared with you.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593145 = newJObject()
  var body_593146 = newJObject()
  add(query_593145, "nextToken", newJString(nextToken))
  if body != nil:
    body_593146 = body
  add(query_593145, "maxResults", newJString(maxResults))
  result = call_593144.call(nil, query_593145, nil, nil, body_593146)

var listResources* = Call_ListResources_593130(name: "listResources",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com", route: "/listresources",
    validator: validate_ListResources_593131, base: "/", url: url_ListResources_593132,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectResourceShareInvitation_593147 = ref object of OpenApiRestCall_592364
proc url_RejectResourceShareInvitation_593149(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RejectResourceShareInvitation_593148(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593150 = header.getOrDefault("X-Amz-Signature")
  valid_593150 = validateParameter(valid_593150, JString, required = false,
                                 default = nil)
  if valid_593150 != nil:
    section.add "X-Amz-Signature", valid_593150
  var valid_593151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593151 = validateParameter(valid_593151, JString, required = false,
                                 default = nil)
  if valid_593151 != nil:
    section.add "X-Amz-Content-Sha256", valid_593151
  var valid_593152 = header.getOrDefault("X-Amz-Date")
  valid_593152 = validateParameter(valid_593152, JString, required = false,
                                 default = nil)
  if valid_593152 != nil:
    section.add "X-Amz-Date", valid_593152
  var valid_593153 = header.getOrDefault("X-Amz-Credential")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "X-Amz-Credential", valid_593153
  var valid_593154 = header.getOrDefault("X-Amz-Security-Token")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "X-Amz-Security-Token", valid_593154
  var valid_593155 = header.getOrDefault("X-Amz-Algorithm")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "X-Amz-Algorithm", valid_593155
  var valid_593156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "X-Amz-SignedHeaders", valid_593156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593158: Call_RejectResourceShareInvitation_593147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Rejects an invitation to a resource share from another AWS account.
  ## 
  let valid = call_593158.validator(path, query, header, formData, body)
  let scheme = call_593158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593158.url(scheme.get, call_593158.host, call_593158.base,
                         call_593158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593158, url, valid)

proc call*(call_593159: Call_RejectResourceShareInvitation_593147; body: JsonNode): Recallable =
  ## rejectResourceShareInvitation
  ## Rejects an invitation to a resource share from another AWS account.
  ##   body: JObject (required)
  var body_593160 = newJObject()
  if body != nil:
    body_593160 = body
  result = call_593159.call(nil, nil, nil, nil, body_593160)

var rejectResourceShareInvitation* = Call_RejectResourceShareInvitation_593147(
    name: "rejectResourceShareInvitation", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/rejectresourceshareinvitation",
    validator: validate_RejectResourceShareInvitation_593148, base: "/",
    url: url_RejectResourceShareInvitation_593149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_593161 = ref object of OpenApiRestCall_592364
proc url_TagResource_593163(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_593162(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593164 = header.getOrDefault("X-Amz-Signature")
  valid_593164 = validateParameter(valid_593164, JString, required = false,
                                 default = nil)
  if valid_593164 != nil:
    section.add "X-Amz-Signature", valid_593164
  var valid_593165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593165 = validateParameter(valid_593165, JString, required = false,
                                 default = nil)
  if valid_593165 != nil:
    section.add "X-Amz-Content-Sha256", valid_593165
  var valid_593166 = header.getOrDefault("X-Amz-Date")
  valid_593166 = validateParameter(valid_593166, JString, required = false,
                                 default = nil)
  if valid_593166 != nil:
    section.add "X-Amz-Date", valid_593166
  var valid_593167 = header.getOrDefault("X-Amz-Credential")
  valid_593167 = validateParameter(valid_593167, JString, required = false,
                                 default = nil)
  if valid_593167 != nil:
    section.add "X-Amz-Credential", valid_593167
  var valid_593168 = header.getOrDefault("X-Amz-Security-Token")
  valid_593168 = validateParameter(valid_593168, JString, required = false,
                                 default = nil)
  if valid_593168 != nil:
    section.add "X-Amz-Security-Token", valid_593168
  var valid_593169 = header.getOrDefault("X-Amz-Algorithm")
  valid_593169 = validateParameter(valid_593169, JString, required = false,
                                 default = nil)
  if valid_593169 != nil:
    section.add "X-Amz-Algorithm", valid_593169
  var valid_593170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593170 = validateParameter(valid_593170, JString, required = false,
                                 default = nil)
  if valid_593170 != nil:
    section.add "X-Amz-SignedHeaders", valid_593170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593172: Call_TagResource_593161; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds the specified tags to the specified resource share that you own.
  ## 
  let valid = call_593172.validator(path, query, header, formData, body)
  let scheme = call_593172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593172.url(scheme.get, call_593172.host, call_593172.base,
                         call_593172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593172, url, valid)

proc call*(call_593173: Call_TagResource_593161; body: JsonNode): Recallable =
  ## tagResource
  ## Adds the specified tags to the specified resource share that you own.
  ##   body: JObject (required)
  var body_593174 = newJObject()
  if body != nil:
    body_593174 = body
  result = call_593173.call(nil, nil, nil, nil, body_593174)

var tagResource* = Call_TagResource_593161(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "ram.amazonaws.com",
                                        route: "/tagresource",
                                        validator: validate_TagResource_593162,
                                        base: "/", url: url_TagResource_593163,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_593175 = ref object of OpenApiRestCall_592364
proc url_UntagResource_593177(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_593176(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593178 = header.getOrDefault("X-Amz-Signature")
  valid_593178 = validateParameter(valid_593178, JString, required = false,
                                 default = nil)
  if valid_593178 != nil:
    section.add "X-Amz-Signature", valid_593178
  var valid_593179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593179 = validateParameter(valid_593179, JString, required = false,
                                 default = nil)
  if valid_593179 != nil:
    section.add "X-Amz-Content-Sha256", valid_593179
  var valid_593180 = header.getOrDefault("X-Amz-Date")
  valid_593180 = validateParameter(valid_593180, JString, required = false,
                                 default = nil)
  if valid_593180 != nil:
    section.add "X-Amz-Date", valid_593180
  var valid_593181 = header.getOrDefault("X-Amz-Credential")
  valid_593181 = validateParameter(valid_593181, JString, required = false,
                                 default = nil)
  if valid_593181 != nil:
    section.add "X-Amz-Credential", valid_593181
  var valid_593182 = header.getOrDefault("X-Amz-Security-Token")
  valid_593182 = validateParameter(valid_593182, JString, required = false,
                                 default = nil)
  if valid_593182 != nil:
    section.add "X-Amz-Security-Token", valid_593182
  var valid_593183 = header.getOrDefault("X-Amz-Algorithm")
  valid_593183 = validateParameter(valid_593183, JString, required = false,
                                 default = nil)
  if valid_593183 != nil:
    section.add "X-Amz-Algorithm", valid_593183
  var valid_593184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593184 = validateParameter(valid_593184, JString, required = false,
                                 default = nil)
  if valid_593184 != nil:
    section.add "X-Amz-SignedHeaders", valid_593184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593186: Call_UntagResource_593175; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tags from the specified resource share that you own.
  ## 
  let valid = call_593186.validator(path, query, header, formData, body)
  let scheme = call_593186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593186.url(scheme.get, call_593186.host, call_593186.base,
                         call_593186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593186, url, valid)

proc call*(call_593187: Call_UntagResource_593175; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tags from the specified resource share that you own.
  ##   body: JObject (required)
  var body_593188 = newJObject()
  if body != nil:
    body_593188 = body
  result = call_593187.call(nil, nil, nil, nil, body_593188)

var untagResource* = Call_UntagResource_593175(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com", route: "/untagresource",
    validator: validate_UntagResource_593176, base: "/", url: url_UntagResource_593177,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceShare_593189 = ref object of OpenApiRestCall_592364
proc url_UpdateResourceShare_593191(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateResourceShare_593190(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593192 = header.getOrDefault("X-Amz-Signature")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-Signature", valid_593192
  var valid_593193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593193 = validateParameter(valid_593193, JString, required = false,
                                 default = nil)
  if valid_593193 != nil:
    section.add "X-Amz-Content-Sha256", valid_593193
  var valid_593194 = header.getOrDefault("X-Amz-Date")
  valid_593194 = validateParameter(valid_593194, JString, required = false,
                                 default = nil)
  if valid_593194 != nil:
    section.add "X-Amz-Date", valid_593194
  var valid_593195 = header.getOrDefault("X-Amz-Credential")
  valid_593195 = validateParameter(valid_593195, JString, required = false,
                                 default = nil)
  if valid_593195 != nil:
    section.add "X-Amz-Credential", valid_593195
  var valid_593196 = header.getOrDefault("X-Amz-Security-Token")
  valid_593196 = validateParameter(valid_593196, JString, required = false,
                                 default = nil)
  if valid_593196 != nil:
    section.add "X-Amz-Security-Token", valid_593196
  var valid_593197 = header.getOrDefault("X-Amz-Algorithm")
  valid_593197 = validateParameter(valid_593197, JString, required = false,
                                 default = nil)
  if valid_593197 != nil:
    section.add "X-Amz-Algorithm", valid_593197
  var valid_593198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593198 = validateParameter(valid_593198, JString, required = false,
                                 default = nil)
  if valid_593198 != nil:
    section.add "X-Amz-SignedHeaders", valid_593198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593200: Call_UpdateResourceShare_593189; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified resource share that you own.
  ## 
  let valid = call_593200.validator(path, query, header, formData, body)
  let scheme = call_593200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593200.url(scheme.get, call_593200.host, call_593200.base,
                         call_593200.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593200, url, valid)

proc call*(call_593201: Call_UpdateResourceShare_593189; body: JsonNode): Recallable =
  ## updateResourceShare
  ## Updates the specified resource share that you own.
  ##   body: JObject (required)
  var body_593202 = newJObject()
  if body != nil:
    body_593202 = body
  result = call_593201.call(nil, nil, nil, nil, body_593202)

var updateResourceShare* = Call_UpdateResourceShare_593189(
    name: "updateResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/updateresourceshare",
    validator: validate_UpdateResourceShare_593190, base: "/",
    url: url_UpdateResourceShare_593191, schemes: {Scheme.Https, Scheme.Http})
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
