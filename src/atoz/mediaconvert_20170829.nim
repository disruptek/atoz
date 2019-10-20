
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
  Call_AssociateCertificate_592703 = ref object of OpenApiRestCall_592364
proc url_AssociateCertificate_592705(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateCertificate_592704(path: JsonNode; query: JsonNode;
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

proc call*(call_592847: Call_AssociateCertificate_592703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates an AWS Certificate Manager (ACM) Amazon Resource Name (ARN) with AWS Elemental MediaConvert.
  ## 
  let valid = call_592847.validator(path, query, header, formData, body)
  let scheme = call_592847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592847.url(scheme.get, call_592847.host, call_592847.base,
                         call_592847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592847, url, valid)

proc call*(call_592918: Call_AssociateCertificate_592703; body: JsonNode): Recallable =
  ## associateCertificate
  ## Associates an AWS Certificate Manager (ACM) Amazon Resource Name (ARN) with AWS Elemental MediaConvert.
  ##   body: JObject (required)
  var body_592919 = newJObject()
  if body != nil:
    body_592919 = body
  result = call_592918.call(nil, nil, nil, nil, body_592919)

var associateCertificate* = Call_AssociateCertificate_592703(
    name: "associateCertificate", meth: HttpMethod.HttpPost,
    host: "mediaconvert.amazonaws.com", route: "/2017-08-29/certificates",
    validator: validate_AssociateCertificate_592704, base: "/",
    url: url_AssociateCertificate_592705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_592958 = ref object of OpenApiRestCall_592364
proc url_GetJob_592960(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetJob_592959(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592975 = path.getOrDefault("id")
  valid_592975 = validateParameter(valid_592975, JString, required = true,
                                 default = nil)
  if valid_592975 != nil:
    section.add "id", valid_592975
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
  var valid_592976 = header.getOrDefault("X-Amz-Signature")
  valid_592976 = validateParameter(valid_592976, JString, required = false,
                                 default = nil)
  if valid_592976 != nil:
    section.add "X-Amz-Signature", valid_592976
  var valid_592977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592977 = validateParameter(valid_592977, JString, required = false,
                                 default = nil)
  if valid_592977 != nil:
    section.add "X-Amz-Content-Sha256", valid_592977
  var valid_592978 = header.getOrDefault("X-Amz-Date")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "X-Amz-Date", valid_592978
  var valid_592979 = header.getOrDefault("X-Amz-Credential")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Credential", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Security-Token")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Security-Token", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Algorithm")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Algorithm", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-SignedHeaders", valid_592982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592983: Call_GetJob_592958; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the JSON for a specific completed transcoding job.
  ## 
  let valid = call_592983.validator(path, query, header, formData, body)
  let scheme = call_592983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592983.url(scheme.get, call_592983.host, call_592983.base,
                         call_592983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592983, url, valid)

proc call*(call_592984: Call_GetJob_592958; id: string): Recallable =
  ## getJob
  ## Retrieve the JSON for a specific completed transcoding job.
  ##   id: string (required)
  ##     : the job ID of the job.
  var path_592985 = newJObject()
  add(path_592985, "id", newJString(id))
  result = call_592984.call(path_592985, nil, nil, nil, nil)

var getJob* = Call_GetJob_592958(name: "getJob", meth: HttpMethod.HttpGet,
                              host: "mediaconvert.amazonaws.com",
                              route: "/2017-08-29/jobs/{id}",
                              validator: validate_GetJob_592959, base: "/",
                              url: url_GetJob_592960,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelJob_592987 = ref object of OpenApiRestCall_592364
proc url_CancelJob_592989(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CancelJob_592988(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592990 = path.getOrDefault("id")
  valid_592990 = validateParameter(valid_592990, JString, required = true,
                                 default = nil)
  if valid_592990 != nil:
    section.add "id", valid_592990
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

proc call*(call_592998: Call_CancelJob_592987; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently cancel a job. Once you have canceled a job, you can't start it again.
  ## 
  let valid = call_592998.validator(path, query, header, formData, body)
  let scheme = call_592998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592998.url(scheme.get, call_592998.host, call_592998.base,
                         call_592998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592998, url, valid)

proc call*(call_592999: Call_CancelJob_592987; id: string): Recallable =
  ## cancelJob
  ## Permanently cancel a job. Once you have canceled a job, you can't start it again.
  ##   id: string (required)
  ##     : The Job ID of the job to be cancelled.
  var path_593000 = newJObject()
  add(path_593000, "id", newJString(id))
  result = call_592999.call(path_593000, nil, nil, nil, nil)

var cancelJob* = Call_CancelJob_592987(name: "cancelJob",
                                    meth: HttpMethod.HttpDelete,
                                    host: "mediaconvert.amazonaws.com",
                                    route: "/2017-08-29/jobs/{id}",
                                    validator: validate_CancelJob_592988,
                                    base: "/", url: url_CancelJob_592989,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_593034 = ref object of OpenApiRestCall_592364
proc url_CreateJob_593036(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateJob_593035(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593037 = header.getOrDefault("X-Amz-Signature")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Signature", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Content-Sha256", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Date")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Date", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Credential")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Credential", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Security-Token")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Security-Token", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-Algorithm")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-Algorithm", valid_593042
  var valid_593043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "X-Amz-SignedHeaders", valid_593043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593045: Call_CreateJob_593034; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new transcoding job. For information about jobs and job settings, see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ## 
  let valid = call_593045.validator(path, query, header, formData, body)
  let scheme = call_593045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593045.url(scheme.get, call_593045.host, call_593045.base,
                         call_593045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593045, url, valid)

proc call*(call_593046: Call_CreateJob_593034; body: JsonNode): Recallable =
  ## createJob
  ## Create a new transcoding job. For information about jobs and job settings, see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ##   body: JObject (required)
  var body_593047 = newJObject()
  if body != nil:
    body_593047 = body
  result = call_593046.call(nil, nil, nil, nil, body_593047)

var createJob* = Call_CreateJob_593034(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "mediaconvert.amazonaws.com",
                                    route: "/2017-08-29/jobs",
                                    validator: validate_CreateJob_593035,
                                    base: "/", url: url_CreateJob_593036,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_593001 = ref object of OpenApiRestCall_592364
proc url_ListJobs_593003(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListJobs_593002(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593004 = query.getOrDefault("queue")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "queue", valid_593004
  var valid_593005 = query.getOrDefault("nextToken")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "nextToken", valid_593005
  var valid_593006 = query.getOrDefault("MaxResults")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "MaxResults", valid_593006
  var valid_593020 = query.getOrDefault("order")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_593020 != nil:
    section.add "order", valid_593020
  var valid_593021 = query.getOrDefault("NextToken")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "NextToken", valid_593021
  var valid_593022 = query.getOrDefault("status")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = newJString("SUBMITTED"))
  if valid_593022 != nil:
    section.add "status", valid_593022
  var valid_593023 = query.getOrDefault("maxResults")
  valid_593023 = validateParameter(valid_593023, JInt, required = false, default = nil)
  if valid_593023 != nil:
    section.add "maxResults", valid_593023
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
  var valid_593024 = header.getOrDefault("X-Amz-Signature")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Signature", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Content-Sha256", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-Date")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Date", valid_593026
  var valid_593027 = header.getOrDefault("X-Amz-Credential")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-Credential", valid_593027
  var valid_593028 = header.getOrDefault("X-Amz-Security-Token")
  valid_593028 = validateParameter(valid_593028, JString, required = false,
                                 default = nil)
  if valid_593028 != nil:
    section.add "X-Amz-Security-Token", valid_593028
  var valid_593029 = header.getOrDefault("X-Amz-Algorithm")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "X-Amz-Algorithm", valid_593029
  var valid_593030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593030 = validateParameter(valid_593030, JString, required = false,
                                 default = nil)
  if valid_593030 != nil:
    section.add "X-Amz-SignedHeaders", valid_593030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593031: Call_ListJobs_593001; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a JSON array of up to twenty of your most recently created jobs. This array includes in-process, completed, and errored jobs. This will return the jobs themselves, not just a list of the jobs. To retrieve the twenty next most recent jobs, use the nextToken string returned with the array.
  ## 
  let valid = call_593031.validator(path, query, header, formData, body)
  let scheme = call_593031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593031.url(scheme.get, call_593031.host, call_593031.base,
                         call_593031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593031, url, valid)

proc call*(call_593032: Call_ListJobs_593001; queue: string = "";
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
  var query_593033 = newJObject()
  add(query_593033, "queue", newJString(queue))
  add(query_593033, "nextToken", newJString(nextToken))
  add(query_593033, "MaxResults", newJString(MaxResults))
  add(query_593033, "order", newJString(order))
  add(query_593033, "NextToken", newJString(NextToken))
  add(query_593033, "status", newJString(status))
  add(query_593033, "maxResults", newJInt(maxResults))
  result = call_593032.call(nil, query_593033, nil, nil, nil)

var listJobs* = Call_ListJobs_593001(name: "listJobs", meth: HttpMethod.HttpGet,
                                  host: "mediaconvert.amazonaws.com",
                                  route: "/2017-08-29/jobs",
                                  validator: validate_ListJobs_593002, base: "/",
                                  url: url_ListJobs_593003,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJobTemplate_593068 = ref object of OpenApiRestCall_592364
proc url_CreateJobTemplate_593070(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateJobTemplate_593069(path: JsonNode; query: JsonNode;
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
  var valid_593071 = header.getOrDefault("X-Amz-Signature")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-Signature", valid_593071
  var valid_593072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-Content-Sha256", valid_593072
  var valid_593073 = header.getOrDefault("X-Amz-Date")
  valid_593073 = validateParameter(valid_593073, JString, required = false,
                                 default = nil)
  if valid_593073 != nil:
    section.add "X-Amz-Date", valid_593073
  var valid_593074 = header.getOrDefault("X-Amz-Credential")
  valid_593074 = validateParameter(valid_593074, JString, required = false,
                                 default = nil)
  if valid_593074 != nil:
    section.add "X-Amz-Credential", valid_593074
  var valid_593075 = header.getOrDefault("X-Amz-Security-Token")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "X-Amz-Security-Token", valid_593075
  var valid_593076 = header.getOrDefault("X-Amz-Algorithm")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "X-Amz-Algorithm", valid_593076
  var valid_593077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-SignedHeaders", valid_593077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593079: Call_CreateJobTemplate_593068; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new job template. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ## 
  let valid = call_593079.validator(path, query, header, formData, body)
  let scheme = call_593079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593079.url(scheme.get, call_593079.host, call_593079.base,
                         call_593079.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593079, url, valid)

proc call*(call_593080: Call_CreateJobTemplate_593068; body: JsonNode): Recallable =
  ## createJobTemplate
  ## Create a new job template. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ##   body: JObject (required)
  var body_593081 = newJObject()
  if body != nil:
    body_593081 = body
  result = call_593080.call(nil, nil, nil, nil, body_593081)

var createJobTemplate* = Call_CreateJobTemplate_593068(name: "createJobTemplate",
    meth: HttpMethod.HttpPost, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates", validator: validate_CreateJobTemplate_593069,
    base: "/", url: url_CreateJobTemplate_593070,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobTemplates_593048 = ref object of OpenApiRestCall_592364
proc url_ListJobTemplates_593050(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListJobTemplates_593049(path: JsonNode; query: JsonNode;
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
  var valid_593051 = query.getOrDefault("nextToken")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "nextToken", valid_593051
  var valid_593052 = query.getOrDefault("MaxResults")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "MaxResults", valid_593052
  var valid_593053 = query.getOrDefault("listBy")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = newJString("NAME"))
  if valid_593053 != nil:
    section.add "listBy", valid_593053
  var valid_593054 = query.getOrDefault("order")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_593054 != nil:
    section.add "order", valid_593054
  var valid_593055 = query.getOrDefault("NextToken")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "NextToken", valid_593055
  var valid_593056 = query.getOrDefault("category")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "category", valid_593056
  var valid_593057 = query.getOrDefault("maxResults")
  valid_593057 = validateParameter(valid_593057, JInt, required = false, default = nil)
  if valid_593057 != nil:
    section.add "maxResults", valid_593057
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
  var valid_593058 = header.getOrDefault("X-Amz-Signature")
  valid_593058 = validateParameter(valid_593058, JString, required = false,
                                 default = nil)
  if valid_593058 != nil:
    section.add "X-Amz-Signature", valid_593058
  var valid_593059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593059 = validateParameter(valid_593059, JString, required = false,
                                 default = nil)
  if valid_593059 != nil:
    section.add "X-Amz-Content-Sha256", valid_593059
  var valid_593060 = header.getOrDefault("X-Amz-Date")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "X-Amz-Date", valid_593060
  var valid_593061 = header.getOrDefault("X-Amz-Credential")
  valid_593061 = validateParameter(valid_593061, JString, required = false,
                                 default = nil)
  if valid_593061 != nil:
    section.add "X-Amz-Credential", valid_593061
  var valid_593062 = header.getOrDefault("X-Amz-Security-Token")
  valid_593062 = validateParameter(valid_593062, JString, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "X-Amz-Security-Token", valid_593062
  var valid_593063 = header.getOrDefault("X-Amz-Algorithm")
  valid_593063 = validateParameter(valid_593063, JString, required = false,
                                 default = nil)
  if valid_593063 != nil:
    section.add "X-Amz-Algorithm", valid_593063
  var valid_593064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593064 = validateParameter(valid_593064, JString, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "X-Amz-SignedHeaders", valid_593064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593065: Call_ListJobTemplates_593048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a JSON array of up to twenty of your job templates. This will return the templates themselves, not just a list of them. To retrieve the next twenty templates, use the nextToken string returned with the array
  ## 
  let valid = call_593065.validator(path, query, header, formData, body)
  let scheme = call_593065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593065.url(scheme.get, call_593065.host, call_593065.base,
                         call_593065.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593065, url, valid)

proc call*(call_593066: Call_ListJobTemplates_593048; nextToken: string = "";
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
  var query_593067 = newJObject()
  add(query_593067, "nextToken", newJString(nextToken))
  add(query_593067, "MaxResults", newJString(MaxResults))
  add(query_593067, "listBy", newJString(listBy))
  add(query_593067, "order", newJString(order))
  add(query_593067, "NextToken", newJString(NextToken))
  add(query_593067, "category", newJString(category))
  add(query_593067, "maxResults", newJInt(maxResults))
  result = call_593066.call(nil, query_593067, nil, nil, nil)

var listJobTemplates* = Call_ListJobTemplates_593048(name: "listJobTemplates",
    meth: HttpMethod.HttpGet, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates", validator: validate_ListJobTemplates_593049,
    base: "/", url: url_ListJobTemplates_593050,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePreset_593102 = ref object of OpenApiRestCall_592364
proc url_CreatePreset_593104(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePreset_593103(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593105 = header.getOrDefault("X-Amz-Signature")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "X-Amz-Signature", valid_593105
  var valid_593106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593106 = validateParameter(valid_593106, JString, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "X-Amz-Content-Sha256", valid_593106
  var valid_593107 = header.getOrDefault("X-Amz-Date")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "X-Amz-Date", valid_593107
  var valid_593108 = header.getOrDefault("X-Amz-Credential")
  valid_593108 = validateParameter(valid_593108, JString, required = false,
                                 default = nil)
  if valid_593108 != nil:
    section.add "X-Amz-Credential", valid_593108
  var valid_593109 = header.getOrDefault("X-Amz-Security-Token")
  valid_593109 = validateParameter(valid_593109, JString, required = false,
                                 default = nil)
  if valid_593109 != nil:
    section.add "X-Amz-Security-Token", valid_593109
  var valid_593110 = header.getOrDefault("X-Amz-Algorithm")
  valid_593110 = validateParameter(valid_593110, JString, required = false,
                                 default = nil)
  if valid_593110 != nil:
    section.add "X-Amz-Algorithm", valid_593110
  var valid_593111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "X-Amz-SignedHeaders", valid_593111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593113: Call_CreatePreset_593102; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new preset. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ## 
  let valid = call_593113.validator(path, query, header, formData, body)
  let scheme = call_593113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593113.url(scheme.get, call_593113.host, call_593113.base,
                         call_593113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593113, url, valid)

proc call*(call_593114: Call_CreatePreset_593102; body: JsonNode): Recallable =
  ## createPreset
  ## Create a new preset. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ##   body: JObject (required)
  var body_593115 = newJObject()
  if body != nil:
    body_593115 = body
  result = call_593114.call(nil, nil, nil, nil, body_593115)

var createPreset* = Call_CreatePreset_593102(name: "createPreset",
    meth: HttpMethod.HttpPost, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/presets", validator: validate_CreatePreset_593103,
    base: "/", url: url_CreatePreset_593104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPresets_593082 = ref object of OpenApiRestCall_592364
proc url_ListPresets_593084(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPresets_593083(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593085 = query.getOrDefault("nextToken")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "nextToken", valid_593085
  var valid_593086 = query.getOrDefault("MaxResults")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "MaxResults", valid_593086
  var valid_593087 = query.getOrDefault("listBy")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = newJString("NAME"))
  if valid_593087 != nil:
    section.add "listBy", valid_593087
  var valid_593088 = query.getOrDefault("order")
  valid_593088 = validateParameter(valid_593088, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_593088 != nil:
    section.add "order", valid_593088
  var valid_593089 = query.getOrDefault("NextToken")
  valid_593089 = validateParameter(valid_593089, JString, required = false,
                                 default = nil)
  if valid_593089 != nil:
    section.add "NextToken", valid_593089
  var valid_593090 = query.getOrDefault("category")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "category", valid_593090
  var valid_593091 = query.getOrDefault("maxResults")
  valid_593091 = validateParameter(valid_593091, JInt, required = false, default = nil)
  if valid_593091 != nil:
    section.add "maxResults", valid_593091
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
  var valid_593092 = header.getOrDefault("X-Amz-Signature")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "X-Amz-Signature", valid_593092
  var valid_593093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593093 = validateParameter(valid_593093, JString, required = false,
                                 default = nil)
  if valid_593093 != nil:
    section.add "X-Amz-Content-Sha256", valid_593093
  var valid_593094 = header.getOrDefault("X-Amz-Date")
  valid_593094 = validateParameter(valid_593094, JString, required = false,
                                 default = nil)
  if valid_593094 != nil:
    section.add "X-Amz-Date", valid_593094
  var valid_593095 = header.getOrDefault("X-Amz-Credential")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "X-Amz-Credential", valid_593095
  var valid_593096 = header.getOrDefault("X-Amz-Security-Token")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "X-Amz-Security-Token", valid_593096
  var valid_593097 = header.getOrDefault("X-Amz-Algorithm")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "X-Amz-Algorithm", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-SignedHeaders", valid_593098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593099: Call_ListPresets_593082; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a JSON array of up to twenty of your presets. This will return the presets themselves, not just a list of them. To retrieve the next twenty presets, use the nextToken string returned with the array.
  ## 
  let valid = call_593099.validator(path, query, header, formData, body)
  let scheme = call_593099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593099.url(scheme.get, call_593099.host, call_593099.base,
                         call_593099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593099, url, valid)

proc call*(call_593100: Call_ListPresets_593082; nextToken: string = "";
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
  var query_593101 = newJObject()
  add(query_593101, "nextToken", newJString(nextToken))
  add(query_593101, "MaxResults", newJString(MaxResults))
  add(query_593101, "listBy", newJString(listBy))
  add(query_593101, "order", newJString(order))
  add(query_593101, "NextToken", newJString(NextToken))
  add(query_593101, "category", newJString(category))
  add(query_593101, "maxResults", newJInt(maxResults))
  result = call_593100.call(nil, query_593101, nil, nil, nil)

var listPresets* = Call_ListPresets_593082(name: "listPresets",
                                        meth: HttpMethod.HttpGet,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/presets",
                                        validator: validate_ListPresets_593083,
                                        base: "/", url: url_ListPresets_593084,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateQueue_593135 = ref object of OpenApiRestCall_592364
proc url_CreateQueue_593137(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateQueue_593136(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593138 = header.getOrDefault("X-Amz-Signature")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-Signature", valid_593138
  var valid_593139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "X-Amz-Content-Sha256", valid_593139
  var valid_593140 = header.getOrDefault("X-Amz-Date")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-Date", valid_593140
  var valid_593141 = header.getOrDefault("X-Amz-Credential")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-Credential", valid_593141
  var valid_593142 = header.getOrDefault("X-Amz-Security-Token")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-Security-Token", valid_593142
  var valid_593143 = header.getOrDefault("X-Amz-Algorithm")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-Algorithm", valid_593143
  var valid_593144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-SignedHeaders", valid_593144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593146: Call_CreateQueue_593135; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new transcoding queue. For information about queues, see Working With Queues in the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/working-with-queues.html
  ## 
  let valid = call_593146.validator(path, query, header, formData, body)
  let scheme = call_593146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593146.url(scheme.get, call_593146.host, call_593146.base,
                         call_593146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593146, url, valid)

proc call*(call_593147: Call_CreateQueue_593135; body: JsonNode): Recallable =
  ## createQueue
  ## Create a new transcoding queue. For information about queues, see Working With Queues in the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/working-with-queues.html
  ##   body: JObject (required)
  var body_593148 = newJObject()
  if body != nil:
    body_593148 = body
  result = call_593147.call(nil, nil, nil, nil, body_593148)

var createQueue* = Call_CreateQueue_593135(name: "createQueue",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/queues",
                                        validator: validate_CreateQueue_593136,
                                        base: "/", url: url_CreateQueue_593137,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQueues_593116 = ref object of OpenApiRestCall_592364
proc url_ListQueues_593118(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListQueues_593117(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593119 = query.getOrDefault("nextToken")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "nextToken", valid_593119
  var valid_593120 = query.getOrDefault("MaxResults")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "MaxResults", valid_593120
  var valid_593121 = query.getOrDefault("listBy")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = newJString("NAME"))
  if valid_593121 != nil:
    section.add "listBy", valid_593121
  var valid_593122 = query.getOrDefault("order")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_593122 != nil:
    section.add "order", valid_593122
  var valid_593123 = query.getOrDefault("NextToken")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "NextToken", valid_593123
  var valid_593124 = query.getOrDefault("maxResults")
  valid_593124 = validateParameter(valid_593124, JInt, required = false, default = nil)
  if valid_593124 != nil:
    section.add "maxResults", valid_593124
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
  var valid_593125 = header.getOrDefault("X-Amz-Signature")
  valid_593125 = validateParameter(valid_593125, JString, required = false,
                                 default = nil)
  if valid_593125 != nil:
    section.add "X-Amz-Signature", valid_593125
  var valid_593126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-Content-Sha256", valid_593126
  var valid_593127 = header.getOrDefault("X-Amz-Date")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-Date", valid_593127
  var valid_593128 = header.getOrDefault("X-Amz-Credential")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-Credential", valid_593128
  var valid_593129 = header.getOrDefault("X-Amz-Security-Token")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-Security-Token", valid_593129
  var valid_593130 = header.getOrDefault("X-Amz-Algorithm")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "X-Amz-Algorithm", valid_593130
  var valid_593131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "X-Amz-SignedHeaders", valid_593131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593132: Call_ListQueues_593116; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a JSON array of up to twenty of your queues. This will return the queues themselves, not just a list of them. To retrieve the next twenty queues, use the nextToken string returned with the array.
  ## 
  let valid = call_593132.validator(path, query, header, formData, body)
  let scheme = call_593132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593132.url(scheme.get, call_593132.host, call_593132.base,
                         call_593132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593132, url, valid)

proc call*(call_593133: Call_ListQueues_593116; nextToken: string = "";
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
  var query_593134 = newJObject()
  add(query_593134, "nextToken", newJString(nextToken))
  add(query_593134, "MaxResults", newJString(MaxResults))
  add(query_593134, "listBy", newJString(listBy))
  add(query_593134, "order", newJString(order))
  add(query_593134, "NextToken", newJString(NextToken))
  add(query_593134, "maxResults", newJInt(maxResults))
  result = call_593133.call(nil, query_593134, nil, nil, nil)

var listQueues* = Call_ListQueues_593116(name: "listQueues",
                                      meth: HttpMethod.HttpGet,
                                      host: "mediaconvert.amazonaws.com",
                                      route: "/2017-08-29/queues",
                                      validator: validate_ListQueues_593117,
                                      base: "/", url: url_ListQueues_593118,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJobTemplate_593163 = ref object of OpenApiRestCall_592364
proc url_UpdateJobTemplate_593165(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateJobTemplate_593164(path: JsonNode; query: JsonNode;
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
  var valid_593166 = path.getOrDefault("name")
  valid_593166 = validateParameter(valid_593166, JString, required = true,
                                 default = nil)
  if valid_593166 != nil:
    section.add "name", valid_593166
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
  var valid_593167 = header.getOrDefault("X-Amz-Signature")
  valid_593167 = validateParameter(valid_593167, JString, required = false,
                                 default = nil)
  if valid_593167 != nil:
    section.add "X-Amz-Signature", valid_593167
  var valid_593168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593168 = validateParameter(valid_593168, JString, required = false,
                                 default = nil)
  if valid_593168 != nil:
    section.add "X-Amz-Content-Sha256", valid_593168
  var valid_593169 = header.getOrDefault("X-Amz-Date")
  valid_593169 = validateParameter(valid_593169, JString, required = false,
                                 default = nil)
  if valid_593169 != nil:
    section.add "X-Amz-Date", valid_593169
  var valid_593170 = header.getOrDefault("X-Amz-Credential")
  valid_593170 = validateParameter(valid_593170, JString, required = false,
                                 default = nil)
  if valid_593170 != nil:
    section.add "X-Amz-Credential", valid_593170
  var valid_593171 = header.getOrDefault("X-Amz-Security-Token")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "X-Amz-Security-Token", valid_593171
  var valid_593172 = header.getOrDefault("X-Amz-Algorithm")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "X-Amz-Algorithm", valid_593172
  var valid_593173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-SignedHeaders", valid_593173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593175: Call_UpdateJobTemplate_593163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modify one of your existing job templates.
  ## 
  let valid = call_593175.validator(path, query, header, formData, body)
  let scheme = call_593175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593175.url(scheme.get, call_593175.host, call_593175.base,
                         call_593175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593175, url, valid)

proc call*(call_593176: Call_UpdateJobTemplate_593163; name: string; body: JsonNode): Recallable =
  ## updateJobTemplate
  ## Modify one of your existing job templates.
  ##   name: string (required)
  ##       : The name of the job template you are modifying
  ##   body: JObject (required)
  var path_593177 = newJObject()
  var body_593178 = newJObject()
  add(path_593177, "name", newJString(name))
  if body != nil:
    body_593178 = body
  result = call_593176.call(path_593177, nil, nil, nil, body_593178)

var updateJobTemplate* = Call_UpdateJobTemplate_593163(name: "updateJobTemplate",
    meth: HttpMethod.HttpPut, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates/{name}",
    validator: validate_UpdateJobTemplate_593164, base: "/",
    url: url_UpdateJobTemplate_593165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobTemplate_593149 = ref object of OpenApiRestCall_592364
proc url_GetJobTemplate_593151(protocol: Scheme; host: string; base: string;
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

proc validate_GetJobTemplate_593150(path: JsonNode; query: JsonNode;
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
  var valid_593152 = path.getOrDefault("name")
  valid_593152 = validateParameter(valid_593152, JString, required = true,
                                 default = nil)
  if valid_593152 != nil:
    section.add "name", valid_593152
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
  var valid_593153 = header.getOrDefault("X-Amz-Signature")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "X-Amz-Signature", valid_593153
  var valid_593154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "X-Amz-Content-Sha256", valid_593154
  var valid_593155 = header.getOrDefault("X-Amz-Date")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "X-Amz-Date", valid_593155
  var valid_593156 = header.getOrDefault("X-Amz-Credential")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "X-Amz-Credential", valid_593156
  var valid_593157 = header.getOrDefault("X-Amz-Security-Token")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-Security-Token", valid_593157
  var valid_593158 = header.getOrDefault("X-Amz-Algorithm")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-Algorithm", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-SignedHeaders", valid_593159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593160: Call_GetJobTemplate_593149; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the JSON for a specific job template.
  ## 
  let valid = call_593160.validator(path, query, header, formData, body)
  let scheme = call_593160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593160.url(scheme.get, call_593160.host, call_593160.base,
                         call_593160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593160, url, valid)

proc call*(call_593161: Call_GetJobTemplate_593149; name: string): Recallable =
  ## getJobTemplate
  ## Retrieve the JSON for a specific job template.
  ##   name: string (required)
  ##       : The name of the job template.
  var path_593162 = newJObject()
  add(path_593162, "name", newJString(name))
  result = call_593161.call(path_593162, nil, nil, nil, nil)

var getJobTemplate* = Call_GetJobTemplate_593149(name: "getJobTemplate",
    meth: HttpMethod.HttpGet, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates/{name}", validator: validate_GetJobTemplate_593150,
    base: "/", url: url_GetJobTemplate_593151, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJobTemplate_593179 = ref object of OpenApiRestCall_592364
proc url_DeleteJobTemplate_593181(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteJobTemplate_593180(path: JsonNode; query: JsonNode;
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
  var valid_593182 = path.getOrDefault("name")
  valid_593182 = validateParameter(valid_593182, JString, required = true,
                                 default = nil)
  if valid_593182 != nil:
    section.add "name", valid_593182
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
  var valid_593183 = header.getOrDefault("X-Amz-Signature")
  valid_593183 = validateParameter(valid_593183, JString, required = false,
                                 default = nil)
  if valid_593183 != nil:
    section.add "X-Amz-Signature", valid_593183
  var valid_593184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593184 = validateParameter(valid_593184, JString, required = false,
                                 default = nil)
  if valid_593184 != nil:
    section.add "X-Amz-Content-Sha256", valid_593184
  var valid_593185 = header.getOrDefault("X-Amz-Date")
  valid_593185 = validateParameter(valid_593185, JString, required = false,
                                 default = nil)
  if valid_593185 != nil:
    section.add "X-Amz-Date", valid_593185
  var valid_593186 = header.getOrDefault("X-Amz-Credential")
  valid_593186 = validateParameter(valid_593186, JString, required = false,
                                 default = nil)
  if valid_593186 != nil:
    section.add "X-Amz-Credential", valid_593186
  var valid_593187 = header.getOrDefault("X-Amz-Security-Token")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-Security-Token", valid_593187
  var valid_593188 = header.getOrDefault("X-Amz-Algorithm")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-Algorithm", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-SignedHeaders", valid_593189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593190: Call_DeleteJobTemplate_593179; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently delete a job template you have created.
  ## 
  let valid = call_593190.validator(path, query, header, formData, body)
  let scheme = call_593190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593190.url(scheme.get, call_593190.host, call_593190.base,
                         call_593190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593190, url, valid)

proc call*(call_593191: Call_DeleteJobTemplate_593179; name: string): Recallable =
  ## deleteJobTemplate
  ## Permanently delete a job template you have created.
  ##   name: string (required)
  ##       : The name of the job template to be deleted.
  var path_593192 = newJObject()
  add(path_593192, "name", newJString(name))
  result = call_593191.call(path_593192, nil, nil, nil, nil)

var deleteJobTemplate* = Call_DeleteJobTemplate_593179(name: "deleteJobTemplate",
    meth: HttpMethod.HttpDelete, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates/{name}",
    validator: validate_DeleteJobTemplate_593180, base: "/",
    url: url_DeleteJobTemplate_593181, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePreset_593207 = ref object of OpenApiRestCall_592364
proc url_UpdatePreset_593209(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePreset_593208(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593210 = path.getOrDefault("name")
  valid_593210 = validateParameter(valid_593210, JString, required = true,
                                 default = nil)
  if valid_593210 != nil:
    section.add "name", valid_593210
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
  var valid_593211 = header.getOrDefault("X-Amz-Signature")
  valid_593211 = validateParameter(valid_593211, JString, required = false,
                                 default = nil)
  if valid_593211 != nil:
    section.add "X-Amz-Signature", valid_593211
  var valid_593212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593212 = validateParameter(valid_593212, JString, required = false,
                                 default = nil)
  if valid_593212 != nil:
    section.add "X-Amz-Content-Sha256", valid_593212
  var valid_593213 = header.getOrDefault("X-Amz-Date")
  valid_593213 = validateParameter(valid_593213, JString, required = false,
                                 default = nil)
  if valid_593213 != nil:
    section.add "X-Amz-Date", valid_593213
  var valid_593214 = header.getOrDefault("X-Amz-Credential")
  valid_593214 = validateParameter(valid_593214, JString, required = false,
                                 default = nil)
  if valid_593214 != nil:
    section.add "X-Amz-Credential", valid_593214
  var valid_593215 = header.getOrDefault("X-Amz-Security-Token")
  valid_593215 = validateParameter(valid_593215, JString, required = false,
                                 default = nil)
  if valid_593215 != nil:
    section.add "X-Amz-Security-Token", valid_593215
  var valid_593216 = header.getOrDefault("X-Amz-Algorithm")
  valid_593216 = validateParameter(valid_593216, JString, required = false,
                                 default = nil)
  if valid_593216 != nil:
    section.add "X-Amz-Algorithm", valid_593216
  var valid_593217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593217 = validateParameter(valid_593217, JString, required = false,
                                 default = nil)
  if valid_593217 != nil:
    section.add "X-Amz-SignedHeaders", valid_593217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593219: Call_UpdatePreset_593207; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modify one of your existing presets.
  ## 
  let valid = call_593219.validator(path, query, header, formData, body)
  let scheme = call_593219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593219.url(scheme.get, call_593219.host, call_593219.base,
                         call_593219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593219, url, valid)

proc call*(call_593220: Call_UpdatePreset_593207; name: string; body: JsonNode): Recallable =
  ## updatePreset
  ## Modify one of your existing presets.
  ##   name: string (required)
  ##       : The name of the preset you are modifying.
  ##   body: JObject (required)
  var path_593221 = newJObject()
  var body_593222 = newJObject()
  add(path_593221, "name", newJString(name))
  if body != nil:
    body_593222 = body
  result = call_593220.call(path_593221, nil, nil, nil, body_593222)

var updatePreset* = Call_UpdatePreset_593207(name: "updatePreset",
    meth: HttpMethod.HttpPut, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/presets/{name}", validator: validate_UpdatePreset_593208,
    base: "/", url: url_UpdatePreset_593209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPreset_593193 = ref object of OpenApiRestCall_592364
proc url_GetPreset_593195(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetPreset_593194(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593196 = path.getOrDefault("name")
  valid_593196 = validateParameter(valid_593196, JString, required = true,
                                 default = nil)
  if valid_593196 != nil:
    section.add "name", valid_593196
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
  var valid_593197 = header.getOrDefault("X-Amz-Signature")
  valid_593197 = validateParameter(valid_593197, JString, required = false,
                                 default = nil)
  if valid_593197 != nil:
    section.add "X-Amz-Signature", valid_593197
  var valid_593198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593198 = validateParameter(valid_593198, JString, required = false,
                                 default = nil)
  if valid_593198 != nil:
    section.add "X-Amz-Content-Sha256", valid_593198
  var valid_593199 = header.getOrDefault("X-Amz-Date")
  valid_593199 = validateParameter(valid_593199, JString, required = false,
                                 default = nil)
  if valid_593199 != nil:
    section.add "X-Amz-Date", valid_593199
  var valid_593200 = header.getOrDefault("X-Amz-Credential")
  valid_593200 = validateParameter(valid_593200, JString, required = false,
                                 default = nil)
  if valid_593200 != nil:
    section.add "X-Amz-Credential", valid_593200
  var valid_593201 = header.getOrDefault("X-Amz-Security-Token")
  valid_593201 = validateParameter(valid_593201, JString, required = false,
                                 default = nil)
  if valid_593201 != nil:
    section.add "X-Amz-Security-Token", valid_593201
  var valid_593202 = header.getOrDefault("X-Amz-Algorithm")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-Algorithm", valid_593202
  var valid_593203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593203 = validateParameter(valid_593203, JString, required = false,
                                 default = nil)
  if valid_593203 != nil:
    section.add "X-Amz-SignedHeaders", valid_593203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593204: Call_GetPreset_593193; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the JSON for a specific preset.
  ## 
  let valid = call_593204.validator(path, query, header, formData, body)
  let scheme = call_593204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593204.url(scheme.get, call_593204.host, call_593204.base,
                         call_593204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593204, url, valid)

proc call*(call_593205: Call_GetPreset_593193; name: string): Recallable =
  ## getPreset
  ## Retrieve the JSON for a specific preset.
  ##   name: string (required)
  ##       : The name of the preset.
  var path_593206 = newJObject()
  add(path_593206, "name", newJString(name))
  result = call_593205.call(path_593206, nil, nil, nil, nil)

var getPreset* = Call_GetPreset_593193(name: "getPreset", meth: HttpMethod.HttpGet,
                                    host: "mediaconvert.amazonaws.com",
                                    route: "/2017-08-29/presets/{name}",
                                    validator: validate_GetPreset_593194,
                                    base: "/", url: url_GetPreset_593195,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePreset_593223 = ref object of OpenApiRestCall_592364
proc url_DeletePreset_593225(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePreset_593224(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593226 = path.getOrDefault("name")
  valid_593226 = validateParameter(valid_593226, JString, required = true,
                                 default = nil)
  if valid_593226 != nil:
    section.add "name", valid_593226
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
  var valid_593227 = header.getOrDefault("X-Amz-Signature")
  valid_593227 = validateParameter(valid_593227, JString, required = false,
                                 default = nil)
  if valid_593227 != nil:
    section.add "X-Amz-Signature", valid_593227
  var valid_593228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593228 = validateParameter(valid_593228, JString, required = false,
                                 default = nil)
  if valid_593228 != nil:
    section.add "X-Amz-Content-Sha256", valid_593228
  var valid_593229 = header.getOrDefault("X-Amz-Date")
  valid_593229 = validateParameter(valid_593229, JString, required = false,
                                 default = nil)
  if valid_593229 != nil:
    section.add "X-Amz-Date", valid_593229
  var valid_593230 = header.getOrDefault("X-Amz-Credential")
  valid_593230 = validateParameter(valid_593230, JString, required = false,
                                 default = nil)
  if valid_593230 != nil:
    section.add "X-Amz-Credential", valid_593230
  var valid_593231 = header.getOrDefault("X-Amz-Security-Token")
  valid_593231 = validateParameter(valid_593231, JString, required = false,
                                 default = nil)
  if valid_593231 != nil:
    section.add "X-Amz-Security-Token", valid_593231
  var valid_593232 = header.getOrDefault("X-Amz-Algorithm")
  valid_593232 = validateParameter(valid_593232, JString, required = false,
                                 default = nil)
  if valid_593232 != nil:
    section.add "X-Amz-Algorithm", valid_593232
  var valid_593233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593233 = validateParameter(valid_593233, JString, required = false,
                                 default = nil)
  if valid_593233 != nil:
    section.add "X-Amz-SignedHeaders", valid_593233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593234: Call_DeletePreset_593223; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently delete a preset you have created.
  ## 
  let valid = call_593234.validator(path, query, header, formData, body)
  let scheme = call_593234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593234.url(scheme.get, call_593234.host, call_593234.base,
                         call_593234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593234, url, valid)

proc call*(call_593235: Call_DeletePreset_593223; name: string): Recallable =
  ## deletePreset
  ## Permanently delete a preset you have created.
  ##   name: string (required)
  ##       : The name of the preset to be deleted.
  var path_593236 = newJObject()
  add(path_593236, "name", newJString(name))
  result = call_593235.call(path_593236, nil, nil, nil, nil)

var deletePreset* = Call_DeletePreset_593223(name: "deletePreset",
    meth: HttpMethod.HttpDelete, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/presets/{name}", validator: validate_DeletePreset_593224,
    base: "/", url: url_DeletePreset_593225, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateQueue_593251 = ref object of OpenApiRestCall_592364
proc url_UpdateQueue_593253(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateQueue_593252(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593254 = path.getOrDefault("name")
  valid_593254 = validateParameter(valid_593254, JString, required = true,
                                 default = nil)
  if valid_593254 != nil:
    section.add "name", valid_593254
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
  var valid_593255 = header.getOrDefault("X-Amz-Signature")
  valid_593255 = validateParameter(valid_593255, JString, required = false,
                                 default = nil)
  if valid_593255 != nil:
    section.add "X-Amz-Signature", valid_593255
  var valid_593256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593256 = validateParameter(valid_593256, JString, required = false,
                                 default = nil)
  if valid_593256 != nil:
    section.add "X-Amz-Content-Sha256", valid_593256
  var valid_593257 = header.getOrDefault("X-Amz-Date")
  valid_593257 = validateParameter(valid_593257, JString, required = false,
                                 default = nil)
  if valid_593257 != nil:
    section.add "X-Amz-Date", valid_593257
  var valid_593258 = header.getOrDefault("X-Amz-Credential")
  valid_593258 = validateParameter(valid_593258, JString, required = false,
                                 default = nil)
  if valid_593258 != nil:
    section.add "X-Amz-Credential", valid_593258
  var valid_593259 = header.getOrDefault("X-Amz-Security-Token")
  valid_593259 = validateParameter(valid_593259, JString, required = false,
                                 default = nil)
  if valid_593259 != nil:
    section.add "X-Amz-Security-Token", valid_593259
  var valid_593260 = header.getOrDefault("X-Amz-Algorithm")
  valid_593260 = validateParameter(valid_593260, JString, required = false,
                                 default = nil)
  if valid_593260 != nil:
    section.add "X-Amz-Algorithm", valid_593260
  var valid_593261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593261 = validateParameter(valid_593261, JString, required = false,
                                 default = nil)
  if valid_593261 != nil:
    section.add "X-Amz-SignedHeaders", valid_593261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593263: Call_UpdateQueue_593251; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modify one of your existing queues.
  ## 
  let valid = call_593263.validator(path, query, header, formData, body)
  let scheme = call_593263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593263.url(scheme.get, call_593263.host, call_593263.base,
                         call_593263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593263, url, valid)

proc call*(call_593264: Call_UpdateQueue_593251; name: string; body: JsonNode): Recallable =
  ## updateQueue
  ## Modify one of your existing queues.
  ##   name: string (required)
  ##       : The name of the queue that you are modifying.
  ##   body: JObject (required)
  var path_593265 = newJObject()
  var body_593266 = newJObject()
  add(path_593265, "name", newJString(name))
  if body != nil:
    body_593266 = body
  result = call_593264.call(path_593265, nil, nil, nil, body_593266)

var updateQueue* = Call_UpdateQueue_593251(name: "updateQueue",
                                        meth: HttpMethod.HttpPut,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/queues/{name}",
                                        validator: validate_UpdateQueue_593252,
                                        base: "/", url: url_UpdateQueue_593253,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQueue_593237 = ref object of OpenApiRestCall_592364
proc url_GetQueue_593239(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetQueue_593238(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593240 = path.getOrDefault("name")
  valid_593240 = validateParameter(valid_593240, JString, required = true,
                                 default = nil)
  if valid_593240 != nil:
    section.add "name", valid_593240
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
  var valid_593241 = header.getOrDefault("X-Amz-Signature")
  valid_593241 = validateParameter(valid_593241, JString, required = false,
                                 default = nil)
  if valid_593241 != nil:
    section.add "X-Amz-Signature", valid_593241
  var valid_593242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593242 = validateParameter(valid_593242, JString, required = false,
                                 default = nil)
  if valid_593242 != nil:
    section.add "X-Amz-Content-Sha256", valid_593242
  var valid_593243 = header.getOrDefault("X-Amz-Date")
  valid_593243 = validateParameter(valid_593243, JString, required = false,
                                 default = nil)
  if valid_593243 != nil:
    section.add "X-Amz-Date", valid_593243
  var valid_593244 = header.getOrDefault("X-Amz-Credential")
  valid_593244 = validateParameter(valid_593244, JString, required = false,
                                 default = nil)
  if valid_593244 != nil:
    section.add "X-Amz-Credential", valid_593244
  var valid_593245 = header.getOrDefault("X-Amz-Security-Token")
  valid_593245 = validateParameter(valid_593245, JString, required = false,
                                 default = nil)
  if valid_593245 != nil:
    section.add "X-Amz-Security-Token", valid_593245
  var valid_593246 = header.getOrDefault("X-Amz-Algorithm")
  valid_593246 = validateParameter(valid_593246, JString, required = false,
                                 default = nil)
  if valid_593246 != nil:
    section.add "X-Amz-Algorithm", valid_593246
  var valid_593247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593247 = validateParameter(valid_593247, JString, required = false,
                                 default = nil)
  if valid_593247 != nil:
    section.add "X-Amz-SignedHeaders", valid_593247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593248: Call_GetQueue_593237; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the JSON for a specific queue.
  ## 
  let valid = call_593248.validator(path, query, header, formData, body)
  let scheme = call_593248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593248.url(scheme.get, call_593248.host, call_593248.base,
                         call_593248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593248, url, valid)

proc call*(call_593249: Call_GetQueue_593237; name: string): Recallable =
  ## getQueue
  ## Retrieve the JSON for a specific queue.
  ##   name: string (required)
  ##       : The name of the queue that you want information about.
  var path_593250 = newJObject()
  add(path_593250, "name", newJString(name))
  result = call_593249.call(path_593250, nil, nil, nil, nil)

var getQueue* = Call_GetQueue_593237(name: "getQueue", meth: HttpMethod.HttpGet,
                                  host: "mediaconvert.amazonaws.com",
                                  route: "/2017-08-29/queues/{name}",
                                  validator: validate_GetQueue_593238, base: "/",
                                  url: url_GetQueue_593239,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteQueue_593267 = ref object of OpenApiRestCall_592364
proc url_DeleteQueue_593269(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteQueue_593268(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593270 = path.getOrDefault("name")
  valid_593270 = validateParameter(valid_593270, JString, required = true,
                                 default = nil)
  if valid_593270 != nil:
    section.add "name", valid_593270
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
  var valid_593271 = header.getOrDefault("X-Amz-Signature")
  valid_593271 = validateParameter(valid_593271, JString, required = false,
                                 default = nil)
  if valid_593271 != nil:
    section.add "X-Amz-Signature", valid_593271
  var valid_593272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593272 = validateParameter(valid_593272, JString, required = false,
                                 default = nil)
  if valid_593272 != nil:
    section.add "X-Amz-Content-Sha256", valid_593272
  var valid_593273 = header.getOrDefault("X-Amz-Date")
  valid_593273 = validateParameter(valid_593273, JString, required = false,
                                 default = nil)
  if valid_593273 != nil:
    section.add "X-Amz-Date", valid_593273
  var valid_593274 = header.getOrDefault("X-Amz-Credential")
  valid_593274 = validateParameter(valid_593274, JString, required = false,
                                 default = nil)
  if valid_593274 != nil:
    section.add "X-Amz-Credential", valid_593274
  var valid_593275 = header.getOrDefault("X-Amz-Security-Token")
  valid_593275 = validateParameter(valid_593275, JString, required = false,
                                 default = nil)
  if valid_593275 != nil:
    section.add "X-Amz-Security-Token", valid_593275
  var valid_593276 = header.getOrDefault("X-Amz-Algorithm")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "X-Amz-Algorithm", valid_593276
  var valid_593277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "X-Amz-SignedHeaders", valid_593277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593278: Call_DeleteQueue_593267; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently delete a queue you have created.
  ## 
  let valid = call_593278.validator(path, query, header, formData, body)
  let scheme = call_593278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593278.url(scheme.get, call_593278.host, call_593278.base,
                         call_593278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593278, url, valid)

proc call*(call_593279: Call_DeleteQueue_593267; name: string): Recallable =
  ## deleteQueue
  ## Permanently delete a queue you have created.
  ##   name: string (required)
  ##       : The name of the queue that you want to delete.
  var path_593280 = newJObject()
  add(path_593280, "name", newJString(name))
  result = call_593279.call(path_593280, nil, nil, nil, nil)

var deleteQueue* = Call_DeleteQueue_593267(name: "deleteQueue",
                                        meth: HttpMethod.HttpDelete,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/queues/{name}",
                                        validator: validate_DeleteQueue_593268,
                                        base: "/", url: url_DeleteQueue_593269,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoints_593281 = ref object of OpenApiRestCall_592364
proc url_DescribeEndpoints_593283(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEndpoints_593282(path: JsonNode; query: JsonNode;
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
  var valid_593284 = query.getOrDefault("MaxResults")
  valid_593284 = validateParameter(valid_593284, JString, required = false,
                                 default = nil)
  if valid_593284 != nil:
    section.add "MaxResults", valid_593284
  var valid_593285 = query.getOrDefault("NextToken")
  valid_593285 = validateParameter(valid_593285, JString, required = false,
                                 default = nil)
  if valid_593285 != nil:
    section.add "NextToken", valid_593285
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
  var valid_593286 = header.getOrDefault("X-Amz-Signature")
  valid_593286 = validateParameter(valid_593286, JString, required = false,
                                 default = nil)
  if valid_593286 != nil:
    section.add "X-Amz-Signature", valid_593286
  var valid_593287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593287 = validateParameter(valid_593287, JString, required = false,
                                 default = nil)
  if valid_593287 != nil:
    section.add "X-Amz-Content-Sha256", valid_593287
  var valid_593288 = header.getOrDefault("X-Amz-Date")
  valid_593288 = validateParameter(valid_593288, JString, required = false,
                                 default = nil)
  if valid_593288 != nil:
    section.add "X-Amz-Date", valid_593288
  var valid_593289 = header.getOrDefault("X-Amz-Credential")
  valid_593289 = validateParameter(valid_593289, JString, required = false,
                                 default = nil)
  if valid_593289 != nil:
    section.add "X-Amz-Credential", valid_593289
  var valid_593290 = header.getOrDefault("X-Amz-Security-Token")
  valid_593290 = validateParameter(valid_593290, JString, required = false,
                                 default = nil)
  if valid_593290 != nil:
    section.add "X-Amz-Security-Token", valid_593290
  var valid_593291 = header.getOrDefault("X-Amz-Algorithm")
  valid_593291 = validateParameter(valid_593291, JString, required = false,
                                 default = nil)
  if valid_593291 != nil:
    section.add "X-Amz-Algorithm", valid_593291
  var valid_593292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593292 = validateParameter(valid_593292, JString, required = false,
                                 default = nil)
  if valid_593292 != nil:
    section.add "X-Amz-SignedHeaders", valid_593292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593294: Call_DescribeEndpoints_593281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Send an request with an empty body to the regional API endpoint to get your account API endpoint.
  ## 
  let valid = call_593294.validator(path, query, header, formData, body)
  let scheme = call_593294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593294.url(scheme.get, call_593294.host, call_593294.base,
                         call_593294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593294, url, valid)

proc call*(call_593295: Call_DescribeEndpoints_593281; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeEndpoints
  ## Send an request with an empty body to the regional API endpoint to get your account API endpoint.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593296 = newJObject()
  var body_593297 = newJObject()
  add(query_593296, "MaxResults", newJString(MaxResults))
  add(query_593296, "NextToken", newJString(NextToken))
  if body != nil:
    body_593297 = body
  result = call_593295.call(nil, query_593296, nil, nil, body_593297)

var describeEndpoints* = Call_DescribeEndpoints_593281(name: "describeEndpoints",
    meth: HttpMethod.HttpPost, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/endpoints", validator: validate_DescribeEndpoints_593282,
    base: "/", url: url_DescribeEndpoints_593283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateCertificate_593298 = ref object of OpenApiRestCall_592364
proc url_DisassociateCertificate_593300(protocol: Scheme; host: string; base: string;
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

proc validate_DisassociateCertificate_593299(path: JsonNode; query: JsonNode;
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
  var valid_593301 = path.getOrDefault("arn")
  valid_593301 = validateParameter(valid_593301, JString, required = true,
                                 default = nil)
  if valid_593301 != nil:
    section.add "arn", valid_593301
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
  var valid_593302 = header.getOrDefault("X-Amz-Signature")
  valid_593302 = validateParameter(valid_593302, JString, required = false,
                                 default = nil)
  if valid_593302 != nil:
    section.add "X-Amz-Signature", valid_593302
  var valid_593303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593303 = validateParameter(valid_593303, JString, required = false,
                                 default = nil)
  if valid_593303 != nil:
    section.add "X-Amz-Content-Sha256", valid_593303
  var valid_593304 = header.getOrDefault("X-Amz-Date")
  valid_593304 = validateParameter(valid_593304, JString, required = false,
                                 default = nil)
  if valid_593304 != nil:
    section.add "X-Amz-Date", valid_593304
  var valid_593305 = header.getOrDefault("X-Amz-Credential")
  valid_593305 = validateParameter(valid_593305, JString, required = false,
                                 default = nil)
  if valid_593305 != nil:
    section.add "X-Amz-Credential", valid_593305
  var valid_593306 = header.getOrDefault("X-Amz-Security-Token")
  valid_593306 = validateParameter(valid_593306, JString, required = false,
                                 default = nil)
  if valid_593306 != nil:
    section.add "X-Amz-Security-Token", valid_593306
  var valid_593307 = header.getOrDefault("X-Amz-Algorithm")
  valid_593307 = validateParameter(valid_593307, JString, required = false,
                                 default = nil)
  if valid_593307 != nil:
    section.add "X-Amz-Algorithm", valid_593307
  var valid_593308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593308 = validateParameter(valid_593308, JString, required = false,
                                 default = nil)
  if valid_593308 != nil:
    section.add "X-Amz-SignedHeaders", valid_593308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593309: Call_DisassociateCertificate_593298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an association between the Amazon Resource Name (ARN) of an AWS Certificate Manager (ACM) certificate and an AWS Elemental MediaConvert resource.
  ## 
  let valid = call_593309.validator(path, query, header, formData, body)
  let scheme = call_593309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593309.url(scheme.get, call_593309.host, call_593309.base,
                         call_593309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593309, url, valid)

proc call*(call_593310: Call_DisassociateCertificate_593298; arn: string): Recallable =
  ## disassociateCertificate
  ## Removes an association between the Amazon Resource Name (ARN) of an AWS Certificate Manager (ACM) certificate and an AWS Elemental MediaConvert resource.
  ##   arn: string (required)
  ##      : The ARN of the ACM certificate that you want to disassociate from your MediaConvert resource.
  var path_593311 = newJObject()
  add(path_593311, "arn", newJString(arn))
  result = call_593310.call(path_593311, nil, nil, nil, nil)

var disassociateCertificate* = Call_DisassociateCertificate_593298(
    name: "disassociateCertificate", meth: HttpMethod.HttpDelete,
    host: "mediaconvert.amazonaws.com", route: "/2017-08-29/certificates/{arn}",
    validator: validate_DisassociateCertificate_593299, base: "/",
    url: url_DisassociateCertificate_593300, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_593326 = ref object of OpenApiRestCall_592364
proc url_UntagResource_593328(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_593327(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593329 = path.getOrDefault("arn")
  valid_593329 = validateParameter(valid_593329, JString, required = true,
                                 default = nil)
  if valid_593329 != nil:
    section.add "arn", valid_593329
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
  var valid_593330 = header.getOrDefault("X-Amz-Signature")
  valid_593330 = validateParameter(valid_593330, JString, required = false,
                                 default = nil)
  if valid_593330 != nil:
    section.add "X-Amz-Signature", valid_593330
  var valid_593331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593331 = validateParameter(valid_593331, JString, required = false,
                                 default = nil)
  if valid_593331 != nil:
    section.add "X-Amz-Content-Sha256", valid_593331
  var valid_593332 = header.getOrDefault("X-Amz-Date")
  valid_593332 = validateParameter(valid_593332, JString, required = false,
                                 default = nil)
  if valid_593332 != nil:
    section.add "X-Amz-Date", valid_593332
  var valid_593333 = header.getOrDefault("X-Amz-Credential")
  valid_593333 = validateParameter(valid_593333, JString, required = false,
                                 default = nil)
  if valid_593333 != nil:
    section.add "X-Amz-Credential", valid_593333
  var valid_593334 = header.getOrDefault("X-Amz-Security-Token")
  valid_593334 = validateParameter(valid_593334, JString, required = false,
                                 default = nil)
  if valid_593334 != nil:
    section.add "X-Amz-Security-Token", valid_593334
  var valid_593335 = header.getOrDefault("X-Amz-Algorithm")
  valid_593335 = validateParameter(valid_593335, JString, required = false,
                                 default = nil)
  if valid_593335 != nil:
    section.add "X-Amz-Algorithm", valid_593335
  var valid_593336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593336 = validateParameter(valid_593336, JString, required = false,
                                 default = nil)
  if valid_593336 != nil:
    section.add "X-Amz-SignedHeaders", valid_593336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593338: Call_UntagResource_593326; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ## 
  let valid = call_593338.validator(path, query, header, formData, body)
  let scheme = call_593338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593338.url(scheme.get, call_593338.host, call_593338.base,
                         call_593338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593338, url, valid)

proc call*(call_593339: Call_UntagResource_593326; arn: string; body: JsonNode): Recallable =
  ## untagResource
  ## Remove tags from a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ##   arn: string (required)
  ##      : The Amazon Resource Name (ARN) of the resource that you want to remove tags from. To get the ARN, send a GET request with the resource name.
  ##   body: JObject (required)
  var path_593340 = newJObject()
  var body_593341 = newJObject()
  add(path_593340, "arn", newJString(arn))
  if body != nil:
    body_593341 = body
  result = call_593339.call(path_593340, nil, nil, nil, body_593341)

var untagResource* = Call_UntagResource_593326(name: "untagResource",
    meth: HttpMethod.HttpPut, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/tags/{arn}", validator: validate_UntagResource_593327,
    base: "/", url: url_UntagResource_593328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_593312 = ref object of OpenApiRestCall_592364
proc url_ListTagsForResource_593314(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_593313(path: JsonNode; query: JsonNode;
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
  var valid_593315 = path.getOrDefault("arn")
  valid_593315 = validateParameter(valid_593315, JString, required = true,
                                 default = nil)
  if valid_593315 != nil:
    section.add "arn", valid_593315
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
  var valid_593316 = header.getOrDefault("X-Amz-Signature")
  valid_593316 = validateParameter(valid_593316, JString, required = false,
                                 default = nil)
  if valid_593316 != nil:
    section.add "X-Amz-Signature", valid_593316
  var valid_593317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593317 = validateParameter(valid_593317, JString, required = false,
                                 default = nil)
  if valid_593317 != nil:
    section.add "X-Amz-Content-Sha256", valid_593317
  var valid_593318 = header.getOrDefault("X-Amz-Date")
  valid_593318 = validateParameter(valid_593318, JString, required = false,
                                 default = nil)
  if valid_593318 != nil:
    section.add "X-Amz-Date", valid_593318
  var valid_593319 = header.getOrDefault("X-Amz-Credential")
  valid_593319 = validateParameter(valid_593319, JString, required = false,
                                 default = nil)
  if valid_593319 != nil:
    section.add "X-Amz-Credential", valid_593319
  var valid_593320 = header.getOrDefault("X-Amz-Security-Token")
  valid_593320 = validateParameter(valid_593320, JString, required = false,
                                 default = nil)
  if valid_593320 != nil:
    section.add "X-Amz-Security-Token", valid_593320
  var valid_593321 = header.getOrDefault("X-Amz-Algorithm")
  valid_593321 = validateParameter(valid_593321, JString, required = false,
                                 default = nil)
  if valid_593321 != nil:
    section.add "X-Amz-Algorithm", valid_593321
  var valid_593322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593322 = validateParameter(valid_593322, JString, required = false,
                                 default = nil)
  if valid_593322 != nil:
    section.add "X-Amz-SignedHeaders", valid_593322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593323: Call_ListTagsForResource_593312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the tags for a MediaConvert resource.
  ## 
  let valid = call_593323.validator(path, query, header, formData, body)
  let scheme = call_593323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593323.url(scheme.get, call_593323.host, call_593323.base,
                         call_593323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593323, url, valid)

proc call*(call_593324: Call_ListTagsForResource_593312; arn: string): Recallable =
  ## listTagsForResource
  ## Retrieve the tags for a MediaConvert resource.
  ##   arn: string (required)
  ##      : The Amazon Resource Name (ARN) of the resource that you want to list tags for. To get the ARN, send a GET request with the resource name.
  var path_593325 = newJObject()
  add(path_593325, "arn", newJString(arn))
  result = call_593324.call(path_593325, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_593312(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "mediaconvert.amazonaws.com", route: "/2017-08-29/tags/{arn}",
    validator: validate_ListTagsForResource_593313, base: "/",
    url: url_ListTagsForResource_593314, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_593342 = ref object of OpenApiRestCall_592364
proc url_TagResource_593344(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_593343(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593345 = header.getOrDefault("X-Amz-Signature")
  valid_593345 = validateParameter(valid_593345, JString, required = false,
                                 default = nil)
  if valid_593345 != nil:
    section.add "X-Amz-Signature", valid_593345
  var valid_593346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593346 = validateParameter(valid_593346, JString, required = false,
                                 default = nil)
  if valid_593346 != nil:
    section.add "X-Amz-Content-Sha256", valid_593346
  var valid_593347 = header.getOrDefault("X-Amz-Date")
  valid_593347 = validateParameter(valid_593347, JString, required = false,
                                 default = nil)
  if valid_593347 != nil:
    section.add "X-Amz-Date", valid_593347
  var valid_593348 = header.getOrDefault("X-Amz-Credential")
  valid_593348 = validateParameter(valid_593348, JString, required = false,
                                 default = nil)
  if valid_593348 != nil:
    section.add "X-Amz-Credential", valid_593348
  var valid_593349 = header.getOrDefault("X-Amz-Security-Token")
  valid_593349 = validateParameter(valid_593349, JString, required = false,
                                 default = nil)
  if valid_593349 != nil:
    section.add "X-Amz-Security-Token", valid_593349
  var valid_593350 = header.getOrDefault("X-Amz-Algorithm")
  valid_593350 = validateParameter(valid_593350, JString, required = false,
                                 default = nil)
  if valid_593350 != nil:
    section.add "X-Amz-Algorithm", valid_593350
  var valid_593351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593351 = validateParameter(valid_593351, JString, required = false,
                                 default = nil)
  if valid_593351 != nil:
    section.add "X-Amz-SignedHeaders", valid_593351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593353: Call_TagResource_593342; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add tags to a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ## 
  let valid = call_593353.validator(path, query, header, formData, body)
  let scheme = call_593353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593353.url(scheme.get, call_593353.host, call_593353.base,
                         call_593353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593353, url, valid)

proc call*(call_593354: Call_TagResource_593342; body: JsonNode): Recallable =
  ## tagResource
  ## Add tags to a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ##   body: JObject (required)
  var body_593355 = newJObject()
  if body != nil:
    body_593355 = body
  result = call_593354.call(nil, nil, nil, nil, body_593355)

var tagResource* = Call_TagResource_593342(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/tags",
                                        validator: validate_TagResource_593343,
                                        base: "/", url: url_TagResource_593344,
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
