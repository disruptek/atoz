
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Data Exchange
## version: 2017-07-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>AWS Data Exchange is a service that makes it easy for AWS customers to exchange data in the cloud. You can use the AWS Data Exchange APIs to create, update, manage, and access file-based data set in the AWS Cloud.</p><p>As a subscriber, you can view and access the data sets that you have an entitlement to through a subscription. You can use the APIS to download or copy your entitled data sets to Amazon S3 for use across a variety of AWS analytics and machine learning services.</p><p>As a provider, you can create and manage your data sets that you would like to publish to a product. Being able to package and provide your data sets into products requires a few steps to determine eligibility. For more information, visit the AWS Data Exchange User Guide.</p><p>A data set is a collection of data that can be changed or updated over time. Data sets can be updated using revisions, which represent a new version or incremental change to a data set.  A revision contains one or more assets. An asset in AWS Data Exchange is a piece of data that can be stored as an Amazon S3 object. The asset can be a structured data file, an image file, or some other data file. Jobs are asynchronous import or export operations used to create or copy assets.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/dataexchange/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "dataexchange.ap-northeast-1.amazonaws.com", "ap-southeast-1": "dataexchange.ap-southeast-1.amazonaws.com",
                           "us-west-2": "dataexchange.us-west-2.amazonaws.com",
                           "eu-west-2": "dataexchange.eu-west-2.amazonaws.com", "ap-northeast-3": "dataexchange.ap-northeast-3.amazonaws.com", "eu-central-1": "dataexchange.eu-central-1.amazonaws.com",
                           "us-east-2": "dataexchange.us-east-2.amazonaws.com",
                           "us-east-1": "dataexchange.us-east-1.amazonaws.com", "cn-northwest-1": "dataexchange.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "dataexchange.ap-south-1.amazonaws.com", "eu-north-1": "dataexchange.eu-north-1.amazonaws.com", "ap-northeast-2": "dataexchange.ap-northeast-2.amazonaws.com",
                           "us-west-1": "dataexchange.us-west-1.amazonaws.com", "us-gov-east-1": "dataexchange.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "dataexchange.eu-west-3.amazonaws.com", "cn-north-1": "dataexchange.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "dataexchange.sa-east-1.amazonaws.com",
                           "eu-west-1": "dataexchange.eu-west-1.amazonaws.com", "us-gov-west-1": "dataexchange.us-gov-west-1.amazonaws.com", "ap-southeast-2": "dataexchange.ap-southeast-2.amazonaws.com", "ca-central-1": "dataexchange.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "dataexchange.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "dataexchange.ap-southeast-1.amazonaws.com",
      "us-west-2": "dataexchange.us-west-2.amazonaws.com",
      "eu-west-2": "dataexchange.eu-west-2.amazonaws.com",
      "ap-northeast-3": "dataexchange.ap-northeast-3.amazonaws.com",
      "eu-central-1": "dataexchange.eu-central-1.amazonaws.com",
      "us-east-2": "dataexchange.us-east-2.amazonaws.com",
      "us-east-1": "dataexchange.us-east-1.amazonaws.com",
      "cn-northwest-1": "dataexchange.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "dataexchange.ap-south-1.amazonaws.com",
      "eu-north-1": "dataexchange.eu-north-1.amazonaws.com",
      "ap-northeast-2": "dataexchange.ap-northeast-2.amazonaws.com",
      "us-west-1": "dataexchange.us-west-1.amazonaws.com",
      "us-gov-east-1": "dataexchange.us-gov-east-1.amazonaws.com",
      "eu-west-3": "dataexchange.eu-west-3.amazonaws.com",
      "cn-north-1": "dataexchange.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "dataexchange.sa-east-1.amazonaws.com",
      "eu-west-1": "dataexchange.eu-west-1.amazonaws.com",
      "us-gov-west-1": "dataexchange.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "dataexchange.ap-southeast-2.amazonaws.com",
      "ca-central-1": "dataexchange.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "dataexchange"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_GetJob_601727 = ref object of OpenApiRestCall_601389
proc url_GetJob_601729(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "JobId" in path, "`JobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/jobs/"),
               (kind: VariableSegment, value: "JobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetJob_601728(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation returns information about a job.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   JobId: JString (required)
  ##        : The unique identifier for a job.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `JobId` field"
  var valid_601855 = path.getOrDefault("JobId")
  valid_601855 = validateParameter(valid_601855, JString, required = true,
                                 default = nil)
  if valid_601855 != nil:
    section.add "JobId", valid_601855
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

proc call*(call_601885: Call_GetJob_601727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job.
  ## 
  let valid = call_601885.validator(path, query, header, formData, body)
  let scheme = call_601885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601885.url(scheme.get, call_601885.host, call_601885.base,
                         call_601885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601885, url, valid)

proc call*(call_601956: Call_GetJob_601727; JobId: string): Recallable =
  ## getJob
  ## This operation returns information about a job.
  ##   JobId: string (required)
  ##        : The unique identifier for a job.
  var path_601957 = newJObject()
  add(path_601957, "JobId", newJString(JobId))
  result = call_601956.call(path_601957, nil, nil, nil, nil)

var getJob* = Call_GetJob_601727(name: "getJob", meth: HttpMethod.HttpGet,
                              host: "dataexchange.amazonaws.com",
                              route: "/v1/jobs/{JobId}",
                              validator: validate_GetJob_601728, base: "/",
                              url: url_GetJob_601729,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartJob_602011 = ref object of OpenApiRestCall_601389
proc url_StartJob_602013(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "JobId" in path, "`JobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/jobs/"),
               (kind: VariableSegment, value: "JobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartJob_602012(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation starts a job.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   JobId: JString (required)
  ##        : The unique identifier for a job.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `JobId` field"
  var valid_602014 = path.getOrDefault("JobId")
  valid_602014 = validateParameter(valid_602014, JString, required = true,
                                 default = nil)
  if valid_602014 != nil:
    section.add "JobId", valid_602014
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

proc call*(call_602022: Call_StartJob_602011; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation starts a job.
  ## 
  let valid = call_602022.validator(path, query, header, formData, body)
  let scheme = call_602022.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602022.url(scheme.get, call_602022.host, call_602022.base,
                         call_602022.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602022, url, valid)

proc call*(call_602023: Call_StartJob_602011; JobId: string): Recallable =
  ## startJob
  ## This operation starts a job.
  ##   JobId: string (required)
  ##        : The unique identifier for a job.
  var path_602024 = newJObject()
  add(path_602024, "JobId", newJString(JobId))
  result = call_602023.call(path_602024, nil, nil, nil, nil)

var startJob* = Call_StartJob_602011(name: "startJob", meth: HttpMethod.HttpPatch,
                                  host: "dataexchange.amazonaws.com",
                                  route: "/v1/jobs/{JobId}",
                                  validator: validate_StartJob_602012, base: "/",
                                  url: url_StartJob_602013,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelJob_601997 = ref object of OpenApiRestCall_601389
proc url_CancelJob_601999(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "JobId" in path, "`JobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/jobs/"),
               (kind: VariableSegment, value: "JobId")]
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
  ## This operation cancels a job. Jobs can be cancelled only when they are in the WAITING state.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   JobId: JString (required)
  ##        : The unique identifier for a job.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `JobId` field"
  var valid_602000 = path.getOrDefault("JobId")
  valid_602000 = validateParameter(valid_602000, JString, required = true,
                                 default = nil)
  if valid_602000 != nil:
    section.add "JobId", valid_602000
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
  ## This operation cancels a job. Jobs can be cancelled only when they are in the WAITING state.
  ## 
  let valid = call_602008.validator(path, query, header, formData, body)
  let scheme = call_602008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602008.url(scheme.get, call_602008.host, call_602008.base,
                         call_602008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602008, url, valid)

proc call*(call_602009: Call_CancelJob_601997; JobId: string): Recallable =
  ## cancelJob
  ## This operation cancels a job. Jobs can be cancelled only when they are in the WAITING state.
  ##   JobId: string (required)
  ##        : The unique identifier for a job.
  var path_602010 = newJObject()
  add(path_602010, "JobId", newJString(JobId))
  result = call_602009.call(path_602010, nil, nil, nil, nil)

var cancelJob* = Call_CancelJob_601997(name: "cancelJob",
                                    meth: HttpMethod.HttpDelete,
                                    host: "dataexchange.amazonaws.com",
                                    route: "/v1/jobs/{JobId}",
                                    validator: validate_CancelJob_601998,
                                    base: "/", url: url_CancelJob_601999,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSet_602043 = ref object of OpenApiRestCall_601389
proc url_CreateDataSet_602045(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDataSet_602044(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation creates a data set.
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
  var valid_602046 = header.getOrDefault("X-Amz-Signature")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Signature", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Content-Sha256", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Date")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Date", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Credential")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Credential", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Security-Token")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Security-Token", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-Algorithm")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Algorithm", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-SignedHeaders", valid_602052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602054: Call_CreateDataSet_602043; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation creates a data set.
  ## 
  let valid = call_602054.validator(path, query, header, formData, body)
  let scheme = call_602054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602054.url(scheme.get, call_602054.host, call_602054.base,
                         call_602054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602054, url, valid)

proc call*(call_602055: Call_CreateDataSet_602043; body: JsonNode): Recallable =
  ## createDataSet
  ## This operation creates a data set.
  ##   body: JObject (required)
  var body_602056 = newJObject()
  if body != nil:
    body_602056 = body
  result = call_602055.call(nil, nil, nil, nil, body_602056)

var createDataSet* = Call_CreateDataSet_602043(name: "createDataSet",
    meth: HttpMethod.HttpPost, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets", validator: validate_CreateDataSet_602044, base: "/",
    url: url_CreateDataSet_602045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSets_602025 = ref object of OpenApiRestCall_601389
proc url_ListDataSets_602027(protocol: Scheme; host: string; base: string;
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

proc validate_ListDataSets_602026(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation lists your data sets. When listing by origin OWNED, results are sorted by CreatedAt in descending order. When listing by origin ENTITLED, there is no order and the maxResults parameter is ignored.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   origin: JString
  ##         : A property that defines the data set as OWNED by the account (for providers) or ENTITLED to the account (for subscribers).
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of results returned by a single call.
  section = newJObject()
  var valid_602028 = query.getOrDefault("nextToken")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "nextToken", valid_602028
  var valid_602029 = query.getOrDefault("MaxResults")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "MaxResults", valid_602029
  var valid_602030 = query.getOrDefault("origin")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "origin", valid_602030
  var valid_602031 = query.getOrDefault("NextToken")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "NextToken", valid_602031
  var valid_602032 = query.getOrDefault("maxResults")
  valid_602032 = validateParameter(valid_602032, JInt, required = false, default = nil)
  if valid_602032 != nil:
    section.add "maxResults", valid_602032
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
  var valid_602033 = header.getOrDefault("X-Amz-Signature")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Signature", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Content-Sha256", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Date")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Date", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-Credential")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Credential", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-Security-Token")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-Security-Token", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-Algorithm")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Algorithm", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-SignedHeaders", valid_602039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602040: Call_ListDataSets_602025; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists your data sets. When listing by origin OWNED, results are sorted by CreatedAt in descending order. When listing by origin ENTITLED, there is no order and the maxResults parameter is ignored.
  ## 
  let valid = call_602040.validator(path, query, header, formData, body)
  let scheme = call_602040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602040.url(scheme.get, call_602040.host, call_602040.base,
                         call_602040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602040, url, valid)

proc call*(call_602041: Call_ListDataSets_602025; nextToken: string = "";
          MaxResults: string = ""; origin: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listDataSets
  ## This operation lists your data sets. When listing by origin OWNED, results are sorted by CreatedAt in descending order. When listing by origin ENTITLED, there is no order and the maxResults parameter is ignored.
  ##   nextToken: string
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   origin: string
  ##         : A property that defines the data set as OWNED by the account (for providers) or ENTITLED to the account (for subscribers).
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results returned by a single call.
  var query_602042 = newJObject()
  add(query_602042, "nextToken", newJString(nextToken))
  add(query_602042, "MaxResults", newJString(MaxResults))
  add(query_602042, "origin", newJString(origin))
  add(query_602042, "NextToken", newJString(NextToken))
  add(query_602042, "maxResults", newJInt(maxResults))
  result = call_602041.call(nil, query_602042, nil, nil, nil)

var listDataSets* = Call_ListDataSets_602025(name: "listDataSets",
    meth: HttpMethod.HttpGet, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets", validator: validate_ListDataSets_602026, base: "/",
    url: url_ListDataSets_602027, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_602076 = ref object of OpenApiRestCall_601389
proc url_CreateJob_602078(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateJob_602077(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation creates a job.
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
  var valid_602079 = header.getOrDefault("X-Amz-Signature")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Signature", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Content-Sha256", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-Date")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-Date", valid_602081
  var valid_602082 = header.getOrDefault("X-Amz-Credential")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-Credential", valid_602082
  var valid_602083 = header.getOrDefault("X-Amz-Security-Token")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-Security-Token", valid_602083
  var valid_602084 = header.getOrDefault("X-Amz-Algorithm")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-Algorithm", valid_602084
  var valid_602085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-SignedHeaders", valid_602085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602087: Call_CreateJob_602076; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation creates a job.
  ## 
  let valid = call_602087.validator(path, query, header, formData, body)
  let scheme = call_602087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602087.url(scheme.get, call_602087.host, call_602087.base,
                         call_602087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602087, url, valid)

proc call*(call_602088: Call_CreateJob_602076; body: JsonNode): Recallable =
  ## createJob
  ## This operation creates a job.
  ##   body: JObject (required)
  var body_602089 = newJObject()
  if body != nil:
    body_602089 = body
  result = call_602088.call(nil, nil, nil, nil, body_602089)

var createJob* = Call_CreateJob_602076(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "dataexchange.amazonaws.com",
                                    route: "/v1/jobs",
                                    validator: validate_CreateJob_602077,
                                    base: "/", url: url_CreateJob_602078,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_602057 = ref object of OpenApiRestCall_601389
proc url_ListJobs_602059(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListJobs_602058(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation lists your jobs sorted by CreatedAt in descending order.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   dataSetId: JString
  ##            : The unique identifier for a data set.
  ##   nextToken: JString
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   revisionId: JString
  ##             : The unique identifier for a revision.
  ##   maxResults: JInt
  ##             : The maximum number of results returned by a single call.
  section = newJObject()
  var valid_602060 = query.getOrDefault("dataSetId")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "dataSetId", valid_602060
  var valid_602061 = query.getOrDefault("nextToken")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "nextToken", valid_602061
  var valid_602062 = query.getOrDefault("MaxResults")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "MaxResults", valid_602062
  var valid_602063 = query.getOrDefault("NextToken")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "NextToken", valid_602063
  var valid_602064 = query.getOrDefault("revisionId")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "revisionId", valid_602064
  var valid_602065 = query.getOrDefault("maxResults")
  valid_602065 = validateParameter(valid_602065, JInt, required = false, default = nil)
  if valid_602065 != nil:
    section.add "maxResults", valid_602065
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
  var valid_602066 = header.getOrDefault("X-Amz-Signature")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Signature", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-Content-Sha256", valid_602067
  var valid_602068 = header.getOrDefault("X-Amz-Date")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Date", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-Credential")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-Credential", valid_602069
  var valid_602070 = header.getOrDefault("X-Amz-Security-Token")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Security-Token", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-Algorithm")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-Algorithm", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-SignedHeaders", valid_602072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602073: Call_ListJobs_602057; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists your jobs sorted by CreatedAt in descending order.
  ## 
  let valid = call_602073.validator(path, query, header, formData, body)
  let scheme = call_602073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602073.url(scheme.get, call_602073.host, call_602073.base,
                         call_602073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602073, url, valid)

proc call*(call_602074: Call_ListJobs_602057; dataSetId: string = "";
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          revisionId: string = ""; maxResults: int = 0): Recallable =
  ## listJobs
  ## This operation lists your jobs sorted by CreatedAt in descending order.
  ##   dataSetId: string
  ##            : The unique identifier for a data set.
  ##   nextToken: string
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   revisionId: string
  ##             : The unique identifier for a revision.
  ##   maxResults: int
  ##             : The maximum number of results returned by a single call.
  var query_602075 = newJObject()
  add(query_602075, "dataSetId", newJString(dataSetId))
  add(query_602075, "nextToken", newJString(nextToken))
  add(query_602075, "MaxResults", newJString(MaxResults))
  add(query_602075, "NextToken", newJString(NextToken))
  add(query_602075, "revisionId", newJString(revisionId))
  add(query_602075, "maxResults", newJInt(maxResults))
  result = call_602074.call(nil, query_602075, nil, nil, nil)

var listJobs* = Call_ListJobs_602057(name: "listJobs", meth: HttpMethod.HttpGet,
                                  host: "dataexchange.amazonaws.com",
                                  route: "/v1/jobs", validator: validate_ListJobs_602058,
                                  base: "/", url: url_ListJobs_602059,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRevision_602109 = ref object of OpenApiRestCall_601389
proc url_CreateRevision_602111(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateRevision_602110(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## This operation creates a revision for a data set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DataSetId` field"
  var valid_602112 = path.getOrDefault("DataSetId")
  valid_602112 = validateParameter(valid_602112, JString, required = true,
                                 default = nil)
  if valid_602112 != nil:
    section.add "DataSetId", valid_602112
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
  var valid_602113 = header.getOrDefault("X-Amz-Signature")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-Signature", valid_602113
  var valid_602114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "X-Amz-Content-Sha256", valid_602114
  var valid_602115 = header.getOrDefault("X-Amz-Date")
  valid_602115 = validateParameter(valid_602115, JString, required = false,
                                 default = nil)
  if valid_602115 != nil:
    section.add "X-Amz-Date", valid_602115
  var valid_602116 = header.getOrDefault("X-Amz-Credential")
  valid_602116 = validateParameter(valid_602116, JString, required = false,
                                 default = nil)
  if valid_602116 != nil:
    section.add "X-Amz-Credential", valid_602116
  var valid_602117 = header.getOrDefault("X-Amz-Security-Token")
  valid_602117 = validateParameter(valid_602117, JString, required = false,
                                 default = nil)
  if valid_602117 != nil:
    section.add "X-Amz-Security-Token", valid_602117
  var valid_602118 = header.getOrDefault("X-Amz-Algorithm")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "X-Amz-Algorithm", valid_602118
  var valid_602119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-SignedHeaders", valid_602119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602121: Call_CreateRevision_602109; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation creates a revision for a data set.
  ## 
  let valid = call_602121.validator(path, query, header, formData, body)
  let scheme = call_602121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602121.url(scheme.get, call_602121.host, call_602121.base,
                         call_602121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602121, url, valid)

proc call*(call_602122: Call_CreateRevision_602109; DataSetId: string; body: JsonNode): Recallable =
  ## createRevision
  ## This operation creates a revision for a data set.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  ##   body: JObject (required)
  var path_602123 = newJObject()
  var body_602124 = newJObject()
  add(path_602123, "DataSetId", newJString(DataSetId))
  if body != nil:
    body_602124 = body
  result = call_602122.call(path_602123, nil, nil, nil, body_602124)

var createRevision* = Call_CreateRevision_602109(name: "createRevision",
    meth: HttpMethod.HttpPost, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions",
    validator: validate_CreateRevision_602110, base: "/", url: url_CreateRevision_602111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSetRevisions_602090 = ref object of OpenApiRestCall_601389
proc url_ListDataSetRevisions_602092(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDataSetRevisions_602091(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation lists a data set's revisions sorted by CreatedAt in descending order.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DataSetId` field"
  var valid_602093 = path.getOrDefault("DataSetId")
  valid_602093 = validateParameter(valid_602093, JString, required = true,
                                 default = nil)
  if valid_602093 != nil:
    section.add "DataSetId", valid_602093
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of results returned by a single call.
  section = newJObject()
  var valid_602094 = query.getOrDefault("nextToken")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "nextToken", valid_602094
  var valid_602095 = query.getOrDefault("MaxResults")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "MaxResults", valid_602095
  var valid_602096 = query.getOrDefault("NextToken")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "NextToken", valid_602096
  var valid_602097 = query.getOrDefault("maxResults")
  valid_602097 = validateParameter(valid_602097, JInt, required = false, default = nil)
  if valid_602097 != nil:
    section.add "maxResults", valid_602097
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
  var valid_602098 = header.getOrDefault("X-Amz-Signature")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "X-Amz-Signature", valid_602098
  var valid_602099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "X-Amz-Content-Sha256", valid_602099
  var valid_602100 = header.getOrDefault("X-Amz-Date")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "X-Amz-Date", valid_602100
  var valid_602101 = header.getOrDefault("X-Amz-Credential")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "X-Amz-Credential", valid_602101
  var valid_602102 = header.getOrDefault("X-Amz-Security-Token")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "X-Amz-Security-Token", valid_602102
  var valid_602103 = header.getOrDefault("X-Amz-Algorithm")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-Algorithm", valid_602103
  var valid_602104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "X-Amz-SignedHeaders", valid_602104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602105: Call_ListDataSetRevisions_602090; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists a data set's revisions sorted by CreatedAt in descending order.
  ## 
  let valid = call_602105.validator(path, query, header, formData, body)
  let scheme = call_602105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602105.url(scheme.get, call_602105.host, call_602105.base,
                         call_602105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602105, url, valid)

proc call*(call_602106: Call_ListDataSetRevisions_602090; DataSetId: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listDataSetRevisions
  ## This operation lists a data set's revisions sorted by CreatedAt in descending order.
  ##   nextToken: string
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  ##   maxResults: int
  ##             : The maximum number of results returned by a single call.
  var path_602107 = newJObject()
  var query_602108 = newJObject()
  add(query_602108, "nextToken", newJString(nextToken))
  add(query_602108, "MaxResults", newJString(MaxResults))
  add(query_602108, "NextToken", newJString(NextToken))
  add(path_602107, "DataSetId", newJString(DataSetId))
  add(query_602108, "maxResults", newJInt(maxResults))
  result = call_602106.call(path_602107, query_602108, nil, nil, nil)

var listDataSetRevisions* = Call_ListDataSetRevisions_602090(
    name: "listDataSetRevisions", meth: HttpMethod.HttpGet,
    host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions",
    validator: validate_ListDataSetRevisions_602091, base: "/",
    url: url_ListDataSetRevisions_602092, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAsset_602125 = ref object of OpenApiRestCall_601389
proc url_GetAsset_602127(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  assert "AssetId" in path, "`AssetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions/"),
               (kind: VariableSegment, value: "RevisionId"),
               (kind: ConstantSegment, value: "/assets/"),
               (kind: VariableSegment, value: "AssetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAsset_602126(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation returns information about an asset.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  ##   AssetId: JString (required)
  ##          : The unique identifier for an asset.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_602128 = path.getOrDefault("RevisionId")
  valid_602128 = validateParameter(valid_602128, JString, required = true,
                                 default = nil)
  if valid_602128 != nil:
    section.add "RevisionId", valid_602128
  var valid_602129 = path.getOrDefault("DataSetId")
  valid_602129 = validateParameter(valid_602129, JString, required = true,
                                 default = nil)
  if valid_602129 != nil:
    section.add "DataSetId", valid_602129
  var valid_602130 = path.getOrDefault("AssetId")
  valid_602130 = validateParameter(valid_602130, JString, required = true,
                                 default = nil)
  if valid_602130 != nil:
    section.add "AssetId", valid_602130
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

proc call*(call_602138: Call_GetAsset_602125; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about an asset.
  ## 
  let valid = call_602138.validator(path, query, header, formData, body)
  let scheme = call_602138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602138.url(scheme.get, call_602138.host, call_602138.base,
                         call_602138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602138, url, valid)

proc call*(call_602139: Call_GetAsset_602125; RevisionId: string; DataSetId: string;
          AssetId: string): Recallable =
  ## getAsset
  ## This operation returns information about an asset.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  ##   AssetId: string (required)
  ##          : The unique identifier for an asset.
  var path_602140 = newJObject()
  add(path_602140, "RevisionId", newJString(RevisionId))
  add(path_602140, "DataSetId", newJString(DataSetId))
  add(path_602140, "AssetId", newJString(AssetId))
  result = call_602139.call(path_602140, nil, nil, nil, nil)

var getAsset* = Call_GetAsset_602125(name: "getAsset", meth: HttpMethod.HttpGet,
                                  host: "dataexchange.amazonaws.com", route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}/assets/{AssetId}",
                                  validator: validate_GetAsset_602126, base: "/",
                                  url: url_GetAsset_602127,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAsset_602157 = ref object of OpenApiRestCall_601389
proc url_UpdateAsset_602159(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  assert "AssetId" in path, "`AssetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions/"),
               (kind: VariableSegment, value: "RevisionId"),
               (kind: ConstantSegment, value: "/assets/"),
               (kind: VariableSegment, value: "AssetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateAsset_602158(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation updates an asset.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  ##   AssetId: JString (required)
  ##          : The unique identifier for an asset.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_602160 = path.getOrDefault("RevisionId")
  valid_602160 = validateParameter(valid_602160, JString, required = true,
                                 default = nil)
  if valid_602160 != nil:
    section.add "RevisionId", valid_602160
  var valid_602161 = path.getOrDefault("DataSetId")
  valid_602161 = validateParameter(valid_602161, JString, required = true,
                                 default = nil)
  if valid_602161 != nil:
    section.add "DataSetId", valid_602161
  var valid_602162 = path.getOrDefault("AssetId")
  valid_602162 = validateParameter(valid_602162, JString, required = true,
                                 default = nil)
  if valid_602162 != nil:
    section.add "AssetId", valid_602162
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
  var valid_602163 = header.getOrDefault("X-Amz-Signature")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Signature", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-Content-Sha256", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Date")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Date", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Credential")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Credential", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Security-Token")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Security-Token", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-Algorithm")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Algorithm", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-SignedHeaders", valid_602169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602171: Call_UpdateAsset_602157; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation updates an asset.
  ## 
  let valid = call_602171.validator(path, query, header, formData, body)
  let scheme = call_602171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602171.url(scheme.get, call_602171.host, call_602171.base,
                         call_602171.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602171, url, valid)

proc call*(call_602172: Call_UpdateAsset_602157; RevisionId: string;
          DataSetId: string; body: JsonNode; AssetId: string): Recallable =
  ## updateAsset
  ## This operation updates an asset.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  ##   body: JObject (required)
  ##   AssetId: string (required)
  ##          : The unique identifier for an asset.
  var path_602173 = newJObject()
  var body_602174 = newJObject()
  add(path_602173, "RevisionId", newJString(RevisionId))
  add(path_602173, "DataSetId", newJString(DataSetId))
  if body != nil:
    body_602174 = body
  add(path_602173, "AssetId", newJString(AssetId))
  result = call_602172.call(path_602173, nil, nil, nil, body_602174)

var updateAsset* = Call_UpdateAsset_602157(name: "updateAsset",
                                        meth: HttpMethod.HttpPatch,
                                        host: "dataexchange.amazonaws.com", route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}/assets/{AssetId}",
                                        validator: validate_UpdateAsset_602158,
                                        base: "/", url: url_UpdateAsset_602159,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAsset_602141 = ref object of OpenApiRestCall_601389
proc url_DeleteAsset_602143(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  assert "AssetId" in path, "`AssetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions/"),
               (kind: VariableSegment, value: "RevisionId"),
               (kind: ConstantSegment, value: "/assets/"),
               (kind: VariableSegment, value: "AssetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAsset_602142(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation deletes an asset.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  ##   AssetId: JString (required)
  ##          : The unique identifier for an asset.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_602144 = path.getOrDefault("RevisionId")
  valid_602144 = validateParameter(valid_602144, JString, required = true,
                                 default = nil)
  if valid_602144 != nil:
    section.add "RevisionId", valid_602144
  var valid_602145 = path.getOrDefault("DataSetId")
  valid_602145 = validateParameter(valid_602145, JString, required = true,
                                 default = nil)
  if valid_602145 != nil:
    section.add "DataSetId", valid_602145
  var valid_602146 = path.getOrDefault("AssetId")
  valid_602146 = validateParameter(valid_602146, JString, required = true,
                                 default = nil)
  if valid_602146 != nil:
    section.add "AssetId", valid_602146
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
  var valid_602147 = header.getOrDefault("X-Amz-Signature")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-Signature", valid_602147
  var valid_602148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "X-Amz-Content-Sha256", valid_602148
  var valid_602149 = header.getOrDefault("X-Amz-Date")
  valid_602149 = validateParameter(valid_602149, JString, required = false,
                                 default = nil)
  if valid_602149 != nil:
    section.add "X-Amz-Date", valid_602149
  var valid_602150 = header.getOrDefault("X-Amz-Credential")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Credential", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-Security-Token")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Security-Token", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-Algorithm")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Algorithm", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-SignedHeaders", valid_602153
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602154: Call_DeleteAsset_602141; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation deletes an asset.
  ## 
  let valid = call_602154.validator(path, query, header, formData, body)
  let scheme = call_602154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602154.url(scheme.get, call_602154.host, call_602154.base,
                         call_602154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602154, url, valid)

proc call*(call_602155: Call_DeleteAsset_602141; RevisionId: string;
          DataSetId: string; AssetId: string): Recallable =
  ## deleteAsset
  ## This operation deletes an asset.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  ##   AssetId: string (required)
  ##          : The unique identifier for an asset.
  var path_602156 = newJObject()
  add(path_602156, "RevisionId", newJString(RevisionId))
  add(path_602156, "DataSetId", newJString(DataSetId))
  add(path_602156, "AssetId", newJString(AssetId))
  result = call_602155.call(path_602156, nil, nil, nil, nil)

var deleteAsset* = Call_DeleteAsset_602141(name: "deleteAsset",
                                        meth: HttpMethod.HttpDelete,
                                        host: "dataexchange.amazonaws.com", route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}/assets/{AssetId}",
                                        validator: validate_DeleteAsset_602142,
                                        base: "/", url: url_DeleteAsset_602143,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataSet_602175 = ref object of OpenApiRestCall_601389
proc url_GetDataSet_602177(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDataSet_602176(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation returns information about a data set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DataSetId` field"
  var valid_602178 = path.getOrDefault("DataSetId")
  valid_602178 = validateParameter(valid_602178, JString, required = true,
                                 default = nil)
  if valid_602178 != nil:
    section.add "DataSetId", valid_602178
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
  var valid_602179 = header.getOrDefault("X-Amz-Signature")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Signature", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Content-Sha256", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Date")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Date", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Credential")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Credential", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Security-Token")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Security-Token", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-Algorithm")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-Algorithm", valid_602184
  var valid_602185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-SignedHeaders", valid_602185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602186: Call_GetDataSet_602175; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a data set.
  ## 
  let valid = call_602186.validator(path, query, header, formData, body)
  let scheme = call_602186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602186.url(scheme.get, call_602186.host, call_602186.base,
                         call_602186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602186, url, valid)

proc call*(call_602187: Call_GetDataSet_602175; DataSetId: string): Recallable =
  ## getDataSet
  ## This operation returns information about a data set.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_602188 = newJObject()
  add(path_602188, "DataSetId", newJString(DataSetId))
  result = call_602187.call(path_602188, nil, nil, nil, nil)

var getDataSet* = Call_GetDataSet_602175(name: "getDataSet",
                                      meth: HttpMethod.HttpGet,
                                      host: "dataexchange.amazonaws.com",
                                      route: "/v1/data-sets/{DataSetId}",
                                      validator: validate_GetDataSet_602176,
                                      base: "/", url: url_GetDataSet_602177,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSet_602203 = ref object of OpenApiRestCall_601389
proc url_UpdateDataSet_602205(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDataSet_602204(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation updates a data set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DataSetId` field"
  var valid_602206 = path.getOrDefault("DataSetId")
  valid_602206 = validateParameter(valid_602206, JString, required = true,
                                 default = nil)
  if valid_602206 != nil:
    section.add "DataSetId", valid_602206
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

proc call*(call_602215: Call_UpdateDataSet_602203; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation updates a data set.
  ## 
  let valid = call_602215.validator(path, query, header, formData, body)
  let scheme = call_602215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602215.url(scheme.get, call_602215.host, call_602215.base,
                         call_602215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602215, url, valid)

proc call*(call_602216: Call_UpdateDataSet_602203; DataSetId: string; body: JsonNode): Recallable =
  ## updateDataSet
  ## This operation updates a data set.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  ##   body: JObject (required)
  var path_602217 = newJObject()
  var body_602218 = newJObject()
  add(path_602217, "DataSetId", newJString(DataSetId))
  if body != nil:
    body_602218 = body
  result = call_602216.call(path_602217, nil, nil, nil, body_602218)

var updateDataSet* = Call_UpdateDataSet_602203(name: "updateDataSet",
    meth: HttpMethod.HttpPatch, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}", validator: validate_UpdateDataSet_602204,
    base: "/", url: url_UpdateDataSet_602205, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSet_602189 = ref object of OpenApiRestCall_601389
proc url_DeleteDataSet_602191(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDataSet_602190(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation deletes a data set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DataSetId` field"
  var valid_602192 = path.getOrDefault("DataSetId")
  valid_602192 = validateParameter(valid_602192, JString, required = true,
                                 default = nil)
  if valid_602192 != nil:
    section.add "DataSetId", valid_602192
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
  var valid_602193 = header.getOrDefault("X-Amz-Signature")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Signature", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Content-Sha256", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Date")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Date", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Credential")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Credential", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Security-Token")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Security-Token", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Algorithm")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Algorithm", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-SignedHeaders", valid_602199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602200: Call_DeleteDataSet_602189; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation deletes a data set.
  ## 
  let valid = call_602200.validator(path, query, header, formData, body)
  let scheme = call_602200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602200.url(scheme.get, call_602200.host, call_602200.base,
                         call_602200.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602200, url, valid)

proc call*(call_602201: Call_DeleteDataSet_602189; DataSetId: string): Recallable =
  ## deleteDataSet
  ## This operation deletes a data set.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_602202 = newJObject()
  add(path_602202, "DataSetId", newJString(DataSetId))
  result = call_602201.call(path_602202, nil, nil, nil, nil)

var deleteDataSet* = Call_DeleteDataSet_602189(name: "deleteDataSet",
    meth: HttpMethod.HttpDelete, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}", validator: validate_DeleteDataSet_602190,
    base: "/", url: url_DeleteDataSet_602191, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevision_602219 = ref object of OpenApiRestCall_601389
proc url_GetRevision_602221(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions/"),
               (kind: VariableSegment, value: "RevisionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRevision_602220(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation returns information about a revision.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_602222 = path.getOrDefault("RevisionId")
  valid_602222 = validateParameter(valid_602222, JString, required = true,
                                 default = nil)
  if valid_602222 != nil:
    section.add "RevisionId", valid_602222
  var valid_602223 = path.getOrDefault("DataSetId")
  valid_602223 = validateParameter(valid_602223, JString, required = true,
                                 default = nil)
  if valid_602223 != nil:
    section.add "DataSetId", valid_602223
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
  var valid_602224 = header.getOrDefault("X-Amz-Signature")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "X-Amz-Signature", valid_602224
  var valid_602225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-Content-Sha256", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-Date")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Date", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-Credential")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Credential", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-Security-Token")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Security-Token", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-Algorithm")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Algorithm", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-SignedHeaders", valid_602230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602231: Call_GetRevision_602219; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a revision.
  ## 
  let valid = call_602231.validator(path, query, header, formData, body)
  let scheme = call_602231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602231.url(scheme.get, call_602231.host, call_602231.base,
                         call_602231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602231, url, valid)

proc call*(call_602232: Call_GetRevision_602219; RevisionId: string;
          DataSetId: string): Recallable =
  ## getRevision
  ## This operation returns information about a revision.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_602233 = newJObject()
  add(path_602233, "RevisionId", newJString(RevisionId))
  add(path_602233, "DataSetId", newJString(DataSetId))
  result = call_602232.call(path_602233, nil, nil, nil, nil)

var getRevision* = Call_GetRevision_602219(name: "getRevision",
                                        meth: HttpMethod.HttpGet,
                                        host: "dataexchange.amazonaws.com", route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}",
                                        validator: validate_GetRevision_602220,
                                        base: "/", url: url_GetRevision_602221,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRevision_602249 = ref object of OpenApiRestCall_601389
proc url_UpdateRevision_602251(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions/"),
               (kind: VariableSegment, value: "RevisionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRevision_602250(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## This operation updates a revision.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_602252 = path.getOrDefault("RevisionId")
  valid_602252 = validateParameter(valid_602252, JString, required = true,
                                 default = nil)
  if valid_602252 != nil:
    section.add "RevisionId", valid_602252
  var valid_602253 = path.getOrDefault("DataSetId")
  valid_602253 = validateParameter(valid_602253, JString, required = true,
                                 default = nil)
  if valid_602253 != nil:
    section.add "DataSetId", valid_602253
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
  var valid_602254 = header.getOrDefault("X-Amz-Signature")
  valid_602254 = validateParameter(valid_602254, JString, required = false,
                                 default = nil)
  if valid_602254 != nil:
    section.add "X-Amz-Signature", valid_602254
  var valid_602255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-Content-Sha256", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-Date")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-Date", valid_602256
  var valid_602257 = header.getOrDefault("X-Amz-Credential")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-Credential", valid_602257
  var valid_602258 = header.getOrDefault("X-Amz-Security-Token")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "X-Amz-Security-Token", valid_602258
  var valid_602259 = header.getOrDefault("X-Amz-Algorithm")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-Algorithm", valid_602259
  var valid_602260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-SignedHeaders", valid_602260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602262: Call_UpdateRevision_602249; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation updates a revision.
  ## 
  let valid = call_602262.validator(path, query, header, formData, body)
  let scheme = call_602262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602262.url(scheme.get, call_602262.host, call_602262.base,
                         call_602262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602262, url, valid)

proc call*(call_602263: Call_UpdateRevision_602249; RevisionId: string;
          DataSetId: string; body: JsonNode): Recallable =
  ## updateRevision
  ## This operation updates a revision.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  ##   body: JObject (required)
  var path_602264 = newJObject()
  var body_602265 = newJObject()
  add(path_602264, "RevisionId", newJString(RevisionId))
  add(path_602264, "DataSetId", newJString(DataSetId))
  if body != nil:
    body_602265 = body
  result = call_602263.call(path_602264, nil, nil, nil, body_602265)

var updateRevision* = Call_UpdateRevision_602249(name: "updateRevision",
    meth: HttpMethod.HttpPatch, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}",
    validator: validate_UpdateRevision_602250, base: "/", url: url_UpdateRevision_602251,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRevision_602234 = ref object of OpenApiRestCall_601389
proc url_DeleteRevision_602236(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions/"),
               (kind: VariableSegment, value: "RevisionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRevision_602235(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## This operation deletes a revision.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_602237 = path.getOrDefault("RevisionId")
  valid_602237 = validateParameter(valid_602237, JString, required = true,
                                 default = nil)
  if valid_602237 != nil:
    section.add "RevisionId", valid_602237
  var valid_602238 = path.getOrDefault("DataSetId")
  valid_602238 = validateParameter(valid_602238, JString, required = true,
                                 default = nil)
  if valid_602238 != nil:
    section.add "DataSetId", valid_602238
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
  var valid_602239 = header.getOrDefault("X-Amz-Signature")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "X-Amz-Signature", valid_602239
  var valid_602240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-Content-Sha256", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-Date")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-Date", valid_602241
  var valid_602242 = header.getOrDefault("X-Amz-Credential")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Credential", valid_602242
  var valid_602243 = header.getOrDefault("X-Amz-Security-Token")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-Security-Token", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-Algorithm")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Algorithm", valid_602244
  var valid_602245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-SignedHeaders", valid_602245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602246: Call_DeleteRevision_602234; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation deletes a revision.
  ## 
  let valid = call_602246.validator(path, query, header, formData, body)
  let scheme = call_602246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602246.url(scheme.get, call_602246.host, call_602246.base,
                         call_602246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602246, url, valid)

proc call*(call_602247: Call_DeleteRevision_602234; RevisionId: string;
          DataSetId: string): Recallable =
  ## deleteRevision
  ## This operation deletes a revision.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_602248 = newJObject()
  add(path_602248, "RevisionId", newJString(RevisionId))
  add(path_602248, "DataSetId", newJString(DataSetId))
  result = call_602247.call(path_602248, nil, nil, nil, nil)

var deleteRevision* = Call_DeleteRevision_602234(name: "deleteRevision",
    meth: HttpMethod.HttpDelete, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}",
    validator: validate_DeleteRevision_602235, base: "/", url: url_DeleteRevision_602236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRevisionAssets_602266 = ref object of OpenApiRestCall_601389
proc url_ListRevisionAssets_602268(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions/"),
               (kind: VariableSegment, value: "RevisionId"),
               (kind: ConstantSegment, value: "/assets")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListRevisionAssets_602267(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## This operation lists a revision's assets sorted alphabetically in descending order.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_602269 = path.getOrDefault("RevisionId")
  valid_602269 = validateParameter(valid_602269, JString, required = true,
                                 default = nil)
  if valid_602269 != nil:
    section.add "RevisionId", valid_602269
  var valid_602270 = path.getOrDefault("DataSetId")
  valid_602270 = validateParameter(valid_602270, JString, required = true,
                                 default = nil)
  if valid_602270 != nil:
    section.add "DataSetId", valid_602270
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of results returned by a single call.
  section = newJObject()
  var valid_602271 = query.getOrDefault("nextToken")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "nextToken", valid_602271
  var valid_602272 = query.getOrDefault("MaxResults")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "MaxResults", valid_602272
  var valid_602273 = query.getOrDefault("NextToken")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "NextToken", valid_602273
  var valid_602274 = query.getOrDefault("maxResults")
  valid_602274 = validateParameter(valid_602274, JInt, required = false, default = nil)
  if valid_602274 != nil:
    section.add "maxResults", valid_602274
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
  var valid_602275 = header.getOrDefault("X-Amz-Signature")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "X-Amz-Signature", valid_602275
  var valid_602276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "X-Amz-Content-Sha256", valid_602276
  var valid_602277 = header.getOrDefault("X-Amz-Date")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "X-Amz-Date", valid_602277
  var valid_602278 = header.getOrDefault("X-Amz-Credential")
  valid_602278 = validateParameter(valid_602278, JString, required = false,
                                 default = nil)
  if valid_602278 != nil:
    section.add "X-Amz-Credential", valid_602278
  var valid_602279 = header.getOrDefault("X-Amz-Security-Token")
  valid_602279 = validateParameter(valid_602279, JString, required = false,
                                 default = nil)
  if valid_602279 != nil:
    section.add "X-Amz-Security-Token", valid_602279
  var valid_602280 = header.getOrDefault("X-Amz-Algorithm")
  valid_602280 = validateParameter(valid_602280, JString, required = false,
                                 default = nil)
  if valid_602280 != nil:
    section.add "X-Amz-Algorithm", valid_602280
  var valid_602281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602281 = validateParameter(valid_602281, JString, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "X-Amz-SignedHeaders", valid_602281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602282: Call_ListRevisionAssets_602266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists a revision's assets sorted alphabetically in descending order.
  ## 
  let valid = call_602282.validator(path, query, header, formData, body)
  let scheme = call_602282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602282.url(scheme.get, call_602282.host, call_602282.base,
                         call_602282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602282, url, valid)

proc call*(call_602283: Call_ListRevisionAssets_602266; RevisionId: string;
          DataSetId: string; nextToken: string = ""; MaxResults: string = "";
          NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listRevisionAssets
  ## This operation lists a revision's assets sorted alphabetically in descending order.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   nextToken: string
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  ##   maxResults: int
  ##             : The maximum number of results returned by a single call.
  var path_602284 = newJObject()
  var query_602285 = newJObject()
  add(path_602284, "RevisionId", newJString(RevisionId))
  add(query_602285, "nextToken", newJString(nextToken))
  add(query_602285, "MaxResults", newJString(MaxResults))
  add(query_602285, "NextToken", newJString(NextToken))
  add(path_602284, "DataSetId", newJString(DataSetId))
  add(query_602285, "maxResults", newJInt(maxResults))
  result = call_602283.call(path_602284, query_602285, nil, nil, nil)

var listRevisionAssets* = Call_ListRevisionAssets_602266(
    name: "listRevisionAssets", meth: HttpMethod.HttpGet,
    host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}/assets",
    validator: validate_ListRevisionAssets_602267, base: "/",
    url: url_ListRevisionAssets_602268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602300 = ref object of OpenApiRestCall_601389
proc url_TagResource_602302(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_602301(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation tags a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_602303 = path.getOrDefault("resource-arn")
  valid_602303 = validateParameter(valid_602303, JString, required = true,
                                 default = nil)
  if valid_602303 != nil:
    section.add "resource-arn", valid_602303
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
  var valid_602304 = header.getOrDefault("X-Amz-Signature")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "X-Amz-Signature", valid_602304
  var valid_602305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602305 = validateParameter(valid_602305, JString, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "X-Amz-Content-Sha256", valid_602305
  var valid_602306 = header.getOrDefault("X-Amz-Date")
  valid_602306 = validateParameter(valid_602306, JString, required = false,
                                 default = nil)
  if valid_602306 != nil:
    section.add "X-Amz-Date", valid_602306
  var valid_602307 = header.getOrDefault("X-Amz-Credential")
  valid_602307 = validateParameter(valid_602307, JString, required = false,
                                 default = nil)
  if valid_602307 != nil:
    section.add "X-Amz-Credential", valid_602307
  var valid_602308 = header.getOrDefault("X-Amz-Security-Token")
  valid_602308 = validateParameter(valid_602308, JString, required = false,
                                 default = nil)
  if valid_602308 != nil:
    section.add "X-Amz-Security-Token", valid_602308
  var valid_602309 = header.getOrDefault("X-Amz-Algorithm")
  valid_602309 = validateParameter(valid_602309, JString, required = false,
                                 default = nil)
  if valid_602309 != nil:
    section.add "X-Amz-Algorithm", valid_602309
  var valid_602310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602310 = validateParameter(valid_602310, JString, required = false,
                                 default = nil)
  if valid_602310 != nil:
    section.add "X-Amz-SignedHeaders", valid_602310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602312: Call_TagResource_602300; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation tags a resource.
  ## 
  let valid = call_602312.validator(path, query, header, formData, body)
  let scheme = call_602312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602312.url(scheme.get, call_602312.host, call_602312.base,
                         call_602312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602312, url, valid)

proc call*(call_602313: Call_TagResource_602300; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## This operation tags a resource.
  ##   resourceArn: string (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  ##   body: JObject (required)
  var path_602314 = newJObject()
  var body_602315 = newJObject()
  add(path_602314, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_602315 = body
  result = call_602313.call(path_602314, nil, nil, nil, body_602315)

var tagResource* = Call_TagResource_602300(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "dataexchange.amazonaws.com",
                                        route: "/tags/{resource-arn}",
                                        validator: validate_TagResource_602301,
                                        base: "/", url: url_TagResource_602302,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602286 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource_602288(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_602287(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## This operation lists the tags on the resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_602289 = path.getOrDefault("resource-arn")
  valid_602289 = validateParameter(valid_602289, JString, required = true,
                                 default = nil)
  if valid_602289 != nil:
    section.add "resource-arn", valid_602289
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
  var valid_602290 = header.getOrDefault("X-Amz-Signature")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "X-Amz-Signature", valid_602290
  var valid_602291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602291 = validateParameter(valid_602291, JString, required = false,
                                 default = nil)
  if valid_602291 != nil:
    section.add "X-Amz-Content-Sha256", valid_602291
  var valid_602292 = header.getOrDefault("X-Amz-Date")
  valid_602292 = validateParameter(valid_602292, JString, required = false,
                                 default = nil)
  if valid_602292 != nil:
    section.add "X-Amz-Date", valid_602292
  var valid_602293 = header.getOrDefault("X-Amz-Credential")
  valid_602293 = validateParameter(valid_602293, JString, required = false,
                                 default = nil)
  if valid_602293 != nil:
    section.add "X-Amz-Credential", valid_602293
  var valid_602294 = header.getOrDefault("X-Amz-Security-Token")
  valid_602294 = validateParameter(valid_602294, JString, required = false,
                                 default = nil)
  if valid_602294 != nil:
    section.add "X-Amz-Security-Token", valid_602294
  var valid_602295 = header.getOrDefault("X-Amz-Algorithm")
  valid_602295 = validateParameter(valid_602295, JString, required = false,
                                 default = nil)
  if valid_602295 != nil:
    section.add "X-Amz-Algorithm", valid_602295
  var valid_602296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = nil)
  if valid_602296 != nil:
    section.add "X-Amz-SignedHeaders", valid_602296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602297: Call_ListTagsForResource_602286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists the tags on the resource.
  ## 
  let valid = call_602297.validator(path, query, header, formData, body)
  let scheme = call_602297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602297.url(scheme.get, call_602297.host, call_602297.base,
                         call_602297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602297, url, valid)

proc call*(call_602298: Call_ListTagsForResource_602286; resourceArn: string): Recallable =
  ## listTagsForResource
  ## This operation lists the tags on the resource.
  ##   resourceArn: string (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  var path_602299 = newJObject()
  add(path_602299, "resource-arn", newJString(resourceArn))
  result = call_602298.call(path_602299, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_602286(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "dataexchange.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_602287, base: "/",
    url: url_ListTagsForResource_602288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602316 = ref object of OpenApiRestCall_601389
proc url_UntagResource_602318(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource-arn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_602317(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation removes one or more tags from a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_602319 = path.getOrDefault("resource-arn")
  valid_602319 = validateParameter(valid_602319, JString, required = true,
                                 default = nil)
  if valid_602319 != nil:
    section.add "resource-arn", valid_602319
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key tags.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_602320 = query.getOrDefault("tagKeys")
  valid_602320 = validateParameter(valid_602320, JArray, required = true, default = nil)
  if valid_602320 != nil:
    section.add "tagKeys", valid_602320
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
  var valid_602321 = header.getOrDefault("X-Amz-Signature")
  valid_602321 = validateParameter(valid_602321, JString, required = false,
                                 default = nil)
  if valid_602321 != nil:
    section.add "X-Amz-Signature", valid_602321
  var valid_602322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602322 = validateParameter(valid_602322, JString, required = false,
                                 default = nil)
  if valid_602322 != nil:
    section.add "X-Amz-Content-Sha256", valid_602322
  var valid_602323 = header.getOrDefault("X-Amz-Date")
  valid_602323 = validateParameter(valid_602323, JString, required = false,
                                 default = nil)
  if valid_602323 != nil:
    section.add "X-Amz-Date", valid_602323
  var valid_602324 = header.getOrDefault("X-Amz-Credential")
  valid_602324 = validateParameter(valid_602324, JString, required = false,
                                 default = nil)
  if valid_602324 != nil:
    section.add "X-Amz-Credential", valid_602324
  var valid_602325 = header.getOrDefault("X-Amz-Security-Token")
  valid_602325 = validateParameter(valid_602325, JString, required = false,
                                 default = nil)
  if valid_602325 != nil:
    section.add "X-Amz-Security-Token", valid_602325
  var valid_602326 = header.getOrDefault("X-Amz-Algorithm")
  valid_602326 = validateParameter(valid_602326, JString, required = false,
                                 default = nil)
  if valid_602326 != nil:
    section.add "X-Amz-Algorithm", valid_602326
  var valid_602327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "X-Amz-SignedHeaders", valid_602327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602328: Call_UntagResource_602316; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation removes one or more tags from a resource.
  ## 
  let valid = call_602328.validator(path, query, header, formData, body)
  let scheme = call_602328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602328.url(scheme.get, call_602328.host, call_602328.base,
                         call_602328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602328, url, valid)

proc call*(call_602329: Call_UntagResource_602316; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## This operation removes one or more tags from a resource.
  ##   resourceArn: string (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  ##   tagKeys: JArray (required)
  ##          : The key tags.
  var path_602330 = newJObject()
  var query_602331 = newJObject()
  add(path_602330, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_602331.add "tagKeys", tagKeys
  result = call_602329.call(path_602330, query_602331, nil, nil, nil)

var untagResource* = Call_UntagResource_602316(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "dataexchange.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_602317,
    base: "/", url: url_UntagResource_602318, schemes: {Scheme.Https, Scheme.Http})
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
