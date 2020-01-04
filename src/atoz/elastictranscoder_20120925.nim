
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
  Call_ReadJob_601727 = ref object of OpenApiRestCall_601389
proc url_ReadJob_601729(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ReadJob_601728(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601855 = path.getOrDefault("Id")
  valid_601855 = validateParameter(valid_601855, JString, required = true,
                                 default = nil)
  if valid_601855 != nil:
    section.add "Id", valid_601855
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
  var valid_601856 = header.getOrDefault("X-Amz-Signature")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Signature", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Content-Sha256", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Date")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Date", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Credential")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Credential", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Security-Token")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Security-Token", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Algorithm")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Algorithm", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-SignedHeaders", valid_601862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601885: Call_ReadJob_601727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The ReadJob operation returns detailed information about a job.
  ## 
  let valid = call_601885.validator(path, query, header, formData, body)
  let scheme = call_601885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601885.url(scheme.get, call_601885.host, call_601885.base,
                         call_601885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601885, url, valid)

proc call*(call_601956: Call_ReadJob_601727; Id: string): Recallable =
  ## readJob
  ## The ReadJob operation returns detailed information about a job.
  ##   Id: string (required)
  ##     : The identifier of the job for which you want to get detailed information.
  var path_601957 = newJObject()
  add(path_601957, "Id", newJString(Id))
  result = call_601956.call(path_601957, nil, nil, nil, nil)

var readJob* = Call_ReadJob_601727(name: "readJob", meth: HttpMethod.HttpGet,
                                host: "elastictranscoder.amazonaws.com",
                                route: "/2012-09-25/jobs/{Id}",
                                validator: validate_ReadJob_601728, base: "/",
                                url: url_ReadJob_601729,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelJob_601997 = ref object of OpenApiRestCall_601389
proc url_CancelJob_601999(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CancelJob_601998(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602000 = path.getOrDefault("Id")
  valid_602000 = validateParameter(valid_602000, JString, required = true,
                                 default = nil)
  if valid_602000 != nil:
    section.add "Id", valid_602000
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
  var valid_602001 = header.getOrDefault("X-Amz-Signature")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Signature", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Content-Sha256", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Date")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Date", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Credential")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Credential", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Security-Token")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Security-Token", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Algorithm")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Algorithm", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-SignedHeaders", valid_602007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602008: Call_CancelJob_601997; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The CancelJob operation cancels an unfinished job.</p> <note> <p>You can only cancel a job that has a status of <code>Submitted</code>. To prevent a pipeline from starting to process a job while you're getting the job identifier, use <a>UpdatePipelineStatus</a> to temporarily pause the pipeline.</p> </note>
  ## 
  let valid = call_602008.validator(path, query, header, formData, body)
  let scheme = call_602008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602008.url(scheme.get, call_602008.host, call_602008.base,
                         call_602008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602008, url, valid)

proc call*(call_602009: Call_CancelJob_601997; Id: string): Recallable =
  ## cancelJob
  ## <p>The CancelJob operation cancels an unfinished job.</p> <note> <p>You can only cancel a job that has a status of <code>Submitted</code>. To prevent a pipeline from starting to process a job while you're getting the job identifier, use <a>UpdatePipelineStatus</a> to temporarily pause the pipeline.</p> </note>
  ##   Id: string (required)
  ##     : <p>The identifier of the job that you want to cancel.</p> <p>To get a list of the jobs (including their <code>jobId</code>) that have a status of <code>Submitted</code>, use the <a>ListJobsByStatus</a> API action.</p>
  var path_602010 = newJObject()
  add(path_602010, "Id", newJString(Id))
  result = call_602009.call(path_602010, nil, nil, nil, nil)

var cancelJob* = Call_CancelJob_601997(name: "cancelJob",
                                    meth: HttpMethod.HttpDelete,
                                    host: "elastictranscoder.amazonaws.com",
                                    route: "/2012-09-25/jobs/{Id}",
                                    validator: validate_CancelJob_601998,
                                    base: "/", url: url_CancelJob_601999,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_602011 = ref object of OpenApiRestCall_601389
proc url_CreateJob_602013(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateJob_602012(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602014 = header.getOrDefault("X-Amz-Signature")
  valid_602014 = validateParameter(valid_602014, JString, required = false,
                                 default = nil)
  if valid_602014 != nil:
    section.add "X-Amz-Signature", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Content-Sha256", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Date")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Date", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Credential")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Credential", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Security-Token")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Security-Token", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Algorithm")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Algorithm", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-SignedHeaders", valid_602020
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602022: Call_CreateJob_602011; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>When you create a job, Elastic Transcoder returns JSON data that includes the values that you specified plus information about the job that is created.</p> <p>If you have specified more than one output for your jobs (for example, one output for the Kindle Fire and another output for the Apple iPhone 4s), you currently must use the Elastic Transcoder API to list the jobs (as opposed to the AWS Console).</p>
  ## 
  let valid = call_602022.validator(path, query, header, formData, body)
  let scheme = call_602022.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602022.url(scheme.get, call_602022.host, call_602022.base,
                         call_602022.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602022, url, valid)

proc call*(call_602023: Call_CreateJob_602011; body: JsonNode): Recallable =
  ## createJob
  ## <p>When you create a job, Elastic Transcoder returns JSON data that includes the values that you specified plus information about the job that is created.</p> <p>If you have specified more than one output for your jobs (for example, one output for the Kindle Fire and another output for the Apple iPhone 4s), you currently must use the Elastic Transcoder API to list the jobs (as opposed to the AWS Console).</p>
  ##   body: JObject (required)
  var body_602024 = newJObject()
  if body != nil:
    body_602024 = body
  result = call_602023.call(nil, nil, nil, nil, body_602024)

var createJob* = Call_CreateJob_602011(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "elastictranscoder.amazonaws.com",
                                    route: "/2012-09-25/jobs",
                                    validator: validate_CreateJob_602012,
                                    base: "/", url: url_CreateJob_602013,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePipeline_602040 = ref object of OpenApiRestCall_601389
proc url_CreatePipeline_602042(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePipeline_602041(path: JsonNode; query: JsonNode;
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
  var valid_602043 = header.getOrDefault("X-Amz-Signature")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-Signature", valid_602043
  var valid_602044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-Content-Sha256", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Date")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Date", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Credential")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Credential", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Security-Token")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Security-Token", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Algorithm")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Algorithm", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-SignedHeaders", valid_602049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602051: Call_CreatePipeline_602040; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The CreatePipeline operation creates a pipeline with settings that you specify.
  ## 
  let valid = call_602051.validator(path, query, header, formData, body)
  let scheme = call_602051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602051.url(scheme.get, call_602051.host, call_602051.base,
                         call_602051.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602051, url, valid)

proc call*(call_602052: Call_CreatePipeline_602040; body: JsonNode): Recallable =
  ## createPipeline
  ## The CreatePipeline operation creates a pipeline with settings that you specify.
  ##   body: JObject (required)
  var body_602053 = newJObject()
  if body != nil:
    body_602053 = body
  result = call_602052.call(nil, nil, nil, nil, body_602053)

var createPipeline* = Call_CreatePipeline_602040(name: "createPipeline",
    meth: HttpMethod.HttpPost, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines", validator: validate_CreatePipeline_602041,
    base: "/", url: url_CreatePipeline_602042, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelines_602025 = ref object of OpenApiRestCall_601389
proc url_ListPipelines_602027(protocol: Scheme; host: string; base: string;
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

proc validate_ListPipelines_602026(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602028 = query.getOrDefault("Ascending")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "Ascending", valid_602028
  var valid_602029 = query.getOrDefault("PageToken")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "PageToken", valid_602029
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
  var valid_602030 = header.getOrDefault("X-Amz-Signature")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Signature", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Content-Sha256", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Date")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Date", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Credential")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Credential", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Security-Token")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Security-Token", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Algorithm")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Algorithm", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-SignedHeaders", valid_602036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602037: Call_ListPipelines_602025; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The ListPipelines operation gets a list of the pipelines associated with the current AWS account.
  ## 
  let valid = call_602037.validator(path, query, header, formData, body)
  let scheme = call_602037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602037.url(scheme.get, call_602037.host, call_602037.base,
                         call_602037.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602037, url, valid)

proc call*(call_602038: Call_ListPipelines_602025; Ascending: string = "";
          PageToken: string = ""): Recallable =
  ## listPipelines
  ## The ListPipelines operation gets a list of the pipelines associated with the current AWS account.
  ##   Ascending: string
  ##            : To list pipelines in chronological order by the date and time that they were created, enter <code>true</code>. To list pipelines in reverse chronological order, enter <code>false</code>.
  ##   PageToken: string
  ##            : When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  var query_602039 = newJObject()
  add(query_602039, "Ascending", newJString(Ascending))
  add(query_602039, "PageToken", newJString(PageToken))
  result = call_602038.call(nil, query_602039, nil, nil, nil)

var listPipelines* = Call_ListPipelines_602025(name: "listPipelines",
    meth: HttpMethod.HttpGet, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines", validator: validate_ListPipelines_602026,
    base: "/", url: url_ListPipelines_602027, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePreset_602069 = ref object of OpenApiRestCall_601389
proc url_CreatePreset_602071(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePreset_602070(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602072 = header.getOrDefault("X-Amz-Signature")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-Signature", valid_602072
  var valid_602073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "X-Amz-Content-Sha256", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-Date")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-Date", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Credential")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Credential", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Security-Token")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Security-Token", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Algorithm")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Algorithm", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-SignedHeaders", valid_602078
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602080: Call_CreatePreset_602069; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The CreatePreset operation creates a preset with settings that you specify.</p> <important> <p>Elastic Transcoder checks the CreatePreset settings to ensure that they meet Elastic Transcoder requirements and to determine whether they comply with H.264 standards. If your settings are not valid for Elastic Transcoder, Elastic Transcoder returns an HTTP 400 response (<code>ValidationException</code>) and does not create the preset. If the settings are valid for Elastic Transcoder but aren't strictly compliant with the H.264 standard, Elastic Transcoder creates the preset and returns a warning message in the response. This helps you determine whether your settings comply with the H.264 standard while giving you greater flexibility with respect to the video that Elastic Transcoder produces.</p> </important> <p>Elastic Transcoder uses the H.264 video-compression format. For more information, see the International Telecommunication Union publication <i>Recommendation ITU-T H.264: Advanced video coding for generic audiovisual services</i>.</p>
  ## 
  let valid = call_602080.validator(path, query, header, formData, body)
  let scheme = call_602080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602080.url(scheme.get, call_602080.host, call_602080.base,
                         call_602080.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602080, url, valid)

proc call*(call_602081: Call_CreatePreset_602069; body: JsonNode): Recallable =
  ## createPreset
  ## <p>The CreatePreset operation creates a preset with settings that you specify.</p> <important> <p>Elastic Transcoder checks the CreatePreset settings to ensure that they meet Elastic Transcoder requirements and to determine whether they comply with H.264 standards. If your settings are not valid for Elastic Transcoder, Elastic Transcoder returns an HTTP 400 response (<code>ValidationException</code>) and does not create the preset. If the settings are valid for Elastic Transcoder but aren't strictly compliant with the H.264 standard, Elastic Transcoder creates the preset and returns a warning message in the response. This helps you determine whether your settings comply with the H.264 standard while giving you greater flexibility with respect to the video that Elastic Transcoder produces.</p> </important> <p>Elastic Transcoder uses the H.264 video-compression format. For more information, see the International Telecommunication Union publication <i>Recommendation ITU-T H.264: Advanced video coding for generic audiovisual services</i>.</p>
  ##   body: JObject (required)
  var body_602082 = newJObject()
  if body != nil:
    body_602082 = body
  result = call_602081.call(nil, nil, nil, nil, body_602082)

var createPreset* = Call_CreatePreset_602069(name: "createPreset",
    meth: HttpMethod.HttpPost, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/presets", validator: validate_CreatePreset_602070,
    base: "/", url: url_CreatePreset_602071, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPresets_602054 = ref object of OpenApiRestCall_601389
proc url_ListPresets_602056(protocol: Scheme; host: string; base: string;
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

proc validate_ListPresets_602055(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602057 = query.getOrDefault("Ascending")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "Ascending", valid_602057
  var valid_602058 = query.getOrDefault("PageToken")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "PageToken", valid_602058
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
  var valid_602059 = header.getOrDefault("X-Amz-Signature")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "X-Amz-Signature", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Content-Sha256", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Date")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Date", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Credential")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Credential", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Security-Token")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Security-Token", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Algorithm")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Algorithm", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-SignedHeaders", valid_602065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602066: Call_ListPresets_602054; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The ListPresets operation gets a list of the default presets included with Elastic Transcoder and the presets that you've added in an AWS region.
  ## 
  let valid = call_602066.validator(path, query, header, formData, body)
  let scheme = call_602066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602066.url(scheme.get, call_602066.host, call_602066.base,
                         call_602066.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602066, url, valid)

proc call*(call_602067: Call_ListPresets_602054; Ascending: string = "";
          PageToken: string = ""): Recallable =
  ## listPresets
  ## The ListPresets operation gets a list of the default presets included with Elastic Transcoder and the presets that you've added in an AWS region.
  ##   Ascending: string
  ##            : To list presets in chronological order by the date and time that they were created, enter <code>true</code>. To list presets in reverse chronological order, enter <code>false</code>.
  ##   PageToken: string
  ##            : When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  var query_602068 = newJObject()
  add(query_602068, "Ascending", newJString(Ascending))
  add(query_602068, "PageToken", newJString(PageToken))
  result = call_602067.call(nil, query_602068, nil, nil, nil)

var listPresets* = Call_ListPresets_602054(name: "listPresets",
                                        meth: HttpMethod.HttpGet, host: "elastictranscoder.amazonaws.com",
                                        route: "/2012-09-25/presets",
                                        validator: validate_ListPresets_602055,
                                        base: "/", url: url_ListPresets_602056,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipeline_602097 = ref object of OpenApiRestCall_601389
proc url_UpdatePipeline_602099(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePipeline_602098(path: JsonNode; query: JsonNode;
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
  var valid_602100 = path.getOrDefault("Id")
  valid_602100 = validateParameter(valid_602100, JString, required = true,
                                 default = nil)
  if valid_602100 != nil:
    section.add "Id", valid_602100
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
  var valid_602101 = header.getOrDefault("X-Amz-Signature")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "X-Amz-Signature", valid_602101
  var valid_602102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "X-Amz-Content-Sha256", valid_602102
  var valid_602103 = header.getOrDefault("X-Amz-Date")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-Date", valid_602103
  var valid_602104 = header.getOrDefault("X-Amz-Credential")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "X-Amz-Credential", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Security-Token")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Security-Token", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Algorithm")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Algorithm", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-SignedHeaders", valid_602107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602109: Call_UpdatePipeline_602097; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Use the <code>UpdatePipeline</code> operation to update settings for a pipeline.</p> <important> <p>When you change pipeline settings, your changes take effect immediately. Jobs that you have already submitted and that Elastic Transcoder has not started to process are affected in addition to jobs that you submit after you change settings. </p> </important>
  ## 
  let valid = call_602109.validator(path, query, header, formData, body)
  let scheme = call_602109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602109.url(scheme.get, call_602109.host, call_602109.base,
                         call_602109.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602109, url, valid)

proc call*(call_602110: Call_UpdatePipeline_602097; body: JsonNode; Id: string): Recallable =
  ## updatePipeline
  ## <p> Use the <code>UpdatePipeline</code> operation to update settings for a pipeline.</p> <important> <p>When you change pipeline settings, your changes take effect immediately. Jobs that you have already submitted and that Elastic Transcoder has not started to process are affected in addition to jobs that you submit after you change settings. </p> </important>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID of the pipeline that you want to update.
  var path_602111 = newJObject()
  var body_602112 = newJObject()
  if body != nil:
    body_602112 = body
  add(path_602111, "Id", newJString(Id))
  result = call_602110.call(path_602111, nil, nil, nil, body_602112)

var updatePipeline* = Call_UpdatePipeline_602097(name: "updatePipeline",
    meth: HttpMethod.HttpPut, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines/{Id}", validator: validate_UpdatePipeline_602098,
    base: "/", url: url_UpdatePipeline_602099, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReadPipeline_602083 = ref object of OpenApiRestCall_601389
proc url_ReadPipeline_602085(protocol: Scheme; host: string; base: string;
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

proc validate_ReadPipeline_602084(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602086 = path.getOrDefault("Id")
  valid_602086 = validateParameter(valid_602086, JString, required = true,
                                 default = nil)
  if valid_602086 != nil:
    section.add "Id", valid_602086
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
  var valid_602087 = header.getOrDefault("X-Amz-Signature")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Signature", valid_602087
  var valid_602088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-Content-Sha256", valid_602088
  var valid_602089 = header.getOrDefault("X-Amz-Date")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-Date", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Credential")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Credential", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Security-Token")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Security-Token", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Algorithm")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Algorithm", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-SignedHeaders", valid_602093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602094: Call_ReadPipeline_602083; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The ReadPipeline operation gets detailed information about a pipeline.
  ## 
  let valid = call_602094.validator(path, query, header, formData, body)
  let scheme = call_602094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602094.url(scheme.get, call_602094.host, call_602094.base,
                         call_602094.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602094, url, valid)

proc call*(call_602095: Call_ReadPipeline_602083; Id: string): Recallable =
  ## readPipeline
  ## The ReadPipeline operation gets detailed information about a pipeline.
  ##   Id: string (required)
  ##     : The identifier of the pipeline to read.
  var path_602096 = newJObject()
  add(path_602096, "Id", newJString(Id))
  result = call_602095.call(path_602096, nil, nil, nil, nil)

var readPipeline* = Call_ReadPipeline_602083(name: "readPipeline",
    meth: HttpMethod.HttpGet, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines/{Id}", validator: validate_ReadPipeline_602084,
    base: "/", url: url_ReadPipeline_602085, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePipeline_602113 = ref object of OpenApiRestCall_601389
proc url_DeletePipeline_602115(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePipeline_602114(path: JsonNode; query: JsonNode;
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
  var valid_602116 = path.getOrDefault("Id")
  valid_602116 = validateParameter(valid_602116, JString, required = true,
                                 default = nil)
  if valid_602116 != nil:
    section.add "Id", valid_602116
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
  var valid_602117 = header.getOrDefault("X-Amz-Signature")
  valid_602117 = validateParameter(valid_602117, JString, required = false,
                                 default = nil)
  if valid_602117 != nil:
    section.add "X-Amz-Signature", valid_602117
  var valid_602118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "X-Amz-Content-Sha256", valid_602118
  var valid_602119 = header.getOrDefault("X-Amz-Date")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-Date", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Credential")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Credential", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Security-Token")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Security-Token", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Algorithm")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Algorithm", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-SignedHeaders", valid_602123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602124: Call_DeletePipeline_602113; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The DeletePipeline operation removes a pipeline.</p> <p> You can only delete a pipeline that has never been used or that is not currently in use (doesn't contain any active jobs). If the pipeline is currently in use, <code>DeletePipeline</code> returns an error. </p>
  ## 
  let valid = call_602124.validator(path, query, header, formData, body)
  let scheme = call_602124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602124.url(scheme.get, call_602124.host, call_602124.base,
                         call_602124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602124, url, valid)

proc call*(call_602125: Call_DeletePipeline_602113; Id: string): Recallable =
  ## deletePipeline
  ## <p>The DeletePipeline operation removes a pipeline.</p> <p> You can only delete a pipeline that has never been used or that is not currently in use (doesn't contain any active jobs). If the pipeline is currently in use, <code>DeletePipeline</code> returns an error. </p>
  ##   Id: string (required)
  ##     : The identifier of the pipeline that you want to delete.
  var path_602126 = newJObject()
  add(path_602126, "Id", newJString(Id))
  result = call_602125.call(path_602126, nil, nil, nil, nil)

var deletePipeline* = Call_DeletePipeline_602113(name: "deletePipeline",
    meth: HttpMethod.HttpDelete, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines/{Id}", validator: validate_DeletePipeline_602114,
    base: "/", url: url_DeletePipeline_602115, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReadPreset_602127 = ref object of OpenApiRestCall_601389
proc url_ReadPreset_602129(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ReadPreset_602128(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602130 = path.getOrDefault("Id")
  valid_602130 = validateParameter(valid_602130, JString, required = true,
                                 default = nil)
  if valid_602130 != nil:
    section.add "Id", valid_602130
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
  var valid_602131 = header.getOrDefault("X-Amz-Signature")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "X-Amz-Signature", valid_602131
  var valid_602132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602132 = validateParameter(valid_602132, JString, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "X-Amz-Content-Sha256", valid_602132
  var valid_602133 = header.getOrDefault("X-Amz-Date")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "X-Amz-Date", valid_602133
  var valid_602134 = header.getOrDefault("X-Amz-Credential")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "X-Amz-Credential", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-Security-Token")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Security-Token", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Algorithm")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Algorithm", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-SignedHeaders", valid_602137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602138: Call_ReadPreset_602127; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The ReadPreset operation gets detailed information about a preset.
  ## 
  let valid = call_602138.validator(path, query, header, formData, body)
  let scheme = call_602138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602138.url(scheme.get, call_602138.host, call_602138.base,
                         call_602138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602138, url, valid)

proc call*(call_602139: Call_ReadPreset_602127; Id: string): Recallable =
  ## readPreset
  ## The ReadPreset operation gets detailed information about a preset.
  ##   Id: string (required)
  ##     : The identifier of the preset for which you want to get detailed information.
  var path_602140 = newJObject()
  add(path_602140, "Id", newJString(Id))
  result = call_602139.call(path_602140, nil, nil, nil, nil)

var readPreset* = Call_ReadPreset_602127(name: "readPreset",
                                      meth: HttpMethod.HttpGet,
                                      host: "elastictranscoder.amazonaws.com",
                                      route: "/2012-09-25/presets/{Id}",
                                      validator: validate_ReadPreset_602128,
                                      base: "/", url: url_ReadPreset_602129,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePreset_602141 = ref object of OpenApiRestCall_601389
proc url_DeletePreset_602143(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePreset_602142(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602144 = path.getOrDefault("Id")
  valid_602144 = validateParameter(valid_602144, JString, required = true,
                                 default = nil)
  if valid_602144 != nil:
    section.add "Id", valid_602144
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
  var valid_602145 = header.getOrDefault("X-Amz-Signature")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Signature", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Content-Sha256", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-Date")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-Date", valid_602147
  var valid_602148 = header.getOrDefault("X-Amz-Credential")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "X-Amz-Credential", valid_602148
  var valid_602149 = header.getOrDefault("X-Amz-Security-Token")
  valid_602149 = validateParameter(valid_602149, JString, required = false,
                                 default = nil)
  if valid_602149 != nil:
    section.add "X-Amz-Security-Token", valid_602149
  var valid_602150 = header.getOrDefault("X-Amz-Algorithm")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Algorithm", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-SignedHeaders", valid_602151
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602152: Call_DeletePreset_602141; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The DeletePreset operation removes a preset that you've added in an AWS region.</p> <note> <p>You can't delete the default presets that are included with Elastic Transcoder.</p> </note>
  ## 
  let valid = call_602152.validator(path, query, header, formData, body)
  let scheme = call_602152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602152.url(scheme.get, call_602152.host, call_602152.base,
                         call_602152.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602152, url, valid)

proc call*(call_602153: Call_DeletePreset_602141; Id: string): Recallable =
  ## deletePreset
  ## <p>The DeletePreset operation removes a preset that you've added in an AWS region.</p> <note> <p>You can't delete the default presets that are included with Elastic Transcoder.</p> </note>
  ##   Id: string (required)
  ##     : The identifier of the preset for which you want to get detailed information.
  var path_602154 = newJObject()
  add(path_602154, "Id", newJString(Id))
  result = call_602153.call(path_602154, nil, nil, nil, nil)

var deletePreset* = Call_DeletePreset_602141(name: "deletePreset",
    meth: HttpMethod.HttpDelete, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/presets/{Id}", validator: validate_DeletePreset_602142,
    base: "/", url: url_DeletePreset_602143, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobsByPipeline_602155 = ref object of OpenApiRestCall_601389
proc url_ListJobsByPipeline_602157(protocol: Scheme; host: string; base: string;
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

proc validate_ListJobsByPipeline_602156(path: JsonNode; query: JsonNode;
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
  var valid_602158 = path.getOrDefault("PipelineId")
  valid_602158 = validateParameter(valid_602158, JString, required = true,
                                 default = nil)
  if valid_602158 != nil:
    section.add "PipelineId", valid_602158
  result.add "path", section
  ## parameters in `query` object:
  ##   Ascending: JString
  ##            :  To list jobs in chronological order by the date and time that they were submitted, enter <code>true</code>. To list jobs in reverse chronological order, enter <code>false</code>. 
  ##   PageToken: JString
  ##            :  When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  section = newJObject()
  var valid_602159 = query.getOrDefault("Ascending")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "Ascending", valid_602159
  var valid_602160 = query.getOrDefault("PageToken")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "PageToken", valid_602160
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
  var valid_602161 = header.getOrDefault("X-Amz-Signature")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-Signature", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Content-Sha256", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-Date")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Date", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-Credential")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-Credential", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Security-Token")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Security-Token", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Algorithm")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Algorithm", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-SignedHeaders", valid_602167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602168: Call_ListJobsByPipeline_602155; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The ListJobsByPipeline operation gets a list of the jobs currently in a pipeline.</p> <p>Elastic Transcoder returns all of the jobs currently in the specified pipeline. The response body contains one element for each job that satisfies the search criteria.</p>
  ## 
  let valid = call_602168.validator(path, query, header, formData, body)
  let scheme = call_602168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602168.url(scheme.get, call_602168.host, call_602168.base,
                         call_602168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602168, url, valid)

proc call*(call_602169: Call_ListJobsByPipeline_602155; PipelineId: string;
          Ascending: string = ""; PageToken: string = ""): Recallable =
  ## listJobsByPipeline
  ## <p>The ListJobsByPipeline operation gets a list of the jobs currently in a pipeline.</p> <p>Elastic Transcoder returns all of the jobs currently in the specified pipeline. The response body contains one element for each job that satisfies the search criteria.</p>
  ##   PipelineId: string (required)
  ##             : The ID of the pipeline for which you want to get job information.
  ##   Ascending: string
  ##            :  To list jobs in chronological order by the date and time that they were submitted, enter <code>true</code>. To list jobs in reverse chronological order, enter <code>false</code>. 
  ##   PageToken: string
  ##            :  When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  var path_602170 = newJObject()
  var query_602171 = newJObject()
  add(path_602170, "PipelineId", newJString(PipelineId))
  add(query_602171, "Ascending", newJString(Ascending))
  add(query_602171, "PageToken", newJString(PageToken))
  result = call_602169.call(path_602170, query_602171, nil, nil, nil)

var listJobsByPipeline* = Call_ListJobsByPipeline_602155(
    name: "listJobsByPipeline", meth: HttpMethod.HttpGet,
    host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/jobsByPipeline/{PipelineId}",
    validator: validate_ListJobsByPipeline_602156, base: "/",
    url: url_ListJobsByPipeline_602157, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobsByStatus_602172 = ref object of OpenApiRestCall_601389
proc url_ListJobsByStatus_602174(protocol: Scheme; host: string; base: string;
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

proc validate_ListJobsByStatus_602173(path: JsonNode; query: JsonNode;
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
  var valid_602175 = path.getOrDefault("Status")
  valid_602175 = validateParameter(valid_602175, JString, required = true,
                                 default = nil)
  if valid_602175 != nil:
    section.add "Status", valid_602175
  result.add "path", section
  ## parameters in `query` object:
  ##   Ascending: JString
  ##            :  To list jobs in chronological order by the date and time that they were submitted, enter <code>true</code>. To list jobs in reverse chronological order, enter <code>false</code>. 
  ##   PageToken: JString
  ##            :  When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  section = newJObject()
  var valid_602176 = query.getOrDefault("Ascending")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "Ascending", valid_602176
  var valid_602177 = query.getOrDefault("PageToken")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "PageToken", valid_602177
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
  var valid_602178 = header.getOrDefault("X-Amz-Signature")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Signature", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Content-Sha256", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Date")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Date", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Credential")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Credential", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Security-Token")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Security-Token", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Algorithm")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Algorithm", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-SignedHeaders", valid_602184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602185: Call_ListJobsByStatus_602172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The ListJobsByStatus operation gets a list of jobs that have a specified status. The response body contains one element for each job that satisfies the search criteria.
  ## 
  let valid = call_602185.validator(path, query, header, formData, body)
  let scheme = call_602185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602185.url(scheme.get, call_602185.host, call_602185.base,
                         call_602185.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602185, url, valid)

proc call*(call_602186: Call_ListJobsByStatus_602172; Status: string;
          Ascending: string = ""; PageToken: string = ""): Recallable =
  ## listJobsByStatus
  ## The ListJobsByStatus operation gets a list of jobs that have a specified status. The response body contains one element for each job that satisfies the search criteria.
  ##   Ascending: string
  ##            :  To list jobs in chronological order by the date and time that they were submitted, enter <code>true</code>. To list jobs in reverse chronological order, enter <code>false</code>. 
  ##   PageToken: string
  ##            :  When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  ##   Status: string (required)
  ##         : To get information about all of the jobs associated with the current AWS account that have a given status, specify the following status: <code>Submitted</code>, <code>Progressing</code>, <code>Complete</code>, <code>Canceled</code>, or <code>Error</code>.
  var path_602187 = newJObject()
  var query_602188 = newJObject()
  add(query_602188, "Ascending", newJString(Ascending))
  add(query_602188, "PageToken", newJString(PageToken))
  add(path_602187, "Status", newJString(Status))
  result = call_602186.call(path_602187, query_602188, nil, nil, nil)

var listJobsByStatus* = Call_ListJobsByStatus_602172(name: "listJobsByStatus",
    meth: HttpMethod.HttpGet, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/jobsByStatus/{Status}",
    validator: validate_ListJobsByStatus_602173, base: "/",
    url: url_ListJobsByStatus_602174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestRole_602189 = ref object of OpenApiRestCall_601389
proc url_TestRole_602191(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_TestRole_602190(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602192 = header.getOrDefault("X-Amz-Signature")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Signature", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Content-Sha256", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-Date")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Date", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Credential")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Credential", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Security-Token")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Security-Token", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Algorithm")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Algorithm", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-SignedHeaders", valid_602198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602200: Call_TestRole_602189; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The TestRole operation tests the IAM role used to create the pipeline.</p> <p>The <code>TestRole</code> action lets you determine whether the IAM role you are using has sufficient permissions to let Elastic Transcoder perform tasks associated with the transcoding process. The action attempts to assume the specified IAM role, checks read access to the input and output buckets, and tries to send a test notification to Amazon SNS topics that you specify.</p>
  ## 
  let valid = call_602200.validator(path, query, header, formData, body)
  let scheme = call_602200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602200.url(scheme.get, call_602200.host, call_602200.base,
                         call_602200.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602200, url, valid)

proc call*(call_602201: Call_TestRole_602189; body: JsonNode): Recallable =
  ## testRole
  ## <p>The TestRole operation tests the IAM role used to create the pipeline.</p> <p>The <code>TestRole</code> action lets you determine whether the IAM role you are using has sufficient permissions to let Elastic Transcoder perform tasks associated with the transcoding process. The action attempts to assume the specified IAM role, checks read access to the input and output buckets, and tries to send a test notification to Amazon SNS topics that you specify.</p>
  ##   body: JObject (required)
  var body_602202 = newJObject()
  if body != nil:
    body_602202 = body
  result = call_602201.call(nil, nil, nil, nil, body_602202)

var testRole* = Call_TestRole_602189(name: "testRole", meth: HttpMethod.HttpPost,
                                  host: "elastictranscoder.amazonaws.com",
                                  route: "/2012-09-25/roleTests",
                                  validator: validate_TestRole_602190, base: "/",
                                  url: url_TestRole_602191,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipelineNotifications_602203 = ref object of OpenApiRestCall_601389
proc url_UpdatePipelineNotifications_602205(protocol: Scheme; host: string;
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

proc validate_UpdatePipelineNotifications_602204(path: JsonNode; query: JsonNode;
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
  var valid_602206 = path.getOrDefault("Id")
  valid_602206 = validateParameter(valid_602206, JString, required = true,
                                 default = nil)
  if valid_602206 != nil:
    section.add "Id", valid_602206
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602215: Call_UpdatePipelineNotifications_602203; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>With the UpdatePipelineNotifications operation, you can update Amazon Simple Notification Service (Amazon SNS) notifications for a pipeline.</p> <p>When you update notifications for a pipeline, Elastic Transcoder returns the values that you specified in the request.</p>
  ## 
  let valid = call_602215.validator(path, query, header, formData, body)
  let scheme = call_602215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602215.url(scheme.get, call_602215.host, call_602215.base,
                         call_602215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602215, url, valid)

proc call*(call_602216: Call_UpdatePipelineNotifications_602203; body: JsonNode;
          Id: string): Recallable =
  ## updatePipelineNotifications
  ## <p>With the UpdatePipelineNotifications operation, you can update Amazon Simple Notification Service (Amazon SNS) notifications for a pipeline.</p> <p>When you update notifications for a pipeline, Elastic Transcoder returns the values that you specified in the request.</p>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The identifier of the pipeline for which you want to change notification settings.
  var path_602217 = newJObject()
  var body_602218 = newJObject()
  if body != nil:
    body_602218 = body
  add(path_602217, "Id", newJString(Id))
  result = call_602216.call(path_602217, nil, nil, nil, body_602218)

var updatePipelineNotifications* = Call_UpdatePipelineNotifications_602203(
    name: "updatePipelineNotifications", meth: HttpMethod.HttpPost,
    host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines/{Id}/notifications",
    validator: validate_UpdatePipelineNotifications_602204, base: "/",
    url: url_UpdatePipelineNotifications_602205,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipelineStatus_602219 = ref object of OpenApiRestCall_601389
proc url_UpdatePipelineStatus_602221(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePipelineStatus_602220(path: JsonNode; query: JsonNode;
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
  var valid_602222 = path.getOrDefault("Id")
  valid_602222 = validateParameter(valid_602222, JString, required = true,
                                 default = nil)
  if valid_602222 != nil:
    section.add "Id", valid_602222
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
  var valid_602223 = header.getOrDefault("X-Amz-Signature")
  valid_602223 = validateParameter(valid_602223, JString, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "X-Amz-Signature", valid_602223
  var valid_602224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "X-Amz-Content-Sha256", valid_602224
  var valid_602225 = header.getOrDefault("X-Amz-Date")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-Date", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-Credential")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Credential", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-Security-Token")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Security-Token", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-Algorithm")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Algorithm", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-SignedHeaders", valid_602229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602231: Call_UpdatePipelineStatus_602219; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The UpdatePipelineStatus operation pauses or reactivates a pipeline, so that the pipeline stops or restarts the processing of jobs.</p> <p>Changing the pipeline status is useful if you want to cancel one or more jobs. You can't cancel jobs after Elastic Transcoder has started processing them; if you pause the pipeline to which you submitted the jobs, you have more time to get the job IDs for the jobs that you want to cancel, and to send a <a>CancelJob</a> request. </p>
  ## 
  let valid = call_602231.validator(path, query, header, formData, body)
  let scheme = call_602231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602231.url(scheme.get, call_602231.host, call_602231.base,
                         call_602231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602231, url, valid)

proc call*(call_602232: Call_UpdatePipelineStatus_602219; body: JsonNode; Id: string): Recallable =
  ## updatePipelineStatus
  ## <p>The UpdatePipelineStatus operation pauses or reactivates a pipeline, so that the pipeline stops or restarts the processing of jobs.</p> <p>Changing the pipeline status is useful if you want to cancel one or more jobs. You can't cancel jobs after Elastic Transcoder has started processing them; if you pause the pipeline to which you submitted the jobs, you have more time to get the job IDs for the jobs that you want to cancel, and to send a <a>CancelJob</a> request. </p>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The identifier of the pipeline to update.
  var path_602233 = newJObject()
  var body_602234 = newJObject()
  if body != nil:
    body_602234 = body
  add(path_602233, "Id", newJString(Id))
  result = call_602232.call(path_602233, nil, nil, nil, body_602234)

var updatePipelineStatus* = Call_UpdatePipelineStatus_602219(
    name: "updatePipelineStatus", meth: HttpMethod.HttpPost,
    host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines/{Id}/status",
    validator: validate_UpdatePipelineStatus_602220, base: "/",
    url: url_UpdatePipelineStatus_602221, schemes: {Scheme.Https, Scheme.Http})
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
