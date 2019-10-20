
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
  Call_ReadJob_592703 = ref object of OpenApiRestCall_592364
proc url_ReadJob_592705(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ReadJob_592704(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592831 = path.getOrDefault("Id")
  valid_592831 = validateParameter(valid_592831, JString, required = true,
                                 default = nil)
  if valid_592831 != nil:
    section.add "Id", valid_592831
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
  var valid_592832 = header.getOrDefault("X-Amz-Signature")
  valid_592832 = validateParameter(valid_592832, JString, required = false,
                                 default = nil)
  if valid_592832 != nil:
    section.add "X-Amz-Signature", valid_592832
  var valid_592833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592833 = validateParameter(valid_592833, JString, required = false,
                                 default = nil)
  if valid_592833 != nil:
    section.add "X-Amz-Content-Sha256", valid_592833
  var valid_592834 = header.getOrDefault("X-Amz-Date")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "X-Amz-Date", valid_592834
  var valid_592835 = header.getOrDefault("X-Amz-Credential")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Credential", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Security-Token")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Security-Token", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-Algorithm")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-Algorithm", valid_592837
  var valid_592838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592838 = validateParameter(valid_592838, JString, required = false,
                                 default = nil)
  if valid_592838 != nil:
    section.add "X-Amz-SignedHeaders", valid_592838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592861: Call_ReadJob_592703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The ReadJob operation returns detailed information about a job.
  ## 
  let valid = call_592861.validator(path, query, header, formData, body)
  let scheme = call_592861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592861.url(scheme.get, call_592861.host, call_592861.base,
                         call_592861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592861, url, valid)

proc call*(call_592932: Call_ReadJob_592703; Id: string): Recallable =
  ## readJob
  ## The ReadJob operation returns detailed information about a job.
  ##   Id: string (required)
  ##     : The identifier of the job for which you want to get detailed information.
  var path_592933 = newJObject()
  add(path_592933, "Id", newJString(Id))
  result = call_592932.call(path_592933, nil, nil, nil, nil)

var readJob* = Call_ReadJob_592703(name: "readJob", meth: HttpMethod.HttpGet,
                                host: "elastictranscoder.amazonaws.com",
                                route: "/2012-09-25/jobs/{Id}",
                                validator: validate_ReadJob_592704, base: "/",
                                url: url_ReadJob_592705,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelJob_592973 = ref object of OpenApiRestCall_592364
proc url_CancelJob_592975(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CancelJob_592974(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592976 = path.getOrDefault("Id")
  valid_592976 = validateParameter(valid_592976, JString, required = true,
                                 default = nil)
  if valid_592976 != nil:
    section.add "Id", valid_592976
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
  var valid_592977 = header.getOrDefault("X-Amz-Signature")
  valid_592977 = validateParameter(valid_592977, JString, required = false,
                                 default = nil)
  if valid_592977 != nil:
    section.add "X-Amz-Signature", valid_592977
  var valid_592978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "X-Amz-Content-Sha256", valid_592978
  var valid_592979 = header.getOrDefault("X-Amz-Date")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Date", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Credential")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Credential", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Security-Token")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Security-Token", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-Algorithm")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-Algorithm", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-SignedHeaders", valid_592983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592984: Call_CancelJob_592973; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The CancelJob operation cancels an unfinished job.</p> <note> <p>You can only cancel a job that has a status of <code>Submitted</code>. To prevent a pipeline from starting to process a job while you're getting the job identifier, use <a>UpdatePipelineStatus</a> to temporarily pause the pipeline.</p> </note>
  ## 
  let valid = call_592984.validator(path, query, header, formData, body)
  let scheme = call_592984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592984.url(scheme.get, call_592984.host, call_592984.base,
                         call_592984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592984, url, valid)

proc call*(call_592985: Call_CancelJob_592973; Id: string): Recallable =
  ## cancelJob
  ## <p>The CancelJob operation cancels an unfinished job.</p> <note> <p>You can only cancel a job that has a status of <code>Submitted</code>. To prevent a pipeline from starting to process a job while you're getting the job identifier, use <a>UpdatePipelineStatus</a> to temporarily pause the pipeline.</p> </note>
  ##   Id: string (required)
  ##     : <p>The identifier of the job that you want to cancel.</p> <p>To get a list of the jobs (including their <code>jobId</code>) that have a status of <code>Submitted</code>, use the <a>ListJobsByStatus</a> API action.</p>
  var path_592986 = newJObject()
  add(path_592986, "Id", newJString(Id))
  result = call_592985.call(path_592986, nil, nil, nil, nil)

var cancelJob* = Call_CancelJob_592973(name: "cancelJob",
                                    meth: HttpMethod.HttpDelete,
                                    host: "elastictranscoder.amazonaws.com",
                                    route: "/2012-09-25/jobs/{Id}",
                                    validator: validate_CancelJob_592974,
                                    base: "/", url: url_CancelJob_592975,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_592987 = ref object of OpenApiRestCall_592364
proc url_CreateJob_592989(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateJob_592988(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592990 = header.getOrDefault("X-Amz-Signature")
  valid_592990 = validateParameter(valid_592990, JString, required = false,
                                 default = nil)
  if valid_592990 != nil:
    section.add "X-Amz-Signature", valid_592990
  var valid_592991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592991 = validateParameter(valid_592991, JString, required = false,
                                 default = nil)
  if valid_592991 != nil:
    section.add "X-Amz-Content-Sha256", valid_592991
  var valid_592992 = header.getOrDefault("X-Amz-Date")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "X-Amz-Date", valid_592992
  var valid_592993 = header.getOrDefault("X-Amz-Credential")
  valid_592993 = validateParameter(valid_592993, JString, required = false,
                                 default = nil)
  if valid_592993 != nil:
    section.add "X-Amz-Credential", valid_592993
  var valid_592994 = header.getOrDefault("X-Amz-Security-Token")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Security-Token", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-Algorithm")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Algorithm", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-SignedHeaders", valid_592996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592998: Call_CreateJob_592987; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>When you create a job, Elastic Transcoder returns JSON data that includes the values that you specified plus information about the job that is created.</p> <p>If you have specified more than one output for your jobs (for example, one output for the Kindle Fire and another output for the Apple iPhone 4s), you currently must use the Elastic Transcoder API to list the jobs (as opposed to the AWS Console).</p>
  ## 
  let valid = call_592998.validator(path, query, header, formData, body)
  let scheme = call_592998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592998.url(scheme.get, call_592998.host, call_592998.base,
                         call_592998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592998, url, valid)

proc call*(call_592999: Call_CreateJob_592987; body: JsonNode): Recallable =
  ## createJob
  ## <p>When you create a job, Elastic Transcoder returns JSON data that includes the values that you specified plus information about the job that is created.</p> <p>If you have specified more than one output for your jobs (for example, one output for the Kindle Fire and another output for the Apple iPhone 4s), you currently must use the Elastic Transcoder API to list the jobs (as opposed to the AWS Console).</p>
  ##   body: JObject (required)
  var body_593000 = newJObject()
  if body != nil:
    body_593000 = body
  result = call_592999.call(nil, nil, nil, nil, body_593000)

var createJob* = Call_CreateJob_592987(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "elastictranscoder.amazonaws.com",
                                    route: "/2012-09-25/jobs",
                                    validator: validate_CreateJob_592988,
                                    base: "/", url: url_CreateJob_592989,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePipeline_593016 = ref object of OpenApiRestCall_592364
proc url_CreatePipeline_593018(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePipeline_593017(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593019 = header.getOrDefault("X-Amz-Signature")
  valid_593019 = validateParameter(valid_593019, JString, required = false,
                                 default = nil)
  if valid_593019 != nil:
    section.add "X-Amz-Signature", valid_593019
  var valid_593020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = nil)
  if valid_593020 != nil:
    section.add "X-Amz-Content-Sha256", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-Date")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-Date", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-Credential")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Credential", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-Security-Token")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-Security-Token", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-Algorithm")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Algorithm", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-SignedHeaders", valid_593025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593027: Call_CreatePipeline_593016; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The CreatePipeline operation creates a pipeline with settings that you specify.
  ## 
  let valid = call_593027.validator(path, query, header, formData, body)
  let scheme = call_593027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593027.url(scheme.get, call_593027.host, call_593027.base,
                         call_593027.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593027, url, valid)

proc call*(call_593028: Call_CreatePipeline_593016; body: JsonNode): Recallable =
  ## createPipeline
  ## The CreatePipeline operation creates a pipeline with settings that you specify.
  ##   body: JObject (required)
  var body_593029 = newJObject()
  if body != nil:
    body_593029 = body
  result = call_593028.call(nil, nil, nil, nil, body_593029)

var createPipeline* = Call_CreatePipeline_593016(name: "createPipeline",
    meth: HttpMethod.HttpPost, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines", validator: validate_CreatePipeline_593017,
    base: "/", url: url_CreatePipeline_593018, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelines_593001 = ref object of OpenApiRestCall_592364
proc url_ListPipelines_593003(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPipelines_593002(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## The ListPipelines operation gets a list of the pipelines associated with the current AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Ascending: JString
  ##            : To list pipelines in chronological order by the date and time that they were created, enter <code>true</code>. To list pipelines in reverse chronological order, enter <code>false</code>.
  ##   PageToken: JString
  ##            : When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  section = newJObject()
  var valid_593004 = query.getOrDefault("Ascending")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "Ascending", valid_593004
  var valid_593005 = query.getOrDefault("PageToken")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "PageToken", valid_593005
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
  var valid_593006 = header.getOrDefault("X-Amz-Signature")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-Signature", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Content-Sha256", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-Date")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-Date", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-Credential")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-Credential", valid_593009
  var valid_593010 = header.getOrDefault("X-Amz-Security-Token")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Security-Token", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-Algorithm")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Algorithm", valid_593011
  var valid_593012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-SignedHeaders", valid_593012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593013: Call_ListPipelines_593001; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The ListPipelines operation gets a list of the pipelines associated with the current AWS account.
  ## 
  let valid = call_593013.validator(path, query, header, formData, body)
  let scheme = call_593013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593013.url(scheme.get, call_593013.host, call_593013.base,
                         call_593013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593013, url, valid)

proc call*(call_593014: Call_ListPipelines_593001; Ascending: string = "";
          PageToken: string = ""): Recallable =
  ## listPipelines
  ## The ListPipelines operation gets a list of the pipelines associated with the current AWS account.
  ##   Ascending: string
  ##            : To list pipelines in chronological order by the date and time that they were created, enter <code>true</code>. To list pipelines in reverse chronological order, enter <code>false</code>.
  ##   PageToken: string
  ##            : When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  var query_593015 = newJObject()
  add(query_593015, "Ascending", newJString(Ascending))
  add(query_593015, "PageToken", newJString(PageToken))
  result = call_593014.call(nil, query_593015, nil, nil, nil)

var listPipelines* = Call_ListPipelines_593001(name: "listPipelines",
    meth: HttpMethod.HttpGet, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines", validator: validate_ListPipelines_593002,
    base: "/", url: url_ListPipelines_593003, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePreset_593045 = ref object of OpenApiRestCall_592364
proc url_CreatePreset_593047(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePreset_593046(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593048 = header.getOrDefault("X-Amz-Signature")
  valid_593048 = validateParameter(valid_593048, JString, required = false,
                                 default = nil)
  if valid_593048 != nil:
    section.add "X-Amz-Signature", valid_593048
  var valid_593049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593049 = validateParameter(valid_593049, JString, required = false,
                                 default = nil)
  if valid_593049 != nil:
    section.add "X-Amz-Content-Sha256", valid_593049
  var valid_593050 = header.getOrDefault("X-Amz-Date")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = nil)
  if valid_593050 != nil:
    section.add "X-Amz-Date", valid_593050
  var valid_593051 = header.getOrDefault("X-Amz-Credential")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "X-Amz-Credential", valid_593051
  var valid_593052 = header.getOrDefault("X-Amz-Security-Token")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-Security-Token", valid_593052
  var valid_593053 = header.getOrDefault("X-Amz-Algorithm")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Algorithm", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-SignedHeaders", valid_593054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593056: Call_CreatePreset_593045; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The CreatePreset operation creates a preset with settings that you specify.</p> <important> <p>Elastic Transcoder checks the CreatePreset settings to ensure that they meet Elastic Transcoder requirements and to determine whether they comply with H.264 standards. If your settings are not valid for Elastic Transcoder, Elastic Transcoder returns an HTTP 400 response (<code>ValidationException</code>) and does not create the preset. If the settings are valid for Elastic Transcoder but aren't strictly compliant with the H.264 standard, Elastic Transcoder creates the preset and returns a warning message in the response. This helps you determine whether your settings comply with the H.264 standard while giving you greater flexibility with respect to the video that Elastic Transcoder produces.</p> </important> <p>Elastic Transcoder uses the H.264 video-compression format. For more information, see the International Telecommunication Union publication <i>Recommendation ITU-T H.264: Advanced video coding for generic audiovisual services</i>.</p>
  ## 
  let valid = call_593056.validator(path, query, header, formData, body)
  let scheme = call_593056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593056.url(scheme.get, call_593056.host, call_593056.base,
                         call_593056.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593056, url, valid)

proc call*(call_593057: Call_CreatePreset_593045; body: JsonNode): Recallable =
  ## createPreset
  ## <p>The CreatePreset operation creates a preset with settings that you specify.</p> <important> <p>Elastic Transcoder checks the CreatePreset settings to ensure that they meet Elastic Transcoder requirements and to determine whether they comply with H.264 standards. If your settings are not valid for Elastic Transcoder, Elastic Transcoder returns an HTTP 400 response (<code>ValidationException</code>) and does not create the preset. If the settings are valid for Elastic Transcoder but aren't strictly compliant with the H.264 standard, Elastic Transcoder creates the preset and returns a warning message in the response. This helps you determine whether your settings comply with the H.264 standard while giving you greater flexibility with respect to the video that Elastic Transcoder produces.</p> </important> <p>Elastic Transcoder uses the H.264 video-compression format. For more information, see the International Telecommunication Union publication <i>Recommendation ITU-T H.264: Advanced video coding for generic audiovisual services</i>.</p>
  ##   body: JObject (required)
  var body_593058 = newJObject()
  if body != nil:
    body_593058 = body
  result = call_593057.call(nil, nil, nil, nil, body_593058)

var createPreset* = Call_CreatePreset_593045(name: "createPreset",
    meth: HttpMethod.HttpPost, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/presets", validator: validate_CreatePreset_593046,
    base: "/", url: url_CreatePreset_593047, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPresets_593030 = ref object of OpenApiRestCall_592364
proc url_ListPresets_593032(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPresets_593031(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## The ListPresets operation gets a list of the default presets included with Elastic Transcoder and the presets that you've added in an AWS region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Ascending: JString
  ##            : To list presets in chronological order by the date and time that they were created, enter <code>true</code>. To list presets in reverse chronological order, enter <code>false</code>.
  ##   PageToken: JString
  ##            : When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  section = newJObject()
  var valid_593033 = query.getOrDefault("Ascending")
  valid_593033 = validateParameter(valid_593033, JString, required = false,
                                 default = nil)
  if valid_593033 != nil:
    section.add "Ascending", valid_593033
  var valid_593034 = query.getOrDefault("PageToken")
  valid_593034 = validateParameter(valid_593034, JString, required = false,
                                 default = nil)
  if valid_593034 != nil:
    section.add "PageToken", valid_593034
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
  var valid_593035 = header.getOrDefault("X-Amz-Signature")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "X-Amz-Signature", valid_593035
  var valid_593036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-Content-Sha256", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-Date")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Date", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-Credential")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Credential", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Security-Token")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Security-Token", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Algorithm")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Algorithm", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-SignedHeaders", valid_593041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593042: Call_ListPresets_593030; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The ListPresets operation gets a list of the default presets included with Elastic Transcoder and the presets that you've added in an AWS region.
  ## 
  let valid = call_593042.validator(path, query, header, formData, body)
  let scheme = call_593042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593042.url(scheme.get, call_593042.host, call_593042.base,
                         call_593042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593042, url, valid)

proc call*(call_593043: Call_ListPresets_593030; Ascending: string = "";
          PageToken: string = ""): Recallable =
  ## listPresets
  ## The ListPresets operation gets a list of the default presets included with Elastic Transcoder and the presets that you've added in an AWS region.
  ##   Ascending: string
  ##            : To list presets in chronological order by the date and time that they were created, enter <code>true</code>. To list presets in reverse chronological order, enter <code>false</code>.
  ##   PageToken: string
  ##            : When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  var query_593044 = newJObject()
  add(query_593044, "Ascending", newJString(Ascending))
  add(query_593044, "PageToken", newJString(PageToken))
  result = call_593043.call(nil, query_593044, nil, nil, nil)

var listPresets* = Call_ListPresets_593030(name: "listPresets",
                                        meth: HttpMethod.HttpGet, host: "elastictranscoder.amazonaws.com",
                                        route: "/2012-09-25/presets",
                                        validator: validate_ListPresets_593031,
                                        base: "/", url: url_ListPresets_593032,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipeline_593073 = ref object of OpenApiRestCall_592364
proc url_UpdatePipeline_593075(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePipeline_593074(path: JsonNode; query: JsonNode;
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
  var valid_593076 = path.getOrDefault("Id")
  valid_593076 = validateParameter(valid_593076, JString, required = true,
                                 default = nil)
  if valid_593076 != nil:
    section.add "Id", valid_593076
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
  var valid_593077 = header.getOrDefault("X-Amz-Signature")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-Signature", valid_593077
  var valid_593078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "X-Amz-Content-Sha256", valid_593078
  var valid_593079 = header.getOrDefault("X-Amz-Date")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "X-Amz-Date", valid_593079
  var valid_593080 = header.getOrDefault("X-Amz-Credential")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "X-Amz-Credential", valid_593080
  var valid_593081 = header.getOrDefault("X-Amz-Security-Token")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "X-Amz-Security-Token", valid_593081
  var valid_593082 = header.getOrDefault("X-Amz-Algorithm")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "X-Amz-Algorithm", valid_593082
  var valid_593083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593083 = validateParameter(valid_593083, JString, required = false,
                                 default = nil)
  if valid_593083 != nil:
    section.add "X-Amz-SignedHeaders", valid_593083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593085: Call_UpdatePipeline_593073; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Use the <code>UpdatePipeline</code> operation to update settings for a pipeline.</p> <important> <p>When you change pipeline settings, your changes take effect immediately. Jobs that you have already submitted and that Elastic Transcoder has not started to process are affected in addition to jobs that you submit after you change settings. </p> </important>
  ## 
  let valid = call_593085.validator(path, query, header, formData, body)
  let scheme = call_593085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593085.url(scheme.get, call_593085.host, call_593085.base,
                         call_593085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593085, url, valid)

proc call*(call_593086: Call_UpdatePipeline_593073; body: JsonNode; Id: string): Recallable =
  ## updatePipeline
  ## <p> Use the <code>UpdatePipeline</code> operation to update settings for a pipeline.</p> <important> <p>When you change pipeline settings, your changes take effect immediately. Jobs that you have already submitted and that Elastic Transcoder has not started to process are affected in addition to jobs that you submit after you change settings. </p> </important>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID of the pipeline that you want to update.
  var path_593087 = newJObject()
  var body_593088 = newJObject()
  if body != nil:
    body_593088 = body
  add(path_593087, "Id", newJString(Id))
  result = call_593086.call(path_593087, nil, nil, nil, body_593088)

var updatePipeline* = Call_UpdatePipeline_593073(name: "updatePipeline",
    meth: HttpMethod.HttpPut, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines/{Id}", validator: validate_UpdatePipeline_593074,
    base: "/", url: url_UpdatePipeline_593075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReadPipeline_593059 = ref object of OpenApiRestCall_592364
proc url_ReadPipeline_593061(protocol: Scheme; host: string; base: string;
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

proc validate_ReadPipeline_593060(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593062 = path.getOrDefault("Id")
  valid_593062 = validateParameter(valid_593062, JString, required = true,
                                 default = nil)
  if valid_593062 != nil:
    section.add "Id", valid_593062
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
  var valid_593063 = header.getOrDefault("X-Amz-Signature")
  valid_593063 = validateParameter(valid_593063, JString, required = false,
                                 default = nil)
  if valid_593063 != nil:
    section.add "X-Amz-Signature", valid_593063
  var valid_593064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593064 = validateParameter(valid_593064, JString, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "X-Amz-Content-Sha256", valid_593064
  var valid_593065 = header.getOrDefault("X-Amz-Date")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-Date", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-Credential")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-Credential", valid_593066
  var valid_593067 = header.getOrDefault("X-Amz-Security-Token")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-Security-Token", valid_593067
  var valid_593068 = header.getOrDefault("X-Amz-Algorithm")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-Algorithm", valid_593068
  var valid_593069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "X-Amz-SignedHeaders", valid_593069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593070: Call_ReadPipeline_593059; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The ReadPipeline operation gets detailed information about a pipeline.
  ## 
  let valid = call_593070.validator(path, query, header, formData, body)
  let scheme = call_593070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593070.url(scheme.get, call_593070.host, call_593070.base,
                         call_593070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593070, url, valid)

proc call*(call_593071: Call_ReadPipeline_593059; Id: string): Recallable =
  ## readPipeline
  ## The ReadPipeline operation gets detailed information about a pipeline.
  ##   Id: string (required)
  ##     : The identifier of the pipeline to read.
  var path_593072 = newJObject()
  add(path_593072, "Id", newJString(Id))
  result = call_593071.call(path_593072, nil, nil, nil, nil)

var readPipeline* = Call_ReadPipeline_593059(name: "readPipeline",
    meth: HttpMethod.HttpGet, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines/{Id}", validator: validate_ReadPipeline_593060,
    base: "/", url: url_ReadPipeline_593061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePipeline_593089 = ref object of OpenApiRestCall_592364
proc url_DeletePipeline_593091(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePipeline_593090(path: JsonNode; query: JsonNode;
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
  var valid_593092 = path.getOrDefault("Id")
  valid_593092 = validateParameter(valid_593092, JString, required = true,
                                 default = nil)
  if valid_593092 != nil:
    section.add "Id", valid_593092
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
  var valid_593093 = header.getOrDefault("X-Amz-Signature")
  valid_593093 = validateParameter(valid_593093, JString, required = false,
                                 default = nil)
  if valid_593093 != nil:
    section.add "X-Amz-Signature", valid_593093
  var valid_593094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593094 = validateParameter(valid_593094, JString, required = false,
                                 default = nil)
  if valid_593094 != nil:
    section.add "X-Amz-Content-Sha256", valid_593094
  var valid_593095 = header.getOrDefault("X-Amz-Date")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "X-Amz-Date", valid_593095
  var valid_593096 = header.getOrDefault("X-Amz-Credential")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "X-Amz-Credential", valid_593096
  var valid_593097 = header.getOrDefault("X-Amz-Security-Token")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "X-Amz-Security-Token", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-Algorithm")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-Algorithm", valid_593098
  var valid_593099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "X-Amz-SignedHeaders", valid_593099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593100: Call_DeletePipeline_593089; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The DeletePipeline operation removes a pipeline.</p> <p> You can only delete a pipeline that has never been used or that is not currently in use (doesn't contain any active jobs). If the pipeline is currently in use, <code>DeletePipeline</code> returns an error. </p>
  ## 
  let valid = call_593100.validator(path, query, header, formData, body)
  let scheme = call_593100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593100.url(scheme.get, call_593100.host, call_593100.base,
                         call_593100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593100, url, valid)

proc call*(call_593101: Call_DeletePipeline_593089; Id: string): Recallable =
  ## deletePipeline
  ## <p>The DeletePipeline operation removes a pipeline.</p> <p> You can only delete a pipeline that has never been used or that is not currently in use (doesn't contain any active jobs). If the pipeline is currently in use, <code>DeletePipeline</code> returns an error. </p>
  ##   Id: string (required)
  ##     : The identifier of the pipeline that you want to delete.
  var path_593102 = newJObject()
  add(path_593102, "Id", newJString(Id))
  result = call_593101.call(path_593102, nil, nil, nil, nil)

var deletePipeline* = Call_DeletePipeline_593089(name: "deletePipeline",
    meth: HttpMethod.HttpDelete, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines/{Id}", validator: validate_DeletePipeline_593090,
    base: "/", url: url_DeletePipeline_593091, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReadPreset_593103 = ref object of OpenApiRestCall_592364
proc url_ReadPreset_593105(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ReadPreset_593104(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593106 = path.getOrDefault("Id")
  valid_593106 = validateParameter(valid_593106, JString, required = true,
                                 default = nil)
  if valid_593106 != nil:
    section.add "Id", valid_593106
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
  var valid_593107 = header.getOrDefault("X-Amz-Signature")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "X-Amz-Signature", valid_593107
  var valid_593108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593108 = validateParameter(valid_593108, JString, required = false,
                                 default = nil)
  if valid_593108 != nil:
    section.add "X-Amz-Content-Sha256", valid_593108
  var valid_593109 = header.getOrDefault("X-Amz-Date")
  valid_593109 = validateParameter(valid_593109, JString, required = false,
                                 default = nil)
  if valid_593109 != nil:
    section.add "X-Amz-Date", valid_593109
  var valid_593110 = header.getOrDefault("X-Amz-Credential")
  valid_593110 = validateParameter(valid_593110, JString, required = false,
                                 default = nil)
  if valid_593110 != nil:
    section.add "X-Amz-Credential", valid_593110
  var valid_593111 = header.getOrDefault("X-Amz-Security-Token")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "X-Amz-Security-Token", valid_593111
  var valid_593112 = header.getOrDefault("X-Amz-Algorithm")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "X-Amz-Algorithm", valid_593112
  var valid_593113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593113 = validateParameter(valid_593113, JString, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "X-Amz-SignedHeaders", valid_593113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593114: Call_ReadPreset_593103; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The ReadPreset operation gets detailed information about a preset.
  ## 
  let valid = call_593114.validator(path, query, header, formData, body)
  let scheme = call_593114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593114.url(scheme.get, call_593114.host, call_593114.base,
                         call_593114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593114, url, valid)

proc call*(call_593115: Call_ReadPreset_593103; Id: string): Recallable =
  ## readPreset
  ## The ReadPreset operation gets detailed information about a preset.
  ##   Id: string (required)
  ##     : The identifier of the preset for which you want to get detailed information.
  var path_593116 = newJObject()
  add(path_593116, "Id", newJString(Id))
  result = call_593115.call(path_593116, nil, nil, nil, nil)

var readPreset* = Call_ReadPreset_593103(name: "readPreset",
                                      meth: HttpMethod.HttpGet,
                                      host: "elastictranscoder.amazonaws.com",
                                      route: "/2012-09-25/presets/{Id}",
                                      validator: validate_ReadPreset_593104,
                                      base: "/", url: url_ReadPreset_593105,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePreset_593117 = ref object of OpenApiRestCall_592364
proc url_DeletePreset_593119(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePreset_593118(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593120 = path.getOrDefault("Id")
  valid_593120 = validateParameter(valid_593120, JString, required = true,
                                 default = nil)
  if valid_593120 != nil:
    section.add "Id", valid_593120
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
  var valid_593121 = header.getOrDefault("X-Amz-Signature")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "X-Amz-Signature", valid_593121
  var valid_593122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "X-Amz-Content-Sha256", valid_593122
  var valid_593123 = header.getOrDefault("X-Amz-Date")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-Date", valid_593123
  var valid_593124 = header.getOrDefault("X-Amz-Credential")
  valid_593124 = validateParameter(valid_593124, JString, required = false,
                                 default = nil)
  if valid_593124 != nil:
    section.add "X-Amz-Credential", valid_593124
  var valid_593125 = header.getOrDefault("X-Amz-Security-Token")
  valid_593125 = validateParameter(valid_593125, JString, required = false,
                                 default = nil)
  if valid_593125 != nil:
    section.add "X-Amz-Security-Token", valid_593125
  var valid_593126 = header.getOrDefault("X-Amz-Algorithm")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-Algorithm", valid_593126
  var valid_593127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-SignedHeaders", valid_593127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593128: Call_DeletePreset_593117; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The DeletePreset operation removes a preset that you've added in an AWS region.</p> <note> <p>You can't delete the default presets that are included with Elastic Transcoder.</p> </note>
  ## 
  let valid = call_593128.validator(path, query, header, formData, body)
  let scheme = call_593128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593128.url(scheme.get, call_593128.host, call_593128.base,
                         call_593128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593128, url, valid)

proc call*(call_593129: Call_DeletePreset_593117; Id: string): Recallable =
  ## deletePreset
  ## <p>The DeletePreset operation removes a preset that you've added in an AWS region.</p> <note> <p>You can't delete the default presets that are included with Elastic Transcoder.</p> </note>
  ##   Id: string (required)
  ##     : The identifier of the preset for which you want to get detailed information.
  var path_593130 = newJObject()
  add(path_593130, "Id", newJString(Id))
  result = call_593129.call(path_593130, nil, nil, nil, nil)

var deletePreset* = Call_DeletePreset_593117(name: "deletePreset",
    meth: HttpMethod.HttpDelete, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/presets/{Id}", validator: validate_DeletePreset_593118,
    base: "/", url: url_DeletePreset_593119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobsByPipeline_593131 = ref object of OpenApiRestCall_592364
proc url_ListJobsByPipeline_593133(protocol: Scheme; host: string; base: string;
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

proc validate_ListJobsByPipeline_593132(path: JsonNode; query: JsonNode;
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
  var valid_593134 = path.getOrDefault("PipelineId")
  valid_593134 = validateParameter(valid_593134, JString, required = true,
                                 default = nil)
  if valid_593134 != nil:
    section.add "PipelineId", valid_593134
  result.add "path", section
  ## parameters in `query` object:
  ##   Ascending: JString
  ##            :  To list jobs in chronological order by the date and time that they were submitted, enter <code>true</code>. To list jobs in reverse chronological order, enter <code>false</code>. 
  ##   PageToken: JString
  ##            :  When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  section = newJObject()
  var valid_593135 = query.getOrDefault("Ascending")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "Ascending", valid_593135
  var valid_593136 = query.getOrDefault("PageToken")
  valid_593136 = validateParameter(valid_593136, JString, required = false,
                                 default = nil)
  if valid_593136 != nil:
    section.add "PageToken", valid_593136
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
  var valid_593137 = header.getOrDefault("X-Amz-Signature")
  valid_593137 = validateParameter(valid_593137, JString, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "X-Amz-Signature", valid_593137
  var valid_593138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-Content-Sha256", valid_593138
  var valid_593139 = header.getOrDefault("X-Amz-Date")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "X-Amz-Date", valid_593139
  var valid_593140 = header.getOrDefault("X-Amz-Credential")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-Credential", valid_593140
  var valid_593141 = header.getOrDefault("X-Amz-Security-Token")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-Security-Token", valid_593141
  var valid_593142 = header.getOrDefault("X-Amz-Algorithm")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-Algorithm", valid_593142
  var valid_593143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-SignedHeaders", valid_593143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593144: Call_ListJobsByPipeline_593131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The ListJobsByPipeline operation gets a list of the jobs currently in a pipeline.</p> <p>Elastic Transcoder returns all of the jobs currently in the specified pipeline. The response body contains one element for each job that satisfies the search criteria.</p>
  ## 
  let valid = call_593144.validator(path, query, header, formData, body)
  let scheme = call_593144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593144.url(scheme.get, call_593144.host, call_593144.base,
                         call_593144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593144, url, valid)

proc call*(call_593145: Call_ListJobsByPipeline_593131; PipelineId: string;
          Ascending: string = ""; PageToken: string = ""): Recallable =
  ## listJobsByPipeline
  ## <p>The ListJobsByPipeline operation gets a list of the jobs currently in a pipeline.</p> <p>Elastic Transcoder returns all of the jobs currently in the specified pipeline. The response body contains one element for each job that satisfies the search criteria.</p>
  ##   PipelineId: string (required)
  ##             : The ID of the pipeline for which you want to get job information.
  ##   Ascending: string
  ##            :  To list jobs in chronological order by the date and time that they were submitted, enter <code>true</code>. To list jobs in reverse chronological order, enter <code>false</code>. 
  ##   PageToken: string
  ##            :  When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  var path_593146 = newJObject()
  var query_593147 = newJObject()
  add(path_593146, "PipelineId", newJString(PipelineId))
  add(query_593147, "Ascending", newJString(Ascending))
  add(query_593147, "PageToken", newJString(PageToken))
  result = call_593145.call(path_593146, query_593147, nil, nil, nil)

var listJobsByPipeline* = Call_ListJobsByPipeline_593131(
    name: "listJobsByPipeline", meth: HttpMethod.HttpGet,
    host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/jobsByPipeline/{PipelineId}",
    validator: validate_ListJobsByPipeline_593132, base: "/",
    url: url_ListJobsByPipeline_593133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobsByStatus_593148 = ref object of OpenApiRestCall_592364
proc url_ListJobsByStatus_593150(protocol: Scheme; host: string; base: string;
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

proc validate_ListJobsByStatus_593149(path: JsonNode; query: JsonNode;
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
  var valid_593151 = path.getOrDefault("Status")
  valid_593151 = validateParameter(valid_593151, JString, required = true,
                                 default = nil)
  if valid_593151 != nil:
    section.add "Status", valid_593151
  result.add "path", section
  ## parameters in `query` object:
  ##   Ascending: JString
  ##            :  To list jobs in chronological order by the date and time that they were submitted, enter <code>true</code>. To list jobs in reverse chronological order, enter <code>false</code>. 
  ##   PageToken: JString
  ##            :  When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  section = newJObject()
  var valid_593152 = query.getOrDefault("Ascending")
  valid_593152 = validateParameter(valid_593152, JString, required = false,
                                 default = nil)
  if valid_593152 != nil:
    section.add "Ascending", valid_593152
  var valid_593153 = query.getOrDefault("PageToken")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "PageToken", valid_593153
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
  var valid_593154 = header.getOrDefault("X-Amz-Signature")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "X-Amz-Signature", valid_593154
  var valid_593155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "X-Amz-Content-Sha256", valid_593155
  var valid_593156 = header.getOrDefault("X-Amz-Date")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "X-Amz-Date", valid_593156
  var valid_593157 = header.getOrDefault("X-Amz-Credential")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-Credential", valid_593157
  var valid_593158 = header.getOrDefault("X-Amz-Security-Token")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-Security-Token", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-Algorithm")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-Algorithm", valid_593159
  var valid_593160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593160 = validateParameter(valid_593160, JString, required = false,
                                 default = nil)
  if valid_593160 != nil:
    section.add "X-Amz-SignedHeaders", valid_593160
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593161: Call_ListJobsByStatus_593148; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The ListJobsByStatus operation gets a list of jobs that have a specified status. The response body contains one element for each job that satisfies the search criteria.
  ## 
  let valid = call_593161.validator(path, query, header, formData, body)
  let scheme = call_593161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593161.url(scheme.get, call_593161.host, call_593161.base,
                         call_593161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593161, url, valid)

proc call*(call_593162: Call_ListJobsByStatus_593148; Status: string;
          Ascending: string = ""; PageToken: string = ""): Recallable =
  ## listJobsByStatus
  ## The ListJobsByStatus operation gets a list of jobs that have a specified status. The response body contains one element for each job that satisfies the search criteria.
  ##   Ascending: string
  ##            :  To list jobs in chronological order by the date and time that they were submitted, enter <code>true</code>. To list jobs in reverse chronological order, enter <code>false</code>. 
  ##   PageToken: string
  ##            :  When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  ##   Status: string (required)
  ##         : To get information about all of the jobs associated with the current AWS account that have a given status, specify the following status: <code>Submitted</code>, <code>Progressing</code>, <code>Complete</code>, <code>Canceled</code>, or <code>Error</code>.
  var path_593163 = newJObject()
  var query_593164 = newJObject()
  add(query_593164, "Ascending", newJString(Ascending))
  add(query_593164, "PageToken", newJString(PageToken))
  add(path_593163, "Status", newJString(Status))
  result = call_593162.call(path_593163, query_593164, nil, nil, nil)

var listJobsByStatus* = Call_ListJobsByStatus_593148(name: "listJobsByStatus",
    meth: HttpMethod.HttpGet, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/jobsByStatus/{Status}",
    validator: validate_ListJobsByStatus_593149, base: "/",
    url: url_ListJobsByStatus_593150, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestRole_593165 = ref object of OpenApiRestCall_592364
proc url_TestRole_593167(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TestRole_593166(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593168 = header.getOrDefault("X-Amz-Signature")
  valid_593168 = validateParameter(valid_593168, JString, required = false,
                                 default = nil)
  if valid_593168 != nil:
    section.add "X-Amz-Signature", valid_593168
  var valid_593169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593169 = validateParameter(valid_593169, JString, required = false,
                                 default = nil)
  if valid_593169 != nil:
    section.add "X-Amz-Content-Sha256", valid_593169
  var valid_593170 = header.getOrDefault("X-Amz-Date")
  valid_593170 = validateParameter(valid_593170, JString, required = false,
                                 default = nil)
  if valid_593170 != nil:
    section.add "X-Amz-Date", valid_593170
  var valid_593171 = header.getOrDefault("X-Amz-Credential")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "X-Amz-Credential", valid_593171
  var valid_593172 = header.getOrDefault("X-Amz-Security-Token")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "X-Amz-Security-Token", valid_593172
  var valid_593173 = header.getOrDefault("X-Amz-Algorithm")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-Algorithm", valid_593173
  var valid_593174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "X-Amz-SignedHeaders", valid_593174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593176: Call_TestRole_593165; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The TestRole operation tests the IAM role used to create the pipeline.</p> <p>The <code>TestRole</code> action lets you determine whether the IAM role you are using has sufficient permissions to let Elastic Transcoder perform tasks associated with the transcoding process. The action attempts to assume the specified IAM role, checks read access to the input and output buckets, and tries to send a test notification to Amazon SNS topics that you specify.</p>
  ## 
  let valid = call_593176.validator(path, query, header, formData, body)
  let scheme = call_593176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593176.url(scheme.get, call_593176.host, call_593176.base,
                         call_593176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593176, url, valid)

proc call*(call_593177: Call_TestRole_593165; body: JsonNode): Recallable =
  ## testRole
  ## <p>The TestRole operation tests the IAM role used to create the pipeline.</p> <p>The <code>TestRole</code> action lets you determine whether the IAM role you are using has sufficient permissions to let Elastic Transcoder perform tasks associated with the transcoding process. The action attempts to assume the specified IAM role, checks read access to the input and output buckets, and tries to send a test notification to Amazon SNS topics that you specify.</p>
  ##   body: JObject (required)
  var body_593178 = newJObject()
  if body != nil:
    body_593178 = body
  result = call_593177.call(nil, nil, nil, nil, body_593178)

var testRole* = Call_TestRole_593165(name: "testRole", meth: HttpMethod.HttpPost,
                                  host: "elastictranscoder.amazonaws.com",
                                  route: "/2012-09-25/roleTests",
                                  validator: validate_TestRole_593166, base: "/",
                                  url: url_TestRole_593167,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipelineNotifications_593179 = ref object of OpenApiRestCall_592364
proc url_UpdatePipelineNotifications_593181(protocol: Scheme; host: string;
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

proc validate_UpdatePipelineNotifications_593180(path: JsonNode; query: JsonNode;
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
  var valid_593182 = path.getOrDefault("Id")
  valid_593182 = validateParameter(valid_593182, JString, required = true,
                                 default = nil)
  if valid_593182 != nil:
    section.add "Id", valid_593182
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593191: Call_UpdatePipelineNotifications_593179; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>With the UpdatePipelineNotifications operation, you can update Amazon Simple Notification Service (Amazon SNS) notifications for a pipeline.</p> <p>When you update notifications for a pipeline, Elastic Transcoder returns the values that you specified in the request.</p>
  ## 
  let valid = call_593191.validator(path, query, header, formData, body)
  let scheme = call_593191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593191.url(scheme.get, call_593191.host, call_593191.base,
                         call_593191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593191, url, valid)

proc call*(call_593192: Call_UpdatePipelineNotifications_593179; body: JsonNode;
          Id: string): Recallable =
  ## updatePipelineNotifications
  ## <p>With the UpdatePipelineNotifications operation, you can update Amazon Simple Notification Service (Amazon SNS) notifications for a pipeline.</p> <p>When you update notifications for a pipeline, Elastic Transcoder returns the values that you specified in the request.</p>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The identifier of the pipeline for which you want to change notification settings.
  var path_593193 = newJObject()
  var body_593194 = newJObject()
  if body != nil:
    body_593194 = body
  add(path_593193, "Id", newJString(Id))
  result = call_593192.call(path_593193, nil, nil, nil, body_593194)

var updatePipelineNotifications* = Call_UpdatePipelineNotifications_593179(
    name: "updatePipelineNotifications", meth: HttpMethod.HttpPost,
    host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines/{Id}/notifications",
    validator: validate_UpdatePipelineNotifications_593180, base: "/",
    url: url_UpdatePipelineNotifications_593181,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipelineStatus_593195 = ref object of OpenApiRestCall_592364
proc url_UpdatePipelineStatus_593197(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePipelineStatus_593196(path: JsonNode; query: JsonNode;
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
  var valid_593198 = path.getOrDefault("Id")
  valid_593198 = validateParameter(valid_593198, JString, required = true,
                                 default = nil)
  if valid_593198 != nil:
    section.add "Id", valid_593198
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
  var valid_593199 = header.getOrDefault("X-Amz-Signature")
  valid_593199 = validateParameter(valid_593199, JString, required = false,
                                 default = nil)
  if valid_593199 != nil:
    section.add "X-Amz-Signature", valid_593199
  var valid_593200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593200 = validateParameter(valid_593200, JString, required = false,
                                 default = nil)
  if valid_593200 != nil:
    section.add "X-Amz-Content-Sha256", valid_593200
  var valid_593201 = header.getOrDefault("X-Amz-Date")
  valid_593201 = validateParameter(valid_593201, JString, required = false,
                                 default = nil)
  if valid_593201 != nil:
    section.add "X-Amz-Date", valid_593201
  var valid_593202 = header.getOrDefault("X-Amz-Credential")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-Credential", valid_593202
  var valid_593203 = header.getOrDefault("X-Amz-Security-Token")
  valid_593203 = validateParameter(valid_593203, JString, required = false,
                                 default = nil)
  if valid_593203 != nil:
    section.add "X-Amz-Security-Token", valid_593203
  var valid_593204 = header.getOrDefault("X-Amz-Algorithm")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "X-Amz-Algorithm", valid_593204
  var valid_593205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-SignedHeaders", valid_593205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593207: Call_UpdatePipelineStatus_593195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The UpdatePipelineStatus operation pauses or reactivates a pipeline, so that the pipeline stops or restarts the processing of jobs.</p> <p>Changing the pipeline status is useful if you want to cancel one or more jobs. You can't cancel jobs after Elastic Transcoder has started processing them; if you pause the pipeline to which you submitted the jobs, you have more time to get the job IDs for the jobs that you want to cancel, and to send a <a>CancelJob</a> request. </p>
  ## 
  let valid = call_593207.validator(path, query, header, formData, body)
  let scheme = call_593207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593207.url(scheme.get, call_593207.host, call_593207.base,
                         call_593207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593207, url, valid)

proc call*(call_593208: Call_UpdatePipelineStatus_593195; body: JsonNode; Id: string): Recallable =
  ## updatePipelineStatus
  ## <p>The UpdatePipelineStatus operation pauses or reactivates a pipeline, so that the pipeline stops or restarts the processing of jobs.</p> <p>Changing the pipeline status is useful if you want to cancel one or more jobs. You can't cancel jobs after Elastic Transcoder has started processing them; if you pause the pipeline to which you submitted the jobs, you have more time to get the job IDs for the jobs that you want to cancel, and to send a <a>CancelJob</a> request. </p>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The identifier of the pipeline to update.
  var path_593209 = newJObject()
  var body_593210 = newJObject()
  if body != nil:
    body_593210 = body
  add(path_593209, "Id", newJString(Id))
  result = call_593208.call(path_593209, nil, nil, nil, body_593210)

var updatePipelineStatus* = Call_UpdatePipelineStatus_593195(
    name: "updatePipelineStatus", meth: HttpMethod.HttpPost,
    host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines/{Id}/status",
    validator: validate_UpdatePipelineStatus_593196, base: "/",
    url: url_UpdatePipelineStatus_593197, schemes: {Scheme.Https, Scheme.Http})
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
