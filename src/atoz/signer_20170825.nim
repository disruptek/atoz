
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Signer
## version: 2017-08-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## With code signing for IoT, you can sign code that you create for any IoT device that is supported by Amazon Web Services (AWS). Code signing is available through <a href="http://docs.aws.amazon.com/freertos/latest/userguide/">Amazon FreeRTOS</a> and <a href="http://docs.aws.amazon.com/iot/latest/developerguide/">AWS IoT Device Management</a>, and integrated with <a href="http://docs.aws.amazon.com/acm/latest/userguide/">AWS Certificate Manager (ACM)</a>. In order to sign code, you import a third-party code signing certificate with ACM that is used to sign updates in Amazon FreeRTOS and AWS IoT Device Management. For general information about using code signing, see the <a href="http://docs.aws.amazon.com/signer/latest/developerguide/Welcome.html">Code Signing for IoT Developer Guide</a>.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/signer/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
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
    if required:
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "signer.ap-northeast-1.amazonaws.com", "ap-southeast-1": "signer.ap-southeast-1.amazonaws.com",
                           "us-west-2": "signer.us-west-2.amazonaws.com",
                           "eu-west-2": "signer.eu-west-2.amazonaws.com", "ap-northeast-3": "signer.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "signer.eu-central-1.amazonaws.com",
                           "us-east-2": "signer.us-east-2.amazonaws.com",
                           "us-east-1": "signer.us-east-1.amazonaws.com", "cn-northwest-1": "signer.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "signer.ap-south-1.amazonaws.com",
                           "eu-north-1": "signer.eu-north-1.amazonaws.com", "ap-northeast-2": "signer.ap-northeast-2.amazonaws.com",
                           "us-west-1": "signer.us-west-1.amazonaws.com", "us-gov-east-1": "signer.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "signer.eu-west-3.amazonaws.com",
                           "cn-north-1": "signer.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "signer.sa-east-1.amazonaws.com",
                           "eu-west-1": "signer.eu-west-1.amazonaws.com", "us-gov-west-1": "signer.us-gov-west-1.amazonaws.com", "ap-southeast-2": "signer.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "signer.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "signer.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "signer.ap-southeast-1.amazonaws.com",
      "us-west-2": "signer.us-west-2.amazonaws.com",
      "eu-west-2": "signer.eu-west-2.amazonaws.com",
      "ap-northeast-3": "signer.ap-northeast-3.amazonaws.com",
      "eu-central-1": "signer.eu-central-1.amazonaws.com",
      "us-east-2": "signer.us-east-2.amazonaws.com",
      "us-east-1": "signer.us-east-1.amazonaws.com",
      "cn-northwest-1": "signer.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "signer.ap-south-1.amazonaws.com",
      "eu-north-1": "signer.eu-north-1.amazonaws.com",
      "ap-northeast-2": "signer.ap-northeast-2.amazonaws.com",
      "us-west-1": "signer.us-west-1.amazonaws.com",
      "us-gov-east-1": "signer.us-gov-east-1.amazonaws.com",
      "eu-west-3": "signer.eu-west-3.amazonaws.com",
      "cn-north-1": "signer.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "signer.sa-east-1.amazonaws.com",
      "eu-west-1": "signer.eu-west-1.amazonaws.com",
      "us-gov-west-1": "signer.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "signer.ap-southeast-2.amazonaws.com",
      "ca-central-1": "signer.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "signer"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_PutSigningProfile_21626030 = ref object of OpenApiRestCall_21625435
proc url_PutSigningProfile_21626032(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "profileName" in path, "`profileName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/signing-profiles/"),
               (kind: VariableSegment, value: "profileName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutSigningProfile_21626031(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a signing profile. A signing profile is a code signing template that can be used to carry out a pre-defined signing job. For more information, see <a href="http://docs.aws.amazon.com/signer/latest/developerguide/gs-profile.html">http://docs.aws.amazon.com/signer/latest/developerguide/gs-profile.html</a> 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   profileName: JString (required)
  ##              : The name of the signing profile to be created.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `profileName` field"
  var valid_21626033 = path.getOrDefault("profileName")
  valid_21626033 = validateParameter(valid_21626033, JString, required = true,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "profileName", valid_21626033
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
  var valid_21626034 = header.getOrDefault("X-Amz-Date")
  valid_21626034 = validateParameter(valid_21626034, JString, required = false,
                                   default = nil)
  if valid_21626034 != nil:
    section.add "X-Amz-Date", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Security-Token", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Algorithm", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-Signature")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Signature", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Credential")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Credential", valid_21626040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626042: Call_PutSigningProfile_21626030; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a signing profile. A signing profile is a code signing template that can be used to carry out a pre-defined signing job. For more information, see <a href="http://docs.aws.amazon.com/signer/latest/developerguide/gs-profile.html">http://docs.aws.amazon.com/signer/latest/developerguide/gs-profile.html</a> 
  ## 
  let valid = call_21626042.validator(path, query, header, formData, body, _)
  let scheme = call_21626042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626042.makeUrl(scheme.get, call_21626042.host, call_21626042.base,
                               call_21626042.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626042, uri, valid, _)

proc call*(call_21626043: Call_PutSigningProfile_21626030; profileName: string;
          body: JsonNode): Recallable =
  ## putSigningProfile
  ## Creates a signing profile. A signing profile is a code signing template that can be used to carry out a pre-defined signing job. For more information, see <a href="http://docs.aws.amazon.com/signer/latest/developerguide/gs-profile.html">http://docs.aws.amazon.com/signer/latest/developerguide/gs-profile.html</a> 
  ##   profileName: string (required)
  ##              : The name of the signing profile to be created.
  ##   body: JObject (required)
  var path_21626044 = newJObject()
  var body_21626045 = newJObject()
  add(path_21626044, "profileName", newJString(profileName))
  if body != nil:
    body_21626045 = body
  result = call_21626043.call(path_21626044, nil, nil, nil, body_21626045)

var putSigningProfile* = Call_PutSigningProfile_21626030(name: "putSigningProfile",
    meth: HttpMethod.HttpPut, host: "signer.amazonaws.com",
    route: "/signing-profiles/{profileName}",
    validator: validate_PutSigningProfile_21626031, base: "/",
    makeUrl: url_PutSigningProfile_21626032, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSigningProfile_21625779 = ref object of OpenApiRestCall_21625435
proc url_GetSigningProfile_21625781(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "profileName" in path, "`profileName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/signing-profiles/"),
               (kind: VariableSegment, value: "profileName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSigningProfile_21625780(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information on a specific signing profile.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   profileName: JString (required)
  ##              : The name of the target signing profile.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `profileName` field"
  var valid_21625895 = path.getOrDefault("profileName")
  valid_21625895 = validateParameter(valid_21625895, JString, required = true,
                                   default = nil)
  if valid_21625895 != nil:
    section.add "profileName", valid_21625895
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
  var valid_21625896 = header.getOrDefault("X-Amz-Date")
  valid_21625896 = validateParameter(valid_21625896, JString, required = false,
                                   default = nil)
  if valid_21625896 != nil:
    section.add "X-Amz-Date", valid_21625896
  var valid_21625897 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625897 = validateParameter(valid_21625897, JString, required = false,
                                   default = nil)
  if valid_21625897 != nil:
    section.add "X-Amz-Security-Token", valid_21625897
  var valid_21625898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625898 = validateParameter(valid_21625898, JString, required = false,
                                   default = nil)
  if valid_21625898 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625898
  var valid_21625899 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Algorithm", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Signature")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Signature", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-Credential")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-Credential", valid_21625902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625927: Call_GetSigningProfile_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information on a specific signing profile.
  ## 
  let valid = call_21625927.validator(path, query, header, formData, body, _)
  let scheme = call_21625927.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625927.makeUrl(scheme.get, call_21625927.host, call_21625927.base,
                               call_21625927.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625927, uri, valid, _)

proc call*(call_21625990: Call_GetSigningProfile_21625779; profileName: string): Recallable =
  ## getSigningProfile
  ## Returns information on a specific signing profile.
  ##   profileName: string (required)
  ##              : The name of the target signing profile.
  var path_21625992 = newJObject()
  add(path_21625992, "profileName", newJString(profileName))
  result = call_21625990.call(path_21625992, nil, nil, nil, nil)

var getSigningProfile* = Call_GetSigningProfile_21625779(name: "getSigningProfile",
    meth: HttpMethod.HttpGet, host: "signer.amazonaws.com",
    route: "/signing-profiles/{profileName}",
    validator: validate_GetSigningProfile_21625780, base: "/",
    makeUrl: url_GetSigningProfile_21625781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelSigningProfile_21626046 = ref object of OpenApiRestCall_21625435
proc url_CancelSigningProfile_21626048(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "profileName" in path, "`profileName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/signing-profiles/"),
               (kind: VariableSegment, value: "profileName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CancelSigningProfile_21626047(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Changes the state of an <code>ACTIVE</code> signing profile to <code>CANCELED</code>. A canceled profile is still viewable with the <code>ListSigningProfiles</code> operation, but it cannot perform new signing jobs, and is deleted two years after cancelation.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   profileName: JString (required)
  ##              : The name of the signing profile to be canceled.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `profileName` field"
  var valid_21626049 = path.getOrDefault("profileName")
  valid_21626049 = validateParameter(valid_21626049, JString, required = true,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "profileName", valid_21626049
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
  var valid_21626050 = header.getOrDefault("X-Amz-Date")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Date", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Security-Token", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-Algorithm", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Signature")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Signature", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-Credential")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Credential", valid_21626056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626057: Call_CancelSigningProfile_21626046; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Changes the state of an <code>ACTIVE</code> signing profile to <code>CANCELED</code>. A canceled profile is still viewable with the <code>ListSigningProfiles</code> operation, but it cannot perform new signing jobs, and is deleted two years after cancelation.
  ## 
  let valid = call_21626057.validator(path, query, header, formData, body, _)
  let scheme = call_21626057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626057.makeUrl(scheme.get, call_21626057.host, call_21626057.base,
                               call_21626057.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626057, uri, valid, _)

proc call*(call_21626058: Call_CancelSigningProfile_21626046; profileName: string): Recallable =
  ## cancelSigningProfile
  ## Changes the state of an <code>ACTIVE</code> signing profile to <code>CANCELED</code>. A canceled profile is still viewable with the <code>ListSigningProfiles</code> operation, but it cannot perform new signing jobs, and is deleted two years after cancelation.
  ##   profileName: string (required)
  ##              : The name of the signing profile to be canceled.
  var path_21626059 = newJObject()
  add(path_21626059, "profileName", newJString(profileName))
  result = call_21626058.call(path_21626059, nil, nil, nil, nil)

var cancelSigningProfile* = Call_CancelSigningProfile_21626046(
    name: "cancelSigningProfile", meth: HttpMethod.HttpDelete,
    host: "signer.amazonaws.com", route: "/signing-profiles/{profileName}",
    validator: validate_CancelSigningProfile_21626047, base: "/",
    makeUrl: url_CancelSigningProfile_21626048,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSigningJob_21626060 = ref object of OpenApiRestCall_21625435
proc url_DescribeSigningJob_21626062(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "jobId" in path, "`jobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/signing-jobs/"),
               (kind: VariableSegment, value: "jobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeSigningJob_21626061(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about a specific code signing job. You specify the job by using the <code>jobId</code> value that is returned by the <a>StartSigningJob</a> operation. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   jobId: JString (required)
  ##        : The ID of the signing job on input.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `jobId` field"
  var valid_21626063 = path.getOrDefault("jobId")
  valid_21626063 = validateParameter(valid_21626063, JString, required = true,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "jobId", valid_21626063
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
  var valid_21626064 = header.getOrDefault("X-Amz-Date")
  valid_21626064 = validateParameter(valid_21626064, JString, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "X-Amz-Date", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Security-Token", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Algorithm", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-Signature")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-Signature", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626069
  var valid_21626070 = header.getOrDefault("X-Amz-Credential")
  valid_21626070 = validateParameter(valid_21626070, JString, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "X-Amz-Credential", valid_21626070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626071: Call_DescribeSigningJob_21626060; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specific code signing job. You specify the job by using the <code>jobId</code> value that is returned by the <a>StartSigningJob</a> operation. 
  ## 
  let valid = call_21626071.validator(path, query, header, formData, body, _)
  let scheme = call_21626071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626071.makeUrl(scheme.get, call_21626071.host, call_21626071.base,
                               call_21626071.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626071, uri, valid, _)

proc call*(call_21626072: Call_DescribeSigningJob_21626060; jobId: string): Recallable =
  ## describeSigningJob
  ## Returns information about a specific code signing job. You specify the job by using the <code>jobId</code> value that is returned by the <a>StartSigningJob</a> operation. 
  ##   jobId: string (required)
  ##        : The ID of the signing job on input.
  var path_21626073 = newJObject()
  add(path_21626073, "jobId", newJString(jobId))
  result = call_21626072.call(path_21626073, nil, nil, nil, nil)

var describeSigningJob* = Call_DescribeSigningJob_21626060(
    name: "describeSigningJob", meth: HttpMethod.HttpGet,
    host: "signer.amazonaws.com", route: "/signing-jobs/{jobId}",
    validator: validate_DescribeSigningJob_21626061, base: "/",
    makeUrl: url_DescribeSigningJob_21626062, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSigningPlatform_21626074 = ref object of OpenApiRestCall_21625435
proc url_GetSigningPlatform_21626076(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "platformId" in path, "`platformId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/signing-platforms/"),
               (kind: VariableSegment, value: "platformId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSigningPlatform_21626075(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information on a specific signing platform.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   platformId: JString (required)
  ##             : The ID of the target signing platform.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `platformId` field"
  var valid_21626077 = path.getOrDefault("platformId")
  valid_21626077 = validateParameter(valid_21626077, JString, required = true,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "platformId", valid_21626077
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
  var valid_21626078 = header.getOrDefault("X-Amz-Date")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Date", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "X-Amz-Security-Token", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Algorithm", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Signature")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Signature", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Credential")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Credential", valid_21626084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626085: Call_GetSigningPlatform_21626074; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information on a specific signing platform.
  ## 
  let valid = call_21626085.validator(path, query, header, formData, body, _)
  let scheme = call_21626085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626085.makeUrl(scheme.get, call_21626085.host, call_21626085.base,
                               call_21626085.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626085, uri, valid, _)

proc call*(call_21626086: Call_GetSigningPlatform_21626074; platformId: string): Recallable =
  ## getSigningPlatform
  ## Returns information on a specific signing platform.
  ##   platformId: string (required)
  ##             : The ID of the target signing platform.
  var path_21626087 = newJObject()
  add(path_21626087, "platformId", newJString(platformId))
  result = call_21626086.call(path_21626087, nil, nil, nil, nil)

var getSigningPlatform* = Call_GetSigningPlatform_21626074(
    name: "getSigningPlatform", meth: HttpMethod.HttpGet,
    host: "signer.amazonaws.com", route: "/signing-platforms/{platformId}",
    validator: validate_GetSigningPlatform_21626075, base: "/",
    makeUrl: url_GetSigningPlatform_21626076, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSigningJob_21626122 = ref object of OpenApiRestCall_21625435
proc url_StartSigningJob_21626124(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartSigningJob_21626123(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Initiates a signing job to be performed on the code provided. Signing jobs are viewable by the <code>ListSigningJobs</code> operation for two years after they are performed. Note the following requirements: </p> <ul> <li> <p> You must create an Amazon S3 source bucket. For more information, see <a href="http://docs.aws.amazon.com/AmazonS3/latest/gsg/CreatingABucket.html">Create a Bucket</a> in the <i>Amazon S3 Getting Started Guide</i>. </p> </li> <li> <p>Your S3 source bucket must be version enabled.</p> </li> <li> <p>You must create an S3 destination bucket. Code signing uses your S3 destination bucket to write your signed code.</p> </li> <li> <p>You specify the name of the source and destination buckets when calling the <code>StartSigningJob</code> operation.</p> </li> <li> <p>You must also specify a request token that identifies your request to code signing.</p> </li> </ul> <p>You can call the <a>DescribeSigningJob</a> and the <a>ListSigningJobs</a> actions after you call <code>StartSigningJob</code>.</p> <p>For a Java example that shows how to use this action, see <a href="http://docs.aws.amazon.com/acm/latest/userguide/">http://docs.aws.amazon.com/acm/latest/userguide/</a> </p>
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
  var valid_21626125 = header.getOrDefault("X-Amz-Date")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Date", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Security-Token", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-Algorithm", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Signature")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Signature", valid_21626129
  var valid_21626130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626130 = validateParameter(valid_21626130, JString, required = false,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626130
  var valid_21626131 = header.getOrDefault("X-Amz-Credential")
  valid_21626131 = validateParameter(valid_21626131, JString, required = false,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "X-Amz-Credential", valid_21626131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626133: Call_StartSigningJob_21626122; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Initiates a signing job to be performed on the code provided. Signing jobs are viewable by the <code>ListSigningJobs</code> operation for two years after they are performed. Note the following requirements: </p> <ul> <li> <p> You must create an Amazon S3 source bucket. For more information, see <a href="http://docs.aws.amazon.com/AmazonS3/latest/gsg/CreatingABucket.html">Create a Bucket</a> in the <i>Amazon S3 Getting Started Guide</i>. </p> </li> <li> <p>Your S3 source bucket must be version enabled.</p> </li> <li> <p>You must create an S3 destination bucket. Code signing uses your S3 destination bucket to write your signed code.</p> </li> <li> <p>You specify the name of the source and destination buckets when calling the <code>StartSigningJob</code> operation.</p> </li> <li> <p>You must also specify a request token that identifies your request to code signing.</p> </li> </ul> <p>You can call the <a>DescribeSigningJob</a> and the <a>ListSigningJobs</a> actions after you call <code>StartSigningJob</code>.</p> <p>For a Java example that shows how to use this action, see <a href="http://docs.aws.amazon.com/acm/latest/userguide/">http://docs.aws.amazon.com/acm/latest/userguide/</a> </p>
  ## 
  let valid = call_21626133.validator(path, query, header, formData, body, _)
  let scheme = call_21626133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626133.makeUrl(scheme.get, call_21626133.host, call_21626133.base,
                               call_21626133.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626133, uri, valid, _)

proc call*(call_21626134: Call_StartSigningJob_21626122; body: JsonNode): Recallable =
  ## startSigningJob
  ## <p>Initiates a signing job to be performed on the code provided. Signing jobs are viewable by the <code>ListSigningJobs</code> operation for two years after they are performed. Note the following requirements: </p> <ul> <li> <p> You must create an Amazon S3 source bucket. For more information, see <a href="http://docs.aws.amazon.com/AmazonS3/latest/gsg/CreatingABucket.html">Create a Bucket</a> in the <i>Amazon S3 Getting Started Guide</i>. </p> </li> <li> <p>Your S3 source bucket must be version enabled.</p> </li> <li> <p>You must create an S3 destination bucket. Code signing uses your S3 destination bucket to write your signed code.</p> </li> <li> <p>You specify the name of the source and destination buckets when calling the <code>StartSigningJob</code> operation.</p> </li> <li> <p>You must also specify a request token that identifies your request to code signing.</p> </li> </ul> <p>You can call the <a>DescribeSigningJob</a> and the <a>ListSigningJobs</a> actions after you call <code>StartSigningJob</code>.</p> <p>For a Java example that shows how to use this action, see <a href="http://docs.aws.amazon.com/acm/latest/userguide/">http://docs.aws.amazon.com/acm/latest/userguide/</a> </p>
  ##   body: JObject (required)
  var body_21626135 = newJObject()
  if body != nil:
    body_21626135 = body
  result = call_21626134.call(nil, nil, nil, nil, body_21626135)

var startSigningJob* = Call_StartSigningJob_21626122(name: "startSigningJob",
    meth: HttpMethod.HttpPost, host: "signer.amazonaws.com", route: "/signing-jobs",
    validator: validate_StartSigningJob_21626123, base: "/",
    makeUrl: url_StartSigningJob_21626124, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSigningJobs_21626088 = ref object of OpenApiRestCall_21625435
proc url_ListSigningJobs_21626090(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSigningJobs_21626089(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists all your signing jobs. You can use the <code>maxResults</code> parameter to limit the number of signing jobs that are returned in the response. If additional jobs remain to be listed, code signing returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that code signing returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   platformId: JString
  ##             : The ID of microcontroller platform that you specified for the distribution of your code image.
  ##   requestedBy: JString
  ##              : The IAM principal that requested the signing job.
  ##   maxResults: JInt
  ##             : Specifies the maximum number of items to return in the response. Use this parameter when paginating results. If additional items exist beyond the number you specify, the <code>nextToken</code> element is set in the response. Use the <code>nextToken</code> value in a subsequent request to retrieve additional items. 
  ##   nextToken: JString
  ##            : String for specifying the next set of paginated results to return. After you receive a response with truncated results, use this parameter in a subsequent request. Set it to the value of <code>nextToken</code> from the response that you just received.
  ##   status: JString
  ##         : A status value with which to filter your results.
  section = newJObject()
  var valid_21626091 = query.getOrDefault("platformId")
  valid_21626091 = validateParameter(valid_21626091, JString, required = false,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "platformId", valid_21626091
  var valid_21626092 = query.getOrDefault("requestedBy")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "requestedBy", valid_21626092
  var valid_21626093 = query.getOrDefault("maxResults")
  valid_21626093 = validateParameter(valid_21626093, JInt, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "maxResults", valid_21626093
  var valid_21626094 = query.getOrDefault("nextToken")
  valid_21626094 = validateParameter(valid_21626094, JString, required = false,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "nextToken", valid_21626094
  var valid_21626109 = query.getOrDefault("status")
  valid_21626109 = validateParameter(valid_21626109, JString, required = false,
                                   default = newJString("InProgress"))
  if valid_21626109 != nil:
    section.add "status", valid_21626109
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
  var valid_21626110 = header.getOrDefault("X-Amz-Date")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Date", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-Security-Token", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-Algorithm", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Signature")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Signature", valid_21626114
  var valid_21626115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626115
  var valid_21626116 = header.getOrDefault("X-Amz-Credential")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "X-Amz-Credential", valid_21626116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626117: Call_ListSigningJobs_21626088; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all your signing jobs. You can use the <code>maxResults</code> parameter to limit the number of signing jobs that are returned in the response. If additional jobs remain to be listed, code signing returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that code signing returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned. 
  ## 
  let valid = call_21626117.validator(path, query, header, formData, body, _)
  let scheme = call_21626117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626117.makeUrl(scheme.get, call_21626117.host, call_21626117.base,
                               call_21626117.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626117, uri, valid, _)

proc call*(call_21626118: Call_ListSigningJobs_21626088; platformId: string = "";
          requestedBy: string = ""; maxResults: int = 0; nextToken: string = "";
          status: string = "InProgress"): Recallable =
  ## listSigningJobs
  ## Lists all your signing jobs. You can use the <code>maxResults</code> parameter to limit the number of signing jobs that are returned in the response. If additional jobs remain to be listed, code signing returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that code signing returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned. 
  ##   platformId: string
  ##             : The ID of microcontroller platform that you specified for the distribution of your code image.
  ##   requestedBy: string
  ##              : The IAM principal that requested the signing job.
  ##   maxResults: int
  ##             : Specifies the maximum number of items to return in the response. Use this parameter when paginating results. If additional items exist beyond the number you specify, the <code>nextToken</code> element is set in the response. Use the <code>nextToken</code> value in a subsequent request to retrieve additional items. 
  ##   nextToken: string
  ##            : String for specifying the next set of paginated results to return. After you receive a response with truncated results, use this parameter in a subsequent request. Set it to the value of <code>nextToken</code> from the response that you just received.
  ##   status: string
  ##         : A status value with which to filter your results.
  var query_21626119 = newJObject()
  add(query_21626119, "platformId", newJString(platformId))
  add(query_21626119, "requestedBy", newJString(requestedBy))
  add(query_21626119, "maxResults", newJInt(maxResults))
  add(query_21626119, "nextToken", newJString(nextToken))
  add(query_21626119, "status", newJString(status))
  result = call_21626118.call(nil, query_21626119, nil, nil, nil)

var listSigningJobs* = Call_ListSigningJobs_21626088(name: "listSigningJobs",
    meth: HttpMethod.HttpGet, host: "signer.amazonaws.com", route: "/signing-jobs",
    validator: validate_ListSigningJobs_21626089, base: "/",
    makeUrl: url_ListSigningJobs_21626090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSigningPlatforms_21626136 = ref object of OpenApiRestCall_21625435
proc url_ListSigningPlatforms_21626138(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSigningPlatforms_21626137(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists all signing platforms available in code signing that match the request parameters. If additional jobs remain to be listed, code signing returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that code signing returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   target: JString
  ##         : The validation template that is used by the target signing platform.
  ##   maxResults: JInt
  ##             : The maximum number of results to be returned by this operation.
  ##   nextToken: JString
  ##            : Value for specifying the next set of paginated results to return. After you receive a response with truncated results, use this parameter in a subsequent request. Set it to the value of <code>nextToken</code> from the response that you just received.
  ##   partner: JString
  ##          : Any partner entities connected to a signing platform.
  ##   category: JString
  ##           : The category type of a signing platform.
  section = newJObject()
  var valid_21626139 = query.getOrDefault("target")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "target", valid_21626139
  var valid_21626140 = query.getOrDefault("maxResults")
  valid_21626140 = validateParameter(valid_21626140, JInt, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "maxResults", valid_21626140
  var valid_21626141 = query.getOrDefault("nextToken")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "nextToken", valid_21626141
  var valid_21626142 = query.getOrDefault("partner")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "partner", valid_21626142
  var valid_21626143 = query.getOrDefault("category")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "category", valid_21626143
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
  var valid_21626144 = header.getOrDefault("X-Amz-Date")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Date", valid_21626144
  var valid_21626145 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "X-Amz-Security-Token", valid_21626145
  var valid_21626146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626146 = validateParameter(valid_21626146, JString, required = false,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626146
  var valid_21626147 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626147 = validateParameter(valid_21626147, JString, required = false,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "X-Amz-Algorithm", valid_21626147
  var valid_21626148 = header.getOrDefault("X-Amz-Signature")
  valid_21626148 = validateParameter(valid_21626148, JString, required = false,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "X-Amz-Signature", valid_21626148
  var valid_21626149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626149 = validateParameter(valid_21626149, JString, required = false,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626149
  var valid_21626150 = header.getOrDefault("X-Amz-Credential")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "X-Amz-Credential", valid_21626150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626151: Call_ListSigningPlatforms_21626136; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all signing platforms available in code signing that match the request parameters. If additional jobs remain to be listed, code signing returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that code signing returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
  ## 
  let valid = call_21626151.validator(path, query, header, formData, body, _)
  let scheme = call_21626151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626151.makeUrl(scheme.get, call_21626151.host, call_21626151.base,
                               call_21626151.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626151, uri, valid, _)

proc call*(call_21626152: Call_ListSigningPlatforms_21626136; target: string = "";
          maxResults: int = 0; nextToken: string = ""; partner: string = "";
          category: string = ""): Recallable =
  ## listSigningPlatforms
  ## Lists all signing platforms available in code signing that match the request parameters. If additional jobs remain to be listed, code signing returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that code signing returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
  ##   target: string
  ##         : The validation template that is used by the target signing platform.
  ##   maxResults: int
  ##             : The maximum number of results to be returned by this operation.
  ##   nextToken: string
  ##            : Value for specifying the next set of paginated results to return. After you receive a response with truncated results, use this parameter in a subsequent request. Set it to the value of <code>nextToken</code> from the response that you just received.
  ##   partner: string
  ##          : Any partner entities connected to a signing platform.
  ##   category: string
  ##           : The category type of a signing platform.
  var query_21626153 = newJObject()
  add(query_21626153, "target", newJString(target))
  add(query_21626153, "maxResults", newJInt(maxResults))
  add(query_21626153, "nextToken", newJString(nextToken))
  add(query_21626153, "partner", newJString(partner))
  add(query_21626153, "category", newJString(category))
  result = call_21626152.call(nil, query_21626153, nil, nil, nil)

var listSigningPlatforms* = Call_ListSigningPlatforms_21626136(
    name: "listSigningPlatforms", meth: HttpMethod.HttpGet,
    host: "signer.amazonaws.com", route: "/signing-platforms",
    validator: validate_ListSigningPlatforms_21626137, base: "/",
    makeUrl: url_ListSigningPlatforms_21626138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSigningProfiles_21626154 = ref object of OpenApiRestCall_21625435
proc url_ListSigningProfiles_21626156(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSigningProfiles_21626155(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists all available signing profiles in your AWS account. Returns only profiles with an <code>ACTIVE</code> status unless the <code>includeCanceled</code> request field is set to <code>true</code>. If additional jobs remain to be listed, code signing returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that code signing returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of profiles to be returned.
  ##   nextToken: JString
  ##            : Value for specifying the next set of paginated results to return. After you receive a response with truncated results, use this parameter in a subsequent request. Set it to the value of <code>nextToken</code> from the response that you just received.
  ##   includeCanceled: JBool
  ##                  : Designates whether to include profiles with the status of <code>CANCELED</code>.
  section = newJObject()
  var valid_21626157 = query.getOrDefault("maxResults")
  valid_21626157 = validateParameter(valid_21626157, JInt, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "maxResults", valid_21626157
  var valid_21626158 = query.getOrDefault("nextToken")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "nextToken", valid_21626158
  var valid_21626159 = query.getOrDefault("includeCanceled")
  valid_21626159 = validateParameter(valid_21626159, JBool, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "includeCanceled", valid_21626159
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
  var valid_21626160 = header.getOrDefault("X-Amz-Date")
  valid_21626160 = validateParameter(valid_21626160, JString, required = false,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "X-Amz-Date", valid_21626160
  var valid_21626161 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "X-Amz-Security-Token", valid_21626161
  var valid_21626162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626162 = validateParameter(valid_21626162, JString, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626162
  var valid_21626163 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626163 = validateParameter(valid_21626163, JString, required = false,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "X-Amz-Algorithm", valid_21626163
  var valid_21626164 = header.getOrDefault("X-Amz-Signature")
  valid_21626164 = validateParameter(valid_21626164, JString, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "X-Amz-Signature", valid_21626164
  var valid_21626165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626165
  var valid_21626166 = header.getOrDefault("X-Amz-Credential")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "X-Amz-Credential", valid_21626166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626167: Call_ListSigningProfiles_21626154; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all available signing profiles in your AWS account. Returns only profiles with an <code>ACTIVE</code> status unless the <code>includeCanceled</code> request field is set to <code>true</code>. If additional jobs remain to be listed, code signing returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that code signing returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
  ## 
  let valid = call_21626167.validator(path, query, header, formData, body, _)
  let scheme = call_21626167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626167.makeUrl(scheme.get, call_21626167.host, call_21626167.base,
                               call_21626167.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626167, uri, valid, _)

proc call*(call_21626168: Call_ListSigningProfiles_21626154; maxResults: int = 0;
          nextToken: string = ""; includeCanceled: bool = false): Recallable =
  ## listSigningProfiles
  ## Lists all available signing profiles in your AWS account. Returns only profiles with an <code>ACTIVE</code> status unless the <code>includeCanceled</code> request field is set to <code>true</code>. If additional jobs remain to be listed, code signing returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that code signing returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
  ##   maxResults: int
  ##             : The maximum number of profiles to be returned.
  ##   nextToken: string
  ##            : Value for specifying the next set of paginated results to return. After you receive a response with truncated results, use this parameter in a subsequent request. Set it to the value of <code>nextToken</code> from the response that you just received.
  ##   includeCanceled: bool
  ##                  : Designates whether to include profiles with the status of <code>CANCELED</code>.
  var query_21626169 = newJObject()
  add(query_21626169, "maxResults", newJInt(maxResults))
  add(query_21626169, "nextToken", newJString(nextToken))
  add(query_21626169, "includeCanceled", newJBool(includeCanceled))
  result = call_21626168.call(nil, query_21626169, nil, nil, nil)

var listSigningProfiles* = Call_ListSigningProfiles_21626154(
    name: "listSigningProfiles", meth: HttpMethod.HttpGet,
    host: "signer.amazonaws.com", route: "/signing-profiles",
    validator: validate_ListSigningProfiles_21626155, base: "/",
    makeUrl: url_ListSigningProfiles_21626156,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626184 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21626186(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_21626185(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds one or more tags to a signing profile. Tags are labels that you can use to identify and organize your AWS resources. Each tag consists of a key and an optional value. You specify the signing profile using its Amazon Resource Name (ARN). You specify the tag by using a key-value pair.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : Amazon Resource Name (ARN) for the signing profile.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_21626187 = path.getOrDefault("resourceArn")
  valid_21626187 = validateParameter(valid_21626187, JString, required = true,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "resourceArn", valid_21626187
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
  var valid_21626188 = header.getOrDefault("X-Amz-Date")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-Date", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Security-Token", valid_21626189
  var valid_21626190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626190
  var valid_21626191 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626191 = validateParameter(valid_21626191, JString, required = false,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "X-Amz-Algorithm", valid_21626191
  var valid_21626192 = header.getOrDefault("X-Amz-Signature")
  valid_21626192 = validateParameter(valid_21626192, JString, required = false,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "X-Amz-Signature", valid_21626192
  var valid_21626193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626193 = validateParameter(valid_21626193, JString, required = false,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626193
  var valid_21626194 = header.getOrDefault("X-Amz-Credential")
  valid_21626194 = validateParameter(valid_21626194, JString, required = false,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "X-Amz-Credential", valid_21626194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626196: Call_TagResource_21626184; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds one or more tags to a signing profile. Tags are labels that you can use to identify and organize your AWS resources. Each tag consists of a key and an optional value. You specify the signing profile using its Amazon Resource Name (ARN). You specify the tag by using a key-value pair.
  ## 
  let valid = call_21626196.validator(path, query, header, formData, body, _)
  let scheme = call_21626196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626196.makeUrl(scheme.get, call_21626196.host, call_21626196.base,
                               call_21626196.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626196, uri, valid, _)

proc call*(call_21626197: Call_TagResource_21626184; body: JsonNode;
          resourceArn: string): Recallable =
  ## tagResource
  ## Adds one or more tags to a signing profile. Tags are labels that you can use to identify and organize your AWS resources. Each tag consists of a key and an optional value. You specify the signing profile using its Amazon Resource Name (ARN). You specify the tag by using a key-value pair.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : Amazon Resource Name (ARN) for the signing profile.
  var path_21626198 = newJObject()
  var body_21626199 = newJObject()
  if body != nil:
    body_21626199 = body
  add(path_21626198, "resourceArn", newJString(resourceArn))
  result = call_21626197.call(path_21626198, nil, nil, nil, body_21626199)

var tagResource* = Call_TagResource_21626184(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "signer.amazonaws.com",
    route: "/tags/{resourceArn}", validator: validate_TagResource_21626185,
    base: "/", makeUrl: url_TagResource_21626186,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626170 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource_21626172(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_21626171(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of the tags associated with a signing profile resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) for the signing profile.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_21626173 = path.getOrDefault("resourceArn")
  valid_21626173 = validateParameter(valid_21626173, JString, required = true,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "resourceArn", valid_21626173
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
  var valid_21626174 = header.getOrDefault("X-Amz-Date")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Date", valid_21626174
  var valid_21626175 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626175 = validateParameter(valid_21626175, JString, required = false,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "X-Amz-Security-Token", valid_21626175
  var valid_21626176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626176 = validateParameter(valid_21626176, JString, required = false,
                                   default = nil)
  if valid_21626176 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626176
  var valid_21626177 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626177 = validateParameter(valid_21626177, JString, required = false,
                                   default = nil)
  if valid_21626177 != nil:
    section.add "X-Amz-Algorithm", valid_21626177
  var valid_21626178 = header.getOrDefault("X-Amz-Signature")
  valid_21626178 = validateParameter(valid_21626178, JString, required = false,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "X-Amz-Signature", valid_21626178
  var valid_21626179 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626179 = validateParameter(valid_21626179, JString, required = false,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626179
  var valid_21626180 = header.getOrDefault("X-Amz-Credential")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "X-Amz-Credential", valid_21626180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626181: Call_ListTagsForResource_21626170; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the tags associated with a signing profile resource.
  ## 
  let valid = call_21626181.validator(path, query, header, formData, body, _)
  let scheme = call_21626181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626181.makeUrl(scheme.get, call_21626181.host, call_21626181.base,
                               call_21626181.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626181, uri, valid, _)

proc call*(call_21626182: Call_ListTagsForResource_21626170; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns a list of the tags associated with a signing profile resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the signing profile.
  var path_21626183 = newJObject()
  add(path_21626183, "resourceArn", newJString(resourceArn))
  result = call_21626182.call(path_21626183, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_21626170(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "signer.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_21626171, base: "/",
    makeUrl: url_ListTagsForResource_21626172,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626200 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21626202(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_21626201(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Remove one or more tags from a signing profile. Specify a list of tag keys to remove the tags.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : Amazon Resource Name (ARN) for the signing profile .
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_21626203 = path.getOrDefault("resourceArn")
  valid_21626203 = validateParameter(valid_21626203, JString, required = true,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "resourceArn", valid_21626203
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A list of tag keys to be removed from the signing profile .
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_21626204 = query.getOrDefault("tagKeys")
  valid_21626204 = validateParameter(valid_21626204, JArray, required = true,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "tagKeys", valid_21626204
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
  var valid_21626205 = header.getOrDefault("X-Amz-Date")
  valid_21626205 = validateParameter(valid_21626205, JString, required = false,
                                   default = nil)
  if valid_21626205 != nil:
    section.add "X-Amz-Date", valid_21626205
  var valid_21626206 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626206 = validateParameter(valid_21626206, JString, required = false,
                                   default = nil)
  if valid_21626206 != nil:
    section.add "X-Amz-Security-Token", valid_21626206
  var valid_21626207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626207 = validateParameter(valid_21626207, JString, required = false,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626207
  var valid_21626208 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626208 = validateParameter(valid_21626208, JString, required = false,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "X-Amz-Algorithm", valid_21626208
  var valid_21626209 = header.getOrDefault("X-Amz-Signature")
  valid_21626209 = validateParameter(valid_21626209, JString, required = false,
                                   default = nil)
  if valid_21626209 != nil:
    section.add "X-Amz-Signature", valid_21626209
  var valid_21626210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626210 = validateParameter(valid_21626210, JString, required = false,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626210
  var valid_21626211 = header.getOrDefault("X-Amz-Credential")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "X-Amz-Credential", valid_21626211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626212: Call_UntagResource_21626200; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Remove one or more tags from a signing profile. Specify a list of tag keys to remove the tags.
  ## 
  let valid = call_21626212.validator(path, query, header, formData, body, _)
  let scheme = call_21626212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626212.makeUrl(scheme.get, call_21626212.host, call_21626212.base,
                               call_21626212.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626212, uri, valid, _)

proc call*(call_21626213: Call_UntagResource_21626200; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Remove one or more tags from a signing profile. Specify a list of tag keys to remove the tags.
  ##   tagKeys: JArray (required)
  ##          : A list of tag keys to be removed from the signing profile .
  ##   resourceArn: string (required)
  ##              : Amazon Resource Name (ARN) for the signing profile .
  var path_21626214 = newJObject()
  var query_21626215 = newJObject()
  if tagKeys != nil:
    query_21626215.add "tagKeys", tagKeys
  add(path_21626214, "resourceArn", newJString(resourceArn))
  result = call_21626213.call(path_21626214, query_21626215, nil, nil, nil)

var untagResource* = Call_UntagResource_21626200(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "signer.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_21626201,
    base: "/", makeUrl: url_UntagResource_21626202,
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}