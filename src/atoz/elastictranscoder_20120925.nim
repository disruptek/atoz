
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Elastic Transcoder
## version: 2012-09-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Elastic Transcoder Service</fullname> <p>The AWS Elastic Transcoder Service.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/elastictranscoder/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "elastictranscoder.ap-northeast-1.amazonaws.com", "ap-southeast-1": "elastictranscoder.ap-southeast-1.amazonaws.com", "us-west-2": "elastictranscoder.us-west-2.amazonaws.com", "eu-west-2": "elastictranscoder.eu-west-2.amazonaws.com", "ap-northeast-3": "elastictranscoder.ap-northeast-3.amazonaws.com", "eu-central-1": "elastictranscoder.eu-central-1.amazonaws.com", "us-east-2": "elastictranscoder.us-east-2.amazonaws.com", "us-east-1": "elastictranscoder.us-east-1.amazonaws.com", "cn-northwest-1": "elastictranscoder.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "elastictranscoder.ap-south-1.amazonaws.com", "eu-north-1": "elastictranscoder.eu-north-1.amazonaws.com", "ap-northeast-2": "elastictranscoder.ap-northeast-2.amazonaws.com", "us-west-1": "elastictranscoder.us-west-1.amazonaws.com", "us-gov-east-1": "elastictranscoder.us-gov-east-1.amazonaws.com", "eu-west-3": "elastictranscoder.eu-west-3.amazonaws.com", "cn-north-1": "elastictranscoder.cn-north-1.amazonaws.com.cn", "sa-east-1": "elastictranscoder.sa-east-1.amazonaws.com", "eu-west-1": "elastictranscoder.eu-west-1.amazonaws.com", "us-gov-west-1": "elastictranscoder.us-gov-west-1.amazonaws.com", "ap-southeast-2": "elastictranscoder.ap-southeast-2.amazonaws.com", "ca-central-1": "elastictranscoder.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "elastictranscoder.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "elastictranscoder.ap-southeast-1.amazonaws.com",
      "us-west-2": "elastictranscoder.us-west-2.amazonaws.com",
      "eu-west-2": "elastictranscoder.eu-west-2.amazonaws.com",
      "ap-northeast-3": "elastictranscoder.ap-northeast-3.amazonaws.com",
      "eu-central-1": "elastictranscoder.eu-central-1.amazonaws.com",
      "us-east-2": "elastictranscoder.us-east-2.amazonaws.com",
      "us-east-1": "elastictranscoder.us-east-1.amazonaws.com",
      "cn-northwest-1": "elastictranscoder.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "elastictranscoder.ap-south-1.amazonaws.com",
      "eu-north-1": "elastictranscoder.eu-north-1.amazonaws.com",
      "ap-northeast-2": "elastictranscoder.ap-northeast-2.amazonaws.com",
      "us-west-1": "elastictranscoder.us-west-1.amazonaws.com",
      "us-gov-east-1": "elastictranscoder.us-gov-east-1.amazonaws.com",
      "eu-west-3": "elastictranscoder.eu-west-3.amazonaws.com",
      "cn-north-1": "elastictranscoder.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "elastictranscoder.sa-east-1.amazonaws.com",
      "eu-west-1": "elastictranscoder.eu-west-1.amazonaws.com",
      "us-gov-west-1": "elastictranscoder.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "elastictranscoder.ap-southeast-2.amazonaws.com",
      "ca-central-1": "elastictranscoder.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "elastictranscoder"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_ReadJob_599705 = ref object of OpenApiRestCall_599368
proc url_ReadJob_599707(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2012-09-25/jobs/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ReadJob_599706(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## The ReadJob operation returns detailed information about a job.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identifier of the job for which you want to get detailed information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_599833 = path.getOrDefault("Id")
  valid_599833 = validateParameter(valid_599833, JString, required = true,
                                 default = nil)
  if valid_599833 != nil:
    section.add "Id", valid_599833
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
  var valid_599834 = header.getOrDefault("X-Amz-Date")
  valid_599834 = validateParameter(valid_599834, JString, required = false,
                                 default = nil)
  if valid_599834 != nil:
    section.add "X-Amz-Date", valid_599834
  var valid_599835 = header.getOrDefault("X-Amz-Security-Token")
  valid_599835 = validateParameter(valid_599835, JString, required = false,
                                 default = nil)
  if valid_599835 != nil:
    section.add "X-Amz-Security-Token", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Content-Sha256", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Algorithm")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Algorithm", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-Signature")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-Signature", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-SignedHeaders", valid_599839
  var valid_599840 = header.getOrDefault("X-Amz-Credential")
  valid_599840 = validateParameter(valid_599840, JString, required = false,
                                 default = nil)
  if valid_599840 != nil:
    section.add "X-Amz-Credential", valid_599840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599863: Call_ReadJob_599705; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The ReadJob operation returns detailed information about a job.
  ## 
  let valid = call_599863.validator(path, query, header, formData, body)
  let scheme = call_599863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599863.url(scheme.get, call_599863.host, call_599863.base,
                         call_599863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599863, url, valid)

proc call*(call_599934: Call_ReadJob_599705; Id: string): Recallable =
  ## readJob
  ## The ReadJob operation returns detailed information about a job.
  ##   Id: string (required)
  ##     : The identifier of the job for which you want to get detailed information.
  var path_599935 = newJObject()
  add(path_599935, "Id", newJString(Id))
  result = call_599934.call(path_599935, nil, nil, nil, nil)

var readJob* = Call_ReadJob_599705(name: "readJob", meth: HttpMethod.HttpGet,
                                host: "elastictranscoder.amazonaws.com",
                                route: "/2012-09-25/jobs/{Id}",
                                validator: validate_ReadJob_599706, base: "/",
                                url: url_ReadJob_599707,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelJob_599975 = ref object of OpenApiRestCall_599368
proc url_CancelJob_599977(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2012-09-25/jobs/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CancelJob_599976(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>The CancelJob operation cancels an unfinished job.</p> <note> <p>You can only cancel a job that has a status of <code>Submitted</code>. To prevent a pipeline from starting to process a job while you're getting the job identifier, use <a>UpdatePipelineStatus</a> to temporarily pause the pipeline.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : <p>The identifier of the job that you want to cancel.</p> <p>To get a list of the jobs (including their <code>jobId</code>) that have a status of <code>Submitted</code>, use the <a>ListJobsByStatus</a> API action.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_599978 = path.getOrDefault("Id")
  valid_599978 = validateParameter(valid_599978, JString, required = true,
                                 default = nil)
  if valid_599978 != nil:
    section.add "Id", valid_599978
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
  var valid_599979 = header.getOrDefault("X-Amz-Date")
  valid_599979 = validateParameter(valid_599979, JString, required = false,
                                 default = nil)
  if valid_599979 != nil:
    section.add "X-Amz-Date", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Security-Token")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Security-Token", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Content-Sha256", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Algorithm")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Algorithm", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Signature")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Signature", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-SignedHeaders", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Credential")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Credential", valid_599985
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599986: Call_CancelJob_599975; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The CancelJob operation cancels an unfinished job.</p> <note> <p>You can only cancel a job that has a status of <code>Submitted</code>. To prevent a pipeline from starting to process a job while you're getting the job identifier, use <a>UpdatePipelineStatus</a> to temporarily pause the pipeline.</p> </note>
  ## 
  let valid = call_599986.validator(path, query, header, formData, body)
  let scheme = call_599986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599986.url(scheme.get, call_599986.host, call_599986.base,
                         call_599986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599986, url, valid)

proc call*(call_599987: Call_CancelJob_599975; Id: string): Recallable =
  ## cancelJob
  ## <p>The CancelJob operation cancels an unfinished job.</p> <note> <p>You can only cancel a job that has a status of <code>Submitted</code>. To prevent a pipeline from starting to process a job while you're getting the job identifier, use <a>UpdatePipelineStatus</a> to temporarily pause the pipeline.</p> </note>
  ##   Id: string (required)
  ##     : <p>The identifier of the job that you want to cancel.</p> <p>To get a list of the jobs (including their <code>jobId</code>) that have a status of <code>Submitted</code>, use the <a>ListJobsByStatus</a> API action.</p>
  var path_599988 = newJObject()
  add(path_599988, "Id", newJString(Id))
  result = call_599987.call(path_599988, nil, nil, nil, nil)

var cancelJob* = Call_CancelJob_599975(name: "cancelJob",
                                    meth: HttpMethod.HttpDelete,
                                    host: "elastictranscoder.amazonaws.com",
                                    route: "/2012-09-25/jobs/{Id}",
                                    validator: validate_CancelJob_599976,
                                    base: "/", url: url_CancelJob_599977,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_599989 = ref object of OpenApiRestCall_599368
proc url_CreateJob_599991(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateJob_599990(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>When you create a job, Elastic Transcoder returns JSON data that includes the values that you specified plus information about the job that is created.</p> <p>If you have specified more than one output for your jobs (for example, one output for the Kindle Fire and another output for the Apple iPhone 4s), you currently must use the Elastic Transcoder API to list the jobs (as opposed to the AWS Console).</p>
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
  var valid_599992 = header.getOrDefault("X-Amz-Date")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Date", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-Security-Token")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Security-Token", valid_599993
  var valid_599994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599994 = validateParameter(valid_599994, JString, required = false,
                                 default = nil)
  if valid_599994 != nil:
    section.add "X-Amz-Content-Sha256", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Algorithm")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Algorithm", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Signature")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Signature", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-SignedHeaders", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-Credential")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-Credential", valid_599998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600000: Call_CreateJob_599989; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>When you create a job, Elastic Transcoder returns JSON data that includes the values that you specified plus information about the job that is created.</p> <p>If you have specified more than one output for your jobs (for example, one output for the Kindle Fire and another output for the Apple iPhone 4s), you currently must use the Elastic Transcoder API to list the jobs (as opposed to the AWS Console).</p>
  ## 
  let valid = call_600000.validator(path, query, header, formData, body)
  let scheme = call_600000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600000.url(scheme.get, call_600000.host, call_600000.base,
                         call_600000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600000, url, valid)

proc call*(call_600001: Call_CreateJob_599989; body: JsonNode): Recallable =
  ## createJob
  ## <p>When you create a job, Elastic Transcoder returns JSON data that includes the values that you specified plus information about the job that is created.</p> <p>If you have specified more than one output for your jobs (for example, one output for the Kindle Fire and another output for the Apple iPhone 4s), you currently must use the Elastic Transcoder API to list the jobs (as opposed to the AWS Console).</p>
  ##   body: JObject (required)
  var body_600002 = newJObject()
  if body != nil:
    body_600002 = body
  result = call_600001.call(nil, nil, nil, nil, body_600002)

var createJob* = Call_CreateJob_599989(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "elastictranscoder.amazonaws.com",
                                    route: "/2012-09-25/jobs",
                                    validator: validate_CreateJob_599990,
                                    base: "/", url: url_CreateJob_599991,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePipeline_600018 = ref object of OpenApiRestCall_599368
proc url_CreatePipeline_600020(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePipeline_600019(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## The CreatePipeline operation creates a pipeline with settings that you specify.
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
  var valid_600021 = header.getOrDefault("X-Amz-Date")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "X-Amz-Date", valid_600021
  var valid_600022 = header.getOrDefault("X-Amz-Security-Token")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Security-Token", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Content-Sha256", valid_600023
  var valid_600024 = header.getOrDefault("X-Amz-Algorithm")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "X-Amz-Algorithm", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Signature")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Signature", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-SignedHeaders", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Credential")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Credential", valid_600027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600029: Call_CreatePipeline_600018; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The CreatePipeline operation creates a pipeline with settings that you specify.
  ## 
  let valid = call_600029.validator(path, query, header, formData, body)
  let scheme = call_600029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600029.url(scheme.get, call_600029.host, call_600029.base,
                         call_600029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600029, url, valid)

proc call*(call_600030: Call_CreatePipeline_600018; body: JsonNode): Recallable =
  ## createPipeline
  ## The CreatePipeline operation creates a pipeline with settings that you specify.
  ##   body: JObject (required)
  var body_600031 = newJObject()
  if body != nil:
    body_600031 = body
  result = call_600030.call(nil, nil, nil, nil, body_600031)

var createPipeline* = Call_CreatePipeline_600018(name: "createPipeline",
    meth: HttpMethod.HttpPost, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines", validator: validate_CreatePipeline_600019,
    base: "/", url: url_CreatePipeline_600020, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelines_600003 = ref object of OpenApiRestCall_599368
proc url_ListPipelines_600005(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPipelines_600004(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## The ListPipelines operation gets a list of the pipelines associated with the current AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageToken: JString
  ##            : When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  ##   Ascending: JString
  ##            : To list pipelines in chronological order by the date and time that they were created, enter <code>true</code>. To list pipelines in reverse chronological order, enter <code>false</code>.
  section = newJObject()
  var valid_600006 = query.getOrDefault("PageToken")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "PageToken", valid_600006
  var valid_600007 = query.getOrDefault("Ascending")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "Ascending", valid_600007
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
  var valid_600008 = header.getOrDefault("X-Amz-Date")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Date", valid_600008
  var valid_600009 = header.getOrDefault("X-Amz-Security-Token")
  valid_600009 = validateParameter(valid_600009, JString, required = false,
                                 default = nil)
  if valid_600009 != nil:
    section.add "X-Amz-Security-Token", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Content-Sha256", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Algorithm")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Algorithm", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-Signature")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Signature", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-SignedHeaders", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-Credential")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Credential", valid_600014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600015: Call_ListPipelines_600003; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The ListPipelines operation gets a list of the pipelines associated with the current AWS account.
  ## 
  let valid = call_600015.validator(path, query, header, formData, body)
  let scheme = call_600015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600015.url(scheme.get, call_600015.host, call_600015.base,
                         call_600015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600015, url, valid)

proc call*(call_600016: Call_ListPipelines_600003; PageToken: string = "";
          Ascending: string = ""): Recallable =
  ## listPipelines
  ## The ListPipelines operation gets a list of the pipelines associated with the current AWS account.
  ##   PageToken: string
  ##            : When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  ##   Ascending: string
  ##            : To list pipelines in chronological order by the date and time that they were created, enter <code>true</code>. To list pipelines in reverse chronological order, enter <code>false</code>.
  var query_600017 = newJObject()
  add(query_600017, "PageToken", newJString(PageToken))
  add(query_600017, "Ascending", newJString(Ascending))
  result = call_600016.call(nil, query_600017, nil, nil, nil)

var listPipelines* = Call_ListPipelines_600003(name: "listPipelines",
    meth: HttpMethod.HttpGet, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines", validator: validate_ListPipelines_600004,
    base: "/", url: url_ListPipelines_600005, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePreset_600047 = ref object of OpenApiRestCall_599368
proc url_CreatePreset_600049(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePreset_600048(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>The CreatePreset operation creates a preset with settings that you specify.</p> <important> <p>Elastic Transcoder checks the CreatePreset settings to ensure that they meet Elastic Transcoder requirements and to determine whether they comply with H.264 standards. If your settings are not valid for Elastic Transcoder, Elastic Transcoder returns an HTTP 400 response (<code>ValidationException</code>) and does not create the preset. If the settings are valid for Elastic Transcoder but aren't strictly compliant with the H.264 standard, Elastic Transcoder creates the preset and returns a warning message in the response. This helps you determine whether your settings comply with the H.264 standard while giving you greater flexibility with respect to the video that Elastic Transcoder produces.</p> </important> <p>Elastic Transcoder uses the H.264 video-compression format. For more information, see the International Telecommunication Union publication <i>Recommendation ITU-T H.264: Advanced video coding for generic audiovisual services</i>.</p>
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
  var valid_600050 = header.getOrDefault("X-Amz-Date")
  valid_600050 = validateParameter(valid_600050, JString, required = false,
                                 default = nil)
  if valid_600050 != nil:
    section.add "X-Amz-Date", valid_600050
  var valid_600051 = header.getOrDefault("X-Amz-Security-Token")
  valid_600051 = validateParameter(valid_600051, JString, required = false,
                                 default = nil)
  if valid_600051 != nil:
    section.add "X-Amz-Security-Token", valid_600051
  var valid_600052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Content-Sha256", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-Algorithm")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Algorithm", valid_600053
  var valid_600054 = header.getOrDefault("X-Amz-Signature")
  valid_600054 = validateParameter(valid_600054, JString, required = false,
                                 default = nil)
  if valid_600054 != nil:
    section.add "X-Amz-Signature", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-SignedHeaders", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Credential")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Credential", valid_600056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600058: Call_CreatePreset_600047; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The CreatePreset operation creates a preset with settings that you specify.</p> <important> <p>Elastic Transcoder checks the CreatePreset settings to ensure that they meet Elastic Transcoder requirements and to determine whether they comply with H.264 standards. If your settings are not valid for Elastic Transcoder, Elastic Transcoder returns an HTTP 400 response (<code>ValidationException</code>) and does not create the preset. If the settings are valid for Elastic Transcoder but aren't strictly compliant with the H.264 standard, Elastic Transcoder creates the preset and returns a warning message in the response. This helps you determine whether your settings comply with the H.264 standard while giving you greater flexibility with respect to the video that Elastic Transcoder produces.</p> </important> <p>Elastic Transcoder uses the H.264 video-compression format. For more information, see the International Telecommunication Union publication <i>Recommendation ITU-T H.264: Advanced video coding for generic audiovisual services</i>.</p>
  ## 
  let valid = call_600058.validator(path, query, header, formData, body)
  let scheme = call_600058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600058.url(scheme.get, call_600058.host, call_600058.base,
                         call_600058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600058, url, valid)

proc call*(call_600059: Call_CreatePreset_600047; body: JsonNode): Recallable =
  ## createPreset
  ## <p>The CreatePreset operation creates a preset with settings that you specify.</p> <important> <p>Elastic Transcoder checks the CreatePreset settings to ensure that they meet Elastic Transcoder requirements and to determine whether they comply with H.264 standards. If your settings are not valid for Elastic Transcoder, Elastic Transcoder returns an HTTP 400 response (<code>ValidationException</code>) and does not create the preset. If the settings are valid for Elastic Transcoder but aren't strictly compliant with the H.264 standard, Elastic Transcoder creates the preset and returns a warning message in the response. This helps you determine whether your settings comply with the H.264 standard while giving you greater flexibility with respect to the video that Elastic Transcoder produces.</p> </important> <p>Elastic Transcoder uses the H.264 video-compression format. For more information, see the International Telecommunication Union publication <i>Recommendation ITU-T H.264: Advanced video coding for generic audiovisual services</i>.</p>
  ##   body: JObject (required)
  var body_600060 = newJObject()
  if body != nil:
    body_600060 = body
  result = call_600059.call(nil, nil, nil, nil, body_600060)

var createPreset* = Call_CreatePreset_600047(name: "createPreset",
    meth: HttpMethod.HttpPost, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/presets", validator: validate_CreatePreset_600048,
    base: "/", url: url_CreatePreset_600049, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPresets_600032 = ref object of OpenApiRestCall_599368
proc url_ListPresets_600034(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPresets_600033(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## The ListPresets operation gets a list of the default presets included with Elastic Transcoder and the presets that you've added in an AWS region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageToken: JString
  ##            : When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  ##   Ascending: JString
  ##            : To list presets in chronological order by the date and time that they were created, enter <code>true</code>. To list presets in reverse chronological order, enter <code>false</code>.
  section = newJObject()
  var valid_600035 = query.getOrDefault("PageToken")
  valid_600035 = validateParameter(valid_600035, JString, required = false,
                                 default = nil)
  if valid_600035 != nil:
    section.add "PageToken", valid_600035
  var valid_600036 = query.getOrDefault("Ascending")
  valid_600036 = validateParameter(valid_600036, JString, required = false,
                                 default = nil)
  if valid_600036 != nil:
    section.add "Ascending", valid_600036
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
  var valid_600037 = header.getOrDefault("X-Amz-Date")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Date", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Security-Token")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Security-Token", valid_600038
  var valid_600039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-Content-Sha256", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Algorithm")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Algorithm", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Signature")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Signature", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-SignedHeaders", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-Credential")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Credential", valid_600043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600044: Call_ListPresets_600032; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The ListPresets operation gets a list of the default presets included with Elastic Transcoder and the presets that you've added in an AWS region.
  ## 
  let valid = call_600044.validator(path, query, header, formData, body)
  let scheme = call_600044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600044.url(scheme.get, call_600044.host, call_600044.base,
                         call_600044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600044, url, valid)

proc call*(call_600045: Call_ListPresets_600032; PageToken: string = "";
          Ascending: string = ""): Recallable =
  ## listPresets
  ## The ListPresets operation gets a list of the default presets included with Elastic Transcoder and the presets that you've added in an AWS region.
  ##   PageToken: string
  ##            : When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  ##   Ascending: string
  ##            : To list presets in chronological order by the date and time that they were created, enter <code>true</code>. To list presets in reverse chronological order, enter <code>false</code>.
  var query_600046 = newJObject()
  add(query_600046, "PageToken", newJString(PageToken))
  add(query_600046, "Ascending", newJString(Ascending))
  result = call_600045.call(nil, query_600046, nil, nil, nil)

var listPresets* = Call_ListPresets_600032(name: "listPresets",
                                        meth: HttpMethod.HttpGet, host: "elastictranscoder.amazonaws.com",
                                        route: "/2012-09-25/presets",
                                        validator: validate_ListPresets_600033,
                                        base: "/", url: url_ListPresets_600034,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipeline_600075 = ref object of OpenApiRestCall_599368
proc url_UpdatePipeline_600077(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2012-09-25/pipelines/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdatePipeline_600076(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p> Use the <code>UpdatePipeline</code> operation to update settings for a pipeline.</p> <important> <p>When you change pipeline settings, your changes take effect immediately. Jobs that you have already submitted and that Elastic Transcoder has not started to process are affected in addition to jobs that you submit after you change settings. </p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the pipeline that you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_600078 = path.getOrDefault("Id")
  valid_600078 = validateParameter(valid_600078, JString, required = true,
                                 default = nil)
  if valid_600078 != nil:
    section.add "Id", valid_600078
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
  var valid_600079 = header.getOrDefault("X-Amz-Date")
  valid_600079 = validateParameter(valid_600079, JString, required = false,
                                 default = nil)
  if valid_600079 != nil:
    section.add "X-Amz-Date", valid_600079
  var valid_600080 = header.getOrDefault("X-Amz-Security-Token")
  valid_600080 = validateParameter(valid_600080, JString, required = false,
                                 default = nil)
  if valid_600080 != nil:
    section.add "X-Amz-Security-Token", valid_600080
  var valid_600081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600081 = validateParameter(valid_600081, JString, required = false,
                                 default = nil)
  if valid_600081 != nil:
    section.add "X-Amz-Content-Sha256", valid_600081
  var valid_600082 = header.getOrDefault("X-Amz-Algorithm")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Algorithm", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-Signature")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Signature", valid_600083
  var valid_600084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600084 = validateParameter(valid_600084, JString, required = false,
                                 default = nil)
  if valid_600084 != nil:
    section.add "X-Amz-SignedHeaders", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Credential")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Credential", valid_600085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600087: Call_UpdatePipeline_600075; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Use the <code>UpdatePipeline</code> operation to update settings for a pipeline.</p> <important> <p>When you change pipeline settings, your changes take effect immediately. Jobs that you have already submitted and that Elastic Transcoder has not started to process are affected in addition to jobs that you submit after you change settings. </p> </important>
  ## 
  let valid = call_600087.validator(path, query, header, formData, body)
  let scheme = call_600087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600087.url(scheme.get, call_600087.host, call_600087.base,
                         call_600087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600087, url, valid)

proc call*(call_600088: Call_UpdatePipeline_600075; Id: string; body: JsonNode): Recallable =
  ## updatePipeline
  ## <p> Use the <code>UpdatePipeline</code> operation to update settings for a pipeline.</p> <important> <p>When you change pipeline settings, your changes take effect immediately. Jobs that you have already submitted and that Elastic Transcoder has not started to process are affected in addition to jobs that you submit after you change settings. </p> </important>
  ##   Id: string (required)
  ##     : The ID of the pipeline that you want to update.
  ##   body: JObject (required)
  var path_600089 = newJObject()
  var body_600090 = newJObject()
  add(path_600089, "Id", newJString(Id))
  if body != nil:
    body_600090 = body
  result = call_600088.call(path_600089, nil, nil, nil, body_600090)

var updatePipeline* = Call_UpdatePipeline_600075(name: "updatePipeline",
    meth: HttpMethod.HttpPut, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines/{Id}", validator: validate_UpdatePipeline_600076,
    base: "/", url: url_UpdatePipeline_600077, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReadPipeline_600061 = ref object of OpenApiRestCall_599368
proc url_ReadPipeline_600063(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2012-09-25/pipelines/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ReadPipeline_600062(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## The ReadPipeline operation gets detailed information about a pipeline.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identifier of the pipeline to read.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_600064 = path.getOrDefault("Id")
  valid_600064 = validateParameter(valid_600064, JString, required = true,
                                 default = nil)
  if valid_600064 != nil:
    section.add "Id", valid_600064
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
  var valid_600065 = header.getOrDefault("X-Amz-Date")
  valid_600065 = validateParameter(valid_600065, JString, required = false,
                                 default = nil)
  if valid_600065 != nil:
    section.add "X-Amz-Date", valid_600065
  var valid_600066 = header.getOrDefault("X-Amz-Security-Token")
  valid_600066 = validateParameter(valid_600066, JString, required = false,
                                 default = nil)
  if valid_600066 != nil:
    section.add "X-Amz-Security-Token", valid_600066
  var valid_600067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Content-Sha256", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Algorithm")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Algorithm", valid_600068
  var valid_600069 = header.getOrDefault("X-Amz-Signature")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "X-Amz-Signature", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-SignedHeaders", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Credential")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Credential", valid_600071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600072: Call_ReadPipeline_600061; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The ReadPipeline operation gets detailed information about a pipeline.
  ## 
  let valid = call_600072.validator(path, query, header, formData, body)
  let scheme = call_600072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600072.url(scheme.get, call_600072.host, call_600072.base,
                         call_600072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600072, url, valid)

proc call*(call_600073: Call_ReadPipeline_600061; Id: string): Recallable =
  ## readPipeline
  ## The ReadPipeline operation gets detailed information about a pipeline.
  ##   Id: string (required)
  ##     : The identifier of the pipeline to read.
  var path_600074 = newJObject()
  add(path_600074, "Id", newJString(Id))
  result = call_600073.call(path_600074, nil, nil, nil, nil)

var readPipeline* = Call_ReadPipeline_600061(name: "readPipeline",
    meth: HttpMethod.HttpGet, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines/{Id}", validator: validate_ReadPipeline_600062,
    base: "/", url: url_ReadPipeline_600063, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePipeline_600091 = ref object of OpenApiRestCall_599368
proc url_DeletePipeline_600093(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2012-09-25/pipelines/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeletePipeline_600092(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>The DeletePipeline operation removes a pipeline.</p> <p> You can only delete a pipeline that has never been used or that is not currently in use (doesn't contain any active jobs). If the pipeline is currently in use, <code>DeletePipeline</code> returns an error. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identifier of the pipeline that you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_600094 = path.getOrDefault("Id")
  valid_600094 = validateParameter(valid_600094, JString, required = true,
                                 default = nil)
  if valid_600094 != nil:
    section.add "Id", valid_600094
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
  var valid_600095 = header.getOrDefault("X-Amz-Date")
  valid_600095 = validateParameter(valid_600095, JString, required = false,
                                 default = nil)
  if valid_600095 != nil:
    section.add "X-Amz-Date", valid_600095
  var valid_600096 = header.getOrDefault("X-Amz-Security-Token")
  valid_600096 = validateParameter(valid_600096, JString, required = false,
                                 default = nil)
  if valid_600096 != nil:
    section.add "X-Amz-Security-Token", valid_600096
  var valid_600097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-Content-Sha256", valid_600097
  var valid_600098 = header.getOrDefault("X-Amz-Algorithm")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Algorithm", valid_600098
  var valid_600099 = header.getOrDefault("X-Amz-Signature")
  valid_600099 = validateParameter(valid_600099, JString, required = false,
                                 default = nil)
  if valid_600099 != nil:
    section.add "X-Amz-Signature", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-SignedHeaders", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-Credential")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Credential", valid_600101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600102: Call_DeletePipeline_600091; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The DeletePipeline operation removes a pipeline.</p> <p> You can only delete a pipeline that has never been used or that is not currently in use (doesn't contain any active jobs). If the pipeline is currently in use, <code>DeletePipeline</code> returns an error. </p>
  ## 
  let valid = call_600102.validator(path, query, header, formData, body)
  let scheme = call_600102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600102.url(scheme.get, call_600102.host, call_600102.base,
                         call_600102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600102, url, valid)

proc call*(call_600103: Call_DeletePipeline_600091; Id: string): Recallable =
  ## deletePipeline
  ## <p>The DeletePipeline operation removes a pipeline.</p> <p> You can only delete a pipeline that has never been used or that is not currently in use (doesn't contain any active jobs). If the pipeline is currently in use, <code>DeletePipeline</code> returns an error. </p>
  ##   Id: string (required)
  ##     : The identifier of the pipeline that you want to delete.
  var path_600104 = newJObject()
  add(path_600104, "Id", newJString(Id))
  result = call_600103.call(path_600104, nil, nil, nil, nil)

var deletePipeline* = Call_DeletePipeline_600091(name: "deletePipeline",
    meth: HttpMethod.HttpDelete, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines/{Id}", validator: validate_DeletePipeline_600092,
    base: "/", url: url_DeletePipeline_600093, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReadPreset_600105 = ref object of OpenApiRestCall_599368
proc url_ReadPreset_600107(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2012-09-25/presets/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ReadPreset_600106(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## The ReadPreset operation gets detailed information about a preset.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identifier of the preset for which you want to get detailed information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_600108 = path.getOrDefault("Id")
  valid_600108 = validateParameter(valid_600108, JString, required = true,
                                 default = nil)
  if valid_600108 != nil:
    section.add "Id", valid_600108
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
  var valid_600109 = header.getOrDefault("X-Amz-Date")
  valid_600109 = validateParameter(valid_600109, JString, required = false,
                                 default = nil)
  if valid_600109 != nil:
    section.add "X-Amz-Date", valid_600109
  var valid_600110 = header.getOrDefault("X-Amz-Security-Token")
  valid_600110 = validateParameter(valid_600110, JString, required = false,
                                 default = nil)
  if valid_600110 != nil:
    section.add "X-Amz-Security-Token", valid_600110
  var valid_600111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600111 = validateParameter(valid_600111, JString, required = false,
                                 default = nil)
  if valid_600111 != nil:
    section.add "X-Amz-Content-Sha256", valid_600111
  var valid_600112 = header.getOrDefault("X-Amz-Algorithm")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Algorithm", valid_600112
  var valid_600113 = header.getOrDefault("X-Amz-Signature")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-Signature", valid_600113
  var valid_600114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600114 = validateParameter(valid_600114, JString, required = false,
                                 default = nil)
  if valid_600114 != nil:
    section.add "X-Amz-SignedHeaders", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Credential")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Credential", valid_600115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600116: Call_ReadPreset_600105; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The ReadPreset operation gets detailed information about a preset.
  ## 
  let valid = call_600116.validator(path, query, header, formData, body)
  let scheme = call_600116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600116.url(scheme.get, call_600116.host, call_600116.base,
                         call_600116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600116, url, valid)

proc call*(call_600117: Call_ReadPreset_600105; Id: string): Recallable =
  ## readPreset
  ## The ReadPreset operation gets detailed information about a preset.
  ##   Id: string (required)
  ##     : The identifier of the preset for which you want to get detailed information.
  var path_600118 = newJObject()
  add(path_600118, "Id", newJString(Id))
  result = call_600117.call(path_600118, nil, nil, nil, nil)

var readPreset* = Call_ReadPreset_600105(name: "readPreset",
                                      meth: HttpMethod.HttpGet,
                                      host: "elastictranscoder.amazonaws.com",
                                      route: "/2012-09-25/presets/{Id}",
                                      validator: validate_ReadPreset_600106,
                                      base: "/", url: url_ReadPreset_600107,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePreset_600119 = ref object of OpenApiRestCall_599368
proc url_DeletePreset_600121(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2012-09-25/presets/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeletePreset_600120(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>The DeletePreset operation removes a preset that you've added in an AWS region.</p> <note> <p>You can't delete the default presets that are included with Elastic Transcoder.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identifier of the preset for which you want to get detailed information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_600122 = path.getOrDefault("Id")
  valid_600122 = validateParameter(valid_600122, JString, required = true,
                                 default = nil)
  if valid_600122 != nil:
    section.add "Id", valid_600122
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
  var valid_600123 = header.getOrDefault("X-Amz-Date")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "X-Amz-Date", valid_600123
  var valid_600124 = header.getOrDefault("X-Amz-Security-Token")
  valid_600124 = validateParameter(valid_600124, JString, required = false,
                                 default = nil)
  if valid_600124 != nil:
    section.add "X-Amz-Security-Token", valid_600124
  var valid_600125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "X-Amz-Content-Sha256", valid_600125
  var valid_600126 = header.getOrDefault("X-Amz-Algorithm")
  valid_600126 = validateParameter(valid_600126, JString, required = false,
                                 default = nil)
  if valid_600126 != nil:
    section.add "X-Amz-Algorithm", valid_600126
  var valid_600127 = header.getOrDefault("X-Amz-Signature")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Signature", valid_600127
  var valid_600128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-SignedHeaders", valid_600128
  var valid_600129 = header.getOrDefault("X-Amz-Credential")
  valid_600129 = validateParameter(valid_600129, JString, required = false,
                                 default = nil)
  if valid_600129 != nil:
    section.add "X-Amz-Credential", valid_600129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600130: Call_DeletePreset_600119; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The DeletePreset operation removes a preset that you've added in an AWS region.</p> <note> <p>You can't delete the default presets that are included with Elastic Transcoder.</p> </note>
  ## 
  let valid = call_600130.validator(path, query, header, formData, body)
  let scheme = call_600130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600130.url(scheme.get, call_600130.host, call_600130.base,
                         call_600130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600130, url, valid)

proc call*(call_600131: Call_DeletePreset_600119; Id: string): Recallable =
  ## deletePreset
  ## <p>The DeletePreset operation removes a preset that you've added in an AWS region.</p> <note> <p>You can't delete the default presets that are included with Elastic Transcoder.</p> </note>
  ##   Id: string (required)
  ##     : The identifier of the preset for which you want to get detailed information.
  var path_600132 = newJObject()
  add(path_600132, "Id", newJString(Id))
  result = call_600131.call(path_600132, nil, nil, nil, nil)

var deletePreset* = Call_DeletePreset_600119(name: "deletePreset",
    meth: HttpMethod.HttpDelete, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/presets/{Id}", validator: validate_DeletePreset_600120,
    base: "/", url: url_DeletePreset_600121, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobsByPipeline_600133 = ref object of OpenApiRestCall_599368
proc url_ListJobsByPipeline_600135(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "PipelineId" in path, "`PipelineId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2012-09-25/jobsByPipeline/"),
               (kind: VariableSegment, value: "PipelineId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListJobsByPipeline_600134(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>The ListJobsByPipeline operation gets a list of the jobs currently in a pipeline.</p> <p>Elastic Transcoder returns all of the jobs currently in the specified pipeline. The response body contains one element for each job that satisfies the search criteria.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   PipelineId: JString (required)
  ##             : The ID of the pipeline for which you want to get job information.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `PipelineId` field"
  var valid_600136 = path.getOrDefault("PipelineId")
  valid_600136 = validateParameter(valid_600136, JString, required = true,
                                 default = nil)
  if valid_600136 != nil:
    section.add "PipelineId", valid_600136
  result.add "path", section
  ## parameters in `query` object:
  ##   PageToken: JString
  ##            :  When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  ##   Ascending: JString
  ##            :  To list jobs in chronological order by the date and time that they were submitted, enter <code>true</code>. To list jobs in reverse chronological order, enter <code>false</code>. 
  section = newJObject()
  var valid_600137 = query.getOrDefault("PageToken")
  valid_600137 = validateParameter(valid_600137, JString, required = false,
                                 default = nil)
  if valid_600137 != nil:
    section.add "PageToken", valid_600137
  var valid_600138 = query.getOrDefault("Ascending")
  valid_600138 = validateParameter(valid_600138, JString, required = false,
                                 default = nil)
  if valid_600138 != nil:
    section.add "Ascending", valid_600138
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
  var valid_600139 = header.getOrDefault("X-Amz-Date")
  valid_600139 = validateParameter(valid_600139, JString, required = false,
                                 default = nil)
  if valid_600139 != nil:
    section.add "X-Amz-Date", valid_600139
  var valid_600140 = header.getOrDefault("X-Amz-Security-Token")
  valid_600140 = validateParameter(valid_600140, JString, required = false,
                                 default = nil)
  if valid_600140 != nil:
    section.add "X-Amz-Security-Token", valid_600140
  var valid_600141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "X-Amz-Content-Sha256", valid_600141
  var valid_600142 = header.getOrDefault("X-Amz-Algorithm")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Algorithm", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Signature")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Signature", valid_600143
  var valid_600144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600144 = validateParameter(valid_600144, JString, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "X-Amz-SignedHeaders", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-Credential")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Credential", valid_600145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600146: Call_ListJobsByPipeline_600133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The ListJobsByPipeline operation gets a list of the jobs currently in a pipeline.</p> <p>Elastic Transcoder returns all of the jobs currently in the specified pipeline. The response body contains one element for each job that satisfies the search criteria.</p>
  ## 
  let valid = call_600146.validator(path, query, header, formData, body)
  let scheme = call_600146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600146.url(scheme.get, call_600146.host, call_600146.base,
                         call_600146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600146, url, valid)

proc call*(call_600147: Call_ListJobsByPipeline_600133; PipelineId: string;
          PageToken: string = ""; Ascending: string = ""): Recallable =
  ## listJobsByPipeline
  ## <p>The ListJobsByPipeline operation gets a list of the jobs currently in a pipeline.</p> <p>Elastic Transcoder returns all of the jobs currently in the specified pipeline. The response body contains one element for each job that satisfies the search criteria.</p>
  ##   PageToken: string
  ##            :  When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  ##   PipelineId: string (required)
  ##             : The ID of the pipeline for which you want to get job information.
  ##   Ascending: string
  ##            :  To list jobs in chronological order by the date and time that they were submitted, enter <code>true</code>. To list jobs in reverse chronological order, enter <code>false</code>. 
  var path_600148 = newJObject()
  var query_600149 = newJObject()
  add(query_600149, "PageToken", newJString(PageToken))
  add(path_600148, "PipelineId", newJString(PipelineId))
  add(query_600149, "Ascending", newJString(Ascending))
  result = call_600147.call(path_600148, query_600149, nil, nil, nil)

var listJobsByPipeline* = Call_ListJobsByPipeline_600133(
    name: "listJobsByPipeline", meth: HttpMethod.HttpGet,
    host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/jobsByPipeline/{PipelineId}",
    validator: validate_ListJobsByPipeline_600134, base: "/",
    url: url_ListJobsByPipeline_600135, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobsByStatus_600150 = ref object of OpenApiRestCall_599368
proc url_ListJobsByStatus_600152(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Status" in path, "`Status` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2012-09-25/jobsByStatus/"),
               (kind: VariableSegment, value: "Status")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListJobsByStatus_600151(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## The ListJobsByStatus operation gets a list of jobs that have a specified status. The response body contains one element for each job that satisfies the search criteria.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Status: JString (required)
  ##         : To get information about all of the jobs associated with the current AWS account that have a given status, specify the following status: <code>Submitted</code>, <code>Progressing</code>, <code>Complete</code>, <code>Canceled</code>, or <code>Error</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Status` field"
  var valid_600153 = path.getOrDefault("Status")
  valid_600153 = validateParameter(valid_600153, JString, required = true,
                                 default = nil)
  if valid_600153 != nil:
    section.add "Status", valid_600153
  result.add "path", section
  ## parameters in `query` object:
  ##   PageToken: JString
  ##            :  When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  ##   Ascending: JString
  ##            :  To list jobs in chronological order by the date and time that they were submitted, enter <code>true</code>. To list jobs in reverse chronological order, enter <code>false</code>. 
  section = newJObject()
  var valid_600154 = query.getOrDefault("PageToken")
  valid_600154 = validateParameter(valid_600154, JString, required = false,
                                 default = nil)
  if valid_600154 != nil:
    section.add "PageToken", valid_600154
  var valid_600155 = query.getOrDefault("Ascending")
  valid_600155 = validateParameter(valid_600155, JString, required = false,
                                 default = nil)
  if valid_600155 != nil:
    section.add "Ascending", valid_600155
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
  var valid_600156 = header.getOrDefault("X-Amz-Date")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "X-Amz-Date", valid_600156
  var valid_600157 = header.getOrDefault("X-Amz-Security-Token")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Security-Token", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Content-Sha256", valid_600158
  var valid_600159 = header.getOrDefault("X-Amz-Algorithm")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "X-Amz-Algorithm", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-Signature")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Signature", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-SignedHeaders", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-Credential")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-Credential", valid_600162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600163: Call_ListJobsByStatus_600150; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The ListJobsByStatus operation gets a list of jobs that have a specified status. The response body contains one element for each job that satisfies the search criteria.
  ## 
  let valid = call_600163.validator(path, query, header, formData, body)
  let scheme = call_600163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600163.url(scheme.get, call_600163.host, call_600163.base,
                         call_600163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600163, url, valid)

proc call*(call_600164: Call_ListJobsByStatus_600150; Status: string;
          PageToken: string = ""; Ascending: string = ""): Recallable =
  ## listJobsByStatus
  ## The ListJobsByStatus operation gets a list of jobs that have a specified status. The response body contains one element for each job that satisfies the search criteria.
  ##   Status: string (required)
  ##         : To get information about all of the jobs associated with the current AWS account that have a given status, specify the following status: <code>Submitted</code>, <code>Progressing</code>, <code>Complete</code>, <code>Canceled</code>, or <code>Error</code>.
  ##   PageToken: string
  ##            :  When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  ##   Ascending: string
  ##            :  To list jobs in chronological order by the date and time that they were submitted, enter <code>true</code>. To list jobs in reverse chronological order, enter <code>false</code>. 
  var path_600165 = newJObject()
  var query_600166 = newJObject()
  add(path_600165, "Status", newJString(Status))
  add(query_600166, "PageToken", newJString(PageToken))
  add(query_600166, "Ascending", newJString(Ascending))
  result = call_600164.call(path_600165, query_600166, nil, nil, nil)

var listJobsByStatus* = Call_ListJobsByStatus_600150(name: "listJobsByStatus",
    meth: HttpMethod.HttpGet, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/jobsByStatus/{Status}",
    validator: validate_ListJobsByStatus_600151, base: "/",
    url: url_ListJobsByStatus_600152, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestRole_600167 = ref object of OpenApiRestCall_599368
proc url_TestRole_600169(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TestRole_600168(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>The TestRole operation tests the IAM role used to create the pipeline.</p> <p>The <code>TestRole</code> action lets you determine whether the IAM role you are using has sufficient permissions to let Elastic Transcoder perform tasks associated with the transcoding process. The action attempts to assume the specified IAM role, checks read access to the input and output buckets, and tries to send a test notification to Amazon SNS topics that you specify.</p>
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
  var valid_600170 = header.getOrDefault("X-Amz-Date")
  valid_600170 = validateParameter(valid_600170, JString, required = false,
                                 default = nil)
  if valid_600170 != nil:
    section.add "X-Amz-Date", valid_600170
  var valid_600171 = header.getOrDefault("X-Amz-Security-Token")
  valid_600171 = validateParameter(valid_600171, JString, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "X-Amz-Security-Token", valid_600171
  var valid_600172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Content-Sha256", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-Algorithm")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Algorithm", valid_600173
  var valid_600174 = header.getOrDefault("X-Amz-Signature")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "X-Amz-Signature", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-SignedHeaders", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Credential")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Credential", valid_600176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600178: Call_TestRole_600167; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The TestRole operation tests the IAM role used to create the pipeline.</p> <p>The <code>TestRole</code> action lets you determine whether the IAM role you are using has sufficient permissions to let Elastic Transcoder perform tasks associated with the transcoding process. The action attempts to assume the specified IAM role, checks read access to the input and output buckets, and tries to send a test notification to Amazon SNS topics that you specify.</p>
  ## 
  let valid = call_600178.validator(path, query, header, formData, body)
  let scheme = call_600178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600178.url(scheme.get, call_600178.host, call_600178.base,
                         call_600178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600178, url, valid)

proc call*(call_600179: Call_TestRole_600167; body: JsonNode): Recallable =
  ## testRole
  ## <p>The TestRole operation tests the IAM role used to create the pipeline.</p> <p>The <code>TestRole</code> action lets you determine whether the IAM role you are using has sufficient permissions to let Elastic Transcoder perform tasks associated with the transcoding process. The action attempts to assume the specified IAM role, checks read access to the input and output buckets, and tries to send a test notification to Amazon SNS topics that you specify.</p>
  ##   body: JObject (required)
  var body_600180 = newJObject()
  if body != nil:
    body_600180 = body
  result = call_600179.call(nil, nil, nil, nil, body_600180)

var testRole* = Call_TestRole_600167(name: "testRole", meth: HttpMethod.HttpPost,
                                  host: "elastictranscoder.amazonaws.com",
                                  route: "/2012-09-25/roleTests",
                                  validator: validate_TestRole_600168, base: "/",
                                  url: url_TestRole_600169,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipelineNotifications_600181 = ref object of OpenApiRestCall_599368
proc url_UpdatePipelineNotifications_600183(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2012-09-25/pipelines/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/notifications")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdatePipelineNotifications_600182(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>With the UpdatePipelineNotifications operation, you can update Amazon Simple Notification Service (Amazon SNS) notifications for a pipeline.</p> <p>When you update notifications for a pipeline, Elastic Transcoder returns the values that you specified in the request.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identifier of the pipeline for which you want to change notification settings.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_600184 = path.getOrDefault("Id")
  valid_600184 = validateParameter(valid_600184, JString, required = true,
                                 default = nil)
  if valid_600184 != nil:
    section.add "Id", valid_600184
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600193: Call_UpdatePipelineNotifications_600181; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>With the UpdatePipelineNotifications operation, you can update Amazon Simple Notification Service (Amazon SNS) notifications for a pipeline.</p> <p>When you update notifications for a pipeline, Elastic Transcoder returns the values that you specified in the request.</p>
  ## 
  let valid = call_600193.validator(path, query, header, formData, body)
  let scheme = call_600193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600193.url(scheme.get, call_600193.host, call_600193.base,
                         call_600193.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600193, url, valid)

proc call*(call_600194: Call_UpdatePipelineNotifications_600181; Id: string;
          body: JsonNode): Recallable =
  ## updatePipelineNotifications
  ## <p>With the UpdatePipelineNotifications operation, you can update Amazon Simple Notification Service (Amazon SNS) notifications for a pipeline.</p> <p>When you update notifications for a pipeline, Elastic Transcoder returns the values that you specified in the request.</p>
  ##   Id: string (required)
  ##     : The identifier of the pipeline for which you want to change notification settings.
  ##   body: JObject (required)
  var path_600195 = newJObject()
  var body_600196 = newJObject()
  add(path_600195, "Id", newJString(Id))
  if body != nil:
    body_600196 = body
  result = call_600194.call(path_600195, nil, nil, nil, body_600196)

var updatePipelineNotifications* = Call_UpdatePipelineNotifications_600181(
    name: "updatePipelineNotifications", meth: HttpMethod.HttpPost,
    host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines/{Id}/notifications",
    validator: validate_UpdatePipelineNotifications_600182, base: "/",
    url: url_UpdatePipelineNotifications_600183,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipelineStatus_600197 = ref object of OpenApiRestCall_599368
proc url_UpdatePipelineStatus_600199(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2012-09-25/pipelines/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/status")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdatePipelineStatus_600198(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>The UpdatePipelineStatus operation pauses or reactivates a pipeline, so that the pipeline stops or restarts the processing of jobs.</p> <p>Changing the pipeline status is useful if you want to cancel one or more jobs. You can't cancel jobs after Elastic Transcoder has started processing them; if you pause the pipeline to which you submitted the jobs, you have more time to get the job IDs for the jobs that you want to cancel, and to send a <a>CancelJob</a> request. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identifier of the pipeline to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_600200 = path.getOrDefault("Id")
  valid_600200 = validateParameter(valid_600200, JString, required = true,
                                 default = nil)
  if valid_600200 != nil:
    section.add "Id", valid_600200
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
  var valid_600201 = header.getOrDefault("X-Amz-Date")
  valid_600201 = validateParameter(valid_600201, JString, required = false,
                                 default = nil)
  if valid_600201 != nil:
    section.add "X-Amz-Date", valid_600201
  var valid_600202 = header.getOrDefault("X-Amz-Security-Token")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "X-Amz-Security-Token", valid_600202
  var valid_600203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-Content-Sha256", valid_600203
  var valid_600204 = header.getOrDefault("X-Amz-Algorithm")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-Algorithm", valid_600204
  var valid_600205 = header.getOrDefault("X-Amz-Signature")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-Signature", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-SignedHeaders", valid_600206
  var valid_600207 = header.getOrDefault("X-Amz-Credential")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-Credential", valid_600207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600209: Call_UpdatePipelineStatus_600197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The UpdatePipelineStatus operation pauses or reactivates a pipeline, so that the pipeline stops or restarts the processing of jobs.</p> <p>Changing the pipeline status is useful if you want to cancel one or more jobs. You can't cancel jobs after Elastic Transcoder has started processing them; if you pause the pipeline to which you submitted the jobs, you have more time to get the job IDs for the jobs that you want to cancel, and to send a <a>CancelJob</a> request. </p>
  ## 
  let valid = call_600209.validator(path, query, header, formData, body)
  let scheme = call_600209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600209.url(scheme.get, call_600209.host, call_600209.base,
                         call_600209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600209, url, valid)

proc call*(call_600210: Call_UpdatePipelineStatus_600197; Id: string; body: JsonNode): Recallable =
  ## updatePipelineStatus
  ## <p>The UpdatePipelineStatus operation pauses or reactivates a pipeline, so that the pipeline stops or restarts the processing of jobs.</p> <p>Changing the pipeline status is useful if you want to cancel one or more jobs. You can't cancel jobs after Elastic Transcoder has started processing them; if you pause the pipeline to which you submitted the jobs, you have more time to get the job IDs for the jobs that you want to cancel, and to send a <a>CancelJob</a> request. </p>
  ##   Id: string (required)
  ##     : The identifier of the pipeline to update.
  ##   body: JObject (required)
  var path_600211 = newJObject()
  var body_600212 = newJObject()
  add(path_600211, "Id", newJString(Id))
  if body != nil:
    body_600212 = body
  result = call_600210.call(path_600211, nil, nil, nil, body_600212)

var updatePipelineStatus* = Call_UpdatePipelineStatus_600197(
    name: "updatePipelineStatus", meth: HttpMethod.HttpPost,
    host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines/{Id}/status",
    validator: validate_UpdatePipelineStatus_600198, base: "/",
    url: url_UpdatePipelineStatus_600199, schemes: {Scheme.Https, Scheme.Http})
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
