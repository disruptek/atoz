
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS S3 Control
## version: 2018-08-20
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
##  AWS S3 Control provides access to Amazon S3 control plane operations. 
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/s3-control/
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

  OpenApiRestCall_600437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600437): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "s3-control.ap-northeast-1.amazonaws.com", "ap-southeast-1": "s3-control.ap-southeast-1.amazonaws.com",
                           "us-west-2": "s3-control.us-west-2.amazonaws.com",
                           "eu-west-2": "s3-control.eu-west-2.amazonaws.com", "ap-northeast-3": "s3-control.ap-northeast-3.amazonaws.com", "eu-central-1": "s3-control.eu-central-1.amazonaws.com",
                           "us-east-2": "s3-control.us-east-2.amazonaws.com",
                           "us-east-1": "s3-control.us-east-1.amazonaws.com", "cn-northwest-1": "s3-control.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "s3-control.ap-south-1.amazonaws.com",
                           "eu-north-1": "s3-control.eu-north-1.amazonaws.com", "ap-northeast-2": "s3-control.ap-northeast-2.amazonaws.com",
                           "us-west-1": "s3-control.us-west-1.amazonaws.com", "us-gov-east-1": "s3-control.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "s3-control.eu-west-3.amazonaws.com", "cn-north-1": "s3-control.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "s3-control.sa-east-1.amazonaws.com",
                           "eu-west-1": "s3-control.eu-west-1.amazonaws.com", "us-gov-west-1": "s3-control.us-gov-west-1.amazonaws.com", "ap-southeast-2": "s3-control.ap-southeast-2.amazonaws.com", "ca-central-1": "s3-control.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "s3-control.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "s3-control.ap-southeast-1.amazonaws.com",
      "us-west-2": "s3-control.us-west-2.amazonaws.com",
      "eu-west-2": "s3-control.eu-west-2.amazonaws.com",
      "ap-northeast-3": "s3-control.ap-northeast-3.amazonaws.com",
      "eu-central-1": "s3-control.eu-central-1.amazonaws.com",
      "us-east-2": "s3-control.us-east-2.amazonaws.com",
      "us-east-1": "s3-control.us-east-1.amazonaws.com",
      "cn-northwest-1": "s3-control.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "s3-control.ap-south-1.amazonaws.com",
      "eu-north-1": "s3-control.eu-north-1.amazonaws.com",
      "ap-northeast-2": "s3-control.ap-northeast-2.amazonaws.com",
      "us-west-1": "s3-control.us-west-1.amazonaws.com",
      "us-gov-east-1": "s3-control.us-gov-east-1.amazonaws.com",
      "eu-west-3": "s3-control.eu-west-3.amazonaws.com",
      "cn-north-1": "s3-control.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "s3-control.sa-east-1.amazonaws.com",
      "eu-west-1": "s3-control.eu-west-1.amazonaws.com",
      "us-gov-west-1": "s3-control.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "s3-control.ap-southeast-2.amazonaws.com",
      "ca-central-1": "s3-control.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "s3control"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateJob_601035 = ref object of OpenApiRestCall_600437
proc url_CreateJob_601037(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateJob_601036(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an Amazon S3 batch operations job.
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
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  section = newJObject()
  var valid_601038 = header.getOrDefault("X-Amz-Date")
  valid_601038 = validateParameter(valid_601038, JString, required = false,
                                 default = nil)
  if valid_601038 != nil:
    section.add "X-Amz-Date", valid_601038
  var valid_601039 = header.getOrDefault("X-Amz-Security-Token")
  valid_601039 = validateParameter(valid_601039, JString, required = false,
                                 default = nil)
  if valid_601039 != nil:
    section.add "X-Amz-Security-Token", valid_601039
  var valid_601040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Content-Sha256", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Algorithm")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Algorithm", valid_601041
  var valid_601042 = header.getOrDefault("X-Amz-Signature")
  valid_601042 = validateParameter(valid_601042, JString, required = false,
                                 default = nil)
  if valid_601042 != nil:
    section.add "X-Amz-Signature", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-SignedHeaders", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Credential")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Credential", valid_601044
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_601045 = header.getOrDefault("x-amz-account-id")
  valid_601045 = validateParameter(valid_601045, JString, required = true,
                                 default = nil)
  if valid_601045 != nil:
    section.add "x-amz-account-id", valid_601045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601047: Call_CreateJob_601035; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon S3 batch operations job.
  ## 
  let valid = call_601047.validator(path, query, header, formData, body)
  let scheme = call_601047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601047.url(scheme.get, call_601047.host, call_601047.base,
                         call_601047.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601047, url, valid)

proc call*(call_601048: Call_CreateJob_601035; body: JsonNode): Recallable =
  ## createJob
  ## Creates an Amazon S3 batch operations job.
  ##   body: JObject (required)
  var body_601049 = newJObject()
  if body != nil:
    body_601049 = body
  result = call_601048.call(nil, nil, nil, nil, body_601049)

var createJob* = Call_CreateJob_601035(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "s3-control.amazonaws.com",
                                    route: "/v20180820/jobs#x-amz-account-id",
                                    validator: validate_CreateJob_601036,
                                    base: "/", url: url_CreateJob_601037,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_600774 = ref object of OpenApiRestCall_600437
proc url_ListJobs_600776(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListJobs_600775(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists current jobs and jobs that have ended within the last 30 days for the AWS account making the request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   jobStatuses: JArray
  ##              : The <code>List Jobs</code> request returns jobs that match the statuses listed in this element.
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of jobs that Amazon S3 will include in the <code>List Jobs</code> response. If there are more jobs than this number, the response will include a pagination token in the <code>NextToken</code> field to enable you to retrieve the next page of results.
  ##   nextToken: JString
  ##            : A pagination token to request the next page of results. Use the token that Amazon S3 returned in the <code>NextToken</code> element of the <code>ListJobsResult</code> from the previous <code>List Jobs</code> request.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600888 = query.getOrDefault("jobStatuses")
  valid_600888 = validateParameter(valid_600888, JArray, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "jobStatuses", valid_600888
  var valid_600889 = query.getOrDefault("NextToken")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "NextToken", valid_600889
  var valid_600890 = query.getOrDefault("maxResults")
  valid_600890 = validateParameter(valid_600890, JInt, required = false, default = nil)
  if valid_600890 != nil:
    section.add "maxResults", valid_600890
  var valid_600891 = query.getOrDefault("nextToken")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "nextToken", valid_600891
  var valid_600892 = query.getOrDefault("MaxResults")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "MaxResults", valid_600892
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  section = newJObject()
  var valid_600893 = header.getOrDefault("X-Amz-Date")
  valid_600893 = validateParameter(valid_600893, JString, required = false,
                                 default = nil)
  if valid_600893 != nil:
    section.add "X-Amz-Date", valid_600893
  var valid_600894 = header.getOrDefault("X-Amz-Security-Token")
  valid_600894 = validateParameter(valid_600894, JString, required = false,
                                 default = nil)
  if valid_600894 != nil:
    section.add "X-Amz-Security-Token", valid_600894
  var valid_600895 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600895 = validateParameter(valid_600895, JString, required = false,
                                 default = nil)
  if valid_600895 != nil:
    section.add "X-Amz-Content-Sha256", valid_600895
  var valid_600896 = header.getOrDefault("X-Amz-Algorithm")
  valid_600896 = validateParameter(valid_600896, JString, required = false,
                                 default = nil)
  if valid_600896 != nil:
    section.add "X-Amz-Algorithm", valid_600896
  var valid_600897 = header.getOrDefault("X-Amz-Signature")
  valid_600897 = validateParameter(valid_600897, JString, required = false,
                                 default = nil)
  if valid_600897 != nil:
    section.add "X-Amz-Signature", valid_600897
  var valid_600898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-SignedHeaders", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-Credential")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Credential", valid_600899
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_600900 = header.getOrDefault("x-amz-account-id")
  valid_600900 = validateParameter(valid_600900, JString, required = true,
                                 default = nil)
  if valid_600900 != nil:
    section.add "x-amz-account-id", valid_600900
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600923: Call_ListJobs_600774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists current jobs and jobs that have ended within the last 30 days for the AWS account making the request.
  ## 
  let valid = call_600923.validator(path, query, header, formData, body)
  let scheme = call_600923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600923.url(scheme.get, call_600923.host, call_600923.base,
                         call_600923.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600923, url, valid)

proc call*(call_600994: Call_ListJobs_600774; jobStatuses: JsonNode = nil;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listJobs
  ## Lists current jobs and jobs that have ended within the last 30 days for the AWS account making the request.
  ##   jobStatuses: JArray
  ##              : The <code>List Jobs</code> request returns jobs that match the statuses listed in this element.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of jobs that Amazon S3 will include in the <code>List Jobs</code> response. If there are more jobs than this number, the response will include a pagination token in the <code>NextToken</code> field to enable you to retrieve the next page of results.
  ##   nextToken: string
  ##            : A pagination token to request the next page of results. Use the token that Amazon S3 returned in the <code>NextToken</code> element of the <code>ListJobsResult</code> from the previous <code>List Jobs</code> request.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600995 = newJObject()
  if jobStatuses != nil:
    query_600995.add "jobStatuses", jobStatuses
  add(query_600995, "NextToken", newJString(NextToken))
  add(query_600995, "maxResults", newJInt(maxResults))
  add(query_600995, "nextToken", newJString(nextToken))
  add(query_600995, "MaxResults", newJString(MaxResults))
  result = call_600994.call(nil, query_600995, nil, nil, nil)

var listJobs* = Call_ListJobs_600774(name: "listJobs", meth: HttpMethod.HttpGet,
                                  host: "s3-control.amazonaws.com",
                                  route: "/v20180820/jobs#x-amz-account-id",
                                  validator: validate_ListJobs_600775, base: "/",
                                  url: url_ListJobs_600776,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPublicAccessBlock_601063 = ref object of OpenApiRestCall_600437
proc url_PutPublicAccessBlock_601065(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutPublicAccessBlock_601064(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p/>
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
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  section = newJObject()
  var valid_601066 = header.getOrDefault("X-Amz-Date")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-Date", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-Security-Token")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-Security-Token", valid_601067
  var valid_601068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-Content-Sha256", valid_601068
  var valid_601069 = header.getOrDefault("X-Amz-Algorithm")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Algorithm", valid_601069
  var valid_601070 = header.getOrDefault("X-Amz-Signature")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Signature", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-SignedHeaders", valid_601071
  var valid_601072 = header.getOrDefault("X-Amz-Credential")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Credential", valid_601072
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_601073 = header.getOrDefault("x-amz-account-id")
  valid_601073 = validateParameter(valid_601073, JString, required = true,
                                 default = nil)
  if valid_601073 != nil:
    section.add "x-amz-account-id", valid_601073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601075: Call_PutPublicAccessBlock_601063; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p/>
  ## 
  let valid = call_601075.validator(path, query, header, formData, body)
  let scheme = call_601075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601075.url(scheme.get, call_601075.host, call_601075.base,
                         call_601075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601075, url, valid)

proc call*(call_601076: Call_PutPublicAccessBlock_601063; body: JsonNode): Recallable =
  ## putPublicAccessBlock
  ## <p/>
  ##   body: JObject (required)
  var body_601077 = newJObject()
  if body != nil:
    body_601077 = body
  result = call_601076.call(nil, nil, nil, nil, body_601077)

var putPublicAccessBlock* = Call_PutPublicAccessBlock_601063(
    name: "putPublicAccessBlock", meth: HttpMethod.HttpPut,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/configuration/publicAccessBlock#x-amz-account-id",
    validator: validate_PutPublicAccessBlock_601064, base: "/",
    url: url_PutPublicAccessBlock_601065, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicAccessBlock_601050 = ref object of OpenApiRestCall_600437
proc url_GetPublicAccessBlock_601052(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPublicAccessBlock_601051(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p/>
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
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  section = newJObject()
  var valid_601053 = header.getOrDefault("X-Amz-Date")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-Date", valid_601053
  var valid_601054 = header.getOrDefault("X-Amz-Security-Token")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "X-Amz-Security-Token", valid_601054
  var valid_601055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Content-Sha256", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Algorithm")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Algorithm", valid_601056
  var valid_601057 = header.getOrDefault("X-Amz-Signature")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Signature", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-SignedHeaders", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Credential")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Credential", valid_601059
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_601060 = header.getOrDefault("x-amz-account-id")
  valid_601060 = validateParameter(valid_601060, JString, required = true,
                                 default = nil)
  if valid_601060 != nil:
    section.add "x-amz-account-id", valid_601060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601061: Call_GetPublicAccessBlock_601050; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p/>
  ## 
  let valid = call_601061.validator(path, query, header, formData, body)
  let scheme = call_601061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601061.url(scheme.get, call_601061.host, call_601061.base,
                         call_601061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601061, url, valid)

proc call*(call_601062: Call_GetPublicAccessBlock_601050): Recallable =
  ## getPublicAccessBlock
  ## <p/>
  result = call_601062.call(nil, nil, nil, nil, nil)

var getPublicAccessBlock* = Call_GetPublicAccessBlock_601050(
    name: "getPublicAccessBlock", meth: HttpMethod.HttpGet,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/configuration/publicAccessBlock#x-amz-account-id",
    validator: validate_GetPublicAccessBlock_601051, base: "/",
    url: url_GetPublicAccessBlock_601052, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublicAccessBlock_601078 = ref object of OpenApiRestCall_600437
proc url_DeletePublicAccessBlock_601080(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeletePublicAccessBlock_601079(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the block public access configuration for the specified account.
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
  ##   x-amz-account-id: JString (required)
  ##                   : The account ID for the AWS account whose block public access configuration you want to delete.
  section = newJObject()
  var valid_601081 = header.getOrDefault("X-Amz-Date")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Date", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-Security-Token")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-Security-Token", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Content-Sha256", valid_601083
  var valid_601084 = header.getOrDefault("X-Amz-Algorithm")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-Algorithm", valid_601084
  var valid_601085 = header.getOrDefault("X-Amz-Signature")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Signature", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-SignedHeaders", valid_601086
  var valid_601087 = header.getOrDefault("X-Amz-Credential")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Credential", valid_601087
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_601088 = header.getOrDefault("x-amz-account-id")
  valid_601088 = validateParameter(valid_601088, JString, required = true,
                                 default = nil)
  if valid_601088 != nil:
    section.add "x-amz-account-id", valid_601088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601089: Call_DeletePublicAccessBlock_601078; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the block public access configuration for the specified account.
  ## 
  let valid = call_601089.validator(path, query, header, formData, body)
  let scheme = call_601089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601089.url(scheme.get, call_601089.host, call_601089.base,
                         call_601089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601089, url, valid)

proc call*(call_601090: Call_DeletePublicAccessBlock_601078): Recallable =
  ## deletePublicAccessBlock
  ## Deletes the block public access configuration for the specified account.
  result = call_601090.call(nil, nil, nil, nil, nil)

var deletePublicAccessBlock* = Call_DeletePublicAccessBlock_601078(
    name: "deletePublicAccessBlock", meth: HttpMethod.HttpDelete,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/configuration/publicAccessBlock#x-amz-account-id",
    validator: validate_DeletePublicAccessBlock_601079, base: "/",
    url: url_DeletePublicAccessBlock_601080, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJob_601091 = ref object of OpenApiRestCall_600437
proc url_DescribeJob_601093(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/jobs/"),
               (kind: VariableSegment, value: "id"),
               (kind: ConstantSegment, value: "#x-amz-account-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeJob_601092(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the configuration parameters and status for a batch operations job.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID for the job whose information you want to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_601108 = path.getOrDefault("id")
  valid_601108 = validateParameter(valid_601108, JString, required = true,
                                 default = nil)
  if valid_601108 != nil:
    section.add "id", valid_601108
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
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  section = newJObject()
  var valid_601109 = header.getOrDefault("X-Amz-Date")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Date", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Security-Token")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Security-Token", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Content-Sha256", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-Algorithm")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-Algorithm", valid_601112
  var valid_601113 = header.getOrDefault("X-Amz-Signature")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-Signature", valid_601113
  var valid_601114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-SignedHeaders", valid_601114
  var valid_601115 = header.getOrDefault("X-Amz-Credential")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Credential", valid_601115
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_601116 = header.getOrDefault("x-amz-account-id")
  valid_601116 = validateParameter(valid_601116, JString, required = true,
                                 default = nil)
  if valid_601116 != nil:
    section.add "x-amz-account-id", valid_601116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601117: Call_DescribeJob_601091; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the configuration parameters and status for a batch operations job.
  ## 
  let valid = call_601117.validator(path, query, header, formData, body)
  let scheme = call_601117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601117.url(scheme.get, call_601117.host, call_601117.base,
                         call_601117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601117, url, valid)

proc call*(call_601118: Call_DescribeJob_601091; id: string): Recallable =
  ## describeJob
  ## Retrieves the configuration parameters and status for a batch operations job.
  ##   id: string (required)
  ##     : The ID for the job whose information you want to retrieve.
  var path_601119 = newJObject()
  add(path_601119, "id", newJString(id))
  result = call_601118.call(path_601119, nil, nil, nil, nil)

var describeJob* = Call_DescribeJob_601091(name: "describeJob",
                                        meth: HttpMethod.HttpGet,
                                        host: "s3-control.amazonaws.com", route: "/v20180820/jobs/{id}#x-amz-account-id",
                                        validator: validate_DescribeJob_601092,
                                        base: "/", url: url_DescribeJob_601093,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJobPriority_601120 = ref object of OpenApiRestCall_600437
proc url_UpdateJobPriority_601122(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/jobs/"),
               (kind: VariableSegment, value: "id"), (kind: ConstantSegment,
        value: "/priority#x-amz-account-id&priority")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateJobPriority_601121(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates an existing job's priority.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID for the job whose priority you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_601123 = path.getOrDefault("id")
  valid_601123 = validateParameter(valid_601123, JString, required = true,
                                 default = nil)
  if valid_601123 != nil:
    section.add "id", valid_601123
  result.add "path", section
  ## parameters in `query` object:
  ##   priority: JInt (required)
  ##           : The priority you want to assign to this job.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `priority` field"
  var valid_601124 = query.getOrDefault("priority")
  valid_601124 = validateParameter(valid_601124, JInt, required = true, default = nil)
  if valid_601124 != nil:
    section.add "priority", valid_601124
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  section = newJObject()
  var valid_601125 = header.getOrDefault("X-Amz-Date")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Date", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Security-Token")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Security-Token", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-Content-Sha256", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Algorithm")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Algorithm", valid_601128
  var valid_601129 = header.getOrDefault("X-Amz-Signature")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-Signature", valid_601129
  var valid_601130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-SignedHeaders", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Credential")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Credential", valid_601131
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_601132 = header.getOrDefault("x-amz-account-id")
  valid_601132 = validateParameter(valid_601132, JString, required = true,
                                 default = nil)
  if valid_601132 != nil:
    section.add "x-amz-account-id", valid_601132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601133: Call_UpdateJobPriority_601120; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing job's priority.
  ## 
  let valid = call_601133.validator(path, query, header, formData, body)
  let scheme = call_601133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601133.url(scheme.get, call_601133.host, call_601133.base,
                         call_601133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601133, url, valid)

proc call*(call_601134: Call_UpdateJobPriority_601120; id: string; priority: int): Recallable =
  ## updateJobPriority
  ## Updates an existing job's priority.
  ##   id: string (required)
  ##     : The ID for the job whose priority you want to update.
  ##   priority: int (required)
  ##           : The priority you want to assign to this job.
  var path_601135 = newJObject()
  var query_601136 = newJObject()
  add(path_601135, "id", newJString(id))
  add(query_601136, "priority", newJInt(priority))
  result = call_601134.call(path_601135, query_601136, nil, nil, nil)

var updateJobPriority* = Call_UpdateJobPriority_601120(name: "updateJobPriority",
    meth: HttpMethod.HttpPost, host: "s3-control.amazonaws.com",
    route: "/v20180820/jobs/{id}/priority#x-amz-account-id&priority",
    validator: validate_UpdateJobPriority_601121, base: "/",
    url: url_UpdateJobPriority_601122, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJobStatus_601137 = ref object of OpenApiRestCall_600437
proc url_UpdateJobStatus_601139(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/jobs/"),
               (kind: VariableSegment, value: "id"), (kind: ConstantSegment,
        value: "/status#x-amz-account-id&requestedJobStatus")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateJobStatus_601138(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Updates the status for the specified job. Use this operation to confirm that you want to run a job or to cancel an existing job.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the job whose status you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_601140 = path.getOrDefault("id")
  valid_601140 = validateParameter(valid_601140, JString, required = true,
                                 default = nil)
  if valid_601140 != nil:
    section.add "id", valid_601140
  result.add "path", section
  ## parameters in `query` object:
  ##   requestedJobStatus: JString (required)
  ##                     : The status that you want to move the specified job to.
  ##   statusUpdateReason: JString
  ##                     : A description of the reason why you want to change the specified job's status. This field can be any string up to the maximum length.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `requestedJobStatus` field"
  var valid_601154 = query.getOrDefault("requestedJobStatus")
  valid_601154 = validateParameter(valid_601154, JString, required = true,
                                 default = newJString("Cancelled"))
  if valid_601154 != nil:
    section.add "requestedJobStatus", valid_601154
  var valid_601155 = query.getOrDefault("statusUpdateReason")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "statusUpdateReason", valid_601155
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  section = newJObject()
  var valid_601156 = header.getOrDefault("X-Amz-Date")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-Date", valid_601156
  var valid_601157 = header.getOrDefault("X-Amz-Security-Token")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-Security-Token", valid_601157
  var valid_601158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-Content-Sha256", valid_601158
  var valid_601159 = header.getOrDefault("X-Amz-Algorithm")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "X-Amz-Algorithm", valid_601159
  var valid_601160 = header.getOrDefault("X-Amz-Signature")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-Signature", valid_601160
  var valid_601161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-SignedHeaders", valid_601161
  var valid_601162 = header.getOrDefault("X-Amz-Credential")
  valid_601162 = validateParameter(valid_601162, JString, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "X-Amz-Credential", valid_601162
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_601163 = header.getOrDefault("x-amz-account-id")
  valid_601163 = validateParameter(valid_601163, JString, required = true,
                                 default = nil)
  if valid_601163 != nil:
    section.add "x-amz-account-id", valid_601163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601164: Call_UpdateJobStatus_601137; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status for the specified job. Use this operation to confirm that you want to run a job or to cancel an existing job.
  ## 
  let valid = call_601164.validator(path, query, header, formData, body)
  let scheme = call_601164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601164.url(scheme.get, call_601164.host, call_601164.base,
                         call_601164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601164, url, valid)

proc call*(call_601165: Call_UpdateJobStatus_601137; id: string;
          requestedJobStatus: string = "Cancelled"; statusUpdateReason: string = ""): Recallable =
  ## updateJobStatus
  ## Updates the status for the specified job. Use this operation to confirm that you want to run a job or to cancel an existing job.
  ##   requestedJobStatus: string (required)
  ##                     : The status that you want to move the specified job to.
  ##   id: string (required)
  ##     : The ID of the job whose status you want to update.
  ##   statusUpdateReason: string
  ##                     : A description of the reason why you want to change the specified job's status. This field can be any string up to the maximum length.
  var path_601166 = newJObject()
  var query_601167 = newJObject()
  add(query_601167, "requestedJobStatus", newJString(requestedJobStatus))
  add(path_601166, "id", newJString(id))
  add(query_601167, "statusUpdateReason", newJString(statusUpdateReason))
  result = call_601165.call(path_601166, query_601167, nil, nil, nil)

var updateJobStatus* = Call_UpdateJobStatus_601137(name: "updateJobStatus",
    meth: HttpMethod.HttpPost, host: "s3-control.amazonaws.com",
    route: "/v20180820/jobs/{id}/status#x-amz-account-id&requestedJobStatus",
    validator: validate_UpdateJobStatus_601138, base: "/", url: url_UpdateJobStatus_601139,
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
