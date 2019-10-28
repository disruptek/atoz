
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_590364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_590364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_590364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateCertificate_590703 = ref object of OpenApiRestCall_590364
proc url_AssociateCertificate_590705(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateCertificate_590704(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_590817 = header.getOrDefault("X-Amz-Signature")
  valid_590817 = validateParameter(valid_590817, JString, required = false,
                                 default = nil)
  if valid_590817 != nil:
    section.add "X-Amz-Signature", valid_590817
  var valid_590818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590818 = validateParameter(valid_590818, JString, required = false,
                                 default = nil)
  if valid_590818 != nil:
    section.add "X-Amz-Content-Sha256", valid_590818
  var valid_590819 = header.getOrDefault("X-Amz-Date")
  valid_590819 = validateParameter(valid_590819, JString, required = false,
                                 default = nil)
  if valid_590819 != nil:
    section.add "X-Amz-Date", valid_590819
  var valid_590820 = header.getOrDefault("X-Amz-Credential")
  valid_590820 = validateParameter(valid_590820, JString, required = false,
                                 default = nil)
  if valid_590820 != nil:
    section.add "X-Amz-Credential", valid_590820
  var valid_590821 = header.getOrDefault("X-Amz-Security-Token")
  valid_590821 = validateParameter(valid_590821, JString, required = false,
                                 default = nil)
  if valid_590821 != nil:
    section.add "X-Amz-Security-Token", valid_590821
  var valid_590822 = header.getOrDefault("X-Amz-Algorithm")
  valid_590822 = validateParameter(valid_590822, JString, required = false,
                                 default = nil)
  if valid_590822 != nil:
    section.add "X-Amz-Algorithm", valid_590822
  var valid_590823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590823 = validateParameter(valid_590823, JString, required = false,
                                 default = nil)
  if valid_590823 != nil:
    section.add "X-Amz-SignedHeaders", valid_590823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590847: Call_AssociateCertificate_590703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates an AWS Certificate Manager (ACM) Amazon Resource Name (ARN) with AWS Elemental MediaConvert.
  ## 
  let valid = call_590847.validator(path, query, header, formData, body)
  let scheme = call_590847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590847.url(scheme.get, call_590847.host, call_590847.base,
                         call_590847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590847, url, valid)

proc call*(call_590918: Call_AssociateCertificate_590703; body: JsonNode): Recallable =
  ## associateCertificate
  ## Associates an AWS Certificate Manager (ACM) Amazon Resource Name (ARN) with AWS Elemental MediaConvert.
  ##   body: JObject (required)
  var body_590919 = newJObject()
  if body != nil:
    body_590919 = body
  result = call_590918.call(nil, nil, nil, nil, body_590919)

var associateCertificate* = Call_AssociateCertificate_590703(
    name: "associateCertificate", meth: HttpMethod.HttpPost,
    host: "mediaconvert.amazonaws.com", route: "/2017-08-29/certificates",
    validator: validate_AssociateCertificate_590704, base: "/",
    url: url_AssociateCertificate_590705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_590958 = ref object of OpenApiRestCall_590364
proc url_GetJob_590960(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetJob_590959(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_590975 = path.getOrDefault("id")
  valid_590975 = validateParameter(valid_590975, JString, required = true,
                                 default = nil)
  if valid_590975 != nil:
    section.add "id", valid_590975
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
  var valid_590976 = header.getOrDefault("X-Amz-Signature")
  valid_590976 = validateParameter(valid_590976, JString, required = false,
                                 default = nil)
  if valid_590976 != nil:
    section.add "X-Amz-Signature", valid_590976
  var valid_590977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590977 = validateParameter(valid_590977, JString, required = false,
                                 default = nil)
  if valid_590977 != nil:
    section.add "X-Amz-Content-Sha256", valid_590977
  var valid_590978 = header.getOrDefault("X-Amz-Date")
  valid_590978 = validateParameter(valid_590978, JString, required = false,
                                 default = nil)
  if valid_590978 != nil:
    section.add "X-Amz-Date", valid_590978
  var valid_590979 = header.getOrDefault("X-Amz-Credential")
  valid_590979 = validateParameter(valid_590979, JString, required = false,
                                 default = nil)
  if valid_590979 != nil:
    section.add "X-Amz-Credential", valid_590979
  var valid_590980 = header.getOrDefault("X-Amz-Security-Token")
  valid_590980 = validateParameter(valid_590980, JString, required = false,
                                 default = nil)
  if valid_590980 != nil:
    section.add "X-Amz-Security-Token", valid_590980
  var valid_590981 = header.getOrDefault("X-Amz-Algorithm")
  valid_590981 = validateParameter(valid_590981, JString, required = false,
                                 default = nil)
  if valid_590981 != nil:
    section.add "X-Amz-Algorithm", valid_590981
  var valid_590982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590982 = validateParameter(valid_590982, JString, required = false,
                                 default = nil)
  if valid_590982 != nil:
    section.add "X-Amz-SignedHeaders", valid_590982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_590983: Call_GetJob_590958; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the JSON for a specific completed transcoding job.
  ## 
  let valid = call_590983.validator(path, query, header, formData, body)
  let scheme = call_590983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590983.url(scheme.get, call_590983.host, call_590983.base,
                         call_590983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590983, url, valid)

proc call*(call_590984: Call_GetJob_590958; id: string): Recallable =
  ## getJob
  ## Retrieve the JSON for a specific completed transcoding job.
  ##   id: string (required)
  ##     : the job ID of the job.
  var path_590985 = newJObject()
  add(path_590985, "id", newJString(id))
  result = call_590984.call(path_590985, nil, nil, nil, nil)

var getJob* = Call_GetJob_590958(name: "getJob", meth: HttpMethod.HttpGet,
                              host: "mediaconvert.amazonaws.com",
                              route: "/2017-08-29/jobs/{id}",
                              validator: validate_GetJob_590959, base: "/",
                              url: url_GetJob_590960,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelJob_590987 = ref object of OpenApiRestCall_590364
proc url_CancelJob_590989(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_CancelJob_590988(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_590990 = path.getOrDefault("id")
  valid_590990 = validateParameter(valid_590990, JString, required = true,
                                 default = nil)
  if valid_590990 != nil:
    section.add "id", valid_590990
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
  var valid_590991 = header.getOrDefault("X-Amz-Signature")
  valid_590991 = validateParameter(valid_590991, JString, required = false,
                                 default = nil)
  if valid_590991 != nil:
    section.add "X-Amz-Signature", valid_590991
  var valid_590992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590992 = validateParameter(valid_590992, JString, required = false,
                                 default = nil)
  if valid_590992 != nil:
    section.add "X-Amz-Content-Sha256", valid_590992
  var valid_590993 = header.getOrDefault("X-Amz-Date")
  valid_590993 = validateParameter(valid_590993, JString, required = false,
                                 default = nil)
  if valid_590993 != nil:
    section.add "X-Amz-Date", valid_590993
  var valid_590994 = header.getOrDefault("X-Amz-Credential")
  valid_590994 = validateParameter(valid_590994, JString, required = false,
                                 default = nil)
  if valid_590994 != nil:
    section.add "X-Amz-Credential", valid_590994
  var valid_590995 = header.getOrDefault("X-Amz-Security-Token")
  valid_590995 = validateParameter(valid_590995, JString, required = false,
                                 default = nil)
  if valid_590995 != nil:
    section.add "X-Amz-Security-Token", valid_590995
  var valid_590996 = header.getOrDefault("X-Amz-Algorithm")
  valid_590996 = validateParameter(valid_590996, JString, required = false,
                                 default = nil)
  if valid_590996 != nil:
    section.add "X-Amz-Algorithm", valid_590996
  var valid_590997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590997 = validateParameter(valid_590997, JString, required = false,
                                 default = nil)
  if valid_590997 != nil:
    section.add "X-Amz-SignedHeaders", valid_590997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_590998: Call_CancelJob_590987; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently cancel a job. Once you have canceled a job, you can't start it again.
  ## 
  let valid = call_590998.validator(path, query, header, formData, body)
  let scheme = call_590998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590998.url(scheme.get, call_590998.host, call_590998.base,
                         call_590998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590998, url, valid)

proc call*(call_590999: Call_CancelJob_590987; id: string): Recallable =
  ## cancelJob
  ## Permanently cancel a job. Once you have canceled a job, you can't start it again.
  ##   id: string (required)
  ##     : The Job ID of the job to be cancelled.
  var path_591000 = newJObject()
  add(path_591000, "id", newJString(id))
  result = call_590999.call(path_591000, nil, nil, nil, nil)

var cancelJob* = Call_CancelJob_590987(name: "cancelJob",
                                    meth: HttpMethod.HttpDelete,
                                    host: "mediaconvert.amazonaws.com",
                                    route: "/2017-08-29/jobs/{id}",
                                    validator: validate_CancelJob_590988,
                                    base: "/", url: url_CancelJob_590989,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_591034 = ref object of OpenApiRestCall_590364
proc url_CreateJob_591036(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateJob_591035(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591037 = header.getOrDefault("X-Amz-Signature")
  valid_591037 = validateParameter(valid_591037, JString, required = false,
                                 default = nil)
  if valid_591037 != nil:
    section.add "X-Amz-Signature", valid_591037
  var valid_591038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591038 = validateParameter(valid_591038, JString, required = false,
                                 default = nil)
  if valid_591038 != nil:
    section.add "X-Amz-Content-Sha256", valid_591038
  var valid_591039 = header.getOrDefault("X-Amz-Date")
  valid_591039 = validateParameter(valid_591039, JString, required = false,
                                 default = nil)
  if valid_591039 != nil:
    section.add "X-Amz-Date", valid_591039
  var valid_591040 = header.getOrDefault("X-Amz-Credential")
  valid_591040 = validateParameter(valid_591040, JString, required = false,
                                 default = nil)
  if valid_591040 != nil:
    section.add "X-Amz-Credential", valid_591040
  var valid_591041 = header.getOrDefault("X-Amz-Security-Token")
  valid_591041 = validateParameter(valid_591041, JString, required = false,
                                 default = nil)
  if valid_591041 != nil:
    section.add "X-Amz-Security-Token", valid_591041
  var valid_591042 = header.getOrDefault("X-Amz-Algorithm")
  valid_591042 = validateParameter(valid_591042, JString, required = false,
                                 default = nil)
  if valid_591042 != nil:
    section.add "X-Amz-Algorithm", valid_591042
  var valid_591043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591043 = validateParameter(valid_591043, JString, required = false,
                                 default = nil)
  if valid_591043 != nil:
    section.add "X-Amz-SignedHeaders", valid_591043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591045: Call_CreateJob_591034; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new transcoding job. For information about jobs and job settings, see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ## 
  let valid = call_591045.validator(path, query, header, formData, body)
  let scheme = call_591045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591045.url(scheme.get, call_591045.host, call_591045.base,
                         call_591045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591045, url, valid)

proc call*(call_591046: Call_CreateJob_591034; body: JsonNode): Recallable =
  ## createJob
  ## Create a new transcoding job. For information about jobs and job settings, see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ##   body: JObject (required)
  var body_591047 = newJObject()
  if body != nil:
    body_591047 = body
  result = call_591046.call(nil, nil, nil, nil, body_591047)

var createJob* = Call_CreateJob_591034(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "mediaconvert.amazonaws.com",
                                    route: "/2017-08-29/jobs",
                                    validator: validate_CreateJob_591035,
                                    base: "/", url: url_CreateJob_591036,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_591001 = ref object of OpenApiRestCall_590364
proc url_ListJobs_591003(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListJobs_591002(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve a JSON array of up to twenty of your most recently created jobs. This array includes in-process, completed, and errored jobs. This will return the jobs themselves, not just a list of the jobs. To retrieve the twenty next most recent jobs, use the nextToken string returned with the array.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   queue: JString
  ##        : Provide a queue name to get back only jobs from that queue.
  ##   nextToken: JString
  ##            : Use this string, provided with the response to a previous request, to request the next batch of jobs.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   order: JString
  ##        : When you request lists of resources, you can optionally specify whether they are sorted in ASCENDING or DESCENDING order. Default varies by resource.
  ##   NextToken: JString
  ##            : Pagination token
  ##   status: JString
  ##         : A job's status can be SUBMITTED, PROGRESSING, COMPLETE, CANCELED, or ERROR.
  ##   maxResults: JInt
  ##             : Optional. Number of jobs, up to twenty, that will be returned at one time.
  section = newJObject()
  var valid_591004 = query.getOrDefault("queue")
  valid_591004 = validateParameter(valid_591004, JString, required = false,
                                 default = nil)
  if valid_591004 != nil:
    section.add "queue", valid_591004
  var valid_591005 = query.getOrDefault("nextToken")
  valid_591005 = validateParameter(valid_591005, JString, required = false,
                                 default = nil)
  if valid_591005 != nil:
    section.add "nextToken", valid_591005
  var valid_591006 = query.getOrDefault("MaxResults")
  valid_591006 = validateParameter(valid_591006, JString, required = false,
                                 default = nil)
  if valid_591006 != nil:
    section.add "MaxResults", valid_591006
  var valid_591020 = query.getOrDefault("order")
  valid_591020 = validateParameter(valid_591020, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_591020 != nil:
    section.add "order", valid_591020
  var valid_591021 = query.getOrDefault("NextToken")
  valid_591021 = validateParameter(valid_591021, JString, required = false,
                                 default = nil)
  if valid_591021 != nil:
    section.add "NextToken", valid_591021
  var valid_591022 = query.getOrDefault("status")
  valid_591022 = validateParameter(valid_591022, JString, required = false,
                                 default = newJString("SUBMITTED"))
  if valid_591022 != nil:
    section.add "status", valid_591022
  var valid_591023 = query.getOrDefault("maxResults")
  valid_591023 = validateParameter(valid_591023, JInt, required = false, default = nil)
  if valid_591023 != nil:
    section.add "maxResults", valid_591023
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
  var valid_591024 = header.getOrDefault("X-Amz-Signature")
  valid_591024 = validateParameter(valid_591024, JString, required = false,
                                 default = nil)
  if valid_591024 != nil:
    section.add "X-Amz-Signature", valid_591024
  var valid_591025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591025 = validateParameter(valid_591025, JString, required = false,
                                 default = nil)
  if valid_591025 != nil:
    section.add "X-Amz-Content-Sha256", valid_591025
  var valid_591026 = header.getOrDefault("X-Amz-Date")
  valid_591026 = validateParameter(valid_591026, JString, required = false,
                                 default = nil)
  if valid_591026 != nil:
    section.add "X-Amz-Date", valid_591026
  var valid_591027 = header.getOrDefault("X-Amz-Credential")
  valid_591027 = validateParameter(valid_591027, JString, required = false,
                                 default = nil)
  if valid_591027 != nil:
    section.add "X-Amz-Credential", valid_591027
  var valid_591028 = header.getOrDefault("X-Amz-Security-Token")
  valid_591028 = validateParameter(valid_591028, JString, required = false,
                                 default = nil)
  if valid_591028 != nil:
    section.add "X-Amz-Security-Token", valid_591028
  var valid_591029 = header.getOrDefault("X-Amz-Algorithm")
  valid_591029 = validateParameter(valid_591029, JString, required = false,
                                 default = nil)
  if valid_591029 != nil:
    section.add "X-Amz-Algorithm", valid_591029
  var valid_591030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591030 = validateParameter(valid_591030, JString, required = false,
                                 default = nil)
  if valid_591030 != nil:
    section.add "X-Amz-SignedHeaders", valid_591030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591031: Call_ListJobs_591001; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a JSON array of up to twenty of your most recently created jobs. This array includes in-process, completed, and errored jobs. This will return the jobs themselves, not just a list of the jobs. To retrieve the twenty next most recent jobs, use the nextToken string returned with the array.
  ## 
  let valid = call_591031.validator(path, query, header, formData, body)
  let scheme = call_591031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591031.url(scheme.get, call_591031.host, call_591031.base,
                         call_591031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591031, url, valid)

proc call*(call_591032: Call_ListJobs_591001; queue: string = "";
          nextToken: string = ""; MaxResults: string = ""; order: string = "ASCENDING";
          NextToken: string = ""; status: string = "SUBMITTED"; maxResults: int = 0): Recallable =
  ## listJobs
  ## Retrieve a JSON array of up to twenty of your most recently created jobs. This array includes in-process, completed, and errored jobs. This will return the jobs themselves, not just a list of the jobs. To retrieve the twenty next most recent jobs, use the nextToken string returned with the array.
  ##   queue: string
  ##        : Provide a queue name to get back only jobs from that queue.
  ##   nextToken: string
  ##            : Use this string, provided with the response to a previous request, to request the next batch of jobs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   order: string
  ##        : When you request lists of resources, you can optionally specify whether they are sorted in ASCENDING or DESCENDING order. Default varies by resource.
  ##   NextToken: string
  ##            : Pagination token
  ##   status: string
  ##         : A job's status can be SUBMITTED, PROGRESSING, COMPLETE, CANCELED, or ERROR.
  ##   maxResults: int
  ##             : Optional. Number of jobs, up to twenty, that will be returned at one time.
  var query_591033 = newJObject()
  add(query_591033, "queue", newJString(queue))
  add(query_591033, "nextToken", newJString(nextToken))
  add(query_591033, "MaxResults", newJString(MaxResults))
  add(query_591033, "order", newJString(order))
  add(query_591033, "NextToken", newJString(NextToken))
  add(query_591033, "status", newJString(status))
  add(query_591033, "maxResults", newJInt(maxResults))
  result = call_591032.call(nil, query_591033, nil, nil, nil)

var listJobs* = Call_ListJobs_591001(name: "listJobs", meth: HttpMethod.HttpGet,
                                  host: "mediaconvert.amazonaws.com",
                                  route: "/2017-08-29/jobs",
                                  validator: validate_ListJobs_591002, base: "/",
                                  url: url_ListJobs_591003,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJobTemplate_591068 = ref object of OpenApiRestCall_590364
proc url_CreateJobTemplate_591070(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateJobTemplate_591069(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591071 = header.getOrDefault("X-Amz-Signature")
  valid_591071 = validateParameter(valid_591071, JString, required = false,
                                 default = nil)
  if valid_591071 != nil:
    section.add "X-Amz-Signature", valid_591071
  var valid_591072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591072 = validateParameter(valid_591072, JString, required = false,
                                 default = nil)
  if valid_591072 != nil:
    section.add "X-Amz-Content-Sha256", valid_591072
  var valid_591073 = header.getOrDefault("X-Amz-Date")
  valid_591073 = validateParameter(valid_591073, JString, required = false,
                                 default = nil)
  if valid_591073 != nil:
    section.add "X-Amz-Date", valid_591073
  var valid_591074 = header.getOrDefault("X-Amz-Credential")
  valid_591074 = validateParameter(valid_591074, JString, required = false,
                                 default = nil)
  if valid_591074 != nil:
    section.add "X-Amz-Credential", valid_591074
  var valid_591075 = header.getOrDefault("X-Amz-Security-Token")
  valid_591075 = validateParameter(valid_591075, JString, required = false,
                                 default = nil)
  if valid_591075 != nil:
    section.add "X-Amz-Security-Token", valid_591075
  var valid_591076 = header.getOrDefault("X-Amz-Algorithm")
  valid_591076 = validateParameter(valid_591076, JString, required = false,
                                 default = nil)
  if valid_591076 != nil:
    section.add "X-Amz-Algorithm", valid_591076
  var valid_591077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591077 = validateParameter(valid_591077, JString, required = false,
                                 default = nil)
  if valid_591077 != nil:
    section.add "X-Amz-SignedHeaders", valid_591077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591079: Call_CreateJobTemplate_591068; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new job template. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ## 
  let valid = call_591079.validator(path, query, header, formData, body)
  let scheme = call_591079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591079.url(scheme.get, call_591079.host, call_591079.base,
                         call_591079.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591079, url, valid)

proc call*(call_591080: Call_CreateJobTemplate_591068; body: JsonNode): Recallable =
  ## createJobTemplate
  ## Create a new job template. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ##   body: JObject (required)
  var body_591081 = newJObject()
  if body != nil:
    body_591081 = body
  result = call_591080.call(nil, nil, nil, nil, body_591081)

var createJobTemplate* = Call_CreateJobTemplate_591068(name: "createJobTemplate",
    meth: HttpMethod.HttpPost, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates", validator: validate_CreateJobTemplate_591069,
    base: "/", url: url_CreateJobTemplate_591070,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobTemplates_591048 = ref object of OpenApiRestCall_590364
proc url_ListJobTemplates_591050(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListJobTemplates_591049(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieve a JSON array of up to twenty of your job templates. This will return the templates themselves, not just a list of them. To retrieve the next twenty templates, use the nextToken string returned with the array
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Use this string, provided with the response to a previous request, to request the next batch of job templates.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   listBy: JString
  ##         : Optional. When you request a list of job templates, you can choose to list them alphabetically by NAME or chronologically by CREATION_DATE. If you don't specify, the service will list them by name.
  ##   order: JString
  ##        : When you request lists of resources, you can optionally specify whether they are sorted in ASCENDING or DESCENDING order. Default varies by resource.
  ##   NextToken: JString
  ##            : Pagination token
  ##   category: JString
  ##           : Optionally, specify a job template category to limit responses to only job templates from that category.
  ##   maxResults: JInt
  ##             : Optional. Number of job templates, up to twenty, that will be returned at one time.
  section = newJObject()
  var valid_591051 = query.getOrDefault("nextToken")
  valid_591051 = validateParameter(valid_591051, JString, required = false,
                                 default = nil)
  if valid_591051 != nil:
    section.add "nextToken", valid_591051
  var valid_591052 = query.getOrDefault("MaxResults")
  valid_591052 = validateParameter(valid_591052, JString, required = false,
                                 default = nil)
  if valid_591052 != nil:
    section.add "MaxResults", valid_591052
  var valid_591053 = query.getOrDefault("listBy")
  valid_591053 = validateParameter(valid_591053, JString, required = false,
                                 default = newJString("NAME"))
  if valid_591053 != nil:
    section.add "listBy", valid_591053
  var valid_591054 = query.getOrDefault("order")
  valid_591054 = validateParameter(valid_591054, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_591054 != nil:
    section.add "order", valid_591054
  var valid_591055 = query.getOrDefault("NextToken")
  valid_591055 = validateParameter(valid_591055, JString, required = false,
                                 default = nil)
  if valid_591055 != nil:
    section.add "NextToken", valid_591055
  var valid_591056 = query.getOrDefault("category")
  valid_591056 = validateParameter(valid_591056, JString, required = false,
                                 default = nil)
  if valid_591056 != nil:
    section.add "category", valid_591056
  var valid_591057 = query.getOrDefault("maxResults")
  valid_591057 = validateParameter(valid_591057, JInt, required = false, default = nil)
  if valid_591057 != nil:
    section.add "maxResults", valid_591057
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
  var valid_591058 = header.getOrDefault("X-Amz-Signature")
  valid_591058 = validateParameter(valid_591058, JString, required = false,
                                 default = nil)
  if valid_591058 != nil:
    section.add "X-Amz-Signature", valid_591058
  var valid_591059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591059 = validateParameter(valid_591059, JString, required = false,
                                 default = nil)
  if valid_591059 != nil:
    section.add "X-Amz-Content-Sha256", valid_591059
  var valid_591060 = header.getOrDefault("X-Amz-Date")
  valid_591060 = validateParameter(valid_591060, JString, required = false,
                                 default = nil)
  if valid_591060 != nil:
    section.add "X-Amz-Date", valid_591060
  var valid_591061 = header.getOrDefault("X-Amz-Credential")
  valid_591061 = validateParameter(valid_591061, JString, required = false,
                                 default = nil)
  if valid_591061 != nil:
    section.add "X-Amz-Credential", valid_591061
  var valid_591062 = header.getOrDefault("X-Amz-Security-Token")
  valid_591062 = validateParameter(valid_591062, JString, required = false,
                                 default = nil)
  if valid_591062 != nil:
    section.add "X-Amz-Security-Token", valid_591062
  var valid_591063 = header.getOrDefault("X-Amz-Algorithm")
  valid_591063 = validateParameter(valid_591063, JString, required = false,
                                 default = nil)
  if valid_591063 != nil:
    section.add "X-Amz-Algorithm", valid_591063
  var valid_591064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591064 = validateParameter(valid_591064, JString, required = false,
                                 default = nil)
  if valid_591064 != nil:
    section.add "X-Amz-SignedHeaders", valid_591064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591065: Call_ListJobTemplates_591048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a JSON array of up to twenty of your job templates. This will return the templates themselves, not just a list of them. To retrieve the next twenty templates, use the nextToken string returned with the array
  ## 
  let valid = call_591065.validator(path, query, header, formData, body)
  let scheme = call_591065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591065.url(scheme.get, call_591065.host, call_591065.base,
                         call_591065.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591065, url, valid)

proc call*(call_591066: Call_ListJobTemplates_591048; nextToken: string = "";
          MaxResults: string = ""; listBy: string = "NAME"; order: string = "ASCENDING";
          NextToken: string = ""; category: string = ""; maxResults: int = 0): Recallable =
  ## listJobTemplates
  ## Retrieve a JSON array of up to twenty of your job templates. This will return the templates themselves, not just a list of them. To retrieve the next twenty templates, use the nextToken string returned with the array
  ##   nextToken: string
  ##            : Use this string, provided with the response to a previous request, to request the next batch of job templates.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   listBy: string
  ##         : Optional. When you request a list of job templates, you can choose to list them alphabetically by NAME or chronologically by CREATION_DATE. If you don't specify, the service will list them by name.
  ##   order: string
  ##        : When you request lists of resources, you can optionally specify whether they are sorted in ASCENDING or DESCENDING order. Default varies by resource.
  ##   NextToken: string
  ##            : Pagination token
  ##   category: string
  ##           : Optionally, specify a job template category to limit responses to only job templates from that category.
  ##   maxResults: int
  ##             : Optional. Number of job templates, up to twenty, that will be returned at one time.
  var query_591067 = newJObject()
  add(query_591067, "nextToken", newJString(nextToken))
  add(query_591067, "MaxResults", newJString(MaxResults))
  add(query_591067, "listBy", newJString(listBy))
  add(query_591067, "order", newJString(order))
  add(query_591067, "NextToken", newJString(NextToken))
  add(query_591067, "category", newJString(category))
  add(query_591067, "maxResults", newJInt(maxResults))
  result = call_591066.call(nil, query_591067, nil, nil, nil)

var listJobTemplates* = Call_ListJobTemplates_591048(name: "listJobTemplates",
    meth: HttpMethod.HttpGet, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates", validator: validate_ListJobTemplates_591049,
    base: "/", url: url_ListJobTemplates_591050,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePreset_591102 = ref object of OpenApiRestCall_590364
proc url_CreatePreset_591104(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePreset_591103(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591105 = header.getOrDefault("X-Amz-Signature")
  valid_591105 = validateParameter(valid_591105, JString, required = false,
                                 default = nil)
  if valid_591105 != nil:
    section.add "X-Amz-Signature", valid_591105
  var valid_591106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591106 = validateParameter(valid_591106, JString, required = false,
                                 default = nil)
  if valid_591106 != nil:
    section.add "X-Amz-Content-Sha256", valid_591106
  var valid_591107 = header.getOrDefault("X-Amz-Date")
  valid_591107 = validateParameter(valid_591107, JString, required = false,
                                 default = nil)
  if valid_591107 != nil:
    section.add "X-Amz-Date", valid_591107
  var valid_591108 = header.getOrDefault("X-Amz-Credential")
  valid_591108 = validateParameter(valid_591108, JString, required = false,
                                 default = nil)
  if valid_591108 != nil:
    section.add "X-Amz-Credential", valid_591108
  var valid_591109 = header.getOrDefault("X-Amz-Security-Token")
  valid_591109 = validateParameter(valid_591109, JString, required = false,
                                 default = nil)
  if valid_591109 != nil:
    section.add "X-Amz-Security-Token", valid_591109
  var valid_591110 = header.getOrDefault("X-Amz-Algorithm")
  valid_591110 = validateParameter(valid_591110, JString, required = false,
                                 default = nil)
  if valid_591110 != nil:
    section.add "X-Amz-Algorithm", valid_591110
  var valid_591111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591111 = validateParameter(valid_591111, JString, required = false,
                                 default = nil)
  if valid_591111 != nil:
    section.add "X-Amz-SignedHeaders", valid_591111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591113: Call_CreatePreset_591102; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new preset. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ## 
  let valid = call_591113.validator(path, query, header, formData, body)
  let scheme = call_591113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591113.url(scheme.get, call_591113.host, call_591113.base,
                         call_591113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591113, url, valid)

proc call*(call_591114: Call_CreatePreset_591102; body: JsonNode): Recallable =
  ## createPreset
  ## Create a new preset. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ##   body: JObject (required)
  var body_591115 = newJObject()
  if body != nil:
    body_591115 = body
  result = call_591114.call(nil, nil, nil, nil, body_591115)

var createPreset* = Call_CreatePreset_591102(name: "createPreset",
    meth: HttpMethod.HttpPost, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/presets", validator: validate_CreatePreset_591103,
    base: "/", url: url_CreatePreset_591104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPresets_591082 = ref object of OpenApiRestCall_590364
proc url_ListPresets_591084(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPresets_591083(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve a JSON array of up to twenty of your presets. This will return the presets themselves, not just a list of them. To retrieve the next twenty presets, use the nextToken string returned with the array.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Use this string, provided with the response to a previous request, to request the next batch of presets.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   listBy: JString
  ##         : Optional. When you request a list of presets, you can choose to list them alphabetically by NAME or chronologically by CREATION_DATE. If you don't specify, the service will list them by name.
  ##   order: JString
  ##        : When you request lists of resources, you can optionally specify whether they are sorted in ASCENDING or DESCENDING order. Default varies by resource.
  ##   NextToken: JString
  ##            : Pagination token
  ##   category: JString
  ##           : Optionally, specify a preset category to limit responses to only presets from that category.
  ##   maxResults: JInt
  ##             : Optional. Number of presets, up to twenty, that will be returned at one time
  section = newJObject()
  var valid_591085 = query.getOrDefault("nextToken")
  valid_591085 = validateParameter(valid_591085, JString, required = false,
                                 default = nil)
  if valid_591085 != nil:
    section.add "nextToken", valid_591085
  var valid_591086 = query.getOrDefault("MaxResults")
  valid_591086 = validateParameter(valid_591086, JString, required = false,
                                 default = nil)
  if valid_591086 != nil:
    section.add "MaxResults", valid_591086
  var valid_591087 = query.getOrDefault("listBy")
  valid_591087 = validateParameter(valid_591087, JString, required = false,
                                 default = newJString("NAME"))
  if valid_591087 != nil:
    section.add "listBy", valid_591087
  var valid_591088 = query.getOrDefault("order")
  valid_591088 = validateParameter(valid_591088, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_591088 != nil:
    section.add "order", valid_591088
  var valid_591089 = query.getOrDefault("NextToken")
  valid_591089 = validateParameter(valid_591089, JString, required = false,
                                 default = nil)
  if valid_591089 != nil:
    section.add "NextToken", valid_591089
  var valid_591090 = query.getOrDefault("category")
  valid_591090 = validateParameter(valid_591090, JString, required = false,
                                 default = nil)
  if valid_591090 != nil:
    section.add "category", valid_591090
  var valid_591091 = query.getOrDefault("maxResults")
  valid_591091 = validateParameter(valid_591091, JInt, required = false, default = nil)
  if valid_591091 != nil:
    section.add "maxResults", valid_591091
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
  var valid_591092 = header.getOrDefault("X-Amz-Signature")
  valid_591092 = validateParameter(valid_591092, JString, required = false,
                                 default = nil)
  if valid_591092 != nil:
    section.add "X-Amz-Signature", valid_591092
  var valid_591093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591093 = validateParameter(valid_591093, JString, required = false,
                                 default = nil)
  if valid_591093 != nil:
    section.add "X-Amz-Content-Sha256", valid_591093
  var valid_591094 = header.getOrDefault("X-Amz-Date")
  valid_591094 = validateParameter(valid_591094, JString, required = false,
                                 default = nil)
  if valid_591094 != nil:
    section.add "X-Amz-Date", valid_591094
  var valid_591095 = header.getOrDefault("X-Amz-Credential")
  valid_591095 = validateParameter(valid_591095, JString, required = false,
                                 default = nil)
  if valid_591095 != nil:
    section.add "X-Amz-Credential", valid_591095
  var valid_591096 = header.getOrDefault("X-Amz-Security-Token")
  valid_591096 = validateParameter(valid_591096, JString, required = false,
                                 default = nil)
  if valid_591096 != nil:
    section.add "X-Amz-Security-Token", valid_591096
  var valid_591097 = header.getOrDefault("X-Amz-Algorithm")
  valid_591097 = validateParameter(valid_591097, JString, required = false,
                                 default = nil)
  if valid_591097 != nil:
    section.add "X-Amz-Algorithm", valid_591097
  var valid_591098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591098 = validateParameter(valid_591098, JString, required = false,
                                 default = nil)
  if valid_591098 != nil:
    section.add "X-Amz-SignedHeaders", valid_591098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591099: Call_ListPresets_591082; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a JSON array of up to twenty of your presets. This will return the presets themselves, not just a list of them. To retrieve the next twenty presets, use the nextToken string returned with the array.
  ## 
  let valid = call_591099.validator(path, query, header, formData, body)
  let scheme = call_591099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591099.url(scheme.get, call_591099.host, call_591099.base,
                         call_591099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591099, url, valid)

proc call*(call_591100: Call_ListPresets_591082; nextToken: string = "";
          MaxResults: string = ""; listBy: string = "NAME"; order: string = "ASCENDING";
          NextToken: string = ""; category: string = ""; maxResults: int = 0): Recallable =
  ## listPresets
  ## Retrieve a JSON array of up to twenty of your presets. This will return the presets themselves, not just a list of them. To retrieve the next twenty presets, use the nextToken string returned with the array.
  ##   nextToken: string
  ##            : Use this string, provided with the response to a previous request, to request the next batch of presets.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   listBy: string
  ##         : Optional. When you request a list of presets, you can choose to list them alphabetically by NAME or chronologically by CREATION_DATE. If you don't specify, the service will list them by name.
  ##   order: string
  ##        : When you request lists of resources, you can optionally specify whether they are sorted in ASCENDING or DESCENDING order. Default varies by resource.
  ##   NextToken: string
  ##            : Pagination token
  ##   category: string
  ##           : Optionally, specify a preset category to limit responses to only presets from that category.
  ##   maxResults: int
  ##             : Optional. Number of presets, up to twenty, that will be returned at one time
  var query_591101 = newJObject()
  add(query_591101, "nextToken", newJString(nextToken))
  add(query_591101, "MaxResults", newJString(MaxResults))
  add(query_591101, "listBy", newJString(listBy))
  add(query_591101, "order", newJString(order))
  add(query_591101, "NextToken", newJString(NextToken))
  add(query_591101, "category", newJString(category))
  add(query_591101, "maxResults", newJInt(maxResults))
  result = call_591100.call(nil, query_591101, nil, nil, nil)

var listPresets* = Call_ListPresets_591082(name: "listPresets",
                                        meth: HttpMethod.HttpGet,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/presets",
                                        validator: validate_ListPresets_591083,
                                        base: "/", url: url_ListPresets_591084,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateQueue_591135 = ref object of OpenApiRestCall_590364
proc url_CreateQueue_591137(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateQueue_591136(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591138 = header.getOrDefault("X-Amz-Signature")
  valid_591138 = validateParameter(valid_591138, JString, required = false,
                                 default = nil)
  if valid_591138 != nil:
    section.add "X-Amz-Signature", valid_591138
  var valid_591139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591139 = validateParameter(valid_591139, JString, required = false,
                                 default = nil)
  if valid_591139 != nil:
    section.add "X-Amz-Content-Sha256", valid_591139
  var valid_591140 = header.getOrDefault("X-Amz-Date")
  valid_591140 = validateParameter(valid_591140, JString, required = false,
                                 default = nil)
  if valid_591140 != nil:
    section.add "X-Amz-Date", valid_591140
  var valid_591141 = header.getOrDefault("X-Amz-Credential")
  valid_591141 = validateParameter(valid_591141, JString, required = false,
                                 default = nil)
  if valid_591141 != nil:
    section.add "X-Amz-Credential", valid_591141
  var valid_591142 = header.getOrDefault("X-Amz-Security-Token")
  valid_591142 = validateParameter(valid_591142, JString, required = false,
                                 default = nil)
  if valid_591142 != nil:
    section.add "X-Amz-Security-Token", valid_591142
  var valid_591143 = header.getOrDefault("X-Amz-Algorithm")
  valid_591143 = validateParameter(valid_591143, JString, required = false,
                                 default = nil)
  if valid_591143 != nil:
    section.add "X-Amz-Algorithm", valid_591143
  var valid_591144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591144 = validateParameter(valid_591144, JString, required = false,
                                 default = nil)
  if valid_591144 != nil:
    section.add "X-Amz-SignedHeaders", valid_591144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591146: Call_CreateQueue_591135; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new transcoding queue. For information about queues, see Working With Queues in the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/working-with-queues.html
  ## 
  let valid = call_591146.validator(path, query, header, formData, body)
  let scheme = call_591146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591146.url(scheme.get, call_591146.host, call_591146.base,
                         call_591146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591146, url, valid)

proc call*(call_591147: Call_CreateQueue_591135; body: JsonNode): Recallable =
  ## createQueue
  ## Create a new transcoding queue. For information about queues, see Working With Queues in the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/working-with-queues.html
  ##   body: JObject (required)
  var body_591148 = newJObject()
  if body != nil:
    body_591148 = body
  result = call_591147.call(nil, nil, nil, nil, body_591148)

var createQueue* = Call_CreateQueue_591135(name: "createQueue",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/queues",
                                        validator: validate_CreateQueue_591136,
                                        base: "/", url: url_CreateQueue_591137,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQueues_591116 = ref object of OpenApiRestCall_590364
proc url_ListQueues_591118(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListQueues_591117(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve a JSON array of up to twenty of your queues. This will return the queues themselves, not just a list of them. To retrieve the next twenty queues, use the nextToken string returned with the array.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Use this string, provided with the response to a previous request, to request the next batch of queues.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   listBy: JString
  ##         : Optional. When you request a list of queues, you can choose to list them alphabetically by NAME or chronologically by CREATION_DATE. If you don't specify, the service will list them by creation date.
  ##   order: JString
  ##        : When you request lists of resources, you can optionally specify whether they are sorted in ASCENDING or DESCENDING order. Default varies by resource.
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Optional. Number of queues, up to twenty, that will be returned at one time.
  section = newJObject()
  var valid_591119 = query.getOrDefault("nextToken")
  valid_591119 = validateParameter(valid_591119, JString, required = false,
                                 default = nil)
  if valid_591119 != nil:
    section.add "nextToken", valid_591119
  var valid_591120 = query.getOrDefault("MaxResults")
  valid_591120 = validateParameter(valid_591120, JString, required = false,
                                 default = nil)
  if valid_591120 != nil:
    section.add "MaxResults", valid_591120
  var valid_591121 = query.getOrDefault("listBy")
  valid_591121 = validateParameter(valid_591121, JString, required = false,
                                 default = newJString("NAME"))
  if valid_591121 != nil:
    section.add "listBy", valid_591121
  var valid_591122 = query.getOrDefault("order")
  valid_591122 = validateParameter(valid_591122, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_591122 != nil:
    section.add "order", valid_591122
  var valid_591123 = query.getOrDefault("NextToken")
  valid_591123 = validateParameter(valid_591123, JString, required = false,
                                 default = nil)
  if valid_591123 != nil:
    section.add "NextToken", valid_591123
  var valid_591124 = query.getOrDefault("maxResults")
  valid_591124 = validateParameter(valid_591124, JInt, required = false, default = nil)
  if valid_591124 != nil:
    section.add "maxResults", valid_591124
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
  var valid_591125 = header.getOrDefault("X-Amz-Signature")
  valid_591125 = validateParameter(valid_591125, JString, required = false,
                                 default = nil)
  if valid_591125 != nil:
    section.add "X-Amz-Signature", valid_591125
  var valid_591126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591126 = validateParameter(valid_591126, JString, required = false,
                                 default = nil)
  if valid_591126 != nil:
    section.add "X-Amz-Content-Sha256", valid_591126
  var valid_591127 = header.getOrDefault("X-Amz-Date")
  valid_591127 = validateParameter(valid_591127, JString, required = false,
                                 default = nil)
  if valid_591127 != nil:
    section.add "X-Amz-Date", valid_591127
  var valid_591128 = header.getOrDefault("X-Amz-Credential")
  valid_591128 = validateParameter(valid_591128, JString, required = false,
                                 default = nil)
  if valid_591128 != nil:
    section.add "X-Amz-Credential", valid_591128
  var valid_591129 = header.getOrDefault("X-Amz-Security-Token")
  valid_591129 = validateParameter(valid_591129, JString, required = false,
                                 default = nil)
  if valid_591129 != nil:
    section.add "X-Amz-Security-Token", valid_591129
  var valid_591130 = header.getOrDefault("X-Amz-Algorithm")
  valid_591130 = validateParameter(valid_591130, JString, required = false,
                                 default = nil)
  if valid_591130 != nil:
    section.add "X-Amz-Algorithm", valid_591130
  var valid_591131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591131 = validateParameter(valid_591131, JString, required = false,
                                 default = nil)
  if valid_591131 != nil:
    section.add "X-Amz-SignedHeaders", valid_591131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591132: Call_ListQueues_591116; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a JSON array of up to twenty of your queues. This will return the queues themselves, not just a list of them. To retrieve the next twenty queues, use the nextToken string returned with the array.
  ## 
  let valid = call_591132.validator(path, query, header, formData, body)
  let scheme = call_591132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591132.url(scheme.get, call_591132.host, call_591132.base,
                         call_591132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591132, url, valid)

proc call*(call_591133: Call_ListQueues_591116; nextToken: string = "";
          MaxResults: string = ""; listBy: string = "NAME"; order: string = "ASCENDING";
          NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listQueues
  ## Retrieve a JSON array of up to twenty of your queues. This will return the queues themselves, not just a list of them. To retrieve the next twenty queues, use the nextToken string returned with the array.
  ##   nextToken: string
  ##            : Use this string, provided with the response to a previous request, to request the next batch of queues.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   listBy: string
  ##         : Optional. When you request a list of queues, you can choose to list them alphabetically by NAME or chronologically by CREATION_DATE. If you don't specify, the service will list them by creation date.
  ##   order: string
  ##        : When you request lists of resources, you can optionally specify whether they are sorted in ASCENDING or DESCENDING order. Default varies by resource.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Optional. Number of queues, up to twenty, that will be returned at one time.
  var query_591134 = newJObject()
  add(query_591134, "nextToken", newJString(nextToken))
  add(query_591134, "MaxResults", newJString(MaxResults))
  add(query_591134, "listBy", newJString(listBy))
  add(query_591134, "order", newJString(order))
  add(query_591134, "NextToken", newJString(NextToken))
  add(query_591134, "maxResults", newJInt(maxResults))
  result = call_591133.call(nil, query_591134, nil, nil, nil)

var listQueues* = Call_ListQueues_591116(name: "listQueues",
                                      meth: HttpMethod.HttpGet,
                                      host: "mediaconvert.amazonaws.com",
                                      route: "/2017-08-29/queues",
                                      validator: validate_ListQueues_591117,
                                      base: "/", url: url_ListQueues_591118,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJobTemplate_591163 = ref object of OpenApiRestCall_590364
proc url_UpdateJobTemplate_591165(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateJobTemplate_591164(path: JsonNode; query: JsonNode;
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
  var valid_591166 = path.getOrDefault("name")
  valid_591166 = validateParameter(valid_591166, JString, required = true,
                                 default = nil)
  if valid_591166 != nil:
    section.add "name", valid_591166
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
  var valid_591167 = header.getOrDefault("X-Amz-Signature")
  valid_591167 = validateParameter(valid_591167, JString, required = false,
                                 default = nil)
  if valid_591167 != nil:
    section.add "X-Amz-Signature", valid_591167
  var valid_591168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591168 = validateParameter(valid_591168, JString, required = false,
                                 default = nil)
  if valid_591168 != nil:
    section.add "X-Amz-Content-Sha256", valid_591168
  var valid_591169 = header.getOrDefault("X-Amz-Date")
  valid_591169 = validateParameter(valid_591169, JString, required = false,
                                 default = nil)
  if valid_591169 != nil:
    section.add "X-Amz-Date", valid_591169
  var valid_591170 = header.getOrDefault("X-Amz-Credential")
  valid_591170 = validateParameter(valid_591170, JString, required = false,
                                 default = nil)
  if valid_591170 != nil:
    section.add "X-Amz-Credential", valid_591170
  var valid_591171 = header.getOrDefault("X-Amz-Security-Token")
  valid_591171 = validateParameter(valid_591171, JString, required = false,
                                 default = nil)
  if valid_591171 != nil:
    section.add "X-Amz-Security-Token", valid_591171
  var valid_591172 = header.getOrDefault("X-Amz-Algorithm")
  valid_591172 = validateParameter(valid_591172, JString, required = false,
                                 default = nil)
  if valid_591172 != nil:
    section.add "X-Amz-Algorithm", valid_591172
  var valid_591173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591173 = validateParameter(valid_591173, JString, required = false,
                                 default = nil)
  if valid_591173 != nil:
    section.add "X-Amz-SignedHeaders", valid_591173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591175: Call_UpdateJobTemplate_591163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modify one of your existing job templates.
  ## 
  let valid = call_591175.validator(path, query, header, formData, body)
  let scheme = call_591175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591175.url(scheme.get, call_591175.host, call_591175.base,
                         call_591175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591175, url, valid)

proc call*(call_591176: Call_UpdateJobTemplate_591163; name: string; body: JsonNode): Recallable =
  ## updateJobTemplate
  ## Modify one of your existing job templates.
  ##   name: string (required)
  ##       : The name of the job template you are modifying
  ##   body: JObject (required)
  var path_591177 = newJObject()
  var body_591178 = newJObject()
  add(path_591177, "name", newJString(name))
  if body != nil:
    body_591178 = body
  result = call_591176.call(path_591177, nil, nil, nil, body_591178)

var updateJobTemplate* = Call_UpdateJobTemplate_591163(name: "updateJobTemplate",
    meth: HttpMethod.HttpPut, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates/{name}",
    validator: validate_UpdateJobTemplate_591164, base: "/",
    url: url_UpdateJobTemplate_591165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobTemplate_591149 = ref object of OpenApiRestCall_590364
proc url_GetJobTemplate_591151(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetJobTemplate_591150(path: JsonNode; query: JsonNode;
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
  var valid_591152 = path.getOrDefault("name")
  valid_591152 = validateParameter(valid_591152, JString, required = true,
                                 default = nil)
  if valid_591152 != nil:
    section.add "name", valid_591152
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
  var valid_591153 = header.getOrDefault("X-Amz-Signature")
  valid_591153 = validateParameter(valid_591153, JString, required = false,
                                 default = nil)
  if valid_591153 != nil:
    section.add "X-Amz-Signature", valid_591153
  var valid_591154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591154 = validateParameter(valid_591154, JString, required = false,
                                 default = nil)
  if valid_591154 != nil:
    section.add "X-Amz-Content-Sha256", valid_591154
  var valid_591155 = header.getOrDefault("X-Amz-Date")
  valid_591155 = validateParameter(valid_591155, JString, required = false,
                                 default = nil)
  if valid_591155 != nil:
    section.add "X-Amz-Date", valid_591155
  var valid_591156 = header.getOrDefault("X-Amz-Credential")
  valid_591156 = validateParameter(valid_591156, JString, required = false,
                                 default = nil)
  if valid_591156 != nil:
    section.add "X-Amz-Credential", valid_591156
  var valid_591157 = header.getOrDefault("X-Amz-Security-Token")
  valid_591157 = validateParameter(valid_591157, JString, required = false,
                                 default = nil)
  if valid_591157 != nil:
    section.add "X-Amz-Security-Token", valid_591157
  var valid_591158 = header.getOrDefault("X-Amz-Algorithm")
  valid_591158 = validateParameter(valid_591158, JString, required = false,
                                 default = nil)
  if valid_591158 != nil:
    section.add "X-Amz-Algorithm", valid_591158
  var valid_591159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591159 = validateParameter(valid_591159, JString, required = false,
                                 default = nil)
  if valid_591159 != nil:
    section.add "X-Amz-SignedHeaders", valid_591159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591160: Call_GetJobTemplate_591149; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the JSON for a specific job template.
  ## 
  let valid = call_591160.validator(path, query, header, formData, body)
  let scheme = call_591160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591160.url(scheme.get, call_591160.host, call_591160.base,
                         call_591160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591160, url, valid)

proc call*(call_591161: Call_GetJobTemplate_591149; name: string): Recallable =
  ## getJobTemplate
  ## Retrieve the JSON for a specific job template.
  ##   name: string (required)
  ##       : The name of the job template.
  var path_591162 = newJObject()
  add(path_591162, "name", newJString(name))
  result = call_591161.call(path_591162, nil, nil, nil, nil)

var getJobTemplate* = Call_GetJobTemplate_591149(name: "getJobTemplate",
    meth: HttpMethod.HttpGet, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates/{name}", validator: validate_GetJobTemplate_591150,
    base: "/", url: url_GetJobTemplate_591151, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJobTemplate_591179 = ref object of OpenApiRestCall_590364
proc url_DeleteJobTemplate_591181(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteJobTemplate_591180(path: JsonNode; query: JsonNode;
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
  var valid_591182 = path.getOrDefault("name")
  valid_591182 = validateParameter(valid_591182, JString, required = true,
                                 default = nil)
  if valid_591182 != nil:
    section.add "name", valid_591182
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
  var valid_591183 = header.getOrDefault("X-Amz-Signature")
  valid_591183 = validateParameter(valid_591183, JString, required = false,
                                 default = nil)
  if valid_591183 != nil:
    section.add "X-Amz-Signature", valid_591183
  var valid_591184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591184 = validateParameter(valid_591184, JString, required = false,
                                 default = nil)
  if valid_591184 != nil:
    section.add "X-Amz-Content-Sha256", valid_591184
  var valid_591185 = header.getOrDefault("X-Amz-Date")
  valid_591185 = validateParameter(valid_591185, JString, required = false,
                                 default = nil)
  if valid_591185 != nil:
    section.add "X-Amz-Date", valid_591185
  var valid_591186 = header.getOrDefault("X-Amz-Credential")
  valid_591186 = validateParameter(valid_591186, JString, required = false,
                                 default = nil)
  if valid_591186 != nil:
    section.add "X-Amz-Credential", valid_591186
  var valid_591187 = header.getOrDefault("X-Amz-Security-Token")
  valid_591187 = validateParameter(valid_591187, JString, required = false,
                                 default = nil)
  if valid_591187 != nil:
    section.add "X-Amz-Security-Token", valid_591187
  var valid_591188 = header.getOrDefault("X-Amz-Algorithm")
  valid_591188 = validateParameter(valid_591188, JString, required = false,
                                 default = nil)
  if valid_591188 != nil:
    section.add "X-Amz-Algorithm", valid_591188
  var valid_591189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591189 = validateParameter(valid_591189, JString, required = false,
                                 default = nil)
  if valid_591189 != nil:
    section.add "X-Amz-SignedHeaders", valid_591189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591190: Call_DeleteJobTemplate_591179; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently delete a job template you have created.
  ## 
  let valid = call_591190.validator(path, query, header, formData, body)
  let scheme = call_591190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591190.url(scheme.get, call_591190.host, call_591190.base,
                         call_591190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591190, url, valid)

proc call*(call_591191: Call_DeleteJobTemplate_591179; name: string): Recallable =
  ## deleteJobTemplate
  ## Permanently delete a job template you have created.
  ##   name: string (required)
  ##       : The name of the job template to be deleted.
  var path_591192 = newJObject()
  add(path_591192, "name", newJString(name))
  result = call_591191.call(path_591192, nil, nil, nil, nil)

var deleteJobTemplate* = Call_DeleteJobTemplate_591179(name: "deleteJobTemplate",
    meth: HttpMethod.HttpDelete, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates/{name}",
    validator: validate_DeleteJobTemplate_591180, base: "/",
    url: url_DeleteJobTemplate_591181, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePreset_591207 = ref object of OpenApiRestCall_590364
proc url_UpdatePreset_591209(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdatePreset_591208(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591210 = path.getOrDefault("name")
  valid_591210 = validateParameter(valid_591210, JString, required = true,
                                 default = nil)
  if valid_591210 != nil:
    section.add "name", valid_591210
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
  var valid_591211 = header.getOrDefault("X-Amz-Signature")
  valid_591211 = validateParameter(valid_591211, JString, required = false,
                                 default = nil)
  if valid_591211 != nil:
    section.add "X-Amz-Signature", valid_591211
  var valid_591212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591212 = validateParameter(valid_591212, JString, required = false,
                                 default = nil)
  if valid_591212 != nil:
    section.add "X-Amz-Content-Sha256", valid_591212
  var valid_591213 = header.getOrDefault("X-Amz-Date")
  valid_591213 = validateParameter(valid_591213, JString, required = false,
                                 default = nil)
  if valid_591213 != nil:
    section.add "X-Amz-Date", valid_591213
  var valid_591214 = header.getOrDefault("X-Amz-Credential")
  valid_591214 = validateParameter(valid_591214, JString, required = false,
                                 default = nil)
  if valid_591214 != nil:
    section.add "X-Amz-Credential", valid_591214
  var valid_591215 = header.getOrDefault("X-Amz-Security-Token")
  valid_591215 = validateParameter(valid_591215, JString, required = false,
                                 default = nil)
  if valid_591215 != nil:
    section.add "X-Amz-Security-Token", valid_591215
  var valid_591216 = header.getOrDefault("X-Amz-Algorithm")
  valid_591216 = validateParameter(valid_591216, JString, required = false,
                                 default = nil)
  if valid_591216 != nil:
    section.add "X-Amz-Algorithm", valid_591216
  var valid_591217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591217 = validateParameter(valid_591217, JString, required = false,
                                 default = nil)
  if valid_591217 != nil:
    section.add "X-Amz-SignedHeaders", valid_591217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591219: Call_UpdatePreset_591207; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modify one of your existing presets.
  ## 
  let valid = call_591219.validator(path, query, header, formData, body)
  let scheme = call_591219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591219.url(scheme.get, call_591219.host, call_591219.base,
                         call_591219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591219, url, valid)

proc call*(call_591220: Call_UpdatePreset_591207; name: string; body: JsonNode): Recallable =
  ## updatePreset
  ## Modify one of your existing presets.
  ##   name: string (required)
  ##       : The name of the preset you are modifying.
  ##   body: JObject (required)
  var path_591221 = newJObject()
  var body_591222 = newJObject()
  add(path_591221, "name", newJString(name))
  if body != nil:
    body_591222 = body
  result = call_591220.call(path_591221, nil, nil, nil, body_591222)

var updatePreset* = Call_UpdatePreset_591207(name: "updatePreset",
    meth: HttpMethod.HttpPut, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/presets/{name}", validator: validate_UpdatePreset_591208,
    base: "/", url: url_UpdatePreset_591209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPreset_591193 = ref object of OpenApiRestCall_590364
proc url_GetPreset_591195(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
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
  result.path = base & hydrated.get

proc validate_GetPreset_591194(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591196 = path.getOrDefault("name")
  valid_591196 = validateParameter(valid_591196, JString, required = true,
                                 default = nil)
  if valid_591196 != nil:
    section.add "name", valid_591196
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
  var valid_591197 = header.getOrDefault("X-Amz-Signature")
  valid_591197 = validateParameter(valid_591197, JString, required = false,
                                 default = nil)
  if valid_591197 != nil:
    section.add "X-Amz-Signature", valid_591197
  var valid_591198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591198 = validateParameter(valid_591198, JString, required = false,
                                 default = nil)
  if valid_591198 != nil:
    section.add "X-Amz-Content-Sha256", valid_591198
  var valid_591199 = header.getOrDefault("X-Amz-Date")
  valid_591199 = validateParameter(valid_591199, JString, required = false,
                                 default = nil)
  if valid_591199 != nil:
    section.add "X-Amz-Date", valid_591199
  var valid_591200 = header.getOrDefault("X-Amz-Credential")
  valid_591200 = validateParameter(valid_591200, JString, required = false,
                                 default = nil)
  if valid_591200 != nil:
    section.add "X-Amz-Credential", valid_591200
  var valid_591201 = header.getOrDefault("X-Amz-Security-Token")
  valid_591201 = validateParameter(valid_591201, JString, required = false,
                                 default = nil)
  if valid_591201 != nil:
    section.add "X-Amz-Security-Token", valid_591201
  var valid_591202 = header.getOrDefault("X-Amz-Algorithm")
  valid_591202 = validateParameter(valid_591202, JString, required = false,
                                 default = nil)
  if valid_591202 != nil:
    section.add "X-Amz-Algorithm", valid_591202
  var valid_591203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591203 = validateParameter(valid_591203, JString, required = false,
                                 default = nil)
  if valid_591203 != nil:
    section.add "X-Amz-SignedHeaders", valid_591203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591204: Call_GetPreset_591193; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the JSON for a specific preset.
  ## 
  let valid = call_591204.validator(path, query, header, formData, body)
  let scheme = call_591204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591204.url(scheme.get, call_591204.host, call_591204.base,
                         call_591204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591204, url, valid)

proc call*(call_591205: Call_GetPreset_591193; name: string): Recallable =
  ## getPreset
  ## Retrieve the JSON for a specific preset.
  ##   name: string (required)
  ##       : The name of the preset.
  var path_591206 = newJObject()
  add(path_591206, "name", newJString(name))
  result = call_591205.call(path_591206, nil, nil, nil, nil)

var getPreset* = Call_GetPreset_591193(name: "getPreset", meth: HttpMethod.HttpGet,
                                    host: "mediaconvert.amazonaws.com",
                                    route: "/2017-08-29/presets/{name}",
                                    validator: validate_GetPreset_591194,
                                    base: "/", url: url_GetPreset_591195,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePreset_591223 = ref object of OpenApiRestCall_590364
proc url_DeletePreset_591225(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeletePreset_591224(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591226 = path.getOrDefault("name")
  valid_591226 = validateParameter(valid_591226, JString, required = true,
                                 default = nil)
  if valid_591226 != nil:
    section.add "name", valid_591226
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
  var valid_591227 = header.getOrDefault("X-Amz-Signature")
  valid_591227 = validateParameter(valid_591227, JString, required = false,
                                 default = nil)
  if valid_591227 != nil:
    section.add "X-Amz-Signature", valid_591227
  var valid_591228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591228 = validateParameter(valid_591228, JString, required = false,
                                 default = nil)
  if valid_591228 != nil:
    section.add "X-Amz-Content-Sha256", valid_591228
  var valid_591229 = header.getOrDefault("X-Amz-Date")
  valid_591229 = validateParameter(valid_591229, JString, required = false,
                                 default = nil)
  if valid_591229 != nil:
    section.add "X-Amz-Date", valid_591229
  var valid_591230 = header.getOrDefault("X-Amz-Credential")
  valid_591230 = validateParameter(valid_591230, JString, required = false,
                                 default = nil)
  if valid_591230 != nil:
    section.add "X-Amz-Credential", valid_591230
  var valid_591231 = header.getOrDefault("X-Amz-Security-Token")
  valid_591231 = validateParameter(valid_591231, JString, required = false,
                                 default = nil)
  if valid_591231 != nil:
    section.add "X-Amz-Security-Token", valid_591231
  var valid_591232 = header.getOrDefault("X-Amz-Algorithm")
  valid_591232 = validateParameter(valid_591232, JString, required = false,
                                 default = nil)
  if valid_591232 != nil:
    section.add "X-Amz-Algorithm", valid_591232
  var valid_591233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591233 = validateParameter(valid_591233, JString, required = false,
                                 default = nil)
  if valid_591233 != nil:
    section.add "X-Amz-SignedHeaders", valid_591233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591234: Call_DeletePreset_591223; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently delete a preset you have created.
  ## 
  let valid = call_591234.validator(path, query, header, formData, body)
  let scheme = call_591234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591234.url(scheme.get, call_591234.host, call_591234.base,
                         call_591234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591234, url, valid)

proc call*(call_591235: Call_DeletePreset_591223; name: string): Recallable =
  ## deletePreset
  ## Permanently delete a preset you have created.
  ##   name: string (required)
  ##       : The name of the preset to be deleted.
  var path_591236 = newJObject()
  add(path_591236, "name", newJString(name))
  result = call_591235.call(path_591236, nil, nil, nil, nil)

var deletePreset* = Call_DeletePreset_591223(name: "deletePreset",
    meth: HttpMethod.HttpDelete, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/presets/{name}", validator: validate_DeletePreset_591224,
    base: "/", url: url_DeletePreset_591225, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateQueue_591251 = ref object of OpenApiRestCall_590364
proc url_UpdateQueue_591253(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateQueue_591252(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591254 = path.getOrDefault("name")
  valid_591254 = validateParameter(valid_591254, JString, required = true,
                                 default = nil)
  if valid_591254 != nil:
    section.add "name", valid_591254
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
  var valid_591255 = header.getOrDefault("X-Amz-Signature")
  valid_591255 = validateParameter(valid_591255, JString, required = false,
                                 default = nil)
  if valid_591255 != nil:
    section.add "X-Amz-Signature", valid_591255
  var valid_591256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591256 = validateParameter(valid_591256, JString, required = false,
                                 default = nil)
  if valid_591256 != nil:
    section.add "X-Amz-Content-Sha256", valid_591256
  var valid_591257 = header.getOrDefault("X-Amz-Date")
  valid_591257 = validateParameter(valid_591257, JString, required = false,
                                 default = nil)
  if valid_591257 != nil:
    section.add "X-Amz-Date", valid_591257
  var valid_591258 = header.getOrDefault("X-Amz-Credential")
  valid_591258 = validateParameter(valid_591258, JString, required = false,
                                 default = nil)
  if valid_591258 != nil:
    section.add "X-Amz-Credential", valid_591258
  var valid_591259 = header.getOrDefault("X-Amz-Security-Token")
  valid_591259 = validateParameter(valid_591259, JString, required = false,
                                 default = nil)
  if valid_591259 != nil:
    section.add "X-Amz-Security-Token", valid_591259
  var valid_591260 = header.getOrDefault("X-Amz-Algorithm")
  valid_591260 = validateParameter(valid_591260, JString, required = false,
                                 default = nil)
  if valid_591260 != nil:
    section.add "X-Amz-Algorithm", valid_591260
  var valid_591261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591261 = validateParameter(valid_591261, JString, required = false,
                                 default = nil)
  if valid_591261 != nil:
    section.add "X-Amz-SignedHeaders", valid_591261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591263: Call_UpdateQueue_591251; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modify one of your existing queues.
  ## 
  let valid = call_591263.validator(path, query, header, formData, body)
  let scheme = call_591263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591263.url(scheme.get, call_591263.host, call_591263.base,
                         call_591263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591263, url, valid)

proc call*(call_591264: Call_UpdateQueue_591251; name: string; body: JsonNode): Recallable =
  ## updateQueue
  ## Modify one of your existing queues.
  ##   name: string (required)
  ##       : The name of the queue that you are modifying.
  ##   body: JObject (required)
  var path_591265 = newJObject()
  var body_591266 = newJObject()
  add(path_591265, "name", newJString(name))
  if body != nil:
    body_591266 = body
  result = call_591264.call(path_591265, nil, nil, nil, body_591266)

var updateQueue* = Call_UpdateQueue_591251(name: "updateQueue",
                                        meth: HttpMethod.HttpPut,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/queues/{name}",
                                        validator: validate_UpdateQueue_591252,
                                        base: "/", url: url_UpdateQueue_591253,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQueue_591237 = ref object of OpenApiRestCall_590364
proc url_GetQueue_591239(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetQueue_591238(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591240 = path.getOrDefault("name")
  valid_591240 = validateParameter(valid_591240, JString, required = true,
                                 default = nil)
  if valid_591240 != nil:
    section.add "name", valid_591240
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
  var valid_591241 = header.getOrDefault("X-Amz-Signature")
  valid_591241 = validateParameter(valid_591241, JString, required = false,
                                 default = nil)
  if valid_591241 != nil:
    section.add "X-Amz-Signature", valid_591241
  var valid_591242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591242 = validateParameter(valid_591242, JString, required = false,
                                 default = nil)
  if valid_591242 != nil:
    section.add "X-Amz-Content-Sha256", valid_591242
  var valid_591243 = header.getOrDefault("X-Amz-Date")
  valid_591243 = validateParameter(valid_591243, JString, required = false,
                                 default = nil)
  if valid_591243 != nil:
    section.add "X-Amz-Date", valid_591243
  var valid_591244 = header.getOrDefault("X-Amz-Credential")
  valid_591244 = validateParameter(valid_591244, JString, required = false,
                                 default = nil)
  if valid_591244 != nil:
    section.add "X-Amz-Credential", valid_591244
  var valid_591245 = header.getOrDefault("X-Amz-Security-Token")
  valid_591245 = validateParameter(valid_591245, JString, required = false,
                                 default = nil)
  if valid_591245 != nil:
    section.add "X-Amz-Security-Token", valid_591245
  var valid_591246 = header.getOrDefault("X-Amz-Algorithm")
  valid_591246 = validateParameter(valid_591246, JString, required = false,
                                 default = nil)
  if valid_591246 != nil:
    section.add "X-Amz-Algorithm", valid_591246
  var valid_591247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591247 = validateParameter(valid_591247, JString, required = false,
                                 default = nil)
  if valid_591247 != nil:
    section.add "X-Amz-SignedHeaders", valid_591247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591248: Call_GetQueue_591237; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the JSON for a specific queue.
  ## 
  let valid = call_591248.validator(path, query, header, formData, body)
  let scheme = call_591248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591248.url(scheme.get, call_591248.host, call_591248.base,
                         call_591248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591248, url, valid)

proc call*(call_591249: Call_GetQueue_591237; name: string): Recallable =
  ## getQueue
  ## Retrieve the JSON for a specific queue.
  ##   name: string (required)
  ##       : The name of the queue that you want information about.
  var path_591250 = newJObject()
  add(path_591250, "name", newJString(name))
  result = call_591249.call(path_591250, nil, nil, nil, nil)

var getQueue* = Call_GetQueue_591237(name: "getQueue", meth: HttpMethod.HttpGet,
                                  host: "mediaconvert.amazonaws.com",
                                  route: "/2017-08-29/queues/{name}",
                                  validator: validate_GetQueue_591238, base: "/",
                                  url: url_GetQueue_591239,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteQueue_591267 = ref object of OpenApiRestCall_590364
proc url_DeleteQueue_591269(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteQueue_591268(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591270 = path.getOrDefault("name")
  valid_591270 = validateParameter(valid_591270, JString, required = true,
                                 default = nil)
  if valid_591270 != nil:
    section.add "name", valid_591270
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
  var valid_591271 = header.getOrDefault("X-Amz-Signature")
  valid_591271 = validateParameter(valid_591271, JString, required = false,
                                 default = nil)
  if valid_591271 != nil:
    section.add "X-Amz-Signature", valid_591271
  var valid_591272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591272 = validateParameter(valid_591272, JString, required = false,
                                 default = nil)
  if valid_591272 != nil:
    section.add "X-Amz-Content-Sha256", valid_591272
  var valid_591273 = header.getOrDefault("X-Amz-Date")
  valid_591273 = validateParameter(valid_591273, JString, required = false,
                                 default = nil)
  if valid_591273 != nil:
    section.add "X-Amz-Date", valid_591273
  var valid_591274 = header.getOrDefault("X-Amz-Credential")
  valid_591274 = validateParameter(valid_591274, JString, required = false,
                                 default = nil)
  if valid_591274 != nil:
    section.add "X-Amz-Credential", valid_591274
  var valid_591275 = header.getOrDefault("X-Amz-Security-Token")
  valid_591275 = validateParameter(valid_591275, JString, required = false,
                                 default = nil)
  if valid_591275 != nil:
    section.add "X-Amz-Security-Token", valid_591275
  var valid_591276 = header.getOrDefault("X-Amz-Algorithm")
  valid_591276 = validateParameter(valid_591276, JString, required = false,
                                 default = nil)
  if valid_591276 != nil:
    section.add "X-Amz-Algorithm", valid_591276
  var valid_591277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591277 = validateParameter(valid_591277, JString, required = false,
                                 default = nil)
  if valid_591277 != nil:
    section.add "X-Amz-SignedHeaders", valid_591277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591278: Call_DeleteQueue_591267; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently delete a queue you have created.
  ## 
  let valid = call_591278.validator(path, query, header, formData, body)
  let scheme = call_591278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591278.url(scheme.get, call_591278.host, call_591278.base,
                         call_591278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591278, url, valid)

proc call*(call_591279: Call_DeleteQueue_591267; name: string): Recallable =
  ## deleteQueue
  ## Permanently delete a queue you have created.
  ##   name: string (required)
  ##       : The name of the queue that you want to delete.
  var path_591280 = newJObject()
  add(path_591280, "name", newJString(name))
  result = call_591279.call(path_591280, nil, nil, nil, nil)

var deleteQueue* = Call_DeleteQueue_591267(name: "deleteQueue",
                                        meth: HttpMethod.HttpDelete,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/queues/{name}",
                                        validator: validate_DeleteQueue_591268,
                                        base: "/", url: url_DeleteQueue_591269,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoints_591281 = ref object of OpenApiRestCall_590364
proc url_DescribeEndpoints_591283(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEndpoints_591282(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Send an request with an empty body to the regional API endpoint to get your account API endpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_591284 = query.getOrDefault("MaxResults")
  valid_591284 = validateParameter(valid_591284, JString, required = false,
                                 default = nil)
  if valid_591284 != nil:
    section.add "MaxResults", valid_591284
  var valid_591285 = query.getOrDefault("NextToken")
  valid_591285 = validateParameter(valid_591285, JString, required = false,
                                 default = nil)
  if valid_591285 != nil:
    section.add "NextToken", valid_591285
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
  var valid_591286 = header.getOrDefault("X-Amz-Signature")
  valid_591286 = validateParameter(valid_591286, JString, required = false,
                                 default = nil)
  if valid_591286 != nil:
    section.add "X-Amz-Signature", valid_591286
  var valid_591287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591287 = validateParameter(valid_591287, JString, required = false,
                                 default = nil)
  if valid_591287 != nil:
    section.add "X-Amz-Content-Sha256", valid_591287
  var valid_591288 = header.getOrDefault("X-Amz-Date")
  valid_591288 = validateParameter(valid_591288, JString, required = false,
                                 default = nil)
  if valid_591288 != nil:
    section.add "X-Amz-Date", valid_591288
  var valid_591289 = header.getOrDefault("X-Amz-Credential")
  valid_591289 = validateParameter(valid_591289, JString, required = false,
                                 default = nil)
  if valid_591289 != nil:
    section.add "X-Amz-Credential", valid_591289
  var valid_591290 = header.getOrDefault("X-Amz-Security-Token")
  valid_591290 = validateParameter(valid_591290, JString, required = false,
                                 default = nil)
  if valid_591290 != nil:
    section.add "X-Amz-Security-Token", valid_591290
  var valid_591291 = header.getOrDefault("X-Amz-Algorithm")
  valid_591291 = validateParameter(valid_591291, JString, required = false,
                                 default = nil)
  if valid_591291 != nil:
    section.add "X-Amz-Algorithm", valid_591291
  var valid_591292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591292 = validateParameter(valid_591292, JString, required = false,
                                 default = nil)
  if valid_591292 != nil:
    section.add "X-Amz-SignedHeaders", valid_591292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591294: Call_DescribeEndpoints_591281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Send an request with an empty body to the regional API endpoint to get your account API endpoint.
  ## 
  let valid = call_591294.validator(path, query, header, formData, body)
  let scheme = call_591294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591294.url(scheme.get, call_591294.host, call_591294.base,
                         call_591294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591294, url, valid)

proc call*(call_591295: Call_DescribeEndpoints_591281; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeEndpoints
  ## Send an request with an empty body to the regional API endpoint to get your account API endpoint.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591296 = newJObject()
  var body_591297 = newJObject()
  add(query_591296, "MaxResults", newJString(MaxResults))
  add(query_591296, "NextToken", newJString(NextToken))
  if body != nil:
    body_591297 = body
  result = call_591295.call(nil, query_591296, nil, nil, body_591297)

var describeEndpoints* = Call_DescribeEndpoints_591281(name: "describeEndpoints",
    meth: HttpMethod.HttpPost, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/endpoints", validator: validate_DescribeEndpoints_591282,
    base: "/", url: url_DescribeEndpoints_591283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateCertificate_591298 = ref object of OpenApiRestCall_590364
proc url_DisassociateCertificate_591300(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
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
  result.path = base & hydrated.get

proc validate_DisassociateCertificate_591299(path: JsonNode; query: JsonNode;
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
  var valid_591301 = path.getOrDefault("arn")
  valid_591301 = validateParameter(valid_591301, JString, required = true,
                                 default = nil)
  if valid_591301 != nil:
    section.add "arn", valid_591301
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
  var valid_591302 = header.getOrDefault("X-Amz-Signature")
  valid_591302 = validateParameter(valid_591302, JString, required = false,
                                 default = nil)
  if valid_591302 != nil:
    section.add "X-Amz-Signature", valid_591302
  var valid_591303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591303 = validateParameter(valid_591303, JString, required = false,
                                 default = nil)
  if valid_591303 != nil:
    section.add "X-Amz-Content-Sha256", valid_591303
  var valid_591304 = header.getOrDefault("X-Amz-Date")
  valid_591304 = validateParameter(valid_591304, JString, required = false,
                                 default = nil)
  if valid_591304 != nil:
    section.add "X-Amz-Date", valid_591304
  var valid_591305 = header.getOrDefault("X-Amz-Credential")
  valid_591305 = validateParameter(valid_591305, JString, required = false,
                                 default = nil)
  if valid_591305 != nil:
    section.add "X-Amz-Credential", valid_591305
  var valid_591306 = header.getOrDefault("X-Amz-Security-Token")
  valid_591306 = validateParameter(valid_591306, JString, required = false,
                                 default = nil)
  if valid_591306 != nil:
    section.add "X-Amz-Security-Token", valid_591306
  var valid_591307 = header.getOrDefault("X-Amz-Algorithm")
  valid_591307 = validateParameter(valid_591307, JString, required = false,
                                 default = nil)
  if valid_591307 != nil:
    section.add "X-Amz-Algorithm", valid_591307
  var valid_591308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591308 = validateParameter(valid_591308, JString, required = false,
                                 default = nil)
  if valid_591308 != nil:
    section.add "X-Amz-SignedHeaders", valid_591308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591309: Call_DisassociateCertificate_591298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an association between the Amazon Resource Name (ARN) of an AWS Certificate Manager (ACM) certificate and an AWS Elemental MediaConvert resource.
  ## 
  let valid = call_591309.validator(path, query, header, formData, body)
  let scheme = call_591309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591309.url(scheme.get, call_591309.host, call_591309.base,
                         call_591309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591309, url, valid)

proc call*(call_591310: Call_DisassociateCertificate_591298; arn: string): Recallable =
  ## disassociateCertificate
  ## Removes an association between the Amazon Resource Name (ARN) of an AWS Certificate Manager (ACM) certificate and an AWS Elemental MediaConvert resource.
  ##   arn: string (required)
  ##      : The ARN of the ACM certificate that you want to disassociate from your MediaConvert resource.
  var path_591311 = newJObject()
  add(path_591311, "arn", newJString(arn))
  result = call_591310.call(path_591311, nil, nil, nil, nil)

var disassociateCertificate* = Call_DisassociateCertificate_591298(
    name: "disassociateCertificate", meth: HttpMethod.HttpDelete,
    host: "mediaconvert.amazonaws.com", route: "/2017-08-29/certificates/{arn}",
    validator: validate_DisassociateCertificate_591299, base: "/",
    url: url_DisassociateCertificate_591300, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_591326 = ref object of OpenApiRestCall_590364
proc url_UntagResource_591328(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UntagResource_591327(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591329 = path.getOrDefault("arn")
  valid_591329 = validateParameter(valid_591329, JString, required = true,
                                 default = nil)
  if valid_591329 != nil:
    section.add "arn", valid_591329
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
  var valid_591330 = header.getOrDefault("X-Amz-Signature")
  valid_591330 = validateParameter(valid_591330, JString, required = false,
                                 default = nil)
  if valid_591330 != nil:
    section.add "X-Amz-Signature", valid_591330
  var valid_591331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591331 = validateParameter(valid_591331, JString, required = false,
                                 default = nil)
  if valid_591331 != nil:
    section.add "X-Amz-Content-Sha256", valid_591331
  var valid_591332 = header.getOrDefault("X-Amz-Date")
  valid_591332 = validateParameter(valid_591332, JString, required = false,
                                 default = nil)
  if valid_591332 != nil:
    section.add "X-Amz-Date", valid_591332
  var valid_591333 = header.getOrDefault("X-Amz-Credential")
  valid_591333 = validateParameter(valid_591333, JString, required = false,
                                 default = nil)
  if valid_591333 != nil:
    section.add "X-Amz-Credential", valid_591333
  var valid_591334 = header.getOrDefault("X-Amz-Security-Token")
  valid_591334 = validateParameter(valid_591334, JString, required = false,
                                 default = nil)
  if valid_591334 != nil:
    section.add "X-Amz-Security-Token", valid_591334
  var valid_591335 = header.getOrDefault("X-Amz-Algorithm")
  valid_591335 = validateParameter(valid_591335, JString, required = false,
                                 default = nil)
  if valid_591335 != nil:
    section.add "X-Amz-Algorithm", valid_591335
  var valid_591336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591336 = validateParameter(valid_591336, JString, required = false,
                                 default = nil)
  if valid_591336 != nil:
    section.add "X-Amz-SignedHeaders", valid_591336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591338: Call_UntagResource_591326; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ## 
  let valid = call_591338.validator(path, query, header, formData, body)
  let scheme = call_591338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591338.url(scheme.get, call_591338.host, call_591338.base,
                         call_591338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591338, url, valid)

proc call*(call_591339: Call_UntagResource_591326; arn: string; body: JsonNode): Recallable =
  ## untagResource
  ## Remove tags from a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ##   arn: string (required)
  ##      : The Amazon Resource Name (ARN) of the resource that you want to remove tags from. To get the ARN, send a GET request with the resource name.
  ##   body: JObject (required)
  var path_591340 = newJObject()
  var body_591341 = newJObject()
  add(path_591340, "arn", newJString(arn))
  if body != nil:
    body_591341 = body
  result = call_591339.call(path_591340, nil, nil, nil, body_591341)

var untagResource* = Call_UntagResource_591326(name: "untagResource",
    meth: HttpMethod.HttpPut, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/tags/{arn}", validator: validate_UntagResource_591327,
    base: "/", url: url_UntagResource_591328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_591312 = ref object of OpenApiRestCall_590364
proc url_ListTagsForResource_591314(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListTagsForResource_591313(path: JsonNode; query: JsonNode;
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
  var valid_591315 = path.getOrDefault("arn")
  valid_591315 = validateParameter(valid_591315, JString, required = true,
                                 default = nil)
  if valid_591315 != nil:
    section.add "arn", valid_591315
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
  var valid_591316 = header.getOrDefault("X-Amz-Signature")
  valid_591316 = validateParameter(valid_591316, JString, required = false,
                                 default = nil)
  if valid_591316 != nil:
    section.add "X-Amz-Signature", valid_591316
  var valid_591317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591317 = validateParameter(valid_591317, JString, required = false,
                                 default = nil)
  if valid_591317 != nil:
    section.add "X-Amz-Content-Sha256", valid_591317
  var valid_591318 = header.getOrDefault("X-Amz-Date")
  valid_591318 = validateParameter(valid_591318, JString, required = false,
                                 default = nil)
  if valid_591318 != nil:
    section.add "X-Amz-Date", valid_591318
  var valid_591319 = header.getOrDefault("X-Amz-Credential")
  valid_591319 = validateParameter(valid_591319, JString, required = false,
                                 default = nil)
  if valid_591319 != nil:
    section.add "X-Amz-Credential", valid_591319
  var valid_591320 = header.getOrDefault("X-Amz-Security-Token")
  valid_591320 = validateParameter(valid_591320, JString, required = false,
                                 default = nil)
  if valid_591320 != nil:
    section.add "X-Amz-Security-Token", valid_591320
  var valid_591321 = header.getOrDefault("X-Amz-Algorithm")
  valid_591321 = validateParameter(valid_591321, JString, required = false,
                                 default = nil)
  if valid_591321 != nil:
    section.add "X-Amz-Algorithm", valid_591321
  var valid_591322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591322 = validateParameter(valid_591322, JString, required = false,
                                 default = nil)
  if valid_591322 != nil:
    section.add "X-Amz-SignedHeaders", valid_591322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591323: Call_ListTagsForResource_591312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the tags for a MediaConvert resource.
  ## 
  let valid = call_591323.validator(path, query, header, formData, body)
  let scheme = call_591323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591323.url(scheme.get, call_591323.host, call_591323.base,
                         call_591323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591323, url, valid)

proc call*(call_591324: Call_ListTagsForResource_591312; arn: string): Recallable =
  ## listTagsForResource
  ## Retrieve the tags for a MediaConvert resource.
  ##   arn: string (required)
  ##      : The Amazon Resource Name (ARN) of the resource that you want to list tags for. To get the ARN, send a GET request with the resource name.
  var path_591325 = newJObject()
  add(path_591325, "arn", newJString(arn))
  result = call_591324.call(path_591325, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_591312(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "mediaconvert.amazonaws.com", route: "/2017-08-29/tags/{arn}",
    validator: validate_ListTagsForResource_591313, base: "/",
    url: url_ListTagsForResource_591314, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_591342 = ref object of OpenApiRestCall_590364
proc url_TagResource_591344(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_591343(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591345 = header.getOrDefault("X-Amz-Signature")
  valid_591345 = validateParameter(valid_591345, JString, required = false,
                                 default = nil)
  if valid_591345 != nil:
    section.add "X-Amz-Signature", valid_591345
  var valid_591346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591346 = validateParameter(valid_591346, JString, required = false,
                                 default = nil)
  if valid_591346 != nil:
    section.add "X-Amz-Content-Sha256", valid_591346
  var valid_591347 = header.getOrDefault("X-Amz-Date")
  valid_591347 = validateParameter(valid_591347, JString, required = false,
                                 default = nil)
  if valid_591347 != nil:
    section.add "X-Amz-Date", valid_591347
  var valid_591348 = header.getOrDefault("X-Amz-Credential")
  valid_591348 = validateParameter(valid_591348, JString, required = false,
                                 default = nil)
  if valid_591348 != nil:
    section.add "X-Amz-Credential", valid_591348
  var valid_591349 = header.getOrDefault("X-Amz-Security-Token")
  valid_591349 = validateParameter(valid_591349, JString, required = false,
                                 default = nil)
  if valid_591349 != nil:
    section.add "X-Amz-Security-Token", valid_591349
  var valid_591350 = header.getOrDefault("X-Amz-Algorithm")
  valid_591350 = validateParameter(valid_591350, JString, required = false,
                                 default = nil)
  if valid_591350 != nil:
    section.add "X-Amz-Algorithm", valid_591350
  var valid_591351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591351 = validateParameter(valid_591351, JString, required = false,
                                 default = nil)
  if valid_591351 != nil:
    section.add "X-Amz-SignedHeaders", valid_591351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591353: Call_TagResource_591342; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add tags to a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ## 
  let valid = call_591353.validator(path, query, header, formData, body)
  let scheme = call_591353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591353.url(scheme.get, call_591353.host, call_591353.base,
                         call_591353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591353, url, valid)

proc call*(call_591354: Call_TagResource_591342; body: JsonNode): Recallable =
  ## tagResource
  ## Add tags to a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ##   body: JObject (required)
  var body_591355 = newJObject()
  if body != nil:
    body_591355 = body
  result = call_591354.call(nil, nil, nil, nil, body_591355)

var tagResource* = Call_TagResource_591342(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/tags",
                                        validator: validate_TagResource_591343,
                                        base: "/", url: url_TagResource_591344,
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
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
