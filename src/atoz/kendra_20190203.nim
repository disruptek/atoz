
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWSKendraFrontendService
## version: 2019-02-03
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Amazon Kendra is a service for indexing large document sets.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/kendra/
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

  OpenApiRestCall_597389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_597389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_597389): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "kendra.ap-northeast-1.amazonaws.com", "ap-southeast-1": "kendra.ap-southeast-1.amazonaws.com",
                           "us-west-2": "kendra.us-west-2.amazonaws.com",
                           "eu-west-2": "kendra.eu-west-2.amazonaws.com", "ap-northeast-3": "kendra.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "kendra.eu-central-1.amazonaws.com",
                           "us-east-2": "kendra.us-east-2.amazonaws.com",
                           "us-east-1": "kendra.us-east-1.amazonaws.com", "cn-northwest-1": "kendra.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "kendra.ap-south-1.amazonaws.com",
                           "eu-north-1": "kendra.eu-north-1.amazonaws.com", "ap-northeast-2": "kendra.ap-northeast-2.amazonaws.com",
                           "us-west-1": "kendra.us-west-1.amazonaws.com", "us-gov-east-1": "kendra.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "kendra.eu-west-3.amazonaws.com",
                           "cn-north-1": "kendra.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "kendra.sa-east-1.amazonaws.com",
                           "eu-west-1": "kendra.eu-west-1.amazonaws.com", "us-gov-west-1": "kendra.us-gov-west-1.amazonaws.com", "ap-southeast-2": "kendra.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "kendra.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "kendra.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "kendra.ap-southeast-1.amazonaws.com",
      "us-west-2": "kendra.us-west-2.amazonaws.com",
      "eu-west-2": "kendra.eu-west-2.amazonaws.com",
      "ap-northeast-3": "kendra.ap-northeast-3.amazonaws.com",
      "eu-central-1": "kendra.eu-central-1.amazonaws.com",
      "us-east-2": "kendra.us-east-2.amazonaws.com",
      "us-east-1": "kendra.us-east-1.amazonaws.com",
      "cn-northwest-1": "kendra.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "kendra.ap-south-1.amazonaws.com",
      "eu-north-1": "kendra.eu-north-1.amazonaws.com",
      "ap-northeast-2": "kendra.ap-northeast-2.amazonaws.com",
      "us-west-1": "kendra.us-west-1.amazonaws.com",
      "us-gov-east-1": "kendra.us-gov-east-1.amazonaws.com",
      "eu-west-3": "kendra.eu-west-3.amazonaws.com",
      "cn-north-1": "kendra.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "kendra.sa-east-1.amazonaws.com",
      "eu-west-1": "kendra.eu-west-1.amazonaws.com",
      "us-gov-west-1": "kendra.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "kendra.ap-southeast-2.amazonaws.com",
      "ca-central-1": "kendra.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "kendra"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchDeleteDocument_597727 = ref object of OpenApiRestCall_597389
proc url_BatchDeleteDocument_597729(protocol: Scheme; host: string; base: string;
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

proc validate_BatchDeleteDocument_597728(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Removes one or more documents from an index. The documents must have been added with the <a>BatchPutDocument</a> operation.</p> <p>The documents are deleted asynchronously. You can see the progress of the deletion by using AWS CloudWatch. Any error messages releated to the processing of the batch are sent to you CloudWatch log.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_597854 = header.getOrDefault("X-Amz-Target")
  valid_597854 = validateParameter(valid_597854, JString, required = true, default = newJString(
      "AWSKendraFrontendService.BatchDeleteDocument"))
  if valid_597854 != nil:
    section.add "X-Amz-Target", valid_597854
  var valid_597855 = header.getOrDefault("X-Amz-Signature")
  valid_597855 = validateParameter(valid_597855, JString, required = false,
                                 default = nil)
  if valid_597855 != nil:
    section.add "X-Amz-Signature", valid_597855
  var valid_597856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597856 = validateParameter(valid_597856, JString, required = false,
                                 default = nil)
  if valid_597856 != nil:
    section.add "X-Amz-Content-Sha256", valid_597856
  var valid_597857 = header.getOrDefault("X-Amz-Date")
  valid_597857 = validateParameter(valid_597857, JString, required = false,
                                 default = nil)
  if valid_597857 != nil:
    section.add "X-Amz-Date", valid_597857
  var valid_597858 = header.getOrDefault("X-Amz-Credential")
  valid_597858 = validateParameter(valid_597858, JString, required = false,
                                 default = nil)
  if valid_597858 != nil:
    section.add "X-Amz-Credential", valid_597858
  var valid_597859 = header.getOrDefault("X-Amz-Security-Token")
  valid_597859 = validateParameter(valid_597859, JString, required = false,
                                 default = nil)
  if valid_597859 != nil:
    section.add "X-Amz-Security-Token", valid_597859
  var valid_597860 = header.getOrDefault("X-Amz-Algorithm")
  valid_597860 = validateParameter(valid_597860, JString, required = false,
                                 default = nil)
  if valid_597860 != nil:
    section.add "X-Amz-Algorithm", valid_597860
  var valid_597861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597861 = validateParameter(valid_597861, JString, required = false,
                                 default = nil)
  if valid_597861 != nil:
    section.add "X-Amz-SignedHeaders", valid_597861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_597885: Call_BatchDeleteDocument_597727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes one or more documents from an index. The documents must have been added with the <a>BatchPutDocument</a> operation.</p> <p>The documents are deleted asynchronously. You can see the progress of the deletion by using AWS CloudWatch. Any error messages releated to the processing of the batch are sent to you CloudWatch log.</p>
  ## 
  let valid = call_597885.validator(path, query, header, formData, body)
  let scheme = call_597885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597885.url(scheme.get, call_597885.host, call_597885.base,
                         call_597885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597885, url, valid)

proc call*(call_597956: Call_BatchDeleteDocument_597727; body: JsonNode): Recallable =
  ## batchDeleteDocument
  ## <p>Removes one or more documents from an index. The documents must have been added with the <a>BatchPutDocument</a> operation.</p> <p>The documents are deleted asynchronously. You can see the progress of the deletion by using AWS CloudWatch. Any error messages releated to the processing of the batch are sent to you CloudWatch log.</p>
  ##   body: JObject (required)
  var body_597957 = newJObject()
  if body != nil:
    body_597957 = body
  result = call_597956.call(nil, nil, nil, nil, body_597957)

var batchDeleteDocument* = Call_BatchDeleteDocument_597727(
    name: "batchDeleteDocument", meth: HttpMethod.HttpPost,
    host: "kendra.amazonaws.com",
    route: "/#X-Amz-Target=AWSKendraFrontendService.BatchDeleteDocument",
    validator: validate_BatchDeleteDocument_597728, base: "/",
    url: url_BatchDeleteDocument_597729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchPutDocument_597996 = ref object of OpenApiRestCall_597389
proc url_BatchPutDocument_597998(protocol: Scheme; host: string; base: string;
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

proc validate_BatchPutDocument_597997(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Adds one or more documents to an index.</p> <p>The <code>BatchPutDocument</code> operation enables you to ingest inline documents or a set of documents stored in an Amazon S3 bucket. Use this operation to ingest your text and unstructured text into an index, add custom attributes to the documents, and to attach an access control list to the documents added to the index.</p> <p>The documents are indexed asynchronously. You can see the progress of the batch using AWS CloudWatch. Any error messages related to processing the batch are sent to your AWS CloudWatch log.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_597999 = header.getOrDefault("X-Amz-Target")
  valid_597999 = validateParameter(valid_597999, JString, required = true, default = newJString(
      "AWSKendraFrontendService.BatchPutDocument"))
  if valid_597999 != nil:
    section.add "X-Amz-Target", valid_597999
  var valid_598000 = header.getOrDefault("X-Amz-Signature")
  valid_598000 = validateParameter(valid_598000, JString, required = false,
                                 default = nil)
  if valid_598000 != nil:
    section.add "X-Amz-Signature", valid_598000
  var valid_598001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598001 = validateParameter(valid_598001, JString, required = false,
                                 default = nil)
  if valid_598001 != nil:
    section.add "X-Amz-Content-Sha256", valid_598001
  var valid_598002 = header.getOrDefault("X-Amz-Date")
  valid_598002 = validateParameter(valid_598002, JString, required = false,
                                 default = nil)
  if valid_598002 != nil:
    section.add "X-Amz-Date", valid_598002
  var valid_598003 = header.getOrDefault("X-Amz-Credential")
  valid_598003 = validateParameter(valid_598003, JString, required = false,
                                 default = nil)
  if valid_598003 != nil:
    section.add "X-Amz-Credential", valid_598003
  var valid_598004 = header.getOrDefault("X-Amz-Security-Token")
  valid_598004 = validateParameter(valid_598004, JString, required = false,
                                 default = nil)
  if valid_598004 != nil:
    section.add "X-Amz-Security-Token", valid_598004
  var valid_598005 = header.getOrDefault("X-Amz-Algorithm")
  valid_598005 = validateParameter(valid_598005, JString, required = false,
                                 default = nil)
  if valid_598005 != nil:
    section.add "X-Amz-Algorithm", valid_598005
  var valid_598006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598006 = validateParameter(valid_598006, JString, required = false,
                                 default = nil)
  if valid_598006 != nil:
    section.add "X-Amz-SignedHeaders", valid_598006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598008: Call_BatchPutDocument_597996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more documents to an index.</p> <p>The <code>BatchPutDocument</code> operation enables you to ingest inline documents or a set of documents stored in an Amazon S3 bucket. Use this operation to ingest your text and unstructured text into an index, add custom attributes to the documents, and to attach an access control list to the documents added to the index.</p> <p>The documents are indexed asynchronously. You can see the progress of the batch using AWS CloudWatch. Any error messages related to processing the batch are sent to your AWS CloudWatch log.</p>
  ## 
  let valid = call_598008.validator(path, query, header, formData, body)
  let scheme = call_598008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598008.url(scheme.get, call_598008.host, call_598008.base,
                         call_598008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598008, url, valid)

proc call*(call_598009: Call_BatchPutDocument_597996; body: JsonNode): Recallable =
  ## batchPutDocument
  ## <p>Adds one or more documents to an index.</p> <p>The <code>BatchPutDocument</code> operation enables you to ingest inline documents or a set of documents stored in an Amazon S3 bucket. Use this operation to ingest your text and unstructured text into an index, add custom attributes to the documents, and to attach an access control list to the documents added to the index.</p> <p>The documents are indexed asynchronously. You can see the progress of the batch using AWS CloudWatch. Any error messages related to processing the batch are sent to your AWS CloudWatch log.</p>
  ##   body: JObject (required)
  var body_598010 = newJObject()
  if body != nil:
    body_598010 = body
  result = call_598009.call(nil, nil, nil, nil, body_598010)

var batchPutDocument* = Call_BatchPutDocument_597996(name: "batchPutDocument",
    meth: HttpMethod.HttpPost, host: "kendra.amazonaws.com",
    route: "/#X-Amz-Target=AWSKendraFrontendService.BatchPutDocument",
    validator: validate_BatchPutDocument_597997, base: "/",
    url: url_BatchPutDocument_597998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSource_598011 = ref object of OpenApiRestCall_597389
proc url_CreateDataSource_598013(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDataSource_598012(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Creates a data source that you use to with an Amazon Kendra index. </p> <p>You specify a name, connector type and description for your data source. You can choose between an S3 connector, a SharePoint Online connector, and a database connector.</p> <p>You also specify configuration information such as document metadata (author, source URI, and so on) and user context information.</p> <p> <code>CreateDataSource</code> is a synchronous operation. The operation returns 200 if the data source was successfully created. Otherwise, an exception is raised.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598014 = header.getOrDefault("X-Amz-Target")
  valid_598014 = validateParameter(valid_598014, JString, required = true, default = newJString(
      "AWSKendraFrontendService.CreateDataSource"))
  if valid_598014 != nil:
    section.add "X-Amz-Target", valid_598014
  var valid_598015 = header.getOrDefault("X-Amz-Signature")
  valid_598015 = validateParameter(valid_598015, JString, required = false,
                                 default = nil)
  if valid_598015 != nil:
    section.add "X-Amz-Signature", valid_598015
  var valid_598016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598016 = validateParameter(valid_598016, JString, required = false,
                                 default = nil)
  if valid_598016 != nil:
    section.add "X-Amz-Content-Sha256", valid_598016
  var valid_598017 = header.getOrDefault("X-Amz-Date")
  valid_598017 = validateParameter(valid_598017, JString, required = false,
                                 default = nil)
  if valid_598017 != nil:
    section.add "X-Amz-Date", valid_598017
  var valid_598018 = header.getOrDefault("X-Amz-Credential")
  valid_598018 = validateParameter(valid_598018, JString, required = false,
                                 default = nil)
  if valid_598018 != nil:
    section.add "X-Amz-Credential", valid_598018
  var valid_598019 = header.getOrDefault("X-Amz-Security-Token")
  valid_598019 = validateParameter(valid_598019, JString, required = false,
                                 default = nil)
  if valid_598019 != nil:
    section.add "X-Amz-Security-Token", valid_598019
  var valid_598020 = header.getOrDefault("X-Amz-Algorithm")
  valid_598020 = validateParameter(valid_598020, JString, required = false,
                                 default = nil)
  if valid_598020 != nil:
    section.add "X-Amz-Algorithm", valid_598020
  var valid_598021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598021 = validateParameter(valid_598021, JString, required = false,
                                 default = nil)
  if valid_598021 != nil:
    section.add "X-Amz-SignedHeaders", valid_598021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598023: Call_CreateDataSource_598011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a data source that you use to with an Amazon Kendra index. </p> <p>You specify a name, connector type and description for your data source. You can choose between an S3 connector, a SharePoint Online connector, and a database connector.</p> <p>You also specify configuration information such as document metadata (author, source URI, and so on) and user context information.</p> <p> <code>CreateDataSource</code> is a synchronous operation. The operation returns 200 if the data source was successfully created. Otherwise, an exception is raised.</p>
  ## 
  let valid = call_598023.validator(path, query, header, formData, body)
  let scheme = call_598023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598023.url(scheme.get, call_598023.host, call_598023.base,
                         call_598023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598023, url, valid)

proc call*(call_598024: Call_CreateDataSource_598011; body: JsonNode): Recallable =
  ## createDataSource
  ## <p>Creates a data source that you use to with an Amazon Kendra index. </p> <p>You specify a name, connector type and description for your data source. You can choose between an S3 connector, a SharePoint Online connector, and a database connector.</p> <p>You also specify configuration information such as document metadata (author, source URI, and so on) and user context information.</p> <p> <code>CreateDataSource</code> is a synchronous operation. The operation returns 200 if the data source was successfully created. Otherwise, an exception is raised.</p>
  ##   body: JObject (required)
  var body_598025 = newJObject()
  if body != nil:
    body_598025 = body
  result = call_598024.call(nil, nil, nil, nil, body_598025)

var createDataSource* = Call_CreateDataSource_598011(name: "createDataSource",
    meth: HttpMethod.HttpPost, host: "kendra.amazonaws.com",
    route: "/#X-Amz-Target=AWSKendraFrontendService.CreateDataSource",
    validator: validate_CreateDataSource_598012, base: "/",
    url: url_CreateDataSource_598013, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFaq_598026 = ref object of OpenApiRestCall_597389
proc url_CreateFaq_598028(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateFaq_598027(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an new set of frequently asked question (FAQ) questions and answers.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598029 = header.getOrDefault("X-Amz-Target")
  valid_598029 = validateParameter(valid_598029, JString, required = true, default = newJString(
      "AWSKendraFrontendService.CreateFaq"))
  if valid_598029 != nil:
    section.add "X-Amz-Target", valid_598029
  var valid_598030 = header.getOrDefault("X-Amz-Signature")
  valid_598030 = validateParameter(valid_598030, JString, required = false,
                                 default = nil)
  if valid_598030 != nil:
    section.add "X-Amz-Signature", valid_598030
  var valid_598031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598031 = validateParameter(valid_598031, JString, required = false,
                                 default = nil)
  if valid_598031 != nil:
    section.add "X-Amz-Content-Sha256", valid_598031
  var valid_598032 = header.getOrDefault("X-Amz-Date")
  valid_598032 = validateParameter(valid_598032, JString, required = false,
                                 default = nil)
  if valid_598032 != nil:
    section.add "X-Amz-Date", valid_598032
  var valid_598033 = header.getOrDefault("X-Amz-Credential")
  valid_598033 = validateParameter(valid_598033, JString, required = false,
                                 default = nil)
  if valid_598033 != nil:
    section.add "X-Amz-Credential", valid_598033
  var valid_598034 = header.getOrDefault("X-Amz-Security-Token")
  valid_598034 = validateParameter(valid_598034, JString, required = false,
                                 default = nil)
  if valid_598034 != nil:
    section.add "X-Amz-Security-Token", valid_598034
  var valid_598035 = header.getOrDefault("X-Amz-Algorithm")
  valid_598035 = validateParameter(valid_598035, JString, required = false,
                                 default = nil)
  if valid_598035 != nil:
    section.add "X-Amz-Algorithm", valid_598035
  var valid_598036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598036 = validateParameter(valid_598036, JString, required = false,
                                 default = nil)
  if valid_598036 != nil:
    section.add "X-Amz-SignedHeaders", valid_598036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598038: Call_CreateFaq_598026; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an new set of frequently asked question (FAQ) questions and answers.
  ## 
  let valid = call_598038.validator(path, query, header, formData, body)
  let scheme = call_598038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598038.url(scheme.get, call_598038.host, call_598038.base,
                         call_598038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598038, url, valid)

proc call*(call_598039: Call_CreateFaq_598026; body: JsonNode): Recallable =
  ## createFaq
  ## Creates an new set of frequently asked question (FAQ) questions and answers.
  ##   body: JObject (required)
  var body_598040 = newJObject()
  if body != nil:
    body_598040 = body
  result = call_598039.call(nil, nil, nil, nil, body_598040)

var createFaq* = Call_CreateFaq_598026(name: "createFaq", meth: HttpMethod.HttpPost,
                                    host: "kendra.amazonaws.com", route: "/#X-Amz-Target=AWSKendraFrontendService.CreateFaq",
                                    validator: validate_CreateFaq_598027,
                                    base: "/", url: url_CreateFaq_598028,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIndex_598041 = ref object of OpenApiRestCall_597389
proc url_CreateIndex_598043(protocol: Scheme; host: string; base: string;
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

proc validate_CreateIndex_598042(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new Amazon Kendra index. Index creation is an asynchronous operation. To determine if index creation has completed, check the <code>Status</code> field returned from a call to . The <code>Status</code> field is set to <code>ACTIVE</code> when the index is ready to use.</p> <p>Once the index is active you can index your documents using the operation or using one of the supported data sources. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598044 = header.getOrDefault("X-Amz-Target")
  valid_598044 = validateParameter(valid_598044, JString, required = true, default = newJString(
      "AWSKendraFrontendService.CreateIndex"))
  if valid_598044 != nil:
    section.add "X-Amz-Target", valid_598044
  var valid_598045 = header.getOrDefault("X-Amz-Signature")
  valid_598045 = validateParameter(valid_598045, JString, required = false,
                                 default = nil)
  if valid_598045 != nil:
    section.add "X-Amz-Signature", valid_598045
  var valid_598046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598046 = validateParameter(valid_598046, JString, required = false,
                                 default = nil)
  if valid_598046 != nil:
    section.add "X-Amz-Content-Sha256", valid_598046
  var valid_598047 = header.getOrDefault("X-Amz-Date")
  valid_598047 = validateParameter(valid_598047, JString, required = false,
                                 default = nil)
  if valid_598047 != nil:
    section.add "X-Amz-Date", valid_598047
  var valid_598048 = header.getOrDefault("X-Amz-Credential")
  valid_598048 = validateParameter(valid_598048, JString, required = false,
                                 default = nil)
  if valid_598048 != nil:
    section.add "X-Amz-Credential", valid_598048
  var valid_598049 = header.getOrDefault("X-Amz-Security-Token")
  valid_598049 = validateParameter(valid_598049, JString, required = false,
                                 default = nil)
  if valid_598049 != nil:
    section.add "X-Amz-Security-Token", valid_598049
  var valid_598050 = header.getOrDefault("X-Amz-Algorithm")
  valid_598050 = validateParameter(valid_598050, JString, required = false,
                                 default = nil)
  if valid_598050 != nil:
    section.add "X-Amz-Algorithm", valid_598050
  var valid_598051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598051 = validateParameter(valid_598051, JString, required = false,
                                 default = nil)
  if valid_598051 != nil:
    section.add "X-Amz-SignedHeaders", valid_598051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598053: Call_CreateIndex_598041; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new Amazon Kendra index. Index creation is an asynchronous operation. To determine if index creation has completed, check the <code>Status</code> field returned from a call to . The <code>Status</code> field is set to <code>ACTIVE</code> when the index is ready to use.</p> <p>Once the index is active you can index your documents using the operation or using one of the supported data sources. </p>
  ## 
  let valid = call_598053.validator(path, query, header, formData, body)
  let scheme = call_598053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598053.url(scheme.get, call_598053.host, call_598053.base,
                         call_598053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598053, url, valid)

proc call*(call_598054: Call_CreateIndex_598041; body: JsonNode): Recallable =
  ## createIndex
  ## <p>Creates a new Amazon Kendra index. Index creation is an asynchronous operation. To determine if index creation has completed, check the <code>Status</code> field returned from a call to . The <code>Status</code> field is set to <code>ACTIVE</code> when the index is ready to use.</p> <p>Once the index is active you can index your documents using the operation or using one of the supported data sources. </p>
  ##   body: JObject (required)
  var body_598055 = newJObject()
  if body != nil:
    body_598055 = body
  result = call_598054.call(nil, nil, nil, nil, body_598055)

var createIndex* = Call_CreateIndex_598041(name: "createIndex",
                                        meth: HttpMethod.HttpPost,
                                        host: "kendra.amazonaws.com", route: "/#X-Amz-Target=AWSKendraFrontendService.CreateIndex",
                                        validator: validate_CreateIndex_598042,
                                        base: "/", url: url_CreateIndex_598043,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFaq_598056 = ref object of OpenApiRestCall_597389
proc url_DeleteFaq_598058(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteFaq_598057(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes an FAQ from an index.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598059 = header.getOrDefault("X-Amz-Target")
  valid_598059 = validateParameter(valid_598059, JString, required = true, default = newJString(
      "AWSKendraFrontendService.DeleteFaq"))
  if valid_598059 != nil:
    section.add "X-Amz-Target", valid_598059
  var valid_598060 = header.getOrDefault("X-Amz-Signature")
  valid_598060 = validateParameter(valid_598060, JString, required = false,
                                 default = nil)
  if valid_598060 != nil:
    section.add "X-Amz-Signature", valid_598060
  var valid_598061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598061 = validateParameter(valid_598061, JString, required = false,
                                 default = nil)
  if valid_598061 != nil:
    section.add "X-Amz-Content-Sha256", valid_598061
  var valid_598062 = header.getOrDefault("X-Amz-Date")
  valid_598062 = validateParameter(valid_598062, JString, required = false,
                                 default = nil)
  if valid_598062 != nil:
    section.add "X-Amz-Date", valid_598062
  var valid_598063 = header.getOrDefault("X-Amz-Credential")
  valid_598063 = validateParameter(valid_598063, JString, required = false,
                                 default = nil)
  if valid_598063 != nil:
    section.add "X-Amz-Credential", valid_598063
  var valid_598064 = header.getOrDefault("X-Amz-Security-Token")
  valid_598064 = validateParameter(valid_598064, JString, required = false,
                                 default = nil)
  if valid_598064 != nil:
    section.add "X-Amz-Security-Token", valid_598064
  var valid_598065 = header.getOrDefault("X-Amz-Algorithm")
  valid_598065 = validateParameter(valid_598065, JString, required = false,
                                 default = nil)
  if valid_598065 != nil:
    section.add "X-Amz-Algorithm", valid_598065
  var valid_598066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598066 = validateParameter(valid_598066, JString, required = false,
                                 default = nil)
  if valid_598066 != nil:
    section.add "X-Amz-SignedHeaders", valid_598066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598068: Call_DeleteFaq_598056; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an FAQ from an index.
  ## 
  let valid = call_598068.validator(path, query, header, formData, body)
  let scheme = call_598068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598068.url(scheme.get, call_598068.host, call_598068.base,
                         call_598068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598068, url, valid)

proc call*(call_598069: Call_DeleteFaq_598056; body: JsonNode): Recallable =
  ## deleteFaq
  ## Removes an FAQ from an index.
  ##   body: JObject (required)
  var body_598070 = newJObject()
  if body != nil:
    body_598070 = body
  result = call_598069.call(nil, nil, nil, nil, body_598070)

var deleteFaq* = Call_DeleteFaq_598056(name: "deleteFaq", meth: HttpMethod.HttpPost,
                                    host: "kendra.amazonaws.com", route: "/#X-Amz-Target=AWSKendraFrontendService.DeleteFaq",
                                    validator: validate_DeleteFaq_598057,
                                    base: "/", url: url_DeleteFaq_598058,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIndex_598071 = ref object of OpenApiRestCall_597389
proc url_DeleteIndex_598073(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIndex_598072(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing Amazon Kendra index. An exception is not thrown if the index is already being deleted. While the index is being deleted, the <code>Status</code> field returned by a call to the <a>DescribeIndex</a> operation is set to <code>DELETING</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598074 = header.getOrDefault("X-Amz-Target")
  valid_598074 = validateParameter(valid_598074, JString, required = true, default = newJString(
      "AWSKendraFrontendService.DeleteIndex"))
  if valid_598074 != nil:
    section.add "X-Amz-Target", valid_598074
  var valid_598075 = header.getOrDefault("X-Amz-Signature")
  valid_598075 = validateParameter(valid_598075, JString, required = false,
                                 default = nil)
  if valid_598075 != nil:
    section.add "X-Amz-Signature", valid_598075
  var valid_598076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598076 = validateParameter(valid_598076, JString, required = false,
                                 default = nil)
  if valid_598076 != nil:
    section.add "X-Amz-Content-Sha256", valid_598076
  var valid_598077 = header.getOrDefault("X-Amz-Date")
  valid_598077 = validateParameter(valid_598077, JString, required = false,
                                 default = nil)
  if valid_598077 != nil:
    section.add "X-Amz-Date", valid_598077
  var valid_598078 = header.getOrDefault("X-Amz-Credential")
  valid_598078 = validateParameter(valid_598078, JString, required = false,
                                 default = nil)
  if valid_598078 != nil:
    section.add "X-Amz-Credential", valid_598078
  var valid_598079 = header.getOrDefault("X-Amz-Security-Token")
  valid_598079 = validateParameter(valid_598079, JString, required = false,
                                 default = nil)
  if valid_598079 != nil:
    section.add "X-Amz-Security-Token", valid_598079
  var valid_598080 = header.getOrDefault("X-Amz-Algorithm")
  valid_598080 = validateParameter(valid_598080, JString, required = false,
                                 default = nil)
  if valid_598080 != nil:
    section.add "X-Amz-Algorithm", valid_598080
  var valid_598081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598081 = validateParameter(valid_598081, JString, required = false,
                                 default = nil)
  if valid_598081 != nil:
    section.add "X-Amz-SignedHeaders", valid_598081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598083: Call_DeleteIndex_598071; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing Amazon Kendra index. An exception is not thrown if the index is already being deleted. While the index is being deleted, the <code>Status</code> field returned by a call to the <a>DescribeIndex</a> operation is set to <code>DELETING</code>.
  ## 
  let valid = call_598083.validator(path, query, header, formData, body)
  let scheme = call_598083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598083.url(scheme.get, call_598083.host, call_598083.base,
                         call_598083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598083, url, valid)

proc call*(call_598084: Call_DeleteIndex_598071; body: JsonNode): Recallable =
  ## deleteIndex
  ## Deletes an existing Amazon Kendra index. An exception is not thrown if the index is already being deleted. While the index is being deleted, the <code>Status</code> field returned by a call to the <a>DescribeIndex</a> operation is set to <code>DELETING</code>.
  ##   body: JObject (required)
  var body_598085 = newJObject()
  if body != nil:
    body_598085 = body
  result = call_598084.call(nil, nil, nil, nil, body_598085)

var deleteIndex* = Call_DeleteIndex_598071(name: "deleteIndex",
                                        meth: HttpMethod.HttpPost,
                                        host: "kendra.amazonaws.com", route: "/#X-Amz-Target=AWSKendraFrontendService.DeleteIndex",
                                        validator: validate_DeleteIndex_598072,
                                        base: "/", url: url_DeleteIndex_598073,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSource_598086 = ref object of OpenApiRestCall_597389
proc url_DescribeDataSource_598088(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDataSource_598087(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Gets information about a Amazon Kendra data source.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598089 = header.getOrDefault("X-Amz-Target")
  valid_598089 = validateParameter(valid_598089, JString, required = true, default = newJString(
      "AWSKendraFrontendService.DescribeDataSource"))
  if valid_598089 != nil:
    section.add "X-Amz-Target", valid_598089
  var valid_598090 = header.getOrDefault("X-Amz-Signature")
  valid_598090 = validateParameter(valid_598090, JString, required = false,
                                 default = nil)
  if valid_598090 != nil:
    section.add "X-Amz-Signature", valid_598090
  var valid_598091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598091 = validateParameter(valid_598091, JString, required = false,
                                 default = nil)
  if valid_598091 != nil:
    section.add "X-Amz-Content-Sha256", valid_598091
  var valid_598092 = header.getOrDefault("X-Amz-Date")
  valid_598092 = validateParameter(valid_598092, JString, required = false,
                                 default = nil)
  if valid_598092 != nil:
    section.add "X-Amz-Date", valid_598092
  var valid_598093 = header.getOrDefault("X-Amz-Credential")
  valid_598093 = validateParameter(valid_598093, JString, required = false,
                                 default = nil)
  if valid_598093 != nil:
    section.add "X-Amz-Credential", valid_598093
  var valid_598094 = header.getOrDefault("X-Amz-Security-Token")
  valid_598094 = validateParameter(valid_598094, JString, required = false,
                                 default = nil)
  if valid_598094 != nil:
    section.add "X-Amz-Security-Token", valid_598094
  var valid_598095 = header.getOrDefault("X-Amz-Algorithm")
  valid_598095 = validateParameter(valid_598095, JString, required = false,
                                 default = nil)
  if valid_598095 != nil:
    section.add "X-Amz-Algorithm", valid_598095
  var valid_598096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598096 = validateParameter(valid_598096, JString, required = false,
                                 default = nil)
  if valid_598096 != nil:
    section.add "X-Amz-SignedHeaders", valid_598096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598098: Call_DescribeDataSource_598086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a Amazon Kendra data source.
  ## 
  let valid = call_598098.validator(path, query, header, formData, body)
  let scheme = call_598098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598098.url(scheme.get, call_598098.host, call_598098.base,
                         call_598098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598098, url, valid)

proc call*(call_598099: Call_DescribeDataSource_598086; body: JsonNode): Recallable =
  ## describeDataSource
  ## Gets information about a Amazon Kendra data source.
  ##   body: JObject (required)
  var body_598100 = newJObject()
  if body != nil:
    body_598100 = body
  result = call_598099.call(nil, nil, nil, nil, body_598100)

var describeDataSource* = Call_DescribeDataSource_598086(
    name: "describeDataSource", meth: HttpMethod.HttpPost,
    host: "kendra.amazonaws.com",
    route: "/#X-Amz-Target=AWSKendraFrontendService.DescribeDataSource",
    validator: validate_DescribeDataSource_598087, base: "/",
    url: url_DescribeDataSource_598088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFaq_598101 = ref object of OpenApiRestCall_597389
proc url_DescribeFaq_598103(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeFaq_598102(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about an FAQ list.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598104 = header.getOrDefault("X-Amz-Target")
  valid_598104 = validateParameter(valid_598104, JString, required = true, default = newJString(
      "AWSKendraFrontendService.DescribeFaq"))
  if valid_598104 != nil:
    section.add "X-Amz-Target", valid_598104
  var valid_598105 = header.getOrDefault("X-Amz-Signature")
  valid_598105 = validateParameter(valid_598105, JString, required = false,
                                 default = nil)
  if valid_598105 != nil:
    section.add "X-Amz-Signature", valid_598105
  var valid_598106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598106 = validateParameter(valid_598106, JString, required = false,
                                 default = nil)
  if valid_598106 != nil:
    section.add "X-Amz-Content-Sha256", valid_598106
  var valid_598107 = header.getOrDefault("X-Amz-Date")
  valid_598107 = validateParameter(valid_598107, JString, required = false,
                                 default = nil)
  if valid_598107 != nil:
    section.add "X-Amz-Date", valid_598107
  var valid_598108 = header.getOrDefault("X-Amz-Credential")
  valid_598108 = validateParameter(valid_598108, JString, required = false,
                                 default = nil)
  if valid_598108 != nil:
    section.add "X-Amz-Credential", valid_598108
  var valid_598109 = header.getOrDefault("X-Amz-Security-Token")
  valid_598109 = validateParameter(valid_598109, JString, required = false,
                                 default = nil)
  if valid_598109 != nil:
    section.add "X-Amz-Security-Token", valid_598109
  var valid_598110 = header.getOrDefault("X-Amz-Algorithm")
  valid_598110 = validateParameter(valid_598110, JString, required = false,
                                 default = nil)
  if valid_598110 != nil:
    section.add "X-Amz-Algorithm", valid_598110
  var valid_598111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598111 = validateParameter(valid_598111, JString, required = false,
                                 default = nil)
  if valid_598111 != nil:
    section.add "X-Amz-SignedHeaders", valid_598111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598113: Call_DescribeFaq_598101; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an FAQ list.
  ## 
  let valid = call_598113.validator(path, query, header, formData, body)
  let scheme = call_598113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598113.url(scheme.get, call_598113.host, call_598113.base,
                         call_598113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598113, url, valid)

proc call*(call_598114: Call_DescribeFaq_598101; body: JsonNode): Recallable =
  ## describeFaq
  ## Gets information about an FAQ list.
  ##   body: JObject (required)
  var body_598115 = newJObject()
  if body != nil:
    body_598115 = body
  result = call_598114.call(nil, nil, nil, nil, body_598115)

var describeFaq* = Call_DescribeFaq_598101(name: "describeFaq",
                                        meth: HttpMethod.HttpPost,
                                        host: "kendra.amazonaws.com", route: "/#X-Amz-Target=AWSKendraFrontendService.DescribeFaq",
                                        validator: validate_DescribeFaq_598102,
                                        base: "/", url: url_DescribeFaq_598103,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIndex_598116 = ref object of OpenApiRestCall_597389
proc url_DescribeIndex_598118(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeIndex_598117(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing Amazon Kendra index
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598119 = header.getOrDefault("X-Amz-Target")
  valid_598119 = validateParameter(valid_598119, JString, required = true, default = newJString(
      "AWSKendraFrontendService.DescribeIndex"))
  if valid_598119 != nil:
    section.add "X-Amz-Target", valid_598119
  var valid_598120 = header.getOrDefault("X-Amz-Signature")
  valid_598120 = validateParameter(valid_598120, JString, required = false,
                                 default = nil)
  if valid_598120 != nil:
    section.add "X-Amz-Signature", valid_598120
  var valid_598121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598121 = validateParameter(valid_598121, JString, required = false,
                                 default = nil)
  if valid_598121 != nil:
    section.add "X-Amz-Content-Sha256", valid_598121
  var valid_598122 = header.getOrDefault("X-Amz-Date")
  valid_598122 = validateParameter(valid_598122, JString, required = false,
                                 default = nil)
  if valid_598122 != nil:
    section.add "X-Amz-Date", valid_598122
  var valid_598123 = header.getOrDefault("X-Amz-Credential")
  valid_598123 = validateParameter(valid_598123, JString, required = false,
                                 default = nil)
  if valid_598123 != nil:
    section.add "X-Amz-Credential", valid_598123
  var valid_598124 = header.getOrDefault("X-Amz-Security-Token")
  valid_598124 = validateParameter(valid_598124, JString, required = false,
                                 default = nil)
  if valid_598124 != nil:
    section.add "X-Amz-Security-Token", valid_598124
  var valid_598125 = header.getOrDefault("X-Amz-Algorithm")
  valid_598125 = validateParameter(valid_598125, JString, required = false,
                                 default = nil)
  if valid_598125 != nil:
    section.add "X-Amz-Algorithm", valid_598125
  var valid_598126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598126 = validateParameter(valid_598126, JString, required = false,
                                 default = nil)
  if valid_598126 != nil:
    section.add "X-Amz-SignedHeaders", valid_598126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598128: Call_DescribeIndex_598116; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing Amazon Kendra index
  ## 
  let valid = call_598128.validator(path, query, header, formData, body)
  let scheme = call_598128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598128.url(scheme.get, call_598128.host, call_598128.base,
                         call_598128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598128, url, valid)

proc call*(call_598129: Call_DescribeIndex_598116; body: JsonNode): Recallable =
  ## describeIndex
  ## Describes an existing Amazon Kendra index
  ##   body: JObject (required)
  var body_598130 = newJObject()
  if body != nil:
    body_598130 = body
  result = call_598129.call(nil, nil, nil, nil, body_598130)

var describeIndex* = Call_DescribeIndex_598116(name: "describeIndex",
    meth: HttpMethod.HttpPost, host: "kendra.amazonaws.com",
    route: "/#X-Amz-Target=AWSKendraFrontendService.DescribeIndex",
    validator: validate_DescribeIndex_598117, base: "/", url: url_DescribeIndex_598118,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSourceSyncJobs_598131 = ref object of OpenApiRestCall_597389
proc url_ListDataSourceSyncJobs_598133(protocol: Scheme; host: string; base: string;
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

proc validate_ListDataSourceSyncJobs_598132(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets statistics about synchronizing Amazon Kendra with a data source.
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
  var valid_598134 = query.getOrDefault("MaxResults")
  valid_598134 = validateParameter(valid_598134, JString, required = false,
                                 default = nil)
  if valid_598134 != nil:
    section.add "MaxResults", valid_598134
  var valid_598135 = query.getOrDefault("NextToken")
  valid_598135 = validateParameter(valid_598135, JString, required = false,
                                 default = nil)
  if valid_598135 != nil:
    section.add "NextToken", valid_598135
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598136 = header.getOrDefault("X-Amz-Target")
  valid_598136 = validateParameter(valid_598136, JString, required = true, default = newJString(
      "AWSKendraFrontendService.ListDataSourceSyncJobs"))
  if valid_598136 != nil:
    section.add "X-Amz-Target", valid_598136
  var valid_598137 = header.getOrDefault("X-Amz-Signature")
  valid_598137 = validateParameter(valid_598137, JString, required = false,
                                 default = nil)
  if valid_598137 != nil:
    section.add "X-Amz-Signature", valid_598137
  var valid_598138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598138 = validateParameter(valid_598138, JString, required = false,
                                 default = nil)
  if valid_598138 != nil:
    section.add "X-Amz-Content-Sha256", valid_598138
  var valid_598139 = header.getOrDefault("X-Amz-Date")
  valid_598139 = validateParameter(valid_598139, JString, required = false,
                                 default = nil)
  if valid_598139 != nil:
    section.add "X-Amz-Date", valid_598139
  var valid_598140 = header.getOrDefault("X-Amz-Credential")
  valid_598140 = validateParameter(valid_598140, JString, required = false,
                                 default = nil)
  if valid_598140 != nil:
    section.add "X-Amz-Credential", valid_598140
  var valid_598141 = header.getOrDefault("X-Amz-Security-Token")
  valid_598141 = validateParameter(valid_598141, JString, required = false,
                                 default = nil)
  if valid_598141 != nil:
    section.add "X-Amz-Security-Token", valid_598141
  var valid_598142 = header.getOrDefault("X-Amz-Algorithm")
  valid_598142 = validateParameter(valid_598142, JString, required = false,
                                 default = nil)
  if valid_598142 != nil:
    section.add "X-Amz-Algorithm", valid_598142
  var valid_598143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598143 = validateParameter(valid_598143, JString, required = false,
                                 default = nil)
  if valid_598143 != nil:
    section.add "X-Amz-SignedHeaders", valid_598143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598145: Call_ListDataSourceSyncJobs_598131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets statistics about synchronizing Amazon Kendra with a data source.
  ## 
  let valid = call_598145.validator(path, query, header, formData, body)
  let scheme = call_598145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598145.url(scheme.get, call_598145.host, call_598145.base,
                         call_598145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598145, url, valid)

proc call*(call_598146: Call_ListDataSourceSyncJobs_598131; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDataSourceSyncJobs
  ## Gets statistics about synchronizing Amazon Kendra with a data source.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_598147 = newJObject()
  var body_598148 = newJObject()
  add(query_598147, "MaxResults", newJString(MaxResults))
  add(query_598147, "NextToken", newJString(NextToken))
  if body != nil:
    body_598148 = body
  result = call_598146.call(nil, query_598147, nil, nil, body_598148)

var listDataSourceSyncJobs* = Call_ListDataSourceSyncJobs_598131(
    name: "listDataSourceSyncJobs", meth: HttpMethod.HttpPost,
    host: "kendra.amazonaws.com",
    route: "/#X-Amz-Target=AWSKendraFrontendService.ListDataSourceSyncJobs",
    validator: validate_ListDataSourceSyncJobs_598132, base: "/",
    url: url_ListDataSourceSyncJobs_598133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSources_598150 = ref object of OpenApiRestCall_597389
proc url_ListDataSources_598152(protocol: Scheme; host: string; base: string;
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

proc validate_ListDataSources_598151(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists the data sources that you have created.
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
  var valid_598153 = query.getOrDefault("MaxResults")
  valid_598153 = validateParameter(valid_598153, JString, required = false,
                                 default = nil)
  if valid_598153 != nil:
    section.add "MaxResults", valid_598153
  var valid_598154 = query.getOrDefault("NextToken")
  valid_598154 = validateParameter(valid_598154, JString, required = false,
                                 default = nil)
  if valid_598154 != nil:
    section.add "NextToken", valid_598154
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598155 = header.getOrDefault("X-Amz-Target")
  valid_598155 = validateParameter(valid_598155, JString, required = true, default = newJString(
      "AWSKendraFrontendService.ListDataSources"))
  if valid_598155 != nil:
    section.add "X-Amz-Target", valid_598155
  var valid_598156 = header.getOrDefault("X-Amz-Signature")
  valid_598156 = validateParameter(valid_598156, JString, required = false,
                                 default = nil)
  if valid_598156 != nil:
    section.add "X-Amz-Signature", valid_598156
  var valid_598157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598157 = validateParameter(valid_598157, JString, required = false,
                                 default = nil)
  if valid_598157 != nil:
    section.add "X-Amz-Content-Sha256", valid_598157
  var valid_598158 = header.getOrDefault("X-Amz-Date")
  valid_598158 = validateParameter(valid_598158, JString, required = false,
                                 default = nil)
  if valid_598158 != nil:
    section.add "X-Amz-Date", valid_598158
  var valid_598159 = header.getOrDefault("X-Amz-Credential")
  valid_598159 = validateParameter(valid_598159, JString, required = false,
                                 default = nil)
  if valid_598159 != nil:
    section.add "X-Amz-Credential", valid_598159
  var valid_598160 = header.getOrDefault("X-Amz-Security-Token")
  valid_598160 = validateParameter(valid_598160, JString, required = false,
                                 default = nil)
  if valid_598160 != nil:
    section.add "X-Amz-Security-Token", valid_598160
  var valid_598161 = header.getOrDefault("X-Amz-Algorithm")
  valid_598161 = validateParameter(valid_598161, JString, required = false,
                                 default = nil)
  if valid_598161 != nil:
    section.add "X-Amz-Algorithm", valid_598161
  var valid_598162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598162 = validateParameter(valid_598162, JString, required = false,
                                 default = nil)
  if valid_598162 != nil:
    section.add "X-Amz-SignedHeaders", valid_598162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598164: Call_ListDataSources_598150; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the data sources that you have created.
  ## 
  let valid = call_598164.validator(path, query, header, formData, body)
  let scheme = call_598164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598164.url(scheme.get, call_598164.host, call_598164.base,
                         call_598164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598164, url, valid)

proc call*(call_598165: Call_ListDataSources_598150; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDataSources
  ## Lists the data sources that you have created.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_598166 = newJObject()
  var body_598167 = newJObject()
  add(query_598166, "MaxResults", newJString(MaxResults))
  add(query_598166, "NextToken", newJString(NextToken))
  if body != nil:
    body_598167 = body
  result = call_598165.call(nil, query_598166, nil, nil, body_598167)

var listDataSources* = Call_ListDataSources_598150(name: "listDataSources",
    meth: HttpMethod.HttpPost, host: "kendra.amazonaws.com",
    route: "/#X-Amz-Target=AWSKendraFrontendService.ListDataSources",
    validator: validate_ListDataSources_598151, base: "/", url: url_ListDataSources_598152,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFaqs_598168 = ref object of OpenApiRestCall_597389
proc url_ListFaqs_598170(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListFaqs_598169(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of FAQ lists associated with an index.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598171 = header.getOrDefault("X-Amz-Target")
  valid_598171 = validateParameter(valid_598171, JString, required = true, default = newJString(
      "AWSKendraFrontendService.ListFaqs"))
  if valid_598171 != nil:
    section.add "X-Amz-Target", valid_598171
  var valid_598172 = header.getOrDefault("X-Amz-Signature")
  valid_598172 = validateParameter(valid_598172, JString, required = false,
                                 default = nil)
  if valid_598172 != nil:
    section.add "X-Amz-Signature", valid_598172
  var valid_598173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598173 = validateParameter(valid_598173, JString, required = false,
                                 default = nil)
  if valid_598173 != nil:
    section.add "X-Amz-Content-Sha256", valid_598173
  var valid_598174 = header.getOrDefault("X-Amz-Date")
  valid_598174 = validateParameter(valid_598174, JString, required = false,
                                 default = nil)
  if valid_598174 != nil:
    section.add "X-Amz-Date", valid_598174
  var valid_598175 = header.getOrDefault("X-Amz-Credential")
  valid_598175 = validateParameter(valid_598175, JString, required = false,
                                 default = nil)
  if valid_598175 != nil:
    section.add "X-Amz-Credential", valid_598175
  var valid_598176 = header.getOrDefault("X-Amz-Security-Token")
  valid_598176 = validateParameter(valid_598176, JString, required = false,
                                 default = nil)
  if valid_598176 != nil:
    section.add "X-Amz-Security-Token", valid_598176
  var valid_598177 = header.getOrDefault("X-Amz-Algorithm")
  valid_598177 = validateParameter(valid_598177, JString, required = false,
                                 default = nil)
  if valid_598177 != nil:
    section.add "X-Amz-Algorithm", valid_598177
  var valid_598178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598178 = validateParameter(valid_598178, JString, required = false,
                                 default = nil)
  if valid_598178 != nil:
    section.add "X-Amz-SignedHeaders", valid_598178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598180: Call_ListFaqs_598168; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of FAQ lists associated with an index.
  ## 
  let valid = call_598180.validator(path, query, header, formData, body)
  let scheme = call_598180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598180.url(scheme.get, call_598180.host, call_598180.base,
                         call_598180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598180, url, valid)

proc call*(call_598181: Call_ListFaqs_598168; body: JsonNode): Recallable =
  ## listFaqs
  ## Gets a list of FAQ lists associated with an index.
  ##   body: JObject (required)
  var body_598182 = newJObject()
  if body != nil:
    body_598182 = body
  result = call_598181.call(nil, nil, nil, nil, body_598182)

var listFaqs* = Call_ListFaqs_598168(name: "listFaqs", meth: HttpMethod.HttpPost,
                                  host: "kendra.amazonaws.com", route: "/#X-Amz-Target=AWSKendraFrontendService.ListFaqs",
                                  validator: validate_ListFaqs_598169, base: "/",
                                  url: url_ListFaqs_598170,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIndices_598183 = ref object of OpenApiRestCall_597389
proc url_ListIndices_598185(protocol: Scheme; host: string; base: string;
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

proc validate_ListIndices_598184(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the Amazon Kendra indexes that you have created.
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
  var valid_598186 = query.getOrDefault("MaxResults")
  valid_598186 = validateParameter(valid_598186, JString, required = false,
                                 default = nil)
  if valid_598186 != nil:
    section.add "MaxResults", valid_598186
  var valid_598187 = query.getOrDefault("NextToken")
  valid_598187 = validateParameter(valid_598187, JString, required = false,
                                 default = nil)
  if valid_598187 != nil:
    section.add "NextToken", valid_598187
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598188 = header.getOrDefault("X-Amz-Target")
  valid_598188 = validateParameter(valid_598188, JString, required = true, default = newJString(
      "AWSKendraFrontendService.ListIndices"))
  if valid_598188 != nil:
    section.add "X-Amz-Target", valid_598188
  var valid_598189 = header.getOrDefault("X-Amz-Signature")
  valid_598189 = validateParameter(valid_598189, JString, required = false,
                                 default = nil)
  if valid_598189 != nil:
    section.add "X-Amz-Signature", valid_598189
  var valid_598190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598190 = validateParameter(valid_598190, JString, required = false,
                                 default = nil)
  if valid_598190 != nil:
    section.add "X-Amz-Content-Sha256", valid_598190
  var valid_598191 = header.getOrDefault("X-Amz-Date")
  valid_598191 = validateParameter(valid_598191, JString, required = false,
                                 default = nil)
  if valid_598191 != nil:
    section.add "X-Amz-Date", valid_598191
  var valid_598192 = header.getOrDefault("X-Amz-Credential")
  valid_598192 = validateParameter(valid_598192, JString, required = false,
                                 default = nil)
  if valid_598192 != nil:
    section.add "X-Amz-Credential", valid_598192
  var valid_598193 = header.getOrDefault("X-Amz-Security-Token")
  valid_598193 = validateParameter(valid_598193, JString, required = false,
                                 default = nil)
  if valid_598193 != nil:
    section.add "X-Amz-Security-Token", valid_598193
  var valid_598194 = header.getOrDefault("X-Amz-Algorithm")
  valid_598194 = validateParameter(valid_598194, JString, required = false,
                                 default = nil)
  if valid_598194 != nil:
    section.add "X-Amz-Algorithm", valid_598194
  var valid_598195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598195 = validateParameter(valid_598195, JString, required = false,
                                 default = nil)
  if valid_598195 != nil:
    section.add "X-Amz-SignedHeaders", valid_598195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598197: Call_ListIndices_598183; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Kendra indexes that you have created.
  ## 
  let valid = call_598197.validator(path, query, header, formData, body)
  let scheme = call_598197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598197.url(scheme.get, call_598197.host, call_598197.base,
                         call_598197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598197, url, valid)

proc call*(call_598198: Call_ListIndices_598183; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listIndices
  ## Lists the Amazon Kendra indexes that you have created.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_598199 = newJObject()
  var body_598200 = newJObject()
  add(query_598199, "MaxResults", newJString(MaxResults))
  add(query_598199, "NextToken", newJString(NextToken))
  if body != nil:
    body_598200 = body
  result = call_598198.call(nil, query_598199, nil, nil, body_598200)

var listIndices* = Call_ListIndices_598183(name: "listIndices",
                                        meth: HttpMethod.HttpPost,
                                        host: "kendra.amazonaws.com", route: "/#X-Amz-Target=AWSKendraFrontendService.ListIndices",
                                        validator: validate_ListIndices_598184,
                                        base: "/", url: url_ListIndices_598185,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_Query_598201 = ref object of OpenApiRestCall_597389
proc url_Query_598203(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_Query_598202(path: JsonNode; query: JsonNode; header: JsonNode;
                          formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Searches an active index. Use this API to search your documents using query. The <code>Query</code> operation enables to do faceted search and to filter results based on document attributes.</p> <p>It also enables you to provide user context that Amazon Kendra uses to enforce document access control in the search results. </p> <p>Amazon Kendra searches your index for text content and question and answer (FAQ) content. By default the response contains three types of results.</p> <ul> <li> <p>Relevant passages</p> </li> <li> <p>Matching FAQs</p> </li> <li> <p>Relevant documents</p> </li> </ul> <p>You can specify that the query return only one type of result using the <code>QueryResultTypeConfig</code> parameter.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598204 = header.getOrDefault("X-Amz-Target")
  valid_598204 = validateParameter(valid_598204, JString, required = true, default = newJString(
      "AWSKendraFrontendService.Query"))
  if valid_598204 != nil:
    section.add "X-Amz-Target", valid_598204
  var valid_598205 = header.getOrDefault("X-Amz-Signature")
  valid_598205 = validateParameter(valid_598205, JString, required = false,
                                 default = nil)
  if valid_598205 != nil:
    section.add "X-Amz-Signature", valid_598205
  var valid_598206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598206 = validateParameter(valid_598206, JString, required = false,
                                 default = nil)
  if valid_598206 != nil:
    section.add "X-Amz-Content-Sha256", valid_598206
  var valid_598207 = header.getOrDefault("X-Amz-Date")
  valid_598207 = validateParameter(valid_598207, JString, required = false,
                                 default = nil)
  if valid_598207 != nil:
    section.add "X-Amz-Date", valid_598207
  var valid_598208 = header.getOrDefault("X-Amz-Credential")
  valid_598208 = validateParameter(valid_598208, JString, required = false,
                                 default = nil)
  if valid_598208 != nil:
    section.add "X-Amz-Credential", valid_598208
  var valid_598209 = header.getOrDefault("X-Amz-Security-Token")
  valid_598209 = validateParameter(valid_598209, JString, required = false,
                                 default = nil)
  if valid_598209 != nil:
    section.add "X-Amz-Security-Token", valid_598209
  var valid_598210 = header.getOrDefault("X-Amz-Algorithm")
  valid_598210 = validateParameter(valid_598210, JString, required = false,
                                 default = nil)
  if valid_598210 != nil:
    section.add "X-Amz-Algorithm", valid_598210
  var valid_598211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598211 = validateParameter(valid_598211, JString, required = false,
                                 default = nil)
  if valid_598211 != nil:
    section.add "X-Amz-SignedHeaders", valid_598211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598213: Call_Query_598201; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Searches an active index. Use this API to search your documents using query. The <code>Query</code> operation enables to do faceted search and to filter results based on document attributes.</p> <p>It also enables you to provide user context that Amazon Kendra uses to enforce document access control in the search results. </p> <p>Amazon Kendra searches your index for text content and question and answer (FAQ) content. By default the response contains three types of results.</p> <ul> <li> <p>Relevant passages</p> </li> <li> <p>Matching FAQs</p> </li> <li> <p>Relevant documents</p> </li> </ul> <p>You can specify that the query return only one type of result using the <code>QueryResultTypeConfig</code> parameter.</p>
  ## 
  let valid = call_598213.validator(path, query, header, formData, body)
  let scheme = call_598213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598213.url(scheme.get, call_598213.host, call_598213.base,
                         call_598213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598213, url, valid)

proc call*(call_598214: Call_Query_598201; body: JsonNode): Recallable =
  ## query
  ## <p>Searches an active index. Use this API to search your documents using query. The <code>Query</code> operation enables to do faceted search and to filter results based on document attributes.</p> <p>It also enables you to provide user context that Amazon Kendra uses to enforce document access control in the search results. </p> <p>Amazon Kendra searches your index for text content and question and answer (FAQ) content. By default the response contains three types of results.</p> <ul> <li> <p>Relevant passages</p> </li> <li> <p>Matching FAQs</p> </li> <li> <p>Relevant documents</p> </li> </ul> <p>You can specify that the query return only one type of result using the <code>QueryResultTypeConfig</code> parameter.</p>
  ##   body: JObject (required)
  var body_598215 = newJObject()
  if body != nil:
    body_598215 = body
  result = call_598214.call(nil, nil, nil, nil, body_598215)

var query* = Call_Query_598201(name: "query", meth: HttpMethod.HttpPost,
                            host: "kendra.amazonaws.com", route: "/#X-Amz-Target=AWSKendraFrontendService.Query",
                            validator: validate_Query_598202, base: "/",
                            url: url_Query_598203,
                            schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDataSourceSyncJob_598216 = ref object of OpenApiRestCall_597389
proc url_StartDataSourceSyncJob_598218(protocol: Scheme; host: string; base: string;
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

proc validate_StartDataSourceSyncJob_598217(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts a synchronization job for a data source. If a synchronization job is already in progress, Amazon Kendra returns a <code>ResourceInUseException</code> exception.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598219 = header.getOrDefault("X-Amz-Target")
  valid_598219 = validateParameter(valid_598219, JString, required = true, default = newJString(
      "AWSKendraFrontendService.StartDataSourceSyncJob"))
  if valid_598219 != nil:
    section.add "X-Amz-Target", valid_598219
  var valid_598220 = header.getOrDefault("X-Amz-Signature")
  valid_598220 = validateParameter(valid_598220, JString, required = false,
                                 default = nil)
  if valid_598220 != nil:
    section.add "X-Amz-Signature", valid_598220
  var valid_598221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598221 = validateParameter(valid_598221, JString, required = false,
                                 default = nil)
  if valid_598221 != nil:
    section.add "X-Amz-Content-Sha256", valid_598221
  var valid_598222 = header.getOrDefault("X-Amz-Date")
  valid_598222 = validateParameter(valid_598222, JString, required = false,
                                 default = nil)
  if valid_598222 != nil:
    section.add "X-Amz-Date", valid_598222
  var valid_598223 = header.getOrDefault("X-Amz-Credential")
  valid_598223 = validateParameter(valid_598223, JString, required = false,
                                 default = nil)
  if valid_598223 != nil:
    section.add "X-Amz-Credential", valid_598223
  var valid_598224 = header.getOrDefault("X-Amz-Security-Token")
  valid_598224 = validateParameter(valid_598224, JString, required = false,
                                 default = nil)
  if valid_598224 != nil:
    section.add "X-Amz-Security-Token", valid_598224
  var valid_598225 = header.getOrDefault("X-Amz-Algorithm")
  valid_598225 = validateParameter(valid_598225, JString, required = false,
                                 default = nil)
  if valid_598225 != nil:
    section.add "X-Amz-Algorithm", valid_598225
  var valid_598226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598226 = validateParameter(valid_598226, JString, required = false,
                                 default = nil)
  if valid_598226 != nil:
    section.add "X-Amz-SignedHeaders", valid_598226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598228: Call_StartDataSourceSyncJob_598216; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a synchronization job for a data source. If a synchronization job is already in progress, Amazon Kendra returns a <code>ResourceInUseException</code> exception.
  ## 
  let valid = call_598228.validator(path, query, header, formData, body)
  let scheme = call_598228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598228.url(scheme.get, call_598228.host, call_598228.base,
                         call_598228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598228, url, valid)

proc call*(call_598229: Call_StartDataSourceSyncJob_598216; body: JsonNode): Recallable =
  ## startDataSourceSyncJob
  ## Starts a synchronization job for a data source. If a synchronization job is already in progress, Amazon Kendra returns a <code>ResourceInUseException</code> exception.
  ##   body: JObject (required)
  var body_598230 = newJObject()
  if body != nil:
    body_598230 = body
  result = call_598229.call(nil, nil, nil, nil, body_598230)

var startDataSourceSyncJob* = Call_StartDataSourceSyncJob_598216(
    name: "startDataSourceSyncJob", meth: HttpMethod.HttpPost,
    host: "kendra.amazonaws.com",
    route: "/#X-Amz-Target=AWSKendraFrontendService.StartDataSourceSyncJob",
    validator: validate_StartDataSourceSyncJob_598217, base: "/",
    url: url_StartDataSourceSyncJob_598218, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDataSourceSyncJob_598231 = ref object of OpenApiRestCall_597389
proc url_StopDataSourceSyncJob_598233(protocol: Scheme; host: string; base: string;
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

proc validate_StopDataSourceSyncJob_598232(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Stops a running synchronization job. You can't stop a scheduled synchronization job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598234 = header.getOrDefault("X-Amz-Target")
  valid_598234 = validateParameter(valid_598234, JString, required = true, default = newJString(
      "AWSKendraFrontendService.StopDataSourceSyncJob"))
  if valid_598234 != nil:
    section.add "X-Amz-Target", valid_598234
  var valid_598235 = header.getOrDefault("X-Amz-Signature")
  valid_598235 = validateParameter(valid_598235, JString, required = false,
                                 default = nil)
  if valid_598235 != nil:
    section.add "X-Amz-Signature", valid_598235
  var valid_598236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598236 = validateParameter(valid_598236, JString, required = false,
                                 default = nil)
  if valid_598236 != nil:
    section.add "X-Amz-Content-Sha256", valid_598236
  var valid_598237 = header.getOrDefault("X-Amz-Date")
  valid_598237 = validateParameter(valid_598237, JString, required = false,
                                 default = nil)
  if valid_598237 != nil:
    section.add "X-Amz-Date", valid_598237
  var valid_598238 = header.getOrDefault("X-Amz-Credential")
  valid_598238 = validateParameter(valid_598238, JString, required = false,
                                 default = nil)
  if valid_598238 != nil:
    section.add "X-Amz-Credential", valid_598238
  var valid_598239 = header.getOrDefault("X-Amz-Security-Token")
  valid_598239 = validateParameter(valid_598239, JString, required = false,
                                 default = nil)
  if valid_598239 != nil:
    section.add "X-Amz-Security-Token", valid_598239
  var valid_598240 = header.getOrDefault("X-Amz-Algorithm")
  valid_598240 = validateParameter(valid_598240, JString, required = false,
                                 default = nil)
  if valid_598240 != nil:
    section.add "X-Amz-Algorithm", valid_598240
  var valid_598241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598241 = validateParameter(valid_598241, JString, required = false,
                                 default = nil)
  if valid_598241 != nil:
    section.add "X-Amz-SignedHeaders", valid_598241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598243: Call_StopDataSourceSyncJob_598231; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a running synchronization job. You can't stop a scheduled synchronization job.
  ## 
  let valid = call_598243.validator(path, query, header, formData, body)
  let scheme = call_598243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598243.url(scheme.get, call_598243.host, call_598243.base,
                         call_598243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598243, url, valid)

proc call*(call_598244: Call_StopDataSourceSyncJob_598231; body: JsonNode): Recallable =
  ## stopDataSourceSyncJob
  ## Stops a running synchronization job. You can't stop a scheduled synchronization job.
  ##   body: JObject (required)
  var body_598245 = newJObject()
  if body != nil:
    body_598245 = body
  result = call_598244.call(nil, nil, nil, nil, body_598245)

var stopDataSourceSyncJob* = Call_StopDataSourceSyncJob_598231(
    name: "stopDataSourceSyncJob", meth: HttpMethod.HttpPost,
    host: "kendra.amazonaws.com",
    route: "/#X-Amz-Target=AWSKendraFrontendService.StopDataSourceSyncJob",
    validator: validate_StopDataSourceSyncJob_598232, base: "/",
    url: url_StopDataSourceSyncJob_598233, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubmitFeedback_598246 = ref object of OpenApiRestCall_597389
proc url_SubmitFeedback_598248(protocol: Scheme; host: string; base: string;
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

proc validate_SubmitFeedback_598247(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Enables you to provide feedback to Amazon Kendra to improve the performance of the service. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598249 = header.getOrDefault("X-Amz-Target")
  valid_598249 = validateParameter(valid_598249, JString, required = true, default = newJString(
      "AWSKendraFrontendService.SubmitFeedback"))
  if valid_598249 != nil:
    section.add "X-Amz-Target", valid_598249
  var valid_598250 = header.getOrDefault("X-Amz-Signature")
  valid_598250 = validateParameter(valid_598250, JString, required = false,
                                 default = nil)
  if valid_598250 != nil:
    section.add "X-Amz-Signature", valid_598250
  var valid_598251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598251 = validateParameter(valid_598251, JString, required = false,
                                 default = nil)
  if valid_598251 != nil:
    section.add "X-Amz-Content-Sha256", valid_598251
  var valid_598252 = header.getOrDefault("X-Amz-Date")
  valid_598252 = validateParameter(valid_598252, JString, required = false,
                                 default = nil)
  if valid_598252 != nil:
    section.add "X-Amz-Date", valid_598252
  var valid_598253 = header.getOrDefault("X-Amz-Credential")
  valid_598253 = validateParameter(valid_598253, JString, required = false,
                                 default = nil)
  if valid_598253 != nil:
    section.add "X-Amz-Credential", valid_598253
  var valid_598254 = header.getOrDefault("X-Amz-Security-Token")
  valid_598254 = validateParameter(valid_598254, JString, required = false,
                                 default = nil)
  if valid_598254 != nil:
    section.add "X-Amz-Security-Token", valid_598254
  var valid_598255 = header.getOrDefault("X-Amz-Algorithm")
  valid_598255 = validateParameter(valid_598255, JString, required = false,
                                 default = nil)
  if valid_598255 != nil:
    section.add "X-Amz-Algorithm", valid_598255
  var valid_598256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598256 = validateParameter(valid_598256, JString, required = false,
                                 default = nil)
  if valid_598256 != nil:
    section.add "X-Amz-SignedHeaders", valid_598256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598258: Call_SubmitFeedback_598246; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables you to provide feedback to Amazon Kendra to improve the performance of the service. 
  ## 
  let valid = call_598258.validator(path, query, header, formData, body)
  let scheme = call_598258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598258.url(scheme.get, call_598258.host, call_598258.base,
                         call_598258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598258, url, valid)

proc call*(call_598259: Call_SubmitFeedback_598246; body: JsonNode): Recallable =
  ## submitFeedback
  ## Enables you to provide feedback to Amazon Kendra to improve the performance of the service. 
  ##   body: JObject (required)
  var body_598260 = newJObject()
  if body != nil:
    body_598260 = body
  result = call_598259.call(nil, nil, nil, nil, body_598260)

var submitFeedback* = Call_SubmitFeedback_598246(name: "submitFeedback",
    meth: HttpMethod.HttpPost, host: "kendra.amazonaws.com",
    route: "/#X-Amz-Target=AWSKendraFrontendService.SubmitFeedback",
    validator: validate_SubmitFeedback_598247, base: "/", url: url_SubmitFeedback_598248,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSource_598261 = ref object of OpenApiRestCall_597389
proc url_UpdateDataSource_598263(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDataSource_598262(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates an existing Amazon Kendra data source.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598264 = header.getOrDefault("X-Amz-Target")
  valid_598264 = validateParameter(valid_598264, JString, required = true, default = newJString(
      "AWSKendraFrontendService.UpdateDataSource"))
  if valid_598264 != nil:
    section.add "X-Amz-Target", valid_598264
  var valid_598265 = header.getOrDefault("X-Amz-Signature")
  valid_598265 = validateParameter(valid_598265, JString, required = false,
                                 default = nil)
  if valid_598265 != nil:
    section.add "X-Amz-Signature", valid_598265
  var valid_598266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598266 = validateParameter(valid_598266, JString, required = false,
                                 default = nil)
  if valid_598266 != nil:
    section.add "X-Amz-Content-Sha256", valid_598266
  var valid_598267 = header.getOrDefault("X-Amz-Date")
  valid_598267 = validateParameter(valid_598267, JString, required = false,
                                 default = nil)
  if valid_598267 != nil:
    section.add "X-Amz-Date", valid_598267
  var valid_598268 = header.getOrDefault("X-Amz-Credential")
  valid_598268 = validateParameter(valid_598268, JString, required = false,
                                 default = nil)
  if valid_598268 != nil:
    section.add "X-Amz-Credential", valid_598268
  var valid_598269 = header.getOrDefault("X-Amz-Security-Token")
  valid_598269 = validateParameter(valid_598269, JString, required = false,
                                 default = nil)
  if valid_598269 != nil:
    section.add "X-Amz-Security-Token", valid_598269
  var valid_598270 = header.getOrDefault("X-Amz-Algorithm")
  valid_598270 = validateParameter(valid_598270, JString, required = false,
                                 default = nil)
  if valid_598270 != nil:
    section.add "X-Amz-Algorithm", valid_598270
  var valid_598271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598271 = validateParameter(valid_598271, JString, required = false,
                                 default = nil)
  if valid_598271 != nil:
    section.add "X-Amz-SignedHeaders", valid_598271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598273: Call_UpdateDataSource_598261; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing Amazon Kendra data source.
  ## 
  let valid = call_598273.validator(path, query, header, formData, body)
  let scheme = call_598273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598273.url(scheme.get, call_598273.host, call_598273.base,
                         call_598273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598273, url, valid)

proc call*(call_598274: Call_UpdateDataSource_598261; body: JsonNode): Recallable =
  ## updateDataSource
  ## Updates an existing Amazon Kendra data source.
  ##   body: JObject (required)
  var body_598275 = newJObject()
  if body != nil:
    body_598275 = body
  result = call_598274.call(nil, nil, nil, nil, body_598275)

var updateDataSource* = Call_UpdateDataSource_598261(name: "updateDataSource",
    meth: HttpMethod.HttpPost, host: "kendra.amazonaws.com",
    route: "/#X-Amz-Target=AWSKendraFrontendService.UpdateDataSource",
    validator: validate_UpdateDataSource_598262, base: "/",
    url: url_UpdateDataSource_598263, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIndex_598276 = ref object of OpenApiRestCall_597389
proc url_UpdateIndex_598278(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateIndex_598277(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing Amazon Kendra index.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598279 = header.getOrDefault("X-Amz-Target")
  valid_598279 = validateParameter(valid_598279, JString, required = true, default = newJString(
      "AWSKendraFrontendService.UpdateIndex"))
  if valid_598279 != nil:
    section.add "X-Amz-Target", valid_598279
  var valid_598280 = header.getOrDefault("X-Amz-Signature")
  valid_598280 = validateParameter(valid_598280, JString, required = false,
                                 default = nil)
  if valid_598280 != nil:
    section.add "X-Amz-Signature", valid_598280
  var valid_598281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598281 = validateParameter(valid_598281, JString, required = false,
                                 default = nil)
  if valid_598281 != nil:
    section.add "X-Amz-Content-Sha256", valid_598281
  var valid_598282 = header.getOrDefault("X-Amz-Date")
  valid_598282 = validateParameter(valid_598282, JString, required = false,
                                 default = nil)
  if valid_598282 != nil:
    section.add "X-Amz-Date", valid_598282
  var valid_598283 = header.getOrDefault("X-Amz-Credential")
  valid_598283 = validateParameter(valid_598283, JString, required = false,
                                 default = nil)
  if valid_598283 != nil:
    section.add "X-Amz-Credential", valid_598283
  var valid_598284 = header.getOrDefault("X-Amz-Security-Token")
  valid_598284 = validateParameter(valid_598284, JString, required = false,
                                 default = nil)
  if valid_598284 != nil:
    section.add "X-Amz-Security-Token", valid_598284
  var valid_598285 = header.getOrDefault("X-Amz-Algorithm")
  valid_598285 = validateParameter(valid_598285, JString, required = false,
                                 default = nil)
  if valid_598285 != nil:
    section.add "X-Amz-Algorithm", valid_598285
  var valid_598286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598286 = validateParameter(valid_598286, JString, required = false,
                                 default = nil)
  if valid_598286 != nil:
    section.add "X-Amz-SignedHeaders", valid_598286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598288: Call_UpdateIndex_598276; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing Amazon Kendra index.
  ## 
  let valid = call_598288.validator(path, query, header, formData, body)
  let scheme = call_598288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598288.url(scheme.get, call_598288.host, call_598288.base,
                         call_598288.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598288, url, valid)

proc call*(call_598289: Call_UpdateIndex_598276; body: JsonNode): Recallable =
  ## updateIndex
  ## Updates an existing Amazon Kendra index.
  ##   body: JObject (required)
  var body_598290 = newJObject()
  if body != nil:
    body_598290 = body
  result = call_598289.call(nil, nil, nil, nil, body_598290)

var updateIndex* = Call_UpdateIndex_598276(name: "updateIndex",
                                        meth: HttpMethod.HttpPost,
                                        host: "kendra.amazonaws.com", route: "/#X-Amz-Target=AWSKendraFrontendService.UpdateIndex",
                                        validator: validate_UpdateIndex_598277,
                                        base: "/", url: url_UpdateIndex_598278,
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
