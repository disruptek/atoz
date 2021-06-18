
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                             header: JsonNode = nil; formData: JsonNode = nil;
                             body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "elastictranscoder.ap-northeast-1.amazonaws.com", "ap-southeast-1": "elastictranscoder.ap-southeast-1.amazonaws.com", "us-west-2": "elastictranscoder.us-west-2.amazonaws.com", "eu-west-2": "elastictranscoder.eu-west-2.amazonaws.com", "ap-northeast-3": "elastictranscoder.ap-northeast-3.amazonaws.com", "eu-central-1": "elastictranscoder.eu-central-1.amazonaws.com", "us-east-2": "elastictranscoder.us-east-2.amazonaws.com", "us-east-1": "elastictranscoder.us-east-1.amazonaws.com", "cn-northwest-1": "elastictranscoder.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "elastictranscoder.ap-south-1.amazonaws.com", "eu-north-1": "elastictranscoder.eu-north-1.amazonaws.com", "ap-northeast-2": "elastictranscoder.ap-northeast-2.amazonaws.com", "us-west-1": "elastictranscoder.us-west-1.amazonaws.com", "us-gov-east-1": "elastictranscoder.us-gov-east-1.amazonaws.com", "eu-west-3": "elastictranscoder.eu-west-3.amazonaws.com", "cn-north-1": "elastictranscoder.cn-north-1.amazonaws.com.cn", "sa-east-1": "elastictranscoder.sa-east-1.amazonaws.com", "eu-west-1": "elastictranscoder.eu-west-1.amazonaws.com", "us-gov-west-1": "elastictranscoder.us-gov-west-1.amazonaws.com", "ap-southeast-2": "elastictranscoder.ap-southeast-2.amazonaws.com", "ca-central-1": "elastictranscoder.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_ReadJob_402656294 = ref object of OpenApiRestCall_402656044
proc url_ReadJob_402656296(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ReadJob_402656295(path: JsonNode; query: JsonNode;
                                header: JsonNode; formData: JsonNode;
                                body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## The ReadJob operation returns detailed information about a job.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The identifier of the job for which you want to get detailed information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656386 = path.getOrDefault("Id")
  valid_402656386 = validateParameter(valid_402656386, JString, required = true,
                                      default = nil)
  if valid_402656386 != nil:
    section.add "Id", valid_402656386
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656387 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-Security-Token", valid_402656387
  var valid_402656388 = header.getOrDefault("X-Amz-Signature")
  valid_402656388 = validateParameter(valid_402656388, JString,
                                      required = false, default = nil)
  if valid_402656388 != nil:
    section.add "X-Amz-Signature", valid_402656388
  var valid_402656389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656389 = validateParameter(valid_402656389, JString,
                                      required = false, default = nil)
  if valid_402656389 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656389
  var valid_402656390 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656390 = validateParameter(valid_402656390, JString,
                                      required = false, default = nil)
  if valid_402656390 != nil:
    section.add "X-Amz-Algorithm", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-Date")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-Date", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-Credential")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-Credential", valid_402656392
  var valid_402656393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656407: Call_ReadJob_402656294; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## The ReadJob operation returns detailed information about a job.
                                                                                         ## 
  let valid = call_402656407.validator(path, query, header, formData, body, _)
  let scheme = call_402656407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656407.makeUrl(scheme.get, call_402656407.host, call_402656407.base,
                                   call_402656407.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656407, uri, valid, _)

proc call*(call_402656456: Call_ReadJob_402656294; Id: string): Recallable =
  ## readJob
  ## The ReadJob operation returns detailed information about a job.
  ##   Id: string (required)
                                                                    ##     : The identifier of the job for which you want to get detailed information.
  var path_402656457 = newJObject()
  add(path_402656457, "Id", newJString(Id))
  result = call_402656456.call(path_402656457, nil, nil, nil, nil)

var readJob* = Call_ReadJob_402656294(name: "readJob", meth: HttpMethod.HttpGet,
                                      host: "elastictranscoder.amazonaws.com",
                                      route: "/2012-09-25/jobs/{Id}",
                                      validator: validate_ReadJob_402656295,
                                      base: "/", makeUrl: url_ReadJob_402656296,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelJob_402656487 = ref object of OpenApiRestCall_402656044
proc url_CancelJob_402656489(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CancelJob_402656488(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>The CancelJob operation cancels an unfinished job.</p> <note> <p>You can only cancel a job that has a status of <code>Submitted</code>. To prevent a pipeline from starting to process a job while you're getting the job identifier, use <a>UpdatePipelineStatus</a> to temporarily pause the pipeline.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : <p>The identifier of the job that you want to cancel.</p> <p>To get a list of the jobs (including their <code>jobId</code>) that have a status of <code>Submitted</code>, use the <a>ListJobsByStatus</a> API action.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656490 = path.getOrDefault("Id")
  valid_402656490 = validateParameter(valid_402656490, JString, required = true,
                                      default = nil)
  if valid_402656490 != nil:
    section.add "Id", valid_402656490
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656491 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-Security-Token", valid_402656491
  var valid_402656492 = header.getOrDefault("X-Amz-Signature")
  valid_402656492 = validateParameter(valid_402656492, JString,
                                      required = false, default = nil)
  if valid_402656492 != nil:
    section.add "X-Amz-Signature", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Algorithm", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Date")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Date", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Credential")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Credential", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656498: Call_CancelJob_402656487; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>The CancelJob operation cancels an unfinished job.</p> <note> <p>You can only cancel a job that has a status of <code>Submitted</code>. To prevent a pipeline from starting to process a job while you're getting the job identifier, use <a>UpdatePipelineStatus</a> to temporarily pause the pipeline.</p> </note>
                                                                                         ## 
  let valid = call_402656498.validator(path, query, header, formData, body, _)
  let scheme = call_402656498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656498.makeUrl(scheme.get, call_402656498.host, call_402656498.base,
                                   call_402656498.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656498, uri, valid, _)

proc call*(call_402656499: Call_CancelJob_402656487; Id: string): Recallable =
  ## cancelJob
  ## <p>The CancelJob operation cancels an unfinished job.</p> <note> <p>You can only cancel a job that has a status of <code>Submitted</code>. To prevent a pipeline from starting to process a job while you're getting the job identifier, use <a>UpdatePipelineStatus</a> to temporarily pause the pipeline.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                            ## Id: string (required)
                                                                                                                                                                                                                                                                                                                            ##     
                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                            ## <p>The 
                                                                                                                                                                                                                                                                                                                            ## identifier 
                                                                                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                            ## job 
                                                                                                                                                                                                                                                                                                                            ## that 
                                                                                                                                                                                                                                                                                                                            ## you 
                                                                                                                                                                                                                                                                                                                            ## want 
                                                                                                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                                                                                                            ## cancel.</p> 
                                                                                                                                                                                                                                                                                                                            ## <p>To 
                                                                                                                                                                                                                                                                                                                            ## get 
                                                                                                                                                                                                                                                                                                                            ## a 
                                                                                                                                                                                                                                                                                                                            ## list 
                                                                                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                            ## jobs 
                                                                                                                                                                                                                                                                                                                            ## (including 
                                                                                                                                                                                                                                                                                                                            ## their 
                                                                                                                                                                                                                                                                                                                            ## <code>jobId</code>) 
                                                                                                                                                                                                                                                                                                                            ## that 
                                                                                                                                                                                                                                                                                                                            ## have 
                                                                                                                                                                                                                                                                                                                            ## a 
                                                                                                                                                                                                                                                                                                                            ## status 
                                                                                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                                                                                            ## <code>Submitted</code>, 
                                                                                                                                                                                                                                                                                                                            ## use 
                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                            ## <a>ListJobsByStatus</a> 
                                                                                                                                                                                                                                                                                                                            ## API 
                                                                                                                                                                                                                                                                                                                            ## action.</p>
  var path_402656500 = newJObject()
  add(path_402656500, "Id", newJString(Id))
  result = call_402656499.call(path_402656500, nil, nil, nil, nil)

var cancelJob* = Call_CancelJob_402656487(name: "cancelJob",
    meth: HttpMethod.HttpDelete, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/jobs/{Id}", validator: validate_CancelJob_402656488,
    base: "/", makeUrl: url_CancelJob_402656489,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_402656501 = ref object of OpenApiRestCall_402656044
proc url_CreateJob_402656503(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateJob_402656502(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>When you create a job, Elastic Transcoder returns JSON data that includes the values that you specified plus information about the job that is created.</p> <p>If you have specified more than one output for your jobs (for example, one output for the Kindle Fire and another output for the Apple iPhone 4s), you currently must use the Elastic Transcoder API to list the jobs (as opposed to the AWS Console).</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656504 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Security-Token", valid_402656504
  var valid_402656505 = header.getOrDefault("X-Amz-Signature")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-Signature", valid_402656505
  var valid_402656506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Algorithm", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Date")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Date", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Credential")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Credential", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656510
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656512: Call_CreateJob_402656501; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>When you create a job, Elastic Transcoder returns JSON data that includes the values that you specified plus information about the job that is created.</p> <p>If you have specified more than one output for your jobs (for example, one output for the Kindle Fire and another output for the Apple iPhone 4s), you currently must use the Elastic Transcoder API to list the jobs (as opposed to the AWS Console).</p>
                                                                                         ## 
  let valid = call_402656512.validator(path, query, header, formData, body, _)
  let scheme = call_402656512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656512.makeUrl(scheme.get, call_402656512.host, call_402656512.base,
                                   call_402656512.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656512, uri, valid, _)

proc call*(call_402656513: Call_CreateJob_402656501; body: JsonNode): Recallable =
  ## createJob
  ## <p>When you create a job, Elastic Transcoder returns JSON data that includes the values that you specified plus information about the job that is created.</p> <p>If you have specified more than one output for your jobs (for example, one output for the Kindle Fire and another output for the Apple iPhone 4s), you currently must use the Elastic Transcoder API to list the jobs (as opposed to the AWS Console).</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402656514 = newJObject()
  if body != nil:
    body_402656514 = body
  result = call_402656513.call(nil, nil, nil, nil, body_402656514)

var createJob* = Call_CreateJob_402656501(name: "createJob",
    meth: HttpMethod.HttpPost, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/jobs", validator: validate_CreateJob_402656502,
    base: "/", makeUrl: url_CreateJob_402656503,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePipeline_402656530 = ref object of OpenApiRestCall_402656044
proc url_CreatePipeline_402656532(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePipeline_402656531(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## The CreatePipeline operation creates a pipeline with settings that you specify.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656533 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-Security-Token", valid_402656533
  var valid_402656534 = header.getOrDefault("X-Amz-Signature")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-Signature", valid_402656534
  var valid_402656535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656535
  var valid_402656536 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-Algorithm", valid_402656536
  var valid_402656537 = header.getOrDefault("X-Amz-Date")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Date", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Credential")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Credential", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656541: Call_CreatePipeline_402656530; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## The CreatePipeline operation creates a pipeline with settings that you specify.
                                                                                         ## 
  let valid = call_402656541.validator(path, query, header, formData, body, _)
  let scheme = call_402656541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656541.makeUrl(scheme.get, call_402656541.host, call_402656541.base,
                                   call_402656541.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656541, uri, valid, _)

proc call*(call_402656542: Call_CreatePipeline_402656530; body: JsonNode): Recallable =
  ## createPipeline
  ## The CreatePipeline operation creates a pipeline with settings that you specify.
  ##   
                                                                                    ## body: JObject (required)
  var body_402656543 = newJObject()
  if body != nil:
    body_402656543 = body
  result = call_402656542.call(nil, nil, nil, nil, body_402656543)

var createPipeline* = Call_CreatePipeline_402656530(name: "createPipeline",
    meth: HttpMethod.HttpPost, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines", validator: validate_CreatePipeline_402656531,
    base: "/", makeUrl: url_CreatePipeline_402656532,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPipelines_402656515 = ref object of OpenApiRestCall_402656044
proc url_ListPipelines_402656517(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPipelines_402656516(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## The ListPipelines operation gets a list of the pipelines associated with the current AWS account.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Ascending: JString
                                  ##            : To list pipelines in chronological order by the date and time that they were created, enter <code>true</code>. To list pipelines in reverse chronological order, enter <code>false</code>.
  ##   
                                                                                                                                                                                                                                            ## PageToken: JString
                                                                                                                                                                                                                                            ##            
                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                            ## When 
                                                                                                                                                                                                                                            ## Elastic 
                                                                                                                                                                                                                                            ## Transcoder 
                                                                                                                                                                                                                                            ## returns 
                                                                                                                                                                                                                                            ## more 
                                                                                                                                                                                                                                            ## than 
                                                                                                                                                                                                                                            ## one 
                                                                                                                                                                                                                                            ## page 
                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                            ## results, 
                                                                                                                                                                                                                                            ## use 
                                                                                                                                                                                                                                            ## <code>pageToken</code> 
                                                                                                                                                                                                                                            ## in 
                                                                                                                                                                                                                                            ## subsequent 
                                                                                                                                                                                                                                            ## <code>GET</code> 
                                                                                                                                                                                                                                            ## requests 
                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                            ## get 
                                                                                                                                                                                                                                            ## each 
                                                                                                                                                                                                                                            ## successive 
                                                                                                                                                                                                                                            ## page 
                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                            ## results. 
  section = newJObject()
  var valid_402656518 = query.getOrDefault("Ascending")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "Ascending", valid_402656518
  var valid_402656519 = query.getOrDefault("PageToken")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "PageToken", valid_402656519
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656520 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-Security-Token", valid_402656520
  var valid_402656521 = header.getOrDefault("X-Amz-Signature")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-Signature", valid_402656521
  var valid_402656522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Algorithm", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Date")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Date", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Credential")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Credential", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656526
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656527: Call_ListPipelines_402656515; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## The ListPipelines operation gets a list of the pipelines associated with the current AWS account.
                                                                                         ## 
  let valid = call_402656527.validator(path, query, header, formData, body, _)
  let scheme = call_402656527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656527.makeUrl(scheme.get, call_402656527.host, call_402656527.base,
                                   call_402656527.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656527, uri, valid, _)

proc call*(call_402656528: Call_ListPipelines_402656515; Ascending: string = "";
           PageToken: string = ""): Recallable =
  ## listPipelines
  ## The ListPipelines operation gets a list of the pipelines associated with the current AWS account.
  ##   
                                                                                                      ## Ascending: string
                                                                                                      ##            
                                                                                                      ## : 
                                                                                                      ## To 
                                                                                                      ## list 
                                                                                                      ## pipelines 
                                                                                                      ## in 
                                                                                                      ## chronological 
                                                                                                      ## order 
                                                                                                      ## by 
                                                                                                      ## the 
                                                                                                      ## date 
                                                                                                      ## and 
                                                                                                      ## time 
                                                                                                      ## that 
                                                                                                      ## they 
                                                                                                      ## were 
                                                                                                      ## created, 
                                                                                                      ## enter 
                                                                                                      ## <code>true</code>. 
                                                                                                      ## To 
                                                                                                      ## list 
                                                                                                      ## pipelines 
                                                                                                      ## in 
                                                                                                      ## reverse 
                                                                                                      ## chronological 
                                                                                                      ## order, 
                                                                                                      ## enter 
                                                                                                      ## <code>false</code>.
  ##   
                                                                                                                            ## PageToken: string
                                                                                                                            ##            
                                                                                                                            ## : 
                                                                                                                            ## When 
                                                                                                                            ## Elastic 
                                                                                                                            ## Transcoder 
                                                                                                                            ## returns 
                                                                                                                            ## more 
                                                                                                                            ## than 
                                                                                                                            ## one 
                                                                                                                            ## page 
                                                                                                                            ## of 
                                                                                                                            ## results, 
                                                                                                                            ## use 
                                                                                                                            ## <code>pageToken</code> 
                                                                                                                            ## in 
                                                                                                                            ## subsequent 
                                                                                                                            ## <code>GET</code> 
                                                                                                                            ## requests 
                                                                                                                            ## to 
                                                                                                                            ## get 
                                                                                                                            ## each 
                                                                                                                            ## successive 
                                                                                                                            ## page 
                                                                                                                            ## of 
                                                                                                                            ## results. 
  var query_402656529 = newJObject()
  add(query_402656529, "Ascending", newJString(Ascending))
  add(query_402656529, "PageToken", newJString(PageToken))
  result = call_402656528.call(nil, query_402656529, nil, nil, nil)

var listPipelines* = Call_ListPipelines_402656515(name: "listPipelines",
    meth: HttpMethod.HttpGet, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines", validator: validate_ListPipelines_402656516,
    base: "/", makeUrl: url_ListPipelines_402656517,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePreset_402656559 = ref object of OpenApiRestCall_402656044
proc url_CreatePreset_402656561(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePreset_402656560(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>The CreatePreset operation creates a preset with settings that you specify.</p> <important> <p>Elastic Transcoder checks the CreatePreset settings to ensure that they meet Elastic Transcoder requirements and to determine whether they comply with H.264 standards. If your settings are not valid for Elastic Transcoder, Elastic Transcoder returns an HTTP 400 response (<code>ValidationException</code>) and does not create the preset. If the settings are valid for Elastic Transcoder but aren't strictly compliant with the H.264 standard, Elastic Transcoder creates the preset and returns a warning message in the response. This helps you determine whether your settings comply with the H.264 standard while giving you greater flexibility with respect to the video that Elastic Transcoder produces.</p> </important> <p>Elastic Transcoder uses the H.264 video-compression format. For more information, see the International Telecommunication Union publication <i>Recommendation ITU-T H.264: Advanced video coding for generic audiovisual services</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656562 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-Security-Token", valid_402656562
  var valid_402656563 = header.getOrDefault("X-Amz-Signature")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "X-Amz-Signature", valid_402656563
  var valid_402656564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656564
  var valid_402656565 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-Algorithm", valid_402656565
  var valid_402656566 = header.getOrDefault("X-Amz-Date")
  valid_402656566 = validateParameter(valid_402656566, JString,
                                      required = false, default = nil)
  if valid_402656566 != nil:
    section.add "X-Amz-Date", valid_402656566
  var valid_402656567 = header.getOrDefault("X-Amz-Credential")
  valid_402656567 = validateParameter(valid_402656567, JString,
                                      required = false, default = nil)
  if valid_402656567 != nil:
    section.add "X-Amz-Credential", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656568
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656570: Call_CreatePreset_402656559; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>The CreatePreset operation creates a preset with settings that you specify.</p> <important> <p>Elastic Transcoder checks the CreatePreset settings to ensure that they meet Elastic Transcoder requirements and to determine whether they comply with H.264 standards. If your settings are not valid for Elastic Transcoder, Elastic Transcoder returns an HTTP 400 response (<code>ValidationException</code>) and does not create the preset. If the settings are valid for Elastic Transcoder but aren't strictly compliant with the H.264 standard, Elastic Transcoder creates the preset and returns a warning message in the response. This helps you determine whether your settings comply with the H.264 standard while giving you greater flexibility with respect to the video that Elastic Transcoder produces.</p> </important> <p>Elastic Transcoder uses the H.264 video-compression format. For more information, see the International Telecommunication Union publication <i>Recommendation ITU-T H.264: Advanced video coding for generic audiovisual services</i>.</p>
                                                                                         ## 
  let valid = call_402656570.validator(path, query, header, formData, body, _)
  let scheme = call_402656570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656570.makeUrl(scheme.get, call_402656570.host, call_402656570.base,
                                   call_402656570.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656570, uri, valid, _)

proc call*(call_402656571: Call_CreatePreset_402656559; body: JsonNode): Recallable =
  ## createPreset
  ## <p>The CreatePreset operation creates a preset with settings that you specify.</p> <important> <p>Elastic Transcoder checks the CreatePreset settings to ensure that they meet Elastic Transcoder requirements and to determine whether they comply with H.264 standards. If your settings are not valid for Elastic Transcoder, Elastic Transcoder returns an HTTP 400 response (<code>ValidationException</code>) and does not create the preset. If the settings are valid for Elastic Transcoder but aren't strictly compliant with the H.264 standard, Elastic Transcoder creates the preset and returns a warning message in the response. This helps you determine whether your settings comply with the H.264 standard while giving you greater flexibility with respect to the video that Elastic Transcoder produces.</p> </important> <p>Elastic Transcoder uses the H.264 video-compression format. For more information, see the International Telecommunication Union publication <i>Recommendation ITU-T H.264: Advanced video coding for generic audiovisual services</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656572 = newJObject()
  if body != nil:
    body_402656572 = body
  result = call_402656571.call(nil, nil, nil, nil, body_402656572)

var createPreset* = Call_CreatePreset_402656559(name: "createPreset",
    meth: HttpMethod.HttpPost, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/presets", validator: validate_CreatePreset_402656560,
    base: "/", makeUrl: url_CreatePreset_402656561,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPresets_402656544 = ref object of OpenApiRestCall_402656044
proc url_ListPresets_402656546(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPresets_402656545(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## The ListPresets operation gets a list of the default presets included with Elastic Transcoder and the presets that you've added in an AWS region.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Ascending: JString
                                  ##            : To list presets in chronological order by the date and time that they were created, enter <code>true</code>. To list presets in reverse chronological order, enter <code>false</code>.
  ##   
                                                                                                                                                                                                                                        ## PageToken: JString
                                                                                                                                                                                                                                        ##            
                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                        ## When 
                                                                                                                                                                                                                                        ## Elastic 
                                                                                                                                                                                                                                        ## Transcoder 
                                                                                                                                                                                                                                        ## returns 
                                                                                                                                                                                                                                        ## more 
                                                                                                                                                                                                                                        ## than 
                                                                                                                                                                                                                                        ## one 
                                                                                                                                                                                                                                        ## page 
                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                        ## results, 
                                                                                                                                                                                                                                        ## use 
                                                                                                                                                                                                                                        ## <code>pageToken</code> 
                                                                                                                                                                                                                                        ## in 
                                                                                                                                                                                                                                        ## subsequent 
                                                                                                                                                                                                                                        ## <code>GET</code> 
                                                                                                                                                                                                                                        ## requests 
                                                                                                                                                                                                                                        ## to 
                                                                                                                                                                                                                                        ## get 
                                                                                                                                                                                                                                        ## each 
                                                                                                                                                                                                                                        ## successive 
                                                                                                                                                                                                                                        ## page 
                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                        ## results. 
  section = newJObject()
  var valid_402656547 = query.getOrDefault("Ascending")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "Ascending", valid_402656547
  var valid_402656548 = query.getOrDefault("PageToken")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "PageToken", valid_402656548
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656549 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-Security-Token", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-Signature")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-Signature", valid_402656550
  var valid_402656551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656551
  var valid_402656552 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-Algorithm", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Date")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Date", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Credential")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Credential", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656555
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656556: Call_ListPresets_402656544; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## The ListPresets operation gets a list of the default presets included with Elastic Transcoder and the presets that you've added in an AWS region.
                                                                                         ## 
  let valid = call_402656556.validator(path, query, header, formData, body, _)
  let scheme = call_402656556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656556.makeUrl(scheme.get, call_402656556.host, call_402656556.base,
                                   call_402656556.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656556, uri, valid, _)

proc call*(call_402656557: Call_ListPresets_402656544; Ascending: string = "";
           PageToken: string = ""): Recallable =
  ## listPresets
  ## The ListPresets operation gets a list of the default presets included with Elastic Transcoder and the presets that you've added in an AWS region.
  ##   
                                                                                                                                                      ## Ascending: string
                                                                                                                                                      ##            
                                                                                                                                                      ## : 
                                                                                                                                                      ## To 
                                                                                                                                                      ## list 
                                                                                                                                                      ## presets 
                                                                                                                                                      ## in 
                                                                                                                                                      ## chronological 
                                                                                                                                                      ## order 
                                                                                                                                                      ## by 
                                                                                                                                                      ## the 
                                                                                                                                                      ## date 
                                                                                                                                                      ## and 
                                                                                                                                                      ## time 
                                                                                                                                                      ## that 
                                                                                                                                                      ## they 
                                                                                                                                                      ## were 
                                                                                                                                                      ## created, 
                                                                                                                                                      ## enter 
                                                                                                                                                      ## <code>true</code>. 
                                                                                                                                                      ## To 
                                                                                                                                                      ## list 
                                                                                                                                                      ## presets 
                                                                                                                                                      ## in 
                                                                                                                                                      ## reverse 
                                                                                                                                                      ## chronological 
                                                                                                                                                      ## order, 
                                                                                                                                                      ## enter 
                                                                                                                                                      ## <code>false</code>.
  ##   
                                                                                                                                                                            ## PageToken: string
                                                                                                                                                                            ##            
                                                                                                                                                                            ## : 
                                                                                                                                                                            ## When 
                                                                                                                                                                            ## Elastic 
                                                                                                                                                                            ## Transcoder 
                                                                                                                                                                            ## returns 
                                                                                                                                                                            ## more 
                                                                                                                                                                            ## than 
                                                                                                                                                                            ## one 
                                                                                                                                                                            ## page 
                                                                                                                                                                            ## of 
                                                                                                                                                                            ## results, 
                                                                                                                                                                            ## use 
                                                                                                                                                                            ## <code>pageToken</code> 
                                                                                                                                                                            ## in 
                                                                                                                                                                            ## subsequent 
                                                                                                                                                                            ## <code>GET</code> 
                                                                                                                                                                            ## requests 
                                                                                                                                                                            ## to 
                                                                                                                                                                            ## get 
                                                                                                                                                                            ## each 
                                                                                                                                                                            ## successive 
                                                                                                                                                                            ## page 
                                                                                                                                                                            ## of 
                                                                                                                                                                            ## results. 
  var query_402656558 = newJObject()
  add(query_402656558, "Ascending", newJString(Ascending))
  add(query_402656558, "PageToken", newJString(PageToken))
  result = call_402656557.call(nil, query_402656558, nil, nil, nil)

var listPresets* = Call_ListPresets_402656544(name: "listPresets",
    meth: HttpMethod.HttpGet, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/presets", validator: validate_ListPresets_402656545,
    base: "/", makeUrl: url_ListPresets_402656546,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipeline_402656587 = ref object of OpenApiRestCall_402656044
proc url_UpdatePipeline_402656589(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdatePipeline_402656588(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p> Use the <code>UpdatePipeline</code> operation to update settings for a pipeline.</p> <important> <p>When you change pipeline settings, your changes take effect immediately. Jobs that you have already submitted and that Elastic Transcoder has not started to process are affected in addition to jobs that you submit after you change settings. </p> </important>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The ID of the pipeline that you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656590 = path.getOrDefault("Id")
  valid_402656590 = validateParameter(valid_402656590, JString, required = true,
                                      default = nil)
  if valid_402656590 != nil:
    section.add "Id", valid_402656590
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656591 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-Security-Token", valid_402656591
  var valid_402656592 = header.getOrDefault("X-Amz-Signature")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Signature", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Algorithm", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-Date")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-Date", valid_402656595
  var valid_402656596 = header.getOrDefault("X-Amz-Credential")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "X-Amz-Credential", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656599: Call_UpdatePipeline_402656587; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Use the <code>UpdatePipeline</code> operation to update settings for a pipeline.</p> <important> <p>When you change pipeline settings, your changes take effect immediately. Jobs that you have already submitted and that Elastic Transcoder has not started to process are affected in addition to jobs that you submit after you change settings. </p> </important>
                                                                                         ## 
  let valid = call_402656599.validator(path, query, header, formData, body, _)
  let scheme = call_402656599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656599.makeUrl(scheme.get, call_402656599.host, call_402656599.base,
                                   call_402656599.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656599, uri, valid, _)

proc call*(call_402656600: Call_UpdatePipeline_402656587; body: JsonNode;
           Id: string): Recallable =
  ## updatePipeline
  ## <p> Use the <code>UpdatePipeline</code> operation to update settings for a pipeline.</p> <important> <p>When you change pipeline settings, your changes take effect immediately. Jobs that you have already submitted and that Elastic Transcoder has not started to process are affected in addition to jobs that you submit after you change settings. </p> </important>
  ##   
                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                          ## Id: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                          ##     
                                                                                                                                                                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                                                                                                                                                                          ## The 
                                                                                                                                                                                                                                                                                                                                                                                                          ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                                                          ## pipeline 
                                                                                                                                                                                                                                                                                                                                                                                                          ## that 
                                                                                                                                                                                                                                                                                                                                                                                                          ## you 
                                                                                                                                                                                                                                                                                                                                                                                                          ## want 
                                                                                                                                                                                                                                                                                                                                                                                                          ## to 
                                                                                                                                                                                                                                                                                                                                                                                                          ## update.
  var path_402656601 = newJObject()
  var body_402656602 = newJObject()
  if body != nil:
    body_402656602 = body
  add(path_402656601, "Id", newJString(Id))
  result = call_402656600.call(path_402656601, nil, nil, nil, body_402656602)

var updatePipeline* = Call_UpdatePipeline_402656587(name: "updatePipeline",
    meth: HttpMethod.HttpPut, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines/{Id}", validator: validate_UpdatePipeline_402656588,
    base: "/", makeUrl: url_UpdatePipeline_402656589,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReadPipeline_402656573 = ref object of OpenApiRestCall_402656044
proc url_ReadPipeline_402656575(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ReadPipeline_402656574(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## The ReadPipeline operation gets detailed information about a pipeline.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The identifier of the pipeline to read.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656576 = path.getOrDefault("Id")
  valid_402656576 = validateParameter(valid_402656576, JString, required = true,
                                      default = nil)
  if valid_402656576 != nil:
    section.add "Id", valid_402656576
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656577 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Security-Token", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-Signature")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-Signature", valid_402656578
  var valid_402656579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656579
  var valid_402656580 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-Algorithm", valid_402656580
  var valid_402656581 = header.getOrDefault("X-Amz-Date")
  valid_402656581 = validateParameter(valid_402656581, JString,
                                      required = false, default = nil)
  if valid_402656581 != nil:
    section.add "X-Amz-Date", valid_402656581
  var valid_402656582 = header.getOrDefault("X-Amz-Credential")
  valid_402656582 = validateParameter(valid_402656582, JString,
                                      required = false, default = nil)
  if valid_402656582 != nil:
    section.add "X-Amz-Credential", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656584: Call_ReadPipeline_402656573; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## The ReadPipeline operation gets detailed information about a pipeline.
                                                                                         ## 
  let valid = call_402656584.validator(path, query, header, formData, body, _)
  let scheme = call_402656584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656584.makeUrl(scheme.get, call_402656584.host, call_402656584.base,
                                   call_402656584.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656584, uri, valid, _)

proc call*(call_402656585: Call_ReadPipeline_402656573; Id: string): Recallable =
  ## readPipeline
  ## The ReadPipeline operation gets detailed information about a pipeline.
  ##   Id: 
                                                                           ## string (required)
                                                                           ##     
                                                                           ## : 
                                                                           ## The 
                                                                           ## identifier 
                                                                           ## of 
                                                                           ## the 
                                                                           ## pipeline 
                                                                           ## to 
                                                                           ## read.
  var path_402656586 = newJObject()
  add(path_402656586, "Id", newJString(Id))
  result = call_402656585.call(path_402656586, nil, nil, nil, nil)

var readPipeline* = Call_ReadPipeline_402656573(name: "readPipeline",
    meth: HttpMethod.HttpGet, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines/{Id}", validator: validate_ReadPipeline_402656574,
    base: "/", makeUrl: url_ReadPipeline_402656575,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePipeline_402656603 = ref object of OpenApiRestCall_402656044
proc url_DeletePipeline_402656605(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeletePipeline_402656604(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>The DeletePipeline operation removes a pipeline.</p> <p> You can only delete a pipeline that has never been used or that is not currently in use (doesn't contain any active jobs). If the pipeline is currently in use, <code>DeletePipeline</code> returns an error. </p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The identifier of the pipeline that you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656606 = path.getOrDefault("Id")
  valid_402656606 = validateParameter(valid_402656606, JString, required = true,
                                      default = nil)
  if valid_402656606 != nil:
    section.add "Id", valid_402656606
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656607 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "X-Amz-Security-Token", valid_402656607
  var valid_402656608 = header.getOrDefault("X-Amz-Signature")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-Signature", valid_402656608
  var valid_402656609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656609
  var valid_402656610 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-Algorithm", valid_402656610
  var valid_402656611 = header.getOrDefault("X-Amz-Date")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-Date", valid_402656611
  var valid_402656612 = header.getOrDefault("X-Amz-Credential")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "X-Amz-Credential", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656614: Call_DeletePipeline_402656603; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>The DeletePipeline operation removes a pipeline.</p> <p> You can only delete a pipeline that has never been used or that is not currently in use (doesn't contain any active jobs). If the pipeline is currently in use, <code>DeletePipeline</code> returns an error. </p>
                                                                                         ## 
  let valid = call_402656614.validator(path, query, header, formData, body, _)
  let scheme = call_402656614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656614.makeUrl(scheme.get, call_402656614.host, call_402656614.base,
                                   call_402656614.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656614, uri, valid, _)

proc call*(call_402656615: Call_DeletePipeline_402656603; Id: string): Recallable =
  ## deletePipeline
  ## <p>The DeletePipeline operation removes a pipeline.</p> <p> You can only delete a pipeline that has never been used or that is not currently in use (doesn't contain any active jobs). If the pipeline is currently in use, <code>DeletePipeline</code> returns an error. </p>
  ##   
                                                                                                                                                                                                                                                                                   ## Id: string (required)
                                                                                                                                                                                                                                                                                   ##     
                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                   ## The 
                                                                                                                                                                                                                                                                                   ## identifier 
                                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                   ## pipeline 
                                                                                                                                                                                                                                                                                   ## that 
                                                                                                                                                                                                                                                                                   ## you 
                                                                                                                                                                                                                                                                                   ## want 
                                                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                                                   ## delete.
  var path_402656616 = newJObject()
  add(path_402656616, "Id", newJString(Id))
  result = call_402656615.call(path_402656616, nil, nil, nil, nil)

var deletePipeline* = Call_DeletePipeline_402656603(name: "deletePipeline",
    meth: HttpMethod.HttpDelete, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines/{Id}", validator: validate_DeletePipeline_402656604,
    base: "/", makeUrl: url_DeletePipeline_402656605,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReadPreset_402656617 = ref object of OpenApiRestCall_402656044
proc url_ReadPreset_402656619(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ReadPreset_402656618(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## The ReadPreset operation gets detailed information about a preset.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The identifier of the preset for which you want to get detailed information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656620 = path.getOrDefault("Id")
  valid_402656620 = validateParameter(valid_402656620, JString, required = true,
                                      default = nil)
  if valid_402656620 != nil:
    section.add "Id", valid_402656620
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656621 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "X-Amz-Security-Token", valid_402656621
  var valid_402656622 = header.getOrDefault("X-Amz-Signature")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "X-Amz-Signature", valid_402656622
  var valid_402656623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656623
  var valid_402656624 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "X-Amz-Algorithm", valid_402656624
  var valid_402656625 = header.getOrDefault("X-Amz-Date")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "X-Amz-Date", valid_402656625
  var valid_402656626 = header.getOrDefault("X-Amz-Credential")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "X-Amz-Credential", valid_402656626
  var valid_402656627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656628: Call_ReadPreset_402656617; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## The ReadPreset operation gets detailed information about a preset.
                                                                                         ## 
  let valid = call_402656628.validator(path, query, header, formData, body, _)
  let scheme = call_402656628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656628.makeUrl(scheme.get, call_402656628.host, call_402656628.base,
                                   call_402656628.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656628, uri, valid, _)

proc call*(call_402656629: Call_ReadPreset_402656617; Id: string): Recallable =
  ## readPreset
  ## The ReadPreset operation gets detailed information about a preset.
  ##   Id: string 
                                                                       ## (required)
                                                                       ##     
                                                                       ## : 
                                                                       ## The 
                                                                       ## identifier of 
                                                                       ## the 
                                                                       ## preset 
                                                                       ## for 
                                                                       ## which 
                                                                       ## you 
                                                                       ## want to 
                                                                       ## get 
                                                                       ## detailed 
                                                                       ## information.
  var path_402656630 = newJObject()
  add(path_402656630, "Id", newJString(Id))
  result = call_402656629.call(path_402656630, nil, nil, nil, nil)

var readPreset* = Call_ReadPreset_402656617(name: "readPreset",
    meth: HttpMethod.HttpGet, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/presets/{Id}", validator: validate_ReadPreset_402656618,
    base: "/", makeUrl: url_ReadPreset_402656619,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePreset_402656631 = ref object of OpenApiRestCall_402656044
proc url_DeletePreset_402656633(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeletePreset_402656632(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>The DeletePreset operation removes a preset that you've added in an AWS region.</p> <note> <p>You can't delete the default presets that are included with Elastic Transcoder.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The identifier of the preset for which you want to get detailed information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656634 = path.getOrDefault("Id")
  valid_402656634 = validateParameter(valid_402656634, JString, required = true,
                                      default = nil)
  if valid_402656634 != nil:
    section.add "Id", valid_402656634
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656635 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "X-Amz-Security-Token", valid_402656635
  var valid_402656636 = header.getOrDefault("X-Amz-Signature")
  valid_402656636 = validateParameter(valid_402656636, JString,
                                      required = false, default = nil)
  if valid_402656636 != nil:
    section.add "X-Amz-Signature", valid_402656636
  var valid_402656637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656637
  var valid_402656638 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656638 = validateParameter(valid_402656638, JString,
                                      required = false, default = nil)
  if valid_402656638 != nil:
    section.add "X-Amz-Algorithm", valid_402656638
  var valid_402656639 = header.getOrDefault("X-Amz-Date")
  valid_402656639 = validateParameter(valid_402656639, JString,
                                      required = false, default = nil)
  if valid_402656639 != nil:
    section.add "X-Amz-Date", valid_402656639
  var valid_402656640 = header.getOrDefault("X-Amz-Credential")
  valid_402656640 = validateParameter(valid_402656640, JString,
                                      required = false, default = nil)
  if valid_402656640 != nil:
    section.add "X-Amz-Credential", valid_402656640
  var valid_402656641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656641 = validateParameter(valid_402656641, JString,
                                      required = false, default = nil)
  if valid_402656641 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656642: Call_DeletePreset_402656631; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>The DeletePreset operation removes a preset that you've added in an AWS region.</p> <note> <p>You can't delete the default presets that are included with Elastic Transcoder.</p> </note>
                                                                                         ## 
  let valid = call_402656642.validator(path, query, header, formData, body, _)
  let scheme = call_402656642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656642.makeUrl(scheme.get, call_402656642.host, call_402656642.base,
                                   call_402656642.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656642, uri, valid, _)

proc call*(call_402656643: Call_DeletePreset_402656631; Id: string): Recallable =
  ## deletePreset
  ## <p>The DeletePreset operation removes a preset that you've added in an AWS region.</p> <note> <p>You can't delete the default presets that are included with Elastic Transcoder.</p> </note>
  ##   
                                                                                                                                                                                                 ## Id: string (required)
                                                                                                                                                                                                 ##     
                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                 ## The 
                                                                                                                                                                                                 ## identifier 
                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## preset 
                                                                                                                                                                                                 ## for 
                                                                                                                                                                                                 ## which 
                                                                                                                                                                                                 ## you 
                                                                                                                                                                                                 ## want 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## get 
                                                                                                                                                                                                 ## detailed 
                                                                                                                                                                                                 ## information.
  var path_402656644 = newJObject()
  add(path_402656644, "Id", newJString(Id))
  result = call_402656643.call(path_402656644, nil, nil, nil, nil)

var deletePreset* = Call_DeletePreset_402656631(name: "deletePreset",
    meth: HttpMethod.HttpDelete, host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/presets/{Id}", validator: validate_DeletePreset_402656632,
    base: "/", makeUrl: url_DeletePreset_402656633,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobsByPipeline_402656645 = ref object of OpenApiRestCall_402656044
proc url_ListJobsByPipeline_402656647(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListJobsByPipeline_402656646(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656648 = path.getOrDefault("PipelineId")
  valid_402656648 = validateParameter(valid_402656648, JString, required = true,
                                      default = nil)
  if valid_402656648 != nil:
    section.add "PipelineId", valid_402656648
  result.add "path", section
  ## parameters in `query` object:
  ##   Ascending: JString
                                  ##            :  To list jobs in chronological order by the date and time that they were submitted, enter <code>true</code>. To list jobs in reverse chronological order, enter <code>false</code>. 
  ##   
                                                                                                                                                                                                                                      ## PageToken: JString
                                                                                                                                                                                                                                      ##            
                                                                                                                                                                                                                                      ## :  
                                                                                                                                                                                                                                      ## When 
                                                                                                                                                                                                                                      ## Elastic 
                                                                                                                                                                                                                                      ## Transcoder 
                                                                                                                                                                                                                                      ## returns 
                                                                                                                                                                                                                                      ## more 
                                                                                                                                                                                                                                      ## than 
                                                                                                                                                                                                                                      ## one 
                                                                                                                                                                                                                                      ## page 
                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                      ## results, 
                                                                                                                                                                                                                                      ## use 
                                                                                                                                                                                                                                      ## <code>pageToken</code> 
                                                                                                                                                                                                                                      ## in 
                                                                                                                                                                                                                                      ## subsequent 
                                                                                                                                                                                                                                      ## <code>GET</code> 
                                                                                                                                                                                                                                      ## requests 
                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                      ## get 
                                                                                                                                                                                                                                      ## each 
                                                                                                                                                                                                                                      ## successive 
                                                                                                                                                                                                                                      ## page 
                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                      ## results. 
  section = newJObject()
  var valid_402656649 = query.getOrDefault("Ascending")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "Ascending", valid_402656649
  var valid_402656650 = query.getOrDefault("PageToken")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "PageToken", valid_402656650
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656651 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "X-Amz-Security-Token", valid_402656651
  var valid_402656652 = header.getOrDefault("X-Amz-Signature")
  valid_402656652 = validateParameter(valid_402656652, JString,
                                      required = false, default = nil)
  if valid_402656652 != nil:
    section.add "X-Amz-Signature", valid_402656652
  var valid_402656653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656653
  var valid_402656654 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656654 = validateParameter(valid_402656654, JString,
                                      required = false, default = nil)
  if valid_402656654 != nil:
    section.add "X-Amz-Algorithm", valid_402656654
  var valid_402656655 = header.getOrDefault("X-Amz-Date")
  valid_402656655 = validateParameter(valid_402656655, JString,
                                      required = false, default = nil)
  if valid_402656655 != nil:
    section.add "X-Amz-Date", valid_402656655
  var valid_402656656 = header.getOrDefault("X-Amz-Credential")
  valid_402656656 = validateParameter(valid_402656656, JString,
                                      required = false, default = nil)
  if valid_402656656 != nil:
    section.add "X-Amz-Credential", valid_402656656
  var valid_402656657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656657 = validateParameter(valid_402656657, JString,
                                      required = false, default = nil)
  if valid_402656657 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656658: Call_ListJobsByPipeline_402656645;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>The ListJobsByPipeline operation gets a list of the jobs currently in a pipeline.</p> <p>Elastic Transcoder returns all of the jobs currently in the specified pipeline. The response body contains one element for each job that satisfies the search criteria.</p>
                                                                                         ## 
  let valid = call_402656658.validator(path, query, header, formData, body, _)
  let scheme = call_402656658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656658.makeUrl(scheme.get, call_402656658.host, call_402656658.base,
                                   call_402656658.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656658, uri, valid, _)

proc call*(call_402656659: Call_ListJobsByPipeline_402656645;
           PipelineId: string; Ascending: string = ""; PageToken: string = ""): Recallable =
  ## listJobsByPipeline
  ## <p>The ListJobsByPipeline operation gets a list of the jobs currently in a pipeline.</p> <p>Elastic Transcoder returns all of the jobs currently in the specified pipeline. The response body contains one element for each job that satisfies the search criteria.</p>
  ##   
                                                                                                                                                                                                                                                                            ## Ascending: string
                                                                                                                                                                                                                                                                            ##            
                                                                                                                                                                                                                                                                            ## :  
                                                                                                                                                                                                                                                                            ## To 
                                                                                                                                                                                                                                                                            ## list 
                                                                                                                                                                                                                                                                            ## jobs 
                                                                                                                                                                                                                                                                            ## in 
                                                                                                                                                                                                                                                                            ## chronological 
                                                                                                                                                                                                                                                                            ## order 
                                                                                                                                                                                                                                                                            ## by 
                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                            ## date 
                                                                                                                                                                                                                                                                            ## and 
                                                                                                                                                                                                                                                                            ## time 
                                                                                                                                                                                                                                                                            ## that 
                                                                                                                                                                                                                                                                            ## they 
                                                                                                                                                                                                                                                                            ## were 
                                                                                                                                                                                                                                                                            ## submitted, 
                                                                                                                                                                                                                                                                            ## enter 
                                                                                                                                                                                                                                                                            ## <code>true</code>. 
                                                                                                                                                                                                                                                                            ## To 
                                                                                                                                                                                                                                                                            ## list 
                                                                                                                                                                                                                                                                            ## jobs 
                                                                                                                                                                                                                                                                            ## in 
                                                                                                                                                                                                                                                                            ## reverse 
                                                                                                                                                                                                                                                                            ## chronological 
                                                                                                                                                                                                                                                                            ## order, 
                                                                                                                                                                                                                                                                            ## enter 
                                                                                                                                                                                                                                                                            ## <code>false</code>. 
  ##   
                                                                                                                                                                                                                                                                                                   ## PipelineId: string (required)
                                                                                                                                                                                                                                                                                                   ##             
                                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                                   ## The 
                                                                                                                                                                                                                                                                                                   ## ID 
                                                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                   ## pipeline 
                                                                                                                                                                                                                                                                                                   ## for 
                                                                                                                                                                                                                                                                                                   ## which 
                                                                                                                                                                                                                                                                                                   ## you 
                                                                                                                                                                                                                                                                                                   ## want 
                                                                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                                                                   ## get 
                                                                                                                                                                                                                                                                                                   ## job 
                                                                                                                                                                                                                                                                                                   ## information.
  ##   
                                                                                                                                                                                                                                                                                                                  ## PageToken: string
                                                                                                                                                                                                                                                                                                                  ##            
                                                                                                                                                                                                                                                                                                                  ## :  
                                                                                                                                                                                                                                                                                                                  ## When 
                                                                                                                                                                                                                                                                                                                  ## Elastic 
                                                                                                                                                                                                                                                                                                                  ## Transcoder 
                                                                                                                                                                                                                                                                                                                  ## returns 
                                                                                                                                                                                                                                                                                                                  ## more 
                                                                                                                                                                                                                                                                                                                  ## than 
                                                                                                                                                                                                                                                                                                                  ## one 
                                                                                                                                                                                                                                                                                                                  ## page 
                                                                                                                                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                                                                                                                                  ## results, 
                                                                                                                                                                                                                                                                                                                  ## use 
                                                                                                                                                                                                                                                                                                                  ## <code>pageToken</code> 
                                                                                                                                                                                                                                                                                                                  ## in 
                                                                                                                                                                                                                                                                                                                  ## subsequent 
                                                                                                                                                                                                                                                                                                                  ## <code>GET</code> 
                                                                                                                                                                                                                                                                                                                  ## requests 
                                                                                                                                                                                                                                                                                                                  ## to 
                                                                                                                                                                                                                                                                                                                  ## get 
                                                                                                                                                                                                                                                                                                                  ## each 
                                                                                                                                                                                                                                                                                                                  ## successive 
                                                                                                                                                                                                                                                                                                                  ## page 
                                                                                                                                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                                                                                                                                  ## results. 
  var path_402656660 = newJObject()
  var query_402656661 = newJObject()
  add(query_402656661, "Ascending", newJString(Ascending))
  add(path_402656660, "PipelineId", newJString(PipelineId))
  add(query_402656661, "PageToken", newJString(PageToken))
  result = call_402656659.call(path_402656660, query_402656661, nil, nil, nil)

var listJobsByPipeline* = Call_ListJobsByPipeline_402656645(
    name: "listJobsByPipeline", meth: HttpMethod.HttpGet,
    host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/jobsByPipeline/{PipelineId}",
    validator: validate_ListJobsByPipeline_402656646, base: "/",
    makeUrl: url_ListJobsByPipeline_402656647,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobsByStatus_402656662 = ref object of OpenApiRestCall_402656044
proc url_ListJobsByStatus_402656664(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListJobsByStatus_402656663(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## The ListJobsByStatus operation gets a list of jobs that have a specified status. The response body contains one element for each job that satisfies the search criteria.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Status: JString (required)
                                 ##         : To get information about all of the jobs associated with the current AWS account that have a given status, specify the following status: <code>Submitted</code>, <code>Progressing</code>, <code>Complete</code>, <code>Canceled</code>, or <code>Error</code>.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `Status` field"
  var valid_402656665 = path.getOrDefault("Status")
  valid_402656665 = validateParameter(valid_402656665, JString, required = true,
                                      default = nil)
  if valid_402656665 != nil:
    section.add "Status", valid_402656665
  result.add "path", section
  ## parameters in `query` object:
  ##   Ascending: JString
                                  ##            :  To list jobs in chronological order by the date and time that they were submitted, enter <code>true</code>. To list jobs in reverse chronological order, enter <code>false</code>. 
  ##   
                                                                                                                                                                                                                                      ## PageToken: JString
                                                                                                                                                                                                                                      ##            
                                                                                                                                                                                                                                      ## :  
                                                                                                                                                                                                                                      ## When 
                                                                                                                                                                                                                                      ## Elastic 
                                                                                                                                                                                                                                      ## Transcoder 
                                                                                                                                                                                                                                      ## returns 
                                                                                                                                                                                                                                      ## more 
                                                                                                                                                                                                                                      ## than 
                                                                                                                                                                                                                                      ## one 
                                                                                                                                                                                                                                      ## page 
                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                      ## results, 
                                                                                                                                                                                                                                      ## use 
                                                                                                                                                                                                                                      ## <code>pageToken</code> 
                                                                                                                                                                                                                                      ## in 
                                                                                                                                                                                                                                      ## subsequent 
                                                                                                                                                                                                                                      ## <code>GET</code> 
                                                                                                                                                                                                                                      ## requests 
                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                      ## get 
                                                                                                                                                                                                                                      ## each 
                                                                                                                                                                                                                                      ## successive 
                                                                                                                                                                                                                                      ## page 
                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                      ## results. 
  section = newJObject()
  var valid_402656666 = query.getOrDefault("Ascending")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "Ascending", valid_402656666
  var valid_402656667 = query.getOrDefault("PageToken")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "PageToken", valid_402656667
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656668 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656668 = validateParameter(valid_402656668, JString,
                                      required = false, default = nil)
  if valid_402656668 != nil:
    section.add "X-Amz-Security-Token", valid_402656668
  var valid_402656669 = header.getOrDefault("X-Amz-Signature")
  valid_402656669 = validateParameter(valid_402656669, JString,
                                      required = false, default = nil)
  if valid_402656669 != nil:
    section.add "X-Amz-Signature", valid_402656669
  var valid_402656670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656670 = validateParameter(valid_402656670, JString,
                                      required = false, default = nil)
  if valid_402656670 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656670
  var valid_402656671 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656671 = validateParameter(valid_402656671, JString,
                                      required = false, default = nil)
  if valid_402656671 != nil:
    section.add "X-Amz-Algorithm", valid_402656671
  var valid_402656672 = header.getOrDefault("X-Amz-Date")
  valid_402656672 = validateParameter(valid_402656672, JString,
                                      required = false, default = nil)
  if valid_402656672 != nil:
    section.add "X-Amz-Date", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Credential")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Credential", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656675: Call_ListJobsByStatus_402656662;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## The ListJobsByStatus operation gets a list of jobs that have a specified status. The response body contains one element for each job that satisfies the search criteria.
                                                                                         ## 
  let valid = call_402656675.validator(path, query, header, formData, body, _)
  let scheme = call_402656675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656675.makeUrl(scheme.get, call_402656675.host, call_402656675.base,
                                   call_402656675.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656675, uri, valid, _)

proc call*(call_402656676: Call_ListJobsByStatus_402656662; Status: string;
           Ascending: string = ""; PageToken: string = ""): Recallable =
  ## listJobsByStatus
  ## The ListJobsByStatus operation gets a list of jobs that have a specified status. The response body contains one element for each job that satisfies the search criteria.
  ##   
                                                                                                                                                                             ## Ascending: string
                                                                                                                                                                             ##            
                                                                                                                                                                             ## :  
                                                                                                                                                                             ## To 
                                                                                                                                                                             ## list 
                                                                                                                                                                             ## jobs 
                                                                                                                                                                             ## in 
                                                                                                                                                                             ## chronological 
                                                                                                                                                                             ## order 
                                                                                                                                                                             ## by 
                                                                                                                                                                             ## the 
                                                                                                                                                                             ## date 
                                                                                                                                                                             ## and 
                                                                                                                                                                             ## time 
                                                                                                                                                                             ## that 
                                                                                                                                                                             ## they 
                                                                                                                                                                             ## were 
                                                                                                                                                                             ## submitted, 
                                                                                                                                                                             ## enter 
                                                                                                                                                                             ## <code>true</code>. 
                                                                                                                                                                             ## To 
                                                                                                                                                                             ## list 
                                                                                                                                                                             ## jobs 
                                                                                                                                                                             ## in 
                                                                                                                                                                             ## reverse 
                                                                                                                                                                             ## chronological 
                                                                                                                                                                             ## order, 
                                                                                                                                                                             ## enter 
                                                                                                                                                                             ## <code>false</code>. 
  ##   
                                                                                                                                                                                                    ## Status: string (required)
                                                                                                                                                                                                    ##         
                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                    ## To 
                                                                                                                                                                                                    ## get 
                                                                                                                                                                                                    ## information 
                                                                                                                                                                                                    ## about 
                                                                                                                                                                                                    ## all 
                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                    ## jobs 
                                                                                                                                                                                                    ## associated 
                                                                                                                                                                                                    ## with 
                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                    ## current 
                                                                                                                                                                                                    ## AWS 
                                                                                                                                                                                                    ## account 
                                                                                                                                                                                                    ## that 
                                                                                                                                                                                                    ## have 
                                                                                                                                                                                                    ## a 
                                                                                                                                                                                                    ## given 
                                                                                                                                                                                                    ## status, 
                                                                                                                                                                                                    ## specify 
                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                    ## following 
                                                                                                                                                                                                    ## status: 
                                                                                                                                                                                                    ## <code>Submitted</code>, 
                                                                                                                                                                                                    ## <code>Progressing</code>, 
                                                                                                                                                                                                    ## <code>Complete</code>, 
                                                                                                                                                                                                    ## <code>Canceled</code>, 
                                                                                                                                                                                                    ## or 
                                                                                                                                                                                                    ## <code>Error</code>.
  ##   
                                                                                                                                                                                                                          ## PageToken: string
                                                                                                                                                                                                                          ##            
                                                                                                                                                                                                                          ## :  
                                                                                                                                                                                                                          ## When 
                                                                                                                                                                                                                          ## Elastic 
                                                                                                                                                                                                                          ## Transcoder 
                                                                                                                                                                                                                          ## returns 
                                                                                                                                                                                                                          ## more 
                                                                                                                                                                                                                          ## than 
                                                                                                                                                                                                                          ## one 
                                                                                                                                                                                                                          ## page 
                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                          ## results, 
                                                                                                                                                                                                                          ## use 
                                                                                                                                                                                                                          ## <code>pageToken</code> 
                                                                                                                                                                                                                          ## in 
                                                                                                                                                                                                                          ## subsequent 
                                                                                                                                                                                                                          ## <code>GET</code> 
                                                                                                                                                                                                                          ## requests 
                                                                                                                                                                                                                          ## to 
                                                                                                                                                                                                                          ## get 
                                                                                                                                                                                                                          ## each 
                                                                                                                                                                                                                          ## successive 
                                                                                                                                                                                                                          ## page 
                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                          ## results. 
  var path_402656677 = newJObject()
  var query_402656678 = newJObject()
  add(query_402656678, "Ascending", newJString(Ascending))
  add(path_402656677, "Status", newJString(Status))
  add(query_402656678, "PageToken", newJString(PageToken))
  result = call_402656676.call(path_402656677, query_402656678, nil, nil, nil)

var listJobsByStatus* = Call_ListJobsByStatus_402656662(
    name: "listJobsByStatus", meth: HttpMethod.HttpGet,
    host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/jobsByStatus/{Status}",
    validator: validate_ListJobsByStatus_402656663, base: "/",
    makeUrl: url_ListJobsByStatus_402656664,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestRole_402656679 = ref object of OpenApiRestCall_402656044
proc url_TestRole_402656681(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TestRole_402656680(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>The TestRole operation tests the IAM role used to create the pipeline.</p> <p>The <code>TestRole</code> action lets you determine whether the IAM role you are using has sufficient permissions to let Elastic Transcoder perform tasks associated with the transcoding process. The action attempts to assume the specified IAM role, checks read access to the input and output buckets, and tries to send a test notification to Amazon SNS topics that you specify.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656682 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "X-Amz-Security-Token", valid_402656682
  var valid_402656683 = header.getOrDefault("X-Amz-Signature")
  valid_402656683 = validateParameter(valid_402656683, JString,
                                      required = false, default = nil)
  if valid_402656683 != nil:
    section.add "X-Amz-Signature", valid_402656683
  var valid_402656684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656684
  var valid_402656685 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "X-Amz-Algorithm", valid_402656685
  var valid_402656686 = header.getOrDefault("X-Amz-Date")
  valid_402656686 = validateParameter(valid_402656686, JString,
                                      required = false, default = nil)
  if valid_402656686 != nil:
    section.add "X-Amz-Date", valid_402656686
  var valid_402656687 = header.getOrDefault("X-Amz-Credential")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "X-Amz-Credential", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656690: Call_TestRole_402656679; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>The TestRole operation tests the IAM role used to create the pipeline.</p> <p>The <code>TestRole</code> action lets you determine whether the IAM role you are using has sufficient permissions to let Elastic Transcoder perform tasks associated with the transcoding process. The action attempts to assume the specified IAM role, checks read access to the input and output buckets, and tries to send a test notification to Amazon SNS topics that you specify.</p>
                                                                                         ## 
  let valid = call_402656690.validator(path, query, header, formData, body, _)
  let scheme = call_402656690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656690.makeUrl(scheme.get, call_402656690.host, call_402656690.base,
                                   call_402656690.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656690, uri, valid, _)

proc call*(call_402656691: Call_TestRole_402656679; body: JsonNode): Recallable =
  ## testRole
  ## <p>The TestRole operation tests the IAM role used to create the pipeline.</p> <p>The <code>TestRole</code> action lets you determine whether the IAM role you are using has sufficient permissions to let Elastic Transcoder perform tasks associated with the transcoding process. The action attempts to assume the specified IAM role, checks read access to the input and output buckets, and tries to send a test notification to Amazon SNS topics that you specify.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656692 = newJObject()
  if body != nil:
    body_402656692 = body
  result = call_402656691.call(nil, nil, nil, nil, body_402656692)

var testRole* = Call_TestRole_402656679(name: "testRole",
                                        meth: HttpMethod.HttpPost, host: "elastictranscoder.amazonaws.com",
                                        route: "/2012-09-25/roleTests",
                                        validator: validate_TestRole_402656680,
                                        base: "/", makeUrl: url_TestRole_402656681,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipelineNotifications_402656693 = ref object of OpenApiRestCall_402656044
proc url_UpdatePipelineNotifications_402656695(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdatePipelineNotifications_402656694(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>With the UpdatePipelineNotifications operation, you can update Amazon Simple Notification Service (Amazon SNS) notifications for a pipeline.</p> <p>When you update notifications for a pipeline, Elastic Transcoder returns the values that you specified in the request.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The identifier of the pipeline for which you want to change notification settings.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656696 = path.getOrDefault("Id")
  valid_402656696 = validateParameter(valid_402656696, JString, required = true,
                                      default = nil)
  if valid_402656696 != nil:
    section.add "Id", valid_402656696
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656697 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656697 = validateParameter(valid_402656697, JString,
                                      required = false, default = nil)
  if valid_402656697 != nil:
    section.add "X-Amz-Security-Token", valid_402656697
  var valid_402656698 = header.getOrDefault("X-Amz-Signature")
  valid_402656698 = validateParameter(valid_402656698, JString,
                                      required = false, default = nil)
  if valid_402656698 != nil:
    section.add "X-Amz-Signature", valid_402656698
  var valid_402656699 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656699 = validateParameter(valid_402656699, JString,
                                      required = false, default = nil)
  if valid_402656699 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656699
  var valid_402656700 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656700 = validateParameter(valid_402656700, JString,
                                      required = false, default = nil)
  if valid_402656700 != nil:
    section.add "X-Amz-Algorithm", valid_402656700
  var valid_402656701 = header.getOrDefault("X-Amz-Date")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "X-Amz-Date", valid_402656701
  var valid_402656702 = header.getOrDefault("X-Amz-Credential")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "X-Amz-Credential", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656703
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656705: Call_UpdatePipelineNotifications_402656693;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>With the UpdatePipelineNotifications operation, you can update Amazon Simple Notification Service (Amazon SNS) notifications for a pipeline.</p> <p>When you update notifications for a pipeline, Elastic Transcoder returns the values that you specified in the request.</p>
                                                                                         ## 
  let valid = call_402656705.validator(path, query, header, formData, body, _)
  let scheme = call_402656705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656705.makeUrl(scheme.get, call_402656705.host, call_402656705.base,
                                   call_402656705.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656705, uri, valid, _)

proc call*(call_402656706: Call_UpdatePipelineNotifications_402656693;
           body: JsonNode; Id: string): Recallable =
  ## updatePipelineNotifications
  ## <p>With the UpdatePipelineNotifications operation, you can update Amazon Simple Notification Service (Amazon SNS) notifications for a pipeline.</p> <p>When you update notifications for a pipeline, Elastic Transcoder returns the values that you specified in the request.</p>
  ##   
                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                 ## Id: string (required)
                                                                                                                                                                                                                                                                                                                 ##     
                                                                                                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                                                                                                 ## The 
                                                                                                                                                                                                                                                                                                                 ## identifier 
                                                                                                                                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                                                                                                 ## pipeline 
                                                                                                                                                                                                                                                                                                                 ## for 
                                                                                                                                                                                                                                                                                                                 ## which 
                                                                                                                                                                                                                                                                                                                 ## you 
                                                                                                                                                                                                                                                                                                                 ## want 
                                                                                                                                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                                                                                                                                 ## change 
                                                                                                                                                                                                                                                                                                                 ## notification 
                                                                                                                                                                                                                                                                                                                 ## settings.
  var path_402656707 = newJObject()
  var body_402656708 = newJObject()
  if body != nil:
    body_402656708 = body
  add(path_402656707, "Id", newJString(Id))
  result = call_402656706.call(path_402656707, nil, nil, nil, body_402656708)

var updatePipelineNotifications* = Call_UpdatePipelineNotifications_402656693(
    name: "updatePipelineNotifications", meth: HttpMethod.HttpPost,
    host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines/{Id}/notifications",
    validator: validate_UpdatePipelineNotifications_402656694, base: "/",
    makeUrl: url_UpdatePipelineNotifications_402656695,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePipelineStatus_402656709 = ref object of OpenApiRestCall_402656044
proc url_UpdatePipelineStatus_402656711(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdatePipelineStatus_402656710(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>The UpdatePipelineStatus operation pauses or reactivates a pipeline, so that the pipeline stops or restarts the processing of jobs.</p> <p>Changing the pipeline status is useful if you want to cancel one or more jobs. You can't cancel jobs after Elastic Transcoder has started processing them; if you pause the pipeline to which you submitted the jobs, you have more time to get the job IDs for the jobs that you want to cancel, and to send a <a>CancelJob</a> request. </p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The identifier of the pipeline to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656712 = path.getOrDefault("Id")
  valid_402656712 = validateParameter(valid_402656712, JString, required = true,
                                      default = nil)
  if valid_402656712 != nil:
    section.add "Id", valid_402656712
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656713 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656713 = validateParameter(valid_402656713, JString,
                                      required = false, default = nil)
  if valid_402656713 != nil:
    section.add "X-Amz-Security-Token", valid_402656713
  var valid_402656714 = header.getOrDefault("X-Amz-Signature")
  valid_402656714 = validateParameter(valid_402656714, JString,
                                      required = false, default = nil)
  if valid_402656714 != nil:
    section.add "X-Amz-Signature", valid_402656714
  var valid_402656715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656715 = validateParameter(valid_402656715, JString,
                                      required = false, default = nil)
  if valid_402656715 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656715
  var valid_402656716 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656716 = validateParameter(valid_402656716, JString,
                                      required = false, default = nil)
  if valid_402656716 != nil:
    section.add "X-Amz-Algorithm", valid_402656716
  var valid_402656717 = header.getOrDefault("X-Amz-Date")
  valid_402656717 = validateParameter(valid_402656717, JString,
                                      required = false, default = nil)
  if valid_402656717 != nil:
    section.add "X-Amz-Date", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Credential")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Credential", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656719
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656721: Call_UpdatePipelineStatus_402656709;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>The UpdatePipelineStatus operation pauses or reactivates a pipeline, so that the pipeline stops or restarts the processing of jobs.</p> <p>Changing the pipeline status is useful if you want to cancel one or more jobs. You can't cancel jobs after Elastic Transcoder has started processing them; if you pause the pipeline to which you submitted the jobs, you have more time to get the job IDs for the jobs that you want to cancel, and to send a <a>CancelJob</a> request. </p>
                                                                                         ## 
  let valid = call_402656721.validator(path, query, header, formData, body, _)
  let scheme = call_402656721.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656721.makeUrl(scheme.get, call_402656721.host, call_402656721.base,
                                   call_402656721.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656721, uri, valid, _)

proc call*(call_402656722: Call_UpdatePipelineStatus_402656709; body: JsonNode;
           Id: string): Recallable =
  ## updatePipelineStatus
  ## <p>The UpdatePipelineStatus operation pauses or reactivates a pipeline, so that the pipeline stops or restarts the processing of jobs.</p> <p>Changing the pipeline status is useful if you want to cancel one or more jobs. You can't cancel jobs after Elastic Transcoder has started processing them; if you pause the pipeline to which you submitted the jobs, you have more time to get the job IDs for the jobs that you want to cancel, and to send a <a>CancelJob</a> request. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Id: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ##     
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## identifier 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## pipeline 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## update.
  var path_402656723 = newJObject()
  var body_402656724 = newJObject()
  if body != nil:
    body_402656724 = body
  add(path_402656723, "Id", newJString(Id))
  result = call_402656722.call(path_402656723, nil, nil, nil, body_402656724)

var updatePipelineStatus* = Call_UpdatePipelineStatus_402656709(
    name: "updatePipelineStatus", meth: HttpMethod.HttpPost,
    host: "elastictranscoder.amazonaws.com",
    route: "/2012-09-25/pipelines/{Id}/status",
    validator: validate_UpdatePipelineStatus_402656710, base: "/",
    makeUrl: url_UpdatePipelineStatus_402656711,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}