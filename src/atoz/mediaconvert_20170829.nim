
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Elemental MediaConvert
## version: 2017-08-29
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## AWS Elemental MediaConvert
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/mediaconvert/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "mediaconvert.ap-northeast-1.amazonaws.com", "ap-southeast-1": "mediaconvert.ap-southeast-1.amazonaws.com",
                           "us-west-2": "mediaconvert.us-west-2.amazonaws.com",
                           "eu-west-2": "mediaconvert.eu-west-2.amazonaws.com", "ap-northeast-3": "mediaconvert.ap-northeast-3.amazonaws.com", "eu-central-1": "mediaconvert.eu-central-1.amazonaws.com",
                           "us-east-2": "mediaconvert.us-east-2.amazonaws.com",
                           "us-east-1": "mediaconvert.us-east-1.amazonaws.com", "cn-northwest-1": "mediaconvert.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "mediaconvert.ap-south-1.amazonaws.com", "eu-north-1": "mediaconvert.eu-north-1.amazonaws.com", "ap-northeast-2": "mediaconvert.ap-northeast-2.amazonaws.com",
                           "us-west-1": "mediaconvert.us-west-1.amazonaws.com", "us-gov-east-1": "mediaconvert.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "mediaconvert.eu-west-3.amazonaws.com", "cn-north-1": "mediaconvert.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "mediaconvert.sa-east-1.amazonaws.com",
                           "eu-west-1": "mediaconvert.eu-west-1.amazonaws.com", "us-gov-west-1": "mediaconvert.us-gov-west-1.amazonaws.com", "ap-southeast-2": "mediaconvert.ap-southeast-2.amazonaws.com", "ca-central-1": "mediaconvert.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "mediaconvert.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "mediaconvert.ap-southeast-1.amazonaws.com",
      "us-west-2": "mediaconvert.us-west-2.amazonaws.com",
      "eu-west-2": "mediaconvert.eu-west-2.amazonaws.com",
      "ap-northeast-3": "mediaconvert.ap-northeast-3.amazonaws.com",
      "eu-central-1": "mediaconvert.eu-central-1.amazonaws.com",
      "us-east-2": "mediaconvert.us-east-2.amazonaws.com",
      "us-east-1": "mediaconvert.us-east-1.amazonaws.com",
      "cn-northwest-1": "mediaconvert.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "mediaconvert.ap-south-1.amazonaws.com",
      "eu-north-1": "mediaconvert.eu-north-1.amazonaws.com",
      "ap-northeast-2": "mediaconvert.ap-northeast-2.amazonaws.com",
      "us-west-1": "mediaconvert.us-west-1.amazonaws.com",
      "us-gov-east-1": "mediaconvert.us-gov-east-1.amazonaws.com",
      "eu-west-3": "mediaconvert.eu-west-3.amazonaws.com",
      "cn-north-1": "mediaconvert.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "mediaconvert.sa-east-1.amazonaws.com",
      "eu-west-1": "mediaconvert.eu-west-1.amazonaws.com",
      "us-gov-west-1": "mediaconvert.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "mediaconvert.ap-southeast-2.amazonaws.com",
      "ca-central-1": "mediaconvert.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "mediaconvert"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_AssociateCertificate_21625779 = ref object of OpenApiRestCall_21625435
proc url_AssociateCertificate_21625781(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateCertificate_21625780(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Associates an AWS Certificate Manager (ACM) Amazon Resource Name (ARN) with AWS Elemental MediaConvert.
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
  var valid_21625882 = header.getOrDefault("X-Amz-Date")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "X-Amz-Date", valid_21625882
  var valid_21625883 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "X-Amz-Security-Token", valid_21625883
  var valid_21625884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625884 = validateParameter(valid_21625884, JString, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625884
  var valid_21625885 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625885 = validateParameter(valid_21625885, JString, required = false,
                                   default = nil)
  if valid_21625885 != nil:
    section.add "X-Amz-Algorithm", valid_21625885
  var valid_21625886 = header.getOrDefault("X-Amz-Signature")
  valid_21625886 = validateParameter(valid_21625886, JString, required = false,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "X-Amz-Signature", valid_21625886
  var valid_21625887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625887 = validateParameter(valid_21625887, JString, required = false,
                                   default = nil)
  if valid_21625887 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625887
  var valid_21625888 = header.getOrDefault("X-Amz-Credential")
  valid_21625888 = validateParameter(valid_21625888, JString, required = false,
                                   default = nil)
  if valid_21625888 != nil:
    section.add "X-Amz-Credential", valid_21625888
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

proc call*(call_21625914: Call_AssociateCertificate_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates an AWS Certificate Manager (ACM) Amazon Resource Name (ARN) with AWS Elemental MediaConvert.
  ## 
  let valid = call_21625914.validator(path, query, header, formData, body, _)
  let scheme = call_21625914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625914.makeUrl(scheme.get, call_21625914.host, call_21625914.base,
                               call_21625914.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625914, uri, valid, _)

proc call*(call_21625977: Call_AssociateCertificate_21625779; body: JsonNode): Recallable =
  ## associateCertificate
  ## Associates an AWS Certificate Manager (ACM) Amazon Resource Name (ARN) with AWS Elemental MediaConvert.
  ##   body: JObject (required)
  var body_21625978 = newJObject()
  if body != nil:
    body_21625978 = body
  result = call_21625977.call(nil, nil, nil, nil, body_21625978)

var associateCertificate* = Call_AssociateCertificate_21625779(
    name: "associateCertificate", meth: HttpMethod.HttpPost,
    host: "mediaconvert.amazonaws.com", route: "/2017-08-29/certificates",
    validator: validate_AssociateCertificate_21625780, base: "/",
    makeUrl: url_AssociateCertificate_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_21626014 = ref object of OpenApiRestCall_21625435
proc url_GetJob_21626016(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/jobs/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetJob_21626015(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve the JSON for a specific completed transcoding job.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : the job ID of the job.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_21626030 = path.getOrDefault("id")
  valid_21626030 = validateParameter(valid_21626030, JString, required = true,
                                   default = nil)
  if valid_21626030 != nil:
    section.add "id", valid_21626030
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
  var valid_21626031 = header.getOrDefault("X-Amz-Date")
  valid_21626031 = validateParameter(valid_21626031, JString, required = false,
                                   default = nil)
  if valid_21626031 != nil:
    section.add "X-Amz-Date", valid_21626031
  var valid_21626032 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626032 = validateParameter(valid_21626032, JString, required = false,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "X-Amz-Security-Token", valid_21626032
  var valid_21626033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626033
  var valid_21626034 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626034 = validateParameter(valid_21626034, JString, required = false,
                                   default = nil)
  if valid_21626034 != nil:
    section.add "X-Amz-Algorithm", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Signature")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Signature", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Credential")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Credential", valid_21626037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626038: Call_GetJob_21626014; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve the JSON for a specific completed transcoding job.
  ## 
  let valid = call_21626038.validator(path, query, header, formData, body, _)
  let scheme = call_21626038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626038.makeUrl(scheme.get, call_21626038.host, call_21626038.base,
                               call_21626038.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626038, uri, valid, _)

proc call*(call_21626039: Call_GetJob_21626014; id: string): Recallable =
  ## getJob
  ## Retrieve the JSON for a specific completed transcoding job.
  ##   id: string (required)
  ##     : the job ID of the job.
  var path_21626041 = newJObject()
  add(path_21626041, "id", newJString(id))
  result = call_21626039.call(path_21626041, nil, nil, nil, nil)

var getJob* = Call_GetJob_21626014(name: "getJob", meth: HttpMethod.HttpGet,
                                host: "mediaconvert.amazonaws.com",
                                route: "/2017-08-29/jobs/{id}",
                                validator: validate_GetJob_21626015, base: "/",
                                makeUrl: url_GetJob_21626016,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelJob_21626044 = ref object of OpenApiRestCall_21625435
proc url_CancelJob_21626046(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/jobs/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CancelJob_21626045(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Permanently cancel a job. Once you have canceled a job, you can't start it again.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The Job ID of the job to be cancelled.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_21626047 = path.getOrDefault("id")
  valid_21626047 = validateParameter(valid_21626047, JString, required = true,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "id", valid_21626047
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
  var valid_21626048 = header.getOrDefault("X-Amz-Date")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Date", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626049 = validateParameter(valid_21626049, JString, required = false,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "X-Amz-Security-Token", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Algorithm", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Signature")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Signature", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Credential")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Credential", valid_21626054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626055: Call_CancelJob_21626044; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Permanently cancel a job. Once you have canceled a job, you can't start it again.
  ## 
  let valid = call_21626055.validator(path, query, header, formData, body, _)
  let scheme = call_21626055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626055.makeUrl(scheme.get, call_21626055.host, call_21626055.base,
                               call_21626055.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626055, uri, valid, _)

proc call*(call_21626056: Call_CancelJob_21626044; id: string): Recallable =
  ## cancelJob
  ## Permanently cancel a job. Once you have canceled a job, you can't start it again.
  ##   id: string (required)
  ##     : The Job ID of the job to be cancelled.
  var path_21626057 = newJObject()
  add(path_21626057, "id", newJString(id))
  result = call_21626056.call(path_21626057, nil, nil, nil, nil)

var cancelJob* = Call_CancelJob_21626044(name: "cancelJob",
                                      meth: HttpMethod.HttpDelete,
                                      host: "mediaconvert.amazonaws.com",
                                      route: "/2017-08-29/jobs/{id}",
                                      validator: validate_CancelJob_21626045,
                                      base: "/", makeUrl: url_CancelJob_21626046,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_21626094 = ref object of OpenApiRestCall_21625435
proc url_CreateJob_21626096(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateJob_21626095(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Create a new transcoding job. For information about jobs and job settings, see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
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
  var valid_21626097 = header.getOrDefault("X-Amz-Date")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Date", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-Security-Token", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626099
  var valid_21626100 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-Algorithm", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-Signature")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Signature", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-Credential")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-Credential", valid_21626103
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

proc call*(call_21626105: Call_CreateJob_21626094; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new transcoding job. For information about jobs and job settings, see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ## 
  let valid = call_21626105.validator(path, query, header, formData, body, _)
  let scheme = call_21626105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626105.makeUrl(scheme.get, call_21626105.host, call_21626105.base,
                               call_21626105.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626105, uri, valid, _)

proc call*(call_21626106: Call_CreateJob_21626094; body: JsonNode): Recallable =
  ## createJob
  ## Create a new transcoding job. For information about jobs and job settings, see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ##   body: JObject (required)
  var body_21626107 = newJObject()
  if body != nil:
    body_21626107 = body
  result = call_21626106.call(nil, nil, nil, nil, body_21626107)

var createJob* = Call_CreateJob_21626094(name: "createJob",
                                      meth: HttpMethod.HttpPost,
                                      host: "mediaconvert.amazonaws.com",
                                      route: "/2017-08-29/jobs",
                                      validator: validate_CreateJob_21626095,
                                      base: "/", makeUrl: url_CreateJob_21626096,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_21626058 = ref object of OpenApiRestCall_21625435
proc url_ListJobs_21626060(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJobs_21626059(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve a JSON array of up to twenty of your most recently created jobs. This array includes in-process, completed, and errored jobs. This will return the jobs themselves, not just a list of the jobs. To retrieve the twenty next most recent jobs, use the nextToken string returned with the array.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   order: JString
  ##        : When you request lists of resources, you can optionally specify whether they are sorted in ASCENDING or DESCENDING order. Default varies by resource.
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Optional. Number of jobs, up to twenty, that will be returned at one time.
  ##   nextToken: JString
  ##            : Use this string, provided with the response to a previous request, to request the next batch of jobs.
  ##   status: JString
  ##         : A job's status can be SUBMITTED, PROGRESSING, COMPLETE, CANCELED, or ERROR.
  ##   queue: JString
  ##        : Provide a queue name to get back only jobs from that queue.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626075 = query.getOrDefault("order")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = newJString("ASCENDING"))
  if valid_21626075 != nil:
    section.add "order", valid_21626075
  var valid_21626076 = query.getOrDefault("NextToken")
  valid_21626076 = validateParameter(valid_21626076, JString, required = false,
                                   default = nil)
  if valid_21626076 != nil:
    section.add "NextToken", valid_21626076
  var valid_21626077 = query.getOrDefault("maxResults")
  valid_21626077 = validateParameter(valid_21626077, JInt, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "maxResults", valid_21626077
  var valid_21626078 = query.getOrDefault("nextToken")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "nextToken", valid_21626078
  var valid_21626079 = query.getOrDefault("status")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = newJString("SUBMITTED"))
  if valid_21626079 != nil:
    section.add "status", valid_21626079
  var valid_21626080 = query.getOrDefault("queue")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "queue", valid_21626080
  var valid_21626081 = query.getOrDefault("MaxResults")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "MaxResults", valid_21626081
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
  var valid_21626082 = header.getOrDefault("X-Amz-Date")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Date", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-Security-Token", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626084
  var valid_21626085 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-Algorithm", valid_21626085
  var valid_21626086 = header.getOrDefault("X-Amz-Signature")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Signature", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626087
  var valid_21626088 = header.getOrDefault("X-Amz-Credential")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "X-Amz-Credential", valid_21626088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626089: Call_ListJobs_21626058; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve a JSON array of up to twenty of your most recently created jobs. This array includes in-process, completed, and errored jobs. This will return the jobs themselves, not just a list of the jobs. To retrieve the twenty next most recent jobs, use the nextToken string returned with the array.
  ## 
  let valid = call_21626089.validator(path, query, header, formData, body, _)
  let scheme = call_21626089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626089.makeUrl(scheme.get, call_21626089.host, call_21626089.base,
                               call_21626089.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626089, uri, valid, _)

proc call*(call_21626090: Call_ListJobs_21626058; order: string = "ASCENDING";
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          status: string = "SUBMITTED"; queue: string = ""; MaxResults: string = ""): Recallable =
  ## listJobs
  ## Retrieve a JSON array of up to twenty of your most recently created jobs. This array includes in-process, completed, and errored jobs. This will return the jobs themselves, not just a list of the jobs. To retrieve the twenty next most recent jobs, use the nextToken string returned with the array.
  ##   order: string
  ##        : When you request lists of resources, you can optionally specify whether they are sorted in ASCENDING or DESCENDING order. Default varies by resource.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Optional. Number of jobs, up to twenty, that will be returned at one time.
  ##   nextToken: string
  ##            : Use this string, provided with the response to a previous request, to request the next batch of jobs.
  ##   status: string
  ##         : A job's status can be SUBMITTED, PROGRESSING, COMPLETE, CANCELED, or ERROR.
  ##   queue: string
  ##        : Provide a queue name to get back only jobs from that queue.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626091 = newJObject()
  add(query_21626091, "order", newJString(order))
  add(query_21626091, "NextToken", newJString(NextToken))
  add(query_21626091, "maxResults", newJInt(maxResults))
  add(query_21626091, "nextToken", newJString(nextToken))
  add(query_21626091, "status", newJString(status))
  add(query_21626091, "queue", newJString(queue))
  add(query_21626091, "MaxResults", newJString(MaxResults))
  result = call_21626090.call(nil, query_21626091, nil, nil, nil)

var listJobs* = Call_ListJobs_21626058(name: "listJobs", meth: HttpMethod.HttpGet,
                                    host: "mediaconvert.amazonaws.com",
                                    route: "/2017-08-29/jobs",
                                    validator: validate_ListJobs_21626059,
                                    base: "/", makeUrl: url_ListJobs_21626060,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJobTemplate_21626128 = ref object of OpenApiRestCall_21625435
proc url_CreateJobTemplate_21626130(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateJobTemplate_21626129(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Create a new job template. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
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
  var valid_21626131 = header.getOrDefault("X-Amz-Date")
  valid_21626131 = validateParameter(valid_21626131, JString, required = false,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "X-Amz-Date", valid_21626131
  var valid_21626132 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626132 = validateParameter(valid_21626132, JString, required = false,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "X-Amz-Security-Token", valid_21626132
  var valid_21626133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626133
  var valid_21626134 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "X-Amz-Algorithm", valid_21626134
  var valid_21626135 = header.getOrDefault("X-Amz-Signature")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-Signature", valid_21626135
  var valid_21626136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626136
  var valid_21626137 = header.getOrDefault("X-Amz-Credential")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Credential", valid_21626137
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

proc call*(call_21626139: Call_CreateJobTemplate_21626128; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new job template. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ## 
  let valid = call_21626139.validator(path, query, header, formData, body, _)
  let scheme = call_21626139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626139.makeUrl(scheme.get, call_21626139.host, call_21626139.base,
                               call_21626139.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626139, uri, valid, _)

proc call*(call_21626140: Call_CreateJobTemplate_21626128; body: JsonNode): Recallable =
  ## createJobTemplate
  ## Create a new job template. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ##   body: JObject (required)
  var body_21626141 = newJObject()
  if body != nil:
    body_21626141 = body
  result = call_21626140.call(nil, nil, nil, nil, body_21626141)

var createJobTemplate* = Call_CreateJobTemplate_21626128(name: "createJobTemplate",
    meth: HttpMethod.HttpPost, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates", validator: validate_CreateJobTemplate_21626129,
    base: "/", makeUrl: url_CreateJobTemplate_21626130,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobTemplates_21626108 = ref object of OpenApiRestCall_21625435
proc url_ListJobTemplates_21626110(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJobTemplates_21626109(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve a JSON array of up to twenty of your job templates. This will return the templates themselves, not just a list of them. To retrieve the next twenty templates, use the nextToken string returned with the array
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   order: JString
  ##        : When you request lists of resources, you can optionally specify whether they are sorted in ASCENDING or DESCENDING order. Default varies by resource.
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Optional. Number of job templates, up to twenty, that will be returned at one time.
  ##   nextToken: JString
  ##            : Use this string, provided with the response to a previous request, to request the next batch of job templates.
  ##   listBy: JString
  ##         : Optional. When you request a list of job templates, you can choose to list them alphabetically by NAME or chronologically by CREATION_DATE. If you don't specify, the service will list them by name.
  ##   category: JString
  ##           : Optionally, specify a job template category to limit responses to only job templates from that category.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626111 = query.getOrDefault("order")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = newJString("ASCENDING"))
  if valid_21626111 != nil:
    section.add "order", valid_21626111
  var valid_21626112 = query.getOrDefault("NextToken")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "NextToken", valid_21626112
  var valid_21626113 = query.getOrDefault("maxResults")
  valid_21626113 = validateParameter(valid_21626113, JInt, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "maxResults", valid_21626113
  var valid_21626114 = query.getOrDefault("nextToken")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "nextToken", valid_21626114
  var valid_21626115 = query.getOrDefault("listBy")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = newJString("NAME"))
  if valid_21626115 != nil:
    section.add "listBy", valid_21626115
  var valid_21626116 = query.getOrDefault("category")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "category", valid_21626116
  var valid_21626117 = query.getOrDefault("MaxResults")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "MaxResults", valid_21626117
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
  var valid_21626118 = header.getOrDefault("X-Amz-Date")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-Date", valid_21626118
  var valid_21626119 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "X-Amz-Security-Token", valid_21626119
  var valid_21626120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626120
  var valid_21626121 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626121 = validateParameter(valid_21626121, JString, required = false,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "X-Amz-Algorithm", valid_21626121
  var valid_21626122 = header.getOrDefault("X-Amz-Signature")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Signature", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Credential")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "X-Amz-Credential", valid_21626124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626125: Call_ListJobTemplates_21626108; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve a JSON array of up to twenty of your job templates. This will return the templates themselves, not just a list of them. To retrieve the next twenty templates, use the nextToken string returned with the array
  ## 
  let valid = call_21626125.validator(path, query, header, formData, body, _)
  let scheme = call_21626125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626125.makeUrl(scheme.get, call_21626125.host, call_21626125.base,
                               call_21626125.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626125, uri, valid, _)

proc call*(call_21626126: Call_ListJobTemplates_21626108;
          order: string = "ASCENDING"; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; listBy: string = "NAME"; category: string = "";
          MaxResults: string = ""): Recallable =
  ## listJobTemplates
  ## Retrieve a JSON array of up to twenty of your job templates. This will return the templates themselves, not just a list of them. To retrieve the next twenty templates, use the nextToken string returned with the array
  ##   order: string
  ##        : When you request lists of resources, you can optionally specify whether they are sorted in ASCENDING or DESCENDING order. Default varies by resource.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Optional. Number of job templates, up to twenty, that will be returned at one time.
  ##   nextToken: string
  ##            : Use this string, provided with the response to a previous request, to request the next batch of job templates.
  ##   listBy: string
  ##         : Optional. When you request a list of job templates, you can choose to list them alphabetically by NAME or chronologically by CREATION_DATE. If you don't specify, the service will list them by name.
  ##   category: string
  ##           : Optionally, specify a job template category to limit responses to only job templates from that category.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626127 = newJObject()
  add(query_21626127, "order", newJString(order))
  add(query_21626127, "NextToken", newJString(NextToken))
  add(query_21626127, "maxResults", newJInt(maxResults))
  add(query_21626127, "nextToken", newJString(nextToken))
  add(query_21626127, "listBy", newJString(listBy))
  add(query_21626127, "category", newJString(category))
  add(query_21626127, "MaxResults", newJString(MaxResults))
  result = call_21626126.call(nil, query_21626127, nil, nil, nil)

var listJobTemplates* = Call_ListJobTemplates_21626108(name: "listJobTemplates",
    meth: HttpMethod.HttpGet, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates", validator: validate_ListJobTemplates_21626109,
    base: "/", makeUrl: url_ListJobTemplates_21626110,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePreset_21626162 = ref object of OpenApiRestCall_21625435
proc url_CreatePreset_21626164(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePreset_21626163(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Create a new preset. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
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
  var valid_21626165 = header.getOrDefault("X-Amz-Date")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "X-Amz-Date", valid_21626165
  var valid_21626166 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "X-Amz-Security-Token", valid_21626166
  var valid_21626167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Algorithm", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Signature")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "X-Amz-Signature", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Credential")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Credential", valid_21626171
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

proc call*(call_21626173: Call_CreatePreset_21626162; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new preset. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ## 
  let valid = call_21626173.validator(path, query, header, formData, body, _)
  let scheme = call_21626173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626173.makeUrl(scheme.get, call_21626173.host, call_21626173.base,
                               call_21626173.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626173, uri, valid, _)

proc call*(call_21626174: Call_CreatePreset_21626162; body: JsonNode): Recallable =
  ## createPreset
  ## Create a new preset. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ##   body: JObject (required)
  var body_21626175 = newJObject()
  if body != nil:
    body_21626175 = body
  result = call_21626174.call(nil, nil, nil, nil, body_21626175)

var createPreset* = Call_CreatePreset_21626162(name: "createPreset",
    meth: HttpMethod.HttpPost, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/presets", validator: validate_CreatePreset_21626163,
    base: "/", makeUrl: url_CreatePreset_21626164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPresets_21626142 = ref object of OpenApiRestCall_21625435
proc url_ListPresets_21626144(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPresets_21626143(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve a JSON array of up to twenty of your presets. This will return the presets themselves, not just a list of them. To retrieve the next twenty presets, use the nextToken string returned with the array.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   order: JString
  ##        : When you request lists of resources, you can optionally specify whether they are sorted in ASCENDING or DESCENDING order. Default varies by resource.
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Optional. Number of presets, up to twenty, that will be returned at one time
  ##   nextToken: JString
  ##            : Use this string, provided with the response to a previous request, to request the next batch of presets.
  ##   listBy: JString
  ##         : Optional. When you request a list of presets, you can choose to list them alphabetically by NAME or chronologically by CREATION_DATE. If you don't specify, the service will list them by name.
  ##   category: JString
  ##           : Optionally, specify a preset category to limit responses to only presets from that category.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626145 = query.getOrDefault("order")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = newJString("ASCENDING"))
  if valid_21626145 != nil:
    section.add "order", valid_21626145
  var valid_21626146 = query.getOrDefault("NextToken")
  valid_21626146 = validateParameter(valid_21626146, JString, required = false,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "NextToken", valid_21626146
  var valid_21626147 = query.getOrDefault("maxResults")
  valid_21626147 = validateParameter(valid_21626147, JInt, required = false,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "maxResults", valid_21626147
  var valid_21626148 = query.getOrDefault("nextToken")
  valid_21626148 = validateParameter(valid_21626148, JString, required = false,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "nextToken", valid_21626148
  var valid_21626149 = query.getOrDefault("listBy")
  valid_21626149 = validateParameter(valid_21626149, JString, required = false,
                                   default = newJString("NAME"))
  if valid_21626149 != nil:
    section.add "listBy", valid_21626149
  var valid_21626150 = query.getOrDefault("category")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "category", valid_21626150
  var valid_21626151 = query.getOrDefault("MaxResults")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "MaxResults", valid_21626151
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
  var valid_21626152 = header.getOrDefault("X-Amz-Date")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Date", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Security-Token", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Algorithm", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Signature")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Signature", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-Credential")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-Credential", valid_21626158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626159: Call_ListPresets_21626142; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve a JSON array of up to twenty of your presets. This will return the presets themselves, not just a list of them. To retrieve the next twenty presets, use the nextToken string returned with the array.
  ## 
  let valid = call_21626159.validator(path, query, header, formData, body, _)
  let scheme = call_21626159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626159.makeUrl(scheme.get, call_21626159.host, call_21626159.base,
                               call_21626159.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626159, uri, valid, _)

proc call*(call_21626160: Call_ListPresets_21626142; order: string = "ASCENDING";
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          listBy: string = "NAME"; category: string = ""; MaxResults: string = ""): Recallable =
  ## listPresets
  ## Retrieve a JSON array of up to twenty of your presets. This will return the presets themselves, not just a list of them. To retrieve the next twenty presets, use the nextToken string returned with the array.
  ##   order: string
  ##        : When you request lists of resources, you can optionally specify whether they are sorted in ASCENDING or DESCENDING order. Default varies by resource.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Optional. Number of presets, up to twenty, that will be returned at one time
  ##   nextToken: string
  ##            : Use this string, provided with the response to a previous request, to request the next batch of presets.
  ##   listBy: string
  ##         : Optional. When you request a list of presets, you can choose to list them alphabetically by NAME or chronologically by CREATION_DATE. If you don't specify, the service will list them by name.
  ##   category: string
  ##           : Optionally, specify a preset category to limit responses to only presets from that category.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626161 = newJObject()
  add(query_21626161, "order", newJString(order))
  add(query_21626161, "NextToken", newJString(NextToken))
  add(query_21626161, "maxResults", newJInt(maxResults))
  add(query_21626161, "nextToken", newJString(nextToken))
  add(query_21626161, "listBy", newJString(listBy))
  add(query_21626161, "category", newJString(category))
  add(query_21626161, "MaxResults", newJString(MaxResults))
  result = call_21626160.call(nil, query_21626161, nil, nil, nil)

var listPresets* = Call_ListPresets_21626142(name: "listPresets",
    meth: HttpMethod.HttpGet, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/presets", validator: validate_ListPresets_21626143,
    base: "/", makeUrl: url_ListPresets_21626144,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateQueue_21626195 = ref object of OpenApiRestCall_21625435
proc url_CreateQueue_21626197(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateQueue_21626196(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Create a new transcoding queue. For information about queues, see Working With Queues in the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/working-with-queues.html
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
  var valid_21626198 = header.getOrDefault("X-Amz-Date")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Date", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-Security-Token", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Algorithm", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Signature")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Signature", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Credential")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Credential", valid_21626204
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

proc call*(call_21626206: Call_CreateQueue_21626195; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new transcoding queue. For information about queues, see Working With Queues in the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/working-with-queues.html
  ## 
  let valid = call_21626206.validator(path, query, header, formData, body, _)
  let scheme = call_21626206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626206.makeUrl(scheme.get, call_21626206.host, call_21626206.base,
                               call_21626206.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626206, uri, valid, _)

proc call*(call_21626207: Call_CreateQueue_21626195; body: JsonNode): Recallable =
  ## createQueue
  ## Create a new transcoding queue. For information about queues, see Working With Queues in the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/working-with-queues.html
  ##   body: JObject (required)
  var body_21626208 = newJObject()
  if body != nil:
    body_21626208 = body
  result = call_21626207.call(nil, nil, nil, nil, body_21626208)

var createQueue* = Call_CreateQueue_21626195(name: "createQueue",
    meth: HttpMethod.HttpPost, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/queues", validator: validate_CreateQueue_21626196,
    base: "/", makeUrl: url_CreateQueue_21626197,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQueues_21626176 = ref object of OpenApiRestCall_21625435
proc url_ListQueues_21626178(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListQueues_21626177(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve a JSON array of up to twenty of your queues. This will return the queues themselves, not just a list of them. To retrieve the next twenty queues, use the nextToken string returned with the array.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   order: JString
  ##        : When you request lists of resources, you can optionally specify whether they are sorted in ASCENDING or DESCENDING order. Default varies by resource.
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Optional. Number of queues, up to twenty, that will be returned at one time.
  ##   nextToken: JString
  ##            : Use this string, provided with the response to a previous request, to request the next batch of queues.
  ##   listBy: JString
  ##         : Optional. When you request a list of queues, you can choose to list them alphabetically by NAME or chronologically by CREATION_DATE. If you don't specify, the service will list them by creation date.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626179 = query.getOrDefault("order")
  valid_21626179 = validateParameter(valid_21626179, JString, required = false,
                                   default = newJString("ASCENDING"))
  if valid_21626179 != nil:
    section.add "order", valid_21626179
  var valid_21626180 = query.getOrDefault("NextToken")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "NextToken", valid_21626180
  var valid_21626181 = query.getOrDefault("maxResults")
  valid_21626181 = validateParameter(valid_21626181, JInt, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "maxResults", valid_21626181
  var valid_21626182 = query.getOrDefault("nextToken")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "nextToken", valid_21626182
  var valid_21626183 = query.getOrDefault("listBy")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = newJString("NAME"))
  if valid_21626183 != nil:
    section.add "listBy", valid_21626183
  var valid_21626184 = query.getOrDefault("MaxResults")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "MaxResults", valid_21626184
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
  var valid_21626185 = header.getOrDefault("X-Amz-Date")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Date", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Security-Token", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-Algorithm", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-Signature")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Signature", valid_21626189
  var valid_21626190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626190
  var valid_21626191 = header.getOrDefault("X-Amz-Credential")
  valid_21626191 = validateParameter(valid_21626191, JString, required = false,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "X-Amz-Credential", valid_21626191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626192: Call_ListQueues_21626176; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve a JSON array of up to twenty of your queues. This will return the queues themselves, not just a list of them. To retrieve the next twenty queues, use the nextToken string returned with the array.
  ## 
  let valid = call_21626192.validator(path, query, header, formData, body, _)
  let scheme = call_21626192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626192.makeUrl(scheme.get, call_21626192.host, call_21626192.base,
                               call_21626192.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626192, uri, valid, _)

proc call*(call_21626193: Call_ListQueues_21626176; order: string = "ASCENDING";
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          listBy: string = "NAME"; MaxResults: string = ""): Recallable =
  ## listQueues
  ## Retrieve a JSON array of up to twenty of your queues. This will return the queues themselves, not just a list of them. To retrieve the next twenty queues, use the nextToken string returned with the array.
  ##   order: string
  ##        : When you request lists of resources, you can optionally specify whether they are sorted in ASCENDING or DESCENDING order. Default varies by resource.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Optional. Number of queues, up to twenty, that will be returned at one time.
  ##   nextToken: string
  ##            : Use this string, provided with the response to a previous request, to request the next batch of queues.
  ##   listBy: string
  ##         : Optional. When you request a list of queues, you can choose to list them alphabetically by NAME or chronologically by CREATION_DATE. If you don't specify, the service will list them by creation date.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626194 = newJObject()
  add(query_21626194, "order", newJString(order))
  add(query_21626194, "NextToken", newJString(NextToken))
  add(query_21626194, "maxResults", newJInt(maxResults))
  add(query_21626194, "nextToken", newJString(nextToken))
  add(query_21626194, "listBy", newJString(listBy))
  add(query_21626194, "MaxResults", newJString(MaxResults))
  result = call_21626193.call(nil, query_21626194, nil, nil, nil)

var listQueues* = Call_ListQueues_21626176(name: "listQueues",
                                        meth: HttpMethod.HttpGet,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/queues",
                                        validator: validate_ListQueues_21626177,
                                        base: "/", makeUrl: url_ListQueues_21626178,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJobTemplate_21626223 = ref object of OpenApiRestCall_21625435
proc url_UpdateJobTemplate_21626225(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/jobTemplates/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateJobTemplate_21626224(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Modify one of your existing job templates.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the job template you are modifying
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626226 = path.getOrDefault("name")
  valid_21626226 = validateParameter(valid_21626226, JString, required = true,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "name", valid_21626226
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
  var valid_21626227 = header.getOrDefault("X-Amz-Date")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Date", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Security-Token", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Algorithm", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Signature")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Signature", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-Credential")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-Credential", valid_21626233
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

proc call*(call_21626235: Call_UpdateJobTemplate_21626223; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Modify one of your existing job templates.
  ## 
  let valid = call_21626235.validator(path, query, header, formData, body, _)
  let scheme = call_21626235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626235.makeUrl(scheme.get, call_21626235.host, call_21626235.base,
                               call_21626235.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626235, uri, valid, _)

proc call*(call_21626236: Call_UpdateJobTemplate_21626223; name: string;
          body: JsonNode): Recallable =
  ## updateJobTemplate
  ## Modify one of your existing job templates.
  ##   name: string (required)
  ##       : The name of the job template you are modifying
  ##   body: JObject (required)
  var path_21626237 = newJObject()
  var body_21626238 = newJObject()
  add(path_21626237, "name", newJString(name))
  if body != nil:
    body_21626238 = body
  result = call_21626236.call(path_21626237, nil, nil, nil, body_21626238)

var updateJobTemplate* = Call_UpdateJobTemplate_21626223(name: "updateJobTemplate",
    meth: HttpMethod.HttpPut, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates/{name}",
    validator: validate_UpdateJobTemplate_21626224, base: "/",
    makeUrl: url_UpdateJobTemplate_21626225, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobTemplate_21626209 = ref object of OpenApiRestCall_21625435
proc url_GetJobTemplate_21626211(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/jobTemplates/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetJobTemplate_21626210(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve the JSON for a specific job template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the job template.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626212 = path.getOrDefault("name")
  valid_21626212 = validateParameter(valid_21626212, JString, required = true,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "name", valid_21626212
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
  var valid_21626213 = header.getOrDefault("X-Amz-Date")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Date", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Security-Token", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Algorithm", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Signature")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Signature", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Credential")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Credential", valid_21626219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626220: Call_GetJobTemplate_21626209; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve the JSON for a specific job template.
  ## 
  let valid = call_21626220.validator(path, query, header, formData, body, _)
  let scheme = call_21626220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626220.makeUrl(scheme.get, call_21626220.host, call_21626220.base,
                               call_21626220.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626220, uri, valid, _)

proc call*(call_21626221: Call_GetJobTemplate_21626209; name: string): Recallable =
  ## getJobTemplate
  ## Retrieve the JSON for a specific job template.
  ##   name: string (required)
  ##       : The name of the job template.
  var path_21626222 = newJObject()
  add(path_21626222, "name", newJString(name))
  result = call_21626221.call(path_21626222, nil, nil, nil, nil)

var getJobTemplate* = Call_GetJobTemplate_21626209(name: "getJobTemplate",
    meth: HttpMethod.HttpGet, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates/{name}", validator: validate_GetJobTemplate_21626210,
    base: "/", makeUrl: url_GetJobTemplate_21626211,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJobTemplate_21626239 = ref object of OpenApiRestCall_21625435
proc url_DeleteJobTemplate_21626241(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/jobTemplates/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteJobTemplate_21626240(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Permanently delete a job template you have created.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the job template to be deleted.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626242 = path.getOrDefault("name")
  valid_21626242 = validateParameter(valid_21626242, JString, required = true,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "name", valid_21626242
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
  var valid_21626243 = header.getOrDefault("X-Amz-Date")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-Date", valid_21626243
  var valid_21626244 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626244 = validateParameter(valid_21626244, JString, required = false,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "X-Amz-Security-Token", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Algorithm", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Signature")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Signature", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Credential")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Credential", valid_21626249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626250: Call_DeleteJobTemplate_21626239; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Permanently delete a job template you have created.
  ## 
  let valid = call_21626250.validator(path, query, header, formData, body, _)
  let scheme = call_21626250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626250.makeUrl(scheme.get, call_21626250.host, call_21626250.base,
                               call_21626250.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626250, uri, valid, _)

proc call*(call_21626251: Call_DeleteJobTemplate_21626239; name: string): Recallable =
  ## deleteJobTemplate
  ## Permanently delete a job template you have created.
  ##   name: string (required)
  ##       : The name of the job template to be deleted.
  var path_21626252 = newJObject()
  add(path_21626252, "name", newJString(name))
  result = call_21626251.call(path_21626252, nil, nil, nil, nil)

var deleteJobTemplate* = Call_DeleteJobTemplate_21626239(name: "deleteJobTemplate",
    meth: HttpMethod.HttpDelete, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates/{name}",
    validator: validate_DeleteJobTemplate_21626240, base: "/",
    makeUrl: url_DeleteJobTemplate_21626241, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePreset_21626267 = ref object of OpenApiRestCall_21625435
proc url_UpdatePreset_21626269(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/presets/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdatePreset_21626268(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Modify one of your existing presets.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the preset you are modifying.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626270 = path.getOrDefault("name")
  valid_21626270 = validateParameter(valid_21626270, JString, required = true,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "name", valid_21626270
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
  var valid_21626271 = header.getOrDefault("X-Amz-Date")
  valid_21626271 = validateParameter(valid_21626271, JString, required = false,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "X-Amz-Date", valid_21626271
  var valid_21626272 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-Security-Token", valid_21626272
  var valid_21626273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626273
  var valid_21626274 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626274 = validateParameter(valid_21626274, JString, required = false,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "X-Amz-Algorithm", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-Signature")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "X-Amz-Signature", valid_21626275
  var valid_21626276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626276
  var valid_21626277 = header.getOrDefault("X-Amz-Credential")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-Credential", valid_21626277
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

proc call*(call_21626279: Call_UpdatePreset_21626267; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Modify one of your existing presets.
  ## 
  let valid = call_21626279.validator(path, query, header, formData, body, _)
  let scheme = call_21626279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626279.makeUrl(scheme.get, call_21626279.host, call_21626279.base,
                               call_21626279.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626279, uri, valid, _)

proc call*(call_21626280: Call_UpdatePreset_21626267; name: string; body: JsonNode): Recallable =
  ## updatePreset
  ## Modify one of your existing presets.
  ##   name: string (required)
  ##       : The name of the preset you are modifying.
  ##   body: JObject (required)
  var path_21626281 = newJObject()
  var body_21626282 = newJObject()
  add(path_21626281, "name", newJString(name))
  if body != nil:
    body_21626282 = body
  result = call_21626280.call(path_21626281, nil, nil, nil, body_21626282)

var updatePreset* = Call_UpdatePreset_21626267(name: "updatePreset",
    meth: HttpMethod.HttpPut, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/presets/{name}", validator: validate_UpdatePreset_21626268,
    base: "/", makeUrl: url_UpdatePreset_21626269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPreset_21626253 = ref object of OpenApiRestCall_21625435
proc url_GetPreset_21626255(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/presets/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetPreset_21626254(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve the JSON for a specific preset.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the preset.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626256 = path.getOrDefault("name")
  valid_21626256 = validateParameter(valid_21626256, JString, required = true,
                                   default = nil)
  if valid_21626256 != nil:
    section.add "name", valid_21626256
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
  var valid_21626257 = header.getOrDefault("X-Amz-Date")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "X-Amz-Date", valid_21626257
  var valid_21626258 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-Security-Token", valid_21626258
  var valid_21626259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626259 = validateParameter(valid_21626259, JString, required = false,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Algorithm", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-Signature")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "X-Amz-Signature", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-Credential")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-Credential", valid_21626263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626264: Call_GetPreset_21626253; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve the JSON for a specific preset.
  ## 
  let valid = call_21626264.validator(path, query, header, formData, body, _)
  let scheme = call_21626264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626264.makeUrl(scheme.get, call_21626264.host, call_21626264.base,
                               call_21626264.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626264, uri, valid, _)

proc call*(call_21626265: Call_GetPreset_21626253; name: string): Recallable =
  ## getPreset
  ## Retrieve the JSON for a specific preset.
  ##   name: string (required)
  ##       : The name of the preset.
  var path_21626266 = newJObject()
  add(path_21626266, "name", newJString(name))
  result = call_21626265.call(path_21626266, nil, nil, nil, nil)

var getPreset* = Call_GetPreset_21626253(name: "getPreset", meth: HttpMethod.HttpGet,
                                      host: "mediaconvert.amazonaws.com",
                                      route: "/2017-08-29/presets/{name}",
                                      validator: validate_GetPreset_21626254,
                                      base: "/", makeUrl: url_GetPreset_21626255,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePreset_21626283 = ref object of OpenApiRestCall_21625435
proc url_DeletePreset_21626285(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/presets/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeletePreset_21626284(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Permanently delete a preset you have created.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the preset to be deleted.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626286 = path.getOrDefault("name")
  valid_21626286 = validateParameter(valid_21626286, JString, required = true,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "name", valid_21626286
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
  var valid_21626287 = header.getOrDefault("X-Amz-Date")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "X-Amz-Date", valid_21626287
  var valid_21626288 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "X-Amz-Security-Token", valid_21626288
  var valid_21626289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626289 = validateParameter(valid_21626289, JString, required = false,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626289
  var valid_21626290 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-Algorithm", valid_21626290
  var valid_21626291 = header.getOrDefault("X-Amz-Signature")
  valid_21626291 = validateParameter(valid_21626291, JString, required = false,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "X-Amz-Signature", valid_21626291
  var valid_21626292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-Credential")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-Credential", valid_21626293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626294: Call_DeletePreset_21626283; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Permanently delete a preset you have created.
  ## 
  let valid = call_21626294.validator(path, query, header, formData, body, _)
  let scheme = call_21626294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626294.makeUrl(scheme.get, call_21626294.host, call_21626294.base,
                               call_21626294.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626294, uri, valid, _)

proc call*(call_21626295: Call_DeletePreset_21626283; name: string): Recallable =
  ## deletePreset
  ## Permanently delete a preset you have created.
  ##   name: string (required)
  ##       : The name of the preset to be deleted.
  var path_21626296 = newJObject()
  add(path_21626296, "name", newJString(name))
  result = call_21626295.call(path_21626296, nil, nil, nil, nil)

var deletePreset* = Call_DeletePreset_21626283(name: "deletePreset",
    meth: HttpMethod.HttpDelete, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/presets/{name}", validator: validate_DeletePreset_21626284,
    base: "/", makeUrl: url_DeletePreset_21626285,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateQueue_21626311 = ref object of OpenApiRestCall_21625435
proc url_UpdateQueue_21626313(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/queues/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateQueue_21626312(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Modify one of your existing queues.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the queue that you are modifying.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626314 = path.getOrDefault("name")
  valid_21626314 = validateParameter(valid_21626314, JString, required = true,
                                   default = nil)
  if valid_21626314 != nil:
    section.add "name", valid_21626314
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
  var valid_21626315 = header.getOrDefault("X-Amz-Date")
  valid_21626315 = validateParameter(valid_21626315, JString, required = false,
                                   default = nil)
  if valid_21626315 != nil:
    section.add "X-Amz-Date", valid_21626315
  var valid_21626316 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626316 = validateParameter(valid_21626316, JString, required = false,
                                   default = nil)
  if valid_21626316 != nil:
    section.add "X-Amz-Security-Token", valid_21626316
  var valid_21626317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626317
  var valid_21626318 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-Algorithm", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Signature")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "X-Amz-Signature", valid_21626319
  var valid_21626320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626320
  var valid_21626321 = header.getOrDefault("X-Amz-Credential")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "X-Amz-Credential", valid_21626321
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

proc call*(call_21626323: Call_UpdateQueue_21626311; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Modify one of your existing queues.
  ## 
  let valid = call_21626323.validator(path, query, header, formData, body, _)
  let scheme = call_21626323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626323.makeUrl(scheme.get, call_21626323.host, call_21626323.base,
                               call_21626323.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626323, uri, valid, _)

proc call*(call_21626324: Call_UpdateQueue_21626311; name: string; body: JsonNode): Recallable =
  ## updateQueue
  ## Modify one of your existing queues.
  ##   name: string (required)
  ##       : The name of the queue that you are modifying.
  ##   body: JObject (required)
  var path_21626325 = newJObject()
  var body_21626326 = newJObject()
  add(path_21626325, "name", newJString(name))
  if body != nil:
    body_21626326 = body
  result = call_21626324.call(path_21626325, nil, nil, nil, body_21626326)

var updateQueue* = Call_UpdateQueue_21626311(name: "updateQueue",
    meth: HttpMethod.HttpPut, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/queues/{name}", validator: validate_UpdateQueue_21626312,
    base: "/", makeUrl: url_UpdateQueue_21626313,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQueue_21626297 = ref object of OpenApiRestCall_21625435
proc url_GetQueue_21626299(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/queues/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetQueue_21626298(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve the JSON for a specific queue.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the queue that you want information about.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626300 = path.getOrDefault("name")
  valid_21626300 = validateParameter(valid_21626300, JString, required = true,
                                   default = nil)
  if valid_21626300 != nil:
    section.add "name", valid_21626300
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
  var valid_21626301 = header.getOrDefault("X-Amz-Date")
  valid_21626301 = validateParameter(valid_21626301, JString, required = false,
                                   default = nil)
  if valid_21626301 != nil:
    section.add "X-Amz-Date", valid_21626301
  var valid_21626302 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626302 = validateParameter(valid_21626302, JString, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "X-Amz-Security-Token", valid_21626302
  var valid_21626303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626304 = validateParameter(valid_21626304, JString, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "X-Amz-Algorithm", valid_21626304
  var valid_21626305 = header.getOrDefault("X-Amz-Signature")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "X-Amz-Signature", valid_21626305
  var valid_21626306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626306 = validateParameter(valid_21626306, JString, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626306
  var valid_21626307 = header.getOrDefault("X-Amz-Credential")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Credential", valid_21626307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626308: Call_GetQueue_21626297; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve the JSON for a specific queue.
  ## 
  let valid = call_21626308.validator(path, query, header, formData, body, _)
  let scheme = call_21626308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626308.makeUrl(scheme.get, call_21626308.host, call_21626308.base,
                               call_21626308.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626308, uri, valid, _)

proc call*(call_21626309: Call_GetQueue_21626297; name: string): Recallable =
  ## getQueue
  ## Retrieve the JSON for a specific queue.
  ##   name: string (required)
  ##       : The name of the queue that you want information about.
  var path_21626310 = newJObject()
  add(path_21626310, "name", newJString(name))
  result = call_21626309.call(path_21626310, nil, nil, nil, nil)

var getQueue* = Call_GetQueue_21626297(name: "getQueue", meth: HttpMethod.HttpGet,
                                    host: "mediaconvert.amazonaws.com",
                                    route: "/2017-08-29/queues/{name}",
                                    validator: validate_GetQueue_21626298,
                                    base: "/", makeUrl: url_GetQueue_21626299,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteQueue_21626327 = ref object of OpenApiRestCall_21625435
proc url_DeleteQueue_21626329(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/queues/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteQueue_21626328(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Permanently delete a queue you have created.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the queue that you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626330 = path.getOrDefault("name")
  valid_21626330 = validateParameter(valid_21626330, JString, required = true,
                                   default = nil)
  if valid_21626330 != nil:
    section.add "name", valid_21626330
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
  var valid_21626331 = header.getOrDefault("X-Amz-Date")
  valid_21626331 = validateParameter(valid_21626331, JString, required = false,
                                   default = nil)
  if valid_21626331 != nil:
    section.add "X-Amz-Date", valid_21626331
  var valid_21626332 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-Security-Token", valid_21626332
  var valid_21626333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626333
  var valid_21626334 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626334 = validateParameter(valid_21626334, JString, required = false,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "X-Amz-Algorithm", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Signature")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Signature", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Credential")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Credential", valid_21626337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626338: Call_DeleteQueue_21626327; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Permanently delete a queue you have created.
  ## 
  let valid = call_21626338.validator(path, query, header, formData, body, _)
  let scheme = call_21626338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626338.makeUrl(scheme.get, call_21626338.host, call_21626338.base,
                               call_21626338.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626338, uri, valid, _)

proc call*(call_21626339: Call_DeleteQueue_21626327; name: string): Recallable =
  ## deleteQueue
  ## Permanently delete a queue you have created.
  ##   name: string (required)
  ##       : The name of the queue that you want to delete.
  var path_21626340 = newJObject()
  add(path_21626340, "name", newJString(name))
  result = call_21626339.call(path_21626340, nil, nil, nil, nil)

var deleteQueue* = Call_DeleteQueue_21626327(name: "deleteQueue",
    meth: HttpMethod.HttpDelete, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/queues/{name}", validator: validate_DeleteQueue_21626328,
    base: "/", makeUrl: url_DeleteQueue_21626329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoints_21626341 = ref object of OpenApiRestCall_21625435
proc url_DescribeEndpoints_21626343(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEndpoints_21626342(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Send an request with an empty body to the regional API endpoint to get your account API endpoint.
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
  var valid_21626344 = query.getOrDefault("NextToken")
  valid_21626344 = validateParameter(valid_21626344, JString, required = false,
                                   default = nil)
  if valid_21626344 != nil:
    section.add "NextToken", valid_21626344
  var valid_21626345 = query.getOrDefault("MaxResults")
  valid_21626345 = validateParameter(valid_21626345, JString, required = false,
                                   default = nil)
  if valid_21626345 != nil:
    section.add "MaxResults", valid_21626345
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
  var valid_21626346 = header.getOrDefault("X-Amz-Date")
  valid_21626346 = validateParameter(valid_21626346, JString, required = false,
                                   default = nil)
  if valid_21626346 != nil:
    section.add "X-Amz-Date", valid_21626346
  var valid_21626347 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626347 = validateParameter(valid_21626347, JString, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "X-Amz-Security-Token", valid_21626347
  var valid_21626348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "X-Amz-Algorithm", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Signature")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Signature", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Credential")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Credential", valid_21626352
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

proc call*(call_21626354: Call_DescribeEndpoints_21626341; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Send an request with an empty body to the regional API endpoint to get your account API endpoint.
  ## 
  let valid = call_21626354.validator(path, query, header, formData, body, _)
  let scheme = call_21626354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626354.makeUrl(scheme.get, call_21626354.host, call_21626354.base,
                               call_21626354.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626354, uri, valid, _)

proc call*(call_21626355: Call_DescribeEndpoints_21626341; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeEndpoints
  ## Send an request with an empty body to the regional API endpoint to get your account API endpoint.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626356 = newJObject()
  var body_21626357 = newJObject()
  add(query_21626356, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626357 = body
  add(query_21626356, "MaxResults", newJString(MaxResults))
  result = call_21626355.call(nil, query_21626356, nil, nil, body_21626357)

var describeEndpoints* = Call_DescribeEndpoints_21626341(name: "describeEndpoints",
    meth: HttpMethod.HttpPost, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/endpoints", validator: validate_DescribeEndpoints_21626342,
    base: "/", makeUrl: url_DescribeEndpoints_21626343,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateCertificate_21626358 = ref object of OpenApiRestCall_21625435
proc url_DisassociateCertificate_21626360(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "arn" in path, "`arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/certificates/"),
               (kind: VariableSegment, value: "arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociateCertificate_21626359(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes an association between the Amazon Resource Name (ARN) of an AWS Certificate Manager (ACM) certificate and an AWS Elemental MediaConvert resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   arn: JString (required)
  ##      : The ARN of the ACM certificate that you want to disassociate from your MediaConvert resource.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `arn` field"
  var valid_21626361 = path.getOrDefault("arn")
  valid_21626361 = validateParameter(valid_21626361, JString, required = true,
                                   default = nil)
  if valid_21626361 != nil:
    section.add "arn", valid_21626361
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
  var valid_21626362 = header.getOrDefault("X-Amz-Date")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "X-Amz-Date", valid_21626362
  var valid_21626363 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626363 = validateParameter(valid_21626363, JString, required = false,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "X-Amz-Security-Token", valid_21626363
  var valid_21626364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626364 = validateParameter(valid_21626364, JString, required = false,
                                   default = nil)
  if valid_21626364 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626364
  var valid_21626365 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626365 = validateParameter(valid_21626365, JString, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "X-Amz-Algorithm", valid_21626365
  var valid_21626366 = header.getOrDefault("X-Amz-Signature")
  valid_21626366 = validateParameter(valid_21626366, JString, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "X-Amz-Signature", valid_21626366
  var valid_21626367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-Credential")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-Credential", valid_21626368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626369: Call_DisassociateCertificate_21626358;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes an association between the Amazon Resource Name (ARN) of an AWS Certificate Manager (ACM) certificate and an AWS Elemental MediaConvert resource.
  ## 
  let valid = call_21626369.validator(path, query, header, formData, body, _)
  let scheme = call_21626369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626369.makeUrl(scheme.get, call_21626369.host, call_21626369.base,
                               call_21626369.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626369, uri, valid, _)

proc call*(call_21626370: Call_DisassociateCertificate_21626358; arn: string): Recallable =
  ## disassociateCertificate
  ## Removes an association between the Amazon Resource Name (ARN) of an AWS Certificate Manager (ACM) certificate and an AWS Elemental MediaConvert resource.
  ##   arn: string (required)
  ##      : The ARN of the ACM certificate that you want to disassociate from your MediaConvert resource.
  var path_21626371 = newJObject()
  add(path_21626371, "arn", newJString(arn))
  result = call_21626370.call(path_21626371, nil, nil, nil, nil)

var disassociateCertificate* = Call_DisassociateCertificate_21626358(
    name: "disassociateCertificate", meth: HttpMethod.HttpDelete,
    host: "mediaconvert.amazonaws.com", route: "/2017-08-29/certificates/{arn}",
    validator: validate_DisassociateCertificate_21626359, base: "/",
    makeUrl: url_DisassociateCertificate_21626360,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626386 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21626388(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "arn" in path, "`arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/tags/"),
               (kind: VariableSegment, value: "arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_21626387(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Remove tags from a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   arn: JString (required)
  ##      : The Amazon Resource Name (ARN) of the resource that you want to remove tags from. To get the ARN, send a GET request with the resource name.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `arn` field"
  var valid_21626389 = path.getOrDefault("arn")
  valid_21626389 = validateParameter(valid_21626389, JString, required = true,
                                   default = nil)
  if valid_21626389 != nil:
    section.add "arn", valid_21626389
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
  var valid_21626390 = header.getOrDefault("X-Amz-Date")
  valid_21626390 = validateParameter(valid_21626390, JString, required = false,
                                   default = nil)
  if valid_21626390 != nil:
    section.add "X-Amz-Date", valid_21626390
  var valid_21626391 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626391 = validateParameter(valid_21626391, JString, required = false,
                                   default = nil)
  if valid_21626391 != nil:
    section.add "X-Amz-Security-Token", valid_21626391
  var valid_21626392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626392 = validateParameter(valid_21626392, JString, required = false,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626392
  var valid_21626393 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626393 = validateParameter(valid_21626393, JString, required = false,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "X-Amz-Algorithm", valid_21626393
  var valid_21626394 = header.getOrDefault("X-Amz-Signature")
  valid_21626394 = validateParameter(valid_21626394, JString, required = false,
                                   default = nil)
  if valid_21626394 != nil:
    section.add "X-Amz-Signature", valid_21626394
  var valid_21626395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-Credential")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-Credential", valid_21626396
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

proc call*(call_21626398: Call_UntagResource_21626386; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Remove tags from a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ## 
  let valid = call_21626398.validator(path, query, header, formData, body, _)
  let scheme = call_21626398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626398.makeUrl(scheme.get, call_21626398.host, call_21626398.base,
                               call_21626398.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626398, uri, valid, _)

proc call*(call_21626399: Call_UntagResource_21626386; arn: string; body: JsonNode): Recallable =
  ## untagResource
  ## Remove tags from a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ##   arn: string (required)
  ##      : The Amazon Resource Name (ARN) of the resource that you want to remove tags from. To get the ARN, send a GET request with the resource name.
  ##   body: JObject (required)
  var path_21626400 = newJObject()
  var body_21626401 = newJObject()
  add(path_21626400, "arn", newJString(arn))
  if body != nil:
    body_21626401 = body
  result = call_21626399.call(path_21626400, nil, nil, nil, body_21626401)

var untagResource* = Call_UntagResource_21626386(name: "untagResource",
    meth: HttpMethod.HttpPut, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/tags/{arn}", validator: validate_UntagResource_21626387,
    base: "/", makeUrl: url_UntagResource_21626388,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626372 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource_21626374(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "arn" in path, "`arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/tags/"),
               (kind: VariableSegment, value: "arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_21626373(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve the tags for a MediaConvert resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   arn: JString (required)
  ##      : The Amazon Resource Name (ARN) of the resource that you want to list tags for. To get the ARN, send a GET request with the resource name.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `arn` field"
  var valid_21626375 = path.getOrDefault("arn")
  valid_21626375 = validateParameter(valid_21626375, JString, required = true,
                                   default = nil)
  if valid_21626375 != nil:
    section.add "arn", valid_21626375
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
  var valid_21626376 = header.getOrDefault("X-Amz-Date")
  valid_21626376 = validateParameter(valid_21626376, JString, required = false,
                                   default = nil)
  if valid_21626376 != nil:
    section.add "X-Amz-Date", valid_21626376
  var valid_21626377 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626377 = validateParameter(valid_21626377, JString, required = false,
                                   default = nil)
  if valid_21626377 != nil:
    section.add "X-Amz-Security-Token", valid_21626377
  var valid_21626378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626378 = validateParameter(valid_21626378, JString, required = false,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626378
  var valid_21626379 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626379 = validateParameter(valid_21626379, JString, required = false,
                                   default = nil)
  if valid_21626379 != nil:
    section.add "X-Amz-Algorithm", valid_21626379
  var valid_21626380 = header.getOrDefault("X-Amz-Signature")
  valid_21626380 = validateParameter(valid_21626380, JString, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "X-Amz-Signature", valid_21626380
  var valid_21626381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626381 = validateParameter(valid_21626381, JString, required = false,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-Credential")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Credential", valid_21626382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626383: Call_ListTagsForResource_21626372; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve the tags for a MediaConvert resource.
  ## 
  let valid = call_21626383.validator(path, query, header, formData, body, _)
  let scheme = call_21626383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626383.makeUrl(scheme.get, call_21626383.host, call_21626383.base,
                               call_21626383.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626383, uri, valid, _)

proc call*(call_21626384: Call_ListTagsForResource_21626372; arn: string): Recallable =
  ## listTagsForResource
  ## Retrieve the tags for a MediaConvert resource.
  ##   arn: string (required)
  ##      : The Amazon Resource Name (ARN) of the resource that you want to list tags for. To get the ARN, send a GET request with the resource name.
  var path_21626385 = newJObject()
  add(path_21626385, "arn", newJString(arn))
  result = call_21626384.call(path_21626385, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_21626372(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "mediaconvert.amazonaws.com", route: "/2017-08-29/tags/{arn}",
    validator: validate_ListTagsForResource_21626373, base: "/",
    makeUrl: url_ListTagsForResource_21626374,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626402 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21626404(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_21626403(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Add tags to a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
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
  var valid_21626405 = header.getOrDefault("X-Amz-Date")
  valid_21626405 = validateParameter(valid_21626405, JString, required = false,
                                   default = nil)
  if valid_21626405 != nil:
    section.add "X-Amz-Date", valid_21626405
  var valid_21626406 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626406 = validateParameter(valid_21626406, JString, required = false,
                                   default = nil)
  if valid_21626406 != nil:
    section.add "X-Amz-Security-Token", valid_21626406
  var valid_21626407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626407 = validateParameter(valid_21626407, JString, required = false,
                                   default = nil)
  if valid_21626407 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626407
  var valid_21626408 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626408 = validateParameter(valid_21626408, JString, required = false,
                                   default = nil)
  if valid_21626408 != nil:
    section.add "X-Amz-Algorithm", valid_21626408
  var valid_21626409 = header.getOrDefault("X-Amz-Signature")
  valid_21626409 = validateParameter(valid_21626409, JString, required = false,
                                   default = nil)
  if valid_21626409 != nil:
    section.add "X-Amz-Signature", valid_21626409
  var valid_21626410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626410 = validateParameter(valid_21626410, JString, required = false,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626410
  var valid_21626411 = header.getOrDefault("X-Amz-Credential")
  valid_21626411 = validateParameter(valid_21626411, JString, required = false,
                                   default = nil)
  if valid_21626411 != nil:
    section.add "X-Amz-Credential", valid_21626411
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

proc call*(call_21626413: Call_TagResource_21626402; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Add tags to a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ## 
  let valid = call_21626413.validator(path, query, header, formData, body, _)
  let scheme = call_21626413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626413.makeUrl(scheme.get, call_21626413.host, call_21626413.base,
                               call_21626413.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626413, uri, valid, _)

proc call*(call_21626414: Call_TagResource_21626402; body: JsonNode): Recallable =
  ## tagResource
  ## Add tags to a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ##   body: JObject (required)
  var body_21626415 = newJObject()
  if body != nil:
    body_21626415 = body
  result = call_21626414.call(nil, nil, nil, nil, body_21626415)

var tagResource* = Call_TagResource_21626402(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/tags", validator: validate_TagResource_21626403, base: "/",
    makeUrl: url_TagResource_21626404, schemes: {Scheme.Https, Scheme.Http})
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