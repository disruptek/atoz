
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateCertificate_599705 = ref object of OpenApiRestCall_599368
proc url_AssociateCertificate_599707(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateCertificate_599706(path: JsonNode; query: JsonNode;
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
  var valid_599819 = header.getOrDefault("X-Amz-Date")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "X-Amz-Date", valid_599819
  var valid_599820 = header.getOrDefault("X-Amz-Security-Token")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Security-Token", valid_599820
  var valid_599821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599821 = validateParameter(valid_599821, JString, required = false,
                                 default = nil)
  if valid_599821 != nil:
    section.add "X-Amz-Content-Sha256", valid_599821
  var valid_599822 = header.getOrDefault("X-Amz-Algorithm")
  valid_599822 = validateParameter(valid_599822, JString, required = false,
                                 default = nil)
  if valid_599822 != nil:
    section.add "X-Amz-Algorithm", valid_599822
  var valid_599823 = header.getOrDefault("X-Amz-Signature")
  valid_599823 = validateParameter(valid_599823, JString, required = false,
                                 default = nil)
  if valid_599823 != nil:
    section.add "X-Amz-Signature", valid_599823
  var valid_599824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599824 = validateParameter(valid_599824, JString, required = false,
                                 default = nil)
  if valid_599824 != nil:
    section.add "X-Amz-SignedHeaders", valid_599824
  var valid_599825 = header.getOrDefault("X-Amz-Credential")
  valid_599825 = validateParameter(valid_599825, JString, required = false,
                                 default = nil)
  if valid_599825 != nil:
    section.add "X-Amz-Credential", valid_599825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599849: Call_AssociateCertificate_599705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates an AWS Certificate Manager (ACM) Amazon Resource Name (ARN) with AWS Elemental MediaConvert.
  ## 
  let valid = call_599849.validator(path, query, header, formData, body)
  let scheme = call_599849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599849.url(scheme.get, call_599849.host, call_599849.base,
                         call_599849.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599849, url, valid)

proc call*(call_599920: Call_AssociateCertificate_599705; body: JsonNode): Recallable =
  ## associateCertificate
  ## Associates an AWS Certificate Manager (ACM) Amazon Resource Name (ARN) with AWS Elemental MediaConvert.
  ##   body: JObject (required)
  var body_599921 = newJObject()
  if body != nil:
    body_599921 = body
  result = call_599920.call(nil, nil, nil, nil, body_599921)

var associateCertificate* = Call_AssociateCertificate_599705(
    name: "associateCertificate", meth: HttpMethod.HttpPost,
    host: "mediaconvert.amazonaws.com", route: "/2017-08-29/certificates",
    validator: validate_AssociateCertificate_599706, base: "/",
    url: url_AssociateCertificate_599707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_599960 = ref object of OpenApiRestCall_599368
proc url_GetJob_599962(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetJob_599961(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599977 = path.getOrDefault("id")
  valid_599977 = validateParameter(valid_599977, JString, required = true,
                                 default = nil)
  if valid_599977 != nil:
    section.add "id", valid_599977
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
  var valid_599978 = header.getOrDefault("X-Amz-Date")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "X-Amz-Date", valid_599978
  var valid_599979 = header.getOrDefault("X-Amz-Security-Token")
  valid_599979 = validateParameter(valid_599979, JString, required = false,
                                 default = nil)
  if valid_599979 != nil:
    section.add "X-Amz-Security-Token", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Content-Sha256", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Algorithm")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Algorithm", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Signature")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Signature", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-SignedHeaders", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Credential")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Credential", valid_599984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599985: Call_GetJob_599960; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the JSON for a specific completed transcoding job.
  ## 
  let valid = call_599985.validator(path, query, header, formData, body)
  let scheme = call_599985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599985.url(scheme.get, call_599985.host, call_599985.base,
                         call_599985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599985, url, valid)

proc call*(call_599986: Call_GetJob_599960; id: string): Recallable =
  ## getJob
  ## Retrieve the JSON for a specific completed transcoding job.
  ##   id: string (required)
  ##     : the job ID of the job.
  var path_599987 = newJObject()
  add(path_599987, "id", newJString(id))
  result = call_599986.call(path_599987, nil, nil, nil, nil)

var getJob* = Call_GetJob_599960(name: "getJob", meth: HttpMethod.HttpGet,
                              host: "mediaconvert.amazonaws.com",
                              route: "/2017-08-29/jobs/{id}",
                              validator: validate_GetJob_599961, base: "/",
                              url: url_GetJob_599962,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelJob_599989 = ref object of OpenApiRestCall_599368
proc url_CancelJob_599991(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CancelJob_599990(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599992 = path.getOrDefault("id")
  valid_599992 = validateParameter(valid_599992, JString, required = true,
                                 default = nil)
  if valid_599992 != nil:
    section.add "id", valid_599992
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
  var valid_599993 = header.getOrDefault("X-Amz-Date")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Date", valid_599993
  var valid_599994 = header.getOrDefault("X-Amz-Security-Token")
  valid_599994 = validateParameter(valid_599994, JString, required = false,
                                 default = nil)
  if valid_599994 != nil:
    section.add "X-Amz-Security-Token", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Content-Sha256", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Algorithm")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Algorithm", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Signature")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Signature", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-SignedHeaders", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Credential")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Credential", valid_599999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600000: Call_CancelJob_599989; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently cancel a job. Once you have canceled a job, you can't start it again.
  ## 
  let valid = call_600000.validator(path, query, header, formData, body)
  let scheme = call_600000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600000.url(scheme.get, call_600000.host, call_600000.base,
                         call_600000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600000, url, valid)

proc call*(call_600001: Call_CancelJob_599989; id: string): Recallable =
  ## cancelJob
  ## Permanently cancel a job. Once you have canceled a job, you can't start it again.
  ##   id: string (required)
  ##     : The Job ID of the job to be cancelled.
  var path_600002 = newJObject()
  add(path_600002, "id", newJString(id))
  result = call_600001.call(path_600002, nil, nil, nil, nil)

var cancelJob* = Call_CancelJob_599989(name: "cancelJob",
                                    meth: HttpMethod.HttpDelete,
                                    host: "mediaconvert.amazonaws.com",
                                    route: "/2017-08-29/jobs/{id}",
                                    validator: validate_CancelJob_599990,
                                    base: "/", url: url_CancelJob_599991,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_600036 = ref object of OpenApiRestCall_599368
proc url_CreateJob_600038(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateJob_600037(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600039 = header.getOrDefault("X-Amz-Date")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-Date", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Security-Token")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Security-Token", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Content-Sha256", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Algorithm")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Algorithm", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-Signature")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Signature", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-SignedHeaders", valid_600044
  var valid_600045 = header.getOrDefault("X-Amz-Credential")
  valid_600045 = validateParameter(valid_600045, JString, required = false,
                                 default = nil)
  if valid_600045 != nil:
    section.add "X-Amz-Credential", valid_600045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600047: Call_CreateJob_600036; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new transcoding job. For information about jobs and job settings, see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ## 
  let valid = call_600047.validator(path, query, header, formData, body)
  let scheme = call_600047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600047.url(scheme.get, call_600047.host, call_600047.base,
                         call_600047.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600047, url, valid)

proc call*(call_600048: Call_CreateJob_600036; body: JsonNode): Recallable =
  ## createJob
  ## Create a new transcoding job. For information about jobs and job settings, see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ##   body: JObject (required)
  var body_600049 = newJObject()
  if body != nil:
    body_600049 = body
  result = call_600048.call(nil, nil, nil, nil, body_600049)

var createJob* = Call_CreateJob_600036(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "mediaconvert.amazonaws.com",
                                    route: "/2017-08-29/jobs",
                                    validator: validate_CreateJob_600037,
                                    base: "/", url: url_CreateJob_600038,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_600003 = ref object of OpenApiRestCall_599368
proc url_ListJobs_600005(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJobs_600004(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600019 = query.getOrDefault("order")
  valid_600019 = validateParameter(valid_600019, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_600019 != nil:
    section.add "order", valid_600019
  var valid_600020 = query.getOrDefault("NextToken")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "NextToken", valid_600020
  var valid_600021 = query.getOrDefault("maxResults")
  valid_600021 = validateParameter(valid_600021, JInt, required = false, default = nil)
  if valid_600021 != nil:
    section.add "maxResults", valid_600021
  var valid_600022 = query.getOrDefault("nextToken")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "nextToken", valid_600022
  var valid_600023 = query.getOrDefault("status")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = newJString("SUBMITTED"))
  if valid_600023 != nil:
    section.add "status", valid_600023
  var valid_600024 = query.getOrDefault("queue")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "queue", valid_600024
  var valid_600025 = query.getOrDefault("MaxResults")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "MaxResults", valid_600025
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
  var valid_600026 = header.getOrDefault("X-Amz-Date")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Date", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Security-Token")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Security-Token", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-Content-Sha256", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Algorithm")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Algorithm", valid_600029
  var valid_600030 = header.getOrDefault("X-Amz-Signature")
  valid_600030 = validateParameter(valid_600030, JString, required = false,
                                 default = nil)
  if valid_600030 != nil:
    section.add "X-Amz-Signature", valid_600030
  var valid_600031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600031 = validateParameter(valid_600031, JString, required = false,
                                 default = nil)
  if valid_600031 != nil:
    section.add "X-Amz-SignedHeaders", valid_600031
  var valid_600032 = header.getOrDefault("X-Amz-Credential")
  valid_600032 = validateParameter(valid_600032, JString, required = false,
                                 default = nil)
  if valid_600032 != nil:
    section.add "X-Amz-Credential", valid_600032
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600033: Call_ListJobs_600003; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a JSON array of up to twenty of your most recently created jobs. This array includes in-process, completed, and errored jobs. This will return the jobs themselves, not just a list of the jobs. To retrieve the twenty next most recent jobs, use the nextToken string returned with the array.
  ## 
  let valid = call_600033.validator(path, query, header, formData, body)
  let scheme = call_600033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600033.url(scheme.get, call_600033.host, call_600033.base,
                         call_600033.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600033, url, valid)

proc call*(call_600034: Call_ListJobs_600003; order: string = "ASCENDING";
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
  var query_600035 = newJObject()
  add(query_600035, "order", newJString(order))
  add(query_600035, "NextToken", newJString(NextToken))
  add(query_600035, "maxResults", newJInt(maxResults))
  add(query_600035, "nextToken", newJString(nextToken))
  add(query_600035, "status", newJString(status))
  add(query_600035, "queue", newJString(queue))
  add(query_600035, "MaxResults", newJString(MaxResults))
  result = call_600034.call(nil, query_600035, nil, nil, nil)

var listJobs* = Call_ListJobs_600003(name: "listJobs", meth: HttpMethod.HttpGet,
                                  host: "mediaconvert.amazonaws.com",
                                  route: "/2017-08-29/jobs",
                                  validator: validate_ListJobs_600004, base: "/",
                                  url: url_ListJobs_600005,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJobTemplate_600070 = ref object of OpenApiRestCall_599368
proc url_CreateJobTemplate_600072(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateJobTemplate_600071(path: JsonNode; query: JsonNode;
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
  var valid_600073 = header.getOrDefault("X-Amz-Date")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-Date", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-Security-Token")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Security-Token", valid_600074
  var valid_600075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600075 = validateParameter(valid_600075, JString, required = false,
                                 default = nil)
  if valid_600075 != nil:
    section.add "X-Amz-Content-Sha256", valid_600075
  var valid_600076 = header.getOrDefault("X-Amz-Algorithm")
  valid_600076 = validateParameter(valid_600076, JString, required = false,
                                 default = nil)
  if valid_600076 != nil:
    section.add "X-Amz-Algorithm", valid_600076
  var valid_600077 = header.getOrDefault("X-Amz-Signature")
  valid_600077 = validateParameter(valid_600077, JString, required = false,
                                 default = nil)
  if valid_600077 != nil:
    section.add "X-Amz-Signature", valid_600077
  var valid_600078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600078 = validateParameter(valid_600078, JString, required = false,
                                 default = nil)
  if valid_600078 != nil:
    section.add "X-Amz-SignedHeaders", valid_600078
  var valid_600079 = header.getOrDefault("X-Amz-Credential")
  valid_600079 = validateParameter(valid_600079, JString, required = false,
                                 default = nil)
  if valid_600079 != nil:
    section.add "X-Amz-Credential", valid_600079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600081: Call_CreateJobTemplate_600070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new job template. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ## 
  let valid = call_600081.validator(path, query, header, formData, body)
  let scheme = call_600081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600081.url(scheme.get, call_600081.host, call_600081.base,
                         call_600081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600081, url, valid)

proc call*(call_600082: Call_CreateJobTemplate_600070; body: JsonNode): Recallable =
  ## createJobTemplate
  ## Create a new job template. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ##   body: JObject (required)
  var body_600083 = newJObject()
  if body != nil:
    body_600083 = body
  result = call_600082.call(nil, nil, nil, nil, body_600083)

var createJobTemplate* = Call_CreateJobTemplate_600070(name: "createJobTemplate",
    meth: HttpMethod.HttpPost, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates", validator: validate_CreateJobTemplate_600071,
    base: "/", url: url_CreateJobTemplate_600072,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobTemplates_600050 = ref object of OpenApiRestCall_599368
proc url_ListJobTemplates_600052(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJobTemplates_600051(path: JsonNode; query: JsonNode;
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
  var valid_600053 = query.getOrDefault("order")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_600053 != nil:
    section.add "order", valid_600053
  var valid_600054 = query.getOrDefault("NextToken")
  valid_600054 = validateParameter(valid_600054, JString, required = false,
                                 default = nil)
  if valid_600054 != nil:
    section.add "NextToken", valid_600054
  var valid_600055 = query.getOrDefault("maxResults")
  valid_600055 = validateParameter(valid_600055, JInt, required = false, default = nil)
  if valid_600055 != nil:
    section.add "maxResults", valid_600055
  var valid_600056 = query.getOrDefault("nextToken")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "nextToken", valid_600056
  var valid_600057 = query.getOrDefault("listBy")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = newJString("NAME"))
  if valid_600057 != nil:
    section.add "listBy", valid_600057
  var valid_600058 = query.getOrDefault("category")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "category", valid_600058
  var valid_600059 = query.getOrDefault("MaxResults")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "MaxResults", valid_600059
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
  var valid_600060 = header.getOrDefault("X-Amz-Date")
  valid_600060 = validateParameter(valid_600060, JString, required = false,
                                 default = nil)
  if valid_600060 != nil:
    section.add "X-Amz-Date", valid_600060
  var valid_600061 = header.getOrDefault("X-Amz-Security-Token")
  valid_600061 = validateParameter(valid_600061, JString, required = false,
                                 default = nil)
  if valid_600061 != nil:
    section.add "X-Amz-Security-Token", valid_600061
  var valid_600062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600062 = validateParameter(valid_600062, JString, required = false,
                                 default = nil)
  if valid_600062 != nil:
    section.add "X-Amz-Content-Sha256", valid_600062
  var valid_600063 = header.getOrDefault("X-Amz-Algorithm")
  valid_600063 = validateParameter(valid_600063, JString, required = false,
                                 default = nil)
  if valid_600063 != nil:
    section.add "X-Amz-Algorithm", valid_600063
  var valid_600064 = header.getOrDefault("X-Amz-Signature")
  valid_600064 = validateParameter(valid_600064, JString, required = false,
                                 default = nil)
  if valid_600064 != nil:
    section.add "X-Amz-Signature", valid_600064
  var valid_600065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600065 = validateParameter(valid_600065, JString, required = false,
                                 default = nil)
  if valid_600065 != nil:
    section.add "X-Amz-SignedHeaders", valid_600065
  var valid_600066 = header.getOrDefault("X-Amz-Credential")
  valid_600066 = validateParameter(valid_600066, JString, required = false,
                                 default = nil)
  if valid_600066 != nil:
    section.add "X-Amz-Credential", valid_600066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600067: Call_ListJobTemplates_600050; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a JSON array of up to twenty of your job templates. This will return the templates themselves, not just a list of them. To retrieve the next twenty templates, use the nextToken string returned with the array
  ## 
  let valid = call_600067.validator(path, query, header, formData, body)
  let scheme = call_600067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600067.url(scheme.get, call_600067.host, call_600067.base,
                         call_600067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600067, url, valid)

proc call*(call_600068: Call_ListJobTemplates_600050; order: string = "ASCENDING";
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
  var query_600069 = newJObject()
  add(query_600069, "order", newJString(order))
  add(query_600069, "NextToken", newJString(NextToken))
  add(query_600069, "maxResults", newJInt(maxResults))
  add(query_600069, "nextToken", newJString(nextToken))
  add(query_600069, "listBy", newJString(listBy))
  add(query_600069, "category", newJString(category))
  add(query_600069, "MaxResults", newJString(MaxResults))
  result = call_600068.call(nil, query_600069, nil, nil, nil)

var listJobTemplates* = Call_ListJobTemplates_600050(name: "listJobTemplates",
    meth: HttpMethod.HttpGet, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates", validator: validate_ListJobTemplates_600051,
    base: "/", url: url_ListJobTemplates_600052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePreset_600104 = ref object of OpenApiRestCall_599368
proc url_CreatePreset_600106(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePreset_600105(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600107 = header.getOrDefault("X-Amz-Date")
  valid_600107 = validateParameter(valid_600107, JString, required = false,
                                 default = nil)
  if valid_600107 != nil:
    section.add "X-Amz-Date", valid_600107
  var valid_600108 = header.getOrDefault("X-Amz-Security-Token")
  valid_600108 = validateParameter(valid_600108, JString, required = false,
                                 default = nil)
  if valid_600108 != nil:
    section.add "X-Amz-Security-Token", valid_600108
  var valid_600109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600109 = validateParameter(valid_600109, JString, required = false,
                                 default = nil)
  if valid_600109 != nil:
    section.add "X-Amz-Content-Sha256", valid_600109
  var valid_600110 = header.getOrDefault("X-Amz-Algorithm")
  valid_600110 = validateParameter(valid_600110, JString, required = false,
                                 default = nil)
  if valid_600110 != nil:
    section.add "X-Amz-Algorithm", valid_600110
  var valid_600111 = header.getOrDefault("X-Amz-Signature")
  valid_600111 = validateParameter(valid_600111, JString, required = false,
                                 default = nil)
  if valid_600111 != nil:
    section.add "X-Amz-Signature", valid_600111
  var valid_600112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-SignedHeaders", valid_600112
  var valid_600113 = header.getOrDefault("X-Amz-Credential")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-Credential", valid_600113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600115: Call_CreatePreset_600104; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new preset. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ## 
  let valid = call_600115.validator(path, query, header, formData, body)
  let scheme = call_600115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600115.url(scheme.get, call_600115.host, call_600115.base,
                         call_600115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600115, url, valid)

proc call*(call_600116: Call_CreatePreset_600104; body: JsonNode): Recallable =
  ## createPreset
  ## Create a new preset. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ##   body: JObject (required)
  var body_600117 = newJObject()
  if body != nil:
    body_600117 = body
  result = call_600116.call(nil, nil, nil, nil, body_600117)

var createPreset* = Call_CreatePreset_600104(name: "createPreset",
    meth: HttpMethod.HttpPost, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/presets", validator: validate_CreatePreset_600105,
    base: "/", url: url_CreatePreset_600106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPresets_600084 = ref object of OpenApiRestCall_599368
proc url_ListPresets_600086(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPresets_600085(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600087 = query.getOrDefault("order")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_600087 != nil:
    section.add "order", valid_600087
  var valid_600088 = query.getOrDefault("NextToken")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "NextToken", valid_600088
  var valid_600089 = query.getOrDefault("maxResults")
  valid_600089 = validateParameter(valid_600089, JInt, required = false, default = nil)
  if valid_600089 != nil:
    section.add "maxResults", valid_600089
  var valid_600090 = query.getOrDefault("nextToken")
  valid_600090 = validateParameter(valid_600090, JString, required = false,
                                 default = nil)
  if valid_600090 != nil:
    section.add "nextToken", valid_600090
  var valid_600091 = query.getOrDefault("listBy")
  valid_600091 = validateParameter(valid_600091, JString, required = false,
                                 default = newJString("NAME"))
  if valid_600091 != nil:
    section.add "listBy", valid_600091
  var valid_600092 = query.getOrDefault("category")
  valid_600092 = validateParameter(valid_600092, JString, required = false,
                                 default = nil)
  if valid_600092 != nil:
    section.add "category", valid_600092
  var valid_600093 = query.getOrDefault("MaxResults")
  valid_600093 = validateParameter(valid_600093, JString, required = false,
                                 default = nil)
  if valid_600093 != nil:
    section.add "MaxResults", valid_600093
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
  var valid_600094 = header.getOrDefault("X-Amz-Date")
  valid_600094 = validateParameter(valid_600094, JString, required = false,
                                 default = nil)
  if valid_600094 != nil:
    section.add "X-Amz-Date", valid_600094
  var valid_600095 = header.getOrDefault("X-Amz-Security-Token")
  valid_600095 = validateParameter(valid_600095, JString, required = false,
                                 default = nil)
  if valid_600095 != nil:
    section.add "X-Amz-Security-Token", valid_600095
  var valid_600096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600096 = validateParameter(valid_600096, JString, required = false,
                                 default = nil)
  if valid_600096 != nil:
    section.add "X-Amz-Content-Sha256", valid_600096
  var valid_600097 = header.getOrDefault("X-Amz-Algorithm")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-Algorithm", valid_600097
  var valid_600098 = header.getOrDefault("X-Amz-Signature")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Signature", valid_600098
  var valid_600099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600099 = validateParameter(valid_600099, JString, required = false,
                                 default = nil)
  if valid_600099 != nil:
    section.add "X-Amz-SignedHeaders", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Credential")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Credential", valid_600100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600101: Call_ListPresets_600084; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a JSON array of up to twenty of your presets. This will return the presets themselves, not just a list of them. To retrieve the next twenty presets, use the nextToken string returned with the array.
  ## 
  let valid = call_600101.validator(path, query, header, formData, body)
  let scheme = call_600101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600101.url(scheme.get, call_600101.host, call_600101.base,
                         call_600101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600101, url, valid)

proc call*(call_600102: Call_ListPresets_600084; order: string = "ASCENDING";
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
  var query_600103 = newJObject()
  add(query_600103, "order", newJString(order))
  add(query_600103, "NextToken", newJString(NextToken))
  add(query_600103, "maxResults", newJInt(maxResults))
  add(query_600103, "nextToken", newJString(nextToken))
  add(query_600103, "listBy", newJString(listBy))
  add(query_600103, "category", newJString(category))
  add(query_600103, "MaxResults", newJString(MaxResults))
  result = call_600102.call(nil, query_600103, nil, nil, nil)

var listPresets* = Call_ListPresets_600084(name: "listPresets",
                                        meth: HttpMethod.HttpGet,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/presets",
                                        validator: validate_ListPresets_600085,
                                        base: "/", url: url_ListPresets_600086,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateQueue_600137 = ref object of OpenApiRestCall_599368
proc url_CreateQueue_600139(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateQueue_600138(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600140 = header.getOrDefault("X-Amz-Date")
  valid_600140 = validateParameter(valid_600140, JString, required = false,
                                 default = nil)
  if valid_600140 != nil:
    section.add "X-Amz-Date", valid_600140
  var valid_600141 = header.getOrDefault("X-Amz-Security-Token")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "X-Amz-Security-Token", valid_600141
  var valid_600142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Content-Sha256", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Algorithm")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Algorithm", valid_600143
  var valid_600144 = header.getOrDefault("X-Amz-Signature")
  valid_600144 = validateParameter(valid_600144, JString, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "X-Amz-Signature", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-SignedHeaders", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Credential")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Credential", valid_600146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600148: Call_CreateQueue_600137; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new transcoding queue. For information about queues, see Working With Queues in the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/working-with-queues.html
  ## 
  let valid = call_600148.validator(path, query, header, formData, body)
  let scheme = call_600148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600148.url(scheme.get, call_600148.host, call_600148.base,
                         call_600148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600148, url, valid)

proc call*(call_600149: Call_CreateQueue_600137; body: JsonNode): Recallable =
  ## createQueue
  ## Create a new transcoding queue. For information about queues, see Working With Queues in the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/working-with-queues.html
  ##   body: JObject (required)
  var body_600150 = newJObject()
  if body != nil:
    body_600150 = body
  result = call_600149.call(nil, nil, nil, nil, body_600150)

var createQueue* = Call_CreateQueue_600137(name: "createQueue",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/queues",
                                        validator: validate_CreateQueue_600138,
                                        base: "/", url: url_CreateQueue_600139,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQueues_600118 = ref object of OpenApiRestCall_599368
proc url_ListQueues_600120(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListQueues_600119(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600121 = query.getOrDefault("order")
  valid_600121 = validateParameter(valid_600121, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_600121 != nil:
    section.add "order", valid_600121
  var valid_600122 = query.getOrDefault("NextToken")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "NextToken", valid_600122
  var valid_600123 = query.getOrDefault("maxResults")
  valid_600123 = validateParameter(valid_600123, JInt, required = false, default = nil)
  if valid_600123 != nil:
    section.add "maxResults", valid_600123
  var valid_600124 = query.getOrDefault("nextToken")
  valid_600124 = validateParameter(valid_600124, JString, required = false,
                                 default = nil)
  if valid_600124 != nil:
    section.add "nextToken", valid_600124
  var valid_600125 = query.getOrDefault("listBy")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = newJString("NAME"))
  if valid_600125 != nil:
    section.add "listBy", valid_600125
  var valid_600126 = query.getOrDefault("MaxResults")
  valid_600126 = validateParameter(valid_600126, JString, required = false,
                                 default = nil)
  if valid_600126 != nil:
    section.add "MaxResults", valid_600126
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
  var valid_600127 = header.getOrDefault("X-Amz-Date")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Date", valid_600127
  var valid_600128 = header.getOrDefault("X-Amz-Security-Token")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Security-Token", valid_600128
  var valid_600129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600129 = validateParameter(valid_600129, JString, required = false,
                                 default = nil)
  if valid_600129 != nil:
    section.add "X-Amz-Content-Sha256", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-Algorithm")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Algorithm", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Signature")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Signature", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-SignedHeaders", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-Credential")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-Credential", valid_600133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600134: Call_ListQueues_600118; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a JSON array of up to twenty of your queues. This will return the queues themselves, not just a list of them. To retrieve the next twenty queues, use the nextToken string returned with the array.
  ## 
  let valid = call_600134.validator(path, query, header, formData, body)
  let scheme = call_600134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600134.url(scheme.get, call_600134.host, call_600134.base,
                         call_600134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600134, url, valid)

proc call*(call_600135: Call_ListQueues_600118; order: string = "ASCENDING";
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
  var query_600136 = newJObject()
  add(query_600136, "order", newJString(order))
  add(query_600136, "NextToken", newJString(NextToken))
  add(query_600136, "maxResults", newJInt(maxResults))
  add(query_600136, "nextToken", newJString(nextToken))
  add(query_600136, "listBy", newJString(listBy))
  add(query_600136, "MaxResults", newJString(MaxResults))
  result = call_600135.call(nil, query_600136, nil, nil, nil)

var listQueues* = Call_ListQueues_600118(name: "listQueues",
                                      meth: HttpMethod.HttpGet,
                                      host: "mediaconvert.amazonaws.com",
                                      route: "/2017-08-29/queues",
                                      validator: validate_ListQueues_600119,
                                      base: "/", url: url_ListQueues_600120,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJobTemplate_600165 = ref object of OpenApiRestCall_599368
proc url_UpdateJobTemplate_600167(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateJobTemplate_600166(path: JsonNode; query: JsonNode;
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
  var valid_600168 = path.getOrDefault("name")
  valid_600168 = validateParameter(valid_600168, JString, required = true,
                                 default = nil)
  if valid_600168 != nil:
    section.add "name", valid_600168
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
  var valid_600169 = header.getOrDefault("X-Amz-Date")
  valid_600169 = validateParameter(valid_600169, JString, required = false,
                                 default = nil)
  if valid_600169 != nil:
    section.add "X-Amz-Date", valid_600169
  var valid_600170 = header.getOrDefault("X-Amz-Security-Token")
  valid_600170 = validateParameter(valid_600170, JString, required = false,
                                 default = nil)
  if valid_600170 != nil:
    section.add "X-Amz-Security-Token", valid_600170
  var valid_600171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600171 = validateParameter(valid_600171, JString, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "X-Amz-Content-Sha256", valid_600171
  var valid_600172 = header.getOrDefault("X-Amz-Algorithm")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Algorithm", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-Signature")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Signature", valid_600173
  var valid_600174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "X-Amz-SignedHeaders", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-Credential")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-Credential", valid_600175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600177: Call_UpdateJobTemplate_600165; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modify one of your existing job templates.
  ## 
  let valid = call_600177.validator(path, query, header, formData, body)
  let scheme = call_600177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600177.url(scheme.get, call_600177.host, call_600177.base,
                         call_600177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600177, url, valid)

proc call*(call_600178: Call_UpdateJobTemplate_600165; name: string; body: JsonNode): Recallable =
  ## updateJobTemplate
  ## Modify one of your existing job templates.
  ##   name: string (required)
  ##       : The name of the job template you are modifying
  ##   body: JObject (required)
  var path_600179 = newJObject()
  var body_600180 = newJObject()
  add(path_600179, "name", newJString(name))
  if body != nil:
    body_600180 = body
  result = call_600178.call(path_600179, nil, nil, nil, body_600180)

var updateJobTemplate* = Call_UpdateJobTemplate_600165(name: "updateJobTemplate",
    meth: HttpMethod.HttpPut, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates/{name}",
    validator: validate_UpdateJobTemplate_600166, base: "/",
    url: url_UpdateJobTemplate_600167, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobTemplate_600151 = ref object of OpenApiRestCall_599368
proc url_GetJobTemplate_600153(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetJobTemplate_600152(path: JsonNode; query: JsonNode;
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
  var valid_600154 = path.getOrDefault("name")
  valid_600154 = validateParameter(valid_600154, JString, required = true,
                                 default = nil)
  if valid_600154 != nil:
    section.add "name", valid_600154
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
  var valid_600155 = header.getOrDefault("X-Amz-Date")
  valid_600155 = validateParameter(valid_600155, JString, required = false,
                                 default = nil)
  if valid_600155 != nil:
    section.add "X-Amz-Date", valid_600155
  var valid_600156 = header.getOrDefault("X-Amz-Security-Token")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "X-Amz-Security-Token", valid_600156
  var valid_600157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Content-Sha256", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Algorithm")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Algorithm", valid_600158
  var valid_600159 = header.getOrDefault("X-Amz-Signature")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "X-Amz-Signature", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-SignedHeaders", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Credential")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Credential", valid_600161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600162: Call_GetJobTemplate_600151; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the JSON for a specific job template.
  ## 
  let valid = call_600162.validator(path, query, header, formData, body)
  let scheme = call_600162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600162.url(scheme.get, call_600162.host, call_600162.base,
                         call_600162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600162, url, valid)

proc call*(call_600163: Call_GetJobTemplate_600151; name: string): Recallable =
  ## getJobTemplate
  ## Retrieve the JSON for a specific job template.
  ##   name: string (required)
  ##       : The name of the job template.
  var path_600164 = newJObject()
  add(path_600164, "name", newJString(name))
  result = call_600163.call(path_600164, nil, nil, nil, nil)

var getJobTemplate* = Call_GetJobTemplate_600151(name: "getJobTemplate",
    meth: HttpMethod.HttpGet, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates/{name}", validator: validate_GetJobTemplate_600152,
    base: "/", url: url_GetJobTemplate_600153, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJobTemplate_600181 = ref object of OpenApiRestCall_599368
proc url_DeleteJobTemplate_600183(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteJobTemplate_600182(path: JsonNode; query: JsonNode;
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
  var valid_600184 = path.getOrDefault("name")
  valid_600184 = validateParameter(valid_600184, JString, required = true,
                                 default = nil)
  if valid_600184 != nil:
    section.add "name", valid_600184
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
  var valid_600185 = header.getOrDefault("X-Amz-Date")
  valid_600185 = validateParameter(valid_600185, JString, required = false,
                                 default = nil)
  if valid_600185 != nil:
    section.add "X-Amz-Date", valid_600185
  var valid_600186 = header.getOrDefault("X-Amz-Security-Token")
  valid_600186 = validateParameter(valid_600186, JString, required = false,
                                 default = nil)
  if valid_600186 != nil:
    section.add "X-Amz-Security-Token", valid_600186
  var valid_600187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-Content-Sha256", valid_600187
  var valid_600188 = header.getOrDefault("X-Amz-Algorithm")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-Algorithm", valid_600188
  var valid_600189 = header.getOrDefault("X-Amz-Signature")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-Signature", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-SignedHeaders", valid_600190
  var valid_600191 = header.getOrDefault("X-Amz-Credential")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-Credential", valid_600191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600192: Call_DeleteJobTemplate_600181; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently delete a job template you have created.
  ## 
  let valid = call_600192.validator(path, query, header, formData, body)
  let scheme = call_600192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600192.url(scheme.get, call_600192.host, call_600192.base,
                         call_600192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600192, url, valid)

proc call*(call_600193: Call_DeleteJobTemplate_600181; name: string): Recallable =
  ## deleteJobTemplate
  ## Permanently delete a job template you have created.
  ##   name: string (required)
  ##       : The name of the job template to be deleted.
  var path_600194 = newJObject()
  add(path_600194, "name", newJString(name))
  result = call_600193.call(path_600194, nil, nil, nil, nil)

var deleteJobTemplate* = Call_DeleteJobTemplate_600181(name: "deleteJobTemplate",
    meth: HttpMethod.HttpDelete, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates/{name}",
    validator: validate_DeleteJobTemplate_600182, base: "/",
    url: url_DeleteJobTemplate_600183, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePreset_600209 = ref object of OpenApiRestCall_599368
proc url_UpdatePreset_600211(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdatePreset_600210(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600212 = path.getOrDefault("name")
  valid_600212 = validateParameter(valid_600212, JString, required = true,
                                 default = nil)
  if valid_600212 != nil:
    section.add "name", valid_600212
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
  var valid_600213 = header.getOrDefault("X-Amz-Date")
  valid_600213 = validateParameter(valid_600213, JString, required = false,
                                 default = nil)
  if valid_600213 != nil:
    section.add "X-Amz-Date", valid_600213
  var valid_600214 = header.getOrDefault("X-Amz-Security-Token")
  valid_600214 = validateParameter(valid_600214, JString, required = false,
                                 default = nil)
  if valid_600214 != nil:
    section.add "X-Amz-Security-Token", valid_600214
  var valid_600215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600215 = validateParameter(valid_600215, JString, required = false,
                                 default = nil)
  if valid_600215 != nil:
    section.add "X-Amz-Content-Sha256", valid_600215
  var valid_600216 = header.getOrDefault("X-Amz-Algorithm")
  valid_600216 = validateParameter(valid_600216, JString, required = false,
                                 default = nil)
  if valid_600216 != nil:
    section.add "X-Amz-Algorithm", valid_600216
  var valid_600217 = header.getOrDefault("X-Amz-Signature")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-Signature", valid_600217
  var valid_600218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-SignedHeaders", valid_600218
  var valid_600219 = header.getOrDefault("X-Amz-Credential")
  valid_600219 = validateParameter(valid_600219, JString, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "X-Amz-Credential", valid_600219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600221: Call_UpdatePreset_600209; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modify one of your existing presets.
  ## 
  let valid = call_600221.validator(path, query, header, formData, body)
  let scheme = call_600221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600221.url(scheme.get, call_600221.host, call_600221.base,
                         call_600221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600221, url, valid)

proc call*(call_600222: Call_UpdatePreset_600209; name: string; body: JsonNode): Recallable =
  ## updatePreset
  ## Modify one of your existing presets.
  ##   name: string (required)
  ##       : The name of the preset you are modifying.
  ##   body: JObject (required)
  var path_600223 = newJObject()
  var body_600224 = newJObject()
  add(path_600223, "name", newJString(name))
  if body != nil:
    body_600224 = body
  result = call_600222.call(path_600223, nil, nil, nil, body_600224)

var updatePreset* = Call_UpdatePreset_600209(name: "updatePreset",
    meth: HttpMethod.HttpPut, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/presets/{name}", validator: validate_UpdatePreset_600210,
    base: "/", url: url_UpdatePreset_600211, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPreset_600195 = ref object of OpenApiRestCall_599368
proc url_GetPreset_600197(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetPreset_600196(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600198 = path.getOrDefault("name")
  valid_600198 = validateParameter(valid_600198, JString, required = true,
                                 default = nil)
  if valid_600198 != nil:
    section.add "name", valid_600198
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
  var valid_600199 = header.getOrDefault("X-Amz-Date")
  valid_600199 = validateParameter(valid_600199, JString, required = false,
                                 default = nil)
  if valid_600199 != nil:
    section.add "X-Amz-Date", valid_600199
  var valid_600200 = header.getOrDefault("X-Amz-Security-Token")
  valid_600200 = validateParameter(valid_600200, JString, required = false,
                                 default = nil)
  if valid_600200 != nil:
    section.add "X-Amz-Security-Token", valid_600200
  var valid_600201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600201 = validateParameter(valid_600201, JString, required = false,
                                 default = nil)
  if valid_600201 != nil:
    section.add "X-Amz-Content-Sha256", valid_600201
  var valid_600202 = header.getOrDefault("X-Amz-Algorithm")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "X-Amz-Algorithm", valid_600202
  var valid_600203 = header.getOrDefault("X-Amz-Signature")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-Signature", valid_600203
  var valid_600204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-SignedHeaders", valid_600204
  var valid_600205 = header.getOrDefault("X-Amz-Credential")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-Credential", valid_600205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600206: Call_GetPreset_600195; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the JSON for a specific preset.
  ## 
  let valid = call_600206.validator(path, query, header, formData, body)
  let scheme = call_600206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600206.url(scheme.get, call_600206.host, call_600206.base,
                         call_600206.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600206, url, valid)

proc call*(call_600207: Call_GetPreset_600195; name: string): Recallable =
  ## getPreset
  ## Retrieve the JSON for a specific preset.
  ##   name: string (required)
  ##       : The name of the preset.
  var path_600208 = newJObject()
  add(path_600208, "name", newJString(name))
  result = call_600207.call(path_600208, nil, nil, nil, nil)

var getPreset* = Call_GetPreset_600195(name: "getPreset", meth: HttpMethod.HttpGet,
                                    host: "mediaconvert.amazonaws.com",
                                    route: "/2017-08-29/presets/{name}",
                                    validator: validate_GetPreset_600196,
                                    base: "/", url: url_GetPreset_600197,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePreset_600225 = ref object of OpenApiRestCall_599368
proc url_DeletePreset_600227(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeletePreset_600226(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600228 = path.getOrDefault("name")
  valid_600228 = validateParameter(valid_600228, JString, required = true,
                                 default = nil)
  if valid_600228 != nil:
    section.add "name", valid_600228
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
  var valid_600229 = header.getOrDefault("X-Amz-Date")
  valid_600229 = validateParameter(valid_600229, JString, required = false,
                                 default = nil)
  if valid_600229 != nil:
    section.add "X-Amz-Date", valid_600229
  var valid_600230 = header.getOrDefault("X-Amz-Security-Token")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "X-Amz-Security-Token", valid_600230
  var valid_600231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600231 = validateParameter(valid_600231, JString, required = false,
                                 default = nil)
  if valid_600231 != nil:
    section.add "X-Amz-Content-Sha256", valid_600231
  var valid_600232 = header.getOrDefault("X-Amz-Algorithm")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-Algorithm", valid_600232
  var valid_600233 = header.getOrDefault("X-Amz-Signature")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-Signature", valid_600233
  var valid_600234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600234 = validateParameter(valid_600234, JString, required = false,
                                 default = nil)
  if valid_600234 != nil:
    section.add "X-Amz-SignedHeaders", valid_600234
  var valid_600235 = header.getOrDefault("X-Amz-Credential")
  valid_600235 = validateParameter(valid_600235, JString, required = false,
                                 default = nil)
  if valid_600235 != nil:
    section.add "X-Amz-Credential", valid_600235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600236: Call_DeletePreset_600225; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently delete a preset you have created.
  ## 
  let valid = call_600236.validator(path, query, header, formData, body)
  let scheme = call_600236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600236.url(scheme.get, call_600236.host, call_600236.base,
                         call_600236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600236, url, valid)

proc call*(call_600237: Call_DeletePreset_600225; name: string): Recallable =
  ## deletePreset
  ## Permanently delete a preset you have created.
  ##   name: string (required)
  ##       : The name of the preset to be deleted.
  var path_600238 = newJObject()
  add(path_600238, "name", newJString(name))
  result = call_600237.call(path_600238, nil, nil, nil, nil)

var deletePreset* = Call_DeletePreset_600225(name: "deletePreset",
    meth: HttpMethod.HttpDelete, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/presets/{name}", validator: validate_DeletePreset_600226,
    base: "/", url: url_DeletePreset_600227, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateQueue_600253 = ref object of OpenApiRestCall_599368
proc url_UpdateQueue_600255(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateQueue_600254(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600256 = path.getOrDefault("name")
  valid_600256 = validateParameter(valid_600256, JString, required = true,
                                 default = nil)
  if valid_600256 != nil:
    section.add "name", valid_600256
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
  var valid_600257 = header.getOrDefault("X-Amz-Date")
  valid_600257 = validateParameter(valid_600257, JString, required = false,
                                 default = nil)
  if valid_600257 != nil:
    section.add "X-Amz-Date", valid_600257
  var valid_600258 = header.getOrDefault("X-Amz-Security-Token")
  valid_600258 = validateParameter(valid_600258, JString, required = false,
                                 default = nil)
  if valid_600258 != nil:
    section.add "X-Amz-Security-Token", valid_600258
  var valid_600259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600259 = validateParameter(valid_600259, JString, required = false,
                                 default = nil)
  if valid_600259 != nil:
    section.add "X-Amz-Content-Sha256", valid_600259
  var valid_600260 = header.getOrDefault("X-Amz-Algorithm")
  valid_600260 = validateParameter(valid_600260, JString, required = false,
                                 default = nil)
  if valid_600260 != nil:
    section.add "X-Amz-Algorithm", valid_600260
  var valid_600261 = header.getOrDefault("X-Amz-Signature")
  valid_600261 = validateParameter(valid_600261, JString, required = false,
                                 default = nil)
  if valid_600261 != nil:
    section.add "X-Amz-Signature", valid_600261
  var valid_600262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-SignedHeaders", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-Credential")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Credential", valid_600263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600265: Call_UpdateQueue_600253; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modify one of your existing queues.
  ## 
  let valid = call_600265.validator(path, query, header, formData, body)
  let scheme = call_600265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600265.url(scheme.get, call_600265.host, call_600265.base,
                         call_600265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600265, url, valid)

proc call*(call_600266: Call_UpdateQueue_600253; name: string; body: JsonNode): Recallable =
  ## updateQueue
  ## Modify one of your existing queues.
  ##   name: string (required)
  ##       : The name of the queue that you are modifying.
  ##   body: JObject (required)
  var path_600267 = newJObject()
  var body_600268 = newJObject()
  add(path_600267, "name", newJString(name))
  if body != nil:
    body_600268 = body
  result = call_600266.call(path_600267, nil, nil, nil, body_600268)

var updateQueue* = Call_UpdateQueue_600253(name: "updateQueue",
                                        meth: HttpMethod.HttpPut,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/queues/{name}",
                                        validator: validate_UpdateQueue_600254,
                                        base: "/", url: url_UpdateQueue_600255,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQueue_600239 = ref object of OpenApiRestCall_599368
proc url_GetQueue_600241(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetQueue_600240(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600242 = path.getOrDefault("name")
  valid_600242 = validateParameter(valid_600242, JString, required = true,
                                 default = nil)
  if valid_600242 != nil:
    section.add "name", valid_600242
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
  var valid_600243 = header.getOrDefault("X-Amz-Date")
  valid_600243 = validateParameter(valid_600243, JString, required = false,
                                 default = nil)
  if valid_600243 != nil:
    section.add "X-Amz-Date", valid_600243
  var valid_600244 = header.getOrDefault("X-Amz-Security-Token")
  valid_600244 = validateParameter(valid_600244, JString, required = false,
                                 default = nil)
  if valid_600244 != nil:
    section.add "X-Amz-Security-Token", valid_600244
  var valid_600245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "X-Amz-Content-Sha256", valid_600245
  var valid_600246 = header.getOrDefault("X-Amz-Algorithm")
  valid_600246 = validateParameter(valid_600246, JString, required = false,
                                 default = nil)
  if valid_600246 != nil:
    section.add "X-Amz-Algorithm", valid_600246
  var valid_600247 = header.getOrDefault("X-Amz-Signature")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-Signature", valid_600247
  var valid_600248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-SignedHeaders", valid_600248
  var valid_600249 = header.getOrDefault("X-Amz-Credential")
  valid_600249 = validateParameter(valid_600249, JString, required = false,
                                 default = nil)
  if valid_600249 != nil:
    section.add "X-Amz-Credential", valid_600249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600250: Call_GetQueue_600239; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the JSON for a specific queue.
  ## 
  let valid = call_600250.validator(path, query, header, formData, body)
  let scheme = call_600250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600250.url(scheme.get, call_600250.host, call_600250.base,
                         call_600250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600250, url, valid)

proc call*(call_600251: Call_GetQueue_600239; name: string): Recallable =
  ## getQueue
  ## Retrieve the JSON for a specific queue.
  ##   name: string (required)
  ##       : The name of the queue that you want information about.
  var path_600252 = newJObject()
  add(path_600252, "name", newJString(name))
  result = call_600251.call(path_600252, nil, nil, nil, nil)

var getQueue* = Call_GetQueue_600239(name: "getQueue", meth: HttpMethod.HttpGet,
                                  host: "mediaconvert.amazonaws.com",
                                  route: "/2017-08-29/queues/{name}",
                                  validator: validate_GetQueue_600240, base: "/",
                                  url: url_GetQueue_600241,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteQueue_600269 = ref object of OpenApiRestCall_599368
proc url_DeleteQueue_600271(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteQueue_600270(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600272 = path.getOrDefault("name")
  valid_600272 = validateParameter(valid_600272, JString, required = true,
                                 default = nil)
  if valid_600272 != nil:
    section.add "name", valid_600272
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
  var valid_600273 = header.getOrDefault("X-Amz-Date")
  valid_600273 = validateParameter(valid_600273, JString, required = false,
                                 default = nil)
  if valid_600273 != nil:
    section.add "X-Amz-Date", valid_600273
  var valid_600274 = header.getOrDefault("X-Amz-Security-Token")
  valid_600274 = validateParameter(valid_600274, JString, required = false,
                                 default = nil)
  if valid_600274 != nil:
    section.add "X-Amz-Security-Token", valid_600274
  var valid_600275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600275 = validateParameter(valid_600275, JString, required = false,
                                 default = nil)
  if valid_600275 != nil:
    section.add "X-Amz-Content-Sha256", valid_600275
  var valid_600276 = header.getOrDefault("X-Amz-Algorithm")
  valid_600276 = validateParameter(valid_600276, JString, required = false,
                                 default = nil)
  if valid_600276 != nil:
    section.add "X-Amz-Algorithm", valid_600276
  var valid_600277 = header.getOrDefault("X-Amz-Signature")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "X-Amz-Signature", valid_600277
  var valid_600278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-SignedHeaders", valid_600278
  var valid_600279 = header.getOrDefault("X-Amz-Credential")
  valid_600279 = validateParameter(valid_600279, JString, required = false,
                                 default = nil)
  if valid_600279 != nil:
    section.add "X-Amz-Credential", valid_600279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600280: Call_DeleteQueue_600269; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently delete a queue you have created.
  ## 
  let valid = call_600280.validator(path, query, header, formData, body)
  let scheme = call_600280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600280.url(scheme.get, call_600280.host, call_600280.base,
                         call_600280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600280, url, valid)

proc call*(call_600281: Call_DeleteQueue_600269; name: string): Recallable =
  ## deleteQueue
  ## Permanently delete a queue you have created.
  ##   name: string (required)
  ##       : The name of the queue that you want to delete.
  var path_600282 = newJObject()
  add(path_600282, "name", newJString(name))
  result = call_600281.call(path_600282, nil, nil, nil, nil)

var deleteQueue* = Call_DeleteQueue_600269(name: "deleteQueue",
                                        meth: HttpMethod.HttpDelete,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/queues/{name}",
                                        validator: validate_DeleteQueue_600270,
                                        base: "/", url: url_DeleteQueue_600271,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoints_600283 = ref object of OpenApiRestCall_599368
proc url_DescribeEndpoints_600285(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEndpoints_600284(path: JsonNode; query: JsonNode;
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
  var valid_600286 = query.getOrDefault("NextToken")
  valid_600286 = validateParameter(valid_600286, JString, required = false,
                                 default = nil)
  if valid_600286 != nil:
    section.add "NextToken", valid_600286
  var valid_600287 = query.getOrDefault("MaxResults")
  valid_600287 = validateParameter(valid_600287, JString, required = false,
                                 default = nil)
  if valid_600287 != nil:
    section.add "MaxResults", valid_600287
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
  var valid_600288 = header.getOrDefault("X-Amz-Date")
  valid_600288 = validateParameter(valid_600288, JString, required = false,
                                 default = nil)
  if valid_600288 != nil:
    section.add "X-Amz-Date", valid_600288
  var valid_600289 = header.getOrDefault("X-Amz-Security-Token")
  valid_600289 = validateParameter(valid_600289, JString, required = false,
                                 default = nil)
  if valid_600289 != nil:
    section.add "X-Amz-Security-Token", valid_600289
  var valid_600290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600290 = validateParameter(valid_600290, JString, required = false,
                                 default = nil)
  if valid_600290 != nil:
    section.add "X-Amz-Content-Sha256", valid_600290
  var valid_600291 = header.getOrDefault("X-Amz-Algorithm")
  valid_600291 = validateParameter(valid_600291, JString, required = false,
                                 default = nil)
  if valid_600291 != nil:
    section.add "X-Amz-Algorithm", valid_600291
  var valid_600292 = header.getOrDefault("X-Amz-Signature")
  valid_600292 = validateParameter(valid_600292, JString, required = false,
                                 default = nil)
  if valid_600292 != nil:
    section.add "X-Amz-Signature", valid_600292
  var valid_600293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-SignedHeaders", valid_600293
  var valid_600294 = header.getOrDefault("X-Amz-Credential")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "X-Amz-Credential", valid_600294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600296: Call_DescribeEndpoints_600283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Send an request with an empty body to the regional API endpoint to get your account API endpoint.
  ## 
  let valid = call_600296.validator(path, query, header, formData, body)
  let scheme = call_600296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600296.url(scheme.get, call_600296.host, call_600296.base,
                         call_600296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600296, url, valid)

proc call*(call_600297: Call_DescribeEndpoints_600283; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeEndpoints
  ## Send an request with an empty body to the regional API endpoint to get your account API endpoint.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600298 = newJObject()
  var body_600299 = newJObject()
  add(query_600298, "NextToken", newJString(NextToken))
  if body != nil:
    body_600299 = body
  add(query_600298, "MaxResults", newJString(MaxResults))
  result = call_600297.call(nil, query_600298, nil, nil, body_600299)

var describeEndpoints* = Call_DescribeEndpoints_600283(name: "describeEndpoints",
    meth: HttpMethod.HttpPost, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/endpoints", validator: validate_DescribeEndpoints_600284,
    base: "/", url: url_DescribeEndpoints_600285,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateCertificate_600300 = ref object of OpenApiRestCall_599368
proc url_DisassociateCertificate_600302(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociateCertificate_600301(path: JsonNode; query: JsonNode;
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
  var valid_600303 = path.getOrDefault("arn")
  valid_600303 = validateParameter(valid_600303, JString, required = true,
                                 default = nil)
  if valid_600303 != nil:
    section.add "arn", valid_600303
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
  var valid_600304 = header.getOrDefault("X-Amz-Date")
  valid_600304 = validateParameter(valid_600304, JString, required = false,
                                 default = nil)
  if valid_600304 != nil:
    section.add "X-Amz-Date", valid_600304
  var valid_600305 = header.getOrDefault("X-Amz-Security-Token")
  valid_600305 = validateParameter(valid_600305, JString, required = false,
                                 default = nil)
  if valid_600305 != nil:
    section.add "X-Amz-Security-Token", valid_600305
  var valid_600306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600306 = validateParameter(valid_600306, JString, required = false,
                                 default = nil)
  if valid_600306 != nil:
    section.add "X-Amz-Content-Sha256", valid_600306
  var valid_600307 = header.getOrDefault("X-Amz-Algorithm")
  valid_600307 = validateParameter(valid_600307, JString, required = false,
                                 default = nil)
  if valid_600307 != nil:
    section.add "X-Amz-Algorithm", valid_600307
  var valid_600308 = header.getOrDefault("X-Amz-Signature")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "X-Amz-Signature", valid_600308
  var valid_600309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600309 = validateParameter(valid_600309, JString, required = false,
                                 default = nil)
  if valid_600309 != nil:
    section.add "X-Amz-SignedHeaders", valid_600309
  var valid_600310 = header.getOrDefault("X-Amz-Credential")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "X-Amz-Credential", valid_600310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600311: Call_DisassociateCertificate_600300; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an association between the Amazon Resource Name (ARN) of an AWS Certificate Manager (ACM) certificate and an AWS Elemental MediaConvert resource.
  ## 
  let valid = call_600311.validator(path, query, header, formData, body)
  let scheme = call_600311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600311.url(scheme.get, call_600311.host, call_600311.base,
                         call_600311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600311, url, valid)

proc call*(call_600312: Call_DisassociateCertificate_600300; arn: string): Recallable =
  ## disassociateCertificate
  ## Removes an association between the Amazon Resource Name (ARN) of an AWS Certificate Manager (ACM) certificate and an AWS Elemental MediaConvert resource.
  ##   arn: string (required)
  ##      : The ARN of the ACM certificate that you want to disassociate from your MediaConvert resource.
  var path_600313 = newJObject()
  add(path_600313, "arn", newJString(arn))
  result = call_600312.call(path_600313, nil, nil, nil, nil)

var disassociateCertificate* = Call_DisassociateCertificate_600300(
    name: "disassociateCertificate", meth: HttpMethod.HttpDelete,
    host: "mediaconvert.amazonaws.com", route: "/2017-08-29/certificates/{arn}",
    validator: validate_DisassociateCertificate_600301, base: "/",
    url: url_DisassociateCertificate_600302, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600328 = ref object of OpenApiRestCall_599368
proc url_UntagResource_600330(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_600329(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600331 = path.getOrDefault("arn")
  valid_600331 = validateParameter(valid_600331, JString, required = true,
                                 default = nil)
  if valid_600331 != nil:
    section.add "arn", valid_600331
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
  var valid_600332 = header.getOrDefault("X-Amz-Date")
  valid_600332 = validateParameter(valid_600332, JString, required = false,
                                 default = nil)
  if valid_600332 != nil:
    section.add "X-Amz-Date", valid_600332
  var valid_600333 = header.getOrDefault("X-Amz-Security-Token")
  valid_600333 = validateParameter(valid_600333, JString, required = false,
                                 default = nil)
  if valid_600333 != nil:
    section.add "X-Amz-Security-Token", valid_600333
  var valid_600334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600334 = validateParameter(valid_600334, JString, required = false,
                                 default = nil)
  if valid_600334 != nil:
    section.add "X-Amz-Content-Sha256", valid_600334
  var valid_600335 = header.getOrDefault("X-Amz-Algorithm")
  valid_600335 = validateParameter(valid_600335, JString, required = false,
                                 default = nil)
  if valid_600335 != nil:
    section.add "X-Amz-Algorithm", valid_600335
  var valid_600336 = header.getOrDefault("X-Amz-Signature")
  valid_600336 = validateParameter(valid_600336, JString, required = false,
                                 default = nil)
  if valid_600336 != nil:
    section.add "X-Amz-Signature", valid_600336
  var valid_600337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600337 = validateParameter(valid_600337, JString, required = false,
                                 default = nil)
  if valid_600337 != nil:
    section.add "X-Amz-SignedHeaders", valid_600337
  var valid_600338 = header.getOrDefault("X-Amz-Credential")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-Credential", valid_600338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600340: Call_UntagResource_600328; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ## 
  let valid = call_600340.validator(path, query, header, formData, body)
  let scheme = call_600340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600340.url(scheme.get, call_600340.host, call_600340.base,
                         call_600340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600340, url, valid)

proc call*(call_600341: Call_UntagResource_600328; arn: string; body: JsonNode): Recallable =
  ## untagResource
  ## Remove tags from a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ##   arn: string (required)
  ##      : The Amazon Resource Name (ARN) of the resource that you want to remove tags from. To get the ARN, send a GET request with the resource name.
  ##   body: JObject (required)
  var path_600342 = newJObject()
  var body_600343 = newJObject()
  add(path_600342, "arn", newJString(arn))
  if body != nil:
    body_600343 = body
  result = call_600341.call(path_600342, nil, nil, nil, body_600343)

var untagResource* = Call_UntagResource_600328(name: "untagResource",
    meth: HttpMethod.HttpPut, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/tags/{arn}", validator: validate_UntagResource_600329,
    base: "/", url: url_UntagResource_600330, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600314 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_600316(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_600315(path: JsonNode; query: JsonNode;
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
  var valid_600317 = path.getOrDefault("arn")
  valid_600317 = validateParameter(valid_600317, JString, required = true,
                                 default = nil)
  if valid_600317 != nil:
    section.add "arn", valid_600317
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
  var valid_600318 = header.getOrDefault("X-Amz-Date")
  valid_600318 = validateParameter(valid_600318, JString, required = false,
                                 default = nil)
  if valid_600318 != nil:
    section.add "X-Amz-Date", valid_600318
  var valid_600319 = header.getOrDefault("X-Amz-Security-Token")
  valid_600319 = validateParameter(valid_600319, JString, required = false,
                                 default = nil)
  if valid_600319 != nil:
    section.add "X-Amz-Security-Token", valid_600319
  var valid_600320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600320 = validateParameter(valid_600320, JString, required = false,
                                 default = nil)
  if valid_600320 != nil:
    section.add "X-Amz-Content-Sha256", valid_600320
  var valid_600321 = header.getOrDefault("X-Amz-Algorithm")
  valid_600321 = validateParameter(valid_600321, JString, required = false,
                                 default = nil)
  if valid_600321 != nil:
    section.add "X-Amz-Algorithm", valid_600321
  var valid_600322 = header.getOrDefault("X-Amz-Signature")
  valid_600322 = validateParameter(valid_600322, JString, required = false,
                                 default = nil)
  if valid_600322 != nil:
    section.add "X-Amz-Signature", valid_600322
  var valid_600323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "X-Amz-SignedHeaders", valid_600323
  var valid_600324 = header.getOrDefault("X-Amz-Credential")
  valid_600324 = validateParameter(valid_600324, JString, required = false,
                                 default = nil)
  if valid_600324 != nil:
    section.add "X-Amz-Credential", valid_600324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600325: Call_ListTagsForResource_600314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the tags for a MediaConvert resource.
  ## 
  let valid = call_600325.validator(path, query, header, formData, body)
  let scheme = call_600325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600325.url(scheme.get, call_600325.host, call_600325.base,
                         call_600325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600325, url, valid)

proc call*(call_600326: Call_ListTagsForResource_600314; arn: string): Recallable =
  ## listTagsForResource
  ## Retrieve the tags for a MediaConvert resource.
  ##   arn: string (required)
  ##      : The Amazon Resource Name (ARN) of the resource that you want to list tags for. To get the ARN, send a GET request with the resource name.
  var path_600327 = newJObject()
  add(path_600327, "arn", newJString(arn))
  result = call_600326.call(path_600327, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_600314(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "mediaconvert.amazonaws.com", route: "/2017-08-29/tags/{arn}",
    validator: validate_ListTagsForResource_600315, base: "/",
    url: url_ListTagsForResource_600316, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600344 = ref object of OpenApiRestCall_599368
proc url_TagResource_600346(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_600345(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600347 = header.getOrDefault("X-Amz-Date")
  valid_600347 = validateParameter(valid_600347, JString, required = false,
                                 default = nil)
  if valid_600347 != nil:
    section.add "X-Amz-Date", valid_600347
  var valid_600348 = header.getOrDefault("X-Amz-Security-Token")
  valid_600348 = validateParameter(valid_600348, JString, required = false,
                                 default = nil)
  if valid_600348 != nil:
    section.add "X-Amz-Security-Token", valid_600348
  var valid_600349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600349 = validateParameter(valid_600349, JString, required = false,
                                 default = nil)
  if valid_600349 != nil:
    section.add "X-Amz-Content-Sha256", valid_600349
  var valid_600350 = header.getOrDefault("X-Amz-Algorithm")
  valid_600350 = validateParameter(valid_600350, JString, required = false,
                                 default = nil)
  if valid_600350 != nil:
    section.add "X-Amz-Algorithm", valid_600350
  var valid_600351 = header.getOrDefault("X-Amz-Signature")
  valid_600351 = validateParameter(valid_600351, JString, required = false,
                                 default = nil)
  if valid_600351 != nil:
    section.add "X-Amz-Signature", valid_600351
  var valid_600352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600352 = validateParameter(valid_600352, JString, required = false,
                                 default = nil)
  if valid_600352 != nil:
    section.add "X-Amz-SignedHeaders", valid_600352
  var valid_600353 = header.getOrDefault("X-Amz-Credential")
  valid_600353 = validateParameter(valid_600353, JString, required = false,
                                 default = nil)
  if valid_600353 != nil:
    section.add "X-Amz-Credential", valid_600353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600355: Call_TagResource_600344; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add tags to a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ## 
  let valid = call_600355.validator(path, query, header, formData, body)
  let scheme = call_600355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600355.url(scheme.get, call_600355.host, call_600355.base,
                         call_600355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600355, url, valid)

proc call*(call_600356: Call_TagResource_600344; body: JsonNode): Recallable =
  ## tagResource
  ## Add tags to a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ##   body: JObject (required)
  var body_600357 = newJObject()
  if body != nil:
    body_600357 = body
  result = call_600356.call(nil, nil, nil, nil, body_600357)

var tagResource* = Call_TagResource_600344(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/tags",
                                        validator: validate_TagResource_600345,
                                        base: "/", url: url_TagResource_600346,
                                        schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
