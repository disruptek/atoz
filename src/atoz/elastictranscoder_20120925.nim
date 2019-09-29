
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_ReadJob_593774 = ref object of OpenApiRestCall_593437
proc url_ReadJob_593776(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_ReadJob_593775(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593902 = path.getOrDefault("Id")
  valid_593902 = validateParameter(valid_593902, JString, required = true,
                                 default = nil)
  if valid_593902 != nil:
    section.add "Id", valid_593902
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

proc call*(call_593932: Call_ReadJob_593774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The ReadJob operation returns detailed information about a job.
  ## 
  let valid = call_593932.validator(path, query, header, formData, body)
  let scheme = call_593932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593932.url(scheme.get, call_593932.host, call_593932.base,
                         call_593932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593932, url, valid)

proc call*(call_594003: Call_ReadJob_593774; Id: string): Recallable =
  ## readJob
  ## The ReadJob operation returns detailed information about a job.
  ##   Id: string (required)
  ##     : The identifier of the job for which you want to get detailed information.
  var path_594004 = newJObject()
  add(path_594004, "Id", newJString(Id))
  result = call_594003.call(path_594004, nil, nil, nil, nil)

var readJob* = Call_ReadJob_593774(name: "readJob", meth: HttpMethod.HttpGet,
                                host: "elastictranscoder.amazonaws.com",
                                route: "/2012-09-25/jobs/{Id}",
                                validator: validate_ReadJob_593775, base: "/",
                                url: url_ReadJob_593776,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelJob_594044 = ref object of OpenApiRestCall_593437
proc url_CancelJob_594046(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_CancelJob_594045(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594047 = path.getOrDefault("Id")
  valid_594047 = validateParameter(valid_594047, JString, required = true,
                                 default = nil)
  if valid_594047 != nil:
    section.add "Id", valid_594047
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
  if body != nil:
    result.add "body", body

proc call*(call_594055: Call_CancelJob_594044; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The CancelJob operation cancels an unfinished job.</p> <note> <p>You can only cancel a job that has a status of <code>Submitted</code>. To prevent a pipeline from starting to process a job while you're getting the job identifier, use <a>UpdatePipelineStatus</a> to temporarily pause the pipeline.</p> </note>
  ## 
  let valid = call_594055.validator(path, query, header, formData, body)
  let scheme = call_594055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594055.url(scheme.get, call_594055.host, call_594055.base,
                         call_594055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594055, url, valid)

proc call*(call_594056: Call_CancelJob_594044; Id: string): Recallable =
  ## cancelJob
  ## <p>The CancelJob operation cancels an unfinished job.</p> <note> <p>You can only cancel a job that has a status of <code>Submitted</code>. To prevent a pipeline from starting to process a job while you're getting the job identifier, use <a>UpdatePipelineStatus</a> to temporarily pause the pipeline.</p> </note>
  ##   Id: string (required)
  ##     : <p>The identifier of the job that you want to cancel.</p> <p>To get a list of the jobs (including their <code>jobId</code>) that have a status of <code>Submitted</code>, use the <a>ListJobsByStatus</a> API action.</p>
  var path_594057 = newJObject()
  add(path_594057, "Id", newJString(Id))
  result = call_594056.call(path_594057, nil, nil, nil, nil)

var cancelJob* = Call_CancelJob_594044(name: "cancelJob",
                                    meth: HttpMethod.HttpDelete,
                                    host: "elastictranscoder.amazonaws.com",
                                    route: "/2012-09-25/jobs/{Id}",
                                    validator: validate_CancelJob_594045,
                                    base: "/", url: url_CancelJob_594046,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_594058 = ref object of OpenApiRestCall_593437
proc url_CreateJob_594060(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateJob_594059(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594061 = header.getOrDefault("X-Amz-Date")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Date", valid_594061
  var valid_594062 = header.getOrDefault("X-Amz-Security-Token")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Security-Token", valid_594062
  var valid_594063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594063 = validateParameter(valid_594063, JString, required = false,
                                 default = nil)
  if valid_594063 != nil:
    section.add "X-Amz-Content-Sha256", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Algorithm")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Algorithm", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Signature")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Signature", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-SignedHeaders", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-Credential")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-Credential", valid_594067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594069: Call_CreateJob_594058; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>When you create a job, Elastic Transcoder returns JSON data that includes the values that you specified plus information about the job that is created.</p> <p>If you have specified more than one output for your jobs (for example, one output for the Kindle Fire and another output for the Apple iPhone 4s), you currently must use the Elastic Transcoder API to list the jobs (as opposed to the AWS Console).</p>
  ## 
  let valid = call_594069.validator(path, query, header, formData, body)
  let scheme = call_594069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594069.url(scheme.get, call_594069.host, call_594069.base,
                         call_594069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594069, url, valid)

proc call*(call_594070: Call_CreateJob_594058; body: JsonNode): Recallable =
  ## createJob
  ## <p>When you create a job, Elastic Transcoder returns JSON data that includes the values that you specified plus information about the job that is created.</p> <p>If you have specified more than one output for your jobs (for example, one output for the Kindle Fire and another output for the Apple iPhone 4s), you currently must use the Elastic Transcoder API to list the jobs (as opposed to the AWS Console).</p>
  ##   body: JObject (required)
  var body_594071 = newJObject()
  if body != nil:
    body_594071 = body
  result = call_594070.call(nil, nil, nil, nil, body_594071)

var createJob* = Call_CreateJob_594058(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "elastictranscoder.amazonaws.com",
                                    route: "/2012-09-25/jobs",
                                    validator: validate_CreateJob_594059,
                                    base: "/", url: url_CreateJob_594060,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePipeline_594087 = ref object of OpenApiRestCall_593437
proc url_CreatePipeline_594089(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePipeline_594088(path: JsonNode; query: JsonNode;
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
  var valid_594090 = header.getOrDefault("X-Amz-Date")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "X-Amz-Date", valid_594090
  var valid_594091 = header.getOrDefault("X-Amz-Security-Token")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Security-Token", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Content-Sha256", valid_594092
  var valid_594093 = header.getOrDefault("X-Amz-Algorithm")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-Algorithm", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Signature")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Signature", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-SignedHeaders", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Credential")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Credential", valid_594096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594098: Call_CreatePipeline_594087; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The CreatePipeline operation creates a pipeline with settings that you specify.
  ## 
  let valid = call_594098.validator(path, query, header, formData, body)
  let scheme = call_594098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594098.url(scheme.get, call_594098.host, call_594098.base,
                         call_594098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594098, url, valid)

proc call*(call_594099: Call_CreatePipeline_594087; body: JsonNode): Recallable =
  ## createPipeline
  ## The CreatePipeline operation creates a pipeline with settings that you specify.
  ##   body: JObject (required)
  var body_594100 = newJObject()
  if body != nil:
    body_594100 = body
  result = call_594099.call(nil, nil, nil, nil, body_594100)

var createPipeline* = Call_CreatePipeline_594087(name: "createPipeline",
    meth: HttpMethod.HttpPost, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines", validator: validate_CreatePipeline_594088,
    base: "/", url: url_CreatePipeline_594089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelines_594072 = ref object of OpenApiRestCall_593437
proc url_ListPipelines_594074(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPipelines_594073(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594075 = query.getOrDefault("PageToken")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "PageToken", valid_594075
  var valid_594076 = query.getOrDefault("Ascending")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "Ascending", valid_594076
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
  var valid_594077 = header.getOrDefault("X-Amz-Date")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Date", valid_594077
  var valid_594078 = header.getOrDefault("X-Amz-Security-Token")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = nil)
  if valid_594078 != nil:
    section.add "X-Amz-Security-Token", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Content-Sha256", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Algorithm")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Algorithm", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Signature")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Signature", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-SignedHeaders", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-Credential")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Credential", valid_594083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594084: Call_ListPipelines_594072; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The ListPipelines operation gets a list of the pipelines associated with the current AWS account.
  ## 
  let valid = call_594084.validator(path, query, header, formData, body)
  let scheme = call_594084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594084.url(scheme.get, call_594084.host, call_594084.base,
                         call_594084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594084, url, valid)

proc call*(call_594085: Call_ListPipelines_594072; PageToken: string = "";
          Ascending: string = ""): Recallable =
  ## listPipelines
  ## The ListPipelines operation gets a list of the pipelines associated with the current AWS account.
  ##   PageToken: string
  ##            : When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  ##   Ascending: string
  ##            : To list pipelines in chronological order by the date and time that they were created, enter <code>true</code>. To list pipelines in reverse chronological order, enter <code>false</code>.
  var query_594086 = newJObject()
  add(query_594086, "PageToken", newJString(PageToken))
  add(query_594086, "Ascending", newJString(Ascending))
  result = call_594085.call(nil, query_594086, nil, nil, nil)

var listPipelines* = Call_ListPipelines_594072(name: "listPipelines",
    meth: HttpMethod.HttpGet, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines", validator: validate_ListPipelines_594073,
    base: "/", url: url_ListPipelines_594074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePreset_594116 = ref object of OpenApiRestCall_593437
proc url_CreatePreset_594118(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePreset_594117(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594119 = header.getOrDefault("X-Amz-Date")
  valid_594119 = validateParameter(valid_594119, JString, required = false,
                                 default = nil)
  if valid_594119 != nil:
    section.add "X-Amz-Date", valid_594119
  var valid_594120 = header.getOrDefault("X-Amz-Security-Token")
  valid_594120 = validateParameter(valid_594120, JString, required = false,
                                 default = nil)
  if valid_594120 != nil:
    section.add "X-Amz-Security-Token", valid_594120
  var valid_594121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Content-Sha256", valid_594121
  var valid_594122 = header.getOrDefault("X-Amz-Algorithm")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "X-Amz-Algorithm", valid_594122
  var valid_594123 = header.getOrDefault("X-Amz-Signature")
  valid_594123 = validateParameter(valid_594123, JString, required = false,
                                 default = nil)
  if valid_594123 != nil:
    section.add "X-Amz-Signature", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-SignedHeaders", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Credential")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Credential", valid_594125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594127: Call_CreatePreset_594116; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The CreatePreset operation creates a preset with settings that you specify.</p> <important> <p>Elastic Transcoder checks the CreatePreset settings to ensure that they meet Elastic Transcoder requirements and to determine whether they comply with H.264 standards. If your settings are not valid for Elastic Transcoder, Elastic Transcoder returns an HTTP 400 response (<code>ValidationException</code>) and does not create the preset. If the settings are valid for Elastic Transcoder but aren't strictly compliant with the H.264 standard, Elastic Transcoder creates the preset and returns a warning message in the response. This helps you determine whether your settings comply with the H.264 standard while giving you greater flexibility with respect to the video that Elastic Transcoder produces.</p> </important> <p>Elastic Transcoder uses the H.264 video-compression format. For more information, see the International Telecommunication Union publication <i>Recommendation ITU-T H.264: Advanced video coding for generic audiovisual services</i>.</p>
  ## 
  let valid = call_594127.validator(path, query, header, formData, body)
  let scheme = call_594127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594127.url(scheme.get, call_594127.host, call_594127.base,
                         call_594127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594127, url, valid)

proc call*(call_594128: Call_CreatePreset_594116; body: JsonNode): Recallable =
  ## createPreset
  ## <p>The CreatePreset operation creates a preset with settings that you specify.</p> <important> <p>Elastic Transcoder checks the CreatePreset settings to ensure that they meet Elastic Transcoder requirements and to determine whether they comply with H.264 standards. If your settings are not valid for Elastic Transcoder, Elastic Transcoder returns an HTTP 400 response (<code>ValidationException</code>) and does not create the preset. If the settings are valid for Elastic Transcoder but aren't strictly compliant with the H.264 standard, Elastic Transcoder creates the preset and returns a warning message in the response. This helps you determine whether your settings comply with the H.264 standard while giving you greater flexibility with respect to the video that Elastic Transcoder produces.</p> </important> <p>Elastic Transcoder uses the H.264 video-compression format. For more information, see the International Telecommunication Union publication <i>Recommendation ITU-T H.264: Advanced video coding for generic audiovisual services</i>.</p>
  ##   body: JObject (required)
  var body_594129 = newJObject()
  if body != nil:
    body_594129 = body
  result = call_594128.call(nil, nil, nil, nil, body_594129)

var createPreset* = Call_CreatePreset_594116(name: "createPreset",
    meth: HttpMethod.HttpPost, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/presets", validator: validate_CreatePreset_594117,
    base: "/", url: url_CreatePreset_594118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPresets_594101 = ref object of OpenApiRestCall_593437
proc url_ListPresets_594103(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPresets_594102(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594104 = query.getOrDefault("PageToken")
  valid_594104 = validateParameter(valid_594104, JString, required = false,
                                 default = nil)
  if valid_594104 != nil:
    section.add "PageToken", valid_594104
  var valid_594105 = query.getOrDefault("Ascending")
  valid_594105 = validateParameter(valid_594105, JString, required = false,
                                 default = nil)
  if valid_594105 != nil:
    section.add "Ascending", valid_594105
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
  var valid_594106 = header.getOrDefault("X-Amz-Date")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Date", valid_594106
  var valid_594107 = header.getOrDefault("X-Amz-Security-Token")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "X-Amz-Security-Token", valid_594107
  var valid_594108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "X-Amz-Content-Sha256", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Algorithm")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Algorithm", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Signature")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Signature", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-SignedHeaders", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Credential")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Credential", valid_594112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594113: Call_ListPresets_594101; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The ListPresets operation gets a list of the default presets included with Elastic Transcoder and the presets that you've added in an AWS region.
  ## 
  let valid = call_594113.validator(path, query, header, formData, body)
  let scheme = call_594113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594113.url(scheme.get, call_594113.host, call_594113.base,
                         call_594113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594113, url, valid)

proc call*(call_594114: Call_ListPresets_594101; PageToken: string = "";
          Ascending: string = ""): Recallable =
  ## listPresets
  ## The ListPresets operation gets a list of the default presets included with Elastic Transcoder and the presets that you've added in an AWS region.
  ##   PageToken: string
  ##            : When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  ##   Ascending: string
  ##            : To list presets in chronological order by the date and time that they were created, enter <code>true</code>. To list presets in reverse chronological order, enter <code>false</code>.
  var query_594115 = newJObject()
  add(query_594115, "PageToken", newJString(PageToken))
  add(query_594115, "Ascending", newJString(Ascending))
  result = call_594114.call(nil, query_594115, nil, nil, nil)

var listPresets* = Call_ListPresets_594101(name: "listPresets",
                                        meth: HttpMethod.HttpGet, host: "elastictranscoder.amazonaws.com",
                                        route: "/2012-09-25/presets",
                                        validator: validate_ListPresets_594102,
                                        base: "/", url: url_ListPresets_594103,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipeline_594144 = ref object of OpenApiRestCall_593437
proc url_UpdatePipeline_594146(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdatePipeline_594145(path: JsonNode; query: JsonNode;
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
  var valid_594147 = path.getOrDefault("Id")
  valid_594147 = validateParameter(valid_594147, JString, required = true,
                                 default = nil)
  if valid_594147 != nil:
    section.add "Id", valid_594147
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
  var valid_594148 = header.getOrDefault("X-Amz-Date")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "X-Amz-Date", valid_594148
  var valid_594149 = header.getOrDefault("X-Amz-Security-Token")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "X-Amz-Security-Token", valid_594149
  var valid_594150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "X-Amz-Content-Sha256", valid_594150
  var valid_594151 = header.getOrDefault("X-Amz-Algorithm")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Algorithm", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Signature")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Signature", valid_594152
  var valid_594153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594153 = validateParameter(valid_594153, JString, required = false,
                                 default = nil)
  if valid_594153 != nil:
    section.add "X-Amz-SignedHeaders", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Credential")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Credential", valid_594154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594156: Call_UpdatePipeline_594144; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Use the <code>UpdatePipeline</code> operation to update settings for a pipeline.</p> <important> <p>When you change pipeline settings, your changes take effect immediately. Jobs that you have already submitted and that Elastic Transcoder has not started to process are affected in addition to jobs that you submit after you change settings. </p> </important>
  ## 
  let valid = call_594156.validator(path, query, header, formData, body)
  let scheme = call_594156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594156.url(scheme.get, call_594156.host, call_594156.base,
                         call_594156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594156, url, valid)

proc call*(call_594157: Call_UpdatePipeline_594144; Id: string; body: JsonNode): Recallable =
  ## updatePipeline
  ## <p> Use the <code>UpdatePipeline</code> operation to update settings for a pipeline.</p> <important> <p>When you change pipeline settings, your changes take effect immediately. Jobs that you have already submitted and that Elastic Transcoder has not started to process are affected in addition to jobs that you submit after you change settings. </p> </important>
  ##   Id: string (required)
  ##     : The ID of the pipeline that you want to update.
  ##   body: JObject (required)
  var path_594158 = newJObject()
  var body_594159 = newJObject()
  add(path_594158, "Id", newJString(Id))
  if body != nil:
    body_594159 = body
  result = call_594157.call(path_594158, nil, nil, nil, body_594159)

var updatePipeline* = Call_UpdatePipeline_594144(name: "updatePipeline",
    meth: HttpMethod.HttpPut, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines/{Id}", validator: validate_UpdatePipeline_594145,
    base: "/", url: url_UpdatePipeline_594146, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReadPipeline_594130 = ref object of OpenApiRestCall_593437
proc url_ReadPipeline_594132(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ReadPipeline_594131(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594133 = path.getOrDefault("Id")
  valid_594133 = validateParameter(valid_594133, JString, required = true,
                                 default = nil)
  if valid_594133 != nil:
    section.add "Id", valid_594133
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
  var valid_594134 = header.getOrDefault("X-Amz-Date")
  valid_594134 = validateParameter(valid_594134, JString, required = false,
                                 default = nil)
  if valid_594134 != nil:
    section.add "X-Amz-Date", valid_594134
  var valid_594135 = header.getOrDefault("X-Amz-Security-Token")
  valid_594135 = validateParameter(valid_594135, JString, required = false,
                                 default = nil)
  if valid_594135 != nil:
    section.add "X-Amz-Security-Token", valid_594135
  var valid_594136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Content-Sha256", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-Algorithm")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Algorithm", valid_594137
  var valid_594138 = header.getOrDefault("X-Amz-Signature")
  valid_594138 = validateParameter(valid_594138, JString, required = false,
                                 default = nil)
  if valid_594138 != nil:
    section.add "X-Amz-Signature", valid_594138
  var valid_594139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-SignedHeaders", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Credential")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Credential", valid_594140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594141: Call_ReadPipeline_594130; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The ReadPipeline operation gets detailed information about a pipeline.
  ## 
  let valid = call_594141.validator(path, query, header, formData, body)
  let scheme = call_594141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594141.url(scheme.get, call_594141.host, call_594141.base,
                         call_594141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594141, url, valid)

proc call*(call_594142: Call_ReadPipeline_594130; Id: string): Recallable =
  ## readPipeline
  ## The ReadPipeline operation gets detailed information about a pipeline.
  ##   Id: string (required)
  ##     : The identifier of the pipeline to read.
  var path_594143 = newJObject()
  add(path_594143, "Id", newJString(Id))
  result = call_594142.call(path_594143, nil, nil, nil, nil)

var readPipeline* = Call_ReadPipeline_594130(name: "readPipeline",
    meth: HttpMethod.HttpGet, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines/{Id}", validator: validate_ReadPipeline_594131,
    base: "/", url: url_ReadPipeline_594132, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePipeline_594160 = ref object of OpenApiRestCall_593437
proc url_DeletePipeline_594162(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeletePipeline_594161(path: JsonNode; query: JsonNode;
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
  var valid_594163 = path.getOrDefault("Id")
  valid_594163 = validateParameter(valid_594163, JString, required = true,
                                 default = nil)
  if valid_594163 != nil:
    section.add "Id", valid_594163
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
  var valid_594164 = header.getOrDefault("X-Amz-Date")
  valid_594164 = validateParameter(valid_594164, JString, required = false,
                                 default = nil)
  if valid_594164 != nil:
    section.add "X-Amz-Date", valid_594164
  var valid_594165 = header.getOrDefault("X-Amz-Security-Token")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-Security-Token", valid_594165
  var valid_594166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Content-Sha256", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Algorithm")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Algorithm", valid_594167
  var valid_594168 = header.getOrDefault("X-Amz-Signature")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "X-Amz-Signature", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-SignedHeaders", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Credential")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Credential", valid_594170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594171: Call_DeletePipeline_594160; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The DeletePipeline operation removes a pipeline.</p> <p> You can only delete a pipeline that has never been used or that is not currently in use (doesn't contain any active jobs). If the pipeline is currently in use, <code>DeletePipeline</code> returns an error. </p>
  ## 
  let valid = call_594171.validator(path, query, header, formData, body)
  let scheme = call_594171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594171.url(scheme.get, call_594171.host, call_594171.base,
                         call_594171.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594171, url, valid)

proc call*(call_594172: Call_DeletePipeline_594160; Id: string): Recallable =
  ## deletePipeline
  ## <p>The DeletePipeline operation removes a pipeline.</p> <p> You can only delete a pipeline that has never been used or that is not currently in use (doesn't contain any active jobs). If the pipeline is currently in use, <code>DeletePipeline</code> returns an error. </p>
  ##   Id: string (required)
  ##     : The identifier of the pipeline that you want to delete.
  var path_594173 = newJObject()
  add(path_594173, "Id", newJString(Id))
  result = call_594172.call(path_594173, nil, nil, nil, nil)

var deletePipeline* = Call_DeletePipeline_594160(name: "deletePipeline",
    meth: HttpMethod.HttpDelete, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines/{Id}", validator: validate_DeletePipeline_594161,
    base: "/", url: url_DeletePipeline_594162, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReadPreset_594174 = ref object of OpenApiRestCall_593437
proc url_ReadPreset_594176(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_ReadPreset_594175(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594177 = path.getOrDefault("Id")
  valid_594177 = validateParameter(valid_594177, JString, required = true,
                                 default = nil)
  if valid_594177 != nil:
    section.add "Id", valid_594177
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
  var valid_594178 = header.getOrDefault("X-Amz-Date")
  valid_594178 = validateParameter(valid_594178, JString, required = false,
                                 default = nil)
  if valid_594178 != nil:
    section.add "X-Amz-Date", valid_594178
  var valid_594179 = header.getOrDefault("X-Amz-Security-Token")
  valid_594179 = validateParameter(valid_594179, JString, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "X-Amz-Security-Token", valid_594179
  var valid_594180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "X-Amz-Content-Sha256", valid_594180
  var valid_594181 = header.getOrDefault("X-Amz-Algorithm")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Algorithm", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Signature")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Signature", valid_594182
  var valid_594183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594183 = validateParameter(valid_594183, JString, required = false,
                                 default = nil)
  if valid_594183 != nil:
    section.add "X-Amz-SignedHeaders", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-Credential")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Credential", valid_594184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594185: Call_ReadPreset_594174; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The ReadPreset operation gets detailed information about a preset.
  ## 
  let valid = call_594185.validator(path, query, header, formData, body)
  let scheme = call_594185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594185.url(scheme.get, call_594185.host, call_594185.base,
                         call_594185.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594185, url, valid)

proc call*(call_594186: Call_ReadPreset_594174; Id: string): Recallable =
  ## readPreset
  ## The ReadPreset operation gets detailed information about a preset.
  ##   Id: string (required)
  ##     : The identifier of the preset for which you want to get detailed information.
  var path_594187 = newJObject()
  add(path_594187, "Id", newJString(Id))
  result = call_594186.call(path_594187, nil, nil, nil, nil)

var readPreset* = Call_ReadPreset_594174(name: "readPreset",
                                      meth: HttpMethod.HttpGet,
                                      host: "elastictranscoder.amazonaws.com",
                                      route: "/2012-09-25/presets/{Id}",
                                      validator: validate_ReadPreset_594175,
                                      base: "/", url: url_ReadPreset_594176,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePreset_594188 = ref object of OpenApiRestCall_593437
proc url_DeletePreset_594190(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeletePreset_594189(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594191 = path.getOrDefault("Id")
  valid_594191 = validateParameter(valid_594191, JString, required = true,
                                 default = nil)
  if valid_594191 != nil:
    section.add "Id", valid_594191
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
  var valid_594192 = header.getOrDefault("X-Amz-Date")
  valid_594192 = validateParameter(valid_594192, JString, required = false,
                                 default = nil)
  if valid_594192 != nil:
    section.add "X-Amz-Date", valid_594192
  var valid_594193 = header.getOrDefault("X-Amz-Security-Token")
  valid_594193 = validateParameter(valid_594193, JString, required = false,
                                 default = nil)
  if valid_594193 != nil:
    section.add "X-Amz-Security-Token", valid_594193
  var valid_594194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594194 = validateParameter(valid_594194, JString, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "X-Amz-Content-Sha256", valid_594194
  var valid_594195 = header.getOrDefault("X-Amz-Algorithm")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "X-Amz-Algorithm", valid_594195
  var valid_594196 = header.getOrDefault("X-Amz-Signature")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Signature", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-SignedHeaders", valid_594197
  var valid_594198 = header.getOrDefault("X-Amz-Credential")
  valid_594198 = validateParameter(valid_594198, JString, required = false,
                                 default = nil)
  if valid_594198 != nil:
    section.add "X-Amz-Credential", valid_594198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594199: Call_DeletePreset_594188; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The DeletePreset operation removes a preset that you've added in an AWS region.</p> <note> <p>You can't delete the default presets that are included with Elastic Transcoder.</p> </note>
  ## 
  let valid = call_594199.validator(path, query, header, formData, body)
  let scheme = call_594199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594199.url(scheme.get, call_594199.host, call_594199.base,
                         call_594199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594199, url, valid)

proc call*(call_594200: Call_DeletePreset_594188; Id: string): Recallable =
  ## deletePreset
  ## <p>The DeletePreset operation removes a preset that you've added in an AWS region.</p> <note> <p>You can't delete the default presets that are included with Elastic Transcoder.</p> </note>
  ##   Id: string (required)
  ##     : The identifier of the preset for which you want to get detailed information.
  var path_594201 = newJObject()
  add(path_594201, "Id", newJString(Id))
  result = call_594200.call(path_594201, nil, nil, nil, nil)

var deletePreset* = Call_DeletePreset_594188(name: "deletePreset",
    meth: HttpMethod.HttpDelete, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/presets/{Id}", validator: validate_DeletePreset_594189,
    base: "/", url: url_DeletePreset_594190, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobsByPipeline_594202 = ref object of OpenApiRestCall_593437
proc url_ListJobsByPipeline_594204(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListJobsByPipeline_594203(path: JsonNode; query: JsonNode;
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
  var valid_594205 = path.getOrDefault("PipelineId")
  valid_594205 = validateParameter(valid_594205, JString, required = true,
                                 default = nil)
  if valid_594205 != nil:
    section.add "PipelineId", valid_594205
  result.add "path", section
  ## parameters in `query` object:
  ##   PageToken: JString
  ##            :  When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  ##   Ascending: JString
  ##            :  To list jobs in chronological order by the date and time that they were submitted, enter <code>true</code>. To list jobs in reverse chronological order, enter <code>false</code>. 
  section = newJObject()
  var valid_594206 = query.getOrDefault("PageToken")
  valid_594206 = validateParameter(valid_594206, JString, required = false,
                                 default = nil)
  if valid_594206 != nil:
    section.add "PageToken", valid_594206
  var valid_594207 = query.getOrDefault("Ascending")
  valid_594207 = validateParameter(valid_594207, JString, required = false,
                                 default = nil)
  if valid_594207 != nil:
    section.add "Ascending", valid_594207
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
  var valid_594208 = header.getOrDefault("X-Amz-Date")
  valid_594208 = validateParameter(valid_594208, JString, required = false,
                                 default = nil)
  if valid_594208 != nil:
    section.add "X-Amz-Date", valid_594208
  var valid_594209 = header.getOrDefault("X-Amz-Security-Token")
  valid_594209 = validateParameter(valid_594209, JString, required = false,
                                 default = nil)
  if valid_594209 != nil:
    section.add "X-Amz-Security-Token", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-Content-Sha256", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-Algorithm")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Algorithm", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Signature")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Signature", valid_594212
  var valid_594213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "X-Amz-SignedHeaders", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-Credential")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Credential", valid_594214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594215: Call_ListJobsByPipeline_594202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The ListJobsByPipeline operation gets a list of the jobs currently in a pipeline.</p> <p>Elastic Transcoder returns all of the jobs currently in the specified pipeline. The response body contains one element for each job that satisfies the search criteria.</p>
  ## 
  let valid = call_594215.validator(path, query, header, formData, body)
  let scheme = call_594215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594215.url(scheme.get, call_594215.host, call_594215.base,
                         call_594215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594215, url, valid)

proc call*(call_594216: Call_ListJobsByPipeline_594202; PipelineId: string;
          PageToken: string = ""; Ascending: string = ""): Recallable =
  ## listJobsByPipeline
  ## <p>The ListJobsByPipeline operation gets a list of the jobs currently in a pipeline.</p> <p>Elastic Transcoder returns all of the jobs currently in the specified pipeline. The response body contains one element for each job that satisfies the search criteria.</p>
  ##   PageToken: string
  ##            :  When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  ##   PipelineId: string (required)
  ##             : The ID of the pipeline for which you want to get job information.
  ##   Ascending: string
  ##            :  To list jobs in chronological order by the date and time that they were submitted, enter <code>true</code>. To list jobs in reverse chronological order, enter <code>false</code>. 
  var path_594217 = newJObject()
  var query_594218 = newJObject()
  add(query_594218, "PageToken", newJString(PageToken))
  add(path_594217, "PipelineId", newJString(PipelineId))
  add(query_594218, "Ascending", newJString(Ascending))
  result = call_594216.call(path_594217, query_594218, nil, nil, nil)

var listJobsByPipeline* = Call_ListJobsByPipeline_594202(
    name: "listJobsByPipeline", meth: HttpMethod.HttpGet,
    host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/jobsByPipeline/{PipelineId}",
    validator: validate_ListJobsByPipeline_594203, base: "/",
    url: url_ListJobsByPipeline_594204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobsByStatus_594219 = ref object of OpenApiRestCall_593437
proc url_ListJobsByStatus_594221(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListJobsByStatus_594220(path: JsonNode; query: JsonNode;
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
  var valid_594222 = path.getOrDefault("Status")
  valid_594222 = validateParameter(valid_594222, JString, required = true,
                                 default = nil)
  if valid_594222 != nil:
    section.add "Status", valid_594222
  result.add "path", section
  ## parameters in `query` object:
  ##   PageToken: JString
  ##            :  When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  ##   Ascending: JString
  ##            :  To list jobs in chronological order by the date and time that they were submitted, enter <code>true</code>. To list jobs in reverse chronological order, enter <code>false</code>. 
  section = newJObject()
  var valid_594223 = query.getOrDefault("PageToken")
  valid_594223 = validateParameter(valid_594223, JString, required = false,
                                 default = nil)
  if valid_594223 != nil:
    section.add "PageToken", valid_594223
  var valid_594224 = query.getOrDefault("Ascending")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "Ascending", valid_594224
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
  var valid_594225 = header.getOrDefault("X-Amz-Date")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "X-Amz-Date", valid_594225
  var valid_594226 = header.getOrDefault("X-Amz-Security-Token")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Security-Token", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-Content-Sha256", valid_594227
  var valid_594228 = header.getOrDefault("X-Amz-Algorithm")
  valid_594228 = validateParameter(valid_594228, JString, required = false,
                                 default = nil)
  if valid_594228 != nil:
    section.add "X-Amz-Algorithm", valid_594228
  var valid_594229 = header.getOrDefault("X-Amz-Signature")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-Signature", valid_594229
  var valid_594230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "X-Amz-SignedHeaders", valid_594230
  var valid_594231 = header.getOrDefault("X-Amz-Credential")
  valid_594231 = validateParameter(valid_594231, JString, required = false,
                                 default = nil)
  if valid_594231 != nil:
    section.add "X-Amz-Credential", valid_594231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594232: Call_ListJobsByStatus_594219; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The ListJobsByStatus operation gets a list of jobs that have a specified status. The response body contains one element for each job that satisfies the search criteria.
  ## 
  let valid = call_594232.validator(path, query, header, formData, body)
  let scheme = call_594232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594232.url(scheme.get, call_594232.host, call_594232.base,
                         call_594232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594232, url, valid)

proc call*(call_594233: Call_ListJobsByStatus_594219; Status: string;
          PageToken: string = ""; Ascending: string = ""): Recallable =
  ## listJobsByStatus
  ## The ListJobsByStatus operation gets a list of jobs that have a specified status. The response body contains one element for each job that satisfies the search criteria.
  ##   Status: string (required)
  ##         : To get information about all of the jobs associated with the current AWS account that have a given status, specify the following status: <code>Submitted</code>, <code>Progressing</code>, <code>Complete</code>, <code>Canceled</code>, or <code>Error</code>.
  ##   PageToken: string
  ##            :  When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  ##   Ascending: string
  ##            :  To list jobs in chronological order by the date and time that they were submitted, enter <code>true</code>. To list jobs in reverse chronological order, enter <code>false</code>. 
  var path_594234 = newJObject()
  var query_594235 = newJObject()
  add(path_594234, "Status", newJString(Status))
  add(query_594235, "PageToken", newJString(PageToken))
  add(query_594235, "Ascending", newJString(Ascending))
  result = call_594233.call(path_594234, query_594235, nil, nil, nil)

var listJobsByStatus* = Call_ListJobsByStatus_594219(name: "listJobsByStatus",
    meth: HttpMethod.HttpGet, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/jobsByStatus/{Status}",
    validator: validate_ListJobsByStatus_594220, base: "/",
    url: url_ListJobsByStatus_594221, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestRole_594236 = ref object of OpenApiRestCall_593437
proc url_TestRole_594238(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TestRole_594237(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594239 = header.getOrDefault("X-Amz-Date")
  valid_594239 = validateParameter(valid_594239, JString, required = false,
                                 default = nil)
  if valid_594239 != nil:
    section.add "X-Amz-Date", valid_594239
  var valid_594240 = header.getOrDefault("X-Amz-Security-Token")
  valid_594240 = validateParameter(valid_594240, JString, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "X-Amz-Security-Token", valid_594240
  var valid_594241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Content-Sha256", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-Algorithm")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Algorithm", valid_594242
  var valid_594243 = header.getOrDefault("X-Amz-Signature")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "X-Amz-Signature", valid_594243
  var valid_594244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "X-Amz-SignedHeaders", valid_594244
  var valid_594245 = header.getOrDefault("X-Amz-Credential")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "X-Amz-Credential", valid_594245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594247: Call_TestRole_594236; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The TestRole operation tests the IAM role used to create the pipeline.</p> <p>The <code>TestRole</code> action lets you determine whether the IAM role you are using has sufficient permissions to let Elastic Transcoder perform tasks associated with the transcoding process. The action attempts to assume the specified IAM role, checks read access to the input and output buckets, and tries to send a test notification to Amazon SNS topics that you specify.</p>
  ## 
  let valid = call_594247.validator(path, query, header, formData, body)
  let scheme = call_594247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594247.url(scheme.get, call_594247.host, call_594247.base,
                         call_594247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594247, url, valid)

proc call*(call_594248: Call_TestRole_594236; body: JsonNode): Recallable =
  ## testRole
  ## <p>The TestRole operation tests the IAM role used to create the pipeline.</p> <p>The <code>TestRole</code> action lets you determine whether the IAM role you are using has sufficient permissions to let Elastic Transcoder perform tasks associated with the transcoding process. The action attempts to assume the specified IAM role, checks read access to the input and output buckets, and tries to send a test notification to Amazon SNS topics that you specify.</p>
  ##   body: JObject (required)
  var body_594249 = newJObject()
  if body != nil:
    body_594249 = body
  result = call_594248.call(nil, nil, nil, nil, body_594249)

var testRole* = Call_TestRole_594236(name: "testRole", meth: HttpMethod.HttpPost,
                                  host: "elastictranscoder.amazonaws.com",
                                  route: "/2012-09-25/roleTests",
                                  validator: validate_TestRole_594237, base: "/",
                                  url: url_TestRole_594238,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipelineNotifications_594250 = ref object of OpenApiRestCall_593437
proc url_UpdatePipelineNotifications_594252(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_UpdatePipelineNotifications_594251(path: JsonNode; query: JsonNode;
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
  var valid_594253 = path.getOrDefault("Id")
  valid_594253 = validateParameter(valid_594253, JString, required = true,
                                 default = nil)
  if valid_594253 != nil:
    section.add "Id", valid_594253
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
  var valid_594254 = header.getOrDefault("X-Amz-Date")
  valid_594254 = validateParameter(valid_594254, JString, required = false,
                                 default = nil)
  if valid_594254 != nil:
    section.add "X-Amz-Date", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-Security-Token")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-Security-Token", valid_594255
  var valid_594256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Content-Sha256", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-Algorithm")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Algorithm", valid_594257
  var valid_594258 = header.getOrDefault("X-Amz-Signature")
  valid_594258 = validateParameter(valid_594258, JString, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "X-Amz-Signature", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-SignedHeaders", valid_594259
  var valid_594260 = header.getOrDefault("X-Amz-Credential")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-Credential", valid_594260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594262: Call_UpdatePipelineNotifications_594250; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>With the UpdatePipelineNotifications operation, you can update Amazon Simple Notification Service (Amazon SNS) notifications for a pipeline.</p> <p>When you update notifications for a pipeline, Elastic Transcoder returns the values that you specified in the request.</p>
  ## 
  let valid = call_594262.validator(path, query, header, formData, body)
  let scheme = call_594262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594262.url(scheme.get, call_594262.host, call_594262.base,
                         call_594262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594262, url, valid)

proc call*(call_594263: Call_UpdatePipelineNotifications_594250; Id: string;
          body: JsonNode): Recallable =
  ## updatePipelineNotifications
  ## <p>With the UpdatePipelineNotifications operation, you can update Amazon Simple Notification Service (Amazon SNS) notifications for a pipeline.</p> <p>When you update notifications for a pipeline, Elastic Transcoder returns the values that you specified in the request.</p>
  ##   Id: string (required)
  ##     : The identifier of the pipeline for which you want to change notification settings.
  ##   body: JObject (required)
  var path_594264 = newJObject()
  var body_594265 = newJObject()
  add(path_594264, "Id", newJString(Id))
  if body != nil:
    body_594265 = body
  result = call_594263.call(path_594264, nil, nil, nil, body_594265)

var updatePipelineNotifications* = Call_UpdatePipelineNotifications_594250(
    name: "updatePipelineNotifications", meth: HttpMethod.HttpPost,
    host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines/{Id}/notifications",
    validator: validate_UpdatePipelineNotifications_594251, base: "/",
    url: url_UpdatePipelineNotifications_594252,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipelineStatus_594266 = ref object of OpenApiRestCall_593437
proc url_UpdatePipelineStatus_594268(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdatePipelineStatus_594267(path: JsonNode; query: JsonNode;
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
  var valid_594269 = path.getOrDefault("Id")
  valid_594269 = validateParameter(valid_594269, JString, required = true,
                                 default = nil)
  if valid_594269 != nil:
    section.add "Id", valid_594269
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
  var valid_594270 = header.getOrDefault("X-Amz-Date")
  valid_594270 = validateParameter(valid_594270, JString, required = false,
                                 default = nil)
  if valid_594270 != nil:
    section.add "X-Amz-Date", valid_594270
  var valid_594271 = header.getOrDefault("X-Amz-Security-Token")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "X-Amz-Security-Token", valid_594271
  var valid_594272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "X-Amz-Content-Sha256", valid_594272
  var valid_594273 = header.getOrDefault("X-Amz-Algorithm")
  valid_594273 = validateParameter(valid_594273, JString, required = false,
                                 default = nil)
  if valid_594273 != nil:
    section.add "X-Amz-Algorithm", valid_594273
  var valid_594274 = header.getOrDefault("X-Amz-Signature")
  valid_594274 = validateParameter(valid_594274, JString, required = false,
                                 default = nil)
  if valid_594274 != nil:
    section.add "X-Amz-Signature", valid_594274
  var valid_594275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594275 = validateParameter(valid_594275, JString, required = false,
                                 default = nil)
  if valid_594275 != nil:
    section.add "X-Amz-SignedHeaders", valid_594275
  var valid_594276 = header.getOrDefault("X-Amz-Credential")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "X-Amz-Credential", valid_594276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594278: Call_UpdatePipelineStatus_594266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The UpdatePipelineStatus operation pauses or reactivates a pipeline, so that the pipeline stops or restarts the processing of jobs.</p> <p>Changing the pipeline status is useful if you want to cancel one or more jobs. You can't cancel jobs after Elastic Transcoder has started processing them; if you pause the pipeline to which you submitted the jobs, you have more time to get the job IDs for the jobs that you want to cancel, and to send a <a>CancelJob</a> request. </p>
  ## 
  let valid = call_594278.validator(path, query, header, formData, body)
  let scheme = call_594278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594278.url(scheme.get, call_594278.host, call_594278.base,
                         call_594278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594278, url, valid)

proc call*(call_594279: Call_UpdatePipelineStatus_594266; Id: string; body: JsonNode): Recallable =
  ## updatePipelineStatus
  ## <p>The UpdatePipelineStatus operation pauses or reactivates a pipeline, so that the pipeline stops or restarts the processing of jobs.</p> <p>Changing the pipeline status is useful if you want to cancel one or more jobs. You can't cancel jobs after Elastic Transcoder has started processing them; if you pause the pipeline to which you submitted the jobs, you have more time to get the job IDs for the jobs that you want to cancel, and to send a <a>CancelJob</a> request. </p>
  ##   Id: string (required)
  ##     : The identifier of the pipeline to update.
  ##   body: JObject (required)
  var path_594280 = newJObject()
  var body_594281 = newJObject()
  add(path_594280, "Id", newJString(Id))
  if body != nil:
    body_594281 = body
  result = call_594279.call(path_594280, nil, nil, nil, body_594281)

var updatePipelineStatus* = Call_UpdatePipelineStatus_594266(
    name: "updatePipelineStatus", meth: HttpMethod.HttpPost,
    host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines/{Id}/status",
    validator: validate_UpdatePipelineStatus_594267, base: "/",
    url: url_UpdatePipelineStatus_594268, schemes: {Scheme.Https, Scheme.Http})
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
