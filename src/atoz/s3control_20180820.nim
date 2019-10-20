
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
  Call_CreateJob_592964 = ref object of OpenApiRestCall_592364
proc url_CreateJob_592966(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateJob_592965(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592967 = header.getOrDefault("X-Amz-Signature")
  valid_592967 = validateParameter(valid_592967, JString, required = false,
                                 default = nil)
  if valid_592967 != nil:
    section.add "X-Amz-Signature", valid_592967
  var valid_592968 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592968 = validateParameter(valid_592968, JString, required = false,
                                 default = nil)
  if valid_592968 != nil:
    section.add "X-Amz-Content-Sha256", valid_592968
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_592969 = header.getOrDefault("x-amz-account-id")
  valid_592969 = validateParameter(valid_592969, JString, required = true,
                                 default = nil)
  if valid_592969 != nil:
    section.add "x-amz-account-id", valid_592969
  var valid_592970 = header.getOrDefault("X-Amz-Date")
  valid_592970 = validateParameter(valid_592970, JString, required = false,
                                 default = nil)
  if valid_592970 != nil:
    section.add "X-Amz-Date", valid_592970
  var valid_592971 = header.getOrDefault("X-Amz-Credential")
  valid_592971 = validateParameter(valid_592971, JString, required = false,
                                 default = nil)
  if valid_592971 != nil:
    section.add "X-Amz-Credential", valid_592971
  var valid_592972 = header.getOrDefault("X-Amz-Security-Token")
  valid_592972 = validateParameter(valid_592972, JString, required = false,
                                 default = nil)
  if valid_592972 != nil:
    section.add "X-Amz-Security-Token", valid_592972
  var valid_592973 = header.getOrDefault("X-Amz-Algorithm")
  valid_592973 = validateParameter(valid_592973, JString, required = false,
                                 default = nil)
  if valid_592973 != nil:
    section.add "X-Amz-Algorithm", valid_592973
  var valid_592974 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592974 = validateParameter(valid_592974, JString, required = false,
                                 default = nil)
  if valid_592974 != nil:
    section.add "X-Amz-SignedHeaders", valid_592974
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592976: Call_CreateJob_592964; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon S3 batch operations job.
  ## 
  let valid = call_592976.validator(path, query, header, formData, body)
  let scheme = call_592976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592976.url(scheme.get, call_592976.host, call_592976.base,
                         call_592976.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592976, url, valid)

proc call*(call_592977: Call_CreateJob_592964; body: JsonNode): Recallable =
  ## createJob
  ## Creates an Amazon S3 batch operations job.
  ##   body: JObject (required)
  var body_592978 = newJObject()
  if body != nil:
    body_592978 = body
  result = call_592977.call(nil, nil, nil, nil, body_592978)

var createJob* = Call_CreateJob_592964(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "s3-control.amazonaws.com",
                                    route: "/v20180820/jobs#x-amz-account-id",
                                    validator: validate_CreateJob_592965,
                                    base: "/", url: url_CreateJob_592966,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_592703 = ref object of OpenApiRestCall_592364
proc url_ListJobs_592705(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListJobs_592704(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists current jobs and jobs that have ended within the last 30 days for the AWS account making the request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A pagination token to request the next page of results. Use the token that Amazon S3 returned in the <code>NextToken</code> element of the <code>ListJobsResult</code> from the previous <code>List Jobs</code> request.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   jobStatuses: JArray
  ##              : The <code>List Jobs</code> request returns jobs that match the statuses listed in this element.
  ##   maxResults: JInt
  ##             : The maximum number of jobs that Amazon S3 will include in the <code>List Jobs</code> response. If there are more jobs than this number, the response will include a pagination token in the <code>NextToken</code> field to enable you to retrieve the next page of results.
  section = newJObject()
  var valid_592817 = query.getOrDefault("nextToken")
  valid_592817 = validateParameter(valid_592817, JString, required = false,
                                 default = nil)
  if valid_592817 != nil:
    section.add "nextToken", valid_592817
  var valid_592818 = query.getOrDefault("MaxResults")
  valid_592818 = validateParameter(valid_592818, JString, required = false,
                                 default = nil)
  if valid_592818 != nil:
    section.add "MaxResults", valid_592818
  var valid_592819 = query.getOrDefault("NextToken")
  valid_592819 = validateParameter(valid_592819, JString, required = false,
                                 default = nil)
  if valid_592819 != nil:
    section.add "NextToken", valid_592819
  var valid_592820 = query.getOrDefault("jobStatuses")
  valid_592820 = validateParameter(valid_592820, JArray, required = false,
                                 default = nil)
  if valid_592820 != nil:
    section.add "jobStatuses", valid_592820
  var valid_592821 = query.getOrDefault("maxResults")
  valid_592821 = validateParameter(valid_592821, JInt, required = false, default = nil)
  if valid_592821 != nil:
    section.add "maxResults", valid_592821
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592822 = header.getOrDefault("X-Amz-Signature")
  valid_592822 = validateParameter(valid_592822, JString, required = false,
                                 default = nil)
  if valid_592822 != nil:
    section.add "X-Amz-Signature", valid_592822
  var valid_592823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592823 = validateParameter(valid_592823, JString, required = false,
                                 default = nil)
  if valid_592823 != nil:
    section.add "X-Amz-Content-Sha256", valid_592823
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_592824 = header.getOrDefault("x-amz-account-id")
  valid_592824 = validateParameter(valid_592824, JString, required = true,
                                 default = nil)
  if valid_592824 != nil:
    section.add "x-amz-account-id", valid_592824
  var valid_592825 = header.getOrDefault("X-Amz-Date")
  valid_592825 = validateParameter(valid_592825, JString, required = false,
                                 default = nil)
  if valid_592825 != nil:
    section.add "X-Amz-Date", valid_592825
  var valid_592826 = header.getOrDefault("X-Amz-Credential")
  valid_592826 = validateParameter(valid_592826, JString, required = false,
                                 default = nil)
  if valid_592826 != nil:
    section.add "X-Amz-Credential", valid_592826
  var valid_592827 = header.getOrDefault("X-Amz-Security-Token")
  valid_592827 = validateParameter(valid_592827, JString, required = false,
                                 default = nil)
  if valid_592827 != nil:
    section.add "X-Amz-Security-Token", valid_592827
  var valid_592828 = header.getOrDefault("X-Amz-Algorithm")
  valid_592828 = validateParameter(valid_592828, JString, required = false,
                                 default = nil)
  if valid_592828 != nil:
    section.add "X-Amz-Algorithm", valid_592828
  var valid_592829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592829 = validateParameter(valid_592829, JString, required = false,
                                 default = nil)
  if valid_592829 != nil:
    section.add "X-Amz-SignedHeaders", valid_592829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592852: Call_ListJobs_592703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists current jobs and jobs that have ended within the last 30 days for the AWS account making the request.
  ## 
  let valid = call_592852.validator(path, query, header, formData, body)
  let scheme = call_592852.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592852.url(scheme.get, call_592852.host, call_592852.base,
                         call_592852.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592852, url, valid)

proc call*(call_592923: Call_ListJobs_592703; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = ""; jobStatuses: JsonNode = nil;
          maxResults: int = 0): Recallable =
  ## listJobs
  ## Lists current jobs and jobs that have ended within the last 30 days for the AWS account making the request.
  ##   nextToken: string
  ##            : A pagination token to request the next page of results. Use the token that Amazon S3 returned in the <code>NextToken</code> element of the <code>ListJobsResult</code> from the previous <code>List Jobs</code> request.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   jobStatuses: JArray
  ##              : The <code>List Jobs</code> request returns jobs that match the statuses listed in this element.
  ##   maxResults: int
  ##             : The maximum number of jobs that Amazon S3 will include in the <code>List Jobs</code> response. If there are more jobs than this number, the response will include a pagination token in the <code>NextToken</code> field to enable you to retrieve the next page of results.
  var query_592924 = newJObject()
  add(query_592924, "nextToken", newJString(nextToken))
  add(query_592924, "MaxResults", newJString(MaxResults))
  add(query_592924, "NextToken", newJString(NextToken))
  if jobStatuses != nil:
    query_592924.add "jobStatuses", jobStatuses
  add(query_592924, "maxResults", newJInt(maxResults))
  result = call_592923.call(nil, query_592924, nil, nil, nil)

var listJobs* = Call_ListJobs_592703(name: "listJobs", meth: HttpMethod.HttpGet,
                                  host: "s3-control.amazonaws.com",
                                  route: "/v20180820/jobs#x-amz-account-id",
                                  validator: validate_ListJobs_592704, base: "/",
                                  url: url_ListJobs_592705,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPublicAccessBlock_592992 = ref object of OpenApiRestCall_592364
proc url_PutPublicAccessBlock_592994(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutPublicAccessBlock_592993(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592995 = header.getOrDefault("X-Amz-Signature")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Signature", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Content-Sha256", valid_592996
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_592997 = header.getOrDefault("x-amz-account-id")
  valid_592997 = validateParameter(valid_592997, JString, required = true,
                                 default = nil)
  if valid_592997 != nil:
    section.add "x-amz-account-id", valid_592997
  var valid_592998 = header.getOrDefault("X-Amz-Date")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "X-Amz-Date", valid_592998
  var valid_592999 = header.getOrDefault("X-Amz-Credential")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-Credential", valid_592999
  var valid_593000 = header.getOrDefault("X-Amz-Security-Token")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-Security-Token", valid_593000
  var valid_593001 = header.getOrDefault("X-Amz-Algorithm")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-Algorithm", valid_593001
  var valid_593002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-SignedHeaders", valid_593002
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593004: Call_PutPublicAccessBlock_592992; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p/>
  ## 
  let valid = call_593004.validator(path, query, header, formData, body)
  let scheme = call_593004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593004.url(scheme.get, call_593004.host, call_593004.base,
                         call_593004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593004, url, valid)

proc call*(call_593005: Call_PutPublicAccessBlock_592992; body: JsonNode): Recallable =
  ## putPublicAccessBlock
  ## <p/>
  ##   body: JObject (required)
  var body_593006 = newJObject()
  if body != nil:
    body_593006 = body
  result = call_593005.call(nil, nil, nil, nil, body_593006)

var putPublicAccessBlock* = Call_PutPublicAccessBlock_592992(
    name: "putPublicAccessBlock", meth: HttpMethod.HttpPut,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/configuration/publicAccessBlock#x-amz-account-id",
    validator: validate_PutPublicAccessBlock_592993, base: "/",
    url: url_PutPublicAccessBlock_592994, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicAccessBlock_592979 = ref object of OpenApiRestCall_592364
proc url_GetPublicAccessBlock_592981(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPublicAccessBlock_592980(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592982 = header.getOrDefault("X-Amz-Signature")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-Signature", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-Content-Sha256", valid_592983
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_592984 = header.getOrDefault("x-amz-account-id")
  valid_592984 = validateParameter(valid_592984, JString, required = true,
                                 default = nil)
  if valid_592984 != nil:
    section.add "x-amz-account-id", valid_592984
  var valid_592985 = header.getOrDefault("X-Amz-Date")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-Date", valid_592985
  var valid_592986 = header.getOrDefault("X-Amz-Credential")
  valid_592986 = validateParameter(valid_592986, JString, required = false,
                                 default = nil)
  if valid_592986 != nil:
    section.add "X-Amz-Credential", valid_592986
  var valid_592987 = header.getOrDefault("X-Amz-Security-Token")
  valid_592987 = validateParameter(valid_592987, JString, required = false,
                                 default = nil)
  if valid_592987 != nil:
    section.add "X-Amz-Security-Token", valid_592987
  var valid_592988 = header.getOrDefault("X-Amz-Algorithm")
  valid_592988 = validateParameter(valid_592988, JString, required = false,
                                 default = nil)
  if valid_592988 != nil:
    section.add "X-Amz-Algorithm", valid_592988
  var valid_592989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592989 = validateParameter(valid_592989, JString, required = false,
                                 default = nil)
  if valid_592989 != nil:
    section.add "X-Amz-SignedHeaders", valid_592989
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592990: Call_GetPublicAccessBlock_592979; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p/>
  ## 
  let valid = call_592990.validator(path, query, header, formData, body)
  let scheme = call_592990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592990.url(scheme.get, call_592990.host, call_592990.base,
                         call_592990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592990, url, valid)

proc call*(call_592991: Call_GetPublicAccessBlock_592979): Recallable =
  ## getPublicAccessBlock
  ## <p/>
  result = call_592991.call(nil, nil, nil, nil, nil)

var getPublicAccessBlock* = Call_GetPublicAccessBlock_592979(
    name: "getPublicAccessBlock", meth: HttpMethod.HttpGet,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/configuration/publicAccessBlock#x-amz-account-id",
    validator: validate_GetPublicAccessBlock_592980, base: "/",
    url: url_GetPublicAccessBlock_592981, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublicAccessBlock_593007 = ref object of OpenApiRestCall_592364
proc url_DeletePublicAccessBlock_593009(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeletePublicAccessBlock_593008(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   x-amz-account-id: JString (required)
  ##                   : The account ID for the AWS account whose block public access configuration you want to delete.
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593010 = header.getOrDefault("X-Amz-Signature")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Signature", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Content-Sha256", valid_593011
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_593012 = header.getOrDefault("x-amz-account-id")
  valid_593012 = validateParameter(valid_593012, JString, required = true,
                                 default = nil)
  if valid_593012 != nil:
    section.add "x-amz-account-id", valid_593012
  var valid_593013 = header.getOrDefault("X-Amz-Date")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "X-Amz-Date", valid_593013
  var valid_593014 = header.getOrDefault("X-Amz-Credential")
  valid_593014 = validateParameter(valid_593014, JString, required = false,
                                 default = nil)
  if valid_593014 != nil:
    section.add "X-Amz-Credential", valid_593014
  var valid_593015 = header.getOrDefault("X-Amz-Security-Token")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "X-Amz-Security-Token", valid_593015
  var valid_593016 = header.getOrDefault("X-Amz-Algorithm")
  valid_593016 = validateParameter(valid_593016, JString, required = false,
                                 default = nil)
  if valid_593016 != nil:
    section.add "X-Amz-Algorithm", valid_593016
  var valid_593017 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "X-Amz-SignedHeaders", valid_593017
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593018: Call_DeletePublicAccessBlock_593007; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the block public access configuration for the specified account.
  ## 
  let valid = call_593018.validator(path, query, header, formData, body)
  let scheme = call_593018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593018.url(scheme.get, call_593018.host, call_593018.base,
                         call_593018.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593018, url, valid)

proc call*(call_593019: Call_DeletePublicAccessBlock_593007): Recallable =
  ## deletePublicAccessBlock
  ## Deletes the block public access configuration for the specified account.
  result = call_593019.call(nil, nil, nil, nil, nil)

var deletePublicAccessBlock* = Call_DeletePublicAccessBlock_593007(
    name: "deletePublicAccessBlock", meth: HttpMethod.HttpDelete,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/configuration/publicAccessBlock#x-amz-account-id",
    validator: validate_DeletePublicAccessBlock_593008, base: "/",
    url: url_DeletePublicAccessBlock_593009, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJob_593020 = ref object of OpenApiRestCall_592364
proc url_DescribeJob_593022(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeJob_593021(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593037 = path.getOrDefault("id")
  valid_593037 = validateParameter(valid_593037, JString, required = true,
                                 default = nil)
  if valid_593037 != nil:
    section.add "id", valid_593037
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593038 = header.getOrDefault("X-Amz-Signature")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Signature", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Content-Sha256", valid_593039
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_593040 = header.getOrDefault("x-amz-account-id")
  valid_593040 = validateParameter(valid_593040, JString, required = true,
                                 default = nil)
  if valid_593040 != nil:
    section.add "x-amz-account-id", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Date")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Date", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-Credential")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-Credential", valid_593042
  var valid_593043 = header.getOrDefault("X-Amz-Security-Token")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "X-Amz-Security-Token", valid_593043
  var valid_593044 = header.getOrDefault("X-Amz-Algorithm")
  valid_593044 = validateParameter(valid_593044, JString, required = false,
                                 default = nil)
  if valid_593044 != nil:
    section.add "X-Amz-Algorithm", valid_593044
  var valid_593045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593045 = validateParameter(valid_593045, JString, required = false,
                                 default = nil)
  if valid_593045 != nil:
    section.add "X-Amz-SignedHeaders", valid_593045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593046: Call_DescribeJob_593020; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the configuration parameters and status for a batch operations job.
  ## 
  let valid = call_593046.validator(path, query, header, formData, body)
  let scheme = call_593046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593046.url(scheme.get, call_593046.host, call_593046.base,
                         call_593046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593046, url, valid)

proc call*(call_593047: Call_DescribeJob_593020; id: string): Recallable =
  ## describeJob
  ## Retrieves the configuration parameters and status for a batch operations job.
  ##   id: string (required)
  ##     : The ID for the job whose information you want to retrieve.
  var path_593048 = newJObject()
  add(path_593048, "id", newJString(id))
  result = call_593047.call(path_593048, nil, nil, nil, nil)

var describeJob* = Call_DescribeJob_593020(name: "describeJob",
                                        meth: HttpMethod.HttpGet,
                                        host: "s3-control.amazonaws.com", route: "/v20180820/jobs/{id}#x-amz-account-id",
                                        validator: validate_DescribeJob_593021,
                                        base: "/", url: url_DescribeJob_593022,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJobPriority_593049 = ref object of OpenApiRestCall_592364
proc url_UpdateJobPriority_593051(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateJobPriority_593050(path: JsonNode; query: JsonNode;
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
  var valid_593052 = path.getOrDefault("id")
  valid_593052 = validateParameter(valid_593052, JString, required = true,
                                 default = nil)
  if valid_593052 != nil:
    section.add "id", valid_593052
  result.add "path", section
  ## parameters in `query` object:
  ##   priority: JInt (required)
  ##           : The priority you want to assign to this job.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `priority` field"
  var valid_593053 = query.getOrDefault("priority")
  valid_593053 = validateParameter(valid_593053, JInt, required = true, default = nil)
  if valid_593053 != nil:
    section.add "priority", valid_593053
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593054 = header.getOrDefault("X-Amz-Signature")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Signature", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Content-Sha256", valid_593055
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_593056 = header.getOrDefault("x-amz-account-id")
  valid_593056 = validateParameter(valid_593056, JString, required = true,
                                 default = nil)
  if valid_593056 != nil:
    section.add "x-amz-account-id", valid_593056
  var valid_593057 = header.getOrDefault("X-Amz-Date")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "X-Amz-Date", valid_593057
  var valid_593058 = header.getOrDefault("X-Amz-Credential")
  valid_593058 = validateParameter(valid_593058, JString, required = false,
                                 default = nil)
  if valid_593058 != nil:
    section.add "X-Amz-Credential", valid_593058
  var valid_593059 = header.getOrDefault("X-Amz-Security-Token")
  valid_593059 = validateParameter(valid_593059, JString, required = false,
                                 default = nil)
  if valid_593059 != nil:
    section.add "X-Amz-Security-Token", valid_593059
  var valid_593060 = header.getOrDefault("X-Amz-Algorithm")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "X-Amz-Algorithm", valid_593060
  var valid_593061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593061 = validateParameter(valid_593061, JString, required = false,
                                 default = nil)
  if valid_593061 != nil:
    section.add "X-Amz-SignedHeaders", valid_593061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593062: Call_UpdateJobPriority_593049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing job's priority.
  ## 
  let valid = call_593062.validator(path, query, header, formData, body)
  let scheme = call_593062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593062.url(scheme.get, call_593062.host, call_593062.base,
                         call_593062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593062, url, valid)

proc call*(call_593063: Call_UpdateJobPriority_593049; id: string; priority: int): Recallable =
  ## updateJobPriority
  ## Updates an existing job's priority.
  ##   id: string (required)
  ##     : The ID for the job whose priority you want to update.
  ##   priority: int (required)
  ##           : The priority you want to assign to this job.
  var path_593064 = newJObject()
  var query_593065 = newJObject()
  add(path_593064, "id", newJString(id))
  add(query_593065, "priority", newJInt(priority))
  result = call_593063.call(path_593064, query_593065, nil, nil, nil)

var updateJobPriority* = Call_UpdateJobPriority_593049(name: "updateJobPriority",
    meth: HttpMethod.HttpPost, host: "s3-control.amazonaws.com",
    route: "/v20180820/jobs/{id}/priority#x-amz-account-id&priority",
    validator: validate_UpdateJobPriority_593050, base: "/",
    url: url_UpdateJobPriority_593051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJobStatus_593066 = ref object of OpenApiRestCall_592364
proc url_UpdateJobStatus_593068(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateJobStatus_593067(path: JsonNode; query: JsonNode;
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
  var valid_593069 = path.getOrDefault("id")
  valid_593069 = validateParameter(valid_593069, JString, required = true,
                                 default = nil)
  if valid_593069 != nil:
    section.add "id", valid_593069
  result.add "path", section
  ## parameters in `query` object:
  ##   statusUpdateReason: JString
  ##                     : A description of the reason why you want to change the specified job's status. This field can be any string up to the maximum length.
  ##   requestedJobStatus: JString (required)
  ##                     : The status that you want to move the specified job to.
  section = newJObject()
  var valid_593070 = query.getOrDefault("statusUpdateReason")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "statusUpdateReason", valid_593070
  assert query != nil, "query argument is necessary due to required `requestedJobStatus` field"
  var valid_593084 = query.getOrDefault("requestedJobStatus")
  valid_593084 = validateParameter(valid_593084, JString, required = true,
                                 default = newJString("Cancelled"))
  if valid_593084 != nil:
    section.add "requestedJobStatus", valid_593084
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593085 = header.getOrDefault("X-Amz-Signature")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "X-Amz-Signature", valid_593085
  var valid_593086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "X-Amz-Content-Sha256", valid_593086
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_593087 = header.getOrDefault("x-amz-account-id")
  valid_593087 = validateParameter(valid_593087, JString, required = true,
                                 default = nil)
  if valid_593087 != nil:
    section.add "x-amz-account-id", valid_593087
  var valid_593088 = header.getOrDefault("X-Amz-Date")
  valid_593088 = validateParameter(valid_593088, JString, required = false,
                                 default = nil)
  if valid_593088 != nil:
    section.add "X-Amz-Date", valid_593088
  var valid_593089 = header.getOrDefault("X-Amz-Credential")
  valid_593089 = validateParameter(valid_593089, JString, required = false,
                                 default = nil)
  if valid_593089 != nil:
    section.add "X-Amz-Credential", valid_593089
  var valid_593090 = header.getOrDefault("X-Amz-Security-Token")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "X-Amz-Security-Token", valid_593090
  var valid_593091 = header.getOrDefault("X-Amz-Algorithm")
  valid_593091 = validateParameter(valid_593091, JString, required = false,
                                 default = nil)
  if valid_593091 != nil:
    section.add "X-Amz-Algorithm", valid_593091
  var valid_593092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "X-Amz-SignedHeaders", valid_593092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593093: Call_UpdateJobStatus_593066; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status for the specified job. Use this operation to confirm that you want to run a job or to cancel an existing job.
  ## 
  let valid = call_593093.validator(path, query, header, formData, body)
  let scheme = call_593093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593093.url(scheme.get, call_593093.host, call_593093.base,
                         call_593093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593093, url, valid)

proc call*(call_593094: Call_UpdateJobStatus_593066; id: string;
          statusUpdateReason: string = ""; requestedJobStatus: string = "Cancelled"): Recallable =
  ## updateJobStatus
  ## Updates the status for the specified job. Use this operation to confirm that you want to run a job or to cancel an existing job.
  ##   statusUpdateReason: string
  ##                     : A description of the reason why you want to change the specified job's status. This field can be any string up to the maximum length.
  ##   id: string (required)
  ##     : The ID of the job whose status you want to update.
  ##   requestedJobStatus: string (required)
  ##                     : The status that you want to move the specified job to.
  var path_593095 = newJObject()
  var query_593096 = newJObject()
  add(query_593096, "statusUpdateReason", newJString(statusUpdateReason))
  add(path_593095, "id", newJString(id))
  add(query_593096, "requestedJobStatus", newJString(requestedJobStatus))
  result = call_593094.call(path_593095, query_593096, nil, nil, nil)

var updateJobStatus* = Call_UpdateJobStatus_593066(name: "updateJobStatus",
    meth: HttpMethod.HttpPost, host: "s3-control.amazonaws.com",
    route: "/v20180820/jobs/{id}/status#x-amz-account-id&requestedJobStatus",
    validator: validate_UpdateJobStatus_593067, base: "/", url: url_UpdateJobStatus_593068,
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
