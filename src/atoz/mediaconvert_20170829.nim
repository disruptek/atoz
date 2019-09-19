
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AssociateCertificate_600768 = ref object of OpenApiRestCall_600426
proc url_AssociateCertificate_600770(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AssociateCertificate_600769(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600882 = header.getOrDefault("X-Amz-Date")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Date", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-Security-Token")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Security-Token", valid_600883
  var valid_600884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "X-Amz-Content-Sha256", valid_600884
  var valid_600885 = header.getOrDefault("X-Amz-Algorithm")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "X-Amz-Algorithm", valid_600885
  var valid_600886 = header.getOrDefault("X-Amz-Signature")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Signature", valid_600886
  var valid_600887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-SignedHeaders", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Credential")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Credential", valid_600888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600912: Call_AssociateCertificate_600768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates an AWS Certificate Manager (ACM) Amazon Resource Name (ARN) with AWS Elemental MediaConvert.
  ## 
  let valid = call_600912.validator(path, query, header, formData, body)
  let scheme = call_600912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600912.url(scheme.get, call_600912.host, call_600912.base,
                         call_600912.route, valid.getOrDefault("path"))
  result = hook(call_600912, url, valid)

proc call*(call_600983: Call_AssociateCertificate_600768; body: JsonNode): Recallable =
  ## associateCertificate
  ## Associates an AWS Certificate Manager (ACM) Amazon Resource Name (ARN) with AWS Elemental MediaConvert.
  ##   body: JObject (required)
  var body_600984 = newJObject()
  if body != nil:
    body_600984 = body
  result = call_600983.call(nil, nil, nil, nil, body_600984)

var associateCertificate* = Call_AssociateCertificate_600768(
    name: "associateCertificate", meth: HttpMethod.HttpPost,
    host: "mediaconvert.amazonaws.com", route: "/2017-08-29/certificates",
    validator: validate_AssociateCertificate_600769, base: "/",
    url: url_AssociateCertificate_600770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_601023 = ref object of OpenApiRestCall_600426
proc url_GetJob_601025(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/jobs/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetJob_601024(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve the JSON for a specific completed transcoding job.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : the job ID of the job.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_601040 = path.getOrDefault("id")
  valid_601040 = validateParameter(valid_601040, JString, required = true,
                                 default = nil)
  if valid_601040 != nil:
    section.add "id", valid_601040
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
  var valid_601041 = header.getOrDefault("X-Amz-Date")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Date", valid_601041
  var valid_601042 = header.getOrDefault("X-Amz-Security-Token")
  valid_601042 = validateParameter(valid_601042, JString, required = false,
                                 default = nil)
  if valid_601042 != nil:
    section.add "X-Amz-Security-Token", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Content-Sha256", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Algorithm")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Algorithm", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Signature")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Signature", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-SignedHeaders", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Credential")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Credential", valid_601047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601048: Call_GetJob_601023; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the JSON for a specific completed transcoding job.
  ## 
  let valid = call_601048.validator(path, query, header, formData, body)
  let scheme = call_601048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601048.url(scheme.get, call_601048.host, call_601048.base,
                         call_601048.route, valid.getOrDefault("path"))
  result = hook(call_601048, url, valid)

proc call*(call_601049: Call_GetJob_601023; id: string): Recallable =
  ## getJob
  ## Retrieve the JSON for a specific completed transcoding job.
  ##   id: string (required)
  ##     : the job ID of the job.
  var path_601050 = newJObject()
  add(path_601050, "id", newJString(id))
  result = call_601049.call(path_601050, nil, nil, nil, nil)

var getJob* = Call_GetJob_601023(name: "getJob", meth: HttpMethod.HttpGet,
                              host: "mediaconvert.amazonaws.com",
                              route: "/2017-08-29/jobs/{id}",
                              validator: validate_GetJob_601024, base: "/",
                              url: url_GetJob_601025,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelJob_601052 = ref object of OpenApiRestCall_600426
proc url_CancelJob_601054(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/jobs/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CancelJob_601053(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Permanently cancel a job. Once you have canceled a job, you can't start it again.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The Job ID of the job to be cancelled.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_601055 = path.getOrDefault("id")
  valid_601055 = validateParameter(valid_601055, JString, required = true,
                                 default = nil)
  if valid_601055 != nil:
    section.add "id", valid_601055
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
  var valid_601056 = header.getOrDefault("X-Amz-Date")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Date", valid_601056
  var valid_601057 = header.getOrDefault("X-Amz-Security-Token")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Security-Token", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Content-Sha256", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Algorithm")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Algorithm", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Signature")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Signature", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-SignedHeaders", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Credential")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Credential", valid_601062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601063: Call_CancelJob_601052; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently cancel a job. Once you have canceled a job, you can't start it again.
  ## 
  let valid = call_601063.validator(path, query, header, formData, body)
  let scheme = call_601063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601063.url(scheme.get, call_601063.host, call_601063.base,
                         call_601063.route, valid.getOrDefault("path"))
  result = hook(call_601063, url, valid)

proc call*(call_601064: Call_CancelJob_601052; id: string): Recallable =
  ## cancelJob
  ## Permanently cancel a job. Once you have canceled a job, you can't start it again.
  ##   id: string (required)
  ##     : The Job ID of the job to be cancelled.
  var path_601065 = newJObject()
  add(path_601065, "id", newJString(id))
  result = call_601064.call(path_601065, nil, nil, nil, nil)

var cancelJob* = Call_CancelJob_601052(name: "cancelJob",
                                    meth: HttpMethod.HttpDelete,
                                    host: "mediaconvert.amazonaws.com",
                                    route: "/2017-08-29/jobs/{id}",
                                    validator: validate_CancelJob_601053,
                                    base: "/", url: url_CancelJob_601054,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_601099 = ref object of OpenApiRestCall_600426
proc url_CreateJob_601101(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateJob_601100(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601102 = header.getOrDefault("X-Amz-Date")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "X-Amz-Date", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Security-Token")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Security-Token", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Content-Sha256", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Algorithm")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Algorithm", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Signature")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Signature", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-SignedHeaders", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-Credential")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Credential", valid_601108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601110: Call_CreateJob_601099; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new transcoding job. For information about jobs and job settings, see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ## 
  let valid = call_601110.validator(path, query, header, formData, body)
  let scheme = call_601110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601110.url(scheme.get, call_601110.host, call_601110.base,
                         call_601110.route, valid.getOrDefault("path"))
  result = hook(call_601110, url, valid)

proc call*(call_601111: Call_CreateJob_601099; body: JsonNode): Recallable =
  ## createJob
  ## Create a new transcoding job. For information about jobs and job settings, see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ##   body: JObject (required)
  var body_601112 = newJObject()
  if body != nil:
    body_601112 = body
  result = call_601111.call(nil, nil, nil, nil, body_601112)

var createJob* = Call_CreateJob_601099(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "mediaconvert.amazonaws.com",
                                    route: "/2017-08-29/jobs",
                                    validator: validate_CreateJob_601100,
                                    base: "/", url: url_CreateJob_601101,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_601066 = ref object of OpenApiRestCall_600426
proc url_ListJobs_601068(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListJobs_601067(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601082 = query.getOrDefault("order")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_601082 != nil:
    section.add "order", valid_601082
  var valid_601083 = query.getOrDefault("NextToken")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "NextToken", valid_601083
  var valid_601084 = query.getOrDefault("maxResults")
  valid_601084 = validateParameter(valid_601084, JInt, required = false, default = nil)
  if valid_601084 != nil:
    section.add "maxResults", valid_601084
  var valid_601085 = query.getOrDefault("nextToken")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "nextToken", valid_601085
  var valid_601086 = query.getOrDefault("status")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = newJString("SUBMITTED"))
  if valid_601086 != nil:
    section.add "status", valid_601086
  var valid_601087 = query.getOrDefault("queue")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "queue", valid_601087
  var valid_601088 = query.getOrDefault("MaxResults")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "MaxResults", valid_601088
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
  var valid_601089 = header.getOrDefault("X-Amz-Date")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Date", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Security-Token")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Security-Token", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Content-Sha256", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Algorithm")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Algorithm", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-Signature")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Signature", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-SignedHeaders", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-Credential")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Credential", valid_601095
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601096: Call_ListJobs_601066; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a JSON array of up to twenty of your most recently created jobs. This array includes in-process, completed, and errored jobs. This will return the jobs themselves, not just a list of the jobs. To retrieve the twenty next most recent jobs, use the nextToken string returned with the array.
  ## 
  let valid = call_601096.validator(path, query, header, formData, body)
  let scheme = call_601096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601096.url(scheme.get, call_601096.host, call_601096.base,
                         call_601096.route, valid.getOrDefault("path"))
  result = hook(call_601096, url, valid)

proc call*(call_601097: Call_ListJobs_601066; order: string = "ASCENDING";
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
  var query_601098 = newJObject()
  add(query_601098, "order", newJString(order))
  add(query_601098, "NextToken", newJString(NextToken))
  add(query_601098, "maxResults", newJInt(maxResults))
  add(query_601098, "nextToken", newJString(nextToken))
  add(query_601098, "status", newJString(status))
  add(query_601098, "queue", newJString(queue))
  add(query_601098, "MaxResults", newJString(MaxResults))
  result = call_601097.call(nil, query_601098, nil, nil, nil)

var listJobs* = Call_ListJobs_601066(name: "listJobs", meth: HttpMethod.HttpGet,
                                  host: "mediaconvert.amazonaws.com",
                                  route: "/2017-08-29/jobs",
                                  validator: validate_ListJobs_601067, base: "/",
                                  url: url_ListJobs_601068,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJobTemplate_601133 = ref object of OpenApiRestCall_600426
proc url_CreateJobTemplate_601135(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateJobTemplate_601134(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_601136 = header.getOrDefault("X-Amz-Date")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Date", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Security-Token")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Security-Token", valid_601137
  var valid_601138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "X-Amz-Content-Sha256", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Algorithm")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Algorithm", valid_601139
  var valid_601140 = header.getOrDefault("X-Amz-Signature")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Signature", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-SignedHeaders", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-Credential")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-Credential", valid_601142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601144: Call_CreateJobTemplate_601133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new job template. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ## 
  let valid = call_601144.validator(path, query, header, formData, body)
  let scheme = call_601144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601144.url(scheme.get, call_601144.host, call_601144.base,
                         call_601144.route, valid.getOrDefault("path"))
  result = hook(call_601144, url, valid)

proc call*(call_601145: Call_CreateJobTemplate_601133; body: JsonNode): Recallable =
  ## createJobTemplate
  ## Create a new job template. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ##   body: JObject (required)
  var body_601146 = newJObject()
  if body != nil:
    body_601146 = body
  result = call_601145.call(nil, nil, nil, nil, body_601146)

var createJobTemplate* = Call_CreateJobTemplate_601133(name: "createJobTemplate",
    meth: HttpMethod.HttpPost, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates", validator: validate_CreateJobTemplate_601134,
    base: "/", url: url_CreateJobTemplate_601135,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobTemplates_601113 = ref object of OpenApiRestCall_600426
proc url_ListJobTemplates_601115(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListJobTemplates_601114(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_601116 = query.getOrDefault("order")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_601116 != nil:
    section.add "order", valid_601116
  var valid_601117 = query.getOrDefault("NextToken")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "NextToken", valid_601117
  var valid_601118 = query.getOrDefault("maxResults")
  valid_601118 = validateParameter(valid_601118, JInt, required = false, default = nil)
  if valid_601118 != nil:
    section.add "maxResults", valid_601118
  var valid_601119 = query.getOrDefault("nextToken")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "nextToken", valid_601119
  var valid_601120 = query.getOrDefault("listBy")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = newJString("NAME"))
  if valid_601120 != nil:
    section.add "listBy", valid_601120
  var valid_601121 = query.getOrDefault("category")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "category", valid_601121
  var valid_601122 = query.getOrDefault("MaxResults")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "MaxResults", valid_601122
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
  var valid_601123 = header.getOrDefault("X-Amz-Date")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "X-Amz-Date", valid_601123
  var valid_601124 = header.getOrDefault("X-Amz-Security-Token")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-Security-Token", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Content-Sha256", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Algorithm")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Algorithm", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-Signature")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-Signature", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-SignedHeaders", valid_601128
  var valid_601129 = header.getOrDefault("X-Amz-Credential")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-Credential", valid_601129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601130: Call_ListJobTemplates_601113; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a JSON array of up to twenty of your job templates. This will return the templates themselves, not just a list of them. To retrieve the next twenty templates, use the nextToken string returned with the array
  ## 
  let valid = call_601130.validator(path, query, header, formData, body)
  let scheme = call_601130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601130.url(scheme.get, call_601130.host, call_601130.base,
                         call_601130.route, valid.getOrDefault("path"))
  result = hook(call_601130, url, valid)

proc call*(call_601131: Call_ListJobTemplates_601113; order: string = "ASCENDING";
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          listBy: string = "NAME"; category: string = ""; MaxResults: string = ""): Recallable =
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
  var query_601132 = newJObject()
  add(query_601132, "order", newJString(order))
  add(query_601132, "NextToken", newJString(NextToken))
  add(query_601132, "maxResults", newJInt(maxResults))
  add(query_601132, "nextToken", newJString(nextToken))
  add(query_601132, "listBy", newJString(listBy))
  add(query_601132, "category", newJString(category))
  add(query_601132, "MaxResults", newJString(MaxResults))
  result = call_601131.call(nil, query_601132, nil, nil, nil)

var listJobTemplates* = Call_ListJobTemplates_601113(name: "listJobTemplates",
    meth: HttpMethod.HttpGet, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates", validator: validate_ListJobTemplates_601114,
    base: "/", url: url_ListJobTemplates_601115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePreset_601167 = ref object of OpenApiRestCall_600426
proc url_CreatePreset_601169(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreatePreset_601168(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601170 = header.getOrDefault("X-Amz-Date")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Date", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-Security-Token")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Security-Token", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-Content-Sha256", valid_601172
  var valid_601173 = header.getOrDefault("X-Amz-Algorithm")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "X-Amz-Algorithm", valid_601173
  var valid_601174 = header.getOrDefault("X-Amz-Signature")
  valid_601174 = validateParameter(valid_601174, JString, required = false,
                                 default = nil)
  if valid_601174 != nil:
    section.add "X-Amz-Signature", valid_601174
  var valid_601175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "X-Amz-SignedHeaders", valid_601175
  var valid_601176 = header.getOrDefault("X-Amz-Credential")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "X-Amz-Credential", valid_601176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601178: Call_CreatePreset_601167; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new preset. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ## 
  let valid = call_601178.validator(path, query, header, formData, body)
  let scheme = call_601178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601178.url(scheme.get, call_601178.host, call_601178.base,
                         call_601178.route, valid.getOrDefault("path"))
  result = hook(call_601178, url, valid)

proc call*(call_601179: Call_CreatePreset_601167; body: JsonNode): Recallable =
  ## createPreset
  ## Create a new preset. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ##   body: JObject (required)
  var body_601180 = newJObject()
  if body != nil:
    body_601180 = body
  result = call_601179.call(nil, nil, nil, nil, body_601180)

var createPreset* = Call_CreatePreset_601167(name: "createPreset",
    meth: HttpMethod.HttpPost, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/presets", validator: validate_CreatePreset_601168,
    base: "/", url: url_CreatePreset_601169, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPresets_601147 = ref object of OpenApiRestCall_600426
proc url_ListPresets_601149(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPresets_601148(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601150 = query.getOrDefault("order")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_601150 != nil:
    section.add "order", valid_601150
  var valid_601151 = query.getOrDefault("NextToken")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "NextToken", valid_601151
  var valid_601152 = query.getOrDefault("maxResults")
  valid_601152 = validateParameter(valid_601152, JInt, required = false, default = nil)
  if valid_601152 != nil:
    section.add "maxResults", valid_601152
  var valid_601153 = query.getOrDefault("nextToken")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "nextToken", valid_601153
  var valid_601154 = query.getOrDefault("listBy")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = newJString("NAME"))
  if valid_601154 != nil:
    section.add "listBy", valid_601154
  var valid_601155 = query.getOrDefault("category")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "category", valid_601155
  var valid_601156 = query.getOrDefault("MaxResults")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "MaxResults", valid_601156
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
  var valid_601157 = header.getOrDefault("X-Amz-Date")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-Date", valid_601157
  var valid_601158 = header.getOrDefault("X-Amz-Security-Token")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-Security-Token", valid_601158
  var valid_601159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "X-Amz-Content-Sha256", valid_601159
  var valid_601160 = header.getOrDefault("X-Amz-Algorithm")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-Algorithm", valid_601160
  var valid_601161 = header.getOrDefault("X-Amz-Signature")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Signature", valid_601161
  var valid_601162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601162 = validateParameter(valid_601162, JString, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "X-Amz-SignedHeaders", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Credential")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Credential", valid_601163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601164: Call_ListPresets_601147; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a JSON array of up to twenty of your presets. This will return the presets themselves, not just a list of them. To retrieve the next twenty presets, use the nextToken string returned with the array.
  ## 
  let valid = call_601164.validator(path, query, header, formData, body)
  let scheme = call_601164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601164.url(scheme.get, call_601164.host, call_601164.base,
                         call_601164.route, valid.getOrDefault("path"))
  result = hook(call_601164, url, valid)

proc call*(call_601165: Call_ListPresets_601147; order: string = "ASCENDING";
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
  var query_601166 = newJObject()
  add(query_601166, "order", newJString(order))
  add(query_601166, "NextToken", newJString(NextToken))
  add(query_601166, "maxResults", newJInt(maxResults))
  add(query_601166, "nextToken", newJString(nextToken))
  add(query_601166, "listBy", newJString(listBy))
  add(query_601166, "category", newJString(category))
  add(query_601166, "MaxResults", newJString(MaxResults))
  result = call_601165.call(nil, query_601166, nil, nil, nil)

var listPresets* = Call_ListPresets_601147(name: "listPresets",
                                        meth: HttpMethod.HttpGet,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/presets",
                                        validator: validate_ListPresets_601148,
                                        base: "/", url: url_ListPresets_601149,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateQueue_601200 = ref object of OpenApiRestCall_600426
proc url_CreateQueue_601202(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateQueue_601201(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601203 = header.getOrDefault("X-Amz-Date")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Date", valid_601203
  var valid_601204 = header.getOrDefault("X-Amz-Security-Token")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "X-Amz-Security-Token", valid_601204
  var valid_601205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-Content-Sha256", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-Algorithm")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Algorithm", valid_601206
  var valid_601207 = header.getOrDefault("X-Amz-Signature")
  valid_601207 = validateParameter(valid_601207, JString, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "X-Amz-Signature", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-SignedHeaders", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-Credential")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Credential", valid_601209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601211: Call_CreateQueue_601200; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new transcoding queue. For information about queues, see Working With Queues in the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/working-with-queues.html
  ## 
  let valid = call_601211.validator(path, query, header, formData, body)
  let scheme = call_601211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601211.url(scheme.get, call_601211.host, call_601211.base,
                         call_601211.route, valid.getOrDefault("path"))
  result = hook(call_601211, url, valid)

proc call*(call_601212: Call_CreateQueue_601200; body: JsonNode): Recallable =
  ## createQueue
  ## Create a new transcoding queue. For information about queues, see Working With Queues in the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/working-with-queues.html
  ##   body: JObject (required)
  var body_601213 = newJObject()
  if body != nil:
    body_601213 = body
  result = call_601212.call(nil, nil, nil, nil, body_601213)

var createQueue* = Call_CreateQueue_601200(name: "createQueue",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/queues",
                                        validator: validate_CreateQueue_601201,
                                        base: "/", url: url_CreateQueue_601202,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQueues_601181 = ref object of OpenApiRestCall_600426
proc url_ListQueues_601183(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListQueues_601182(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601184 = query.getOrDefault("order")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_601184 != nil:
    section.add "order", valid_601184
  var valid_601185 = query.getOrDefault("NextToken")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "NextToken", valid_601185
  var valid_601186 = query.getOrDefault("maxResults")
  valid_601186 = validateParameter(valid_601186, JInt, required = false, default = nil)
  if valid_601186 != nil:
    section.add "maxResults", valid_601186
  var valid_601187 = query.getOrDefault("nextToken")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "nextToken", valid_601187
  var valid_601188 = query.getOrDefault("listBy")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = newJString("NAME"))
  if valid_601188 != nil:
    section.add "listBy", valid_601188
  var valid_601189 = query.getOrDefault("MaxResults")
  valid_601189 = validateParameter(valid_601189, JString, required = false,
                                 default = nil)
  if valid_601189 != nil:
    section.add "MaxResults", valid_601189
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
  var valid_601190 = header.getOrDefault("X-Amz-Date")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-Date", valid_601190
  var valid_601191 = header.getOrDefault("X-Amz-Security-Token")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-Security-Token", valid_601191
  var valid_601192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601192 = validateParameter(valid_601192, JString, required = false,
                                 default = nil)
  if valid_601192 != nil:
    section.add "X-Amz-Content-Sha256", valid_601192
  var valid_601193 = header.getOrDefault("X-Amz-Algorithm")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Algorithm", valid_601193
  var valid_601194 = header.getOrDefault("X-Amz-Signature")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Signature", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-SignedHeaders", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-Credential")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-Credential", valid_601196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601197: Call_ListQueues_601181; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a JSON array of up to twenty of your queues. This will return the queues themselves, not just a list of them. To retrieve the next twenty queues, use the nextToken string returned with the array.
  ## 
  let valid = call_601197.validator(path, query, header, formData, body)
  let scheme = call_601197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601197.url(scheme.get, call_601197.host, call_601197.base,
                         call_601197.route, valid.getOrDefault("path"))
  result = hook(call_601197, url, valid)

proc call*(call_601198: Call_ListQueues_601181; order: string = "ASCENDING";
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
  var query_601199 = newJObject()
  add(query_601199, "order", newJString(order))
  add(query_601199, "NextToken", newJString(NextToken))
  add(query_601199, "maxResults", newJInt(maxResults))
  add(query_601199, "nextToken", newJString(nextToken))
  add(query_601199, "listBy", newJString(listBy))
  add(query_601199, "MaxResults", newJString(MaxResults))
  result = call_601198.call(nil, query_601199, nil, nil, nil)

var listQueues* = Call_ListQueues_601181(name: "listQueues",
                                      meth: HttpMethod.HttpGet,
                                      host: "mediaconvert.amazonaws.com",
                                      route: "/2017-08-29/queues",
                                      validator: validate_ListQueues_601182,
                                      base: "/", url: url_ListQueues_601183,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJobTemplate_601228 = ref object of OpenApiRestCall_600426
proc url_UpdateJobTemplate_601230(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/jobTemplates/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateJobTemplate_601229(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Modify one of your existing job templates.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the job template you are modifying
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_601231 = path.getOrDefault("name")
  valid_601231 = validateParameter(valid_601231, JString, required = true,
                                 default = nil)
  if valid_601231 != nil:
    section.add "name", valid_601231
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
  var valid_601232 = header.getOrDefault("X-Amz-Date")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Date", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-Security-Token")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-Security-Token", valid_601233
  var valid_601234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-Content-Sha256", valid_601234
  var valid_601235 = header.getOrDefault("X-Amz-Algorithm")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Algorithm", valid_601235
  var valid_601236 = header.getOrDefault("X-Amz-Signature")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-Signature", valid_601236
  var valid_601237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "X-Amz-SignedHeaders", valid_601237
  var valid_601238 = header.getOrDefault("X-Amz-Credential")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "X-Amz-Credential", valid_601238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601240: Call_UpdateJobTemplate_601228; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modify one of your existing job templates.
  ## 
  let valid = call_601240.validator(path, query, header, formData, body)
  let scheme = call_601240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601240.url(scheme.get, call_601240.host, call_601240.base,
                         call_601240.route, valid.getOrDefault("path"))
  result = hook(call_601240, url, valid)

proc call*(call_601241: Call_UpdateJobTemplate_601228; name: string; body: JsonNode): Recallable =
  ## updateJobTemplate
  ## Modify one of your existing job templates.
  ##   name: string (required)
  ##       : The name of the job template you are modifying
  ##   body: JObject (required)
  var path_601242 = newJObject()
  var body_601243 = newJObject()
  add(path_601242, "name", newJString(name))
  if body != nil:
    body_601243 = body
  result = call_601241.call(path_601242, nil, nil, nil, body_601243)

var updateJobTemplate* = Call_UpdateJobTemplate_601228(name: "updateJobTemplate",
    meth: HttpMethod.HttpPut, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates/{name}",
    validator: validate_UpdateJobTemplate_601229, base: "/",
    url: url_UpdateJobTemplate_601230, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobTemplate_601214 = ref object of OpenApiRestCall_600426
proc url_GetJobTemplate_601216(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/jobTemplates/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetJobTemplate_601215(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieve the JSON for a specific job template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the job template.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_601217 = path.getOrDefault("name")
  valid_601217 = validateParameter(valid_601217, JString, required = true,
                                 default = nil)
  if valid_601217 != nil:
    section.add "name", valid_601217
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
  var valid_601218 = header.getOrDefault("X-Amz-Date")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Date", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-Security-Token")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-Security-Token", valid_601219
  var valid_601220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Content-Sha256", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-Algorithm")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-Algorithm", valid_601221
  var valid_601222 = header.getOrDefault("X-Amz-Signature")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "X-Amz-Signature", valid_601222
  var valid_601223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "X-Amz-SignedHeaders", valid_601223
  var valid_601224 = header.getOrDefault("X-Amz-Credential")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-Credential", valid_601224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601225: Call_GetJobTemplate_601214; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the JSON for a specific job template.
  ## 
  let valid = call_601225.validator(path, query, header, formData, body)
  let scheme = call_601225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601225.url(scheme.get, call_601225.host, call_601225.base,
                         call_601225.route, valid.getOrDefault("path"))
  result = hook(call_601225, url, valid)

proc call*(call_601226: Call_GetJobTemplate_601214; name: string): Recallable =
  ## getJobTemplate
  ## Retrieve the JSON for a specific job template.
  ##   name: string (required)
  ##       : The name of the job template.
  var path_601227 = newJObject()
  add(path_601227, "name", newJString(name))
  result = call_601226.call(path_601227, nil, nil, nil, nil)

var getJobTemplate* = Call_GetJobTemplate_601214(name: "getJobTemplate",
    meth: HttpMethod.HttpGet, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates/{name}", validator: validate_GetJobTemplate_601215,
    base: "/", url: url_GetJobTemplate_601216, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJobTemplate_601244 = ref object of OpenApiRestCall_600426
proc url_DeleteJobTemplate_601246(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/jobTemplates/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteJobTemplate_601245(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Permanently delete a job template you have created.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the job template to be deleted.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_601247 = path.getOrDefault("name")
  valid_601247 = validateParameter(valid_601247, JString, required = true,
                                 default = nil)
  if valid_601247 != nil:
    section.add "name", valid_601247
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
  var valid_601248 = header.getOrDefault("X-Amz-Date")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Date", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-Security-Token")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-Security-Token", valid_601249
  var valid_601250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-Content-Sha256", valid_601250
  var valid_601251 = header.getOrDefault("X-Amz-Algorithm")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-Algorithm", valid_601251
  var valid_601252 = header.getOrDefault("X-Amz-Signature")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "X-Amz-Signature", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-SignedHeaders", valid_601253
  var valid_601254 = header.getOrDefault("X-Amz-Credential")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Credential", valid_601254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601255: Call_DeleteJobTemplate_601244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently delete a job template you have created.
  ## 
  let valid = call_601255.validator(path, query, header, formData, body)
  let scheme = call_601255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601255.url(scheme.get, call_601255.host, call_601255.base,
                         call_601255.route, valid.getOrDefault("path"))
  result = hook(call_601255, url, valid)

proc call*(call_601256: Call_DeleteJobTemplate_601244; name: string): Recallable =
  ## deleteJobTemplate
  ## Permanently delete a job template you have created.
  ##   name: string (required)
  ##       : The name of the job template to be deleted.
  var path_601257 = newJObject()
  add(path_601257, "name", newJString(name))
  result = call_601256.call(path_601257, nil, nil, nil, nil)

var deleteJobTemplate* = Call_DeleteJobTemplate_601244(name: "deleteJobTemplate",
    meth: HttpMethod.HttpDelete, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates/{name}",
    validator: validate_DeleteJobTemplate_601245, base: "/",
    url: url_DeleteJobTemplate_601246, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePreset_601272 = ref object of OpenApiRestCall_600426
proc url_UpdatePreset_601274(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/presets/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdatePreset_601273(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Modify one of your existing presets.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the preset you are modifying.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_601275 = path.getOrDefault("name")
  valid_601275 = validateParameter(valid_601275, JString, required = true,
                                 default = nil)
  if valid_601275 != nil:
    section.add "name", valid_601275
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
  var valid_601276 = header.getOrDefault("X-Amz-Date")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-Date", valid_601276
  var valid_601277 = header.getOrDefault("X-Amz-Security-Token")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "X-Amz-Security-Token", valid_601277
  var valid_601278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "X-Amz-Content-Sha256", valid_601278
  var valid_601279 = header.getOrDefault("X-Amz-Algorithm")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "X-Amz-Algorithm", valid_601279
  var valid_601280 = header.getOrDefault("X-Amz-Signature")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-Signature", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-SignedHeaders", valid_601281
  var valid_601282 = header.getOrDefault("X-Amz-Credential")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "X-Amz-Credential", valid_601282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601284: Call_UpdatePreset_601272; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modify one of your existing presets.
  ## 
  let valid = call_601284.validator(path, query, header, formData, body)
  let scheme = call_601284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601284.url(scheme.get, call_601284.host, call_601284.base,
                         call_601284.route, valid.getOrDefault("path"))
  result = hook(call_601284, url, valid)

proc call*(call_601285: Call_UpdatePreset_601272; name: string; body: JsonNode): Recallable =
  ## updatePreset
  ## Modify one of your existing presets.
  ##   name: string (required)
  ##       : The name of the preset you are modifying.
  ##   body: JObject (required)
  var path_601286 = newJObject()
  var body_601287 = newJObject()
  add(path_601286, "name", newJString(name))
  if body != nil:
    body_601287 = body
  result = call_601285.call(path_601286, nil, nil, nil, body_601287)

var updatePreset* = Call_UpdatePreset_601272(name: "updatePreset",
    meth: HttpMethod.HttpPut, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/presets/{name}", validator: validate_UpdatePreset_601273,
    base: "/", url: url_UpdatePreset_601274, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPreset_601258 = ref object of OpenApiRestCall_600426
proc url_GetPreset_601260(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/presets/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetPreset_601259(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve the JSON for a specific preset.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the preset.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_601261 = path.getOrDefault("name")
  valid_601261 = validateParameter(valid_601261, JString, required = true,
                                 default = nil)
  if valid_601261 != nil:
    section.add "name", valid_601261
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
  var valid_601262 = header.getOrDefault("X-Amz-Date")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Date", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-Security-Token")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-Security-Token", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-Content-Sha256", valid_601264
  var valid_601265 = header.getOrDefault("X-Amz-Algorithm")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Algorithm", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-Signature")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Signature", valid_601266
  var valid_601267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "X-Amz-SignedHeaders", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-Credential")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-Credential", valid_601268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601269: Call_GetPreset_601258; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the JSON for a specific preset.
  ## 
  let valid = call_601269.validator(path, query, header, formData, body)
  let scheme = call_601269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601269.url(scheme.get, call_601269.host, call_601269.base,
                         call_601269.route, valid.getOrDefault("path"))
  result = hook(call_601269, url, valid)

proc call*(call_601270: Call_GetPreset_601258; name: string): Recallable =
  ## getPreset
  ## Retrieve the JSON for a specific preset.
  ##   name: string (required)
  ##       : The name of the preset.
  var path_601271 = newJObject()
  add(path_601271, "name", newJString(name))
  result = call_601270.call(path_601271, nil, nil, nil, nil)

var getPreset* = Call_GetPreset_601258(name: "getPreset", meth: HttpMethod.HttpGet,
                                    host: "mediaconvert.amazonaws.com",
                                    route: "/2017-08-29/presets/{name}",
                                    validator: validate_GetPreset_601259,
                                    base: "/", url: url_GetPreset_601260,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePreset_601288 = ref object of OpenApiRestCall_600426
proc url_DeletePreset_601290(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/presets/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeletePreset_601289(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Permanently delete a preset you have created.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the preset to be deleted.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_601291 = path.getOrDefault("name")
  valid_601291 = validateParameter(valid_601291, JString, required = true,
                                 default = nil)
  if valid_601291 != nil:
    section.add "name", valid_601291
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
  var valid_601292 = header.getOrDefault("X-Amz-Date")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Date", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-Security-Token")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-Security-Token", valid_601293
  var valid_601294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "X-Amz-Content-Sha256", valid_601294
  var valid_601295 = header.getOrDefault("X-Amz-Algorithm")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-Algorithm", valid_601295
  var valid_601296 = header.getOrDefault("X-Amz-Signature")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-Signature", valid_601296
  var valid_601297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "X-Amz-SignedHeaders", valid_601297
  var valid_601298 = header.getOrDefault("X-Amz-Credential")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "X-Amz-Credential", valid_601298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601299: Call_DeletePreset_601288; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently delete a preset you have created.
  ## 
  let valid = call_601299.validator(path, query, header, formData, body)
  let scheme = call_601299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601299.url(scheme.get, call_601299.host, call_601299.base,
                         call_601299.route, valid.getOrDefault("path"))
  result = hook(call_601299, url, valid)

proc call*(call_601300: Call_DeletePreset_601288; name: string): Recallable =
  ## deletePreset
  ## Permanently delete a preset you have created.
  ##   name: string (required)
  ##       : The name of the preset to be deleted.
  var path_601301 = newJObject()
  add(path_601301, "name", newJString(name))
  result = call_601300.call(path_601301, nil, nil, nil, nil)

var deletePreset* = Call_DeletePreset_601288(name: "deletePreset",
    meth: HttpMethod.HttpDelete, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/presets/{name}", validator: validate_DeletePreset_601289,
    base: "/", url: url_DeletePreset_601290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateQueue_601316 = ref object of OpenApiRestCall_600426
proc url_UpdateQueue_601318(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/queues/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateQueue_601317(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Modify one of your existing queues.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the queue that you are modifying.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_601319 = path.getOrDefault("name")
  valid_601319 = validateParameter(valid_601319, JString, required = true,
                                 default = nil)
  if valid_601319 != nil:
    section.add "name", valid_601319
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
  var valid_601320 = header.getOrDefault("X-Amz-Date")
  valid_601320 = validateParameter(valid_601320, JString, required = false,
                                 default = nil)
  if valid_601320 != nil:
    section.add "X-Amz-Date", valid_601320
  var valid_601321 = header.getOrDefault("X-Amz-Security-Token")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "X-Amz-Security-Token", valid_601321
  var valid_601322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601322 = validateParameter(valid_601322, JString, required = false,
                                 default = nil)
  if valid_601322 != nil:
    section.add "X-Amz-Content-Sha256", valid_601322
  var valid_601323 = header.getOrDefault("X-Amz-Algorithm")
  valid_601323 = validateParameter(valid_601323, JString, required = false,
                                 default = nil)
  if valid_601323 != nil:
    section.add "X-Amz-Algorithm", valid_601323
  var valid_601324 = header.getOrDefault("X-Amz-Signature")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "X-Amz-Signature", valid_601324
  var valid_601325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "X-Amz-SignedHeaders", valid_601325
  var valid_601326 = header.getOrDefault("X-Amz-Credential")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-Credential", valid_601326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601328: Call_UpdateQueue_601316; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modify one of your existing queues.
  ## 
  let valid = call_601328.validator(path, query, header, formData, body)
  let scheme = call_601328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601328.url(scheme.get, call_601328.host, call_601328.base,
                         call_601328.route, valid.getOrDefault("path"))
  result = hook(call_601328, url, valid)

proc call*(call_601329: Call_UpdateQueue_601316; name: string; body: JsonNode): Recallable =
  ## updateQueue
  ## Modify one of your existing queues.
  ##   name: string (required)
  ##       : The name of the queue that you are modifying.
  ##   body: JObject (required)
  var path_601330 = newJObject()
  var body_601331 = newJObject()
  add(path_601330, "name", newJString(name))
  if body != nil:
    body_601331 = body
  result = call_601329.call(path_601330, nil, nil, nil, body_601331)

var updateQueue* = Call_UpdateQueue_601316(name: "updateQueue",
                                        meth: HttpMethod.HttpPut,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/queues/{name}",
                                        validator: validate_UpdateQueue_601317,
                                        base: "/", url: url_UpdateQueue_601318,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQueue_601302 = ref object of OpenApiRestCall_600426
proc url_GetQueue_601304(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/queues/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetQueue_601303(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve the JSON for a specific queue.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the queue that you want information about.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_601305 = path.getOrDefault("name")
  valid_601305 = validateParameter(valid_601305, JString, required = true,
                                 default = nil)
  if valid_601305 != nil:
    section.add "name", valid_601305
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
  var valid_601306 = header.getOrDefault("X-Amz-Date")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Date", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-Security-Token")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-Security-Token", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-Content-Sha256", valid_601308
  var valid_601309 = header.getOrDefault("X-Amz-Algorithm")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-Algorithm", valid_601309
  var valid_601310 = header.getOrDefault("X-Amz-Signature")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-Signature", valid_601310
  var valid_601311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "X-Amz-SignedHeaders", valid_601311
  var valid_601312 = header.getOrDefault("X-Amz-Credential")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "X-Amz-Credential", valid_601312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601313: Call_GetQueue_601302; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the JSON for a specific queue.
  ## 
  let valid = call_601313.validator(path, query, header, formData, body)
  let scheme = call_601313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601313.url(scheme.get, call_601313.host, call_601313.base,
                         call_601313.route, valid.getOrDefault("path"))
  result = hook(call_601313, url, valid)

proc call*(call_601314: Call_GetQueue_601302; name: string): Recallable =
  ## getQueue
  ## Retrieve the JSON for a specific queue.
  ##   name: string (required)
  ##       : The name of the queue that you want information about.
  var path_601315 = newJObject()
  add(path_601315, "name", newJString(name))
  result = call_601314.call(path_601315, nil, nil, nil, nil)

var getQueue* = Call_GetQueue_601302(name: "getQueue", meth: HttpMethod.HttpGet,
                                  host: "mediaconvert.amazonaws.com",
                                  route: "/2017-08-29/queues/{name}",
                                  validator: validate_GetQueue_601303, base: "/",
                                  url: url_GetQueue_601304,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteQueue_601332 = ref object of OpenApiRestCall_600426
proc url_DeleteQueue_601334(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/queues/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteQueue_601333(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Permanently delete a queue you have created.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the queue that you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_601335 = path.getOrDefault("name")
  valid_601335 = validateParameter(valid_601335, JString, required = true,
                                 default = nil)
  if valid_601335 != nil:
    section.add "name", valid_601335
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
  var valid_601336 = header.getOrDefault("X-Amz-Date")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "X-Amz-Date", valid_601336
  var valid_601337 = header.getOrDefault("X-Amz-Security-Token")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "X-Amz-Security-Token", valid_601337
  var valid_601338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "X-Amz-Content-Sha256", valid_601338
  var valid_601339 = header.getOrDefault("X-Amz-Algorithm")
  valid_601339 = validateParameter(valid_601339, JString, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "X-Amz-Algorithm", valid_601339
  var valid_601340 = header.getOrDefault("X-Amz-Signature")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "X-Amz-Signature", valid_601340
  var valid_601341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-SignedHeaders", valid_601341
  var valid_601342 = header.getOrDefault("X-Amz-Credential")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "X-Amz-Credential", valid_601342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601343: Call_DeleteQueue_601332; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently delete a queue you have created.
  ## 
  let valid = call_601343.validator(path, query, header, formData, body)
  let scheme = call_601343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601343.url(scheme.get, call_601343.host, call_601343.base,
                         call_601343.route, valid.getOrDefault("path"))
  result = hook(call_601343, url, valid)

proc call*(call_601344: Call_DeleteQueue_601332; name: string): Recallable =
  ## deleteQueue
  ## Permanently delete a queue you have created.
  ##   name: string (required)
  ##       : The name of the queue that you want to delete.
  var path_601345 = newJObject()
  add(path_601345, "name", newJString(name))
  result = call_601344.call(path_601345, nil, nil, nil, nil)

var deleteQueue* = Call_DeleteQueue_601332(name: "deleteQueue",
                                        meth: HttpMethod.HttpDelete,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/queues/{name}",
                                        validator: validate_DeleteQueue_601333,
                                        base: "/", url: url_DeleteQueue_601334,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoints_601346 = ref object of OpenApiRestCall_600426
proc url_DescribeEndpoints_601348(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEndpoints_601347(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_601349 = query.getOrDefault("NextToken")
  valid_601349 = validateParameter(valid_601349, JString, required = false,
                                 default = nil)
  if valid_601349 != nil:
    section.add "NextToken", valid_601349
  var valid_601350 = query.getOrDefault("MaxResults")
  valid_601350 = validateParameter(valid_601350, JString, required = false,
                                 default = nil)
  if valid_601350 != nil:
    section.add "MaxResults", valid_601350
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
  var valid_601351 = header.getOrDefault("X-Amz-Date")
  valid_601351 = validateParameter(valid_601351, JString, required = false,
                                 default = nil)
  if valid_601351 != nil:
    section.add "X-Amz-Date", valid_601351
  var valid_601352 = header.getOrDefault("X-Amz-Security-Token")
  valid_601352 = validateParameter(valid_601352, JString, required = false,
                                 default = nil)
  if valid_601352 != nil:
    section.add "X-Amz-Security-Token", valid_601352
  var valid_601353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601353 = validateParameter(valid_601353, JString, required = false,
                                 default = nil)
  if valid_601353 != nil:
    section.add "X-Amz-Content-Sha256", valid_601353
  var valid_601354 = header.getOrDefault("X-Amz-Algorithm")
  valid_601354 = validateParameter(valid_601354, JString, required = false,
                                 default = nil)
  if valid_601354 != nil:
    section.add "X-Amz-Algorithm", valid_601354
  var valid_601355 = header.getOrDefault("X-Amz-Signature")
  valid_601355 = validateParameter(valid_601355, JString, required = false,
                                 default = nil)
  if valid_601355 != nil:
    section.add "X-Amz-Signature", valid_601355
  var valid_601356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "X-Amz-SignedHeaders", valid_601356
  var valid_601357 = header.getOrDefault("X-Amz-Credential")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "X-Amz-Credential", valid_601357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601359: Call_DescribeEndpoints_601346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Send an request with an empty body to the regional API endpoint to get your account API endpoint.
  ## 
  let valid = call_601359.validator(path, query, header, formData, body)
  let scheme = call_601359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601359.url(scheme.get, call_601359.host, call_601359.base,
                         call_601359.route, valid.getOrDefault("path"))
  result = hook(call_601359, url, valid)

proc call*(call_601360: Call_DescribeEndpoints_601346; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeEndpoints
  ## Send an request with an empty body to the regional API endpoint to get your account API endpoint.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601361 = newJObject()
  var body_601362 = newJObject()
  add(query_601361, "NextToken", newJString(NextToken))
  if body != nil:
    body_601362 = body
  add(query_601361, "MaxResults", newJString(MaxResults))
  result = call_601360.call(nil, query_601361, nil, nil, body_601362)

var describeEndpoints* = Call_DescribeEndpoints_601346(name: "describeEndpoints",
    meth: HttpMethod.HttpPost, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/endpoints", validator: validate_DescribeEndpoints_601347,
    base: "/", url: url_DescribeEndpoints_601348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateCertificate_601363 = ref object of OpenApiRestCall_600426
proc url_DisassociateCertificate_601365(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "arn" in path, "`arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/certificates/"),
               (kind: VariableSegment, value: "arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DisassociateCertificate_601364(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes an association between the Amazon Resource Name (ARN) of an AWS Certificate Manager (ACM) certificate and an AWS Elemental MediaConvert resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   arn: JString (required)
  ##      : The ARN of the ACM certificate that you want to disassociate from your MediaConvert resource.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `arn` field"
  var valid_601366 = path.getOrDefault("arn")
  valid_601366 = validateParameter(valid_601366, JString, required = true,
                                 default = nil)
  if valid_601366 != nil:
    section.add "arn", valid_601366
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
  var valid_601367 = header.getOrDefault("X-Amz-Date")
  valid_601367 = validateParameter(valid_601367, JString, required = false,
                                 default = nil)
  if valid_601367 != nil:
    section.add "X-Amz-Date", valid_601367
  var valid_601368 = header.getOrDefault("X-Amz-Security-Token")
  valid_601368 = validateParameter(valid_601368, JString, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "X-Amz-Security-Token", valid_601368
  var valid_601369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601369 = validateParameter(valid_601369, JString, required = false,
                                 default = nil)
  if valid_601369 != nil:
    section.add "X-Amz-Content-Sha256", valid_601369
  var valid_601370 = header.getOrDefault("X-Amz-Algorithm")
  valid_601370 = validateParameter(valid_601370, JString, required = false,
                                 default = nil)
  if valid_601370 != nil:
    section.add "X-Amz-Algorithm", valid_601370
  var valid_601371 = header.getOrDefault("X-Amz-Signature")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "X-Amz-Signature", valid_601371
  var valid_601372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601372 = validateParameter(valid_601372, JString, required = false,
                                 default = nil)
  if valid_601372 != nil:
    section.add "X-Amz-SignedHeaders", valid_601372
  var valid_601373 = header.getOrDefault("X-Amz-Credential")
  valid_601373 = validateParameter(valid_601373, JString, required = false,
                                 default = nil)
  if valid_601373 != nil:
    section.add "X-Amz-Credential", valid_601373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601374: Call_DisassociateCertificate_601363; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an association between the Amazon Resource Name (ARN) of an AWS Certificate Manager (ACM) certificate and an AWS Elemental MediaConvert resource.
  ## 
  let valid = call_601374.validator(path, query, header, formData, body)
  let scheme = call_601374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601374.url(scheme.get, call_601374.host, call_601374.base,
                         call_601374.route, valid.getOrDefault("path"))
  result = hook(call_601374, url, valid)

proc call*(call_601375: Call_DisassociateCertificate_601363; arn: string): Recallable =
  ## disassociateCertificate
  ## Removes an association between the Amazon Resource Name (ARN) of an AWS Certificate Manager (ACM) certificate and an AWS Elemental MediaConvert resource.
  ##   arn: string (required)
  ##      : The ARN of the ACM certificate that you want to disassociate from your MediaConvert resource.
  var path_601376 = newJObject()
  add(path_601376, "arn", newJString(arn))
  result = call_601375.call(path_601376, nil, nil, nil, nil)

var disassociateCertificate* = Call_DisassociateCertificate_601363(
    name: "disassociateCertificate", meth: HttpMethod.HttpDelete,
    host: "mediaconvert.amazonaws.com", route: "/2017-08-29/certificates/{arn}",
    validator: validate_DisassociateCertificate_601364, base: "/",
    url: url_DisassociateCertificate_601365, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601391 = ref object of OpenApiRestCall_600426
proc url_UntagResource_601393(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "arn" in path, "`arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/tags/"),
               (kind: VariableSegment, value: "arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UntagResource_601392(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove tags from a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   arn: JString (required)
  ##      : The Amazon Resource Name (ARN) of the resource that you want to remove tags from. To get the ARN, send a GET request with the resource name.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `arn` field"
  var valid_601394 = path.getOrDefault("arn")
  valid_601394 = validateParameter(valid_601394, JString, required = true,
                                 default = nil)
  if valid_601394 != nil:
    section.add "arn", valid_601394
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
  var valid_601395 = header.getOrDefault("X-Amz-Date")
  valid_601395 = validateParameter(valid_601395, JString, required = false,
                                 default = nil)
  if valid_601395 != nil:
    section.add "X-Amz-Date", valid_601395
  var valid_601396 = header.getOrDefault("X-Amz-Security-Token")
  valid_601396 = validateParameter(valid_601396, JString, required = false,
                                 default = nil)
  if valid_601396 != nil:
    section.add "X-Amz-Security-Token", valid_601396
  var valid_601397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601397 = validateParameter(valid_601397, JString, required = false,
                                 default = nil)
  if valid_601397 != nil:
    section.add "X-Amz-Content-Sha256", valid_601397
  var valid_601398 = header.getOrDefault("X-Amz-Algorithm")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "X-Amz-Algorithm", valid_601398
  var valid_601399 = header.getOrDefault("X-Amz-Signature")
  valid_601399 = validateParameter(valid_601399, JString, required = false,
                                 default = nil)
  if valid_601399 != nil:
    section.add "X-Amz-Signature", valid_601399
  var valid_601400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601400 = validateParameter(valid_601400, JString, required = false,
                                 default = nil)
  if valid_601400 != nil:
    section.add "X-Amz-SignedHeaders", valid_601400
  var valid_601401 = header.getOrDefault("X-Amz-Credential")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "X-Amz-Credential", valid_601401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601403: Call_UntagResource_601391; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ## 
  let valid = call_601403.validator(path, query, header, formData, body)
  let scheme = call_601403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601403.url(scheme.get, call_601403.host, call_601403.base,
                         call_601403.route, valid.getOrDefault("path"))
  result = hook(call_601403, url, valid)

proc call*(call_601404: Call_UntagResource_601391; arn: string; body: JsonNode): Recallable =
  ## untagResource
  ## Remove tags from a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ##   arn: string (required)
  ##      : The Amazon Resource Name (ARN) of the resource that you want to remove tags from. To get the ARN, send a GET request with the resource name.
  ##   body: JObject (required)
  var path_601405 = newJObject()
  var body_601406 = newJObject()
  add(path_601405, "arn", newJString(arn))
  if body != nil:
    body_601406 = body
  result = call_601404.call(path_601405, nil, nil, nil, body_601406)

var untagResource* = Call_UntagResource_601391(name: "untagResource",
    meth: HttpMethod.HttpPut, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/tags/{arn}", validator: validate_UntagResource_601392,
    base: "/", url: url_UntagResource_601393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_601377 = ref object of OpenApiRestCall_600426
proc url_ListTagsForResource_601379(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "arn" in path, "`arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-08-29/tags/"),
               (kind: VariableSegment, value: "arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListTagsForResource_601378(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieve the tags for a MediaConvert resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   arn: JString (required)
  ##      : The Amazon Resource Name (ARN) of the resource that you want to list tags for. To get the ARN, send a GET request with the resource name.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `arn` field"
  var valid_601380 = path.getOrDefault("arn")
  valid_601380 = validateParameter(valid_601380, JString, required = true,
                                 default = nil)
  if valid_601380 != nil:
    section.add "arn", valid_601380
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
  var valid_601381 = header.getOrDefault("X-Amz-Date")
  valid_601381 = validateParameter(valid_601381, JString, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "X-Amz-Date", valid_601381
  var valid_601382 = header.getOrDefault("X-Amz-Security-Token")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-Security-Token", valid_601382
  var valid_601383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "X-Amz-Content-Sha256", valid_601383
  var valid_601384 = header.getOrDefault("X-Amz-Algorithm")
  valid_601384 = validateParameter(valid_601384, JString, required = false,
                                 default = nil)
  if valid_601384 != nil:
    section.add "X-Amz-Algorithm", valid_601384
  var valid_601385 = header.getOrDefault("X-Amz-Signature")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-Signature", valid_601385
  var valid_601386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601386 = validateParameter(valid_601386, JString, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "X-Amz-SignedHeaders", valid_601386
  var valid_601387 = header.getOrDefault("X-Amz-Credential")
  valid_601387 = validateParameter(valid_601387, JString, required = false,
                                 default = nil)
  if valid_601387 != nil:
    section.add "X-Amz-Credential", valid_601387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601388: Call_ListTagsForResource_601377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the tags for a MediaConvert resource.
  ## 
  let valid = call_601388.validator(path, query, header, formData, body)
  let scheme = call_601388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601388.url(scheme.get, call_601388.host, call_601388.base,
                         call_601388.route, valid.getOrDefault("path"))
  result = hook(call_601388, url, valid)

proc call*(call_601389: Call_ListTagsForResource_601377; arn: string): Recallable =
  ## listTagsForResource
  ## Retrieve the tags for a MediaConvert resource.
  ##   arn: string (required)
  ##      : The Amazon Resource Name (ARN) of the resource that you want to list tags for. To get the ARN, send a GET request with the resource name.
  var path_601390 = newJObject()
  add(path_601390, "arn", newJString(arn))
  result = call_601389.call(path_601390, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_601377(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "mediaconvert.amazonaws.com", route: "/2017-08-29/tags/{arn}",
    validator: validate_ListTagsForResource_601378, base: "/",
    url: url_ListTagsForResource_601379, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601407 = ref object of OpenApiRestCall_600426
proc url_TagResource_601409(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_601408(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601410 = header.getOrDefault("X-Amz-Date")
  valid_601410 = validateParameter(valid_601410, JString, required = false,
                                 default = nil)
  if valid_601410 != nil:
    section.add "X-Amz-Date", valid_601410
  var valid_601411 = header.getOrDefault("X-Amz-Security-Token")
  valid_601411 = validateParameter(valid_601411, JString, required = false,
                                 default = nil)
  if valid_601411 != nil:
    section.add "X-Amz-Security-Token", valid_601411
  var valid_601412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601412 = validateParameter(valid_601412, JString, required = false,
                                 default = nil)
  if valid_601412 != nil:
    section.add "X-Amz-Content-Sha256", valid_601412
  var valid_601413 = header.getOrDefault("X-Amz-Algorithm")
  valid_601413 = validateParameter(valid_601413, JString, required = false,
                                 default = nil)
  if valid_601413 != nil:
    section.add "X-Amz-Algorithm", valid_601413
  var valid_601414 = header.getOrDefault("X-Amz-Signature")
  valid_601414 = validateParameter(valid_601414, JString, required = false,
                                 default = nil)
  if valid_601414 != nil:
    section.add "X-Amz-Signature", valid_601414
  var valid_601415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601415 = validateParameter(valid_601415, JString, required = false,
                                 default = nil)
  if valid_601415 != nil:
    section.add "X-Amz-SignedHeaders", valid_601415
  var valid_601416 = header.getOrDefault("X-Amz-Credential")
  valid_601416 = validateParameter(valid_601416, JString, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "X-Amz-Credential", valid_601416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601418: Call_TagResource_601407; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add tags to a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ## 
  let valid = call_601418.validator(path, query, header, formData, body)
  let scheme = call_601418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601418.url(scheme.get, call_601418.host, call_601418.base,
                         call_601418.route, valid.getOrDefault("path"))
  result = hook(call_601418, url, valid)

proc call*(call_601419: Call_TagResource_601407; body: JsonNode): Recallable =
  ## tagResource
  ## Add tags to a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ##   body: JObject (required)
  var body_601420 = newJObject()
  if body != nil:
    body_601420 = body
  result = call_601419.call(nil, nil, nil, nil, body_601420)

var tagResource* = Call_TagResource_601407(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/tags",
                                        validator: validate_TagResource_601408,
                                        base: "/", url: url_TagResource_601409,
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
