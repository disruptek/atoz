
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  Call_AssociateCertificate_601727 = ref object of OpenApiRestCall_601389
proc url_AssociateCertificate_601729(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateCertificate_601728(path: JsonNode; query: JsonNode;
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
  var valid_601841 = header.getOrDefault("X-Amz-Signature")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "X-Amz-Signature", valid_601841
  var valid_601842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "X-Amz-Content-Sha256", valid_601842
  var valid_601843 = header.getOrDefault("X-Amz-Date")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Date", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-Credential")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-Credential", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-Security-Token")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Security-Token", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Algorithm")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Algorithm", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-SignedHeaders", valid_601847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601871: Call_AssociateCertificate_601727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates an AWS Certificate Manager (ACM) Amazon Resource Name (ARN) with AWS Elemental MediaConvert.
  ## 
  let valid = call_601871.validator(path, query, header, formData, body)
  let scheme = call_601871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601871.url(scheme.get, call_601871.host, call_601871.base,
                         call_601871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601871, url, valid)

proc call*(call_601942: Call_AssociateCertificate_601727; body: JsonNode): Recallable =
  ## associateCertificate
  ## Associates an AWS Certificate Manager (ACM) Amazon Resource Name (ARN) with AWS Elemental MediaConvert.
  ##   body: JObject (required)
  var body_601943 = newJObject()
  if body != nil:
    body_601943 = body
  result = call_601942.call(nil, nil, nil, nil, body_601943)

var associateCertificate* = Call_AssociateCertificate_601727(
    name: "associateCertificate", meth: HttpMethod.HttpPost,
    host: "mediaconvert.amazonaws.com", route: "/2017-08-29/certificates",
    validator: validate_AssociateCertificate_601728, base: "/",
    url: url_AssociateCertificate_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_601982 = ref object of OpenApiRestCall_601389
proc url_GetJob_601984(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetJob_601983(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601999 = path.getOrDefault("id")
  valid_601999 = validateParameter(valid_601999, JString, required = true,
                                 default = nil)
  if valid_601999 != nil:
    section.add "id", valid_601999
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
  var valid_602000 = header.getOrDefault("X-Amz-Signature")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Signature", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Content-Sha256", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Date")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Date", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Credential")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Credential", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Security-Token")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Security-Token", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Algorithm")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Algorithm", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-SignedHeaders", valid_602006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602007: Call_GetJob_601982; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the JSON for a specific completed transcoding job.
  ## 
  let valid = call_602007.validator(path, query, header, formData, body)
  let scheme = call_602007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602007.url(scheme.get, call_602007.host, call_602007.base,
                         call_602007.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602007, url, valid)

proc call*(call_602008: Call_GetJob_601982; id: string): Recallable =
  ## getJob
  ## Retrieve the JSON for a specific completed transcoding job.
  ##   id: string (required)
  ##     : the job ID of the job.
  var path_602009 = newJObject()
  add(path_602009, "id", newJString(id))
  result = call_602008.call(path_602009, nil, nil, nil, nil)

var getJob* = Call_GetJob_601982(name: "getJob", meth: HttpMethod.HttpGet,
                              host: "mediaconvert.amazonaws.com",
                              route: "/2017-08-29/jobs/{id}",
                              validator: validate_GetJob_601983, base: "/",
                              url: url_GetJob_601984,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelJob_602011 = ref object of OpenApiRestCall_601389
proc url_CancelJob_602013(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CancelJob_602012(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602014 = path.getOrDefault("id")
  valid_602014 = validateParameter(valid_602014, JString, required = true,
                                 default = nil)
  if valid_602014 != nil:
    section.add "id", valid_602014
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
  var valid_602015 = header.getOrDefault("X-Amz-Signature")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Signature", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Content-Sha256", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Date")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Date", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Credential")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Credential", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Security-Token")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Security-Token", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Algorithm")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Algorithm", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-SignedHeaders", valid_602021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602022: Call_CancelJob_602011; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently cancel a job. Once you have canceled a job, you can't start it again.
  ## 
  let valid = call_602022.validator(path, query, header, formData, body)
  let scheme = call_602022.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602022.url(scheme.get, call_602022.host, call_602022.base,
                         call_602022.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602022, url, valid)

proc call*(call_602023: Call_CancelJob_602011; id: string): Recallable =
  ## cancelJob
  ## Permanently cancel a job. Once you have canceled a job, you can't start it again.
  ##   id: string (required)
  ##     : The Job ID of the job to be cancelled.
  var path_602024 = newJObject()
  add(path_602024, "id", newJString(id))
  result = call_602023.call(path_602024, nil, nil, nil, nil)

var cancelJob* = Call_CancelJob_602011(name: "cancelJob",
                                    meth: HttpMethod.HttpDelete,
                                    host: "mediaconvert.amazonaws.com",
                                    route: "/2017-08-29/jobs/{id}",
                                    validator: validate_CancelJob_602012,
                                    base: "/", url: url_CancelJob_602013,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_602058 = ref object of OpenApiRestCall_601389
proc url_CreateJob_602060(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateJob_602059(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602061 = header.getOrDefault("X-Amz-Signature")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Signature", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Content-Sha256", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Date")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Date", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Credential")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Credential", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Security-Token")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Security-Token", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-Algorithm")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Algorithm", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-SignedHeaders", valid_602067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602069: Call_CreateJob_602058; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new transcoding job. For information about jobs and job settings, see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ## 
  let valid = call_602069.validator(path, query, header, formData, body)
  let scheme = call_602069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602069.url(scheme.get, call_602069.host, call_602069.base,
                         call_602069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602069, url, valid)

proc call*(call_602070: Call_CreateJob_602058; body: JsonNode): Recallable =
  ## createJob
  ## Create a new transcoding job. For information about jobs and job settings, see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ##   body: JObject (required)
  var body_602071 = newJObject()
  if body != nil:
    body_602071 = body
  result = call_602070.call(nil, nil, nil, nil, body_602071)

var createJob* = Call_CreateJob_602058(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "mediaconvert.amazonaws.com",
                                    route: "/2017-08-29/jobs",
                                    validator: validate_CreateJob_602059,
                                    base: "/", url: url_CreateJob_602060,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_602025 = ref object of OpenApiRestCall_601389
proc url_ListJobs_602027(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJobs_602026(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602028 = query.getOrDefault("queue")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "queue", valid_602028
  var valid_602029 = query.getOrDefault("nextToken")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "nextToken", valid_602029
  var valid_602030 = query.getOrDefault("MaxResults")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "MaxResults", valid_602030
  var valid_602044 = query.getOrDefault("order")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_602044 != nil:
    section.add "order", valid_602044
  var valid_602045 = query.getOrDefault("NextToken")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "NextToken", valid_602045
  var valid_602046 = query.getOrDefault("status")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = newJString("SUBMITTED"))
  if valid_602046 != nil:
    section.add "status", valid_602046
  var valid_602047 = query.getOrDefault("maxResults")
  valid_602047 = validateParameter(valid_602047, JInt, required = false, default = nil)
  if valid_602047 != nil:
    section.add "maxResults", valid_602047
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
  var valid_602048 = header.getOrDefault("X-Amz-Signature")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Signature", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Content-Sha256", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Date")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Date", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-Credential")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Credential", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-Security-Token")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-Security-Token", valid_602052
  var valid_602053 = header.getOrDefault("X-Amz-Algorithm")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-Algorithm", valid_602053
  var valid_602054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-SignedHeaders", valid_602054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602055: Call_ListJobs_602025; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a JSON array of up to twenty of your most recently created jobs. This array includes in-process, completed, and errored jobs. This will return the jobs themselves, not just a list of the jobs. To retrieve the twenty next most recent jobs, use the nextToken string returned with the array.
  ## 
  let valid = call_602055.validator(path, query, header, formData, body)
  let scheme = call_602055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602055.url(scheme.get, call_602055.host, call_602055.base,
                         call_602055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602055, url, valid)

proc call*(call_602056: Call_ListJobs_602025; queue: string = "";
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
  var query_602057 = newJObject()
  add(query_602057, "queue", newJString(queue))
  add(query_602057, "nextToken", newJString(nextToken))
  add(query_602057, "MaxResults", newJString(MaxResults))
  add(query_602057, "order", newJString(order))
  add(query_602057, "NextToken", newJString(NextToken))
  add(query_602057, "status", newJString(status))
  add(query_602057, "maxResults", newJInt(maxResults))
  result = call_602056.call(nil, query_602057, nil, nil, nil)

var listJobs* = Call_ListJobs_602025(name: "listJobs", meth: HttpMethod.HttpGet,
                                  host: "mediaconvert.amazonaws.com",
                                  route: "/2017-08-29/jobs",
                                  validator: validate_ListJobs_602026, base: "/",
                                  url: url_ListJobs_602027,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJobTemplate_602092 = ref object of OpenApiRestCall_601389
proc url_CreateJobTemplate_602094(protocol: Scheme; host: string; base: string;
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

proc validate_CreateJobTemplate_602093(path: JsonNode; query: JsonNode;
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
  var valid_602095 = header.getOrDefault("X-Amz-Signature")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Signature", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-Content-Sha256", valid_602096
  var valid_602097 = header.getOrDefault("X-Amz-Date")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "X-Amz-Date", valid_602097
  var valid_602098 = header.getOrDefault("X-Amz-Credential")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "X-Amz-Credential", valid_602098
  var valid_602099 = header.getOrDefault("X-Amz-Security-Token")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "X-Amz-Security-Token", valid_602099
  var valid_602100 = header.getOrDefault("X-Amz-Algorithm")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "X-Amz-Algorithm", valid_602100
  var valid_602101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "X-Amz-SignedHeaders", valid_602101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602103: Call_CreateJobTemplate_602092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new job template. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ## 
  let valid = call_602103.validator(path, query, header, formData, body)
  let scheme = call_602103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602103.url(scheme.get, call_602103.host, call_602103.base,
                         call_602103.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602103, url, valid)

proc call*(call_602104: Call_CreateJobTemplate_602092; body: JsonNode): Recallable =
  ## createJobTemplate
  ## Create a new job template. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ##   body: JObject (required)
  var body_602105 = newJObject()
  if body != nil:
    body_602105 = body
  result = call_602104.call(nil, nil, nil, nil, body_602105)

var createJobTemplate* = Call_CreateJobTemplate_602092(name: "createJobTemplate",
    meth: HttpMethod.HttpPost, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates", validator: validate_CreateJobTemplate_602093,
    base: "/", url: url_CreateJobTemplate_602094,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobTemplates_602072 = ref object of OpenApiRestCall_601389
proc url_ListJobTemplates_602074(protocol: Scheme; host: string; base: string;
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

proc validate_ListJobTemplates_602073(path: JsonNode; query: JsonNode;
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
  var valid_602075 = query.getOrDefault("nextToken")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "nextToken", valid_602075
  var valid_602076 = query.getOrDefault("MaxResults")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "MaxResults", valid_602076
  var valid_602077 = query.getOrDefault("listBy")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = newJString("NAME"))
  if valid_602077 != nil:
    section.add "listBy", valid_602077
  var valid_602078 = query.getOrDefault("order")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_602078 != nil:
    section.add "order", valid_602078
  var valid_602079 = query.getOrDefault("NextToken")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "NextToken", valid_602079
  var valid_602080 = query.getOrDefault("category")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "category", valid_602080
  var valid_602081 = query.getOrDefault("maxResults")
  valid_602081 = validateParameter(valid_602081, JInt, required = false, default = nil)
  if valid_602081 != nil:
    section.add "maxResults", valid_602081
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
  var valid_602082 = header.getOrDefault("X-Amz-Signature")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-Signature", valid_602082
  var valid_602083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-Content-Sha256", valid_602083
  var valid_602084 = header.getOrDefault("X-Amz-Date")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-Date", valid_602084
  var valid_602085 = header.getOrDefault("X-Amz-Credential")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-Credential", valid_602085
  var valid_602086 = header.getOrDefault("X-Amz-Security-Token")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "X-Amz-Security-Token", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-Algorithm")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Algorithm", valid_602087
  var valid_602088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-SignedHeaders", valid_602088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602089: Call_ListJobTemplates_602072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a JSON array of up to twenty of your job templates. This will return the templates themselves, not just a list of them. To retrieve the next twenty templates, use the nextToken string returned with the array
  ## 
  let valid = call_602089.validator(path, query, header, formData, body)
  let scheme = call_602089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602089.url(scheme.get, call_602089.host, call_602089.base,
                         call_602089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602089, url, valid)

proc call*(call_602090: Call_ListJobTemplates_602072; nextToken: string = "";
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
  var query_602091 = newJObject()
  add(query_602091, "nextToken", newJString(nextToken))
  add(query_602091, "MaxResults", newJString(MaxResults))
  add(query_602091, "listBy", newJString(listBy))
  add(query_602091, "order", newJString(order))
  add(query_602091, "NextToken", newJString(NextToken))
  add(query_602091, "category", newJString(category))
  add(query_602091, "maxResults", newJInt(maxResults))
  result = call_602090.call(nil, query_602091, nil, nil, nil)

var listJobTemplates* = Call_ListJobTemplates_602072(name: "listJobTemplates",
    meth: HttpMethod.HttpGet, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates", validator: validate_ListJobTemplates_602073,
    base: "/", url: url_ListJobTemplates_602074,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePreset_602126 = ref object of OpenApiRestCall_601389
proc url_CreatePreset_602128(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePreset_602127(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602129 = header.getOrDefault("X-Amz-Signature")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "X-Amz-Signature", valid_602129
  var valid_602130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "X-Amz-Content-Sha256", valid_602130
  var valid_602131 = header.getOrDefault("X-Amz-Date")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "X-Amz-Date", valid_602131
  var valid_602132 = header.getOrDefault("X-Amz-Credential")
  valid_602132 = validateParameter(valid_602132, JString, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "X-Amz-Credential", valid_602132
  var valid_602133 = header.getOrDefault("X-Amz-Security-Token")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "X-Amz-Security-Token", valid_602133
  var valid_602134 = header.getOrDefault("X-Amz-Algorithm")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "X-Amz-Algorithm", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-SignedHeaders", valid_602135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602137: Call_CreatePreset_602126; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new preset. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ## 
  let valid = call_602137.validator(path, query, header, formData, body)
  let scheme = call_602137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602137.url(scheme.get, call_602137.host, call_602137.base,
                         call_602137.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602137, url, valid)

proc call*(call_602138: Call_CreatePreset_602126; body: JsonNode): Recallable =
  ## createPreset
  ## Create a new preset. For information about job templates see the User Guide at http://docs.aws.amazon.com/mediaconvert/latest/ug/what-is.html
  ##   body: JObject (required)
  var body_602139 = newJObject()
  if body != nil:
    body_602139 = body
  result = call_602138.call(nil, nil, nil, nil, body_602139)

var createPreset* = Call_CreatePreset_602126(name: "createPreset",
    meth: HttpMethod.HttpPost, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/presets", validator: validate_CreatePreset_602127,
    base: "/", url: url_CreatePreset_602128, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPresets_602106 = ref object of OpenApiRestCall_601389
proc url_ListPresets_602108(protocol: Scheme; host: string; base: string;
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

proc validate_ListPresets_602107(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602109 = query.getOrDefault("nextToken")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "nextToken", valid_602109
  var valid_602110 = query.getOrDefault("MaxResults")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "MaxResults", valid_602110
  var valid_602111 = query.getOrDefault("listBy")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = newJString("NAME"))
  if valid_602111 != nil:
    section.add "listBy", valid_602111
  var valid_602112 = query.getOrDefault("order")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_602112 != nil:
    section.add "order", valid_602112
  var valid_602113 = query.getOrDefault("NextToken")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "NextToken", valid_602113
  var valid_602114 = query.getOrDefault("category")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "category", valid_602114
  var valid_602115 = query.getOrDefault("maxResults")
  valid_602115 = validateParameter(valid_602115, JInt, required = false, default = nil)
  if valid_602115 != nil:
    section.add "maxResults", valid_602115
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
  var valid_602116 = header.getOrDefault("X-Amz-Signature")
  valid_602116 = validateParameter(valid_602116, JString, required = false,
                                 default = nil)
  if valid_602116 != nil:
    section.add "X-Amz-Signature", valid_602116
  var valid_602117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602117 = validateParameter(valid_602117, JString, required = false,
                                 default = nil)
  if valid_602117 != nil:
    section.add "X-Amz-Content-Sha256", valid_602117
  var valid_602118 = header.getOrDefault("X-Amz-Date")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "X-Amz-Date", valid_602118
  var valid_602119 = header.getOrDefault("X-Amz-Credential")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-Credential", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Security-Token")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Security-Token", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Algorithm")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Algorithm", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-SignedHeaders", valid_602122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602123: Call_ListPresets_602106; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a JSON array of up to twenty of your presets. This will return the presets themselves, not just a list of them. To retrieve the next twenty presets, use the nextToken string returned with the array.
  ## 
  let valid = call_602123.validator(path, query, header, formData, body)
  let scheme = call_602123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602123.url(scheme.get, call_602123.host, call_602123.base,
                         call_602123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602123, url, valid)

proc call*(call_602124: Call_ListPresets_602106; nextToken: string = "";
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
  var query_602125 = newJObject()
  add(query_602125, "nextToken", newJString(nextToken))
  add(query_602125, "MaxResults", newJString(MaxResults))
  add(query_602125, "listBy", newJString(listBy))
  add(query_602125, "order", newJString(order))
  add(query_602125, "NextToken", newJString(NextToken))
  add(query_602125, "category", newJString(category))
  add(query_602125, "maxResults", newJInt(maxResults))
  result = call_602124.call(nil, query_602125, nil, nil, nil)

var listPresets* = Call_ListPresets_602106(name: "listPresets",
                                        meth: HttpMethod.HttpGet,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/presets",
                                        validator: validate_ListPresets_602107,
                                        base: "/", url: url_ListPresets_602108,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateQueue_602159 = ref object of OpenApiRestCall_601389
proc url_CreateQueue_602161(protocol: Scheme; host: string; base: string;
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

proc validate_CreateQueue_602160(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602162 = header.getOrDefault("X-Amz-Signature")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Signature", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Content-Sha256", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-Date")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-Date", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Credential")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Credential", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Security-Token")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Security-Token", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Algorithm")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Algorithm", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-SignedHeaders", valid_602168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602170: Call_CreateQueue_602159; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new transcoding queue. For information about queues, see Working With Queues in the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/working-with-queues.html
  ## 
  let valid = call_602170.validator(path, query, header, formData, body)
  let scheme = call_602170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602170.url(scheme.get, call_602170.host, call_602170.base,
                         call_602170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602170, url, valid)

proc call*(call_602171: Call_CreateQueue_602159; body: JsonNode): Recallable =
  ## createQueue
  ## Create a new transcoding queue. For information about queues, see Working With Queues in the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/working-with-queues.html
  ##   body: JObject (required)
  var body_602172 = newJObject()
  if body != nil:
    body_602172 = body
  result = call_602171.call(nil, nil, nil, nil, body_602172)

var createQueue* = Call_CreateQueue_602159(name: "createQueue",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/queues",
                                        validator: validate_CreateQueue_602160,
                                        base: "/", url: url_CreateQueue_602161,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQueues_602140 = ref object of OpenApiRestCall_601389
proc url_ListQueues_602142(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListQueues_602141(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602143 = query.getOrDefault("nextToken")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "nextToken", valid_602143
  var valid_602144 = query.getOrDefault("MaxResults")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "MaxResults", valid_602144
  var valid_602145 = query.getOrDefault("listBy")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = newJString("NAME"))
  if valid_602145 != nil:
    section.add "listBy", valid_602145
  var valid_602146 = query.getOrDefault("order")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_602146 != nil:
    section.add "order", valid_602146
  var valid_602147 = query.getOrDefault("NextToken")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "NextToken", valid_602147
  var valid_602148 = query.getOrDefault("maxResults")
  valid_602148 = validateParameter(valid_602148, JInt, required = false, default = nil)
  if valid_602148 != nil:
    section.add "maxResults", valid_602148
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
  var valid_602149 = header.getOrDefault("X-Amz-Signature")
  valid_602149 = validateParameter(valid_602149, JString, required = false,
                                 default = nil)
  if valid_602149 != nil:
    section.add "X-Amz-Signature", valid_602149
  var valid_602150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Content-Sha256", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-Date")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Date", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-Credential")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Credential", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-Security-Token")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Security-Token", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Algorithm")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Algorithm", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-SignedHeaders", valid_602155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602156: Call_ListQueues_602140; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a JSON array of up to twenty of your queues. This will return the queues themselves, not just a list of them. To retrieve the next twenty queues, use the nextToken string returned with the array.
  ## 
  let valid = call_602156.validator(path, query, header, formData, body)
  let scheme = call_602156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602156.url(scheme.get, call_602156.host, call_602156.base,
                         call_602156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602156, url, valid)

proc call*(call_602157: Call_ListQueues_602140; nextToken: string = "";
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
  var query_602158 = newJObject()
  add(query_602158, "nextToken", newJString(nextToken))
  add(query_602158, "MaxResults", newJString(MaxResults))
  add(query_602158, "listBy", newJString(listBy))
  add(query_602158, "order", newJString(order))
  add(query_602158, "NextToken", newJString(NextToken))
  add(query_602158, "maxResults", newJInt(maxResults))
  result = call_602157.call(nil, query_602158, nil, nil, nil)

var listQueues* = Call_ListQueues_602140(name: "listQueues",
                                      meth: HttpMethod.HttpGet,
                                      host: "mediaconvert.amazonaws.com",
                                      route: "/2017-08-29/queues",
                                      validator: validate_ListQueues_602141,
                                      base: "/", url: url_ListQueues_602142,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJobTemplate_602187 = ref object of OpenApiRestCall_601389
proc url_UpdateJobTemplate_602189(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateJobTemplate_602188(path: JsonNode; query: JsonNode;
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
  var valid_602190 = path.getOrDefault("name")
  valid_602190 = validateParameter(valid_602190, JString, required = true,
                                 default = nil)
  if valid_602190 != nil:
    section.add "name", valid_602190
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
  var valid_602191 = header.getOrDefault("X-Amz-Signature")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "X-Amz-Signature", valid_602191
  var valid_602192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Content-Sha256", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-Date")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Date", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-Credential")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Credential", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Security-Token")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Security-Token", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Algorithm")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Algorithm", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-SignedHeaders", valid_602197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602199: Call_UpdateJobTemplate_602187; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modify one of your existing job templates.
  ## 
  let valid = call_602199.validator(path, query, header, formData, body)
  let scheme = call_602199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602199.url(scheme.get, call_602199.host, call_602199.base,
                         call_602199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602199, url, valid)

proc call*(call_602200: Call_UpdateJobTemplate_602187; name: string; body: JsonNode): Recallable =
  ## updateJobTemplate
  ## Modify one of your existing job templates.
  ##   name: string (required)
  ##       : The name of the job template you are modifying
  ##   body: JObject (required)
  var path_602201 = newJObject()
  var body_602202 = newJObject()
  add(path_602201, "name", newJString(name))
  if body != nil:
    body_602202 = body
  result = call_602200.call(path_602201, nil, nil, nil, body_602202)

var updateJobTemplate* = Call_UpdateJobTemplate_602187(name: "updateJobTemplate",
    meth: HttpMethod.HttpPut, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates/{name}",
    validator: validate_UpdateJobTemplate_602188, base: "/",
    url: url_UpdateJobTemplate_602189, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobTemplate_602173 = ref object of OpenApiRestCall_601389
proc url_GetJobTemplate_602175(protocol: Scheme; host: string; base: string;
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

proc validate_GetJobTemplate_602174(path: JsonNode; query: JsonNode;
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
  var valid_602176 = path.getOrDefault("name")
  valid_602176 = validateParameter(valid_602176, JString, required = true,
                                 default = nil)
  if valid_602176 != nil:
    section.add "name", valid_602176
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
  var valid_602177 = header.getOrDefault("X-Amz-Signature")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Signature", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Content-Sha256", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Date")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Date", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Credential")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Credential", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Security-Token")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Security-Token", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Algorithm")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Algorithm", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-SignedHeaders", valid_602183
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602184: Call_GetJobTemplate_602173; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the JSON for a specific job template.
  ## 
  let valid = call_602184.validator(path, query, header, formData, body)
  let scheme = call_602184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602184.url(scheme.get, call_602184.host, call_602184.base,
                         call_602184.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602184, url, valid)

proc call*(call_602185: Call_GetJobTemplate_602173; name: string): Recallable =
  ## getJobTemplate
  ## Retrieve the JSON for a specific job template.
  ##   name: string (required)
  ##       : The name of the job template.
  var path_602186 = newJObject()
  add(path_602186, "name", newJString(name))
  result = call_602185.call(path_602186, nil, nil, nil, nil)

var getJobTemplate* = Call_GetJobTemplate_602173(name: "getJobTemplate",
    meth: HttpMethod.HttpGet, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates/{name}", validator: validate_GetJobTemplate_602174,
    base: "/", url: url_GetJobTemplate_602175, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJobTemplate_602203 = ref object of OpenApiRestCall_601389
proc url_DeleteJobTemplate_602205(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteJobTemplate_602204(path: JsonNode; query: JsonNode;
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
  var valid_602206 = path.getOrDefault("name")
  valid_602206 = validateParameter(valid_602206, JString, required = true,
                                 default = nil)
  if valid_602206 != nil:
    section.add "name", valid_602206
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
  var valid_602207 = header.getOrDefault("X-Amz-Signature")
  valid_602207 = validateParameter(valid_602207, JString, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "X-Amz-Signature", valid_602207
  var valid_602208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602208 = validateParameter(valid_602208, JString, required = false,
                                 default = nil)
  if valid_602208 != nil:
    section.add "X-Amz-Content-Sha256", valid_602208
  var valid_602209 = header.getOrDefault("X-Amz-Date")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "X-Amz-Date", valid_602209
  var valid_602210 = header.getOrDefault("X-Amz-Credential")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Credential", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-Security-Token")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Security-Token", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-Algorithm")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Algorithm", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-SignedHeaders", valid_602213
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602214: Call_DeleteJobTemplate_602203; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently delete a job template you have created.
  ## 
  let valid = call_602214.validator(path, query, header, formData, body)
  let scheme = call_602214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602214.url(scheme.get, call_602214.host, call_602214.base,
                         call_602214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602214, url, valid)

proc call*(call_602215: Call_DeleteJobTemplate_602203; name: string): Recallable =
  ## deleteJobTemplate
  ## Permanently delete a job template you have created.
  ##   name: string (required)
  ##       : The name of the job template to be deleted.
  var path_602216 = newJObject()
  add(path_602216, "name", newJString(name))
  result = call_602215.call(path_602216, nil, nil, nil, nil)

var deleteJobTemplate* = Call_DeleteJobTemplate_602203(name: "deleteJobTemplate",
    meth: HttpMethod.HttpDelete, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/jobTemplates/{name}",
    validator: validate_DeleteJobTemplate_602204, base: "/",
    url: url_DeleteJobTemplate_602205, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePreset_602231 = ref object of OpenApiRestCall_601389
proc url_UpdatePreset_602233(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePreset_602232(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602234 = path.getOrDefault("name")
  valid_602234 = validateParameter(valid_602234, JString, required = true,
                                 default = nil)
  if valid_602234 != nil:
    section.add "name", valid_602234
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
  var valid_602235 = header.getOrDefault("X-Amz-Signature")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-Signature", valid_602235
  var valid_602236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-Content-Sha256", valid_602236
  var valid_602237 = header.getOrDefault("X-Amz-Date")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "X-Amz-Date", valid_602237
  var valid_602238 = header.getOrDefault("X-Amz-Credential")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "X-Amz-Credential", valid_602238
  var valid_602239 = header.getOrDefault("X-Amz-Security-Token")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "X-Amz-Security-Token", valid_602239
  var valid_602240 = header.getOrDefault("X-Amz-Algorithm")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-Algorithm", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-SignedHeaders", valid_602241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602243: Call_UpdatePreset_602231; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modify one of your existing presets.
  ## 
  let valid = call_602243.validator(path, query, header, formData, body)
  let scheme = call_602243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602243.url(scheme.get, call_602243.host, call_602243.base,
                         call_602243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602243, url, valid)

proc call*(call_602244: Call_UpdatePreset_602231; name: string; body: JsonNode): Recallable =
  ## updatePreset
  ## Modify one of your existing presets.
  ##   name: string (required)
  ##       : The name of the preset you are modifying.
  ##   body: JObject (required)
  var path_602245 = newJObject()
  var body_602246 = newJObject()
  add(path_602245, "name", newJString(name))
  if body != nil:
    body_602246 = body
  result = call_602244.call(path_602245, nil, nil, nil, body_602246)

var updatePreset* = Call_UpdatePreset_602231(name: "updatePreset",
    meth: HttpMethod.HttpPut, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/presets/{name}", validator: validate_UpdatePreset_602232,
    base: "/", url: url_UpdatePreset_602233, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPreset_602217 = ref object of OpenApiRestCall_601389
proc url_GetPreset_602219(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetPreset_602218(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602220 = path.getOrDefault("name")
  valid_602220 = validateParameter(valid_602220, JString, required = true,
                                 default = nil)
  if valid_602220 != nil:
    section.add "name", valid_602220
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
  var valid_602221 = header.getOrDefault("X-Amz-Signature")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "X-Amz-Signature", valid_602221
  var valid_602222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "X-Amz-Content-Sha256", valid_602222
  var valid_602223 = header.getOrDefault("X-Amz-Date")
  valid_602223 = validateParameter(valid_602223, JString, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "X-Amz-Date", valid_602223
  var valid_602224 = header.getOrDefault("X-Amz-Credential")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "X-Amz-Credential", valid_602224
  var valid_602225 = header.getOrDefault("X-Amz-Security-Token")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-Security-Token", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-Algorithm")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Algorithm", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-SignedHeaders", valid_602227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602228: Call_GetPreset_602217; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the JSON for a specific preset.
  ## 
  let valid = call_602228.validator(path, query, header, formData, body)
  let scheme = call_602228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602228.url(scheme.get, call_602228.host, call_602228.base,
                         call_602228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602228, url, valid)

proc call*(call_602229: Call_GetPreset_602217; name: string): Recallable =
  ## getPreset
  ## Retrieve the JSON for a specific preset.
  ##   name: string (required)
  ##       : The name of the preset.
  var path_602230 = newJObject()
  add(path_602230, "name", newJString(name))
  result = call_602229.call(path_602230, nil, nil, nil, nil)

var getPreset* = Call_GetPreset_602217(name: "getPreset", meth: HttpMethod.HttpGet,
                                    host: "mediaconvert.amazonaws.com",
                                    route: "/2017-08-29/presets/{name}",
                                    validator: validate_GetPreset_602218,
                                    base: "/", url: url_GetPreset_602219,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePreset_602247 = ref object of OpenApiRestCall_601389
proc url_DeletePreset_602249(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePreset_602248(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602250 = path.getOrDefault("name")
  valid_602250 = validateParameter(valid_602250, JString, required = true,
                                 default = nil)
  if valid_602250 != nil:
    section.add "name", valid_602250
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
  var valid_602251 = header.getOrDefault("X-Amz-Signature")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-Signature", valid_602251
  var valid_602252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602252 = validateParameter(valid_602252, JString, required = false,
                                 default = nil)
  if valid_602252 != nil:
    section.add "X-Amz-Content-Sha256", valid_602252
  var valid_602253 = header.getOrDefault("X-Amz-Date")
  valid_602253 = validateParameter(valid_602253, JString, required = false,
                                 default = nil)
  if valid_602253 != nil:
    section.add "X-Amz-Date", valid_602253
  var valid_602254 = header.getOrDefault("X-Amz-Credential")
  valid_602254 = validateParameter(valid_602254, JString, required = false,
                                 default = nil)
  if valid_602254 != nil:
    section.add "X-Amz-Credential", valid_602254
  var valid_602255 = header.getOrDefault("X-Amz-Security-Token")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-Security-Token", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-Algorithm")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-Algorithm", valid_602256
  var valid_602257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-SignedHeaders", valid_602257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602258: Call_DeletePreset_602247; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently delete a preset you have created.
  ## 
  let valid = call_602258.validator(path, query, header, formData, body)
  let scheme = call_602258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602258.url(scheme.get, call_602258.host, call_602258.base,
                         call_602258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602258, url, valid)

proc call*(call_602259: Call_DeletePreset_602247; name: string): Recallable =
  ## deletePreset
  ## Permanently delete a preset you have created.
  ##   name: string (required)
  ##       : The name of the preset to be deleted.
  var path_602260 = newJObject()
  add(path_602260, "name", newJString(name))
  result = call_602259.call(path_602260, nil, nil, nil, nil)

var deletePreset* = Call_DeletePreset_602247(name: "deletePreset",
    meth: HttpMethod.HttpDelete, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/presets/{name}", validator: validate_DeletePreset_602248,
    base: "/", url: url_DeletePreset_602249, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateQueue_602275 = ref object of OpenApiRestCall_601389
proc url_UpdateQueue_602277(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateQueue_602276(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602278 = path.getOrDefault("name")
  valid_602278 = validateParameter(valid_602278, JString, required = true,
                                 default = nil)
  if valid_602278 != nil:
    section.add "name", valid_602278
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
  var valid_602279 = header.getOrDefault("X-Amz-Signature")
  valid_602279 = validateParameter(valid_602279, JString, required = false,
                                 default = nil)
  if valid_602279 != nil:
    section.add "X-Amz-Signature", valid_602279
  var valid_602280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602280 = validateParameter(valid_602280, JString, required = false,
                                 default = nil)
  if valid_602280 != nil:
    section.add "X-Amz-Content-Sha256", valid_602280
  var valid_602281 = header.getOrDefault("X-Amz-Date")
  valid_602281 = validateParameter(valid_602281, JString, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "X-Amz-Date", valid_602281
  var valid_602282 = header.getOrDefault("X-Amz-Credential")
  valid_602282 = validateParameter(valid_602282, JString, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "X-Amz-Credential", valid_602282
  var valid_602283 = header.getOrDefault("X-Amz-Security-Token")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "X-Amz-Security-Token", valid_602283
  var valid_602284 = header.getOrDefault("X-Amz-Algorithm")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-Algorithm", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-SignedHeaders", valid_602285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602287: Call_UpdateQueue_602275; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modify one of your existing queues.
  ## 
  let valid = call_602287.validator(path, query, header, formData, body)
  let scheme = call_602287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602287.url(scheme.get, call_602287.host, call_602287.base,
                         call_602287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602287, url, valid)

proc call*(call_602288: Call_UpdateQueue_602275; name: string; body: JsonNode): Recallable =
  ## updateQueue
  ## Modify one of your existing queues.
  ##   name: string (required)
  ##       : The name of the queue that you are modifying.
  ##   body: JObject (required)
  var path_602289 = newJObject()
  var body_602290 = newJObject()
  add(path_602289, "name", newJString(name))
  if body != nil:
    body_602290 = body
  result = call_602288.call(path_602289, nil, nil, nil, body_602290)

var updateQueue* = Call_UpdateQueue_602275(name: "updateQueue",
                                        meth: HttpMethod.HttpPut,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/queues/{name}",
                                        validator: validate_UpdateQueue_602276,
                                        base: "/", url: url_UpdateQueue_602277,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQueue_602261 = ref object of OpenApiRestCall_601389
proc url_GetQueue_602263(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetQueue_602262(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602264 = path.getOrDefault("name")
  valid_602264 = validateParameter(valid_602264, JString, required = true,
                                 default = nil)
  if valid_602264 != nil:
    section.add "name", valid_602264
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
  var valid_602265 = header.getOrDefault("X-Amz-Signature")
  valid_602265 = validateParameter(valid_602265, JString, required = false,
                                 default = nil)
  if valid_602265 != nil:
    section.add "X-Amz-Signature", valid_602265
  var valid_602266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602266 = validateParameter(valid_602266, JString, required = false,
                                 default = nil)
  if valid_602266 != nil:
    section.add "X-Amz-Content-Sha256", valid_602266
  var valid_602267 = header.getOrDefault("X-Amz-Date")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "X-Amz-Date", valid_602267
  var valid_602268 = header.getOrDefault("X-Amz-Credential")
  valid_602268 = validateParameter(valid_602268, JString, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "X-Amz-Credential", valid_602268
  var valid_602269 = header.getOrDefault("X-Amz-Security-Token")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "X-Amz-Security-Token", valid_602269
  var valid_602270 = header.getOrDefault("X-Amz-Algorithm")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "X-Amz-Algorithm", valid_602270
  var valid_602271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-SignedHeaders", valid_602271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602272: Call_GetQueue_602261; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the JSON for a specific queue.
  ## 
  let valid = call_602272.validator(path, query, header, formData, body)
  let scheme = call_602272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602272.url(scheme.get, call_602272.host, call_602272.base,
                         call_602272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602272, url, valid)

proc call*(call_602273: Call_GetQueue_602261; name: string): Recallable =
  ## getQueue
  ## Retrieve the JSON for a specific queue.
  ##   name: string (required)
  ##       : The name of the queue that you want information about.
  var path_602274 = newJObject()
  add(path_602274, "name", newJString(name))
  result = call_602273.call(path_602274, nil, nil, nil, nil)

var getQueue* = Call_GetQueue_602261(name: "getQueue", meth: HttpMethod.HttpGet,
                                  host: "mediaconvert.amazonaws.com",
                                  route: "/2017-08-29/queues/{name}",
                                  validator: validate_GetQueue_602262, base: "/",
                                  url: url_GetQueue_602263,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteQueue_602291 = ref object of OpenApiRestCall_601389
proc url_DeleteQueue_602293(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteQueue_602292(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602294 = path.getOrDefault("name")
  valid_602294 = validateParameter(valid_602294, JString, required = true,
                                 default = nil)
  if valid_602294 != nil:
    section.add "name", valid_602294
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
  var valid_602295 = header.getOrDefault("X-Amz-Signature")
  valid_602295 = validateParameter(valid_602295, JString, required = false,
                                 default = nil)
  if valid_602295 != nil:
    section.add "X-Amz-Signature", valid_602295
  var valid_602296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = nil)
  if valid_602296 != nil:
    section.add "X-Amz-Content-Sha256", valid_602296
  var valid_602297 = header.getOrDefault("X-Amz-Date")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "X-Amz-Date", valid_602297
  var valid_602298 = header.getOrDefault("X-Amz-Credential")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "X-Amz-Credential", valid_602298
  var valid_602299 = header.getOrDefault("X-Amz-Security-Token")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "X-Amz-Security-Token", valid_602299
  var valid_602300 = header.getOrDefault("X-Amz-Algorithm")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Algorithm", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-SignedHeaders", valid_602301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602302: Call_DeleteQueue_602291; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently delete a queue you have created.
  ## 
  let valid = call_602302.validator(path, query, header, formData, body)
  let scheme = call_602302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602302.url(scheme.get, call_602302.host, call_602302.base,
                         call_602302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602302, url, valid)

proc call*(call_602303: Call_DeleteQueue_602291; name: string): Recallable =
  ## deleteQueue
  ## Permanently delete a queue you have created.
  ##   name: string (required)
  ##       : The name of the queue that you want to delete.
  var path_602304 = newJObject()
  add(path_602304, "name", newJString(name))
  result = call_602303.call(path_602304, nil, nil, nil, nil)

var deleteQueue* = Call_DeleteQueue_602291(name: "deleteQueue",
                                        meth: HttpMethod.HttpDelete,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/queues/{name}",
                                        validator: validate_DeleteQueue_602292,
                                        base: "/", url: url_DeleteQueue_602293,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoints_602305 = ref object of OpenApiRestCall_601389
proc url_DescribeEndpoints_602307(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeEndpoints_602306(path: JsonNode; query: JsonNode;
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
  var valid_602308 = query.getOrDefault("MaxResults")
  valid_602308 = validateParameter(valid_602308, JString, required = false,
                                 default = nil)
  if valid_602308 != nil:
    section.add "MaxResults", valid_602308
  var valid_602309 = query.getOrDefault("NextToken")
  valid_602309 = validateParameter(valid_602309, JString, required = false,
                                 default = nil)
  if valid_602309 != nil:
    section.add "NextToken", valid_602309
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
  var valid_602310 = header.getOrDefault("X-Amz-Signature")
  valid_602310 = validateParameter(valid_602310, JString, required = false,
                                 default = nil)
  if valid_602310 != nil:
    section.add "X-Amz-Signature", valid_602310
  var valid_602311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602311 = validateParameter(valid_602311, JString, required = false,
                                 default = nil)
  if valid_602311 != nil:
    section.add "X-Amz-Content-Sha256", valid_602311
  var valid_602312 = header.getOrDefault("X-Amz-Date")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "X-Amz-Date", valid_602312
  var valid_602313 = header.getOrDefault("X-Amz-Credential")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-Credential", valid_602313
  var valid_602314 = header.getOrDefault("X-Amz-Security-Token")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Security-Token", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-Algorithm")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Algorithm", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-SignedHeaders", valid_602316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602318: Call_DescribeEndpoints_602305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Send an request with an empty body to the regional API endpoint to get your account API endpoint.
  ## 
  let valid = call_602318.validator(path, query, header, formData, body)
  let scheme = call_602318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602318.url(scheme.get, call_602318.host, call_602318.base,
                         call_602318.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602318, url, valid)

proc call*(call_602319: Call_DescribeEndpoints_602305; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeEndpoints
  ## Send an request with an empty body to the regional API endpoint to get your account API endpoint.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602320 = newJObject()
  var body_602321 = newJObject()
  add(query_602320, "MaxResults", newJString(MaxResults))
  add(query_602320, "NextToken", newJString(NextToken))
  if body != nil:
    body_602321 = body
  result = call_602319.call(nil, query_602320, nil, nil, body_602321)

var describeEndpoints* = Call_DescribeEndpoints_602305(name: "describeEndpoints",
    meth: HttpMethod.HttpPost, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/endpoints", validator: validate_DescribeEndpoints_602306,
    base: "/", url: url_DescribeEndpoints_602307,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateCertificate_602322 = ref object of OpenApiRestCall_601389
proc url_DisassociateCertificate_602324(protocol: Scheme; host: string; base: string;
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

proc validate_DisassociateCertificate_602323(path: JsonNode; query: JsonNode;
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
  var valid_602325 = path.getOrDefault("arn")
  valid_602325 = validateParameter(valid_602325, JString, required = true,
                                 default = nil)
  if valid_602325 != nil:
    section.add "arn", valid_602325
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
  var valid_602326 = header.getOrDefault("X-Amz-Signature")
  valid_602326 = validateParameter(valid_602326, JString, required = false,
                                 default = nil)
  if valid_602326 != nil:
    section.add "X-Amz-Signature", valid_602326
  var valid_602327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "X-Amz-Content-Sha256", valid_602327
  var valid_602328 = header.getOrDefault("X-Amz-Date")
  valid_602328 = validateParameter(valid_602328, JString, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "X-Amz-Date", valid_602328
  var valid_602329 = header.getOrDefault("X-Amz-Credential")
  valid_602329 = validateParameter(valid_602329, JString, required = false,
                                 default = nil)
  if valid_602329 != nil:
    section.add "X-Amz-Credential", valid_602329
  var valid_602330 = header.getOrDefault("X-Amz-Security-Token")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "X-Amz-Security-Token", valid_602330
  var valid_602331 = header.getOrDefault("X-Amz-Algorithm")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Algorithm", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-SignedHeaders", valid_602332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602333: Call_DisassociateCertificate_602322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an association between the Amazon Resource Name (ARN) of an AWS Certificate Manager (ACM) certificate and an AWS Elemental MediaConvert resource.
  ## 
  let valid = call_602333.validator(path, query, header, formData, body)
  let scheme = call_602333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602333.url(scheme.get, call_602333.host, call_602333.base,
                         call_602333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602333, url, valid)

proc call*(call_602334: Call_DisassociateCertificate_602322; arn: string): Recallable =
  ## disassociateCertificate
  ## Removes an association between the Amazon Resource Name (ARN) of an AWS Certificate Manager (ACM) certificate and an AWS Elemental MediaConvert resource.
  ##   arn: string (required)
  ##      : The ARN of the ACM certificate that you want to disassociate from your MediaConvert resource.
  var path_602335 = newJObject()
  add(path_602335, "arn", newJString(arn))
  result = call_602334.call(path_602335, nil, nil, nil, nil)

var disassociateCertificate* = Call_DisassociateCertificate_602322(
    name: "disassociateCertificate", meth: HttpMethod.HttpDelete,
    host: "mediaconvert.amazonaws.com", route: "/2017-08-29/certificates/{arn}",
    validator: validate_DisassociateCertificate_602323, base: "/",
    url: url_DisassociateCertificate_602324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602350 = ref object of OpenApiRestCall_601389
proc url_UntagResource_602352(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_602351(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602353 = path.getOrDefault("arn")
  valid_602353 = validateParameter(valid_602353, JString, required = true,
                                 default = nil)
  if valid_602353 != nil:
    section.add "arn", valid_602353
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
  var valid_602354 = header.getOrDefault("X-Amz-Signature")
  valid_602354 = validateParameter(valid_602354, JString, required = false,
                                 default = nil)
  if valid_602354 != nil:
    section.add "X-Amz-Signature", valid_602354
  var valid_602355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602355 = validateParameter(valid_602355, JString, required = false,
                                 default = nil)
  if valid_602355 != nil:
    section.add "X-Amz-Content-Sha256", valid_602355
  var valid_602356 = header.getOrDefault("X-Amz-Date")
  valid_602356 = validateParameter(valid_602356, JString, required = false,
                                 default = nil)
  if valid_602356 != nil:
    section.add "X-Amz-Date", valid_602356
  var valid_602357 = header.getOrDefault("X-Amz-Credential")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-Credential", valid_602357
  var valid_602358 = header.getOrDefault("X-Amz-Security-Token")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "X-Amz-Security-Token", valid_602358
  var valid_602359 = header.getOrDefault("X-Amz-Algorithm")
  valid_602359 = validateParameter(valid_602359, JString, required = false,
                                 default = nil)
  if valid_602359 != nil:
    section.add "X-Amz-Algorithm", valid_602359
  var valid_602360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "X-Amz-SignedHeaders", valid_602360
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602362: Call_UntagResource_602350; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ## 
  let valid = call_602362.validator(path, query, header, formData, body)
  let scheme = call_602362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602362.url(scheme.get, call_602362.host, call_602362.base,
                         call_602362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602362, url, valid)

proc call*(call_602363: Call_UntagResource_602350; arn: string; body: JsonNode): Recallable =
  ## untagResource
  ## Remove tags from a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ##   arn: string (required)
  ##      : The Amazon Resource Name (ARN) of the resource that you want to remove tags from. To get the ARN, send a GET request with the resource name.
  ##   body: JObject (required)
  var path_602364 = newJObject()
  var body_602365 = newJObject()
  add(path_602364, "arn", newJString(arn))
  if body != nil:
    body_602365 = body
  result = call_602363.call(path_602364, nil, nil, nil, body_602365)

var untagResource* = Call_UntagResource_602350(name: "untagResource",
    meth: HttpMethod.HttpPut, host: "mediaconvert.amazonaws.com",
    route: "/2017-08-29/tags/{arn}", validator: validate_UntagResource_602351,
    base: "/", url: url_UntagResource_602352, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602336 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource_602338(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_602337(path: JsonNode; query: JsonNode;
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
  var valid_602339 = path.getOrDefault("arn")
  valid_602339 = validateParameter(valid_602339, JString, required = true,
                                 default = nil)
  if valid_602339 != nil:
    section.add "arn", valid_602339
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
  var valid_602340 = header.getOrDefault("X-Amz-Signature")
  valid_602340 = validateParameter(valid_602340, JString, required = false,
                                 default = nil)
  if valid_602340 != nil:
    section.add "X-Amz-Signature", valid_602340
  var valid_602341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602341 = validateParameter(valid_602341, JString, required = false,
                                 default = nil)
  if valid_602341 != nil:
    section.add "X-Amz-Content-Sha256", valid_602341
  var valid_602342 = header.getOrDefault("X-Amz-Date")
  valid_602342 = validateParameter(valid_602342, JString, required = false,
                                 default = nil)
  if valid_602342 != nil:
    section.add "X-Amz-Date", valid_602342
  var valid_602343 = header.getOrDefault("X-Amz-Credential")
  valid_602343 = validateParameter(valid_602343, JString, required = false,
                                 default = nil)
  if valid_602343 != nil:
    section.add "X-Amz-Credential", valid_602343
  var valid_602344 = header.getOrDefault("X-Amz-Security-Token")
  valid_602344 = validateParameter(valid_602344, JString, required = false,
                                 default = nil)
  if valid_602344 != nil:
    section.add "X-Amz-Security-Token", valid_602344
  var valid_602345 = header.getOrDefault("X-Amz-Algorithm")
  valid_602345 = validateParameter(valid_602345, JString, required = false,
                                 default = nil)
  if valid_602345 != nil:
    section.add "X-Amz-Algorithm", valid_602345
  var valid_602346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "X-Amz-SignedHeaders", valid_602346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602347: Call_ListTagsForResource_602336; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the tags for a MediaConvert resource.
  ## 
  let valid = call_602347.validator(path, query, header, formData, body)
  let scheme = call_602347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602347.url(scheme.get, call_602347.host, call_602347.base,
                         call_602347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602347, url, valid)

proc call*(call_602348: Call_ListTagsForResource_602336; arn: string): Recallable =
  ## listTagsForResource
  ## Retrieve the tags for a MediaConvert resource.
  ##   arn: string (required)
  ##      : The Amazon Resource Name (ARN) of the resource that you want to list tags for. To get the ARN, send a GET request with the resource name.
  var path_602349 = newJObject()
  add(path_602349, "arn", newJString(arn))
  result = call_602348.call(path_602349, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_602336(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "mediaconvert.amazonaws.com", route: "/2017-08-29/tags/{arn}",
    validator: validate_ListTagsForResource_602337, base: "/",
    url: url_ListTagsForResource_602338, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602366 = ref object of OpenApiRestCall_601389
proc url_TagResource_602368(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_602367(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602369 = header.getOrDefault("X-Amz-Signature")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-Signature", valid_602369
  var valid_602370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602370 = validateParameter(valid_602370, JString, required = false,
                                 default = nil)
  if valid_602370 != nil:
    section.add "X-Amz-Content-Sha256", valid_602370
  var valid_602371 = header.getOrDefault("X-Amz-Date")
  valid_602371 = validateParameter(valid_602371, JString, required = false,
                                 default = nil)
  if valid_602371 != nil:
    section.add "X-Amz-Date", valid_602371
  var valid_602372 = header.getOrDefault("X-Amz-Credential")
  valid_602372 = validateParameter(valid_602372, JString, required = false,
                                 default = nil)
  if valid_602372 != nil:
    section.add "X-Amz-Credential", valid_602372
  var valid_602373 = header.getOrDefault("X-Amz-Security-Token")
  valid_602373 = validateParameter(valid_602373, JString, required = false,
                                 default = nil)
  if valid_602373 != nil:
    section.add "X-Amz-Security-Token", valid_602373
  var valid_602374 = header.getOrDefault("X-Amz-Algorithm")
  valid_602374 = validateParameter(valid_602374, JString, required = false,
                                 default = nil)
  if valid_602374 != nil:
    section.add "X-Amz-Algorithm", valid_602374
  var valid_602375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602375 = validateParameter(valid_602375, JString, required = false,
                                 default = nil)
  if valid_602375 != nil:
    section.add "X-Amz-SignedHeaders", valid_602375
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602377: Call_TagResource_602366; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add tags to a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ## 
  let valid = call_602377.validator(path, query, header, formData, body)
  let scheme = call_602377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602377.url(scheme.get, call_602377.host, call_602377.base,
                         call_602377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602377, url, valid)

proc call*(call_602378: Call_TagResource_602366; body: JsonNode): Recallable =
  ## tagResource
  ## Add tags to a MediaConvert queue, preset, or job template. For information about tagging, see the User Guide at https://docs.aws.amazon.com/mediaconvert/latest/ug/tagging-resources.html
  ##   body: JObject (required)
  var body_602379 = newJObject()
  if body != nil:
    body_602379 = body
  result = call_602378.call(nil, nil, nil, nil, body_602379)

var tagResource* = Call_TagResource_602366(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediaconvert.amazonaws.com",
                                        route: "/2017-08-29/tags",
                                        validator: validate_TagResource_602367,
                                        base: "/", url: url_TagResource_602368,
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
