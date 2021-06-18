
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
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

  OpenApiRestCall_402656038 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656038](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656038): Option[Scheme] {.used.} =
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "signer.ap-northeast-1.amazonaws.com", "ap-southeast-1": "signer.ap-southeast-1.amazonaws.com",
                               "us-west-2": "signer.us-west-2.amazonaws.com",
                               "eu-west-2": "signer.eu-west-2.amazonaws.com", "ap-northeast-3": "signer.ap-northeast-3.amazonaws.com", "eu-central-1": "signer.eu-central-1.amazonaws.com",
                               "us-east-2": "signer.us-east-2.amazonaws.com",
                               "us-east-1": "signer.us-east-1.amazonaws.com", "cn-northwest-1": "signer.cn-northwest-1.amazonaws.com.cn",
                               "ap-south-1": "signer.ap-south-1.amazonaws.com",
                               "eu-north-1": "signer.eu-north-1.amazonaws.com", "ap-northeast-2": "signer.ap-northeast-2.amazonaws.com",
                               "us-west-1": "signer.us-west-1.amazonaws.com", "us-gov-east-1": "signer.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "signer.eu-west-3.amazonaws.com", "cn-north-1": "signer.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "signer.sa-east-1.amazonaws.com",
                               "eu-west-1": "signer.eu-west-1.amazonaws.com", "us-gov-west-1": "signer.us-gov-west-1.amazonaws.com", "ap-southeast-2": "signer.ap-southeast-2.amazonaws.com", "ca-central-1": "signer.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_PutSigningProfile_402656481 = ref object of OpenApiRestCall_402656038
proc url_PutSigningProfile_402656483(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
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

proc validate_PutSigningProfile_402656482(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656484 = path.getOrDefault("profileName")
  valid_402656484 = validateParameter(valid_402656484, JString, required = true,
                                      default = nil)
  if valid_402656484 != nil:
    section.add "profileName", valid_402656484
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656485 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-Security-Token", valid_402656485
  var valid_402656486 = header.getOrDefault("X-Amz-Signature")
  valid_402656486 = validateParameter(valid_402656486, JString,
                                      required = false, default = nil)
  if valid_402656486 != nil:
    section.add "X-Amz-Signature", valid_402656486
  var valid_402656487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656487
  var valid_402656488 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "X-Amz-Algorithm", valid_402656488
  var valid_402656489 = header.getOrDefault("X-Amz-Date")
  valid_402656489 = validateParameter(valid_402656489, JString,
                                      required = false, default = nil)
  if valid_402656489 != nil:
    section.add "X-Amz-Date", valid_402656489
  var valid_402656490 = header.getOrDefault("X-Amz-Credential")
  valid_402656490 = validateParameter(valid_402656490, JString,
                                      required = false, default = nil)
  if valid_402656490 != nil:
    section.add "X-Amz-Credential", valid_402656490
  var valid_402656491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656491
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

proc call*(call_402656493: Call_PutSigningProfile_402656481;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a signing profile. A signing profile is a code signing template that can be used to carry out a pre-defined signing job. For more information, see <a href="http://docs.aws.amazon.com/signer/latest/developerguide/gs-profile.html">http://docs.aws.amazon.com/signer/latest/developerguide/gs-profile.html</a> 
                                                                                         ## 
  let valid = call_402656493.validator(path, query, header, formData, body, _)
  let scheme = call_402656493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656493.makeUrl(scheme.get, call_402656493.host, call_402656493.base,
                                   call_402656493.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656493, uri, valid, _)

proc call*(call_402656494: Call_PutSigningProfile_402656481; body: JsonNode;
           profileName: string): Recallable =
  ## putSigningProfile
  ## Creates a signing profile. A signing profile is a code signing template that can be used to carry out a pre-defined signing job. For more information, see <a href="http://docs.aws.amazon.com/signer/latest/developerguide/gs-profile.html">http://docs.aws.amazon.com/signer/latest/developerguide/gs-profile.html</a> 
  ##   
                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                         ## profileName: string (required)
                                                                                                                                                                                                                                                                                                                                                         ##              
                                                                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                                                                         ## The 
                                                                                                                                                                                                                                                                                                                                                         ## name 
                                                                                                                                                                                                                                                                                                                                                         ## of 
                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                         ## signing 
                                                                                                                                                                                                                                                                                                                                                         ## profile 
                                                                                                                                                                                                                                                                                                                                                         ## to 
                                                                                                                                                                                                                                                                                                                                                         ## be 
                                                                                                                                                                                                                                                                                                                                                         ## created.
  var path_402656495 = newJObject()
  var body_402656496 = newJObject()
  if body != nil:
    body_402656496 = body
  add(path_402656495, "profileName", newJString(profileName))
  result = call_402656494.call(path_402656495, nil, nil, nil, body_402656496)

var putSigningProfile* = Call_PutSigningProfile_402656481(
    name: "putSigningProfile", meth: HttpMethod.HttpPut,
    host: "signer.amazonaws.com", route: "/signing-profiles/{profileName}",
    validator: validate_PutSigningProfile_402656482, base: "/",
    makeUrl: url_PutSigningProfile_402656483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSigningProfile_402656288 = ref object of OpenApiRestCall_402656038
proc url_GetSigningProfile_402656290(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetSigningProfile_402656289(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656380 = path.getOrDefault("profileName")
  valid_402656380 = validateParameter(valid_402656380, JString, required = true,
                                      default = nil)
  if valid_402656380 != nil:
    section.add "profileName", valid_402656380
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656381 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "X-Amz-Security-Token", valid_402656381
  var valid_402656382 = header.getOrDefault("X-Amz-Signature")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "X-Amz-Signature", valid_402656382
  var valid_402656383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656383
  var valid_402656384 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656384 = validateParameter(valid_402656384, JString,
                                      required = false, default = nil)
  if valid_402656384 != nil:
    section.add "X-Amz-Algorithm", valid_402656384
  var valid_402656385 = header.getOrDefault("X-Amz-Date")
  valid_402656385 = validateParameter(valid_402656385, JString,
                                      required = false, default = nil)
  if valid_402656385 != nil:
    section.add "X-Amz-Date", valid_402656385
  var valid_402656386 = header.getOrDefault("X-Amz-Credential")
  valid_402656386 = validateParameter(valid_402656386, JString,
                                      required = false, default = nil)
  if valid_402656386 != nil:
    section.add "X-Amz-Credential", valid_402656386
  var valid_402656387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656401: Call_GetSigningProfile_402656288;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information on a specific signing profile.
                                                                                         ## 
  let valid = call_402656401.validator(path, query, header, formData, body, _)
  let scheme = call_402656401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656401.makeUrl(scheme.get, call_402656401.host, call_402656401.base,
                                   call_402656401.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656401, uri, valid, _)

proc call*(call_402656450: Call_GetSigningProfile_402656288; profileName: string): Recallable =
  ## getSigningProfile
  ## Returns information on a specific signing profile.
  ##   profileName: string (required)
                                                       ##              : The name of the target signing profile.
  var path_402656451 = newJObject()
  add(path_402656451, "profileName", newJString(profileName))
  result = call_402656450.call(path_402656451, nil, nil, nil, nil)

var getSigningProfile* = Call_GetSigningProfile_402656288(
    name: "getSigningProfile", meth: HttpMethod.HttpGet,
    host: "signer.amazonaws.com", route: "/signing-profiles/{profileName}",
    validator: validate_GetSigningProfile_402656289, base: "/",
    makeUrl: url_GetSigningProfile_402656290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelSigningProfile_402656497 = ref object of OpenApiRestCall_402656038
proc url_CancelSigningProfile_402656499(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
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

proc validate_CancelSigningProfile_402656498(path: JsonNode; query: JsonNode;
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
  var valid_402656500 = path.getOrDefault("profileName")
  valid_402656500 = validateParameter(valid_402656500, JString, required = true,
                                      default = nil)
  if valid_402656500 != nil:
    section.add "profileName", valid_402656500
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656501 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "X-Amz-Security-Token", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-Signature")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-Signature", valid_402656502
  var valid_402656503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Algorithm", valid_402656504
  var valid_402656505 = header.getOrDefault("X-Amz-Date")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-Date", valid_402656505
  var valid_402656506 = header.getOrDefault("X-Amz-Credential")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Credential", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656508: Call_CancelSigningProfile_402656497;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Changes the state of an <code>ACTIVE</code> signing profile to <code>CANCELED</code>. A canceled profile is still viewable with the <code>ListSigningProfiles</code> operation, but it cannot perform new signing jobs, and is deleted two years after cancelation.
                                                                                         ## 
  let valid = call_402656508.validator(path, query, header, formData, body, _)
  let scheme = call_402656508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656508.makeUrl(scheme.get, call_402656508.host, call_402656508.base,
                                   call_402656508.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656508, uri, valid, _)

proc call*(call_402656509: Call_CancelSigningProfile_402656497;
           profileName: string): Recallable =
  ## cancelSigningProfile
  ## Changes the state of an <code>ACTIVE</code> signing profile to <code>CANCELED</code>. A canceled profile is still viewable with the <code>ListSigningProfiles</code> operation, but it cannot perform new signing jobs, and is deleted two years after cancelation.
  ##   
                                                                                                                                                                                                                                                                        ## profileName: string (required)
                                                                                                                                                                                                                                                                        ##              
                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                                                                                        ## name 
                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                        ## signing 
                                                                                                                                                                                                                                                                        ## profile 
                                                                                                                                                                                                                                                                        ## to 
                                                                                                                                                                                                                                                                        ## be 
                                                                                                                                                                                                                                                                        ## canceled.
  var path_402656510 = newJObject()
  add(path_402656510, "profileName", newJString(profileName))
  result = call_402656509.call(path_402656510, nil, nil, nil, nil)

var cancelSigningProfile* = Call_CancelSigningProfile_402656497(
    name: "cancelSigningProfile", meth: HttpMethod.HttpDelete,
    host: "signer.amazonaws.com", route: "/signing-profiles/{profileName}",
    validator: validate_CancelSigningProfile_402656498, base: "/",
    makeUrl: url_CancelSigningProfile_402656499,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSigningJob_402656511 = ref object of OpenApiRestCall_402656038
proc url_DescribeSigningJob_402656513(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
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

proc validate_DescribeSigningJob_402656512(path: JsonNode; query: JsonNode;
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
  var valid_402656514 = path.getOrDefault("jobId")
  valid_402656514 = validateParameter(valid_402656514, JString, required = true,
                                      default = nil)
  if valid_402656514 != nil:
    section.add "jobId", valid_402656514
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656515 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-Security-Token", valid_402656515
  var valid_402656516 = header.getOrDefault("X-Amz-Signature")
  valid_402656516 = validateParameter(valid_402656516, JString,
                                      required = false, default = nil)
  if valid_402656516 != nil:
    section.add "X-Amz-Signature", valid_402656516
  var valid_402656517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656517
  var valid_402656518 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "X-Amz-Algorithm", valid_402656518
  var valid_402656519 = header.getOrDefault("X-Amz-Date")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-Date", valid_402656519
  var valid_402656520 = header.getOrDefault("X-Amz-Credential")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-Credential", valid_402656520
  var valid_402656521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656522: Call_DescribeSigningJob_402656511;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specific code signing job. You specify the job by using the <code>jobId</code> value that is returned by the <a>StartSigningJob</a> operation. 
                                                                                         ## 
  let valid = call_402656522.validator(path, query, header, formData, body, _)
  let scheme = call_402656522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656522.makeUrl(scheme.get, call_402656522.host, call_402656522.base,
                                   call_402656522.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656522, uri, valid, _)

proc call*(call_402656523: Call_DescribeSigningJob_402656511; jobId: string): Recallable =
  ## describeSigningJob
  ## Returns information about a specific code signing job. You specify the job by using the <code>jobId</code> value that is returned by the <a>StartSigningJob</a> operation. 
  ##   
                                                                                                                                                                                ## jobId: string (required)
                                                                                                                                                                                ##        
                                                                                                                                                                                ## : 
                                                                                                                                                                                ## The 
                                                                                                                                                                                ## ID 
                                                                                                                                                                                ## of 
                                                                                                                                                                                ## the 
                                                                                                                                                                                ## signing 
                                                                                                                                                                                ## job 
                                                                                                                                                                                ## on 
                                                                                                                                                                                ## input.
  var path_402656524 = newJObject()
  add(path_402656524, "jobId", newJString(jobId))
  result = call_402656523.call(path_402656524, nil, nil, nil, nil)

var describeSigningJob* = Call_DescribeSigningJob_402656511(
    name: "describeSigningJob", meth: HttpMethod.HttpGet,
    host: "signer.amazonaws.com", route: "/signing-jobs/{jobId}",
    validator: validate_DescribeSigningJob_402656512, base: "/",
    makeUrl: url_DescribeSigningJob_402656513,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSigningPlatform_402656525 = ref object of OpenApiRestCall_402656038
proc url_GetSigningPlatform_402656527(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetSigningPlatform_402656526(path: JsonNode; query: JsonNode;
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
  var valid_402656528 = path.getOrDefault("platformId")
  valid_402656528 = validateParameter(valid_402656528, JString, required = true,
                                      default = nil)
  if valid_402656528 != nil:
    section.add "platformId", valid_402656528
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656529 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-Security-Token", valid_402656529
  var valid_402656530 = header.getOrDefault("X-Amz-Signature")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "X-Amz-Signature", valid_402656530
  var valid_402656531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656531 = validateParameter(valid_402656531, JString,
                                      required = false, default = nil)
  if valid_402656531 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656531
  var valid_402656532 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "X-Amz-Algorithm", valid_402656532
  var valid_402656533 = header.getOrDefault("X-Amz-Date")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-Date", valid_402656533
  var valid_402656534 = header.getOrDefault("X-Amz-Credential")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-Credential", valid_402656534
  var valid_402656535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656536: Call_GetSigningPlatform_402656525;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information on a specific signing platform.
                                                                                         ## 
  let valid = call_402656536.validator(path, query, header, formData, body, _)
  let scheme = call_402656536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656536.makeUrl(scheme.get, call_402656536.host, call_402656536.base,
                                   call_402656536.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656536, uri, valid, _)

proc call*(call_402656537: Call_GetSigningPlatform_402656525; platformId: string): Recallable =
  ## getSigningPlatform
  ## Returns information on a specific signing platform.
  ##   platformId: string (required)
                                                        ##             : The ID of the target signing platform.
  var path_402656538 = newJObject()
  add(path_402656538, "platformId", newJString(platformId))
  result = call_402656537.call(path_402656538, nil, nil, nil, nil)

var getSigningPlatform* = Call_GetSigningPlatform_402656525(
    name: "getSigningPlatform", meth: HttpMethod.HttpGet,
    host: "signer.amazonaws.com", route: "/signing-platforms/{platformId}",
    validator: validate_GetSigningPlatform_402656526, base: "/",
    makeUrl: url_GetSigningPlatform_402656527,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSigningJob_402656569 = ref object of OpenApiRestCall_402656038
proc url_StartSigningJob_402656571(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartSigningJob_402656570(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656572 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Security-Token", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Signature")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Signature", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656574
  var valid_402656575 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "X-Amz-Algorithm", valid_402656575
  var valid_402656576 = header.getOrDefault("X-Amz-Date")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "X-Amz-Date", valid_402656576
  var valid_402656577 = header.getOrDefault("X-Amz-Credential")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Credential", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656578
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

proc call*(call_402656580: Call_StartSigningJob_402656569; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Initiates a signing job to be performed on the code provided. Signing jobs are viewable by the <code>ListSigningJobs</code> operation for two years after they are performed. Note the following requirements: </p> <ul> <li> <p> You must create an Amazon S3 source bucket. For more information, see <a href="http://docs.aws.amazon.com/AmazonS3/latest/gsg/CreatingABucket.html">Create a Bucket</a> in the <i>Amazon S3 Getting Started Guide</i>. </p> </li> <li> <p>Your S3 source bucket must be version enabled.</p> </li> <li> <p>You must create an S3 destination bucket. Code signing uses your S3 destination bucket to write your signed code.</p> </li> <li> <p>You specify the name of the source and destination buckets when calling the <code>StartSigningJob</code> operation.</p> </li> <li> <p>You must also specify a request token that identifies your request to code signing.</p> </li> </ul> <p>You can call the <a>DescribeSigningJob</a> and the <a>ListSigningJobs</a> actions after you call <code>StartSigningJob</code>.</p> <p>For a Java example that shows how to use this action, see <a href="http://docs.aws.amazon.com/acm/latest/userguide/">http://docs.aws.amazon.com/acm/latest/userguide/</a> </p>
                                                                                         ## 
  let valid = call_402656580.validator(path, query, header, formData, body, _)
  let scheme = call_402656580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656580.makeUrl(scheme.get, call_402656580.host, call_402656580.base,
                                   call_402656580.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656580, uri, valid, _)

proc call*(call_402656581: Call_StartSigningJob_402656569; body: JsonNode): Recallable =
  ## startSigningJob
  ## <p>Initiates a signing job to be performed on the code provided. Signing jobs are viewable by the <code>ListSigningJobs</code> operation for two years after they are performed. Note the following requirements: </p> <ul> <li> <p> You must create an Amazon S3 source bucket. For more information, see <a href="http://docs.aws.amazon.com/AmazonS3/latest/gsg/CreatingABucket.html">Create a Bucket</a> in the <i>Amazon S3 Getting Started Guide</i>. </p> </li> <li> <p>Your S3 source bucket must be version enabled.</p> </li> <li> <p>You must create an S3 destination bucket. Code signing uses your S3 destination bucket to write your signed code.</p> </li> <li> <p>You specify the name of the source and destination buckets when calling the <code>StartSigningJob</code> operation.</p> </li> <li> <p>You must also specify a request token that identifies your request to code signing.</p> </li> </ul> <p>You can call the <a>DescribeSigningJob</a> and the <a>ListSigningJobs</a> actions after you call <code>StartSigningJob</code>.</p> <p>For a Java example that shows how to use this action, see <a href="http://docs.aws.amazon.com/acm/latest/userguide/">http://docs.aws.amazon.com/acm/latest/userguide/</a> </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656582 = newJObject()
  if body != nil:
    body_402656582 = body
  result = call_402656581.call(nil, nil, nil, nil, body_402656582)

var startSigningJob* = Call_StartSigningJob_402656569(name: "startSigningJob",
    meth: HttpMethod.HttpPost, host: "signer.amazonaws.com",
    route: "/signing-jobs", validator: validate_StartSigningJob_402656570,
    base: "/", makeUrl: url_StartSigningJob_402656571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSigningJobs_402656539 = ref object of OpenApiRestCall_402656038
proc url_ListSigningJobs_402656541(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSigningJobs_402656540(path: JsonNode; query: JsonNode;
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
  ##   maxResults: JInt
                                  ##             : Specifies the maximum number of items to return in the response. Use this parameter when paginating results. If additional items exist beyond the number you specify, the <code>nextToken</code> element is set in the response. Use the <code>nextToken</code> value in a subsequent request to retrieve additional items. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                               ## status: JString
                                                                                                                                                                                                                                                                                                                                                                               ##         
                                                                                                                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                                                                                                                               ## A 
                                                                                                                                                                                                                                                                                                                                                                               ## status 
                                                                                                                                                                                                                                                                                                                                                                               ## value 
                                                                                                                                                                                                                                                                                                                                                                               ## with 
                                                                                                                                                                                                                                                                                                                                                                               ## which 
                                                                                                                                                                                                                                                                                                                                                                               ## to 
                                                                                                                                                                                                                                                                                                                                                                               ## filter 
                                                                                                                                                                                                                                                                                                                                                                               ## your 
                                                                                                                                                                                                                                                                                                                                                                               ## results.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                          ## nextToken: JString
                                                                                                                                                                                                                                                                                                                                                                                          ##            
                                                                                                                                                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                                                                                                                                                          ## String 
                                                                                                                                                                                                                                                                                                                                                                                          ## for 
                                                                                                                                                                                                                                                                                                                                                                                          ## specifying 
                                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                                          ## next 
                                                                                                                                                                                                                                                                                                                                                                                          ## set 
                                                                                                                                                                                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                                                                                                                                                                                          ## paginated 
                                                                                                                                                                                                                                                                                                                                                                                          ## results 
                                                                                                                                                                                                                                                                                                                                                                                          ## to 
                                                                                                                                                                                                                                                                                                                                                                                          ## return. 
                                                                                                                                                                                                                                                                                                                                                                                          ## After 
                                                                                                                                                                                                                                                                                                                                                                                          ## you 
                                                                                                                                                                                                                                                                                                                                                                                          ## receive 
                                                                                                                                                                                                                                                                                                                                                                                          ## a 
                                                                                                                                                                                                                                                                                                                                                                                          ## response 
                                                                                                                                                                                                                                                                                                                                                                                          ## with 
                                                                                                                                                                                                                                                                                                                                                                                          ## truncated 
                                                                                                                                                                                                                                                                                                                                                                                          ## results, 
                                                                                                                                                                                                                                                                                                                                                                                          ## use 
                                                                                                                                                                                                                                                                                                                                                                                          ## this 
                                                                                                                                                                                                                                                                                                                                                                                          ## parameter 
                                                                                                                                                                                                                                                                                                                                                                                          ## in 
                                                                                                                                                                                                                                                                                                                                                                                          ## a 
                                                                                                                                                                                                                                                                                                                                                                                          ## subsequent 
                                                                                                                                                                                                                                                                                                                                                                                          ## request. 
                                                                                                                                                                                                                                                                                                                                                                                          ## Set 
                                                                                                                                                                                                                                                                                                                                                                                          ## it 
                                                                                                                                                                                                                                                                                                                                                                                          ## to 
                                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                                          ## value 
                                                                                                                                                                                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                                                                                                                                                                                          ## <code>nextToken</code> 
                                                                                                                                                                                                                                                                                                                                                                                          ## from 
                                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                                          ## response 
                                                                                                                                                                                                                                                                                                                                                                                          ## that 
                                                                                                                                                                                                                                                                                                                                                                                          ## you 
                                                                                                                                                                                                                                                                                                                                                                                          ## just 
                                                                                                                                                                                                                                                                                                                                                                                          ## received.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                      ## requestedBy: JString
                                                                                                                                                                                                                                                                                                                                                                                                      ##              
                                                                                                                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                                                                                                                      ## The 
                                                                                                                                                                                                                                                                                                                                                                                                      ## IAM 
                                                                                                                                                                                                                                                                                                                                                                                                      ## principal 
                                                                                                                                                                                                                                                                                                                                                                                                      ## that 
                                                                                                                                                                                                                                                                                                                                                                                                      ## requested 
                                                                                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                                                                                      ## signing 
                                                                                                                                                                                                                                                                                                                                                                                                      ## job.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                             ## platformId: JString
                                                                                                                                                                                                                                                                                                                                                                                                             ##             
                                                                                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                                                                                             ## The 
                                                                                                                                                                                                                                                                                                                                                                                                             ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                             ## of 
                                                                                                                                                                                                                                                                                                                                                                                                             ## microcontroller 
                                                                                                                                                                                                                                                                                                                                                                                                             ## platform 
                                                                                                                                                                                                                                                                                                                                                                                                             ## that 
                                                                                                                                                                                                                                                                                                                                                                                                             ## you 
                                                                                                                                                                                                                                                                                                                                                                                                             ## specified 
                                                                                                                                                                                                                                                                                                                                                                                                             ## for 
                                                                                                                                                                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                                                                                                                                                                             ## distribution 
                                                                                                                                                                                                                                                                                                                                                                                                             ## of 
                                                                                                                                                                                                                                                                                                                                                                                                             ## your 
                                                                                                                                                                                                                                                                                                                                                                                                             ## code 
                                                                                                                                                                                                                                                                                                                                                                                                             ## image.
  section = newJObject()
  var valid_402656542 = query.getOrDefault("maxResults")
  valid_402656542 = validateParameter(valid_402656542, JInt, required = false,
                                      default = nil)
  if valid_402656542 != nil:
    section.add "maxResults", valid_402656542
  var valid_402656555 = query.getOrDefault("status")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false,
                                      default = newJString("InProgress"))
  if valid_402656555 != nil:
    section.add "status", valid_402656555
  var valid_402656556 = query.getOrDefault("nextToken")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "nextToken", valid_402656556
  var valid_402656557 = query.getOrDefault("requestedBy")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "requestedBy", valid_402656557
  var valid_402656558 = query.getOrDefault("platformId")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "platformId", valid_402656558
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656559 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-Security-Token", valid_402656559
  var valid_402656560 = header.getOrDefault("X-Amz-Signature")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "X-Amz-Signature", valid_402656560
  var valid_402656561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656561
  var valid_402656562 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-Algorithm", valid_402656562
  var valid_402656563 = header.getOrDefault("X-Amz-Date")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "X-Amz-Date", valid_402656563
  var valid_402656564 = header.getOrDefault("X-Amz-Credential")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-Credential", valid_402656564
  var valid_402656565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656566: Call_ListSigningJobs_402656539; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all your signing jobs. You can use the <code>maxResults</code> parameter to limit the number of signing jobs that are returned in the response. If additional jobs remain to be listed, code signing returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that code signing returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned. 
                                                                                         ## 
  let valid = call_402656566.validator(path, query, header, formData, body, _)
  let scheme = call_402656566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656566.makeUrl(scheme.get, call_402656566.host, call_402656566.base,
                                   call_402656566.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656566, uri, valid, _)

proc call*(call_402656567: Call_ListSigningJobs_402656539; maxResults: int = 0;
           status: string = "InProgress"; nextToken: string = "";
           requestedBy: string = ""; platformId: string = ""): Recallable =
  ## listSigningJobs
  ## Lists all your signing jobs. You can use the <code>maxResults</code> parameter to limit the number of signing jobs that are returned in the response. If additional jobs remain to be listed, code signing returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that code signing returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## maxResults: int
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## Specifies 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## items 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## return 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## response. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## Use 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## this 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## parameter 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## when 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## paginating 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## results. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## If 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## additional 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## items 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## exist 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## beyond 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## specify, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## <code>nextToken</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## element 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## response. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## Use 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## <code>nextToken</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## value 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## subsequent 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## request 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## retrieve 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## additional 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## items. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## status: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ##         
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## A 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## status 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## value 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## with 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## which 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## filter 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## your 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## results.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## nextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## String 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## specifying 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## next 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## paginated 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## results 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## return. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## After 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## receive 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## response 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## with 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## truncated 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## results, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## use 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## this 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## parameter 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## subsequent 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## request. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## Set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## it 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## value 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## <code>nextToken</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## from 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## response 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## just 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## received.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## requestedBy: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ##              
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## IAM 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## principal 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## requested 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## signing 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## job.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## platformId: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## microcontroller 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## platform 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## specified 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## distribution 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## your 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## code 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## image.
  var query_402656568 = newJObject()
  add(query_402656568, "maxResults", newJInt(maxResults))
  add(query_402656568, "status", newJString(status))
  add(query_402656568, "nextToken", newJString(nextToken))
  add(query_402656568, "requestedBy", newJString(requestedBy))
  add(query_402656568, "platformId", newJString(platformId))
  result = call_402656567.call(nil, query_402656568, nil, nil, nil)

var listSigningJobs* = Call_ListSigningJobs_402656539(name: "listSigningJobs",
    meth: HttpMethod.HttpGet, host: "signer.amazonaws.com",
    route: "/signing-jobs", validator: validate_ListSigningJobs_402656540,
    base: "/", makeUrl: url_ListSigningJobs_402656541,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSigningPlatforms_402656583 = ref object of OpenApiRestCall_402656038
proc url_ListSigningPlatforms_402656585(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSigningPlatforms_402656584(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists all signing platforms available in code signing that match the request parameters. If additional jobs remain to be listed, code signing returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that code signing returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results to be returned by this operation.
  ##   
                                                                                                                  ## nextToken: JString
                                                                                                                  ##            
                                                                                                                  ## : 
                                                                                                                  ## Value 
                                                                                                                  ## for 
                                                                                                                  ## specifying 
                                                                                                                  ## the 
                                                                                                                  ## next 
                                                                                                                  ## set 
                                                                                                                  ## of 
                                                                                                                  ## paginated 
                                                                                                                  ## results 
                                                                                                                  ## to 
                                                                                                                  ## return. 
                                                                                                                  ## After 
                                                                                                                  ## you 
                                                                                                                  ## receive 
                                                                                                                  ## a 
                                                                                                                  ## response 
                                                                                                                  ## with 
                                                                                                                  ## truncated 
                                                                                                                  ## results, 
                                                                                                                  ## use 
                                                                                                                  ## this 
                                                                                                                  ## parameter 
                                                                                                                  ## in 
                                                                                                                  ## a 
                                                                                                                  ## subsequent 
                                                                                                                  ## request. 
                                                                                                                  ## Set 
                                                                                                                  ## it 
                                                                                                                  ## to 
                                                                                                                  ## the 
                                                                                                                  ## value 
                                                                                                                  ## of 
                                                                                                                  ## <code>nextToken</code> 
                                                                                                                  ## from 
                                                                                                                  ## the 
                                                                                                                  ## response 
                                                                                                                  ## that 
                                                                                                                  ## you 
                                                                                                                  ## just 
                                                                                                                  ## received.
  ##   
                                                                                                                              ## category: JString
                                                                                                                              ##           
                                                                                                                              ## : 
                                                                                                                              ## The 
                                                                                                                              ## category 
                                                                                                                              ## type 
                                                                                                                              ## of 
                                                                                                                              ## a 
                                                                                                                              ## signing 
                                                                                                                              ## platform.
  ##   
                                                                                                                                          ## target: JString
                                                                                                                                          ##         
                                                                                                                                          ## : 
                                                                                                                                          ## The 
                                                                                                                                          ## validation 
                                                                                                                                          ## template 
                                                                                                                                          ## that 
                                                                                                                                          ## is 
                                                                                                                                          ## used 
                                                                                                                                          ## by 
                                                                                                                                          ## the 
                                                                                                                                          ## target 
                                                                                                                                          ## signing 
                                                                                                                                          ## platform.
  ##   
                                                                                                                                                      ## partner: JString
                                                                                                                                                      ##          
                                                                                                                                                      ## : 
                                                                                                                                                      ## Any 
                                                                                                                                                      ## partner 
                                                                                                                                                      ## entities 
                                                                                                                                                      ## connected 
                                                                                                                                                      ## to 
                                                                                                                                                      ## a 
                                                                                                                                                      ## signing 
                                                                                                                                                      ## platform.
  section = newJObject()
  var valid_402656586 = query.getOrDefault("maxResults")
  valid_402656586 = validateParameter(valid_402656586, JInt, required = false,
                                      default = nil)
  if valid_402656586 != nil:
    section.add "maxResults", valid_402656586
  var valid_402656587 = query.getOrDefault("nextToken")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "nextToken", valid_402656587
  var valid_402656588 = query.getOrDefault("category")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "category", valid_402656588
  var valid_402656589 = query.getOrDefault("target")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "target", valid_402656589
  var valid_402656590 = query.getOrDefault("partner")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "partner", valid_402656590
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656591 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-Security-Token", valid_402656591
  var valid_402656592 = header.getOrDefault("X-Amz-Signature")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Signature", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Algorithm", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-Date")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-Date", valid_402656595
  var valid_402656596 = header.getOrDefault("X-Amz-Credential")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "X-Amz-Credential", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656598: Call_ListSigningPlatforms_402656583;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all signing platforms available in code signing that match the request parameters. If additional jobs remain to be listed, code signing returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that code signing returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
                                                                                         ## 
  let valid = call_402656598.validator(path, query, header, formData, body, _)
  let scheme = call_402656598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656598.makeUrl(scheme.get, call_402656598.host, call_402656598.base,
                                   call_402656598.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656598, uri, valid, _)

proc call*(call_402656599: Call_ListSigningPlatforms_402656583;
           maxResults: int = 0; nextToken: string = ""; category: string = "";
           target: string = ""; partner: string = ""): Recallable =
  ## listSigningPlatforms
  ## Lists all signing platforms available in code signing that match the request parameters. If additional jobs remain to be listed, code signing returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that code signing returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## maxResults: int
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## results 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## be 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## returned 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## by 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## this 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## operation.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## nextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## Value 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## specifying 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## next 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## paginated 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## results 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## return. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## After 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## receive 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## response 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## with 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## truncated 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## results, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## use 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## this 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## parameter 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## subsequent 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## request. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## Set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## it 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## value 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## <code>nextToken</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## from 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## response 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## just 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## received.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## category: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ##           
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## category 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## type 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## signing 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## platform.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## target: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ##         
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## validation 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## template 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## used 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## by 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## target 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## signing 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## platform.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## partner: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ##          
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## Any 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## partner 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## entities 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## connected 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## signing 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## platform.
  var query_402656600 = newJObject()
  add(query_402656600, "maxResults", newJInt(maxResults))
  add(query_402656600, "nextToken", newJString(nextToken))
  add(query_402656600, "category", newJString(category))
  add(query_402656600, "target", newJString(target))
  add(query_402656600, "partner", newJString(partner))
  result = call_402656599.call(nil, query_402656600, nil, nil, nil)

var listSigningPlatforms* = Call_ListSigningPlatforms_402656583(
    name: "listSigningPlatforms", meth: HttpMethod.HttpGet,
    host: "signer.amazonaws.com", route: "/signing-platforms",
    validator: validate_ListSigningPlatforms_402656584, base: "/",
    makeUrl: url_ListSigningPlatforms_402656585,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSigningProfiles_402656601 = ref object of OpenApiRestCall_402656038
proc url_ListSigningProfiles_402656603(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSigningProfiles_402656602(path: JsonNode; query: JsonNode;
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
  ##   
                                                                                                 ## nextToken: JString
                                                                                                 ##            
                                                                                                 ## : 
                                                                                                 ## Value 
                                                                                                 ## for 
                                                                                                 ## specifying 
                                                                                                 ## the 
                                                                                                 ## next 
                                                                                                 ## set 
                                                                                                 ## of 
                                                                                                 ## paginated 
                                                                                                 ## results 
                                                                                                 ## to 
                                                                                                 ## return. 
                                                                                                 ## After 
                                                                                                 ## you 
                                                                                                 ## receive 
                                                                                                 ## a 
                                                                                                 ## response 
                                                                                                 ## with 
                                                                                                 ## truncated 
                                                                                                 ## results, 
                                                                                                 ## use 
                                                                                                 ## this 
                                                                                                 ## parameter 
                                                                                                 ## in 
                                                                                                 ## a 
                                                                                                 ## subsequent 
                                                                                                 ## request. 
                                                                                                 ## Set 
                                                                                                 ## it 
                                                                                                 ## to 
                                                                                                 ## the 
                                                                                                 ## value 
                                                                                                 ## of 
                                                                                                 ## <code>nextToken</code> 
                                                                                                 ## from 
                                                                                                 ## the 
                                                                                                 ## response 
                                                                                                 ## that 
                                                                                                 ## you 
                                                                                                 ## just 
                                                                                                 ## received.
  ##   
                                                                                                             ## includeCanceled: JBool
                                                                                                             ##                  
                                                                                                             ## : 
                                                                                                             ## Designates 
                                                                                                             ## whether 
                                                                                                             ## to 
                                                                                                             ## include 
                                                                                                             ## profiles 
                                                                                                             ## with 
                                                                                                             ## the 
                                                                                                             ## status 
                                                                                                             ## of 
                                                                                                             ## <code>CANCELED</code>.
  section = newJObject()
  var valid_402656604 = query.getOrDefault("maxResults")
  valid_402656604 = validateParameter(valid_402656604, JInt, required = false,
                                      default = nil)
  if valid_402656604 != nil:
    section.add "maxResults", valid_402656604
  var valid_402656605 = query.getOrDefault("nextToken")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "nextToken", valid_402656605
  var valid_402656606 = query.getOrDefault("includeCanceled")
  valid_402656606 = validateParameter(valid_402656606, JBool, required = false,
                                      default = nil)
  if valid_402656606 != nil:
    section.add "includeCanceled", valid_402656606
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656607 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "X-Amz-Security-Token", valid_402656607
  var valid_402656608 = header.getOrDefault("X-Amz-Signature")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-Signature", valid_402656608
  var valid_402656609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656609
  var valid_402656610 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-Algorithm", valid_402656610
  var valid_402656611 = header.getOrDefault("X-Amz-Date")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-Date", valid_402656611
  var valid_402656612 = header.getOrDefault("X-Amz-Credential")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "X-Amz-Credential", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656614: Call_ListSigningProfiles_402656601;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all available signing profiles in your AWS account. Returns only profiles with an <code>ACTIVE</code> status unless the <code>includeCanceled</code> request field is set to <code>true</code>. If additional jobs remain to be listed, code signing returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that code signing returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
                                                                                         ## 
  let valid = call_402656614.validator(path, query, header, formData, body, _)
  let scheme = call_402656614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656614.makeUrl(scheme.get, call_402656614.host, call_402656614.base,
                                   call_402656614.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656614, uri, valid, _)

proc call*(call_402656615: Call_ListSigningProfiles_402656601;
           maxResults: int = 0; nextToken: string = "";
           includeCanceled: bool = false): Recallable =
  ## listSigningProfiles
  ## Lists all available signing profiles in your AWS account. Returns only profiles with an <code>ACTIVE</code> status unless the <code>includeCanceled</code> request field is set to <code>true</code>. If additional jobs remain to be listed, code signing returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that code signing returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## maxResults: int
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## profiles 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## be 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## returned.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## nextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## Value 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## specifying 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## next 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## paginated 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## results 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## return. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## After 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## receive 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## response 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## with 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## truncated 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## results, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## use 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## this 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## parameter 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## subsequent 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## request. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## Set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## it 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## value 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## <code>nextToken</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## from 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## response 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## just 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## received.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## includeCanceled: bool
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ##                  
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Designates 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## whether 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## include 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## profiles 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## with 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## status 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## <code>CANCELED</code>.
  var query_402656616 = newJObject()
  add(query_402656616, "maxResults", newJInt(maxResults))
  add(query_402656616, "nextToken", newJString(nextToken))
  add(query_402656616, "includeCanceled", newJBool(includeCanceled))
  result = call_402656615.call(nil, query_402656616, nil, nil, nil)

var listSigningProfiles* = Call_ListSigningProfiles_402656601(
    name: "listSigningProfiles", meth: HttpMethod.HttpGet,
    host: "signer.amazonaws.com", route: "/signing-profiles",
    validator: validate_ListSigningProfiles_402656602, base: "/",
    makeUrl: url_ListSigningProfiles_402656603,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656631 = ref object of OpenApiRestCall_402656038
proc url_TagResource_402656633(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_402656632(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656634 = path.getOrDefault("resourceArn")
  valid_402656634 = validateParameter(valid_402656634, JString, required = true,
                                      default = nil)
  if valid_402656634 != nil:
    section.add "resourceArn", valid_402656634
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656635 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "X-Amz-Security-Token", valid_402656635
  var valid_402656636 = header.getOrDefault("X-Amz-Signature")
  valid_402656636 = validateParameter(valid_402656636, JString,
                                      required = false, default = nil)
  if valid_402656636 != nil:
    section.add "X-Amz-Signature", valid_402656636
  var valid_402656637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656637
  var valid_402656638 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656638 = validateParameter(valid_402656638, JString,
                                      required = false, default = nil)
  if valid_402656638 != nil:
    section.add "X-Amz-Algorithm", valid_402656638
  var valid_402656639 = header.getOrDefault("X-Amz-Date")
  valid_402656639 = validateParameter(valid_402656639, JString,
                                      required = false, default = nil)
  if valid_402656639 != nil:
    section.add "X-Amz-Date", valid_402656639
  var valid_402656640 = header.getOrDefault("X-Amz-Credential")
  valid_402656640 = validateParameter(valid_402656640, JString,
                                      required = false, default = nil)
  if valid_402656640 != nil:
    section.add "X-Amz-Credential", valid_402656640
  var valid_402656641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656641 = validateParameter(valid_402656641, JString,
                                      required = false, default = nil)
  if valid_402656641 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656641
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

proc call*(call_402656643: Call_TagResource_402656631; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds one or more tags to a signing profile. Tags are labels that you can use to identify and organize your AWS resources. Each tag consists of a key and an optional value. You specify the signing profile using its Amazon Resource Name (ARN). You specify the tag by using a key-value pair.
                                                                                         ## 
  let valid = call_402656643.validator(path, query, header, formData, body, _)
  let scheme = call_402656643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656643.makeUrl(scheme.get, call_402656643.host, call_402656643.base,
                                   call_402656643.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656643, uri, valid, _)

proc call*(call_402656644: Call_TagResource_402656631; body: JsonNode;
           resourceArn: string): Recallable =
  ## tagResource
  ## Adds one or more tags to a signing profile. Tags are labels that you can use to identify and organize your AWS resources. Each tag consists of a key and an optional value. You specify the signing profile using its Amazon Resource Name (ARN). You specify the tag by using a key-value pair.
  ##   
                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                ## resourceArn: string (required)
                                                                                                                                                                                                                                                                                                                                ##              
                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                ## Amazon 
                                                                                                                                                                                                                                                                                                                                ## Resource 
                                                                                                                                                                                                                                                                                                                                ## Name 
                                                                                                                                                                                                                                                                                                                                ## (ARN) 
                                                                                                                                                                                                                                                                                                                                ## for 
                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                ## signing 
                                                                                                                                                                                                                                                                                                                                ## profile.
  var path_402656645 = newJObject()
  var body_402656646 = newJObject()
  if body != nil:
    body_402656646 = body
  add(path_402656645, "resourceArn", newJString(resourceArn))
  result = call_402656644.call(path_402656645, nil, nil, nil, body_402656646)

var tagResource* = Call_TagResource_402656631(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "signer.amazonaws.com",
    route: "/tags/{resourceArn}", validator: validate_TagResource_402656632,
    base: "/", makeUrl: url_TagResource_402656633,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656617 = ref object of OpenApiRestCall_402656038
proc url_ListTagsForResource_402656619(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
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

proc validate_ListTagsForResource_402656618(path: JsonNode; query: JsonNode;
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
  var valid_402656620 = path.getOrDefault("resourceArn")
  valid_402656620 = validateParameter(valid_402656620, JString, required = true,
                                      default = nil)
  if valid_402656620 != nil:
    section.add "resourceArn", valid_402656620
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656621 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "X-Amz-Security-Token", valid_402656621
  var valid_402656622 = header.getOrDefault("X-Amz-Signature")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "X-Amz-Signature", valid_402656622
  var valid_402656623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656623
  var valid_402656624 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "X-Amz-Algorithm", valid_402656624
  var valid_402656625 = header.getOrDefault("X-Amz-Date")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "X-Amz-Date", valid_402656625
  var valid_402656626 = header.getOrDefault("X-Amz-Credential")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "X-Amz-Credential", valid_402656626
  var valid_402656627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656628: Call_ListTagsForResource_402656617;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the tags associated with a signing profile resource.
                                                                                         ## 
  let valid = call_402656628.validator(path, query, header, formData, body, _)
  let scheme = call_402656628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656628.makeUrl(scheme.get, call_402656628.host, call_402656628.base,
                                   call_402656628.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656628, uri, valid, _)

proc call*(call_402656629: Call_ListTagsForResource_402656617;
           resourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns a list of the tags associated with a signing profile resource.
  ##   
                                                                           ## resourceArn: string (required)
                                                                           ##              
                                                                           ## : 
                                                                           ## The 
                                                                           ## Amazon 
                                                                           ## Resource 
                                                                           ## Name 
                                                                           ## (ARN) 
                                                                           ## for 
                                                                           ## the 
                                                                           ## signing 
                                                                           ## profile.
  var path_402656630 = newJObject()
  add(path_402656630, "resourceArn", newJString(resourceArn))
  result = call_402656629.call(path_402656630, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402656617(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "signer.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_402656618, base: "/",
    makeUrl: url_ListTagsForResource_402656619,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656647 = ref object of OpenApiRestCall_402656038
proc url_UntagResource_402656649(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_402656648(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656650 = path.getOrDefault("resourceArn")
  valid_402656650 = validateParameter(valid_402656650, JString, required = true,
                                      default = nil)
  if valid_402656650 != nil:
    section.add "resourceArn", valid_402656650
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          : A list of tag keys to be removed from the signing profile .
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402656651 = query.getOrDefault("tagKeys")
  valid_402656651 = validateParameter(valid_402656651, JArray, required = true,
                                      default = nil)
  if valid_402656651 != nil:
    section.add "tagKeys", valid_402656651
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656652 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656652 = validateParameter(valid_402656652, JString,
                                      required = false, default = nil)
  if valid_402656652 != nil:
    section.add "X-Amz-Security-Token", valid_402656652
  var valid_402656653 = header.getOrDefault("X-Amz-Signature")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "X-Amz-Signature", valid_402656653
  var valid_402656654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656654 = validateParameter(valid_402656654, JString,
                                      required = false, default = nil)
  if valid_402656654 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656654
  var valid_402656655 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656655 = validateParameter(valid_402656655, JString,
                                      required = false, default = nil)
  if valid_402656655 != nil:
    section.add "X-Amz-Algorithm", valid_402656655
  var valid_402656656 = header.getOrDefault("X-Amz-Date")
  valid_402656656 = validateParameter(valid_402656656, JString,
                                      required = false, default = nil)
  if valid_402656656 != nil:
    section.add "X-Amz-Date", valid_402656656
  var valid_402656657 = header.getOrDefault("X-Amz-Credential")
  valid_402656657 = validateParameter(valid_402656657, JString,
                                      required = false, default = nil)
  if valid_402656657 != nil:
    section.add "X-Amz-Credential", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656659: Call_UntagResource_402656647; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Remove one or more tags from a signing profile. Specify a list of tag keys to remove the tags.
                                                                                         ## 
  let valid = call_402656659.validator(path, query, header, formData, body, _)
  let scheme = call_402656659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656659.makeUrl(scheme.get, call_402656659.host, call_402656659.base,
                                   call_402656659.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656659, uri, valid, _)

proc call*(call_402656660: Call_UntagResource_402656647; tagKeys: JsonNode;
           resourceArn: string): Recallable =
  ## untagResource
  ## Remove one or more tags from a signing profile. Specify a list of tag keys to remove the tags.
  ##   
                                                                                                   ## tagKeys: JArray (required)
                                                                                                   ##          
                                                                                                   ## : 
                                                                                                   ## A 
                                                                                                   ## list 
                                                                                                   ## of 
                                                                                                   ## tag 
                                                                                                   ## keys 
                                                                                                   ## to 
                                                                                                   ## be 
                                                                                                   ## removed 
                                                                                                   ## from 
                                                                                                   ## the 
                                                                                                   ## signing 
                                                                                                   ## profile 
                                                                                                   ## .
  ##   
                                                                                                       ## resourceArn: string (required)
                                                                                                       ##              
                                                                                                       ## : 
                                                                                                       ## Amazon 
                                                                                                       ## Resource 
                                                                                                       ## Name 
                                                                                                       ## (ARN) 
                                                                                                       ## for 
                                                                                                       ## the 
                                                                                                       ## signing 
                                                                                                       ## profile 
                                                                                                       ## .
  var path_402656661 = newJObject()
  var query_402656662 = newJObject()
  if tagKeys != nil:
    query_402656662.add "tagKeys", tagKeys
  add(path_402656661, "resourceArn", newJString(resourceArn))
  result = call_402656660.call(path_402656661, query_402656662, nil, nil, nil)

var untagResource* = Call_UntagResource_402656647(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "signer.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_402656648,
    base: "/", makeUrl: url_UntagResource_402656649,
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
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
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