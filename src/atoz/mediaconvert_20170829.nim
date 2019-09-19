
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
  Call_AssociateCertificate_772933 = ref object of OpenApiRestCall_772597
proc url_AssociateCertificate_772935(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AssociateCertificate_772934(path: JsonNode; query: JsonNode;
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

proc call*(call_773077: Call_AssociateCertificate_772933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates an AWS Certificate Manager (ACM) Amazon Resource Name (ARN) with AWS Elemental MediaConvert.
  ## 
  let valid = call_773077.validator(path, query, header, formData, body)
  let scheme = call_773077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773077.url(scheme.get, call_773077.host, call_773077.base,
                         call_773077.route, valid.getOrDefault("path"))
  result = hook(call_773077, url, valid)

proc call*(call_773148: Call_AssociateCertificate_772933; body: JsonNode): Recallable =
  ## associateCertificate
  ## Associates an AWS Certificate Manager (ACM) Amazon Resource Name (ARN) with AWS Elemental MediaConvert.
  ##   body: JObject (required)
  var body_773149 = newJObject()
  if body != nil:
    body_773149 = body
  result = call_773148.call(nil, nil, nil, nil, body_773149)

var associateCertificate* = Call_AssociateCertificate_772933(
    name: "associateCertificate", meth: HttpMethod.HttpPost,
    host: "mediaconvert.amazonaws.com", route: "/2017-08-29/certificates",
    validator: validate_AssociateCertificate_772934, base: "/",
    url: url_AssociateCertificate_772935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_773188 = ref object of OpenApiRestCall_772597
proc url_GetJob_773190(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetJob_773189(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773205 = path.getOrDefault("id")
  valid_773205 = validateParameter(valid_773205, JString, required = true,
                                 default = nil)
  if valid_773205 != nil:
    section.add "id", valid_773205
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
  var valid_773206 = header.getOrDefault("X-Amz-Date")
  valid_773206 = validateParameter(valid_773206, JString, required = false,
                                 default = nil)
  if valid_773206 != nil:
    section.add "X-Amz-Date", valid_773206
  var valid_773207 = header.getOrDefault("X-Amz-Security-Token")
  valid_773207 = validateParameter(valid_773207, JString, required = false,
                                 default = nil)
  if valid_773207 != nil:
    section.add "X-Amz-Security-Token", valid_773207
  var valid_773208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "X-Amz-Content-Sha256", valid_773208
  var valid_773209 = header.getOrDefault("X-Amz-Algorithm")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Algorithm", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-Signature")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Signature", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-SignedHeaders", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Credential")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Credential", valid_773212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773213: Call_GetJob_773188; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the JSON for a specific completed transcoding job.
  ## 
  let valid = call_773213.validator(path, query, header, formData, body)
  let scheme = call_773213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773213.url(scheme.get, call_773213.host, call_773213.base,
                         call_773213.route, valid.getOrDefault("path"))
  result = hook(call_773213, url, valid)

proc call*(call_773214: Call_GetJob_773188; id: string): Recallable =
  ## getJob
  ## Retrieve the JSON for a specific completed transcoding job.
  ##   id: string (required)
  ##     : the job ID of the job.
  var path_773215 = newJObject()
  add(path_773215, "id", newJString(id))
  result = call_773214.call(path_773215, nil, nil, nil, nil)

var getJob* = Call_GetJob_773188(name: "getJob", meth: HttpMethod.HttpGet,
                              host: "mediaconvert.amazonaws.com",
                              route: "/2017-08-29/jobs/{id}",
                              validator: validate_GetJob_773189, base: "/",
                              url: url_GetJob_773190,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelJob_773217 = ref object of OpenApiRestCall_772597
proc url_CancelJob_773219(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CancelJob_773218(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773220 = path.getOrDefault("id")
  valid_773220 = validateParameter(valid_773220, JString, required = true,
                                 default = nil)
  if valid_773220 != nil:
    section.add "id", valid_773220
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

proc call*(call_773228: Call_CancelJob_773217; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently cancel a job. Once you have canceled a job, you can't start it again.
  ## 
  let valid = call_773228.validator(path, query, header, formData, body)
  let scheme = call_773228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773228.url(scheme.get, call_773228.host, call_773228.base,
                         call_773228.route, valid.getOrDefault("path"))
  result = hook(call_773228, url, valid)

proc call*(call_773229: Call_CancelJob_773217; id: string): Recallable =
  ## cancelJob
  ## Permanently cancel a job. Once you have canceled a job, you can't start it again.
  ##   id: string (required)
  ##     : The Job ID of the job to be cancelled.
  var path_773230 = newJObject()
  add(path_773230, "id", newJString(id))
  result = call_773229.call(path_773230, nil, nil, nil, nil)

var cancelJob* = Call_CancelJob_773217(name: "cancelJob",
                                    meth: HttpMethod.HttpDelete,
                                    host: "mediaconvert.amazonaws.com",
                                    route: "/2017-08-29/jobs/{id}",
                                    validator: validate_CancelJob_773218,
                                    base: "/", url: url_CancelJob_773219,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_773264 = ref object of OpenApiRestCall_772597
proc url_CreateJob_773266(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateJob_773265(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773267 = header.getOrDefault("X-Amz-Date")
  valid_773267 = validateParameter(valid_773267, JString, required = false,
                                 default = nil)
  if valid_773267 != nil:
    section.add "X-Amz-Date", valid_773267
  var valid_773268 = header.getOrDefault("X-Amz-Security-Token")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Security-Token", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Content-Sha256", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-Algorithm")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-Algorithm", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-Signature")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-Signature", valid_773271
  var valid_773272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "X-Amz-SignedHeaders", valid_773272
  var valid_773273 = header.getOrDefault("X-Amz-Credential")
  valid_773273 = validateParameter(valid_773273, JString, required = false,
                                 default = nil)
  if valid_773273 != nil:
    section.add "X-Amz-Credential", valid_773273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773275: Call_CreateJob_773264; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new transcoding job. For information about jobs and job settings, see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ## 
  let valid = call_773275.validator(path, query, header, formData, body)
  let scheme = call_773275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773275.url(scheme.get, call_773275.host, call_773275.base,
                         call_773275.route, valid.getOrDefault("path"))
  result = hook(call_773275, url, valid)

proc call*(call_773276: Call_CreateJob_773264; body: JsonNode): Recallable =
  ## createJob
  ## Create a new transcoding job. For information about jobs and job settings, see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ##   body: JObject (required)
  var body_773277 = newJObject()
  if body != nil:
    body_773277 = body
  result = call_773276.call(nil, nil, nil, nil, body_773277)

var createJob* = Call_CreateJob_773264(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "mediaconvert.amazonaws.com",
                                    route: "/2017-08-29/jobs",
                                    validator: validate_CreateJob_773265,
                                    base: "/", url: url_CreateJob_773266,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_773231 = ref object of OpenApiRestCall_772597
proc url_ListJobs_773233(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListJobs_773232(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773247 = query.getOrDefault("order")
  valid_773247 = validateParameter(valid_773247, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_773247 != nil:
    section.add "order", valid_773247
  var valid_773248 = query.getOrDefault("NextToken")
  valid_773248 = validateParameter(valid_773248, JString, required = false,
                                 default = nil)
  if valid_773248 != nil:
    section.add "NextToken", valid_773248
  var valid_773249 = query.getOrDefault("maxResults")
  valid_773249 = validateParameter(valid_773249, JInt, required = false, default = nil)
  if valid_773249 != nil:
    section.add "maxResults", valid_773249
  var valid_773250 = query.getOrDefault("nextToken")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "nextToken", valid_773250
  var valid_773251 = query.getOrDefault("status")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = newJString("SUBMITTED"))
  if valid_773251 != nil:
    section.add "status", valid_773251
  var valid_773252 = query.getOrDefault("queue")
  valid_773252 = validateParameter(valid_773252, JString, required = false,
                                 default = nil)
  if valid_773252 != nil:
    section.add "queue", valid_773252
  var valid_773253 = query.getOrDefault("MaxResults")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "MaxResults", valid_773253
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
  var valid_773254 = header.getOrDefault("X-Amz-Date")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Date", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-Security-Token")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-Security-Token", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-Content-Sha256", valid_773256
  var valid_773257 = header.getOrDefault("X-Amz-Algorithm")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "X-Amz-Algorithm", valid_773257
  var valid_773258 = header.getOrDefault("X-Amz-Signature")
  valid_773258 = validateParameter(valid_773258, JString, required = false,
                                 default = nil)
  if valid_773258 != nil:
    section.add "X-Amz-Signature", valid_773258
  var valid_773259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773259 = validateParameter(valid_773259, JString, required = false,
                                 default = nil)
  if valid_773259 != nil:
    section.add "X-Amz-SignedHeaders", valid_773259
  var valid_773260 = header.getOrDefault("X-Amz-Credential")
  valid_773260 = validateParameter(valid_773260, JString, required = false,
                                 default = nil)
  if valid_773260 != nil:
    section.add "X-Amz-Credential", valid_773260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773261: Call_ListJobs_773231; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a JSON array of up to twenty of your most recently created jobs. This array includes in-process, completed, and errored jobs. This will return the jobs themselves, not just a list of the jobs. To retrieve the twenty next most recent jobs, use the nextToken string returned with the array.
  ## 
  let valid = call_773261.validator(path, query, header, formData, body)
  let scheme = call_773261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773261.url(scheme.get, call_773261.host, call_773261.base,
                         call_773261.route, valid.getOrDefault("path"))
  result = hook(call_773261, url, valid)

proc call*(call_773262: Call_ListJobs_773231; order: string = "ASCENDING";
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
  var query_773263 = newJObject()
  add(query_773263, "order", newJString(order))
  add(query_773263, "NextToken", newJString(NextToken))
  add(query_773263, "maxResults", newJInt(maxResults))
  add(query_773263, "nextToken", newJString(nextToken))
  add(query_773263, "status", newJString(status))
  add(query_773263, "queue", newJString(queue))
  add(query_773263, "MaxResults", newJString(MaxResults))
  result = call_773262.call(nil, query_773263, nil, nil, nil)

var listJobs* = Call_ListJobs_773231(name: "listJobs", meth: HttpMethod.HttpGet,
                                  host: "mediaconvert.amazonaws.com",
                                  route: "/2017-08-29/jobs",
                                  validator: validate_ListJobs_773232, base: "/",
                                  url: url_ListJobs_773233,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJobTemplate_773298 = ref object of OpenApiRestCall_772597
proc url_CreateJobTemplate_773300(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateJobTemplate_773299(path: JsonNode; query: JsonNode;
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
  var valid_773301 = header.getOrDefault("X-Amz-Date")
  valid_773301 = validateParameter(valid_773301, JString, required = false,
                                 default = nil)
  if valid_773301 != nil:
    section.add "X-Amz-Date", valid_773301
  var valid_773302 = header.getOrDefault("X-Amz-Security-Token")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "X-Amz-Security-Token", valid_773302
  var valid_773303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773303 = validateParameter(valid_773303, JString, required = false,
                                 default = nil)
  if valid_773303 != nil:
    section.add "X-Amz-Content-Sha256", valid_773303
  var valid_773304 = header.getOrDefault("X-Amz-Algorithm")
  valid_773304 = validateParameter(valid_773304, JString, required = false,
                                 default = nil)
  if valid_773304 != nil:
    section.add "X-Amz-Algorithm", valid_773304
  var valid_773305 = header.getOrDefault("X-Amz-Signature")
  valid_773305 = validateParameter(valid_773305, JString, required = false,
                                 default = nil)
  if valid_773305 != nil:
    section.add "X-Amz-Signature", valid_773305
  var valid_773306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773306 = validateParameter(valid_773306, JString, required = false,
                                 default = nil)
  if valid_773306 != nil:
    section.add "X-Amz-SignedHeaders", valid_773306
  var valid_773307 = header.getOrDefault("X-Amz-Credential")
  valid_773307 = validateParameter(valid_773307, JString, required = false,
                                 default = nil)
  if valid_773307 != nil:
    section.add "X-Amz-Credential", valid_773307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773309: Call_CreateJobTemplate_773298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new job template. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ## 
  let valid = call_773309.validator(path, query, header, formData, body)
  let scheme = call_773309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773309.url(scheme.get, call_773309.host, call_773309.base,
                         call_773309.route, valid.getOrDefault("path"))
  result = hook(call_773309, url, valid)

proc call*(call_773310: Call_CreateJobTemplate_773298; body: JsonNode): Recallable =
  ## createJobTemplate
  ## Create a new job template. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ##   body: JObject (required)
  var body_773311 = newJObject()
  if body != nil:
    body_773311 = body
  result = call_773310.call(nil, nil, nil, nil, body_773311)

var createJobTemplate* = Call_CreateJobTemplate_773298(name: "createJobTemplate",
    meth: HttpMethod.HttpPost, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates", validator: validate_CreateJobTemplate_773299,
    base: "/", url: url_CreateJobTemplate_773300,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobTemplates_773278 = ref object of OpenApiRestCall_772597
proc url_ListJobTemplates_773280(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListJobTemplates_773279(path: JsonNode; query: JsonNode;
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
  var valid_773281 = query.getOrDefault("order")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_773281 != nil:
    section.add "order", valid_773281
  var valid_773282 = query.getOrDefault("NextToken")
  valid_773282 = validateParameter(valid_773282, JString, required = false,
                                 default = nil)
  if valid_773282 != nil:
    section.add "NextToken", valid_773282
  var valid_773283 = query.getOrDefault("maxResults")
  valid_773283 = validateParameter(valid_773283, JInt, required = false, default = nil)
  if valid_773283 != nil:
    section.add "maxResults", valid_773283
  var valid_773284 = query.getOrDefault("nextToken")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "nextToken", valid_773284
  var valid_773285 = query.getOrDefault("listBy")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = newJString("NAME"))
  if valid_773285 != nil:
    section.add "listBy", valid_773285
  var valid_773286 = query.getOrDefault("category")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "category", valid_773286
  var valid_773287 = query.getOrDefault("MaxResults")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "MaxResults", valid_773287
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
  var valid_773288 = header.getOrDefault("X-Amz-Date")
  valid_773288 = validateParameter(valid_773288, JString, required = false,
                                 default = nil)
  if valid_773288 != nil:
    section.add "X-Amz-Date", valid_773288
  var valid_773289 = header.getOrDefault("X-Amz-Security-Token")
  valid_773289 = validateParameter(valid_773289, JString, required = false,
                                 default = nil)
  if valid_773289 != nil:
    section.add "X-Amz-Security-Token", valid_773289
  var valid_773290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773290 = validateParameter(valid_773290, JString, required = false,
                                 default = nil)
  if valid_773290 != nil:
    section.add "X-Amz-Content-Sha256", valid_773290
  var valid_773291 = header.getOrDefault("X-Amz-Algorithm")
  valid_773291 = validateParameter(valid_773291, JString, required = false,
                                 default = nil)
  if valid_773291 != nil:
    section.add "X-Amz-Algorithm", valid_773291
  var valid_773292 = header.getOrDefault("X-Amz-Signature")
  valid_773292 = validateParameter(valid_773292, JString, required = false,
                                 default = nil)
  if valid_773292 != nil:
    section.add "X-Amz-Signature", valid_773292
  var valid_773293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773293 = validateParameter(valid_773293, JString, required = false,
                                 default = nil)
  if valid_773293 != nil:
    section.add "X-Amz-SignedHeaders", valid_773293
  var valid_773294 = header.getOrDefault("X-Amz-Credential")
  valid_773294 = validateParameter(valid_773294, JString, required = false,
                                 default = nil)
  if valid_773294 != nil:
    section.add "X-Amz-Credential", valid_773294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773295: Call_ListJobTemplates_773278; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a JSON array of up to twenty of your job templates. This will return the templates themselves, not just a list of them. To retrieve the next twenty templates, use the nextToken string returned with the array
  ## 
  let valid = call_773295.validator(path, query, header, formData, body)
  let scheme = call_773295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773295.url(scheme.get, call_773295.host, call_773295.base,
                         call_773295.route, valid.getOrDefault("path"))
  result = hook(call_773295, url, valid)

proc call*(call_773296: Call_ListJobTemplates_773278; order: string = "ASCENDING";
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
  var query_773297 = newJObject()
  add(query_773297, "order", newJString(order))
  add(query_773297, "NextToken", newJString(NextToken))
  add(query_773297, "maxResults", newJInt(maxResults))
  add(query_773297, "nextToken", newJString(nextToken))
  add(query_773297, "listBy", newJString(listBy))
  add(query_773297, "category", newJString(category))
  add(query_773297, "MaxResults", newJString(MaxResults))
  result = call_773296.call(nil, query_773297, nil, nil, nil)

var listJobTemplates* = Call_ListJobTemplates_773278(name: "listJobTemplates",
    meth: HttpMethod.HttpGet, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates", validator: validate_ListJobTemplates_773279,
    base: "/", url: url_ListJobTemplates_773280,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePreset_773332 = ref object of OpenApiRestCall_772597
proc url_CreatePreset_773334(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreatePreset_773333(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773335 = header.getOrDefault("X-Amz-Date")
  valid_773335 = validateParameter(valid_773335, JString, required = false,
                                 default = nil)
  if valid_773335 != nil:
    section.add "X-Amz-Date", valid_773335
  var valid_773336 = header.getOrDefault("X-Amz-Security-Token")
  valid_773336 = validateParameter(valid_773336, JString, required = false,
                                 default = nil)
  if valid_773336 != nil:
    section.add "X-Amz-Security-Token", valid_773336
  var valid_773337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773337 = validateParameter(valid_773337, JString, required = false,
                                 default = nil)
  if valid_773337 != nil:
    section.add "X-Amz-Content-Sha256", valid_773337
  var valid_773338 = header.getOrDefault("X-Amz-Algorithm")
  valid_773338 = validateParameter(valid_773338, JString, required = false,
                                 default = nil)
  if valid_773338 != nil:
    section.add "X-Amz-Algorithm", valid_773338
  var valid_773339 = header.getOrDefault("X-Amz-Signature")
  valid_773339 = validateParameter(valid_773339, JString, required = false,
                                 default = nil)
  if valid_773339 != nil:
    section.add "X-Amz-Signature", valid_773339
  var valid_773340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773340 = validateParameter(valid_773340, JString, required = false,
                                 default = nil)
  if valid_773340 != nil:
    section.add "X-Amz-SignedHeaders", valid_773340
  var valid_773341 = header.getOrDefault("X-Amz-Credential")
  valid_773341 = validateParameter(valid_773341, JString, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "X-Amz-Credential", valid_773341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773343: Call_CreatePreset_773332; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new preset. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ## 
  let valid = call_773343.validator(path, query, header, formData, body)
  let scheme = call_773343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773343.url(scheme.get, call_773343.host, call_773343.base,
                         call_773343.route, valid.getOrDefault("path"))
  result = hook(call_773343, url, valid)

proc call*(call_773344: Call_CreatePreset_773332; body: JsonNode): Recallable =
  ## createPreset
  ## Create a new preset. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ##   body: JObject (required)
  var body_773345 = newJObject()
  if body != nil:
    body_773345 = body
  result = call_773344.call(nil, nil, nil, nil, body_773345)

var createPreset* = Call_CreatePreset_773332(name: "createPreset",
    meth: HttpMethod.HttpPost, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/presets", validator: validate_CreatePreset_773333,
    base: "/", url: url_CreatePreset_773334, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPresets_773312 = ref object of OpenApiRestCall_772597
proc url_ListPresets_773314(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPresets_773313(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773315 = query.getOrDefault("order")
  valid_773315 = validateParameter(valid_773315, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_773315 != nil:
    section.add "order", valid_773315
  var valid_773316 = query.getOrDefault("NextToken")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "NextToken", valid_773316
  var valid_773317 = query.getOrDefault("maxResults")
  valid_773317 = validateParameter(valid_773317, JInt, required = false, default = nil)
  if valid_773317 != nil:
    section.add "maxResults", valid_773317
  var valid_773318 = query.getOrDefault("nextToken")
  valid_773318 = validateParameter(valid_773318, JString, required = false,
                                 default = nil)
  if valid_773318 != nil:
    section.add "nextToken", valid_773318
  var valid_773319 = query.getOrDefault("listBy")
  valid_773319 = validateParameter(valid_773319, JString, required = false,
                                 default = newJString("NAME"))
  if valid_773319 != nil:
    section.add "listBy", valid_773319
  var valid_773320 = query.getOrDefault("category")
  valid_773320 = validateParameter(valid_773320, JString, required = false,
                                 default = nil)
  if valid_773320 != nil:
    section.add "category", valid_773320
  var valid_773321 = query.getOrDefault("MaxResults")
  valid_773321 = validateParameter(valid_773321, JString, required = false,
                                 default = nil)
  if valid_773321 != nil:
    section.add "MaxResults", valid_773321
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
  var valid_773322 = header.getOrDefault("X-Amz-Date")
  valid_773322 = validateParameter(valid_773322, JString, required = false,
                                 default = nil)
  if valid_773322 != nil:
    section.add "X-Amz-Date", valid_773322
  var valid_773323 = header.getOrDefault("X-Amz-Security-Token")
  valid_773323 = validateParameter(valid_773323, JString, required = false,
                                 default = nil)
  if valid_773323 != nil:
    section.add "X-Amz-Security-Token", valid_773323
  var valid_773324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773324 = validateParameter(valid_773324, JString, required = false,
                                 default = nil)
  if valid_773324 != nil:
    section.add "X-Amz-Content-Sha256", valid_773324
  var valid_773325 = header.getOrDefault("X-Amz-Algorithm")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "X-Amz-Algorithm", valid_773325
  var valid_773326 = header.getOrDefault("X-Amz-Signature")
  valid_773326 = validateParameter(valid_773326, JString, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "X-Amz-Signature", valid_773326
  var valid_773327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773327 = validateParameter(valid_773327, JString, required = false,
                                 default = nil)
  if valid_773327 != nil:
    section.add "X-Amz-SignedHeaders", valid_773327
  var valid_773328 = header.getOrDefault("X-Amz-Credential")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "X-Amz-Credential", valid_773328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773329: Call_ListPresets_773312; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a JSON array of up to twenty of your presets. This will return the presets themselves, not just a list of them. To retrieve the next twenty presets, use the nextToken string returned with the array.
  ## 
  let valid = call_773329.validator(path, query, header, formData, body)
  let scheme = call_773329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773329.url(scheme.get, call_773329.host, call_773329.base,
                         call_773329.route, valid.getOrDefault("path"))
  result = hook(call_773329, url, valid)

proc call*(call_773330: Call_ListPresets_773312; order: string = "ASCENDING";
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
  var query_773331 = newJObject()
  add(query_773331, "order", newJString(order))
  add(query_773331, "NextToken", newJString(NextToken))
  add(query_773331, "maxResults", newJInt(maxResults))
  add(query_773331, "nextToken", newJString(nextToken))
  add(query_773331, "listBy", newJString(listBy))
  add(query_773331, "category", newJString(category))
  add(query_773331, "MaxResults", newJString(MaxResults))
  result = call_773330.call(nil, query_773331, nil, nil, nil)

var listPresets* = Call_ListPresets_773312(name: "listPresets",
                                        meth: HttpMethod.HttpGet,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/presets",
                                        validator: validate_ListPresets_773313,
                                        base: "/", url: url_ListPresets_773314,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateQueue_773365 = ref object of OpenApiRestCall_772597
proc url_CreateQueue_773367(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateQueue_773366(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773368 = header.getOrDefault("X-Amz-Date")
  valid_773368 = validateParameter(valid_773368, JString, required = false,
                                 default = nil)
  if valid_773368 != nil:
    section.add "X-Amz-Date", valid_773368
  var valid_773369 = header.getOrDefault("X-Amz-Security-Token")
  valid_773369 = validateParameter(valid_773369, JString, required = false,
                                 default = nil)
  if valid_773369 != nil:
    section.add "X-Amz-Security-Token", valid_773369
  var valid_773370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "X-Amz-Content-Sha256", valid_773370
  var valid_773371 = header.getOrDefault("X-Amz-Algorithm")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "X-Amz-Algorithm", valid_773371
  var valid_773372 = header.getOrDefault("X-Amz-Signature")
  valid_773372 = validateParameter(valid_773372, JString, required = false,
                                 default = nil)
  if valid_773372 != nil:
    section.add "X-Amz-Signature", valid_773372
  var valid_773373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-SignedHeaders", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-Credential")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-Credential", valid_773374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773376: Call_CreateQueue_773365; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new transcoding queue. For information about queues, see Working With Queues in the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/working-with-queues.html
  ## 
  let valid = call_773376.validator(path, query, header, formData, body)
  let scheme = call_773376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773376.url(scheme.get, call_773376.host, call_773376.base,
                         call_773376.route, valid.getOrDefault("path"))
  result = hook(call_773376, url, valid)

proc call*(call_773377: Call_CreateQueue_773365; body: JsonNode): Recallable =
  ## createQueue
  ## Create a new transcoding queue. For information about queues, see Working With Queues in the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/working-with-queues.html
  ##   body: JObject (required)
  var body_773378 = newJObject()
  if body != nil:
    body_773378 = body
  result = call_773377.call(nil, nil, nil, nil, body_773378)

var createQueue* = Call_CreateQueue_773365(name: "createQueue",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/queues",
                                        validator: validate_CreateQueue_773366,
                                        base: "/", url: url_CreateQueue_773367,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQueues_773346 = ref object of OpenApiRestCall_772597
proc url_ListQueues_773348(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListQueues_773347(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773349 = query.getOrDefault("order")
  valid_773349 = validateParameter(valid_773349, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_773349 != nil:
    section.add "order", valid_773349
  var valid_773350 = query.getOrDefault("NextToken")
  valid_773350 = validateParameter(valid_773350, JString, required = false,
                                 default = nil)
  if valid_773350 != nil:
    section.add "NextToken", valid_773350
  var valid_773351 = query.getOrDefault("maxResults")
  valid_773351 = validateParameter(valid_773351, JInt, required = false, default = nil)
  if valid_773351 != nil:
    section.add "maxResults", valid_773351
  var valid_773352 = query.getOrDefault("nextToken")
  valid_773352 = validateParameter(valid_773352, JString, required = false,
                                 default = nil)
  if valid_773352 != nil:
    section.add "nextToken", valid_773352
  var valid_773353 = query.getOrDefault("listBy")
  valid_773353 = validateParameter(valid_773353, JString, required = false,
                                 default = newJString("NAME"))
  if valid_773353 != nil:
    section.add "listBy", valid_773353
  var valid_773354 = query.getOrDefault("MaxResults")
  valid_773354 = validateParameter(valid_773354, JString, required = false,
                                 default = nil)
  if valid_773354 != nil:
    section.add "MaxResults", valid_773354
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
  var valid_773355 = header.getOrDefault("X-Amz-Date")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "X-Amz-Date", valid_773355
  var valid_773356 = header.getOrDefault("X-Amz-Security-Token")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "X-Amz-Security-Token", valid_773356
  var valid_773357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773357 = validateParameter(valid_773357, JString, required = false,
                                 default = nil)
  if valid_773357 != nil:
    section.add "X-Amz-Content-Sha256", valid_773357
  var valid_773358 = header.getOrDefault("X-Amz-Algorithm")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Algorithm", valid_773358
  var valid_773359 = header.getOrDefault("X-Amz-Signature")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Signature", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-SignedHeaders", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-Credential")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-Credential", valid_773361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773362: Call_ListQueues_773346; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a JSON array of up to twenty of your queues. This will return the queues themselves, not just a list of them. To retrieve the next twenty queues, use the nextToken string returned with the array.
  ## 
  let valid = call_773362.validator(path, query, header, formData, body)
  let scheme = call_773362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773362.url(scheme.get, call_773362.host, call_773362.base,
                         call_773362.route, valid.getOrDefault("path"))
  result = hook(call_773362, url, valid)

proc call*(call_773363: Call_ListQueues_773346; order: string = "ASCENDING";
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
  var query_773364 = newJObject()
  add(query_773364, "order", newJString(order))
  add(query_773364, "NextToken", newJString(NextToken))
  add(query_773364, "maxResults", newJInt(maxResults))
  add(query_773364, "nextToken", newJString(nextToken))
  add(query_773364, "listBy", newJString(listBy))
  add(query_773364, "MaxResults", newJString(MaxResults))
  result = call_773363.call(nil, query_773364, nil, nil, nil)

var listQueues* = Call_ListQueues_773346(name: "listQueues",
                                      meth: HttpMethod.HttpGet,
                                      host: "mediaconvert.amazonaws.com",
                                      route: "/2017-08-29/queues",
                                      validator: validate_ListQueues_773347,
                                      base: "/", url: url_ListQueues_773348,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJobTemplate_773393 = ref object of OpenApiRestCall_772597
proc url_UpdateJobTemplate_773395(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateJobTemplate_773394(path: JsonNode; query: JsonNode;
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
  var valid_773396 = path.getOrDefault("name")
  valid_773396 = validateParameter(valid_773396, JString, required = true,
                                 default = nil)
  if valid_773396 != nil:
    section.add "name", valid_773396
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
  var valid_773397 = header.getOrDefault("X-Amz-Date")
  valid_773397 = validateParameter(valid_773397, JString, required = false,
                                 default = nil)
  if valid_773397 != nil:
    section.add "X-Amz-Date", valid_773397
  var valid_773398 = header.getOrDefault("X-Amz-Security-Token")
  valid_773398 = validateParameter(valid_773398, JString, required = false,
                                 default = nil)
  if valid_773398 != nil:
    section.add "X-Amz-Security-Token", valid_773398
  var valid_773399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773399 = validateParameter(valid_773399, JString, required = false,
                                 default = nil)
  if valid_773399 != nil:
    section.add "X-Amz-Content-Sha256", valid_773399
  var valid_773400 = header.getOrDefault("X-Amz-Algorithm")
  valid_773400 = validateParameter(valid_773400, JString, required = false,
                                 default = nil)
  if valid_773400 != nil:
    section.add "X-Amz-Algorithm", valid_773400
  var valid_773401 = header.getOrDefault("X-Amz-Signature")
  valid_773401 = validateParameter(valid_773401, JString, required = false,
                                 default = nil)
  if valid_773401 != nil:
    section.add "X-Amz-Signature", valid_773401
  var valid_773402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773402 = validateParameter(valid_773402, JString, required = false,
                                 default = nil)
  if valid_773402 != nil:
    section.add "X-Amz-SignedHeaders", valid_773402
  var valid_773403 = header.getOrDefault("X-Amz-Credential")
  valid_773403 = validateParameter(valid_773403, JString, required = false,
                                 default = nil)
  if valid_773403 != nil:
    section.add "X-Amz-Credential", valid_773403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773405: Call_UpdateJobTemplate_773393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modify one of your existing job templates.
  ## 
  let valid = call_773405.validator(path, query, header, formData, body)
  let scheme = call_773405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773405.url(scheme.get, call_773405.host, call_773405.base,
                         call_773405.route, valid.getOrDefault("path"))
  result = hook(call_773405, url, valid)

proc call*(call_773406: Call_UpdateJobTemplate_773393; name: string; body: JsonNode): Recallable =
  ## updateJobTemplate
  ## Modify one of your existing job templates.
  ##   name: string (required)
  ##       : The name of the job template you are modifying
  ##   body: JObject (required)
  var path_773407 = newJObject()
  var body_773408 = newJObject()
  add(path_773407, "name", newJString(name))
  if body != nil:
    body_773408 = body
  result = call_773406.call(path_773407, nil, nil, nil, body_773408)

var updateJobTemplate* = Call_UpdateJobTemplate_773393(name: "updateJobTemplate",
    meth: HttpMethod.HttpPut, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates/{name}",
    validator: validate_UpdateJobTemplate_773394, base: "/",
    url: url_UpdateJobTemplate_773395, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobTemplate_773379 = ref object of OpenApiRestCall_772597
proc url_GetJobTemplate_773381(protocol: Scheme; host: string; base: string;
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

proc validate_GetJobTemplate_773380(path: JsonNode; query: JsonNode;
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
  var valid_773382 = path.getOrDefault("name")
  valid_773382 = validateParameter(valid_773382, JString, required = true,
                                 default = nil)
  if valid_773382 != nil:
    section.add "name", valid_773382
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
  var valid_773383 = header.getOrDefault("X-Amz-Date")
  valid_773383 = validateParameter(valid_773383, JString, required = false,
                                 default = nil)
  if valid_773383 != nil:
    section.add "X-Amz-Date", valid_773383
  var valid_773384 = header.getOrDefault("X-Amz-Security-Token")
  valid_773384 = validateParameter(valid_773384, JString, required = false,
                                 default = nil)
  if valid_773384 != nil:
    section.add "X-Amz-Security-Token", valid_773384
  var valid_773385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773385 = validateParameter(valid_773385, JString, required = false,
                                 default = nil)
  if valid_773385 != nil:
    section.add "X-Amz-Content-Sha256", valid_773385
  var valid_773386 = header.getOrDefault("X-Amz-Algorithm")
  valid_773386 = validateParameter(valid_773386, JString, required = false,
                                 default = nil)
  if valid_773386 != nil:
    section.add "X-Amz-Algorithm", valid_773386
  var valid_773387 = header.getOrDefault("X-Amz-Signature")
  valid_773387 = validateParameter(valid_773387, JString, required = false,
                                 default = nil)
  if valid_773387 != nil:
    section.add "X-Amz-Signature", valid_773387
  var valid_773388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "X-Amz-SignedHeaders", valid_773388
  var valid_773389 = header.getOrDefault("X-Amz-Credential")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "X-Amz-Credential", valid_773389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773390: Call_GetJobTemplate_773379; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the JSON for a specific job template.
  ## 
  let valid = call_773390.validator(path, query, header, formData, body)
  let scheme = call_773390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773390.url(scheme.get, call_773390.host, call_773390.base,
                         call_773390.route, valid.getOrDefault("path"))
  result = hook(call_773390, url, valid)

proc call*(call_773391: Call_GetJobTemplate_773379; name: string): Recallable =
  ## getJobTemplate
  ## Retrieve the JSON for a specific job template.
  ##   name: string (required)
  ##       : The name of the job template.
  var path_773392 = newJObject()
  add(path_773392, "name", newJString(name))
  result = call_773391.call(path_773392, nil, nil, nil, nil)

var getJobTemplate* = Call_GetJobTemplate_773379(name: "getJobTemplate",
    meth: HttpMethod.HttpGet, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates/{name}", validator: validate_GetJobTemplate_773380,
    base: "/", url: url_GetJobTemplate_773381, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJobTemplate_773409 = ref object of OpenApiRestCall_772597
proc url_DeleteJobTemplate_773411(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteJobTemplate_773410(path: JsonNode; query: JsonNode;
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
  var valid_773412 = path.getOrDefault("name")
  valid_773412 = validateParameter(valid_773412, JString, required = true,
                                 default = nil)
  if valid_773412 != nil:
    section.add "name", valid_773412
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
  var valid_773413 = header.getOrDefault("X-Amz-Date")
  valid_773413 = validateParameter(valid_773413, JString, required = false,
                                 default = nil)
  if valid_773413 != nil:
    section.add "X-Amz-Date", valid_773413
  var valid_773414 = header.getOrDefault("X-Amz-Security-Token")
  valid_773414 = validateParameter(valid_773414, JString, required = false,
                                 default = nil)
  if valid_773414 != nil:
    section.add "X-Amz-Security-Token", valid_773414
  var valid_773415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773415 = validateParameter(valid_773415, JString, required = false,
                                 default = nil)
  if valid_773415 != nil:
    section.add "X-Amz-Content-Sha256", valid_773415
  var valid_773416 = header.getOrDefault("X-Amz-Algorithm")
  valid_773416 = validateParameter(valid_773416, JString, required = false,
                                 default = nil)
  if valid_773416 != nil:
    section.add "X-Amz-Algorithm", valid_773416
  var valid_773417 = header.getOrDefault("X-Amz-Signature")
  valid_773417 = validateParameter(valid_773417, JString, required = false,
                                 default = nil)
  if valid_773417 != nil:
    section.add "X-Amz-Signature", valid_773417
  var valid_773418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773418 = validateParameter(valid_773418, JString, required = false,
                                 default = nil)
  if valid_773418 != nil:
    section.add "X-Amz-SignedHeaders", valid_773418
  var valid_773419 = header.getOrDefault("X-Amz-Credential")
  valid_773419 = validateParameter(valid_773419, JString, required = false,
                                 default = nil)
  if valid_773419 != nil:
    section.add "X-Amz-Credential", valid_773419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773420: Call_DeleteJobTemplate_773409; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently delete a job template you have created.
  ## 
  let valid = call_773420.validator(path, query, header, formData, body)
  let scheme = call_773420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773420.url(scheme.get, call_773420.host, call_773420.base,
                         call_773420.route, valid.getOrDefault("path"))
  result = hook(call_773420, url, valid)

proc call*(call_773421: Call_DeleteJobTemplate_773409; name: string): Recallable =
  ## deleteJobTemplate
  ## Permanently delete a job template you have created.
  ##   name: string (required)
  ##       : The name of the job template to be deleted.
  var path_773422 = newJObject()
  add(path_773422, "name", newJString(name))
  result = call_773421.call(path_773422, nil, nil, nil, nil)

var deleteJobTemplate* = Call_DeleteJobTemplate_773409(name: "deleteJobTemplate",
    meth: HttpMethod.HttpDelete, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates/{name}",
    validator: validate_DeleteJobTemplate_773410, base: "/",
    url: url_DeleteJobTemplate_773411, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePreset_773437 = ref object of OpenApiRestCall_772597
proc url_UpdatePreset_773439(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePreset_773438(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773440 = path.getOrDefault("name")
  valid_773440 = validateParameter(valid_773440, JString, required = true,
                                 default = nil)
  if valid_773440 != nil:
    section.add "name", valid_773440
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
  var valid_773441 = header.getOrDefault("X-Amz-Date")
  valid_773441 = validateParameter(valid_773441, JString, required = false,
                                 default = nil)
  if valid_773441 != nil:
    section.add "X-Amz-Date", valid_773441
  var valid_773442 = header.getOrDefault("X-Amz-Security-Token")
  valid_773442 = validateParameter(valid_773442, JString, required = false,
                                 default = nil)
  if valid_773442 != nil:
    section.add "X-Amz-Security-Token", valid_773442
  var valid_773443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773443 = validateParameter(valid_773443, JString, required = false,
                                 default = nil)
  if valid_773443 != nil:
    section.add "X-Amz-Content-Sha256", valid_773443
  var valid_773444 = header.getOrDefault("X-Amz-Algorithm")
  valid_773444 = validateParameter(valid_773444, JString, required = false,
                                 default = nil)
  if valid_773444 != nil:
    section.add "X-Amz-Algorithm", valid_773444
  var valid_773445 = header.getOrDefault("X-Amz-Signature")
  valid_773445 = validateParameter(valid_773445, JString, required = false,
                                 default = nil)
  if valid_773445 != nil:
    section.add "X-Amz-Signature", valid_773445
  var valid_773446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773446 = validateParameter(valid_773446, JString, required = false,
                                 default = nil)
  if valid_773446 != nil:
    section.add "X-Amz-SignedHeaders", valid_773446
  var valid_773447 = header.getOrDefault("X-Amz-Credential")
  valid_773447 = validateParameter(valid_773447, JString, required = false,
                                 default = nil)
  if valid_773447 != nil:
    section.add "X-Amz-Credential", valid_773447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773449: Call_UpdatePreset_773437; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modify one of your existing presets.
  ## 
  let valid = call_773449.validator(path, query, header, formData, body)
  let scheme = call_773449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773449.url(scheme.get, call_773449.host, call_773449.base,
                         call_773449.route, valid.getOrDefault("path"))
  result = hook(call_773449, url, valid)

proc call*(call_773450: Call_UpdatePreset_773437; name: string; body: JsonNode): Recallable =
  ## updatePreset
  ## Modify one of your existing presets.
  ##   name: string (required)
  ##       : The name of the preset you are modifying.
  ##   body: JObject (required)
  var path_773451 = newJObject()
  var body_773452 = newJObject()
  add(path_773451, "name", newJString(name))
  if body != nil:
    body_773452 = body
  result = call_773450.call(path_773451, nil, nil, nil, body_773452)

var updatePreset* = Call_UpdatePreset_773437(name: "updatePreset",
    meth: HttpMethod.HttpPut, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/presets/{name}", validator: validate_UpdatePreset_773438,
    base: "/", url: url_UpdatePreset_773439, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPreset_773423 = ref object of OpenApiRestCall_772597
proc url_GetPreset_773425(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetPreset_773424(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773426 = path.getOrDefault("name")
  valid_773426 = validateParameter(valid_773426, JString, required = true,
                                 default = nil)
  if valid_773426 != nil:
    section.add "name", valid_773426
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
  var valid_773427 = header.getOrDefault("X-Amz-Date")
  valid_773427 = validateParameter(valid_773427, JString, required = false,
                                 default = nil)
  if valid_773427 != nil:
    section.add "X-Amz-Date", valid_773427
  var valid_773428 = header.getOrDefault("X-Amz-Security-Token")
  valid_773428 = validateParameter(valid_773428, JString, required = false,
                                 default = nil)
  if valid_773428 != nil:
    section.add "X-Amz-Security-Token", valid_773428
  var valid_773429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773429 = validateParameter(valid_773429, JString, required = false,
                                 default = nil)
  if valid_773429 != nil:
    section.add "X-Amz-Content-Sha256", valid_773429
  var valid_773430 = header.getOrDefault("X-Amz-Algorithm")
  valid_773430 = validateParameter(valid_773430, JString, required = false,
                                 default = nil)
  if valid_773430 != nil:
    section.add "X-Amz-Algorithm", valid_773430
  var valid_773431 = header.getOrDefault("X-Amz-Signature")
  valid_773431 = validateParameter(valid_773431, JString, required = false,
                                 default = nil)
  if valid_773431 != nil:
    section.add "X-Amz-Signature", valid_773431
  var valid_773432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773432 = validateParameter(valid_773432, JString, required = false,
                                 default = nil)
  if valid_773432 != nil:
    section.add "X-Amz-SignedHeaders", valid_773432
  var valid_773433 = header.getOrDefault("X-Amz-Credential")
  valid_773433 = validateParameter(valid_773433, JString, required = false,
                                 default = nil)
  if valid_773433 != nil:
    section.add "X-Amz-Credential", valid_773433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773434: Call_GetPreset_773423; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the JSON for a specific preset.
  ## 
  let valid = call_773434.validator(path, query, header, formData, body)
  let scheme = call_773434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773434.url(scheme.get, call_773434.host, call_773434.base,
                         call_773434.route, valid.getOrDefault("path"))
  result = hook(call_773434, url, valid)

proc call*(call_773435: Call_GetPreset_773423; name: string): Recallable =
  ## getPreset
  ## Retrieve the JSON for a specific preset.
  ##   name: string (required)
  ##       : The name of the preset.
  var path_773436 = newJObject()
  add(path_773436, "name", newJString(name))
  result = call_773435.call(path_773436, nil, nil, nil, nil)

var getPreset* = Call_GetPreset_773423(name: "getPreset", meth: HttpMethod.HttpGet,
                                    host: "mediaconvert.amazonaws.com",
                                    route: "/2017-08-29/presets/{name}",
                                    validator: validate_GetPreset_773424,
                                    base: "/", url: url_GetPreset_773425,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePreset_773453 = ref object of OpenApiRestCall_772597
proc url_DeletePreset_773455(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePreset_773454(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773456 = path.getOrDefault("name")
  valid_773456 = validateParameter(valid_773456, JString, required = true,
                                 default = nil)
  if valid_773456 != nil:
    section.add "name", valid_773456
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
  var valid_773457 = header.getOrDefault("X-Amz-Date")
  valid_773457 = validateParameter(valid_773457, JString, required = false,
                                 default = nil)
  if valid_773457 != nil:
    section.add "X-Amz-Date", valid_773457
  var valid_773458 = header.getOrDefault("X-Amz-Security-Token")
  valid_773458 = validateParameter(valid_773458, JString, required = false,
                                 default = nil)
  if valid_773458 != nil:
    section.add "X-Amz-Security-Token", valid_773458
  var valid_773459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773459 = validateParameter(valid_773459, JString, required = false,
                                 default = nil)
  if valid_773459 != nil:
    section.add "X-Amz-Content-Sha256", valid_773459
  var valid_773460 = header.getOrDefault("X-Amz-Algorithm")
  valid_773460 = validateParameter(valid_773460, JString, required = false,
                                 default = nil)
  if valid_773460 != nil:
    section.add "X-Amz-Algorithm", valid_773460
  var valid_773461 = header.getOrDefault("X-Amz-Signature")
  valid_773461 = validateParameter(valid_773461, JString, required = false,
                                 default = nil)
  if valid_773461 != nil:
    section.add "X-Amz-Signature", valid_773461
  var valid_773462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773462 = validateParameter(valid_773462, JString, required = false,
                                 default = nil)
  if valid_773462 != nil:
    section.add "X-Amz-SignedHeaders", valid_773462
  var valid_773463 = header.getOrDefault("X-Amz-Credential")
  valid_773463 = validateParameter(valid_773463, JString, required = false,
                                 default = nil)
  if valid_773463 != nil:
    section.add "X-Amz-Credential", valid_773463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773464: Call_DeletePreset_773453; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently delete a preset you have created.
  ## 
  let valid = call_773464.validator(path, query, header, formData, body)
  let scheme = call_773464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773464.url(scheme.get, call_773464.host, call_773464.base,
                         call_773464.route, valid.getOrDefault("path"))
  result = hook(call_773464, url, valid)

proc call*(call_773465: Call_DeletePreset_773453; name: string): Recallable =
  ## deletePreset
  ## Permanently delete a preset you have created.
  ##   name: string (required)
  ##       : The name of the preset to be deleted.
  var path_773466 = newJObject()
  add(path_773466, "name", newJString(name))
  result = call_773465.call(path_773466, nil, nil, nil, nil)

var deletePreset* = Call_DeletePreset_773453(name: "deletePreset",
    meth: HttpMethod.HttpDelete, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/presets/{name}", validator: validate_DeletePreset_773454,
    base: "/", url: url_DeletePreset_773455, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateQueue_773481 = ref object of OpenApiRestCall_772597
proc url_UpdateQueue_773483(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateQueue_773482(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773484 = path.getOrDefault("name")
  valid_773484 = validateParameter(valid_773484, JString, required = true,
                                 default = nil)
  if valid_773484 != nil:
    section.add "name", valid_773484
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
  var valid_773485 = header.getOrDefault("X-Amz-Date")
  valid_773485 = validateParameter(valid_773485, JString, required = false,
                                 default = nil)
  if valid_773485 != nil:
    section.add "X-Amz-Date", valid_773485
  var valid_773486 = header.getOrDefault("X-Amz-Security-Token")
  valid_773486 = validateParameter(valid_773486, JString, required = false,
                                 default = nil)
  if valid_773486 != nil:
    section.add "X-Amz-Security-Token", valid_773486
  var valid_773487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773487 = validateParameter(valid_773487, JString, required = false,
                                 default = nil)
  if valid_773487 != nil:
    section.add "X-Amz-Content-Sha256", valid_773487
  var valid_773488 = header.getOrDefault("X-Amz-Algorithm")
  valid_773488 = validateParameter(valid_773488, JString, required = false,
                                 default = nil)
  if valid_773488 != nil:
    section.add "X-Amz-Algorithm", valid_773488
  var valid_773489 = header.getOrDefault("X-Amz-Signature")
  valid_773489 = validateParameter(valid_773489, JString, required = false,
                                 default = nil)
  if valid_773489 != nil:
    section.add "X-Amz-Signature", valid_773489
  var valid_773490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773490 = validateParameter(valid_773490, JString, required = false,
                                 default = nil)
  if valid_773490 != nil:
    section.add "X-Amz-SignedHeaders", valid_773490
  var valid_773491 = header.getOrDefault("X-Amz-Credential")
  valid_773491 = validateParameter(valid_773491, JString, required = false,
                                 default = nil)
  if valid_773491 != nil:
    section.add "X-Amz-Credential", valid_773491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773493: Call_UpdateQueue_773481; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modify one of your existing queues.
  ## 
  let valid = call_773493.validator(path, query, header, formData, body)
  let scheme = call_773493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773493.url(scheme.get, call_773493.host, call_773493.base,
                         call_773493.route, valid.getOrDefault("path"))
  result = hook(call_773493, url, valid)

proc call*(call_773494: Call_UpdateQueue_773481; name: string; body: JsonNode): Recallable =
  ## updateQueue
  ## Modify one of your existing queues.
  ##   name: string (required)
  ##       : The name of the queue that you are modifying.
  ##   body: JObject (required)
  var path_773495 = newJObject()
  var body_773496 = newJObject()
  add(path_773495, "name", newJString(name))
  if body != nil:
    body_773496 = body
  result = call_773494.call(path_773495, nil, nil, nil, body_773496)

var updateQueue* = Call_UpdateQueue_773481(name: "updateQueue",
                                        meth: HttpMethod.HttpPut,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/queues/{name}",
                                        validator: validate_UpdateQueue_773482,
                                        base: "/", url: url_UpdateQueue_773483,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQueue_773467 = ref object of OpenApiRestCall_772597
proc url_GetQueue_773469(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetQueue_773468(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773470 = path.getOrDefault("name")
  valid_773470 = validateParameter(valid_773470, JString, required = true,
                                 default = nil)
  if valid_773470 != nil:
    section.add "name", valid_773470
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
  var valid_773471 = header.getOrDefault("X-Amz-Date")
  valid_773471 = validateParameter(valid_773471, JString, required = false,
                                 default = nil)
  if valid_773471 != nil:
    section.add "X-Amz-Date", valid_773471
  var valid_773472 = header.getOrDefault("X-Amz-Security-Token")
  valid_773472 = validateParameter(valid_773472, JString, required = false,
                                 default = nil)
  if valid_773472 != nil:
    section.add "X-Amz-Security-Token", valid_773472
  var valid_773473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773473 = validateParameter(valid_773473, JString, required = false,
                                 default = nil)
  if valid_773473 != nil:
    section.add "X-Amz-Content-Sha256", valid_773473
  var valid_773474 = header.getOrDefault("X-Amz-Algorithm")
  valid_773474 = validateParameter(valid_773474, JString, required = false,
                                 default = nil)
  if valid_773474 != nil:
    section.add "X-Amz-Algorithm", valid_773474
  var valid_773475 = header.getOrDefault("X-Amz-Signature")
  valid_773475 = validateParameter(valid_773475, JString, required = false,
                                 default = nil)
  if valid_773475 != nil:
    section.add "X-Amz-Signature", valid_773475
  var valid_773476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773476 = validateParameter(valid_773476, JString, required = false,
                                 default = nil)
  if valid_773476 != nil:
    section.add "X-Amz-SignedHeaders", valid_773476
  var valid_773477 = header.getOrDefault("X-Amz-Credential")
  valid_773477 = validateParameter(valid_773477, JString, required = false,
                                 default = nil)
  if valid_773477 != nil:
    section.add "X-Amz-Credential", valid_773477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773478: Call_GetQueue_773467; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the JSON for a specific queue.
  ## 
  let valid = call_773478.validator(path, query, header, formData, body)
  let scheme = call_773478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773478.url(scheme.get, call_773478.host, call_773478.base,
                         call_773478.route, valid.getOrDefault("path"))
  result = hook(call_773478, url, valid)

proc call*(call_773479: Call_GetQueue_773467; name: string): Recallable =
  ## getQueue
  ## Retrieve the JSON for a specific queue.
  ##   name: string (required)
  ##       : The name of the queue that you want information about.
  var path_773480 = newJObject()
  add(path_773480, "name", newJString(name))
  result = call_773479.call(path_773480, nil, nil, nil, nil)

var getQueue* = Call_GetQueue_773467(name: "getQueue", meth: HttpMethod.HttpGet,
                                  host: "mediaconvert.amazonaws.com",
                                  route: "/2017-08-29/queues/{name}",
                                  validator: validate_GetQueue_773468, base: "/",
                                  url: url_GetQueue_773469,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteQueue_773497 = ref object of OpenApiRestCall_772597
proc url_DeleteQueue_773499(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteQueue_773498(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773500 = path.getOrDefault("name")
  valid_773500 = validateParameter(valid_773500, JString, required = true,
                                 default = nil)
  if valid_773500 != nil:
    section.add "name", valid_773500
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
  var valid_773501 = header.getOrDefault("X-Amz-Date")
  valid_773501 = validateParameter(valid_773501, JString, required = false,
                                 default = nil)
  if valid_773501 != nil:
    section.add "X-Amz-Date", valid_773501
  var valid_773502 = header.getOrDefault("X-Amz-Security-Token")
  valid_773502 = validateParameter(valid_773502, JString, required = false,
                                 default = nil)
  if valid_773502 != nil:
    section.add "X-Amz-Security-Token", valid_773502
  var valid_773503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773503 = validateParameter(valid_773503, JString, required = false,
                                 default = nil)
  if valid_773503 != nil:
    section.add "X-Amz-Content-Sha256", valid_773503
  var valid_773504 = header.getOrDefault("X-Amz-Algorithm")
  valid_773504 = validateParameter(valid_773504, JString, required = false,
                                 default = nil)
  if valid_773504 != nil:
    section.add "X-Amz-Algorithm", valid_773504
  var valid_773505 = header.getOrDefault("X-Amz-Signature")
  valid_773505 = validateParameter(valid_773505, JString, required = false,
                                 default = nil)
  if valid_773505 != nil:
    section.add "X-Amz-Signature", valid_773505
  var valid_773506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773506 = validateParameter(valid_773506, JString, required = false,
                                 default = nil)
  if valid_773506 != nil:
    section.add "X-Amz-SignedHeaders", valid_773506
  var valid_773507 = header.getOrDefault("X-Amz-Credential")
  valid_773507 = validateParameter(valid_773507, JString, required = false,
                                 default = nil)
  if valid_773507 != nil:
    section.add "X-Amz-Credential", valid_773507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773508: Call_DeleteQueue_773497; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently delete a queue you have created.
  ## 
  let valid = call_773508.validator(path, query, header, formData, body)
  let scheme = call_773508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773508.url(scheme.get, call_773508.host, call_773508.base,
                         call_773508.route, valid.getOrDefault("path"))
  result = hook(call_773508, url, valid)

proc call*(call_773509: Call_DeleteQueue_773497; name: string): Recallable =
  ## deleteQueue
  ## Permanently delete a queue you have created.
  ##   name: string (required)
  ##       : The name of the queue that you want to delete.
  var path_773510 = newJObject()
  add(path_773510, "name", newJString(name))
  result = call_773509.call(path_773510, nil, nil, nil, nil)

var deleteQueue* = Call_DeleteQueue_773497(name: "deleteQueue",
                                        meth: HttpMethod.HttpDelete,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/queues/{name}",
                                        validator: validate_DeleteQueue_773498,
                                        base: "/", url: url_DeleteQueue_773499,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoints_773511 = ref object of OpenApiRestCall_772597
proc url_DescribeEndpoints_773513(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEndpoints_773512(path: JsonNode; query: JsonNode;
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
  var valid_773514 = query.getOrDefault("NextToken")
  valid_773514 = validateParameter(valid_773514, JString, required = false,
                                 default = nil)
  if valid_773514 != nil:
    section.add "NextToken", valid_773514
  var valid_773515 = query.getOrDefault("MaxResults")
  valid_773515 = validateParameter(valid_773515, JString, required = false,
                                 default = nil)
  if valid_773515 != nil:
    section.add "MaxResults", valid_773515
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
  var valid_773516 = header.getOrDefault("X-Amz-Date")
  valid_773516 = validateParameter(valid_773516, JString, required = false,
                                 default = nil)
  if valid_773516 != nil:
    section.add "X-Amz-Date", valid_773516
  var valid_773517 = header.getOrDefault("X-Amz-Security-Token")
  valid_773517 = validateParameter(valid_773517, JString, required = false,
                                 default = nil)
  if valid_773517 != nil:
    section.add "X-Amz-Security-Token", valid_773517
  var valid_773518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773518 = validateParameter(valid_773518, JString, required = false,
                                 default = nil)
  if valid_773518 != nil:
    section.add "X-Amz-Content-Sha256", valid_773518
  var valid_773519 = header.getOrDefault("X-Amz-Algorithm")
  valid_773519 = validateParameter(valid_773519, JString, required = false,
                                 default = nil)
  if valid_773519 != nil:
    section.add "X-Amz-Algorithm", valid_773519
  var valid_773520 = header.getOrDefault("X-Amz-Signature")
  valid_773520 = validateParameter(valid_773520, JString, required = false,
                                 default = nil)
  if valid_773520 != nil:
    section.add "X-Amz-Signature", valid_773520
  var valid_773521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773521 = validateParameter(valid_773521, JString, required = false,
                                 default = nil)
  if valid_773521 != nil:
    section.add "X-Amz-SignedHeaders", valid_773521
  var valid_773522 = header.getOrDefault("X-Amz-Credential")
  valid_773522 = validateParameter(valid_773522, JString, required = false,
                                 default = nil)
  if valid_773522 != nil:
    section.add "X-Amz-Credential", valid_773522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773524: Call_DescribeEndpoints_773511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Send an request with an empty body to the regional API endpoint to get your account API endpoint.
  ## 
  let valid = call_773524.validator(path, query, header, formData, body)
  let scheme = call_773524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773524.url(scheme.get, call_773524.host, call_773524.base,
                         call_773524.route, valid.getOrDefault("path"))
  result = hook(call_773524, url, valid)

proc call*(call_773525: Call_DescribeEndpoints_773511; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeEndpoints
  ## Send an request with an empty body to the regional API endpoint to get your account API endpoint.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773526 = newJObject()
  var body_773527 = newJObject()
  add(query_773526, "NextToken", newJString(NextToken))
  if body != nil:
    body_773527 = body
  add(query_773526, "MaxResults", newJString(MaxResults))
  result = call_773525.call(nil, query_773526, nil, nil, body_773527)

var describeEndpoints* = Call_DescribeEndpoints_773511(name: "describeEndpoints",
    meth: HttpMethod.HttpPost, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/endpoints", validator: validate_DescribeEndpoints_773512,
    base: "/", url: url_DescribeEndpoints_773513,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateCertificate_773528 = ref object of OpenApiRestCall_772597
proc url_DisassociateCertificate_773530(protocol: Scheme; host: string; base: string;
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

proc validate_DisassociateCertificate_773529(path: JsonNode; query: JsonNode;
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
  var valid_773531 = path.getOrDefault("arn")
  valid_773531 = validateParameter(valid_773531, JString, required = true,
                                 default = nil)
  if valid_773531 != nil:
    section.add "arn", valid_773531
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
  var valid_773532 = header.getOrDefault("X-Amz-Date")
  valid_773532 = validateParameter(valid_773532, JString, required = false,
                                 default = nil)
  if valid_773532 != nil:
    section.add "X-Amz-Date", valid_773532
  var valid_773533 = header.getOrDefault("X-Amz-Security-Token")
  valid_773533 = validateParameter(valid_773533, JString, required = false,
                                 default = nil)
  if valid_773533 != nil:
    section.add "X-Amz-Security-Token", valid_773533
  var valid_773534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773534 = validateParameter(valid_773534, JString, required = false,
                                 default = nil)
  if valid_773534 != nil:
    section.add "X-Amz-Content-Sha256", valid_773534
  var valid_773535 = header.getOrDefault("X-Amz-Algorithm")
  valid_773535 = validateParameter(valid_773535, JString, required = false,
                                 default = nil)
  if valid_773535 != nil:
    section.add "X-Amz-Algorithm", valid_773535
  var valid_773536 = header.getOrDefault("X-Amz-Signature")
  valid_773536 = validateParameter(valid_773536, JString, required = false,
                                 default = nil)
  if valid_773536 != nil:
    section.add "X-Amz-Signature", valid_773536
  var valid_773537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773537 = validateParameter(valid_773537, JString, required = false,
                                 default = nil)
  if valid_773537 != nil:
    section.add "X-Amz-SignedHeaders", valid_773537
  var valid_773538 = header.getOrDefault("X-Amz-Credential")
  valid_773538 = validateParameter(valid_773538, JString, required = false,
                                 default = nil)
  if valid_773538 != nil:
    section.add "X-Amz-Credential", valid_773538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773539: Call_DisassociateCertificate_773528; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an association between the Amazon Resource Name (ARN) of an AWS Certificate Manager (ACM) certificate and an AWS Elemental MediaConvert resource.
  ## 
  let valid = call_773539.validator(path, query, header, formData, body)
  let scheme = call_773539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773539.url(scheme.get, call_773539.host, call_773539.base,
                         call_773539.route, valid.getOrDefault("path"))
  result = hook(call_773539, url, valid)

proc call*(call_773540: Call_DisassociateCertificate_773528; arn: string): Recallable =
  ## disassociateCertificate
  ## Removes an association between the Amazon Resource Name (ARN) of an AWS Certificate Manager (ACM) certificate and an AWS Elemental MediaConvert resource.
  ##   arn: string (required)
  ##      : The ARN of the ACM certificate that you want to disassociate from your MediaConvert resource.
  var path_773541 = newJObject()
  add(path_773541, "arn", newJString(arn))
  result = call_773540.call(path_773541, nil, nil, nil, nil)

var disassociateCertificate* = Call_DisassociateCertificate_773528(
    name: "disassociateCertificate", meth: HttpMethod.HttpDelete,
    host: "mediaconvert.amazonaws.com", route: "/2017-08-29/certificates/{arn}",
    validator: validate_DisassociateCertificate_773529, base: "/",
    url: url_DisassociateCertificate_773530, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_773556 = ref object of OpenApiRestCall_772597
proc url_UntagResource_773558(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_773557(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773559 = path.getOrDefault("arn")
  valid_773559 = validateParameter(valid_773559, JString, required = true,
                                 default = nil)
  if valid_773559 != nil:
    section.add "arn", valid_773559
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
  var valid_773560 = header.getOrDefault("X-Amz-Date")
  valid_773560 = validateParameter(valid_773560, JString, required = false,
                                 default = nil)
  if valid_773560 != nil:
    section.add "X-Amz-Date", valid_773560
  var valid_773561 = header.getOrDefault("X-Amz-Security-Token")
  valid_773561 = validateParameter(valid_773561, JString, required = false,
                                 default = nil)
  if valid_773561 != nil:
    section.add "X-Amz-Security-Token", valid_773561
  var valid_773562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773562 = validateParameter(valid_773562, JString, required = false,
                                 default = nil)
  if valid_773562 != nil:
    section.add "X-Amz-Content-Sha256", valid_773562
  var valid_773563 = header.getOrDefault("X-Amz-Algorithm")
  valid_773563 = validateParameter(valid_773563, JString, required = false,
                                 default = nil)
  if valid_773563 != nil:
    section.add "X-Amz-Algorithm", valid_773563
  var valid_773564 = header.getOrDefault("X-Amz-Signature")
  valid_773564 = validateParameter(valid_773564, JString, required = false,
                                 default = nil)
  if valid_773564 != nil:
    section.add "X-Amz-Signature", valid_773564
  var valid_773565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773565 = validateParameter(valid_773565, JString, required = false,
                                 default = nil)
  if valid_773565 != nil:
    section.add "X-Amz-SignedHeaders", valid_773565
  var valid_773566 = header.getOrDefault("X-Amz-Credential")
  valid_773566 = validateParameter(valid_773566, JString, required = false,
                                 default = nil)
  if valid_773566 != nil:
    section.add "X-Amz-Credential", valid_773566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773568: Call_UntagResource_773556; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ## 
  let valid = call_773568.validator(path, query, header, formData, body)
  let scheme = call_773568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773568.url(scheme.get, call_773568.host, call_773568.base,
                         call_773568.route, valid.getOrDefault("path"))
  result = hook(call_773568, url, valid)

proc call*(call_773569: Call_UntagResource_773556; arn: string; body: JsonNode): Recallable =
  ## untagResource
  ## Remove tags from a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ##   arn: string (required)
  ##      : The Amazon Resource Name (ARN) of the resource that you want to remove tags from. To get the ARN, send a GET request with the resource name.
  ##   body: JObject (required)
  var path_773570 = newJObject()
  var body_773571 = newJObject()
  add(path_773570, "arn", newJString(arn))
  if body != nil:
    body_773571 = body
  result = call_773569.call(path_773570, nil, nil, nil, body_773571)

var untagResource* = Call_UntagResource_773556(name: "untagResource",
    meth: HttpMethod.HttpPut, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/tags/{arn}", validator: validate_UntagResource_773557,
    base: "/", url: url_UntagResource_773558, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_773542 = ref object of OpenApiRestCall_772597
proc url_ListTagsForResource_773544(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_773543(path: JsonNode; query: JsonNode;
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
  var valid_773545 = path.getOrDefault("arn")
  valid_773545 = validateParameter(valid_773545, JString, required = true,
                                 default = nil)
  if valid_773545 != nil:
    section.add "arn", valid_773545
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
  var valid_773546 = header.getOrDefault("X-Amz-Date")
  valid_773546 = validateParameter(valid_773546, JString, required = false,
                                 default = nil)
  if valid_773546 != nil:
    section.add "X-Amz-Date", valid_773546
  var valid_773547 = header.getOrDefault("X-Amz-Security-Token")
  valid_773547 = validateParameter(valid_773547, JString, required = false,
                                 default = nil)
  if valid_773547 != nil:
    section.add "X-Amz-Security-Token", valid_773547
  var valid_773548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773548 = validateParameter(valid_773548, JString, required = false,
                                 default = nil)
  if valid_773548 != nil:
    section.add "X-Amz-Content-Sha256", valid_773548
  var valid_773549 = header.getOrDefault("X-Amz-Algorithm")
  valid_773549 = validateParameter(valid_773549, JString, required = false,
                                 default = nil)
  if valid_773549 != nil:
    section.add "X-Amz-Algorithm", valid_773549
  var valid_773550 = header.getOrDefault("X-Amz-Signature")
  valid_773550 = validateParameter(valid_773550, JString, required = false,
                                 default = nil)
  if valid_773550 != nil:
    section.add "X-Amz-Signature", valid_773550
  var valid_773551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773551 = validateParameter(valid_773551, JString, required = false,
                                 default = nil)
  if valid_773551 != nil:
    section.add "X-Amz-SignedHeaders", valid_773551
  var valid_773552 = header.getOrDefault("X-Amz-Credential")
  valid_773552 = validateParameter(valid_773552, JString, required = false,
                                 default = nil)
  if valid_773552 != nil:
    section.add "X-Amz-Credential", valid_773552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773553: Call_ListTagsForResource_773542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the tags for a MediaConvert resource.
  ## 
  let valid = call_773553.validator(path, query, header, formData, body)
  let scheme = call_773553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773553.url(scheme.get, call_773553.host, call_773553.base,
                         call_773553.route, valid.getOrDefault("path"))
  result = hook(call_773553, url, valid)

proc call*(call_773554: Call_ListTagsForResource_773542; arn: string): Recallable =
  ## listTagsForResource
  ## Retrieve the tags for a MediaConvert resource.
  ##   arn: string (required)
  ##      : The Amazon Resource Name (ARN) of the resource that you want to list tags for. To get the ARN, send a GET request with the resource name.
  var path_773555 = newJObject()
  add(path_773555, "arn", newJString(arn))
  result = call_773554.call(path_773555, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_773542(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "mediaconvert.amazonaws.com", route: "/2017-08-29/tags/{arn}",
    validator: validate_ListTagsForResource_773543, base: "/",
    url: url_ListTagsForResource_773544, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_773572 = ref object of OpenApiRestCall_772597
proc url_TagResource_773574(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_773573(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773575 = header.getOrDefault("X-Amz-Date")
  valid_773575 = validateParameter(valid_773575, JString, required = false,
                                 default = nil)
  if valid_773575 != nil:
    section.add "X-Amz-Date", valid_773575
  var valid_773576 = header.getOrDefault("X-Amz-Security-Token")
  valid_773576 = validateParameter(valid_773576, JString, required = false,
                                 default = nil)
  if valid_773576 != nil:
    section.add "X-Amz-Security-Token", valid_773576
  var valid_773577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773577 = validateParameter(valid_773577, JString, required = false,
                                 default = nil)
  if valid_773577 != nil:
    section.add "X-Amz-Content-Sha256", valid_773577
  var valid_773578 = header.getOrDefault("X-Amz-Algorithm")
  valid_773578 = validateParameter(valid_773578, JString, required = false,
                                 default = nil)
  if valid_773578 != nil:
    section.add "X-Amz-Algorithm", valid_773578
  var valid_773579 = header.getOrDefault("X-Amz-Signature")
  valid_773579 = validateParameter(valid_773579, JString, required = false,
                                 default = nil)
  if valid_773579 != nil:
    section.add "X-Amz-Signature", valid_773579
  var valid_773580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773580 = validateParameter(valid_773580, JString, required = false,
                                 default = nil)
  if valid_773580 != nil:
    section.add "X-Amz-SignedHeaders", valid_773580
  var valid_773581 = header.getOrDefault("X-Amz-Credential")
  valid_773581 = validateParameter(valid_773581, JString, required = false,
                                 default = nil)
  if valid_773581 != nil:
    section.add "X-Amz-Credential", valid_773581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773583: Call_TagResource_773572; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add tags to a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ## 
  let valid = call_773583.validator(path, query, header, formData, body)
  let scheme = call_773583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773583.url(scheme.get, call_773583.host, call_773583.base,
                         call_773583.route, valid.getOrDefault("path"))
  result = hook(call_773583, url, valid)

proc call*(call_773584: Call_TagResource_773572; body: JsonNode): Recallable =
  ## tagResource
  ## Add tags to a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ##   body: JObject (required)
  var body_773585 = newJObject()
  if body != nil:
    body_773585 = body
  result = call_773584.call(nil, nil, nil, nil, body_773585)

var tagResource* = Call_TagResource_773572(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/tags",
                                        validator: validate_TagResource_773573,
                                        base: "/", url: url_TagResource_773574,
                                        schemes: {Scheme.Https, Scheme.Http})
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
