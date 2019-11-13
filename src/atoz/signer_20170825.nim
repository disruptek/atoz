
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_593389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593389): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PutSigningProfile_593997 = ref object of OpenApiRestCall_593389
proc url_PutSigningProfile_593999(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutSigningProfile_593998(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_594000 = path.getOrDefault("profileName")
  valid_594000 = validateParameter(valid_594000, JString, required = true,
                                 default = nil)
  if valid_594000 != nil:
    section.add "profileName", valid_594000
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
  var valid_594001 = header.getOrDefault("X-Amz-Signature")
  valid_594001 = validateParameter(valid_594001, JString, required = false,
                                 default = nil)
  if valid_594001 != nil:
    section.add "X-Amz-Signature", valid_594001
  var valid_594002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594002 = validateParameter(valid_594002, JString, required = false,
                                 default = nil)
  if valid_594002 != nil:
    section.add "X-Amz-Content-Sha256", valid_594002
  var valid_594003 = header.getOrDefault("X-Amz-Date")
  valid_594003 = validateParameter(valid_594003, JString, required = false,
                                 default = nil)
  if valid_594003 != nil:
    section.add "X-Amz-Date", valid_594003
  var valid_594004 = header.getOrDefault("X-Amz-Credential")
  valid_594004 = validateParameter(valid_594004, JString, required = false,
                                 default = nil)
  if valid_594004 != nil:
    section.add "X-Amz-Credential", valid_594004
  var valid_594005 = header.getOrDefault("X-Amz-Security-Token")
  valid_594005 = validateParameter(valid_594005, JString, required = false,
                                 default = nil)
  if valid_594005 != nil:
    section.add "X-Amz-Security-Token", valid_594005
  var valid_594006 = header.getOrDefault("X-Amz-Algorithm")
  valid_594006 = validateParameter(valid_594006, JString, required = false,
                                 default = nil)
  if valid_594006 != nil:
    section.add "X-Amz-Algorithm", valid_594006
  var valid_594007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594007 = validateParameter(valid_594007, JString, required = false,
                                 default = nil)
  if valid_594007 != nil:
    section.add "X-Amz-SignedHeaders", valid_594007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594009: Call_PutSigningProfile_593997; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a signing profile. A signing profile is a code signing template that can be used to carry out a pre-defined signing job. For more information, see <a href="http://docs.aws.amazon.com/signer/latest/developerguide/gs-profile.html">http://docs.aws.amazon.com/signer/latest/developerguide/gs-profile.html</a> 
  ## 
  let valid = call_594009.validator(path, query, header, formData, body)
  let scheme = call_594009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594009.url(scheme.get, call_594009.host, call_594009.base,
                         call_594009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594009, url, valid)

proc call*(call_594010: Call_PutSigningProfile_593997; profileName: string;
          body: JsonNode): Recallable =
  ## putSigningProfile
  ## Creates a signing profile. A signing profile is a code signing template that can be used to carry out a pre-defined signing job. For more information, see <a href="http://docs.aws.amazon.com/signer/latest/developerguide/gs-profile.html">http://docs.aws.amazon.com/signer/latest/developerguide/gs-profile.html</a> 
  ##   profileName: string (required)
  ##              : The name of the signing profile to be created.
  ##   body: JObject (required)
  var path_594011 = newJObject()
  var body_594012 = newJObject()
  add(path_594011, "profileName", newJString(profileName))
  if body != nil:
    body_594012 = body
  result = call_594010.call(path_594011, nil, nil, nil, body_594012)

var putSigningProfile* = Call_PutSigningProfile_593997(name: "putSigningProfile",
    meth: HttpMethod.HttpPut, host: "signer.amazonaws.com",
    route: "/signing-profiles/{profileName}",
    validator: validate_PutSigningProfile_593998, base: "/",
    url: url_PutSigningProfile_593999, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSigningProfile_593727 = ref object of OpenApiRestCall_593389
proc url_GetSigningProfile_593729(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSigningProfile_593728(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_593855 = path.getOrDefault("profileName")
  valid_593855 = validateParameter(valid_593855, JString, required = true,
                                 default = nil)
  if valid_593855 != nil:
    section.add "profileName", valid_593855
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
  var valid_593856 = header.getOrDefault("X-Amz-Signature")
  valid_593856 = validateParameter(valid_593856, JString, required = false,
                                 default = nil)
  if valid_593856 != nil:
    section.add "X-Amz-Signature", valid_593856
  var valid_593857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593857 = validateParameter(valid_593857, JString, required = false,
                                 default = nil)
  if valid_593857 != nil:
    section.add "X-Amz-Content-Sha256", valid_593857
  var valid_593858 = header.getOrDefault("X-Amz-Date")
  valid_593858 = validateParameter(valid_593858, JString, required = false,
                                 default = nil)
  if valid_593858 != nil:
    section.add "X-Amz-Date", valid_593858
  var valid_593859 = header.getOrDefault("X-Amz-Credential")
  valid_593859 = validateParameter(valid_593859, JString, required = false,
                                 default = nil)
  if valid_593859 != nil:
    section.add "X-Amz-Credential", valid_593859
  var valid_593860 = header.getOrDefault("X-Amz-Security-Token")
  valid_593860 = validateParameter(valid_593860, JString, required = false,
                                 default = nil)
  if valid_593860 != nil:
    section.add "X-Amz-Security-Token", valid_593860
  var valid_593861 = header.getOrDefault("X-Amz-Algorithm")
  valid_593861 = validateParameter(valid_593861, JString, required = false,
                                 default = nil)
  if valid_593861 != nil:
    section.add "X-Amz-Algorithm", valid_593861
  var valid_593862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593862 = validateParameter(valid_593862, JString, required = false,
                                 default = nil)
  if valid_593862 != nil:
    section.add "X-Amz-SignedHeaders", valid_593862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593885: Call_GetSigningProfile_593727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information on a specific signing profile.
  ## 
  let valid = call_593885.validator(path, query, header, formData, body)
  let scheme = call_593885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593885.url(scheme.get, call_593885.host, call_593885.base,
                         call_593885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593885, url, valid)

proc call*(call_593956: Call_GetSigningProfile_593727; profileName: string): Recallable =
  ## getSigningProfile
  ## Returns information on a specific signing profile.
  ##   profileName: string (required)
  ##              : The name of the target signing profile.
  var path_593957 = newJObject()
  add(path_593957, "profileName", newJString(profileName))
  result = call_593956.call(path_593957, nil, nil, nil, nil)

var getSigningProfile* = Call_GetSigningProfile_593727(name: "getSigningProfile",
    meth: HttpMethod.HttpGet, host: "signer.amazonaws.com",
    route: "/signing-profiles/{profileName}",
    validator: validate_GetSigningProfile_593728, base: "/",
    url: url_GetSigningProfile_593729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelSigningProfile_594013 = ref object of OpenApiRestCall_593389
proc url_CancelSigningProfile_594015(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CancelSigningProfile_594014(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_594016 = path.getOrDefault("profileName")
  valid_594016 = validateParameter(valid_594016, JString, required = true,
                                 default = nil)
  if valid_594016 != nil:
    section.add "profileName", valid_594016
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
  var valid_594017 = header.getOrDefault("X-Amz-Signature")
  valid_594017 = validateParameter(valid_594017, JString, required = false,
                                 default = nil)
  if valid_594017 != nil:
    section.add "X-Amz-Signature", valid_594017
  var valid_594018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594018 = validateParameter(valid_594018, JString, required = false,
                                 default = nil)
  if valid_594018 != nil:
    section.add "X-Amz-Content-Sha256", valid_594018
  var valid_594019 = header.getOrDefault("X-Amz-Date")
  valid_594019 = validateParameter(valid_594019, JString, required = false,
                                 default = nil)
  if valid_594019 != nil:
    section.add "X-Amz-Date", valid_594019
  var valid_594020 = header.getOrDefault("X-Amz-Credential")
  valid_594020 = validateParameter(valid_594020, JString, required = false,
                                 default = nil)
  if valid_594020 != nil:
    section.add "X-Amz-Credential", valid_594020
  var valid_594021 = header.getOrDefault("X-Amz-Security-Token")
  valid_594021 = validateParameter(valid_594021, JString, required = false,
                                 default = nil)
  if valid_594021 != nil:
    section.add "X-Amz-Security-Token", valid_594021
  var valid_594022 = header.getOrDefault("X-Amz-Algorithm")
  valid_594022 = validateParameter(valid_594022, JString, required = false,
                                 default = nil)
  if valid_594022 != nil:
    section.add "X-Amz-Algorithm", valid_594022
  var valid_594023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594023 = validateParameter(valid_594023, JString, required = false,
                                 default = nil)
  if valid_594023 != nil:
    section.add "X-Amz-SignedHeaders", valid_594023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594024: Call_CancelSigningProfile_594013; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the state of an <code>ACTIVE</code> signing profile to <code>CANCELED</code>. A canceled profile is still viewable with the <code>ListSigningProfiles</code> operation, but it cannot perform new signing jobs, and is deleted two years after cancelation.
  ## 
  let valid = call_594024.validator(path, query, header, formData, body)
  let scheme = call_594024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594024.url(scheme.get, call_594024.host, call_594024.base,
                         call_594024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594024, url, valid)

proc call*(call_594025: Call_CancelSigningProfile_594013; profileName: string): Recallable =
  ## cancelSigningProfile
  ## Changes the state of an <code>ACTIVE</code> signing profile to <code>CANCELED</code>. A canceled profile is still viewable with the <code>ListSigningProfiles</code> operation, but it cannot perform new signing jobs, and is deleted two years after cancelation.
  ##   profileName: string (required)
  ##              : The name of the signing profile to be canceled.
  var path_594026 = newJObject()
  add(path_594026, "profileName", newJString(profileName))
  result = call_594025.call(path_594026, nil, nil, nil, nil)

var cancelSigningProfile* = Call_CancelSigningProfile_594013(
    name: "cancelSigningProfile", meth: HttpMethod.HttpDelete,
    host: "signer.amazonaws.com", route: "/signing-profiles/{profileName}",
    validator: validate_CancelSigningProfile_594014, base: "/",
    url: url_CancelSigningProfile_594015, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSigningJob_594027 = ref object of OpenApiRestCall_593389
proc url_DescribeSigningJob_594029(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeSigningJob_594028(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns information about a specific code signing job. You specify the job by using the <code>jobId</code> value that is returned by the <a>StartSigningJob</a> operation. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   jobId: JString (required)
  ##        : The ID of the signing job on input.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `jobId` field"
  var valid_594030 = path.getOrDefault("jobId")
  valid_594030 = validateParameter(valid_594030, JString, required = true,
                                 default = nil)
  if valid_594030 != nil:
    section.add "jobId", valid_594030
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
  var valid_594031 = header.getOrDefault("X-Amz-Signature")
  valid_594031 = validateParameter(valid_594031, JString, required = false,
                                 default = nil)
  if valid_594031 != nil:
    section.add "X-Amz-Signature", valid_594031
  var valid_594032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594032 = validateParameter(valid_594032, JString, required = false,
                                 default = nil)
  if valid_594032 != nil:
    section.add "X-Amz-Content-Sha256", valid_594032
  var valid_594033 = header.getOrDefault("X-Amz-Date")
  valid_594033 = validateParameter(valid_594033, JString, required = false,
                                 default = nil)
  if valid_594033 != nil:
    section.add "X-Amz-Date", valid_594033
  var valid_594034 = header.getOrDefault("X-Amz-Credential")
  valid_594034 = validateParameter(valid_594034, JString, required = false,
                                 default = nil)
  if valid_594034 != nil:
    section.add "X-Amz-Credential", valid_594034
  var valid_594035 = header.getOrDefault("X-Amz-Security-Token")
  valid_594035 = validateParameter(valid_594035, JString, required = false,
                                 default = nil)
  if valid_594035 != nil:
    section.add "X-Amz-Security-Token", valid_594035
  var valid_594036 = header.getOrDefault("X-Amz-Algorithm")
  valid_594036 = validateParameter(valid_594036, JString, required = false,
                                 default = nil)
  if valid_594036 != nil:
    section.add "X-Amz-Algorithm", valid_594036
  var valid_594037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594037 = validateParameter(valid_594037, JString, required = false,
                                 default = nil)
  if valid_594037 != nil:
    section.add "X-Amz-SignedHeaders", valid_594037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594038: Call_DescribeSigningJob_594027; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific code signing job. You specify the job by using the <code>jobId</code> value that is returned by the <a>StartSigningJob</a> operation. 
  ## 
  let valid = call_594038.validator(path, query, header, formData, body)
  let scheme = call_594038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594038.url(scheme.get, call_594038.host, call_594038.base,
                         call_594038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594038, url, valid)

proc call*(call_594039: Call_DescribeSigningJob_594027; jobId: string): Recallable =
  ## describeSigningJob
  ## Returns information about a specific code signing job. You specify the job by using the <code>jobId</code> value that is returned by the <a>StartSigningJob</a> operation. 
  ##   jobId: string (required)
  ##        : The ID of the signing job on input.
  var path_594040 = newJObject()
  add(path_594040, "jobId", newJString(jobId))
  result = call_594039.call(path_594040, nil, nil, nil, nil)

var describeSigningJob* = Call_DescribeSigningJob_594027(
    name: "describeSigningJob", meth: HttpMethod.HttpGet,
    host: "signer.amazonaws.com", route: "/signing-jobs/{jobId}",
    validator: validate_DescribeSigningJob_594028, base: "/",
    url: url_DescribeSigningJob_594029, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSigningPlatform_594041 = ref object of OpenApiRestCall_593389
proc url_GetSigningPlatform_594043(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSigningPlatform_594042(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_594044 = path.getOrDefault("platformId")
  valid_594044 = validateParameter(valid_594044, JString, required = true,
                                 default = nil)
  if valid_594044 != nil:
    section.add "platformId", valid_594044
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
  var valid_594045 = header.getOrDefault("X-Amz-Signature")
  valid_594045 = validateParameter(valid_594045, JString, required = false,
                                 default = nil)
  if valid_594045 != nil:
    section.add "X-Amz-Signature", valid_594045
  var valid_594046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-Content-Sha256", valid_594046
  var valid_594047 = header.getOrDefault("X-Amz-Date")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Date", valid_594047
  var valid_594048 = header.getOrDefault("X-Amz-Credential")
  valid_594048 = validateParameter(valid_594048, JString, required = false,
                                 default = nil)
  if valid_594048 != nil:
    section.add "X-Amz-Credential", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Security-Token")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Security-Token", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Algorithm")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Algorithm", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-SignedHeaders", valid_594051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594052: Call_GetSigningPlatform_594041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information on a specific signing platform.
  ## 
  let valid = call_594052.validator(path, query, header, formData, body)
  let scheme = call_594052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594052.url(scheme.get, call_594052.host, call_594052.base,
                         call_594052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594052, url, valid)

proc call*(call_594053: Call_GetSigningPlatform_594041; platformId: string): Recallable =
  ## getSigningPlatform
  ## Returns information on a specific signing platform.
  ##   platformId: string (required)
  ##             : The ID of the target signing platform.
  var path_594054 = newJObject()
  add(path_594054, "platformId", newJString(platformId))
  result = call_594053.call(path_594054, nil, nil, nil, nil)

var getSigningPlatform* = Call_GetSigningPlatform_594041(
    name: "getSigningPlatform", meth: HttpMethod.HttpGet,
    host: "signer.amazonaws.com", route: "/signing-platforms/{platformId}",
    validator: validate_GetSigningPlatform_594042, base: "/",
    url: url_GetSigningPlatform_594043, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSigningJob_594086 = ref object of OpenApiRestCall_593389
proc url_StartSigningJob_594088(protocol: Scheme; host: string; base: string;
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

proc validate_StartSigningJob_594087(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Initiates a signing job to be performed on the code provided. Signing jobs are viewable by the <code>ListSigningJobs</code> operation for two years after they are performed. Note the following requirements: </p> <ul> <li> <p> You must create an Amazon S3 source bucket. For more information, see <a href="http://docs.aws.amazon.com/AmazonS3/latest/gsg/CreatingABucket.html">Create a Bucket</a> in the <i>Amazon S3 Getting Started Guide</i>. </p> </li> <li> <p>Your S3 source bucket must be version enabled.</p> </li> <li> <p>You must create an S3 destination bucket. Code signing uses your S3 destination bucket to write your signed code.</p> </li> <li> <p>You specify the name of the source and destination buckets when calling the <code>StartSigningJob</code> operation.</p> </li> <li> <p>You must also specify a request token that identifies your request to code signing.</p> </li> </ul> <p>You can call the <a>DescribeSigningJob</a> and the <a>ListSigningJobs</a> actions after you call <code>StartSigningJob</code>.</p> <p>For a Java example that shows how to use this action, see <a href="http://docs.aws.amazon.com/acm/latest/userguide/">http://docs.aws.amazon.com/acm/latest/userguide/</a> </p>
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
  var valid_594089 = header.getOrDefault("X-Amz-Signature")
  valid_594089 = validateParameter(valid_594089, JString, required = false,
                                 default = nil)
  if valid_594089 != nil:
    section.add "X-Amz-Signature", valid_594089
  var valid_594090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "X-Amz-Content-Sha256", valid_594090
  var valid_594091 = header.getOrDefault("X-Amz-Date")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Date", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Credential")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Credential", valid_594092
  var valid_594093 = header.getOrDefault("X-Amz-Security-Token")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-Security-Token", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Algorithm")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Algorithm", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-SignedHeaders", valid_594095
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594097: Call_StartSigningJob_594086; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a signing job to be performed on the code provided. Signing jobs are viewable by the <code>ListSigningJobs</code> operation for two years after they are performed. Note the following requirements: </p> <ul> <li> <p> You must create an Amazon S3 source bucket. For more information, see <a href="http://docs.aws.amazon.com/AmazonS3/latest/gsg/CreatingABucket.html">Create a Bucket</a> in the <i>Amazon S3 Getting Started Guide</i>. </p> </li> <li> <p>Your S3 source bucket must be version enabled.</p> </li> <li> <p>You must create an S3 destination bucket. Code signing uses your S3 destination bucket to write your signed code.</p> </li> <li> <p>You specify the name of the source and destination buckets when calling the <code>StartSigningJob</code> operation.</p> </li> <li> <p>You must also specify a request token that identifies your request to code signing.</p> </li> </ul> <p>You can call the <a>DescribeSigningJob</a> and the <a>ListSigningJobs</a> actions after you call <code>StartSigningJob</code>.</p> <p>For a Java example that shows how to use this action, see <a href="http://docs.aws.amazon.com/acm/latest/userguide/">http://docs.aws.amazon.com/acm/latest/userguide/</a> </p>
  ## 
  let valid = call_594097.validator(path, query, header, formData, body)
  let scheme = call_594097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594097.url(scheme.get, call_594097.host, call_594097.base,
                         call_594097.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594097, url, valid)

proc call*(call_594098: Call_StartSigningJob_594086; body: JsonNode): Recallable =
  ## startSigningJob
  ## <p>Initiates a signing job to be performed on the code provided. Signing jobs are viewable by the <code>ListSigningJobs</code> operation for two years after they are performed. Note the following requirements: </p> <ul> <li> <p> You must create an Amazon S3 source bucket. For more information, see <a href="http://docs.aws.amazon.com/AmazonS3/latest/gsg/CreatingABucket.html">Create a Bucket</a> in the <i>Amazon S3 Getting Started Guide</i>. </p> </li> <li> <p>Your S3 source bucket must be version enabled.</p> </li> <li> <p>You must create an S3 destination bucket. Code signing uses your S3 destination bucket to write your signed code.</p> </li> <li> <p>You specify the name of the source and destination buckets when calling the <code>StartSigningJob</code> operation.</p> </li> <li> <p>You must also specify a request token that identifies your request to code signing.</p> </li> </ul> <p>You can call the <a>DescribeSigningJob</a> and the <a>ListSigningJobs</a> actions after you call <code>StartSigningJob</code>.</p> <p>For a Java example that shows how to use this action, see <a href="http://docs.aws.amazon.com/acm/latest/userguide/">http://docs.aws.amazon.com/acm/latest/userguide/</a> </p>
  ##   body: JObject (required)
  var body_594099 = newJObject()
  if body != nil:
    body_594099 = body
  result = call_594098.call(nil, nil, nil, nil, body_594099)

var startSigningJob* = Call_StartSigningJob_594086(name: "startSigningJob",
    meth: HttpMethod.HttpPost, host: "signer.amazonaws.com", route: "/signing-jobs",
    validator: validate_StartSigningJob_594087, base: "/", url: url_StartSigningJob_594088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSigningJobs_594055 = ref object of OpenApiRestCall_593389
proc url_ListSigningJobs_594057(protocol: Scheme; host: string; base: string;
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

proc validate_ListSigningJobs_594056(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists all your signing jobs. You can use the <code>maxResults</code> parameter to limit the number of signing jobs that are returned in the response. If additional jobs remain to be listed, code signing returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that code signing returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : String for specifying the next set of paginated results to return. After you receive a response with truncated results, use this parameter in a subsequent request. Set it to the value of <code>nextToken</code> from the response that you just received.
  ##   platformId: JString
  ##             : The ID of microcontroller platform that you specified for the distribution of your code image.
  ##   requestedBy: JString
  ##              : The IAM principal that requested the signing job.
  ##   status: JString
  ##         : A status value with which to filter your results.
  ##   maxResults: JInt
  ##             : Specifies the maximum number of items to return in the response. Use this parameter when paginating results. If additional items exist beyond the number you specify, the <code>nextToken</code> element is set in the response. Use the <code>nextToken</code> value in a subsequent request to retrieve additional items. 
  section = newJObject()
  var valid_594058 = query.getOrDefault("nextToken")
  valid_594058 = validateParameter(valid_594058, JString, required = false,
                                 default = nil)
  if valid_594058 != nil:
    section.add "nextToken", valid_594058
  var valid_594059 = query.getOrDefault("platformId")
  valid_594059 = validateParameter(valid_594059, JString, required = false,
                                 default = nil)
  if valid_594059 != nil:
    section.add "platformId", valid_594059
  var valid_594060 = query.getOrDefault("requestedBy")
  valid_594060 = validateParameter(valid_594060, JString, required = false,
                                 default = nil)
  if valid_594060 != nil:
    section.add "requestedBy", valid_594060
  var valid_594074 = query.getOrDefault("status")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = newJString("InProgress"))
  if valid_594074 != nil:
    section.add "status", valid_594074
  var valid_594075 = query.getOrDefault("maxResults")
  valid_594075 = validateParameter(valid_594075, JInt, required = false, default = nil)
  if valid_594075 != nil:
    section.add "maxResults", valid_594075
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
  var valid_594076 = header.getOrDefault("X-Amz-Signature")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Signature", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Content-Sha256", valid_594077
  var valid_594078 = header.getOrDefault("X-Amz-Date")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = nil)
  if valid_594078 != nil:
    section.add "X-Amz-Date", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Credential")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Credential", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Security-Token")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Security-Token", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Algorithm")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Algorithm", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-SignedHeaders", valid_594082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594083: Call_ListSigningJobs_594055; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all your signing jobs. You can use the <code>maxResults</code> parameter to limit the number of signing jobs that are returned in the response. If additional jobs remain to be listed, code signing returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that code signing returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned. 
  ## 
  let valid = call_594083.validator(path, query, header, formData, body)
  let scheme = call_594083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594083.url(scheme.get, call_594083.host, call_594083.base,
                         call_594083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594083, url, valid)

proc call*(call_594084: Call_ListSigningJobs_594055; nextToken: string = "";
          platformId: string = ""; requestedBy: string = "";
          status: string = "InProgress"; maxResults: int = 0): Recallable =
  ## listSigningJobs
  ## Lists all your signing jobs. You can use the <code>maxResults</code> parameter to limit the number of signing jobs that are returned in the response. If additional jobs remain to be listed, code signing returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that code signing returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned. 
  ##   nextToken: string
  ##            : String for specifying the next set of paginated results to return. After you receive a response with truncated results, use this parameter in a subsequent request. Set it to the value of <code>nextToken</code> from the response that you just received.
  ##   platformId: string
  ##             : The ID of microcontroller platform that you specified for the distribution of your code image.
  ##   requestedBy: string
  ##              : The IAM principal that requested the signing job.
  ##   status: string
  ##         : A status value with which to filter your results.
  ##   maxResults: int
  ##             : Specifies the maximum number of items to return in the response. Use this parameter when paginating results. If additional items exist beyond the number you specify, the <code>nextToken</code> element is set in the response. Use the <code>nextToken</code> value in a subsequent request to retrieve additional items. 
  var query_594085 = newJObject()
  add(query_594085, "nextToken", newJString(nextToken))
  add(query_594085, "platformId", newJString(platformId))
  add(query_594085, "requestedBy", newJString(requestedBy))
  add(query_594085, "status", newJString(status))
  add(query_594085, "maxResults", newJInt(maxResults))
  result = call_594084.call(nil, query_594085, nil, nil, nil)

var listSigningJobs* = Call_ListSigningJobs_594055(name: "listSigningJobs",
    meth: HttpMethod.HttpGet, host: "signer.amazonaws.com", route: "/signing-jobs",
    validator: validate_ListSigningJobs_594056, base: "/", url: url_ListSigningJobs_594057,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSigningPlatforms_594100 = ref object of OpenApiRestCall_593389
proc url_ListSigningPlatforms_594102(protocol: Scheme; host: string; base: string;
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

proc validate_ListSigningPlatforms_594101(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all signing platforms available in code signing that match the request parameters. If additional jobs remain to be listed, code signing returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that code signing returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Value for specifying the next set of paginated results to return. After you receive a response with truncated results, use this parameter in a subsequent request. Set it to the value of <code>nextToken</code> from the response that you just received.
  ##   target: JString
  ##         : The validation template that is used by the target signing platform.
  ##   partner: JString
  ##          : Any partner entities connected to a signing platform.
  ##   category: JString
  ##           : The category type of a signing platform.
  ##   maxResults: JInt
  ##             : The maximum number of results to be returned by this operation.
  section = newJObject()
  var valid_594103 = query.getOrDefault("nextToken")
  valid_594103 = validateParameter(valid_594103, JString, required = false,
                                 default = nil)
  if valid_594103 != nil:
    section.add "nextToken", valid_594103
  var valid_594104 = query.getOrDefault("target")
  valid_594104 = validateParameter(valid_594104, JString, required = false,
                                 default = nil)
  if valid_594104 != nil:
    section.add "target", valid_594104
  var valid_594105 = query.getOrDefault("partner")
  valid_594105 = validateParameter(valid_594105, JString, required = false,
                                 default = nil)
  if valid_594105 != nil:
    section.add "partner", valid_594105
  var valid_594106 = query.getOrDefault("category")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "category", valid_594106
  var valid_594107 = query.getOrDefault("maxResults")
  valid_594107 = validateParameter(valid_594107, JInt, required = false, default = nil)
  if valid_594107 != nil:
    section.add "maxResults", valid_594107
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
  var valid_594108 = header.getOrDefault("X-Amz-Signature")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "X-Amz-Signature", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Content-Sha256", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Date")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Date", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Credential")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Credential", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Security-Token")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Security-Token", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Algorithm")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Algorithm", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-SignedHeaders", valid_594114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594115: Call_ListSigningPlatforms_594100; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all signing platforms available in code signing that match the request parameters. If additional jobs remain to be listed, code signing returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that code signing returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
  ## 
  let valid = call_594115.validator(path, query, header, formData, body)
  let scheme = call_594115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594115.url(scheme.get, call_594115.host, call_594115.base,
                         call_594115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594115, url, valid)

proc call*(call_594116: Call_ListSigningPlatforms_594100; nextToken: string = "";
          target: string = ""; partner: string = ""; category: string = "";
          maxResults: int = 0): Recallable =
  ## listSigningPlatforms
  ## Lists all signing platforms available in code signing that match the request parameters. If additional jobs remain to be listed, code signing returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that code signing returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
  ##   nextToken: string
  ##            : Value for specifying the next set of paginated results to return. After you receive a response with truncated results, use this parameter in a subsequent request. Set it to the value of <code>nextToken</code> from the response that you just received.
  ##   target: string
  ##         : The validation template that is used by the target signing platform.
  ##   partner: string
  ##          : Any partner entities connected to a signing platform.
  ##   category: string
  ##           : The category type of a signing platform.
  ##   maxResults: int
  ##             : The maximum number of results to be returned by this operation.
  var query_594117 = newJObject()
  add(query_594117, "nextToken", newJString(nextToken))
  add(query_594117, "target", newJString(target))
  add(query_594117, "partner", newJString(partner))
  add(query_594117, "category", newJString(category))
  add(query_594117, "maxResults", newJInt(maxResults))
  result = call_594116.call(nil, query_594117, nil, nil, nil)

var listSigningPlatforms* = Call_ListSigningPlatforms_594100(
    name: "listSigningPlatforms", meth: HttpMethod.HttpGet,
    host: "signer.amazonaws.com", route: "/signing-platforms",
    validator: validate_ListSigningPlatforms_594101, base: "/",
    url: url_ListSigningPlatforms_594102, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSigningProfiles_594118 = ref object of OpenApiRestCall_593389
proc url_ListSigningProfiles_594120(protocol: Scheme; host: string; base: string;
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

proc validate_ListSigningProfiles_594119(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists all available signing profiles in your AWS account. Returns only profiles with an <code>ACTIVE</code> status unless the <code>includeCanceled</code> request field is set to <code>true</code>. If additional jobs remain to be listed, code signing returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that code signing returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Value for specifying the next set of paginated results to return. After you receive a response with truncated results, use this parameter in a subsequent request. Set it to the value of <code>nextToken</code> from the response that you just received.
  ##   includeCanceled: JBool
  ##                  : Designates whether to include profiles with the status of <code>CANCELED</code>.
  ##   maxResults: JInt
  ##             : The maximum number of profiles to be returned.
  section = newJObject()
  var valid_594121 = query.getOrDefault("nextToken")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "nextToken", valid_594121
  var valid_594122 = query.getOrDefault("includeCanceled")
  valid_594122 = validateParameter(valid_594122, JBool, required = false, default = nil)
  if valid_594122 != nil:
    section.add "includeCanceled", valid_594122
  var valid_594123 = query.getOrDefault("maxResults")
  valid_594123 = validateParameter(valid_594123, JInt, required = false, default = nil)
  if valid_594123 != nil:
    section.add "maxResults", valid_594123
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
  var valid_594124 = header.getOrDefault("X-Amz-Signature")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Signature", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Content-Sha256", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Date")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Date", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-Credential")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-Credential", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Security-Token")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Security-Token", valid_594128
  var valid_594129 = header.getOrDefault("X-Amz-Algorithm")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-Algorithm", valid_594129
  var valid_594130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-SignedHeaders", valid_594130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594131: Call_ListSigningProfiles_594118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all available signing profiles in your AWS account. Returns only profiles with an <code>ACTIVE</code> status unless the <code>includeCanceled</code> request field is set to <code>true</code>. If additional jobs remain to be listed, code signing returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that code signing returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
  ## 
  let valid = call_594131.validator(path, query, header, formData, body)
  let scheme = call_594131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594131.url(scheme.get, call_594131.host, call_594131.base,
                         call_594131.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594131, url, valid)

proc call*(call_594132: Call_ListSigningProfiles_594118; nextToken: string = "";
          includeCanceled: bool = false; maxResults: int = 0): Recallable =
  ## listSigningProfiles
  ## Lists all available signing profiles in your AWS account. Returns only profiles with an <code>ACTIVE</code> status unless the <code>includeCanceled</code> request field is set to <code>true</code>. If additional jobs remain to be listed, code signing returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that code signing returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
  ##   nextToken: string
  ##            : Value for specifying the next set of paginated results to return. After you receive a response with truncated results, use this parameter in a subsequent request. Set it to the value of <code>nextToken</code> from the response that you just received.
  ##   includeCanceled: bool
  ##                  : Designates whether to include profiles with the status of <code>CANCELED</code>.
  ##   maxResults: int
  ##             : The maximum number of profiles to be returned.
  var query_594133 = newJObject()
  add(query_594133, "nextToken", newJString(nextToken))
  add(query_594133, "includeCanceled", newJBool(includeCanceled))
  add(query_594133, "maxResults", newJInt(maxResults))
  result = call_594132.call(nil, query_594133, nil, nil, nil)

var listSigningProfiles* = Call_ListSigningProfiles_594118(
    name: "listSigningProfiles", meth: HttpMethod.HttpGet,
    host: "signer.amazonaws.com", route: "/signing-profiles",
    validator: validate_ListSigningProfiles_594119, base: "/",
    url: url_ListSigningProfiles_594120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_594148 = ref object of OpenApiRestCall_593389
proc url_TagResource_594150(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_594149(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_594151 = path.getOrDefault("resourceArn")
  valid_594151 = validateParameter(valid_594151, JString, required = true,
                                 default = nil)
  if valid_594151 != nil:
    section.add "resourceArn", valid_594151
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
  var valid_594152 = header.getOrDefault("X-Amz-Signature")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Signature", valid_594152
  var valid_594153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594153 = validateParameter(valid_594153, JString, required = false,
                                 default = nil)
  if valid_594153 != nil:
    section.add "X-Amz-Content-Sha256", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Date")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Date", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-Credential")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Credential", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-Security-Token")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Security-Token", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-Algorithm")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-Algorithm", valid_594157
  var valid_594158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-SignedHeaders", valid_594158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594160: Call_TagResource_594148; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to a signing profile. Tags are labels that you can use to identify and organize your AWS resources. Each tag consists of a key and an optional value. You specify the signing profile using its Amazon Resource Name (ARN). You specify the tag by using a key-value pair.
  ## 
  let valid = call_594160.validator(path, query, header, formData, body)
  let scheme = call_594160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594160.url(scheme.get, call_594160.host, call_594160.base,
                         call_594160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594160, url, valid)

proc call*(call_594161: Call_TagResource_594148; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags to a signing profile. Tags are labels that you can use to identify and organize your AWS resources. Each tag consists of a key and an optional value. You specify the signing profile using its Amazon Resource Name (ARN). You specify the tag by using a key-value pair.
  ##   resourceArn: string (required)
  ##              : Amazon Resource Name (ARN) for the signing profile.
  ##   body: JObject (required)
  var path_594162 = newJObject()
  var body_594163 = newJObject()
  add(path_594162, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_594163 = body
  result = call_594161.call(path_594162, nil, nil, nil, body_594163)

var tagResource* = Call_TagResource_594148(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "signer.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_594149,
                                        base: "/", url: url_TagResource_594150,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_594134 = ref object of OpenApiRestCall_593389
proc url_ListTagsForResource_594136(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_594135(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_594137 = path.getOrDefault("resourceArn")
  valid_594137 = validateParameter(valid_594137, JString, required = true,
                                 default = nil)
  if valid_594137 != nil:
    section.add "resourceArn", valid_594137
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
  var valid_594138 = header.getOrDefault("X-Amz-Signature")
  valid_594138 = validateParameter(valid_594138, JString, required = false,
                                 default = nil)
  if valid_594138 != nil:
    section.add "X-Amz-Signature", valid_594138
  var valid_594139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Content-Sha256", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Date")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Date", valid_594140
  var valid_594141 = header.getOrDefault("X-Amz-Credential")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-Credential", valid_594141
  var valid_594142 = header.getOrDefault("X-Amz-Security-Token")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "X-Amz-Security-Token", valid_594142
  var valid_594143 = header.getOrDefault("X-Amz-Algorithm")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Algorithm", valid_594143
  var valid_594144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594144 = validateParameter(valid_594144, JString, required = false,
                                 default = nil)
  if valid_594144 != nil:
    section.add "X-Amz-SignedHeaders", valid_594144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594145: Call_ListTagsForResource_594134; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the tags associated with a signing profile resource.
  ## 
  let valid = call_594145.validator(path, query, header, formData, body)
  let scheme = call_594145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594145.url(scheme.get, call_594145.host, call_594145.base,
                         call_594145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594145, url, valid)

proc call*(call_594146: Call_ListTagsForResource_594134; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns a list of the tags associated with a signing profile resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the signing profile.
  var path_594147 = newJObject()
  add(path_594147, "resourceArn", newJString(resourceArn))
  result = call_594146.call(path_594147, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_594134(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "signer.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_594135, base: "/",
    url: url_ListTagsForResource_594136, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_594164 = ref object of OpenApiRestCall_593389
proc url_UntagResource_594166(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_594165(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_594167 = path.getOrDefault("resourceArn")
  valid_594167 = validateParameter(valid_594167, JString, required = true,
                                 default = nil)
  if valid_594167 != nil:
    section.add "resourceArn", valid_594167
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A list of tag keys to be removed from the signing profile .
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_594168 = query.getOrDefault("tagKeys")
  valid_594168 = validateParameter(valid_594168, JArray, required = true, default = nil)
  if valid_594168 != nil:
    section.add "tagKeys", valid_594168
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
  var valid_594169 = header.getOrDefault("X-Amz-Signature")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Signature", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Content-Sha256", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-Date")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Date", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-Credential")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-Credential", valid_594172
  var valid_594173 = header.getOrDefault("X-Amz-Security-Token")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-Security-Token", valid_594173
  var valid_594174 = header.getOrDefault("X-Amz-Algorithm")
  valid_594174 = validateParameter(valid_594174, JString, required = false,
                                 default = nil)
  if valid_594174 != nil:
    section.add "X-Amz-Algorithm", valid_594174
  var valid_594175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594175 = validateParameter(valid_594175, JString, required = false,
                                 default = nil)
  if valid_594175 != nil:
    section.add "X-Amz-SignedHeaders", valid_594175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594176: Call_UntagResource_594164; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove one or more tags from a signing profile. Specify a list of tag keys to remove the tags.
  ## 
  let valid = call_594176.validator(path, query, header, formData, body)
  let scheme = call_594176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594176.url(scheme.get, call_594176.host, call_594176.base,
                         call_594176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594176, url, valid)

proc call*(call_594177: Call_UntagResource_594164; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Remove one or more tags from a signing profile. Specify a list of tag keys to remove the tags.
  ##   resourceArn: string (required)
  ##              : Amazon Resource Name (ARN) for the signing profile .
  ##   tagKeys: JArray (required)
  ##          : A list of tag keys to be removed from the signing profile .
  var path_594178 = newJObject()
  var query_594179 = newJObject()
  add(path_594178, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_594179.add "tagKeys", tagKeys
  result = call_594177.call(path_594178, query_594179, nil, nil, nil)

var untagResource* = Call_UntagResource_594164(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "signer.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_594165,
    base: "/", url: url_UntagResource_594166, schemes: {Scheme.Https, Scheme.Http})
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
