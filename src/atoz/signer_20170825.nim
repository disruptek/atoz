
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Signer
## version: 2017-08-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## You can use Code Signing for Amazon FreeRTOS (AWS Signer) to sign code that you created for any of the IoT devices that Amazon Web Services supports. AWS Signer is integrated with Amazon FreeRTOS, AWS Certificate Manager, and AWS CloudTrail. Amazon FreeRTOS customers can use AWS Signer to sign code images before making them available for microcontrollers. You can use ACM to import third-party certificates to be used by AWS Signer. For general information about using AWS Signer, see the <a href="http://docs.aws.amazon.com/signer/latest/developerguide/Welcome.html">Code Signing for Amazon FreeRTOS Developer Guide</a>.
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
  Call_PutSigningProfile_592973 = ref object of OpenApiRestCall_592364
proc url_PutSigningProfile_592975(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_PutSigningProfile_592974(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates a signing profile. A signing profile is an AWS Signer template that can be used to carry out a pre-defined signing job. For more information, see <a href="http://docs.aws.amazon.com/signer/latest/developerguide/gs-profile.html">http://docs.aws.amazon.com/signer/latest/developerguide/gs-profile.html</a> 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   profileName: JString (required)
  ##              : The name of the signing profile to be created.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `profileName` field"
  var valid_592976 = path.getOrDefault("profileName")
  valid_592976 = validateParameter(valid_592976, JString, required = true,
                                 default = nil)
  if valid_592976 != nil:
    section.add "profileName", valid_592976
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
  var valid_592977 = header.getOrDefault("X-Amz-Signature")
  valid_592977 = validateParameter(valid_592977, JString, required = false,
                                 default = nil)
  if valid_592977 != nil:
    section.add "X-Amz-Signature", valid_592977
  var valid_592978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "X-Amz-Content-Sha256", valid_592978
  var valid_592979 = header.getOrDefault("X-Amz-Date")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Date", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Credential")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Credential", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Security-Token")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Security-Token", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-Algorithm")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-Algorithm", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-SignedHeaders", valid_592983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592985: Call_PutSigningProfile_592973; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a signing profile. A signing profile is an AWS Signer template that can be used to carry out a pre-defined signing job. For more information, see <a href="http://docs.aws.amazon.com/signer/latest/developerguide/gs-profile.html">http://docs.aws.amazon.com/signer/latest/developerguide/gs-profile.html</a> 
  ## 
  let valid = call_592985.validator(path, query, header, formData, body)
  let scheme = call_592985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592985.url(scheme.get, call_592985.host, call_592985.base,
                         call_592985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592985, url, valid)

proc call*(call_592986: Call_PutSigningProfile_592973; profileName: string;
          body: JsonNode): Recallable =
  ## putSigningProfile
  ## Creates a signing profile. A signing profile is an AWS Signer template that can be used to carry out a pre-defined signing job. For more information, see <a href="http://docs.aws.amazon.com/signer/latest/developerguide/gs-profile.html">http://docs.aws.amazon.com/signer/latest/developerguide/gs-profile.html</a> 
  ##   profileName: string (required)
  ##              : The name of the signing profile to be created.
  ##   body: JObject (required)
  var path_592987 = newJObject()
  var body_592988 = newJObject()
  add(path_592987, "profileName", newJString(profileName))
  if body != nil:
    body_592988 = body
  result = call_592986.call(path_592987, nil, nil, nil, body_592988)

var putSigningProfile* = Call_PutSigningProfile_592973(name: "putSigningProfile",
    meth: HttpMethod.HttpPut, host: "signer.amazonaws.com",
    route: "/signing-profiles/{profileName}",
    validator: validate_PutSigningProfile_592974, base: "/",
    url: url_PutSigningProfile_592975, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSigningProfile_592703 = ref object of OpenApiRestCall_592364
proc url_GetSigningProfile_592705(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetSigningProfile_592704(path: JsonNode; query: JsonNode;
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
  var valid_592831 = path.getOrDefault("profileName")
  valid_592831 = validateParameter(valid_592831, JString, required = true,
                                 default = nil)
  if valid_592831 != nil:
    section.add "profileName", valid_592831
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
  var valid_592832 = header.getOrDefault("X-Amz-Signature")
  valid_592832 = validateParameter(valid_592832, JString, required = false,
                                 default = nil)
  if valid_592832 != nil:
    section.add "X-Amz-Signature", valid_592832
  var valid_592833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592833 = validateParameter(valid_592833, JString, required = false,
                                 default = nil)
  if valid_592833 != nil:
    section.add "X-Amz-Content-Sha256", valid_592833
  var valid_592834 = header.getOrDefault("X-Amz-Date")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "X-Amz-Date", valid_592834
  var valid_592835 = header.getOrDefault("X-Amz-Credential")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Credential", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Security-Token")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Security-Token", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-Algorithm")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-Algorithm", valid_592837
  var valid_592838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592838 = validateParameter(valid_592838, JString, required = false,
                                 default = nil)
  if valid_592838 != nil:
    section.add "X-Amz-SignedHeaders", valid_592838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592861: Call_GetSigningProfile_592703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information on a specific signing profile.
  ## 
  let valid = call_592861.validator(path, query, header, formData, body)
  let scheme = call_592861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592861.url(scheme.get, call_592861.host, call_592861.base,
                         call_592861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592861, url, valid)

proc call*(call_592932: Call_GetSigningProfile_592703; profileName: string): Recallable =
  ## getSigningProfile
  ## Returns information on a specific signing profile.
  ##   profileName: string (required)
  ##              : The name of the target signing profile.
  var path_592933 = newJObject()
  add(path_592933, "profileName", newJString(profileName))
  result = call_592932.call(path_592933, nil, nil, nil, nil)

var getSigningProfile* = Call_GetSigningProfile_592703(name: "getSigningProfile",
    meth: HttpMethod.HttpGet, host: "signer.amazonaws.com",
    route: "/signing-profiles/{profileName}",
    validator: validate_GetSigningProfile_592704, base: "/",
    url: url_GetSigningProfile_592705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelSigningProfile_592989 = ref object of OpenApiRestCall_592364
proc url_CancelSigningProfile_592991(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CancelSigningProfile_592990(path: JsonNode; query: JsonNode;
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
  var valid_592992 = path.getOrDefault("profileName")
  valid_592992 = validateParameter(valid_592992, JString, required = true,
                                 default = nil)
  if valid_592992 != nil:
    section.add "profileName", valid_592992
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
  var valid_592993 = header.getOrDefault("X-Amz-Signature")
  valid_592993 = validateParameter(valid_592993, JString, required = false,
                                 default = nil)
  if valid_592993 != nil:
    section.add "X-Amz-Signature", valid_592993
  var valid_592994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Content-Sha256", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-Date")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Date", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-Credential")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Credential", valid_592996
  var valid_592997 = header.getOrDefault("X-Amz-Security-Token")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-Security-Token", valid_592997
  var valid_592998 = header.getOrDefault("X-Amz-Algorithm")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "X-Amz-Algorithm", valid_592998
  var valid_592999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-SignedHeaders", valid_592999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593000: Call_CancelSigningProfile_592989; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the state of an <code>ACTIVE</code> signing profile to <code>CANCELED</code>. A canceled profile is still viewable with the <code>ListSigningProfiles</code> operation, but it cannot perform new signing jobs, and is deleted two years after cancelation.
  ## 
  let valid = call_593000.validator(path, query, header, formData, body)
  let scheme = call_593000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593000.url(scheme.get, call_593000.host, call_593000.base,
                         call_593000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593000, url, valid)

proc call*(call_593001: Call_CancelSigningProfile_592989; profileName: string): Recallable =
  ## cancelSigningProfile
  ## Changes the state of an <code>ACTIVE</code> signing profile to <code>CANCELED</code>. A canceled profile is still viewable with the <code>ListSigningProfiles</code> operation, but it cannot perform new signing jobs, and is deleted two years after cancelation.
  ##   profileName: string (required)
  ##              : The name of the signing profile to be canceled.
  var path_593002 = newJObject()
  add(path_593002, "profileName", newJString(profileName))
  result = call_593001.call(path_593002, nil, nil, nil, nil)

var cancelSigningProfile* = Call_CancelSigningProfile_592989(
    name: "cancelSigningProfile", meth: HttpMethod.HttpDelete,
    host: "signer.amazonaws.com", route: "/signing-profiles/{profileName}",
    validator: validate_CancelSigningProfile_592990, base: "/",
    url: url_CancelSigningProfile_592991, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSigningJob_593003 = ref object of OpenApiRestCall_592364
proc url_DescribeSigningJob_593005(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeSigningJob_593004(path: JsonNode; query: JsonNode;
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
  var valid_593006 = path.getOrDefault("jobId")
  valid_593006 = validateParameter(valid_593006, JString, required = true,
                                 default = nil)
  if valid_593006 != nil:
    section.add "jobId", valid_593006
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
  var valid_593007 = header.getOrDefault("X-Amz-Signature")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Signature", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-Content-Sha256", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-Date")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-Date", valid_593009
  var valid_593010 = header.getOrDefault("X-Amz-Credential")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Credential", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-Security-Token")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Security-Token", valid_593011
  var valid_593012 = header.getOrDefault("X-Amz-Algorithm")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-Algorithm", valid_593012
  var valid_593013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "X-Amz-SignedHeaders", valid_593013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593014: Call_DescribeSigningJob_593003; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific code signing job. You specify the job by using the <code>jobId</code> value that is returned by the <a>StartSigningJob</a> operation. 
  ## 
  let valid = call_593014.validator(path, query, header, formData, body)
  let scheme = call_593014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593014.url(scheme.get, call_593014.host, call_593014.base,
                         call_593014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593014, url, valid)

proc call*(call_593015: Call_DescribeSigningJob_593003; jobId: string): Recallable =
  ## describeSigningJob
  ## Returns information about a specific code signing job. You specify the job by using the <code>jobId</code> value that is returned by the <a>StartSigningJob</a> operation. 
  ##   jobId: string (required)
  ##        : The ID of the signing job on input.
  var path_593016 = newJObject()
  add(path_593016, "jobId", newJString(jobId))
  result = call_593015.call(path_593016, nil, nil, nil, nil)

var describeSigningJob* = Call_DescribeSigningJob_593003(
    name: "describeSigningJob", meth: HttpMethod.HttpGet,
    host: "signer.amazonaws.com", route: "/signing-jobs/{jobId}",
    validator: validate_DescribeSigningJob_593004, base: "/",
    url: url_DescribeSigningJob_593005, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSigningPlatform_593017 = ref object of OpenApiRestCall_592364
proc url_GetSigningPlatform_593019(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetSigningPlatform_593018(path: JsonNode; query: JsonNode;
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
  var valid_593020 = path.getOrDefault("platformId")
  valid_593020 = validateParameter(valid_593020, JString, required = true,
                                 default = nil)
  if valid_593020 != nil:
    section.add "platformId", valid_593020
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
  var valid_593021 = header.getOrDefault("X-Amz-Signature")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-Signature", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Content-Sha256", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-Date")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-Date", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-Credential")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Credential", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Security-Token")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Security-Token", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-Algorithm")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Algorithm", valid_593026
  var valid_593027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-SignedHeaders", valid_593027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593028: Call_GetSigningPlatform_593017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information on a specific signing platform.
  ## 
  let valid = call_593028.validator(path, query, header, formData, body)
  let scheme = call_593028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593028.url(scheme.get, call_593028.host, call_593028.base,
                         call_593028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593028, url, valid)

proc call*(call_593029: Call_GetSigningPlatform_593017; platformId: string): Recallable =
  ## getSigningPlatform
  ## Returns information on a specific signing platform.
  ##   platformId: string (required)
  ##             : The ID of the target signing platform.
  var path_593030 = newJObject()
  add(path_593030, "platformId", newJString(platformId))
  result = call_593029.call(path_593030, nil, nil, nil, nil)

var getSigningPlatform* = Call_GetSigningPlatform_593017(
    name: "getSigningPlatform", meth: HttpMethod.HttpGet,
    host: "signer.amazonaws.com", route: "/signing-platforms/{platformId}",
    validator: validate_GetSigningPlatform_593018, base: "/",
    url: url_GetSigningPlatform_593019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSigningJob_593062 = ref object of OpenApiRestCall_592364
proc url_StartSigningJob_593064(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartSigningJob_593063(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Initiates a signing job to be performed on the code provided. Signing jobs are viewable by the <code>ListSigningJobs</code> operation for two years after they are performed. Note the following requirements: </p> <ul> <li> <p> You must create an Amazon S3 source bucket. For more information, see <a href="http://docs.aws.amazon.com/AmazonS3/latest/gsg/CreatingABucket.html">Create a Bucket</a> in the <i>Amazon S3 Getting Started Guide</i>. </p> </li> <li> <p>Your S3 source bucket must be version enabled.</p> </li> <li> <p>You must create an S3 destination bucket. AWS Signer uses your S3 destination bucket to write your signed code.</p> </li> <li> <p>You specify the name of the source and destination buckets when calling the <code>StartSigningJob</code> operation.</p> </li> <li> <p>You must also specify a request token that identifies your request to AWS Signer. </p> </li> </ul> <p>You can call the <a>DescribeSigningJob</a> and the <a>ListSigningJobs</a> actions after you call <code>StartSigningJob</code>.</p> <p>For a Java example that shows how to use this action, see <a href="http://docs.aws.amazon.com/acm/latest/userguide/">http://docs.aws.amazon.com/acm/latest/userguide/</a> </p>
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
  var valid_593065 = header.getOrDefault("X-Amz-Signature")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-Signature", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-Content-Sha256", valid_593066
  var valid_593067 = header.getOrDefault("X-Amz-Date")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-Date", valid_593067
  var valid_593068 = header.getOrDefault("X-Amz-Credential")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-Credential", valid_593068
  var valid_593069 = header.getOrDefault("X-Amz-Security-Token")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "X-Amz-Security-Token", valid_593069
  var valid_593070 = header.getOrDefault("X-Amz-Algorithm")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "X-Amz-Algorithm", valid_593070
  var valid_593071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-SignedHeaders", valid_593071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593073: Call_StartSigningJob_593062; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a signing job to be performed on the code provided. Signing jobs are viewable by the <code>ListSigningJobs</code> operation for two years after they are performed. Note the following requirements: </p> <ul> <li> <p> You must create an Amazon S3 source bucket. For more information, see <a href="http://docs.aws.amazon.com/AmazonS3/latest/gsg/CreatingABucket.html">Create a Bucket</a> in the <i>Amazon S3 Getting Started Guide</i>. </p> </li> <li> <p>Your S3 source bucket must be version enabled.</p> </li> <li> <p>You must create an S3 destination bucket. AWS Signer uses your S3 destination bucket to write your signed code.</p> </li> <li> <p>You specify the name of the source and destination buckets when calling the <code>StartSigningJob</code> operation.</p> </li> <li> <p>You must also specify a request token that identifies your request to AWS Signer. </p> </li> </ul> <p>You can call the <a>DescribeSigningJob</a> and the <a>ListSigningJobs</a> actions after you call <code>StartSigningJob</code>.</p> <p>For a Java example that shows how to use this action, see <a href="http://docs.aws.amazon.com/acm/latest/userguide/">http://docs.aws.amazon.com/acm/latest/userguide/</a> </p>
  ## 
  let valid = call_593073.validator(path, query, header, formData, body)
  let scheme = call_593073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593073.url(scheme.get, call_593073.host, call_593073.base,
                         call_593073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593073, url, valid)

proc call*(call_593074: Call_StartSigningJob_593062; body: JsonNode): Recallable =
  ## startSigningJob
  ## <p>Initiates a signing job to be performed on the code provided. Signing jobs are viewable by the <code>ListSigningJobs</code> operation for two years after they are performed. Note the following requirements: </p> <ul> <li> <p> You must create an Amazon S3 source bucket. For more information, see <a href="http://docs.aws.amazon.com/AmazonS3/latest/gsg/CreatingABucket.html">Create a Bucket</a> in the <i>Amazon S3 Getting Started Guide</i>. </p> </li> <li> <p>Your S3 source bucket must be version enabled.</p> </li> <li> <p>You must create an S3 destination bucket. AWS Signer uses your S3 destination bucket to write your signed code.</p> </li> <li> <p>You specify the name of the source and destination buckets when calling the <code>StartSigningJob</code> operation.</p> </li> <li> <p>You must also specify a request token that identifies your request to AWS Signer. </p> </li> </ul> <p>You can call the <a>DescribeSigningJob</a> and the <a>ListSigningJobs</a> actions after you call <code>StartSigningJob</code>.</p> <p>For a Java example that shows how to use this action, see <a href="http://docs.aws.amazon.com/acm/latest/userguide/">http://docs.aws.amazon.com/acm/latest/userguide/</a> </p>
  ##   body: JObject (required)
  var body_593075 = newJObject()
  if body != nil:
    body_593075 = body
  result = call_593074.call(nil, nil, nil, nil, body_593075)

var startSigningJob* = Call_StartSigningJob_593062(name: "startSigningJob",
    meth: HttpMethod.HttpPost, host: "signer.amazonaws.com", route: "/signing-jobs",
    validator: validate_StartSigningJob_593063, base: "/", url: url_StartSigningJob_593064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSigningJobs_593031 = ref object of OpenApiRestCall_592364
proc url_ListSigningJobs_593033(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSigningJobs_593032(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists all your signing jobs. You can use the <code>maxResults</code> parameter to limit the number of signing jobs that are returned in the response. If additional jobs remain to be listed, AWS Signer returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that AWS Signer returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned. 
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
  var valid_593034 = query.getOrDefault("nextToken")
  valid_593034 = validateParameter(valid_593034, JString, required = false,
                                 default = nil)
  if valid_593034 != nil:
    section.add "nextToken", valid_593034
  var valid_593035 = query.getOrDefault("platformId")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "platformId", valid_593035
  var valid_593036 = query.getOrDefault("requestedBy")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "requestedBy", valid_593036
  var valid_593050 = query.getOrDefault("status")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = newJString("InProgress"))
  if valid_593050 != nil:
    section.add "status", valid_593050
  var valid_593051 = query.getOrDefault("maxResults")
  valid_593051 = validateParameter(valid_593051, JInt, required = false, default = nil)
  if valid_593051 != nil:
    section.add "maxResults", valid_593051
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
  var valid_593052 = header.getOrDefault("X-Amz-Signature")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-Signature", valid_593052
  var valid_593053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Content-Sha256", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-Date")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Date", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Credential")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Credential", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-Security-Token")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-Security-Token", valid_593056
  var valid_593057 = header.getOrDefault("X-Amz-Algorithm")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "X-Amz-Algorithm", valid_593057
  var valid_593058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593058 = validateParameter(valid_593058, JString, required = false,
                                 default = nil)
  if valid_593058 != nil:
    section.add "X-Amz-SignedHeaders", valid_593058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593059: Call_ListSigningJobs_593031; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all your signing jobs. You can use the <code>maxResults</code> parameter to limit the number of signing jobs that are returned in the response. If additional jobs remain to be listed, AWS Signer returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that AWS Signer returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned. 
  ## 
  let valid = call_593059.validator(path, query, header, formData, body)
  let scheme = call_593059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593059.url(scheme.get, call_593059.host, call_593059.base,
                         call_593059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593059, url, valid)

proc call*(call_593060: Call_ListSigningJobs_593031; nextToken: string = "";
          platformId: string = ""; requestedBy: string = "";
          status: string = "InProgress"; maxResults: int = 0): Recallable =
  ## listSigningJobs
  ## Lists all your signing jobs. You can use the <code>maxResults</code> parameter to limit the number of signing jobs that are returned in the response. If additional jobs remain to be listed, AWS Signer returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that AWS Signer returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned. 
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
  var query_593061 = newJObject()
  add(query_593061, "nextToken", newJString(nextToken))
  add(query_593061, "platformId", newJString(platformId))
  add(query_593061, "requestedBy", newJString(requestedBy))
  add(query_593061, "status", newJString(status))
  add(query_593061, "maxResults", newJInt(maxResults))
  result = call_593060.call(nil, query_593061, nil, nil, nil)

var listSigningJobs* = Call_ListSigningJobs_593031(name: "listSigningJobs",
    meth: HttpMethod.HttpGet, host: "signer.amazonaws.com", route: "/signing-jobs",
    validator: validate_ListSigningJobs_593032, base: "/", url: url_ListSigningJobs_593033,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSigningPlatforms_593076 = ref object of OpenApiRestCall_592364
proc url_ListSigningPlatforms_593078(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSigningPlatforms_593077(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all signing platforms available in AWS Signer that match the request parameters. If additional jobs remain to be listed, AWS Signer returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that AWS Signer returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
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
  var valid_593079 = query.getOrDefault("nextToken")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "nextToken", valid_593079
  var valid_593080 = query.getOrDefault("target")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "target", valid_593080
  var valid_593081 = query.getOrDefault("partner")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "partner", valid_593081
  var valid_593082 = query.getOrDefault("category")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "category", valid_593082
  var valid_593083 = query.getOrDefault("maxResults")
  valid_593083 = validateParameter(valid_593083, JInt, required = false, default = nil)
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
  if body != nil:
    result.add "body", body

proc call*(call_593091: Call_ListSigningPlatforms_593076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all signing platforms available in AWS Signer that match the request parameters. If additional jobs remain to be listed, AWS Signer returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that AWS Signer returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
  ## 
  let valid = call_593091.validator(path, query, header, formData, body)
  let scheme = call_593091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593091.url(scheme.get, call_593091.host, call_593091.base,
                         call_593091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593091, url, valid)

proc call*(call_593092: Call_ListSigningPlatforms_593076; nextToken: string = "";
          target: string = ""; partner: string = ""; category: string = "";
          maxResults: int = 0): Recallable =
  ## listSigningPlatforms
  ## Lists all signing platforms available in AWS Signer that match the request parameters. If additional jobs remain to be listed, AWS Signer returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that AWS Signer returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
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
  var query_593093 = newJObject()
  add(query_593093, "nextToken", newJString(nextToken))
  add(query_593093, "target", newJString(target))
  add(query_593093, "partner", newJString(partner))
  add(query_593093, "category", newJString(category))
  add(query_593093, "maxResults", newJInt(maxResults))
  result = call_593092.call(nil, query_593093, nil, nil, nil)

var listSigningPlatforms* = Call_ListSigningPlatforms_593076(
    name: "listSigningPlatforms", meth: HttpMethod.HttpGet,
    host: "signer.amazonaws.com", route: "/signing-platforms",
    validator: validate_ListSigningPlatforms_593077, base: "/",
    url: url_ListSigningPlatforms_593078, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSigningProfiles_593094 = ref object of OpenApiRestCall_592364
proc url_ListSigningProfiles_593096(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSigningProfiles_593095(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists all available signing profiles in your AWS account. Returns only profiles with an <code>ACTIVE</code> status unless the <code>includeCanceled</code> request field is set to <code>true</code>. If additional jobs remain to be listed, AWS Signer returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that AWS Signer returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
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
  var valid_593097 = query.getOrDefault("nextToken")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "nextToken", valid_593097
  var valid_593098 = query.getOrDefault("includeCanceled")
  valid_593098 = validateParameter(valid_593098, JBool, required = false, default = nil)
  if valid_593098 != nil:
    section.add "includeCanceled", valid_593098
  var valid_593099 = query.getOrDefault("maxResults")
  valid_593099 = validateParameter(valid_593099, JInt, required = false, default = nil)
  if valid_593099 != nil:
    section.add "maxResults", valid_593099
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
  var valid_593100 = header.getOrDefault("X-Amz-Signature")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-Signature", valid_593100
  var valid_593101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-Content-Sha256", valid_593101
  var valid_593102 = header.getOrDefault("X-Amz-Date")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "X-Amz-Date", valid_593102
  var valid_593103 = header.getOrDefault("X-Amz-Credential")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "X-Amz-Credential", valid_593103
  var valid_593104 = header.getOrDefault("X-Amz-Security-Token")
  valid_593104 = validateParameter(valid_593104, JString, required = false,
                                 default = nil)
  if valid_593104 != nil:
    section.add "X-Amz-Security-Token", valid_593104
  var valid_593105 = header.getOrDefault("X-Amz-Algorithm")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "X-Amz-Algorithm", valid_593105
  var valid_593106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593106 = validateParameter(valid_593106, JString, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "X-Amz-SignedHeaders", valid_593106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593107: Call_ListSigningProfiles_593094; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all available signing profiles in your AWS account. Returns only profiles with an <code>ACTIVE</code> status unless the <code>includeCanceled</code> request field is set to <code>true</code>. If additional jobs remain to be listed, AWS Signer returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that AWS Signer returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
  ## 
  let valid = call_593107.validator(path, query, header, formData, body)
  let scheme = call_593107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593107.url(scheme.get, call_593107.host, call_593107.base,
                         call_593107.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593107, url, valid)

proc call*(call_593108: Call_ListSigningProfiles_593094; nextToken: string = "";
          includeCanceled: bool = false; maxResults: int = 0): Recallable =
  ## listSigningProfiles
  ## Lists all available signing profiles in your AWS account. Returns only profiles with an <code>ACTIVE</code> status unless the <code>includeCanceled</code> request field is set to <code>true</code>. If additional jobs remain to be listed, AWS Signer returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that AWS Signer returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
  ##   nextToken: string
  ##            : Value for specifying the next set of paginated results to return. After you receive a response with truncated results, use this parameter in a subsequent request. Set it to the value of <code>nextToken</code> from the response that you just received.
  ##   includeCanceled: bool
  ##                  : Designates whether to include profiles with the status of <code>CANCELED</code>.
  ##   maxResults: int
  ##             : The maximum number of profiles to be returned.
  var query_593109 = newJObject()
  add(query_593109, "nextToken", newJString(nextToken))
  add(query_593109, "includeCanceled", newJBool(includeCanceled))
  add(query_593109, "maxResults", newJInt(maxResults))
  result = call_593108.call(nil, query_593109, nil, nil, nil)

var listSigningProfiles* = Call_ListSigningProfiles_593094(
    name: "listSigningProfiles", meth: HttpMethod.HttpGet,
    host: "signer.amazonaws.com", route: "/signing-profiles",
    validator: validate_ListSigningProfiles_593095, base: "/",
    url: url_ListSigningProfiles_593096, schemes: {Scheme.Https, Scheme.Http})
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
