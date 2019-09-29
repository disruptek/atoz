
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

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
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
  Call_PutSigningProfile_594044 = ref object of OpenApiRestCall_593437
proc url_PutSigningProfile_594046(protocol: Scheme; host: string; base: string;
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

proc validate_PutSigningProfile_594045(path: JsonNode; query: JsonNode;
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
  var valid_594047 = path.getOrDefault("profileName")
  valid_594047 = validateParameter(valid_594047, JString, required = true,
                                 default = nil)
  if valid_594047 != nil:
    section.add "profileName", valid_594047
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
  var valid_594048 = header.getOrDefault("X-Amz-Date")
  valid_594048 = validateParameter(valid_594048, JString, required = false,
                                 default = nil)
  if valid_594048 != nil:
    section.add "X-Amz-Date", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Security-Token")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Security-Token", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Content-Sha256", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Algorithm")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Algorithm", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-Signature")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-Signature", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-SignedHeaders", valid_594053
  var valid_594054 = header.getOrDefault("X-Amz-Credential")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-Credential", valid_594054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594056: Call_PutSigningProfile_594044; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a signing profile. A signing profile is an AWS Signer template that can be used to carry out a pre-defined signing job. For more information, see <a href="http://docs.aws.amazon.com/signer/latest/developerguide/gs-profile.html">http://docs.aws.amazon.com/signer/latest/developerguide/gs-profile.html</a> 
  ## 
  let valid = call_594056.validator(path, query, header, formData, body)
  let scheme = call_594056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594056.url(scheme.get, call_594056.host, call_594056.base,
                         call_594056.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594056, url, valid)

proc call*(call_594057: Call_PutSigningProfile_594044; profileName: string;
          body: JsonNode): Recallable =
  ## putSigningProfile
  ## Creates a signing profile. A signing profile is an AWS Signer template that can be used to carry out a pre-defined signing job. For more information, see <a href="http://docs.aws.amazon.com/signer/latest/developerguide/gs-profile.html">http://docs.aws.amazon.com/signer/latest/developerguide/gs-profile.html</a> 
  ##   profileName: string (required)
  ##              : The name of the signing profile to be created.
  ##   body: JObject (required)
  var path_594058 = newJObject()
  var body_594059 = newJObject()
  add(path_594058, "profileName", newJString(profileName))
  if body != nil:
    body_594059 = body
  result = call_594057.call(path_594058, nil, nil, nil, body_594059)

var putSigningProfile* = Call_PutSigningProfile_594044(name: "putSigningProfile",
    meth: HttpMethod.HttpPut, host: "signer.amazonaws.com",
    route: "/signing-profiles/{profileName}",
    validator: validate_PutSigningProfile_594045, base: "/",
    url: url_PutSigningProfile_594046, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSigningProfile_593774 = ref object of OpenApiRestCall_593437
proc url_GetSigningProfile_593776(protocol: Scheme; host: string; base: string;
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

proc validate_GetSigningProfile_593775(path: JsonNode; query: JsonNode;
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
  var valid_593902 = path.getOrDefault("profileName")
  valid_593902 = validateParameter(valid_593902, JString, required = true,
                                 default = nil)
  if valid_593902 != nil:
    section.add "profileName", valid_593902
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
  var valid_593903 = header.getOrDefault("X-Amz-Date")
  valid_593903 = validateParameter(valid_593903, JString, required = false,
                                 default = nil)
  if valid_593903 != nil:
    section.add "X-Amz-Date", valid_593903
  var valid_593904 = header.getOrDefault("X-Amz-Security-Token")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "X-Amz-Security-Token", valid_593904
  var valid_593905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Content-Sha256", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Algorithm")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Algorithm", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-Signature")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-Signature", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-SignedHeaders", valid_593908
  var valid_593909 = header.getOrDefault("X-Amz-Credential")
  valid_593909 = validateParameter(valid_593909, JString, required = false,
                                 default = nil)
  if valid_593909 != nil:
    section.add "X-Amz-Credential", valid_593909
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593932: Call_GetSigningProfile_593774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information on a specific signing profile.
  ## 
  let valid = call_593932.validator(path, query, header, formData, body)
  let scheme = call_593932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593932.url(scheme.get, call_593932.host, call_593932.base,
                         call_593932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593932, url, valid)

proc call*(call_594003: Call_GetSigningProfile_593774; profileName: string): Recallable =
  ## getSigningProfile
  ## Returns information on a specific signing profile.
  ##   profileName: string (required)
  ##              : The name of the target signing profile.
  var path_594004 = newJObject()
  add(path_594004, "profileName", newJString(profileName))
  result = call_594003.call(path_594004, nil, nil, nil, nil)

var getSigningProfile* = Call_GetSigningProfile_593774(name: "getSigningProfile",
    meth: HttpMethod.HttpGet, host: "signer.amazonaws.com",
    route: "/signing-profiles/{profileName}",
    validator: validate_GetSigningProfile_593775, base: "/",
    url: url_GetSigningProfile_593776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelSigningProfile_594060 = ref object of OpenApiRestCall_593437
proc url_CancelSigningProfile_594062(protocol: Scheme; host: string; base: string;
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

proc validate_CancelSigningProfile_594061(path: JsonNode; query: JsonNode;
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
  var valid_594063 = path.getOrDefault("profileName")
  valid_594063 = validateParameter(valid_594063, JString, required = true,
                                 default = nil)
  if valid_594063 != nil:
    section.add "profileName", valid_594063
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
  var valid_594064 = header.getOrDefault("X-Amz-Date")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Date", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Security-Token")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Security-Token", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Content-Sha256", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-Algorithm")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-Algorithm", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Signature")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Signature", valid_594068
  var valid_594069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-SignedHeaders", valid_594069
  var valid_594070 = header.getOrDefault("X-Amz-Credential")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-Credential", valid_594070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594071: Call_CancelSigningProfile_594060; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the state of an <code>ACTIVE</code> signing profile to <code>CANCELED</code>. A canceled profile is still viewable with the <code>ListSigningProfiles</code> operation, but it cannot perform new signing jobs, and is deleted two years after cancelation.
  ## 
  let valid = call_594071.validator(path, query, header, formData, body)
  let scheme = call_594071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594071.url(scheme.get, call_594071.host, call_594071.base,
                         call_594071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594071, url, valid)

proc call*(call_594072: Call_CancelSigningProfile_594060; profileName: string): Recallable =
  ## cancelSigningProfile
  ## Changes the state of an <code>ACTIVE</code> signing profile to <code>CANCELED</code>. A canceled profile is still viewable with the <code>ListSigningProfiles</code> operation, but it cannot perform new signing jobs, and is deleted two years after cancelation.
  ##   profileName: string (required)
  ##              : The name of the signing profile to be canceled.
  var path_594073 = newJObject()
  add(path_594073, "profileName", newJString(profileName))
  result = call_594072.call(path_594073, nil, nil, nil, nil)

var cancelSigningProfile* = Call_CancelSigningProfile_594060(
    name: "cancelSigningProfile", meth: HttpMethod.HttpDelete,
    host: "signer.amazonaws.com", route: "/signing-profiles/{profileName}",
    validator: validate_CancelSigningProfile_594061, base: "/",
    url: url_CancelSigningProfile_594062, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSigningJob_594074 = ref object of OpenApiRestCall_593437
proc url_DescribeSigningJob_594076(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeSigningJob_594075(path: JsonNode; query: JsonNode;
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
  var valid_594077 = path.getOrDefault("jobId")
  valid_594077 = validateParameter(valid_594077, JString, required = true,
                                 default = nil)
  if valid_594077 != nil:
    section.add "jobId", valid_594077
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
  var valid_594078 = header.getOrDefault("X-Amz-Date")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = nil)
  if valid_594078 != nil:
    section.add "X-Amz-Date", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Security-Token")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Security-Token", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Content-Sha256", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Algorithm")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Algorithm", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-Signature")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-Signature", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-SignedHeaders", valid_594083
  var valid_594084 = header.getOrDefault("X-Amz-Credential")
  valid_594084 = validateParameter(valid_594084, JString, required = false,
                                 default = nil)
  if valid_594084 != nil:
    section.add "X-Amz-Credential", valid_594084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594085: Call_DescribeSigningJob_594074; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific code signing job. You specify the job by using the <code>jobId</code> value that is returned by the <a>StartSigningJob</a> operation. 
  ## 
  let valid = call_594085.validator(path, query, header, formData, body)
  let scheme = call_594085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594085.url(scheme.get, call_594085.host, call_594085.base,
                         call_594085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594085, url, valid)

proc call*(call_594086: Call_DescribeSigningJob_594074; jobId: string): Recallable =
  ## describeSigningJob
  ## Returns information about a specific code signing job. You specify the job by using the <code>jobId</code> value that is returned by the <a>StartSigningJob</a> operation. 
  ##   jobId: string (required)
  ##        : The ID of the signing job on input.
  var path_594087 = newJObject()
  add(path_594087, "jobId", newJString(jobId))
  result = call_594086.call(path_594087, nil, nil, nil, nil)

var describeSigningJob* = Call_DescribeSigningJob_594074(
    name: "describeSigningJob", meth: HttpMethod.HttpGet,
    host: "signer.amazonaws.com", route: "/signing-jobs/{jobId}",
    validator: validate_DescribeSigningJob_594075, base: "/",
    url: url_DescribeSigningJob_594076, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSigningPlatform_594088 = ref object of OpenApiRestCall_593437
proc url_GetSigningPlatform_594090(protocol: Scheme; host: string; base: string;
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

proc validate_GetSigningPlatform_594089(path: JsonNode; query: JsonNode;
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
  var valid_594091 = path.getOrDefault("platformId")
  valid_594091 = validateParameter(valid_594091, JString, required = true,
                                 default = nil)
  if valid_594091 != nil:
    section.add "platformId", valid_594091
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
  var valid_594092 = header.getOrDefault("X-Amz-Date")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Date", valid_594092
  var valid_594093 = header.getOrDefault("X-Amz-Security-Token")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-Security-Token", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Content-Sha256", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Algorithm")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Algorithm", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Signature")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Signature", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-SignedHeaders", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Credential")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Credential", valid_594098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594099: Call_GetSigningPlatform_594088; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information on a specific signing platform.
  ## 
  let valid = call_594099.validator(path, query, header, formData, body)
  let scheme = call_594099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594099.url(scheme.get, call_594099.host, call_594099.base,
                         call_594099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594099, url, valid)

proc call*(call_594100: Call_GetSigningPlatform_594088; platformId: string): Recallable =
  ## getSigningPlatform
  ## Returns information on a specific signing platform.
  ##   platformId: string (required)
  ##             : The ID of the target signing platform.
  var path_594101 = newJObject()
  add(path_594101, "platformId", newJString(platformId))
  result = call_594100.call(path_594101, nil, nil, nil, nil)

var getSigningPlatform* = Call_GetSigningPlatform_594088(
    name: "getSigningPlatform", meth: HttpMethod.HttpGet,
    host: "signer.amazonaws.com", route: "/signing-platforms/{platformId}",
    validator: validate_GetSigningPlatform_594089, base: "/",
    url: url_GetSigningPlatform_594090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSigningJob_594133 = ref object of OpenApiRestCall_593437
proc url_StartSigningJob_594135(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartSigningJob_594134(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594136 = header.getOrDefault("X-Amz-Date")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Date", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-Security-Token")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Security-Token", valid_594137
  var valid_594138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594138 = validateParameter(valid_594138, JString, required = false,
                                 default = nil)
  if valid_594138 != nil:
    section.add "X-Amz-Content-Sha256", valid_594138
  var valid_594139 = header.getOrDefault("X-Amz-Algorithm")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Algorithm", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Signature")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Signature", valid_594140
  var valid_594141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-SignedHeaders", valid_594141
  var valid_594142 = header.getOrDefault("X-Amz-Credential")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "X-Amz-Credential", valid_594142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594144: Call_StartSigningJob_594133; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a signing job to be performed on the code provided. Signing jobs are viewable by the <code>ListSigningJobs</code> operation for two years after they are performed. Note the following requirements: </p> <ul> <li> <p> You must create an Amazon S3 source bucket. For more information, see <a href="http://docs.aws.amazon.com/AmazonS3/latest/gsg/CreatingABucket.html">Create a Bucket</a> in the <i>Amazon S3 Getting Started Guide</i>. </p> </li> <li> <p>Your S3 source bucket must be version enabled.</p> </li> <li> <p>You must create an S3 destination bucket. AWS Signer uses your S3 destination bucket to write your signed code.</p> </li> <li> <p>You specify the name of the source and destination buckets when calling the <code>StartSigningJob</code> operation.</p> </li> <li> <p>You must also specify a request token that identifies your request to AWS Signer. </p> </li> </ul> <p>You can call the <a>DescribeSigningJob</a> and the <a>ListSigningJobs</a> actions after you call <code>StartSigningJob</code>.</p> <p>For a Java example that shows how to use this action, see <a href="http://docs.aws.amazon.com/acm/latest/userguide/">http://docs.aws.amazon.com/acm/latest/userguide/</a> </p>
  ## 
  let valid = call_594144.validator(path, query, header, formData, body)
  let scheme = call_594144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594144.url(scheme.get, call_594144.host, call_594144.base,
                         call_594144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594144, url, valid)

proc call*(call_594145: Call_StartSigningJob_594133; body: JsonNode): Recallable =
  ## startSigningJob
  ## <p>Initiates a signing job to be performed on the code provided. Signing jobs are viewable by the <code>ListSigningJobs</code> operation for two years after they are performed. Note the following requirements: </p> <ul> <li> <p> You must create an Amazon S3 source bucket. For more information, see <a href="http://docs.aws.amazon.com/AmazonS3/latest/gsg/CreatingABucket.html">Create a Bucket</a> in the <i>Amazon S3 Getting Started Guide</i>. </p> </li> <li> <p>Your S3 source bucket must be version enabled.</p> </li> <li> <p>You must create an S3 destination bucket. AWS Signer uses your S3 destination bucket to write your signed code.</p> </li> <li> <p>You specify the name of the source and destination buckets when calling the <code>StartSigningJob</code> operation.</p> </li> <li> <p>You must also specify a request token that identifies your request to AWS Signer. </p> </li> </ul> <p>You can call the <a>DescribeSigningJob</a> and the <a>ListSigningJobs</a> actions after you call <code>StartSigningJob</code>.</p> <p>For a Java example that shows how to use this action, see <a href="http://docs.aws.amazon.com/acm/latest/userguide/">http://docs.aws.amazon.com/acm/latest/userguide/</a> </p>
  ##   body: JObject (required)
  var body_594146 = newJObject()
  if body != nil:
    body_594146 = body
  result = call_594145.call(nil, nil, nil, nil, body_594146)

var startSigningJob* = Call_StartSigningJob_594133(name: "startSigningJob",
    meth: HttpMethod.HttpPost, host: "signer.amazonaws.com", route: "/signing-jobs",
    validator: validate_StartSigningJob_594134, base: "/", url: url_StartSigningJob_594135,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSigningJobs_594102 = ref object of OpenApiRestCall_593437
proc url_ListSigningJobs_594104(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSigningJobs_594103(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists all your signing jobs. You can use the <code>maxResults</code> parameter to limit the number of signing jobs that are returned in the response. If additional jobs remain to be listed, AWS Signer returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that AWS Signer returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned. 
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
  var valid_594105 = query.getOrDefault("platformId")
  valid_594105 = validateParameter(valid_594105, JString, required = false,
                                 default = nil)
  if valid_594105 != nil:
    section.add "platformId", valid_594105
  var valid_594106 = query.getOrDefault("requestedBy")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "requestedBy", valid_594106
  var valid_594107 = query.getOrDefault("maxResults")
  valid_594107 = validateParameter(valid_594107, JInt, required = false, default = nil)
  if valid_594107 != nil:
    section.add "maxResults", valid_594107
  var valid_594108 = query.getOrDefault("nextToken")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "nextToken", valid_594108
  var valid_594122 = query.getOrDefault("status")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = newJString("InProgress"))
  if valid_594122 != nil:
    section.add "status", valid_594122
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
  var valid_594123 = header.getOrDefault("X-Amz-Date")
  valid_594123 = validateParameter(valid_594123, JString, required = false,
                                 default = nil)
  if valid_594123 != nil:
    section.add "X-Amz-Date", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-Security-Token")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Security-Token", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Content-Sha256", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Algorithm")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Algorithm", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-Signature")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-Signature", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-SignedHeaders", valid_594128
  var valid_594129 = header.getOrDefault("X-Amz-Credential")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-Credential", valid_594129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594130: Call_ListSigningJobs_594102; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all your signing jobs. You can use the <code>maxResults</code> parameter to limit the number of signing jobs that are returned in the response. If additional jobs remain to be listed, AWS Signer returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that AWS Signer returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned. 
  ## 
  let valid = call_594130.validator(path, query, header, formData, body)
  let scheme = call_594130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594130.url(scheme.get, call_594130.host, call_594130.base,
                         call_594130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594130, url, valid)

proc call*(call_594131: Call_ListSigningJobs_594102; platformId: string = "";
          requestedBy: string = ""; maxResults: int = 0; nextToken: string = "";
          status: string = "InProgress"): Recallable =
  ## listSigningJobs
  ## Lists all your signing jobs. You can use the <code>maxResults</code> parameter to limit the number of signing jobs that are returned in the response. If additional jobs remain to be listed, AWS Signer returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that AWS Signer returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned. 
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
  var query_594132 = newJObject()
  add(query_594132, "platformId", newJString(platformId))
  add(query_594132, "requestedBy", newJString(requestedBy))
  add(query_594132, "maxResults", newJInt(maxResults))
  add(query_594132, "nextToken", newJString(nextToken))
  add(query_594132, "status", newJString(status))
  result = call_594131.call(nil, query_594132, nil, nil, nil)

var listSigningJobs* = Call_ListSigningJobs_594102(name: "listSigningJobs",
    meth: HttpMethod.HttpGet, host: "signer.amazonaws.com", route: "/signing-jobs",
    validator: validate_ListSigningJobs_594103, base: "/", url: url_ListSigningJobs_594104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSigningPlatforms_594147 = ref object of OpenApiRestCall_593437
proc url_ListSigningPlatforms_594149(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSigningPlatforms_594148(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all signing platforms available in AWS Signer that match the request parameters. If additional jobs remain to be listed, AWS Signer returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that AWS Signer returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
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
  var valid_594150 = query.getOrDefault("target")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "target", valid_594150
  var valid_594151 = query.getOrDefault("maxResults")
  valid_594151 = validateParameter(valid_594151, JInt, required = false, default = nil)
  if valid_594151 != nil:
    section.add "maxResults", valid_594151
  var valid_594152 = query.getOrDefault("nextToken")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "nextToken", valid_594152
  var valid_594153 = query.getOrDefault("partner")
  valid_594153 = validateParameter(valid_594153, JString, required = false,
                                 default = nil)
  if valid_594153 != nil:
    section.add "partner", valid_594153
  var valid_594154 = query.getOrDefault("category")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "category", valid_594154
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
  var valid_594155 = header.getOrDefault("X-Amz-Date")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Date", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-Security-Token")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Security-Token", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-Content-Sha256", valid_594157
  var valid_594158 = header.getOrDefault("X-Amz-Algorithm")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Algorithm", valid_594158
  var valid_594159 = header.getOrDefault("X-Amz-Signature")
  valid_594159 = validateParameter(valid_594159, JString, required = false,
                                 default = nil)
  if valid_594159 != nil:
    section.add "X-Amz-Signature", valid_594159
  var valid_594160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594160 = validateParameter(valid_594160, JString, required = false,
                                 default = nil)
  if valid_594160 != nil:
    section.add "X-Amz-SignedHeaders", valid_594160
  var valid_594161 = header.getOrDefault("X-Amz-Credential")
  valid_594161 = validateParameter(valid_594161, JString, required = false,
                                 default = nil)
  if valid_594161 != nil:
    section.add "X-Amz-Credential", valid_594161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594162: Call_ListSigningPlatforms_594147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all signing platforms available in AWS Signer that match the request parameters. If additional jobs remain to be listed, AWS Signer returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that AWS Signer returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
  ## 
  let valid = call_594162.validator(path, query, header, formData, body)
  let scheme = call_594162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594162.url(scheme.get, call_594162.host, call_594162.base,
                         call_594162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594162, url, valid)

proc call*(call_594163: Call_ListSigningPlatforms_594147; target: string = "";
          maxResults: int = 0; nextToken: string = ""; partner: string = "";
          category: string = ""): Recallable =
  ## listSigningPlatforms
  ## Lists all signing platforms available in AWS Signer that match the request parameters. If additional jobs remain to be listed, AWS Signer returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that AWS Signer returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
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
  var query_594164 = newJObject()
  add(query_594164, "target", newJString(target))
  add(query_594164, "maxResults", newJInt(maxResults))
  add(query_594164, "nextToken", newJString(nextToken))
  add(query_594164, "partner", newJString(partner))
  add(query_594164, "category", newJString(category))
  result = call_594163.call(nil, query_594164, nil, nil, nil)

var listSigningPlatforms* = Call_ListSigningPlatforms_594147(
    name: "listSigningPlatforms", meth: HttpMethod.HttpGet,
    host: "signer.amazonaws.com", route: "/signing-platforms",
    validator: validate_ListSigningPlatforms_594148, base: "/",
    url: url_ListSigningPlatforms_594149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSigningProfiles_594165 = ref object of OpenApiRestCall_593437
proc url_ListSigningProfiles_594167(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSigningProfiles_594166(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists all available signing profiles in your AWS account. Returns only profiles with an <code>ACTIVE</code> status unless the <code>includeCanceled</code> request field is set to <code>true</code>. If additional jobs remain to be listed, AWS Signer returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that AWS Signer returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
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
  var valid_594168 = query.getOrDefault("maxResults")
  valid_594168 = validateParameter(valid_594168, JInt, required = false, default = nil)
  if valid_594168 != nil:
    section.add "maxResults", valid_594168
  var valid_594169 = query.getOrDefault("nextToken")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "nextToken", valid_594169
  var valid_594170 = query.getOrDefault("includeCanceled")
  valid_594170 = validateParameter(valid_594170, JBool, required = false, default = nil)
  if valid_594170 != nil:
    section.add "includeCanceled", valid_594170
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
  var valid_594171 = header.getOrDefault("X-Amz-Date")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Date", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-Security-Token")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-Security-Token", valid_594172
  var valid_594173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-Content-Sha256", valid_594173
  var valid_594174 = header.getOrDefault("X-Amz-Algorithm")
  valid_594174 = validateParameter(valid_594174, JString, required = false,
                                 default = nil)
  if valid_594174 != nil:
    section.add "X-Amz-Algorithm", valid_594174
  var valid_594175 = header.getOrDefault("X-Amz-Signature")
  valid_594175 = validateParameter(valid_594175, JString, required = false,
                                 default = nil)
  if valid_594175 != nil:
    section.add "X-Amz-Signature", valid_594175
  var valid_594176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594176 = validateParameter(valid_594176, JString, required = false,
                                 default = nil)
  if valid_594176 != nil:
    section.add "X-Amz-SignedHeaders", valid_594176
  var valid_594177 = header.getOrDefault("X-Amz-Credential")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "X-Amz-Credential", valid_594177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594178: Call_ListSigningProfiles_594165; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all available signing profiles in your AWS account. Returns only profiles with an <code>ACTIVE</code> status unless the <code>includeCanceled</code> request field is set to <code>true</code>. If additional jobs remain to be listed, AWS Signer returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that AWS Signer returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
  ## 
  let valid = call_594178.validator(path, query, header, formData, body)
  let scheme = call_594178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594178.url(scheme.get, call_594178.host, call_594178.base,
                         call_594178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594178, url, valid)

proc call*(call_594179: Call_ListSigningProfiles_594165; maxResults: int = 0;
          nextToken: string = ""; includeCanceled: bool = false): Recallable =
  ## listSigningProfiles
  ## Lists all available signing profiles in your AWS account. Returns only profiles with an <code>ACTIVE</code> status unless the <code>includeCanceled</code> request field is set to <code>true</code>. If additional jobs remain to be listed, AWS Signer returns a <code>nextToken</code> value. Use this value in subsequent calls to <code>ListSigningJobs</code> to fetch the remaining values. You can continue calling <code>ListSigningJobs</code> with your <code>maxResults</code> parameter and with new values that AWS Signer returns in the <code>nextToken</code> parameter until all of your signing jobs have been returned.
  ##   maxResults: int
  ##             : The maximum number of profiles to be returned.
  ##   nextToken: string
  ##            : Value for specifying the next set of paginated results to return. After you receive a response with truncated results, use this parameter in a subsequent request. Set it to the value of <code>nextToken</code> from the response that you just received.
  ##   includeCanceled: bool
  ##                  : Designates whether to include profiles with the status of <code>CANCELED</code>.
  var query_594180 = newJObject()
  add(query_594180, "maxResults", newJInt(maxResults))
  add(query_594180, "nextToken", newJString(nextToken))
  add(query_594180, "includeCanceled", newJBool(includeCanceled))
  result = call_594179.call(nil, query_594180, nil, nil, nil)

var listSigningProfiles* = Call_ListSigningProfiles_594165(
    name: "listSigningProfiles", meth: HttpMethod.HttpGet,
    host: "signer.amazonaws.com", route: "/signing-profiles",
    validator: validate_ListSigningProfiles_594166, base: "/",
    url: url_ListSigningProfiles_594167, schemes: {Scheme.Https, Scheme.Http})
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
